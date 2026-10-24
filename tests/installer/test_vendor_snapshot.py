"""VM/CI only: exact-revision imports and downstream modification protection."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('vendor_tool', Path(__file__).resolve().parents[2]/'tools/vendor_components.py')
v = importlib.util.module_from_spec(spec); spec.loader.exec_module(v)

class VendorSnapshot(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.upstream = self.root/'upstream'; self.upstream.mkdir()
        self.dest = self.root/'vendor/kos-ui'; self.dest.parent.mkdir()
        self.pin = patch.object(v, 'DEST', self.dest); self.pin.start()
        self.git('init', '-q')
        self.git('remote', 'add', 'origin', v.REPO)
        self.git('config', 'user.name', 'Snapshot Test')
        self.git('config', 'user.email', 'snapshot@example.invalid')
        for name, content in {'LICENSE':'license', 'NOTICE.md':'provenance', 'shared/qml/CMakeLists.txt':'# build',
                              'shared/qml/Control.qml':'Item {}', 'demo/gallery.qml':'EXCLUDED'}.items():
            p = self.upstream/name; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(content)
        self.git('add', '.'); self.git('commit', '-qm', 'upstream')
        self.revision = self.git('rev-parse', 'HEAD')

    def tearDown(self):
        self.pin.stop(); self.temp.cleanup()

    def git(self, *args):
        return subprocess.check_output(['git','-C',str(self.upstream),*args], text=True, stderr=subprocess.STDOUT).strip()

    def import_pin(self):
        v.import_revision(self.upstream, self.revision)

    def test_exact_import_no_demo_or_git_and_repeat_is_identical(self):
        self.import_pin()
        manifest = v.validate_snapshot(self.dest)
        self.assertEqual(manifest['revision'], self.revision)
        self.assertEqual((self.dest/'LICENSE').read_text(), 'license')
        self.assertFalse((self.dest/'demo').exists())
        self.assertFalse((self.dest/'.git').exists())
        before = (self.dest/v.MANIFEST).read_bytes()
        self.import_pin()
        self.assertEqual((self.dest/v.MANIFEST).read_bytes(), before)

    def test_other_upstream_repository_is_rejected(self):
        self.git('remote', 'set-url', 'origin', 'https://example.invalid/other.git')
        with self.assertRaises(ValueError): self.import_pin()
        self.assertFalse(self.dest.exists())

    def test_ref_name_is_rejected(self):
        with self.assertRaises(ValueError):
            v.import_revision(self.upstream, 'main')
        self.assertFalse(self.dest.exists())

    def test_modified_downstream_is_not_overwritten(self):
        self.import_pin()
        control = self.dest/'shared/qml/Control.qml'; control.write_text('local edit')
        with self.assertRaises(ValueError):
            self.import_pin()
        self.assertEqual(control.read_text(), 'local edit')

    def test_missing_and_extra_files_are_detected(self):
        self.import_pin()
        extra = self.dest/'extra.qml'; extra.write_text('extra')
        with self.assertRaises(ValueError): v.validate_snapshot(self.dest)
        extra.unlink(); (self.dest/'LICENSE').unlink()
        with self.assertRaises(ValueError): v.validate_snapshot(self.dest)

    def test_upstream_worktree_changes_are_not_imported(self):
        (self.upstream/'shared/qml/Control.qml').write_text('uncommitted')
        self.import_pin()
        self.assertEqual((self.dest/'shared/qml/Control.qml').read_text(), 'Item {}')

    def test_upstream_symlink_is_rejected_without_replacing_snapshot(self):
        self.import_pin(); before = (self.dest/v.MANIFEST).read_bytes()
        (self.upstream/'shared/qml/alias.qml').symlink_to('Control.qml')
        self.git('add', '.'); self.git('commit', '-qm', 'link')
        with self.assertRaises(ValueError): v.import_revision(self.upstream, self.git('rev-parse', 'HEAD'))
        self.assertEqual((self.dest/v.MANIFEST).read_bytes(), before)

if __name__ == '__main__':
    unittest.main()
