import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
import "UiLanguage.mjs" as Language
LiquidDialog {
    id: dialog
    required property var account
    anchors.centerIn: parent
    width: 370; modal: true; title: Language.text("NetEase account", "网易云账号")
    standardButtons: Dialog.Close
    onClosed: if (!account.authenticated) account.cancelLogin()
    contentItem: ColumnLayout {
        spacing: 14
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.text
            text: dialog.account.authenticated ? Language.text("Signed in as %1", "已登录：%1").arg(dialog.account.nickname)
                : dialog.account.message || Language.text("Sign in with the NetEase Cloud Music mobile app. No password is shared with KMusic.", "请使用网易云音乐手机客户端扫码登录，无需向 KMusic 提供密码。")
        }
        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 216; Layout.preferredHeight: 216
            visible: dialog.account.qrImage.length > 0
            source: dialog.account.qrImage; cache: false; smooth: false
        }
        BusyIndicator { Layout.alignment: Qt.AlignHCenter; visible: running; running: ["generating", "checking", "restoring"].indexOf(dialog.account.state) >= 0 }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11; color: AppTheme.mutedText
            text: dialog.account.storageMessage
            visible: text.length > 0
        }
        MusicActionButton {
            Layout.fillWidth: true
            visible: !dialog.account.authenticated && ["waiting", "scanned", "generating", "checking", "restoring"].indexOf(dialog.account.state) < 0
            objectName: "reviewAccountGenerate"
            text: Language.text("Generate sign-in code", "生成登录二维码")
            onClicked: dialog.account.beginLogin()
        }
        MusicActionButton {
            objectName: "reviewAccountCancel"
            Layout.fillWidth: true; visible: ["waiting", "scanned", "generating", "checking"].indexOf(dialog.account.state) >= 0
            text: Language.text("Cancel sign-in", "取消登录")
            onClicked: { dialog.account.cancelLogin(); dialog.close() }
        }
        MusicActionButton {
            Layout.fillWidth: true; visible: dialog.account.state === "error"
            text: Language.text("Retry saved session", "重试恢复登录"); onClicked: dialog.account.retrySession()
        }
        MusicActionButton {
            Layout.fillWidth: true; visible: dialog.account.authenticated || dialog.account.cleanupRequired; text: dialog.account.authenticated ? Language.text("Sign out on this device", "退出此设备登录") : Language.text("Retry removing saved session", "重试移除已保存的登录信息")
            onClicked: dialog.account.logout()
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11; color: AppTheme.mutedText
            text: Language.text("Playback availability still depends on your subscription and each track’s rights. A successful sign-in does not unlock unavailable music.", "可播放内容取决于你的订阅和歌曲版权，登录不会解锁不可用的音乐。")
        }
    }
}
