#include "DesktopPresence.h"

#import <AppKit/AppKit.h>
#import <objc/runtime.h>

// 菜单项 tag。两个菜单（状态项 / Dock）共用同一套编号，
// dispatch: 按 tag 分发到对应的 Qt 信号。
namespace {
constexpr NSInteger kActionOpen = 1;
constexpr NSInteger kActionPrevious = 2;
constexpr NSInteger kActionNext = 3;
constexpr NSInteger kActionSettings = 4;
constexpr NSInteger kActionQuit = 5;
constexpr NSInteger kActionPlayPause = 6;
} // namespace

// 单例语义：整个进程只创建一个 DesktopPresence。
// Dock 菜单是在 NSApplicationDelegate 的回调里临时构建的，
// 回调拿不到 C++ this 指针，所以用文件级指针转发。
DesktopPresence *g_presence = nullptr;
bool g_canPrevious = false;
bool g_canNext = false;
bool g_isPlaying = false;

// 菜单项的 action target，同时持有状态项与需要动态改可用态的菜单项引用，
// 这样 C++ 侧就不用跨 ARC 边界保存 Obj-C 对象指针。
// 注意：Obj-C 类不能放进 C++ namespace，必须留在全局作用域。
@interface KMusicPresenceTarget : NSObject
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenuItem *playPauseItem;
@property (nonatomic, strong) NSMenuItem *previousItem;
@property (nonatomic, strong) NSMenuItem *nextItem;
@end

@implementation KMusicPresenceTarget
- (void)dispatch:(NSMenuItem *)sender
{
    if (!g_presence)
        return;
    switch (sender.tag) {
    case kActionOpen:      emit g_presence->openRequested(); break;
    case kActionPlayPause: emit g_presence->playPauseRequested(); break;
    case kActionPrevious:  emit g_presence->previousRequested(); break;
    case kActionNext:      emit g_presence->nextRequested(); break;
    case kActionSettings:  emit g_presence->settingsRequested(); break;
    case kActionQuit:      emit g_presence->quitRequested(); break;
    default: break;
    }
}
@end

namespace {

KMusicPresenceTarget *presenceTarget()
{
    static KMusicPresenceTarget *target = nil;
    if (!target)
        target = [[KMusicPresenceTarget alloc] init];
    return target;
}

NSMenuItem *appendItem(NSMenu *menu, NSString *title, NSInteger tag)
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                 action:@selector(dispatch:)
                                          keyEquivalent:@""];
    item.tag = tag;
    item.target = presenceTarget();
    [menu addItem:item];
    return item;
}

// 菜单栏图标用 SF Symbol 的模板图：自动跟随系统明暗，无需自绘两套。
// template 是 C++ 关键字，Obj-C 属性只能用方括号语法访问。
NSImage *statusImage()
{
    NSImage *image = [NSImage imageWithSystemSymbolName:@"music.note"
                               accessibilityDescription:@"KMusic"];
    if (image)
        [image setTemplate:YES];
    return image;
}

NSMenu *buildMenu()
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"KMusic"];
    appendItem(menu, @"打开 KMusic", kActionOpen);
    [menu addItem:[NSMenuItem separatorItem]];
    // 同一个条目在「播放」和「暂停」之间切换标题，状态由 setPlaybackActions 同步
    KMusicPresenceTarget *target = presenceTarget();
    target.playPauseItem = appendItem(menu, g_isPlaying ? @"暂停" : @"播放", kActionPlayPause);
    target.previousItem = appendItem(menu, @"上一首", kActionPrevious);
    target.nextItem = appendItem(menu, @"下一首", kActionNext);
    target.previousItem.enabled = g_canPrevious ? YES : NO;
    target.nextItem.enabled = g_canNext ? YES : NO;
    [menu addItem:[NSMenuItem separatorItem]];
    appendItem(menu, @"设置", kActionSettings);
    [menu addItem:[NSMenuItem separatorItem]];
    appendItem(menu, @"退出 KMusic", kActionQuit);
    return menu;
}

// Dock 右键菜单的标准入口是 NSApplicationDelegate 的 applicationDockMenu:。
// Qt 自己装了一个 delegate，且这个方法是可选的，所以在 delegate 的类上
// 动态补一个实现，不动 Qt 自己的委托逻辑。每次弹出都重建，可用态总是最新。
NSMenu *kmusic_dockMenu(id, SEL)
{
    return buildMenu();
}

void installDockMenuHook()
{
    id delegate = [NSApp delegate];
    if (!delegate)
        return;
    Class delegateClass = object_getClass(delegate);
    if (!delegateClass)
        return;
    if (class_respondsToSelector(delegateClass, @selector(applicationDockMenu:)))
        return; // 已有实现（理论上不会），不覆盖
    class_addMethod(delegateClass, @selector(applicationDockMenu:),
                    reinterpret_cast<IMP>(kmusic_dockMenu), "@@:@");
}

} // namespace

// macOS 26 的状态项走 NSScene：在 app 完成启动前创建，拿到的是一个
// 高度为 0、永远不会上屏的窗口。所以由 main.cpp 在事件循环首轮调用
// （QTimer::singleShot(0)），那时 didFinishLaunching 已经结束。可重复调用。
void DesktopPresence::installStatusItem()
{
    KMusicPresenceTarget *target = presenceTarget();
    if (target.statusItem)
        return;
    @autoreleasepool {
        NSStatusItem *item = [[NSStatusBar systemStatusBar]
            statusItemWithLength:NSVariableStatusItemLength];
        item.button.image = statusImage();
        item.button.toolTip = @"KMusic";
        item.menu = buildMenu();
        target.statusItem = item;
    }
}

DesktopPresence::DesktopPresence(QObject *parent)
    : QObject(parent)
{
    g_presence = this;
    @autoreleasepool {
        installDockMenuHook();
    }
}

DesktopPresence::~DesktopPresence()
{
    @autoreleasepool {
        KMusicPresenceTarget *target = presenceTarget();
        if (target.statusItem)
            [[NSStatusBar systemStatusBar] removeStatusItem:target.statusItem];
        target.statusItem = nil;
    }
    if (g_presence == this)
        g_presence = nullptr;
}

void DesktopPresence::setPlaybackActions(bool playing, bool canPrevious, bool canNext)
{
    g_isPlaying = playing;
    g_canPrevious = canPrevious;
    g_canNext = canNext;
    // 状态项菜单里的几个条目是长期持有的，直接更新；Dock 菜单每次
    // 弹出重建，走文件级变量即可。
    @autoreleasepool {
        KMusicPresenceTarget *target = presenceTarget();
        target.playPauseItem.title = playing ? @"暂停" : @"播放";
        target.previousItem.enabled = canPrevious ? YES : NO;
        target.nextItem.enabled = canNext ? YES : NO;
    }
}
