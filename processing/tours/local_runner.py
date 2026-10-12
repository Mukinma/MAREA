"""Temporary Docker consumer of the production Supabase queue; no Flutter secrets."""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import hmac
import json
import os
from pathlib import Path
import signal
import subprocess
import threading
import time
import uuid
from worker import Backend, TourError, valid_uuid

STOP=threading.Event()

def read_config(path):
    path=path.resolve()
    if path.stat().st_mode & 0o077:
        raise ValueError('Local credential file must have permissions 0600')
    values={}
    for line in path.read_text().splitlines():
        if line and not line.startswith('#'):
            key,sep,value=line.partition('=')
            if not sep:raise ValueError('Invalid environment file')
            values[key]=value
    for key in ('SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY','TOUR_WORKER_SECRET'):
        if not values.get(key):raise ValueError('Missing server configuration: '+key)
    if len(values['TOUR_WORKER_SECRET'])<32:raise ValueError('Invalid worker secret')
    return values

def docker_arguments(job, env_file, image, secret, name):
    ident,lease=valid_uuid(job['id']),valid_uuid(job['lease_id'])
    proof=hmac.new(secret.encode(),f'{ident}:{lease}'.encode(),hashlib.sha256).hexdigest()
    return ['docker','run','--rm','--platform','linux/amd64','--name',name,
            '--cpus','4','--memory','8g','--memory-swap','8g',
            '--env-file',str(env_file),'--security-opt','no-new-privileges',image,
            '--job',ident,'--lease',lease,'--proof',proof]

def verify_result(backend, job, exit_code):
    # Only the durable receipt for this exact lease proves successful completion.
    receipt=backend.receipt(job['id'],job['lease_id'])
    if receipt and receipt.get('committed') and receipt.get('result'):
        return {'state':'ready','result':receipt['result'],'container_exit':exit_code}
    current=backend.current(job['id'],job['lease_id'])
    return {'state':'unresolved' if current else 'not_ready','container_exit':exit_code}

def log(event,**data):
    print(json.dumps({'component':'marea_tour_local_runner','event':event,**data}),flush=True)

def container_stopped(name):
    try:
        status=subprocess.run(['docker','inspect','--format','{{.State.Running}}',name],capture_output=True,text=True,timeout=10)
    except (OSError,subprocess.SubprocessError):return False
    return (status.returncode==0 and status.stdout.strip()=='false') or (status.returncode==1 and 'No such object:' in status.stderr)

def stop_container(name):
    for action in (['stop','--time','5'],['kill']):
        try:subprocess.run(['docker',*action,name],capture_output=True,timeout=15)
        except (OSError,subprocess.SubprocessError):pass
        if container_stopped(name):return True
    return False

def run_one(job,env_file,image,config):
    name='marea-tour-'+job['id'][:8]+'-'+uuid.uuid4().hex[:8]
    # Thread-local requests sessions: independent leases/connections.
    backend=Backend(config['SUPABASE_URL'],config['SUPABASE_SERVICE_ROLE_KEY'])
    if not backend.current(job['id'],job['lease_id']):return {'state':'not_ready'}
    started=time.monotonic();failure=None
    with subprocess.Popen(docker_arguments(job,env_file,image,config['TOUR_WORKER_SECRET'],name),
                          stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True) as process:
        def drain():
            for line in process.stdout:
                # Emit only known structured worker events; never echo CLI/env diagnostics.
                try:
                    item=json.loads(line)
                    if item.get('component')=='marea_tour_worker':print(json.dumps(item),flush=True)
                except (ValueError,AttributeError):pass
        output=threading.Thread(target=drain,daemon=True);output.start()
        while process.poll() is None:
            if STOP.is_set() or time.monotonic()-started>=900:
                failure='timeout' if not STOP.is_set() else 'dispatch_unavailable'
                stop_container(name)
                try:process.wait(timeout=10)
                except subprocess.TimeoutExpired:process.kill();process.wait()
                break
            STOP.wait(.5)
        output.join(timeout=3);code=process.returncode
    result=verify_result(backend,job,code)
    if result['state']=='unresolved' and container_stopped(name):
        # Confirm the container stopped first. If Docker is unreachable, retain
        # the lease for bounded recovery rather than duplicate an execution.
        backend.finish(job['id'],job['lease_id'],'retry',error=failure or 'dispatch_unavailable')
        result=verify_result(backend,job,code)
    log('checked',job_id=job['id'],elapsed_seconds=round(time.monotonic()-started,3),**result)
    return result

def cycle(env_file,image,config):
    backend=Backend(config['SUPABASE_URL'],config['SUPABASE_SERVICE_ROLE_KEY'])
    for residue in backend.rpc('tours_claim_cleanup',{}):
        if STOP.is_set():break
        guard={'p_job':residue['id'],'p_lease':residue['lease_id']}
        # A batch entry may have expired while earlier Storage operations ran.
        # Renew ONLY if the same token still owns a non-ready job.
        if not backend.rpc('tours_renew_cleanup',guard):
            log('cleanup_skipped',job_id=residue['id']);continue
        success=False
        try:backend.remove(residue['paths']);success=True
        finally:
            if not backend.rpc('tours_finish_cleanup',{**guard,'p_success':success}):
                raise TourError('cleanup_lease_lost')
    jobs=backend.rpc('tours_claim_jobs',{})
    if len(jobs)>2:raise ValueError('Queue violated the global two-job limit')
    log('claimed',count=len(jobs))
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures=[pool.submit(run_one,job,env_file,image,config) for job in jobs]
        return [future.result() for future in futures]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True);mode.add_argument('--once',action='store_true');mode.add_argument('--watch',action='store_true')
    parser.add_argument('--env-file',type=Path,default=Path('config/.env.tours-local'))
    parser.add_argument('--image',default='marea/tour-stitch:local-pilot')
    parser.add_argument('--interval',type=float,default=10)
    args=parser.parse_args()
    if args.interval<1:parser.error('interval must be at least one second')
    config=read_config(args.env_file)
    for sig in (signal.SIGINT,signal.SIGTERM):signal.signal(sig,lambda *_:STOP.set())
    failed=False
    while not STOP.is_set():
        try:
            results=cycle(args.env_file.resolve(),args.image,config)
            failed=any(result['state']!='ready' for result in results)
        except (TourError,ValueError,OSError,subprocess.SubprocessError) as error:
            log('error',error_code=error.code if isinstance(error,TourError) else type(error).__name__);failed=True
        if args.once:break
        STOP.wait(args.interval)
    return 1 if failed else 0
if __name__=='__main__':raise SystemExit(main())
