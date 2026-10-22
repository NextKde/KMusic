#!/usr/bin/env python3
"""Isolated real/mock server test. No GUI interaction, no real account required."""
import argparse, base64, hashlib, http.server, json, os, secrets, shutil, socket, subprocess, tempfile, threading, time, urllib.parse, urllib.request
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--navidrome');p.add_argument('--gdb',action='store_true');p.add_argument('--audio-dir',required=True);a=p.parse_args()
repo=Path(__file__).resolve().parents[1]; root=Path(tempfile.mkdtemp(prefix='subsonic-test-',dir=repo/'.task'))
for d in ['music','server','data','cache','config','xdg-data','xdg-cache']:(root/d).mkdir()
password=secrets.token_hex(16); user='admin'
# Re-encode a fixture copy with deterministic tags; original downloaded music is untouched.
fixture=next(Path(a.audio_dir).glob('*.ogg'))
for n in (1,2):
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(fixture),'-t','20','-metadata',f'title=Fixture {n}','-metadata','artist=Test Artist','-metadata','album=Test Album',str(root/'music'/f'{n}.flac')],check=True)
subprocess.run(['ffmpeg','-v','error','-y','-f','lavfi','-i','color=c=blue:s=64x64','-frames:v','1',str(root/'music'/'cover.jpg')],check=True)
env=os.environ.copy();env.update(QT_QPA_PLATFORM='offscreen',KOS_MUSIC_DATA_DIR=str(root/'data'),KOS_MUSIC_CACHE_DIR=str(root/'cache'),XDG_CONFIG_HOME=str(root/'config'),XDG_DATA_HOME=str(root/'xdg-data'),XDG_CACHE_HOME=str(root/'xdg-cache'),SUBSONIC_TEST_PASSWORD=password,SUBSONIC_TEST_USER=user)
requests=[];process=None;server=None
try:
 if a.navidrome:
  with socket.socket() as sock:sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
  server_env=os.environ.copy();server_env.update(ND_DEVAUTOCREATEADMINPASSWORD=password,ND_ENABLEEXTERNALSERVICES='false',ND_SCANSCHEDULE='@every 1h',ND_LOGLEVEL='error')
  log=open(root/'server.log','w')
  process=subprocess.Popen([str(Path(a.navidrome).resolve()),'--address','127.0.0.1','--port',str(port),'--datafolder',str(root/'server'),'--musicfolder',str(root/'music'),'--nobanner'],env=server_env,stdout=log,stderr=log)
  base=f'http://127.0.0.1:{port}'
  for _ in range(120):
   try:
    q=urllib.parse.urlencode(dict(u=user,p=password,v='1.16.1',c='test',f='json',type='alphabeticalByName'))
    data=json.load(urllib.request.urlopen(base+'/rest/getAlbumList2.view?'+q,timeout=1))
    if data.get('subsonic-response',{}).get('albumList2',{}).get('album'):break
   except Exception:pass
   time.sleep(.5)
  else:raise RuntimeError('Temporary Navidrome did not finish initialization; see isolated server.log')
 else:
  env['SUBSONIC_MOCK']='1'
  class Handler(http.server.BaseHTTPRequestHandler):
   def log_message(self,*args):pass
   def do_GET(self):
    parsed=urllib.parse.urlsplit(self.path);q={k:v[0] for k,v in urllib.parse.parse_qs(parsed.query,keep_blank_values=True).items()};method=parsed.path.split('/')[-1].replace('.view','');requests.append(method)
    valid=q.get('u')==user and q.get('t')==hashlib.md5((password+q.get('s','')).encode()).hexdigest()
    rootjson={'status':'ok','version':'1.16.1'}
    songs=[dict(id=str(n),title=f'Fixture {n}',artist='Test Artist',album='Test Album',duration=20,suffix='flac',coverArt='cover') for n in (1,2)]
    blob=None;ctype='application/json'
    if not valid:rootjson={'status':'failed','error':{'code':40,'message':'Wrong credentials'}}
    elif method=='getAlbumList2':rootjson['albumList2']={'album':[dict(id=str(n),name=f'Album {n}',artist='Test Artist',coverArt='cover') for n in range(int(q.get('offset',0)),min(51,int(q.get('offset',0))+int(q.get('size',50))))]}
    elif method=='getAlbum':rootjson['album']={'song':songs}
    elif method=='search3':rootjson['searchResult3']={'song':[] if q.get('query')=='__no_match_fixture__' else songs}
    elif method=='getCoverArt':blob=(root/'music'/'cover.jpg').read_bytes();ctype='image/jpeg'
    elif method=='stream':blob=(root/'music'/(q['id']+'.flac')).read_bytes();ctype='audio/flac'
    elif method!='ping':rootjson={'status':'failed','error':{'code':70}}
    if blob is None:blob=json.dumps({'subsonic-response':rootjson}).encode()
    self.send_response(200);self.send_header('Content-Type',ctype);self.send_header('Content-Length',str(len(blob)));self.end_headers();self.wfile.write(blob)
  server=http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler);threading.Thread(target=server.serve_forever,daemon=True).start();base=f'http://127.0.0.1:{server.server_port}'
 env['SUBSONIC_TEST_URL']=base
 with open(root/'report.json','w') as output, open(root/'client.log','w') as errors:
  result=subprocess.run(['dbus-run-session','--'] + (['gdb','-batch','-ex','run','-ex','bt','--args'] if a.gdb else []) + [str(repo/'build/kmusic_subsonic_tests')],env=env,text=True,stdout=output,stderr=errors,timeout=180)
 result.stdout=(root/'report.json').read_text();result.stderr=(root/'client.log').read_text()
 (root/'report.json').write_text(result.stdout);(root/'client.log').write_text(result.stderr.replace(password,'[REDACTED]'))
 (root/'requests.json').write_text(json.dumps(requests))
 print(root);print(result.stdout)
 if result.returncode:print(result.stderr[-1500:].replace(password,'[REDACTED]'))
 if result.returncode == 0 and not a.gdb:
  env['SUBSONIC_RESUME']='1'
  with open(root/'restart-report.json','w') as output, open(root/'restart.log','w') as errors:
   resumed=subprocess.run(['dbus-run-session','--',str(repo/'build/kmusic_subsonic_tests')],env=env,text=True,stdout=output,stderr=errors,timeout=90)
  resumed.stdout=(root/'restart-report.json').read_text();resumed.stderr=(root/'restart.log').read_text()
  (root/'restart-report.json').write_text(resumed.stdout);print(resumed.stdout)
  if resumed.returncode:print(resumed.stderr[-1500:].replace(password,'[REDACTED]'))
  raise SystemExit(resumed.returncode)
 raise SystemExit(result.returncode)
finally:
 if process:
  process.terminate()
  try:process.wait(timeout=10)
  except subprocess.TimeoutExpired:process.kill();process.wait()
 if server:server.shutdown()
