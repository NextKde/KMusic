#!/usr/bin/env python3
"""Import an exact Kos.Ui Git revision, or check the committed offline snapshot."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

REPO = 'https://github.com/NextKde/nextkdeAppDemo.git'
DEST = Path(__file__).resolve().parents[1] / 'vendor/nextkdeAppDemo'
MANIFEST = 'vendor-manifest.json'


def validate_snapshot(root):
    root = Path(root)
    manifest = json.loads((root / MANIFEST).read_text())
    if manifest.get('schemaVersion') != 1 or manifest.get('repository') != REPO or not re.fullmatch(r'[0-9a-f]{40}', manifest.get('revision', '')):
        raise ValueError('Invalid component provenance')
    files = manifest.get('files', {})
    if not files or 'LICENSE' not in files or 'shared/qml/CMakeLists.txt' not in files:
        raise ValueError('Incomplete component manifest')
    actual = {p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() or p.is_symlink()}
    if actual != set(files) | {MANIFEST}:
        raise ValueError('Vendored file set differs from the manifest')
    for name, digest in files.items():
        path = root / name
        if path.is_symlink() or not path.resolve().is_relative_to(root.resolve()):
            raise ValueError('Unexpected component link/path: ' + name)
        if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise ValueError('Modified or missing component: ' + name)
    return manifest


def import_revision(source, revision):
    if not re.fullmatch(r'[0-9a-f]{40}', revision):
        raise ValueError('Use a full lowercase 40-character commit SHA')
    source = Path(source).resolve()
    def git(*args):
        return subprocess.check_output(['git', '-C', str(source), *args])
    origin = git('remote', 'get-url', 'origin').decode().strip()
    if origin not in [REPO, 'git@github.com:NextKde/nextkdeAppDemo.git']:
        raise ValueError('Upstream origin must be NextKde/nextkdeAppDemo')
    if git('rev-parse', revision + '^{commit}').decode().strip() != revision:
        raise ValueError('Revision is not an exact commit')
    entries = git('ls-tree', '-rz', revision, '--', 'shared/qml', 'LICENSE', 'NOTICE.md').split(b'\0')
    with tempfile.TemporaryDirectory(prefix='kos-ui-import-', dir=DEST.parent) as td:
        snapshot = Path(td) / 'snapshot'; snapshot.mkdir()
        files = {}
        for entry in entries:
            if not entry:
                continue
            info, name = entry.split(b'\t', 1)
            mode, kind, oid = info.decode().split()
            name = name.decode()
            if mode != '100644' or kind != 'blob':
                raise ValueError('Unsupported upstream file type: ' + name)
            data = git('cat-file', 'blob', oid)
            target = snapshot / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            files[name] = hashlib.sha256(data).hexdigest()
        (snapshot / MANIFEST).write_text(json.dumps(dict(schemaVersion=1, repository=REPO,
            revision=revision, files=dict(sorted(files.items()))), indent=2) + '\n')
        validate_snapshot(snapshot)
        if (DEST / '.git').exists():
            raise ValueError('Remove the old submodule before importing; refusing to overwrite a Git checkout')
        if DEST.exists():
            validate_snapshot(DEST)  # Never silently overwrite a downstream hand edit.
            shutil.rmtree(DEST)
        shutil.move(str(snapshot), DEST)
    print('Imported Kos.Ui ' + revision + ' (' + str(len(files)) + ' files)')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--upstream-dir', type=Path)
    parser.add_argument('--revision')
    args = parser.parse_args()
    if args.check:
        if args.upstream_dir or args.revision:
            parser.error('--check cannot be combined with import arguments')
        result = validate_snapshot(DEST)
        print('Kos.Ui snapshot matches manifest: ' + result['revision'])
    else:
        if not args.upstream_dir or not args.revision:
            parser.error('Import requires --upstream-dir and --revision')
        import_revision(args.upstream_dir, args.revision)


if __name__ == '__main__':
    main()
