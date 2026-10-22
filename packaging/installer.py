#!/usr/bin/env python3
"""KMusic App Store protocol v1. No system package mutations or GUI execution."""
import sys, os, json, re, shutil, subprocess, tempfile, pathlib, platform, fcntl, uuid, signal
from datetime import datetime, timezone

APP = 'org.nextkde.KMusic'
REPO = 'https://github.com/NextKde/KMusic.git'
CODES = {'INVALID_ARGUMENT':2, 'UNSUPPORTED_PLATFORM':10, 'DEPENDENCY_UNSATISFIED':11,
         'PERMISSION_DENIED':12, 'INSTALL_BUSY':13, 'DOWNLOAD_FAILED':20,
         'INTEGRITY_FAILED':21, 'BUILD_FAILED':30, 'INSTALL_FAILED':31,
         'UNINSTALL_FAILED':32, 'INTERNAL_ERROR':99, 'CANCELLED':130}
action = 'unknown'; stage = 'arguments'; log_path = None; log = None

def emit(**fields):
    print(json.dumps(dict(schemaVersion=1, type='result', appId=APP, action=action, **fields)), flush=True)

def fail(code, message, **details):
    raise Failure(code, message, details)

class Failure(Exception):
    def __init__(self, code, message, details):
        self.code, self.message, self.details = code, message, details

def run(args, cwd=None, code='DEPENDENCY_UNSATISFIED', timeout=1800):
    try:
        p = subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           text=True, timeout=timeout)
        if log: log.write(p.stdout); log.flush()
        if p.returncode: fail(code, 'Command failed; see the installation log.', command=args[0])
        return p.stdout.strip()
    except subprocess.TimeoutExpired:
        fail(code, 'Command timed out.', command=args[0])

def progress(name):
    global stage
    stage = name
    print(json.dumps(dict(schemaVersion=1, type='progress', appId=APP, action=action, stage=name)), flush=True)

def atomic_json(path, value):
    tmp = path.with_name(path.name + '.tmp-' + uuid.uuid4().hex)
    tmp.write_text(json.dumps(value, indent=2) + '\n'); os.replace(tmp, path)

def atomic_link(path, target):
    tmp = path.with_name(path.name + '.tmp-' + uuid.uuid4().hex)
    tmp.symlink_to(target); os.replace(tmp, path)

def dependencies(work):
    missing = []
    def add(name, required, installed=None):
        missing.append(dict(id=name, required=required, installed=installed,
                            reason='missing' if installed is None else 'version_too_old'))
    def version(tool, required, args):
        if not shutil.which(tool): add(tool, required); return
        value = run([tool] + args)
        match = re.search(r'(\d+)\.(\d+)(?:\.(\d+))?', value)
        if not match or tuple(int(x or 0) for x in match.groups()) < tuple(map(int, required.split('.'))):
            add(tool, '>=' + required, value.splitlines()[0] if value else 'unknown')
    version('cmake', '3.21.0', ['--version']); version('node', '22.19.0', ['--version'])
    for tool in ['git', 'pkg-config', 'c++', 'make', 'gst-inspect-1.0']:
        if not shutil.which(tool): add(tool, 'present')
    if shutil.which('pkg-config'):
        for name, minimum in [('gstreamer-1.0','1.0'), ('gstreamer-audio-1.0','1.0'), ('gstreamer-pbutils-1.0','1.0'), ('taglib','1.12'), ('libqrencode','0')]:
            p = subprocess.run(['pkg-config','--modversion',name], capture_output=True, text=True)
            value = p.stdout.strip() if p.returncode == 0 else None
            if value is None or subprocess.run(['pkg-config','--atleast-version='+minimum,name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
                add(name, '>='+minimum, value)
    if shutil.which('gst-inspect-1.0'):
        for element in ['playbin', 'autoaudiosink', 'audioconvert', 'audioresample', 'vorbisdec', 'flacdec', 'mpg123audiodec']:
            if subprocess.run(['gst-inspect-1.0',element], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
                add('gstreamer:'+element, 'present')
    if all(shutil.which(x) for x in ['cmake','c++','make']):
        probe = work/'probe'; probe.mkdir()
        modules = ['Core','Gui','Qml','Quick','QuickControls2','QuickDialogs2','Concurrent','DBus','Network','Sql','Svg','ShaderTools','Core5Compat']
        cm = ['cmake_minimum_required(VERSION 3.21)', 'project(DependencyProbe LANGUAGES CXX)',
              'set(CMAKE_CXX_STANDARD 20)', 'set(CMAKE_CXX_STANDARD_REQUIRED ON)',
              'file(WRITE "${CMAKE_BINARY_DIR}/missing.txt" "")']
        for mod in modules:
            cm += [f'find_package(Qt6{mod} QUIET)', f'if(NOT Qt6{mod}_FOUND)',
                   f'file(APPEND "${{CMAKE_BINARY_DIR}}/missing.txt" "Qt6{mod}|>=6.8|\\n")',
                   f'elseif(Qt6{mod}_VERSION VERSION_LESS "6.8")',
                   f'file(APPEND "${{CMAKE_BINARY_DIR}}/missing.txt" "Qt6{mod}|>=6.8|${{Qt6{mod}_VERSION}}\\n")', 'endif()']
        cm += ['find_package(Qt6Keychain QUIET)', 'if(NOT Qt6Keychain_FOUND)', 'file(APPEND "${CMAKE_BINARY_DIR}/missing.txt" "Qt6Keychain|present|\\n")', 'endif()',
               'if(TARGET Qt6::qmake)', 'get_target_property(QMAKE_PATH Qt6::qmake IMPORTED_LOCATION)',
               'file(WRITE "${CMAKE_BINARY_DIR}/qmake.txt" "${QMAKE_PATH}")', 'endif()',
               'add_executable(cxx20 main.cpp)']
        (probe/'CMakeLists.txt').write_text('\n'.join(cm))
        (probe/'main.cpp').write_text('#include <span>\nint main(){int a[1]{}; return std::span<int>(a)[0];}\n')
        try:
            run(['cmake','-S',str(probe),'-B',str(probe/'build'),'-G','Unix Makefiles'])
            run(['cmake','--build',str(probe/'build')])
        except Failure:
            add('C++20/CMake toolchain', 'working configure and compile', 'probe failed')
        mf = probe/'build/missing.txt'
        if mf.exists():
            for line in mf.read_text().splitlines():
                name, required, installed = line.split('|', 2)
                add(name, required, installed or None)
        qf = probe/'build/qmake.txt'
        if qf.exists():
            qmake = qf.read_text()
            qml = pathlib.Path(run([qmake,'-query','QT_INSTALL_QML']))
            plugins = pathlib.Path(run([qmake,'-query','QT_INSTALL_PLUGINS']))
            for module in ['QtQuick','QtQuick/Effects','Qt5Compat/GraphicalEffects','QtQuick/Controls','QtQuick/Dialogs','QtQuick/Layouts','QtQuick/Window','QtQuick/Templates','QtQml/WorkerScript','QtCore']:
                if not (qml/module/'qmldir').is_file(): add('QML:'+module, 'present')
            for pattern in ['sqldrivers/libqsqlite.so','imageformats/libqsvg.so']:
                if not (plugins/pattern).exists(): add('Qt plugin:'+pattern,'present')
            if not any((plugins/'platforms').glob('libq*wayland*.so')) and not (plugins/'platforms/libqxcb.so').exists():
                add('Qt platform plugin','Wayland or XCB')
        else: add('Qt6 qmake','present for runtime module discovery')
    if missing: fail('DEPENDENCY_UNSATISFIED', 'Required dependencies are missing or incompatible.', dependencies=missing)


def main():
    global action, stage, log_path, log
    args = sys.argv[1:]
    if not args or args[0] not in ['check','install','status','uninstall']: fail('INVALID_ARGUMENT','Expected check, install, status or uninstall.')
    action = args.pop(0); revision = None
    if args:
        if action == 'install' and len(args)==2 and args[0]=='--version': revision=args[1]
        else: fail('INVALID_ARGUMENT','Unexpected arguments.')
    if action == 'install' and (revision is None or not re.fullmatch(r'[0-9a-f]{40}', revision)):
        fail('INVALID_ARGUMENT','--version must be the exact 40-character Git commit SHA from the trusted store catalog.')
    if sys.version_info < (3,9): fail('DEPENDENCY_UNSATISFIED','Python 3.9 or newer is required.',dependencies=[dict(id='python3',required='>=3.9',installed=platform.python_version(),reason='version_too_old')])
    if os.geteuid()==0: fail('PERMISSION_DENIED','Run as the target desktop user, not root.')
    release = {}
    for line in pathlib.Path('/etc/os-release').read_text().splitlines():
        if '=' in line:
            k,v=line.split('=',1); release[k]=v.strip('"')
    if release.get('ID') not in ['arch','ubuntu','debian'] or platform.machine() not in ['x86_64','aarch64']:
        fail('UNSUPPORTED_PLATFORM','Supported platforms: Arch, Ubuntu, Debian; x86_64 or aarch64.')
    home = pathlib.Path.home()
    def xdg(name, fallback):
        p = pathlib.Path(os.environ.get(name, str(home/fallback)))
        if not p.is_absolute(): fail('INVALID_ARGUMENT',name+' must be an absolute path.')
        return p
    data = xdg('XDG_DATA_HOME','.local/share'); state = xdg('XDG_STATE_HOME','.local/state')/'kmusic-installer'
    root = data/'kmusic-app'; current = root/'current'; manifest = root/'manifest.json'
    desktop = data/'applications/kmusic.desktop'; icon = data/'icons/hicolor/scalable/apps/kmusic.svg'
    state.mkdir(parents=True,exist_ok=True)
    lock = (state/'lock').open('a')
    try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    except BlockingIOError: fail('INSTALL_BUSY','Another KMusic installer is running.')
    log_path = str(state/('install-'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S')+'-'+uuid.uuid4().hex[:8]+'.log'))
    log = open(log_path,'w'); os.chmod(log_path,0o600)
    installed = json.loads(manifest.read_text()) if manifest.exists() else None
    if action == 'status':
        emit(success=True,code='OK',installed=bool(installed and current.exists()),version=installed.get('version') if installed else None,logPath=log_path); return
    if action == 'uninstall':
        progress('uninstall')
        if installed:
            for p in [desktop,icon]:
                if p.is_symlink() and str(p.readlink()).startswith(str(root)+'/'): p.unlink()
            if root.is_symlink(): fail('UNINSTALL_FAILED','Installation root must not be a symlink.')
            shutil.rmtree(root)
        emit(success=True,code='OK',changed=bool(installed),dataPreserved=True,logPath=log_path); return
    progress('check')
    with tempfile.TemporaryDirectory(prefix='check-',dir=state) as td:
        dependencies(pathlib.Path(td))
    if action == 'check': emit(success=True,code='OK',distribution=release.get('ID'),architecture=platform.machine(),logPath=log_path); return
    if installed and installed.get('version')==revision and (current/'bin/kmusic').is_file():
        emit(success=True,code='ALREADY_INSTALLED',version=revision,changed=False,desktopId='kmusic.desktop',logPath=log_path); return
    if root.is_symlink(): fail('INSTALL_FAILED','Installation root must not be a symlink.')
    for p in [desktop,icon]:
        if (p.exists() or p.is_symlink()) and not (p.is_symlink() and str(p.readlink()).startswith(str(root)+'/')):
            fail('INSTALL_FAILED','An unmanaged desktop entry or icon already exists; it will not be overwritten.',path=str(p))
    root.mkdir(parents=True,exist_ok=True); (root/'versions').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='stage-',dir=root) as td:
        work = pathlib.Path(td); source=work/'source'; build=work/'build'; dest=work/'payload'
        progress('download')
        run(['git','init',str(source)],code='DOWNLOAD_FAILED')
        run(['git','-C',str(source),'remote','add','origin',REPO],code='DOWNLOAD_FAILED')
        run(['git','-C',str(source),'fetch','--depth=1','origin',revision],code='DOWNLOAD_FAILED')
        run(['git','-C',str(source),'checkout','--detach','FETCH_HEAD'],code='DOWNLOAD_FAILED')
        if run(['git','-C',str(source),'rev-parse','HEAD']) != revision: fail('INTEGRITY_FAILED','Source revision mismatch.')
        run(['git','-C',str(source),'-c','protocol.file.allow=never','submodule','update','--init','--recursive','--depth=1'],code='DOWNLOAD_FAILED')
        submodules = run(['git','-C',str(source),'submodule','status','--recursive'])
        if any(line.startswith(('+','-','U')) for line in submodules.splitlines()): fail('INTEGRITY_FAILED','Submodule revisions do not match the source.')
        progress('build')
        run(['cmake','-S',str(source),'-B',str(build),'-G','Unix Makefiles','-DCMAKE_BUILD_TYPE=Release','-DCMAKE_INSTALL_LIBDIR=lib','-DKMUSIC_BUILD_LOCAL_TESTS=OFF','-DKMUSIC_BUILD_SUBSONIC_TESTS=OFF'],code='BUILD_FAILED')
        run(['cmake','--build',str(build),'--parallel',str(min(4,os.cpu_count() or 1))],code='BUILD_FAILED')
        progress('install')
        run(['cmake','--install',str(build),'--prefix',str(dest)],code='INSTALL_FAILED')
        if not (dest/'bin/kmusic').is_file(): fail('INSTALL_FAILED','Staged executable is missing.')
        # Stable absolute launch path; no PATH assumptions in the desktop entry.
        launcher = str(current/'bin/kmusic').replace('\\','\\\\').replace('"','\\"').replace('`','\\`').replace('$','\\$').replace('%','%%')
        entry = dest/'share/applications/kmusic.desktop'
        entry.write_text(re.sub(r'^Exec=.*$', lambda _: 'Exec="'+launcher+'" %U',entry.read_text(),flags=re.M))
        target = root/'versions'/(revision+'-'+uuid.uuid4().hex[:8]); os.replace(dest,target)
        old = current.readlink() if current.is_symlink() else None
        old_links = {p:p.readlink() if p.is_symlink() else None for p in [desktop,icon]}
        try:
            atomic_link(current,target)
            for p, rel in [(desktop,'share/applications/kmusic.desktop'),(icon,'share/icons/hicolor/scalable/apps/kmusic.svg')]:
                p.parent.mkdir(parents=True,exist_ok=True); atomic_link(p,current/rel)
            atomic_json(manifest,dict(appId=APP,version=revision,previous=str(old) if old else None,submodules=submodules))
        except BaseException:
            if old is not None: atomic_link(current,old)
            elif current.is_symlink(): current.unlink()
            for p,t in old_links.items():
                if t is not None: atomic_link(p,t)
                elif p.is_symlink(): p.unlink()
            raise
        emit(success=True,code='INSTALLED',version=revision,changed=True,desktopId='kmusic.desktop',logPath=log_path)

def entrypoint():
    def interrupted(signum, frame):
        raise KeyboardInterrupt()
    signal.signal(signal.SIGTERM, interrupted)
    try: main()
    except Failure as e:
        emit(success=False,code=e.code,stage=stage,message=e.message,details=e.details,logPath=log_path); sys.exit(CODES[e.code])
    except KeyboardInterrupt:
        emit(success=False,code='CANCELLED',stage=stage,message='Installation cancelled.',logPath=log_path); sys.exit(130)
    except Exception as e:
        code = 'PERMISSION_DENIED' if isinstance(e, PermissionError) else ('UNINSTALL_FAILED' if action=='uninstall' else 'INSTALL_FAILED' if stage=='install' else 'INTERNAL_ERROR')
        if log: log.write(repr(e)+'\n'); log.flush()
        emit(success=False,code=code,stage=stage,message='Operation failed; see the log.',logPath=log_path); sys.exit(CODES[code])

if __name__ == '__main__':
    entrypoint()
