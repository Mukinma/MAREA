"""Quiescent maintenance fence. No bypass switch, purge plan or ownership migration."""
import hashlib,json,time,uuid
from pathlib import Path
import s0_lab_v2 as L
MANIFEST=L.RUN/'S0-GUARD-MANIFEST-v3.json'
import s0_services as S
from s0_cases import refs

def state_copy(a):return f'{L.OWNER}-{a}-control-v2-copy'
def state_bytes(a):return L.docker('exec',state_copy(a),'cat','/dest/data/state.json',binary=True).stdout

def put_state(a,value):
 code="""import pathlib,sys,os
p=pathlib.Path('/dest/data');p.mkdir(mode=0o755,exist_ok=True);os.chmod(p,0o755)
b=sys.stdin.buffer.read();q=p/'state.tmp';q.write_bytes(b);os.chmod(q,0o644);q.replace(p/'state.json')
"""
 raw=(json.dumps(value,sort_keys=True)+'\n').encode();L.docker('exec','-i',state_copy(a),'python','-c',code,input=raw,binary=True);return hashlib.sha256(raw).hexdigest()

def assert_guards(a):
 manifest=json.loads((MANIFEST).read_text())['tables'];pg=f'{L.OWNER}-{a}-pg'
 rows=L.val(pg,"SELECT jsonb_agg(jsonb_build_object('schema',n.nspname,'table',c.relname,'name',t.tgname,'enabled',t.tgenabled,'function',t.tgfoid::regprocedure::text,'type',t.tgtype,'conditional',t.tgqual IS NOT NULL,'arguments',t.tgnargs,'columns',coalesce((SELECT jsonb_agg(a.attname ORDER BY a.attname) FROM pg_attribute a WHERE a.attrelid=c.oid AND a.attnum=ANY(t.tgattr::smallint[])),'[]'::jsonb)) ORDER BY n.nspname,c.relname,t.tgname) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE t.tgname LIKE 'aa_s0_%';")
 expected=[]
 for schema,table,cols in manifest:
  for name in ['aa_s0_delete','aa_s0_truncate']+(['aa_s0_reference'] if cols else []):expected.append({'schema':schema,'table':table,'name':name,'enabled':'O','function':'collaboration.s0_deny_mutation()','type':11 if name=='aa_s0_delete' else 34 if name=='aa_s0_truncate' else 23 if cols==['*'] else 19,'conditional':False,'arguments':0,'columns':sorted(cols) if name=='aa_s0_reference' and cols!=['*'] else []})
 L.require(rows==sorted(expected,key=lambda x:(x['schema'],x['table'],x['name'])),'S0 guard set incomplete/inconsistent')
 fn=L.val(pg,"SELECT jsonb_build_object('definition',pg_get_functiondef(p.oid),'owner',r.rolname,'definer',p.prosecdef,'settings',p.proconfig) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles r ON r.oid=p.proowner WHERE n.nspname='collaboration' AND p.proname='s0_deny_mutation';")
 L.require(fn is not None and fn['definer'] is False and fn['owner']=='supabase_admin' and fn['settings']==['search_path=""'],'S0 guard hardening drift')
 return {'triggers':rows,'function':fn}

def activate(a,held,sql_path,protected):
 # PREPARING is durable before stopping the old API. It is never client success.
 control=f'{L.OWNER}-{a}-control-v2';L.copier(control,'0:0')
 state={'schema_version':1,'status':'PREPARING','epoch':str(uuid.uuid4()),'physical_readonly':False,'quiescence_verified':False}
 put_state(a,state);pg=f'{L.OWNER}-{a}-pg';old=L.owned(held)
 L.docker('stop','--time','1',held);stopped=L.owned(held);L.require(not stopped['State']['Running'] and stopped['State']['Pid']==0,'Old Storage process not dead')
 for _ in range(40):
  connections=L.val(pg,"SELECT count(*) FROM pg_stat_activity WHERE usename='supabase_storage_admin';")
  if connections==0:break
  time.sleep(.05)
 L.require(connections==0,'Storage sessions/transactions not drained')
 L.require(refs(a)==protected['refs'] and L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy')==protected['tree'],'Protected resource lost before cut; activation prohibited')
 before=L.capture(pg);q=Path(sql_path).read_text();L.require(q.startswith('BEGIN;') and q.rstrip().endswith('COMMIT;'),'Transactional S0 SQL required')
 L.sql(pg,q.rsplit('COMMIT;',1)[0]+'ROLLBACK;',write=True);L.require(L.capture(pg)==before,'S0 rehearsal rollback changed catalog/data')
 L.sql(pg,q,write=True);installed=L.capture(pg);L.require(installed['row_hashes']==before['row_hashes'] and installed['sequences']==before['sequences'],'S0 DDL changed data')
 L.private(a+'-before-S0-DDL.json',before);L.private(a+'-after-S0-DDL.json',installed);guards=assert_guards(a)
 api=S.storage_start(a,'storage-fenced-v2',readonly=True);L.require(L.capture(pg)==installed,'Fenced API startup drift')
 L.require(refs(a)==protected['refs'] and L.pax_snapshot(f'{L.OWNER}-{a}-storage-copy')==protected['tree'],'Protected resource lost during activation')
 c=L.owned(api);L.require([m['RW'] for m in c['Mounts'] if m['Destination']=='/files']==[False],'Physical backend not read-only')
 old_apis=[]
 for cid in L.dtext('ps','-aq','--filter','label='+L.LABEL+'='+L.OWNER).split():
  x=L.inspect(cid)
  if x['Image']==L.STORAGE and x['Name'].startswith('/'+L.OWNER+'-'+a+'-') and x['Id']!=c['Id']:
   L.require(not x['State']['Running'],'An old Storage API still runs');old_apis.append(x['Id'])
 state.update(status='ACTIVE',physical_readonly=True,quiescence_verified=True,guard_manifest_sha256=L.sha(MANIFEST),quiesced_container=old['Id'],protected_tree_sha256=hashlib.sha256(json.dumps(protected['tree'],sort_keys=True).encode()).hexdigest())
 digest=put_state(a,state);L.private(a+'-ACTIVE-state-v3.json',state)
 return {'state':state,'digest':digest,'guards':guards,'old_api_exit_code':stopped['State']['ExitCode'],'old_api_pid':0,'old_apis_stopped':old_apis,'old_Storage_DB_sessions':0,'DDL_rollback_exact':True,'original_rows_sequences_unchanged_by_DDL':True,'physical_mount_readonly':True,'api':api}

def ingress_start(a,digest,label='ingress-v2'):
 pg=f'{L.OWNER}-{a}-pg';name=f'{L.OWNER}-{a}-{label}';cfg={'S0_STATE_DIGEST':digest,'SERVICE_ROLE_KEY':S.jwt(a,ttl=3600),'DENO_DIR':'/tmp/denocache'}
 cmd="while [ ! -f /tmp/ready ]; do sleep 0.05; done;exec deno run --no-config --cached-only --no-prompt --allow-net=127.0.0.1:9000,127.0.0.1:5000,127.0.0.1:9999,127.0.0.1:3000 --allow-env=S0_STATE_DIGEST,SERVICE_ROLE_KEY --allow-read=/state/data/state.json /tmp/main.ts"
 L.docker('run','-d',*L.base_args(name,'container:'+pg),'--mount',f'type=volume,src={L.OWNER}-{a}-control-v2,dst=/state,readonly','--tmpfs','/tmp:rw,nosuid,noexec,size=32m,mode=1777','--env-file',str(S.env_file(a,label,cfg)),'--entrypoint','sh',L.DENO,'-ec',cmd)
 source=(L.ROOT/'tool/task002/s0/ingress.ts').read_text();L.private(a+'-'+label+'-source.json',{'sha256':hashlib.sha256(source.encode()).hexdigest()});L.owned(name);L.docker('exec','-i',name,'sh','-c','cat >/tmp/main.ts',input=source);L.docker('exec',name,'touch','/tmp/ready')
 for _ in range(40):
  L.require(L.owned(name)['State']['Running'],'S0 ingress exited')
  if S.request(a,9000,'/health')['status']==200:return name
  time.sleep(.1)
 raise RuntimeError('S0 ingress readiness failure')


def reconcile_active(a):
 state=json.loads(state_bytes(a));L.require(state['status']=='ACTIVE' and state['physical_readonly'] is True and state['quiescence_verified'] is True,'Unknown S0 state')
 L.require(state['guard_manifest_sha256']==L.sha(MANIFEST),'Guard manifest mismatch')
 expected=json.loads((L.PRIVATE/(a+'-ACTIVE-state-v3.json')).read_text());L.require(state==expected,'Activation epoch/content mismatch')
 guards=assert_guards(a);record=json.loads((L.PRIVATE/(a+'-T49-v2-after.json')).read_text())['activation']['guards']
 L.require(guards['function']==record['function'],'Guard body/owner/settings changed')
 running=[]
 for cid in L.dtext('ps','-q','--filter','label='+L.LABEL+'='+L.OWNER).split():
  c=L.inspect(cid)
  if c['Image']==L.STORAGE and c['Name'].startswith('/'+L.OWNER+'-'+a+'-'):
   L.owned(c['Name'].lstrip('/'));L.require([m['RW'] for m in c['Mounts'] if m['Destination']=='/files']==[False],'Writable Storage API after activation');running.append(c['Id'])
 L.require(len(running)==1,'Storage API set incomplete/ambiguous')
 return {'epoch':state['epoch'],'digest':hashlib.sha256(state_bytes(a)).hexdigest(),'guard_count':len(guards['triggers']),'read_only_APIs':1}
