"""Retrieve existing CLI administrative access into an ignored, restricted file."""
import json
import os
from pathlib import Path
import secrets
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
public=json.loads((root/'config/supabase.production.json').read_text())
ref=public['SUPABASE_URL'].split('//')[1].split('.')[0]
result=subprocess.run(['supabase','projects','api-keys','--project-ref',ref,'--output','json'],capture_output=True,text=True,check=True)
rows=json.loads(result.stdout)
key=next(row['api_key'] for row in rows if row['name']=='service_role')
path=root/'config/.env.tours-local'
ignored=subprocess.run(['git','check-ignore','--quiet',str(path)],cwd=root)
if ignored.returncode:raise SystemExit('Credential destination must be ignored by Git')
secret=secrets.token_urlsafe(48)
if path.exists():
    if path.stat().st_mode & 0o077:raise SystemExit('Existing config permissions must be 0600')
    for line in path.read_text().splitlines():
        if line.startswith('TOUR_WORKER_SECRET='):secret=line.partition('=')[2]
if len(secret)<32:raise SystemExit('Existing worker secret invalid')
fd,temporary=tempfile.mkstemp(dir=path.parent,prefix='.env.tours-')
try:
    os.fchmod(fd,0o600)
    with os.fdopen(fd,'w') as stream:
        stream.write(f'SUPABASE_URL={public["SUPABASE_URL"]}\nSUPABASE_SERVICE_ROLE_KEY={key}\nTOUR_WORKER_SECRET={secret}\n')
    os.replace(temporary,path)
finally:
    if os.path.exists(temporary):os.unlink(temporary)
# Set only the dispatcher secret. No Google credentials, Vault or cron changes.
fd,temporary=tempfile.mkstemp(prefix='marea-tour-edge-',suffix='.env')
try:
    os.fchmod(fd,0o600)
    with os.fdopen(fd,'w') as stream:stream.write('TOUR_WORKER_SECRET='+secret+'\n')
    result=subprocess.run(['supabase','secrets','set','--project-ref',ref,'--env-file',temporary],capture_output=True,text=True)
    if result.returncode:raise SystemExit('Edge secret setup failed; CLI output withheld')
finally:os.unlink(temporary)
print('Local server configuration saved with mode 0600; dispatcher secret set. No values printed.')
