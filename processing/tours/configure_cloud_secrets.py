"""FUTURE explicit Secret Manager/Edge setup; no cron or Vault activation."""
import argparse
import json
from pathlib import Path
import os
import subprocess
import tempfile
from local_runner import read_config

parser=argparse.ArgumentParser();parser.add_argument('--run',action='store_true');parser.add_argument('--dispatcher-key',type=Path,required=True);args=parser.parse_args()
if not args.run:parser.exit(message='Add --run only after billing and IAM are ready.\n')
root=Path(__file__).resolve().parents[2];config=read_config(root/'config/.env.tours-local');project='marea-f6a92'
if args.dispatcher_key.stat().st_mode & 0o077:raise SystemExit('Dispatcher key must have restricted permissions 0600')
account=json.loads(args.dispatcher_key.read_text())
if account.get('project_id')!=project or account.get('client_email')!='marea-tour-dispatch@'+project+'.iam.gserviceaccount.com':raise SystemExit('Wrong dispatcher project or service account')
result=subprocess.run(['gcloud','billing','projects','describe',project,'--format=value(billingEnabled)'],capture_output=True,text=True,check=True)
if result.stdout.strip()!='True':raise SystemExit('Active billing is required')
subprocess.run(['gcloud','services','enable','secretmanager.googleapis.com','--project',project],check=True)
for name,key in [('marea-supabase-url','SUPABASE_URL'),('marea-supabase-service-role','SUPABASE_SERVICE_ROLE_KEY'),('marea-tour-worker-secret','TOUR_WORKER_SECRET')]:
    existing=subprocess.run(['gcloud','secrets','describe',name,'--project',project],capture_output=True)
    if existing.returncode:subprocess.run(['gcloud','secrets','create',name,'--replication-policy=automatic','--project',project],check=True)
    # Secret bytes on stdin, never arguments or stdout.
    result=subprocess.run(['gcloud','secrets','versions','add',name,'--data-file=-','--project',project],input=config[key].encode(),capture_output=True)
    if result.returncode:raise SystemExit('Secret Manager update failed; output withheld')
fd,path=tempfile.mkstemp(prefix='marea-tour-google-',suffix='.env')
try:
    os.fchmod(fd,0o600)
    with os.fdopen(fd,'w') as stream:
        stream.write('TOUR_GOOGLE_SERVICE_ACCOUNT_JSON='+json.dumps(account,separators=(',',':'))+'\nTOUR_WORKER_SECRET='+config['TOUR_WORKER_SECRET']+'\n')
    ref=config['SUPABASE_URL'].split('//')[1].split('.')[0]
    result=subprocess.run(['supabase','secrets','set','--project-ref',ref,'--env-file',path],capture_output=True)
    if result.returncode:raise SystemExit('Edge configuration failed; output withheld')
finally:os.unlink(path)
print('Cloud secrets configured. Tours cron and Vault remain inactive; verify a real execution first.')
