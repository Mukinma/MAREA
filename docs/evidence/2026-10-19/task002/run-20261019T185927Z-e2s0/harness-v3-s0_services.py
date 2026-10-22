"""Only loopback services in fresh S0 clones; no remote endpoint or historical mount."""
import base64,hashlib,hmac,json,secrets,time
from pathlib import Path
import s0_lab as L
PORTS={5432,5000,3000,9999,9000}
def keys(a):
 p=L.PRIVATE/(a+'-keys.json')
 if p.exists():return json.loads(p.read_text())
 x={'secret':secrets.token_hex(32)};L.private(a+'-keys.json',x);return x

def jwt(a,role='service_role',sub=None,session=None):
 data={'role':role,'iss':'supabase','aud':'authenticated','iat':int(time.time()),'exp':int(time.time())+90}
 if sub:data['sub']=sub
 if session:data['session_id']=session
 enc=lambda b:base64.urlsafe_b64encode(b).decode().rstrip('=')
 body=enc(b'{"alg":"HS256","typ":"JWT"}')+'.'+enc(json.dumps(data).encode())
 return body+'.'+enc(hmac.new(keys(a)['secret'].encode(),body.encode(),hashlib.sha256).digest())

def request(a,port,path,method='GET',data=None,body=None,token=None,headers=None):
 L.require(port in PORTS and path.startswith('/') and '://' not in path,'Only local approved API')
 L.runtime_net(a,PORTS)
 code='''import urllib.request,urllib.error,base64,json,sys
x=json.load(sys.stdin);req=urllib.request.Request('http://127.0.0.1:'+str(x['port'])+x['path'],data=base64.b64decode(x['body']) if x['body'] is not None else None,method=x['method'],headers=x['headers'])
try:
 r=urllib.request.urlopen(req,timeout=45);status=r.status;body=r.read();headers=dict(r.headers)
except urllib.error.HTTPError as e:status=e.code;body=e.read();headers=dict(e.headers)
except Exception as e:status=0;body=type(e).__name__.encode();headers={}
print(json.dumps({'status':status,'base64':base64.b64encode(body).decode(),'headers':headers}))
'''
 h=headers or {}
 if data is not None:body=json.dumps(data).encode();h={**h,'Content-Type':'application/json'}
 if token:h={**h,'Authorization':'Bearer '+token}
 payload={'port':port,'path':path,'method':method,'body':base64.b64encode(body).decode() if body is not None else None,'headers':h}
 r=L.docker('run','--rm','-i','--pull','never','--label',L.LABEL+'='+L.OWNER,'--network','container:'+L.OWNER+'-'+a+'-pg','--read-only','--user','1000:1000','--cap-drop','ALL','--security-opt','no-new-privileges','--entrypoint','python',L.HELPER,'-c',code,input=json.dumps(payload),timeout=70)
 out=json.loads(r.stdout);b=base64.b64decode(out.pop('base64'));out['sha256']=hashlib.sha256(b).hexdigest()
 try:out['body']=json.loads(b)
 except (ValueError,UnicodeDecodeError):out['body_text']=b.decode(errors='replace')[:200]
 return out

def env_file(a,label,values):
 p=L.PRIVATE/(a+'-'+label+'.env');L.require(not p.exists(),'Environment file already exists');p.write_text(''.join(k+'='+v+'\n' for k,v in values.items()));return p

def storage_start(a,label='storage',readonly=False,hook=None):
 pg=f'{L.OWNER}-{a}-pg';name=f'{L.OWNER}-{a}-{label}';L.runtime_net(a,{5432,3000,9999,9000})
 cfg={'AUTH_JWT_SECRET':keys(a)['secret'],'ANON_KEY':jwt(a,'anon'),'SERVICE_KEY':jwt(a),'DATABASE_URL':'postgres://supabase_storage_admin@127.0.0.1:5432/postgres?sslmode=disable&options=-c%20default_transaction_read_only%3Doff','STORAGE_BACKEND':'file','FILE_STORAGE_BACKEND_PATH':'/files/data','GLOBAL_S3_BUCKET':'stub','TENANT_ID':'stub','REGION':'local','SERVER_HOST':'127.0.0.1','SERVER_PORT':'5000','PG_QUEUE_ENABLE':'false','PG_QUEUE_WORKERS_ENABLE':'false','DB_ALLOW_MIGRATION_REFRESH':'false','EXPOSE_DOCS':'false','NODE_ENV':'production','ENABLE_IMAGE_TRANSFORMATION':'false','TUS_URL_PATH':'/upload/resumable','UPLOAD_FILE_SIZE_LIMIT':'52428800'}
 mount=f'type=volume,src={L.OWNER}-{a}-storage,dst=/files'+(',readonly' if readonly else '')
 ep=['dist/start/server.js']
 args=['--entrypoint','node']
 if hook is not None:args=['--entrypoint','sh'];ep=['-ec','while [ ! -f /tmp/ready ]; do sleep 0.05; done;exec node --require /tmp/hook.cjs dist/start/server.js']
 L.docker('run','-d',*L.base_args(name,'container:'+pg,'0:0'),'--mount',mount,'--tmpfs','/tmp:rw,nosuid,noexec,size=16m','--env-file',str(env_file(a,label,cfg)),*args,L.STORAGE,*ep)
 c=L.owned(name);L.require([m['RW'] for m in c['Mounts'] if m['Destination']=='/files']==[not readonly],'Storage mount mode mismatch')
 if hook is not None:
  L.docker('exec','-i',name,'sh','-c','cat >/tmp/hook.cjs',input=hook);L.docker('exec',name,'touch','/tmp/ready')
 for _ in range(40):
  L.require(L.owned(name)['State']['Running'],'Storage exited; inspect private logs')
  r=request(a,5000,'/status')
  if r['status']==200:return name
  time.sleep(.2)
 raise RuntimeError('Storage readiness failed')

def rest_start(a,label="rest"):
 pg=f'{L.OWNER}-{a}-pg';name=f'{L.OWNER}-{a}-{label}'
 cfg={'PGRST_DB_URI':'postgres://authenticator@127.0.0.1:5432/postgres?sslmode=disable&options=-c%20default_transaction_read_only%3Doff','PGRST_DB_SCHEMAS':'public','PGRST_DB_ANON_ROLE':'anon','PGRST_JWT_SECRET':keys(a)['secret'],'PGRST_SERVER_HOST':'127.0.0.1','PGRST_SERVER_PORT':'3000','PGRST_LOG_LEVEL':'error'}
 L.docker('run','-d',*L.base_args(name,'container:'+pg),'--env-file',str(env_file(a,label,cfg)),L.POSTGREST);L.owned(name)
 for _ in range(30):
  if request(a,3000,'/')['status']==200:return name
  L.require(L.owned(name)['State']['Running'],'PostgREST exited');time.sleep(.2)
 raise RuntimeError('REST startup failed')

def auth_start(a,label="auth"):
 pg=f'{L.OWNER}-{a}-pg';name=f'{L.OWNER}-{a}-{label}'
 cfg={'GOTRUE_API_HOST':'127.0.0.1','GOTRUE_API_PORT':'9999','API_EXTERNAL_URL':'http://127.0.0.1:9999','GOTRUE_SITE_URL':'http://127.0.0.1:9999','GOTRUE_DB_DRIVER':'postgres','GOTRUE_DB_DATABASE_URL':'postgres://supabase_auth_admin@127.0.0.1:5432/postgres?sslmode=disable&options=-c%20default_transaction_read_only%3Doff','GOTRUE_DB_CLEANUP_ENABLED':'false','GOTRUE_JWT_SECRET':keys(a)['secret'],'GOTRUE_JWT_AUD':'authenticated','GOTRUE_JWT_DEFAULT_GROUP_NAME':'authenticated','GOTRUE_JWT_ADMIN_ROLES':'service_role','GOTRUE_JWT_EXP':'60','GOTRUE_EXTERNAL_EMAIL_ENABLED':'true','GOTRUE_DISABLE_SIGNUP':'false','GOTRUE_MAILER_AUTOCONFIRM':'true','GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED':'false','GOTRUE_SMTP_HOST':'127.0.0.1','GOTRUE_SMTP_PORT':'1025','GOTRUE_SMTP_ADMIN_EMAIL':'auth@s0.invalid','GOTRUE_RATE_LIMIT_EMAIL_SENT':'1000','GOTRUE_RATE_LIMIT_TOKEN_REFRESH':'1000','GOTRUE_SECURITY_CAPTCHA_ENABLED':'false','GOTRUE_LOG_LEVEL':'error'}
 L.docker('run','-d',*L.base_args(name,'container:'+pg),'--tmpfs','/tmp:rw,noexec,nosuid,size=16m','--env-file',str(env_file(a,label,cfg)),'--entrypoint','auth',L.AUTH)
 for _ in range(30):
  if request(a,9999,'/health')['status']==200:return name
  L.require(L.owned(name)['State']['Running'],'Auth exited');time.sleep(.2)
 raise RuntimeError('Auth readiness failure')
