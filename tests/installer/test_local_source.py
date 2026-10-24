"""VM/CI only. Real Git/CMake fixture; no KMusic GUI, account or network access."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import hashlib
import shutil
import tempfile
import unittest
from unittest.mock import patch
from source_copy import copy_checkout

spec = importlib.util.spec_from_file_location('local_installer', Path(__file__).resolve().parents[2] / 'packaging/installer.py')
i = importlib.util.module_from_spec(spec)
spec.loader.exec_module(i)

class LocalSourceInstall(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kmusic-local-test-')
        self.base = Path(self.temp.name)
        self.source = self.base / 'source with spaces'
        self.source.mkdir()
        self.env = {'XDG_DATA_HOME': str(self.base/'data'), 'XDG_STATE_HOME': str(self.base/'state')}
        self.root = self.base/'data/kmusic-app'
        self.calls = []
        self.git(self.source, 'init', '-q')
        self.git(self.source, 'config', 'user.name', 'Installer Test')
        self.git(self.source, 'config', 'user.email', 'installer@example.invalid')
        vendor = self.source/'vendor/nextkdeAppDemo'
        (vendor/'shared/qml').mkdir(parents=True)
        (vendor/'shared/qml/CMakeLists.txt').write_text('# pinned fixture\n')
        (vendor/'LICENSE').write_text('fixture license\n')
        files_hash = {name: hashlib.sha256((vendor/name).read_bytes()).hexdigest()
                      for name in ['LICENSE', 'shared/qml/CMakeLists.txt']}
        (vendor/'vendor-manifest.json').write_text(json.dumps(dict(schemaVersion=1,
            repository='https://github.com/NextKde/nextkdeAppDemo.git', revision='a'*40, files=files_hash)))
        (self.source/'tools').mkdir()
        shutil.copyfile(Path(__file__).resolve().parents[2]/'tools/vendor_components.py', self.source/'tools/vendor_components.py')
        files = {
            'src/main.cpp': '// fixture\n',
            'providers/runtime/helper.js': '// fixture\n',
            'data/kmusic.desktop': '[Desktop Entry]\nExec=kmusic %U\n',
            'data/kmusic.svg': '<svg/>',
            'CMakeLists.txt': '''cmake_minimum_required(VERSION 3.21)
project(InstallerFixture NONE)
file(WRITE "${CMAKE_BINARY_DIR}/kmusic" "#!/bin/sh\\nexit 0\\n")
install(PROGRAMS "${CMAKE_BINARY_DIR}/kmusic" DESTINATION bin)
install(FILES data/kmusic.desktop DESTINATION share/applications)
install(FILES data/kmusic.svg DESTINATION share/icons/hicolor/scalable/apps)
'''}
        for name, text in files.items():
            p = self.source/name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)
        self.commit()
        self.real_run = i.run
        self.stack = contextlib.ExitStack()
        for p in [patch.dict(os.environ, self.env), patch.object(i.os, 'geteuid', return_value=1000),
                  patch.object(i, 'dependencies'), patch.object(i, 'run', side_effect=self.guarded_run)]:
            self.stack.enter_context(p)

    def tearDown(self):
        if i.log:
            i.log.close()
            i.log = None
        self.stack.close()
        self.temp.cleanup()

    def git(self, directory, *args):
        return subprocess.check_output(['git', '-C', str(directory), *args], stderr=subprocess.STDOUT, text=True).strip()

    def commit(self):
        self.git(self.source, 'add', '.')
        self.git(self.source, 'commit', '-qm', 'fixture source')
        return self.git(self.source, 'rev-parse', 'HEAD')

    def guarded_run(self, args, **kwargs):
        self.calls.append(args)
        if args[0] == 'git':
            self.assertFalse(any(x in args for x in ['fetch', 'clone', 'pull', 'checkout']), args)
            self.assertFalse('submodule' in args and 'update' in args, args)
        return self.real_run(args, **kwargs)

    def invoke(self, *args):
        i.action = 'unknown'; i.stage = 'arguments'; i.log_path = None
        output = io.StringIO()
        code = 0
        with patch.object(i.sys, 'argv', ['install.sh', *args]), contextlib.redirect_stdout(output):
            try:
                i.entrypoint()
            except SystemExit as e:
                code = e.code
        if i.log:
            i.log.close(); i.log = None
        records = [json.loads(line) for line in output.getvalue().splitlines()]
        results = [r for r in records if r['type'] == 'result']
        self.assertEqual(len(results), 1)
        result = results[0]
        self.assertEqual(result['schemaVersion'], 1)
        self.assertEqual(result['success'], code == 0)
        self.assertFalse(any(r.get('stage') == 'download' for r in records))
        return code, result

    def install(self):
        return self.invoke('install', '--source-dir', str(self.source))

    def test_local_install_update_status_uninstall_preserves_data(self):
        # CWD-relative '.', spaces, actual configure/build/install, and atomic links.
        previous = os.getcwd()
        try:
            os.chdir(self.source)
            self.assertEqual(self.invoke('install', '--source-dir', '.')[1]['code'], 'INSTALLED')
        finally:
            os.chdir(previous)
        current = (self.root/'current').resolve()
        self.assertTrue((current/'bin/kmusic').is_file())
        desktop = self.base/'data/applications/kmusic.desktop'
        self.assertIn('Exec="'+str(self.root/'current/bin/kmusic')+'" %U', desktop.read_text())
        manifest = json.loads((self.root/'manifest.json').read_text())
        self.assertEqual(manifest['sourceType'], 'local')
        self.assertEqual(manifest['components']['Kos.Ui']['revision'], 'a'*40)
        self.assertEqual(self.git(self.source, 'ls-files', '--stage', 'vendor').count('160000'), 0)
        self.assertEqual(self.invoke('status')[1]['version'], manifest['version'])
        self.assertEqual(self.install()[1]['code'], 'ALREADY_INSTALLED')
        (self.source/'src/main.cpp').write_text('// updated fixture\n')
        new = self.commit()
        self.assertEqual(self.install()[1]['version'], new)
        self.assertTrue(current.exists())
        self.assertNotEqual((self.root/'current').resolve(), current)
        user_data = self.base/'data/kmusic/library.db'
        user_data.parent.mkdir(); user_data.write_text('keep')
        self.assertTrue(self.invoke('uninstall')[1]['dataPreserved'])
        self.assertFalse(self.root.exists())
        self.assertFalse(desktop.is_symlink())
        self.assertEqual(user_data.read_text(), 'keep')
        self.assertFalse(self.invoke('status')[1]['installed'])
        self.assertFalse(self.invoke('uninstall')[1]['changed'])

    def test_ci_checkout_copy_preserves_tracked_symlinks_and_clean_status(self):
        (self.source/'src/main-link.cpp').symlink_to('main.cpp')
        self.commit()
        copied = self.base/'copied source'
        copy_checkout(self.source, copied)
        self.assertTrue((copied/'src/main-link.cpp').is_symlink())
        self.assertEqual(self.git(copied, 'status', '--porcelain', '--untracked-files=no'), '')

    def test_missing_path_and_conflicting_arguments(self):
        self.assertEqual(self.invoke('install', '--source-dir', str(self.base/'absent'))[0], 2)
        self.assertEqual(self.invoke('install', '--source-dir', str(self.source), '--version', 'a'*40)[0], 2)
        self.assertEqual(self.invoke('status', '--source-dir', str(self.source))[0], 2)

    def test_non_repository_and_subdirectory_fail(self):
        self.assertEqual(self.invoke('install', '--source-dir', str(self.base))[0], 21)
        self.assertEqual(self.invoke('install', '--source-dir', str(self.source/'src'))[0], 2)

    def test_dirty_source_and_missing_provider_fail(self):
        (self.source/'src/main.cpp').write_text('// uncommitted\n')
        self.assertEqual(self.install()[0], 21)
        (self.source/'providers/runtime/helper.js').unlink()
        self.assertEqual(self.install()[0], 21)
        self.assertFalse(self.root.exists())

    def test_missing_bundled_component_is_not_downloaded(self):
        (self.source/'vendor/nextkdeAppDemo/shared/qml/CMakeLists.txt').unlink()
        self.commit()
        self.assertEqual(self.install()[0], 21)
        self.assertFalse(self.root.exists())

    def test_committed_component_change_without_sync_manifest_is_rejected(self):
        (self.source/'vendor/nextkdeAppDemo/shared/qml/CMakeLists.txt').write_text('# changed without sync\n')
        self.commit()
        self.assertEqual(self.install()[0], 21)

    def test_manifest_revision_or_extra_file_is_rejected(self):
        manifest = self.source/'vendor/nextkdeAppDemo/vendor-manifest.json'
        data = json.loads(manifest.read_text()); data['revision'] = 'main'
        manifest.write_text(json.dumps(data)); self.commit()
        self.assertEqual(self.install()[0], 21)
        data['revision'] = 'a'*40; manifest.write_text(json.dumps(data))
        (manifest.parent/'unexpected.qml').write_text('Item {}')
        self.commit()
        self.assertEqual(self.install()[0], 21)

    def test_committed_incomplete_source_is_rejected(self):
        (self.source/'providers/runtime/helper.js').unlink()
        self.commit()
        self.assertEqual(self.install()[0], 21)
        self.assertFalse(self.root.exists())

    def test_dependency_failure_is_uniform(self):
        with patch.object(i, 'dependencies', side_effect=i.Failure('DEPENDENCY_UNSATISFIED', 'fixture', {'dependencies': [{'id':'Qt6Core'}]})):
            code, result = self.install()
        self.assertEqual(code, 11)
        self.assertEqual(result['details']['dependencies'][0]['id'], 'Qt6Core')
        self.assertFalse(self.root.exists())

    def test_failed_update_preserves_existing_install(self):
        self.assertEqual(self.install()[0], 0)
        before = (self.root/'manifest.json').read_bytes()
        old = (self.root/'current').resolve()
        (self.source/'src/main.cpp').write_text('// new revision\n'); self.commit()
        guard = self.guarded_run
        def failed_build(args, **kwargs):
            if args[:2] == ['cmake', '--build']:
                i.fail('BUILD_FAILED', 'injected compile failure')
            return guard(args, **kwargs)
        with patch.object(i, 'run', side_effect=failed_build):
            self.assertEqual(self.install()[0], 30)
        self.assertEqual((self.root/'manifest.json').read_bytes(), before)
        self.assertEqual((self.root/'current').resolve(), old)

if __name__ == '__main__':
    unittest.main()
