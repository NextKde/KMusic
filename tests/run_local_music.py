#!/usr/bin/env python3
"""Opt-in local backend integration test; leaves the user's running app/data untouched."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--binary', type=Path, default=Path('build/kmusic_local_tests'))
parser.add_argument('--audio-dir', type=Path, required=True)
parser.add_argument('--output-dir', type=Path, default=Path('.task'))
args = parser.parse_args()
audio = args.audio_dir.resolve()
assert len(list(audio.glob('*.ogg'))) == 2, 'Supply the two downloaded Ogg fixtures'
args.output_dir.mkdir(parents=True, exist_ok=True)
run = Path(tempfile.mkdtemp(prefix='local-integration-', dir=args.output_dir.resolve()))
env = os.environ.copy()
env.pop('KOS_MUSIC_FAKE_AUDIO', None)
env.pop('KMUSIC_REVIEW_DIR', None)
env.update(KOS_MUSIC_DATA_DIR=str(run/'data'), KOS_MUSIC_CACHE_DIR=str(run/'cache'),
           XDG_CONFIG_HOME=str(run/'config'), XDG_DATA_HOME=str(run/'xdg-data'),
           XDG_CACHE_HOME=str(run/'xdg-cache'), QT_QPA_PLATFORM='offscreen')
report = {'binary': str(args.binary.resolve()), 'audio': [], 'phases': []}
for path in sorted(audio.glob('*.ogg')):
    report['audio'].append({'name': path.name, 'bytes': path.stat().st_size,
                            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
for phase in ('seed', 'persist'):
    try:
        result = subprocess.run(['dbus-run-session', '--', str(args.binary.resolve()), phase, str(audio)],
                                env=env, capture_output=True, text=True, timeout=120)
        (run/f'{phase}.log').write_text(result.stderr)
        (run/f'{phase}.json').write_text(result.stdout)
        data = json.loads(result.stdout)
        report['phases'].append(data)
        if result.returncode or not data['passed']:
            break
    except Exception as error:
        report['phases'].append({'phase': phase, 'passed': False, 'failure': str(error)})
        break
report['passed'] = len(report['phases']) == 2 and all(p['passed'] for p in report['phases'])
(run/'report.json').write_text(json.dumps(report, indent=2))
print(json.dumps({'passed': report['passed'], 'report': str(run/'report.json'),
                  'checks': sum(len(p.get('checks', [])) for p in report['phases']),
                  'failures': [p.get('failure') for p in report['phases'] if not p['passed']]}, indent=2))
raise SystemExit(0 if report['passed'] else 1)
