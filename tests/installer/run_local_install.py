#!/usr/bin/env python3
"""Real app local-source lifecycle; only run inside disposable provisioned CI/VM."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

p = argparse.ArgumentParser()
p.add_argument('--source', required=True)
p.add_argument('--results', required=True)
p.add_argument('--reject-dependencies', action='store_true')
a = p.parse_args()
source = Path(a.source).resolve()
results = Path(a.results).resolve(); results.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='kmusic-real-local-') as td:
    work = Path(td)
    # Installer never receives the remote URL; source was prepared by CI checkout.
    checkout = work/'source'
    shutil.copytree(source, checkout, ignore=shutil.ignore_patterns('results', 'kos-tests', 'build', '.task', '__pycache__'))
    shim = work/'tools'; shim.mkdir()
    real_git = shutil.which('git')
    (shim/'git').write_text('#!/usr/bin/env python3\nimport os,sys\na=sys.argv[1:]\n'
        'if any(x in a for x in ["fetch","clone","pull","checkout"]) or ("submodule" in a and "update" in a):\n'
        ' print("Forbidden source download/mutation",file=sys.stderr);sys.exit(98)\n'
        'os.execv('+repr(real_git)+', ['+repr(real_git)+']+a)\n')
    (shim/'git').chmod(0o755)
    env = dict(os.environ, XDG_DATA_HOME=str(work/'data'), XDG_STATE_HOME=str(work/'state'), PATH=str(shim)+os.pathsep+os.environ['PATH'])
    records = []
    def call(name, args, expected):
        proc = subprocess.run(['sh', str(checkout/'install.sh'), *args], cwd=checkout, env=env, capture_output=True, text=True)
        (results/(name+'.jsonl')).write_text(proc.stdout)
        (results/(name+'.stderr')).write_text(proc.stderr)
        rows = [json.loads(line) for line in proc.stdout.splitlines()]
        result = [r for r in rows if r['type'] == 'result']
        assert len(result) == 1 and result[0]['code'] == expected, (name, proc.returncode, proc.stdout, proc.stderr)
        assert (proc.returncode == 0) == result[0]['success']
        assert not any(r.get('stage') == 'download' for r in rows)
        if result[0].get('logPath'):
            shutil.copyfile(result[0]['logPath'], results/(name+'.log'))
        records.append({'case':name, 'result':expected})
        return result[0]
    if a.reject_dependencies:
        call('local-missing-dependency', ['install','--source-dir','.'], 'DEPENDENCY_UNSATISFIED')
        assert not (work/'data/kmusic-app').exists()
    else:
        call('local-install', ['install','--source-dir','.'], 'INSTALLED')
        root = work/'data/kmusic-app'
        assert (root/'current/bin/kmusic').is_file()
        manifest = json.loads((root/'manifest.json').read_text())
        assert manifest['sourceType'] == 'local'
        assert manifest['version'] == subprocess.check_output([real_git,'-C',str(checkout),'rev-parse','HEAD'], text=True).strip()
        call('local-repeat', ['install','--source-dir','.'], 'ALREADY_INSTALLED')
        assert call('local-status', ['status'], 'OK')['installed']
        user_data = work/'data/kmusic/keep.txt'; user_data.parent.mkdir(); user_data.write_text('preserve')
        call('local-uninstall', ['uninstall'], 'OK')
        assert not root.exists() and user_data.read_text() == 'preserve'
        assert not (work/'data/applications/kmusic.desktop').is_symlink()
        assert not (work/'data/icons/hicolor/scalable/apps/kmusic.svg').is_symlink()
        assert not call('local-removed-status', ['status'], 'OK')['installed']
        call('local-uninstall-again', ['uninstall'], 'OK')
    (results/'summary.json').write_text(json.dumps(records, indent=2)+'\n')
