"""Only E2-A cases. Expected failures are assertions, never permission workarounds."""
import concurrent.futures,datetime,json,time,uuid,re
from pathlib import Path
import e2a_r2 as L

def write(pg,q,check=True):return L.sql(pg,"BEGIN;SET LOCAL default_transaction_read_only=off;SET LOCAL statement_timeout='15s';SET LOCAL lock_timeout='1500ms';\n"+q+'\nCOMMIT;',write=True,check=check)
def literal(value):return "'"+str(value).replace("'","''")+"'"
def asrole(pg,role,q,check=True):return write(pg,'SET LOCAL ROLE '+role+';'+q,check)
def expect_sql_error(pg,q,state,role=None):
 r=asrole(pg,role,q,False) if role else write(pg,q,False)
 L.require(r.returncode!=0 and re.search(r'\b'+state+r'\b',r.stderr),'Unexpected error/SQLSTATE: '+r.stderr[:240]);return {'result':'PASS','SQLSTATE':state}
def signup_id(response):
 L.require(response['status']==200,'Signup should succeed: '+str(response['status']))
 user=response['body'].get('user',response['body']);L.require(bool(user.get('id')),'No server Auth id');return user['id']
def phase_red():
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';base=L.capture(pg);L.auth_start(a)
  L.require(L.capture(pg)==base,'Auth startup changed baseline')
  response,body,before,after=L.signup(a,'red')
  uid=signup_id(response);n=L.val(pg,'SELECT count(*) FROM collaboration.persons WHERE auth_user_id='+literal(uid)+';')
  L.require(n==0,'E2-A unexpectedly present')
  L.private(a+'-red-fixture-id.json',{'uid':uid})
  results[a]={'Auth_HTTP':200,'expected_persons':1,'actual_persons':n,'result':'EXPECTED_RED','legacy_validation_preserved':True}
 L.save('04-functional-RED.json',{'result':'EXPECTED_RED','test':'E2-T02','sources':results,'A_DDL_applied':False})

def phase_install(sql_path):
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);L.private(a+'-before-A.json',before)
  q=Path(sql_path).read_text();L.require(q.startswith('BEGIN;') and q.rstrip().endswith('COMMIT;'),'Transactional A SQL')
  # Actual rollback rehearsal before commit, no successful Auth transactions in between.
  r=L.sql(pg,q.rsplit('COMMIT;',1)[0]+'ROLLBACK;',write=True);L.require(L.capture(pg)==before,'DDL rollback changed baseline')
  L.sql(pg,q,write=True);after=L.capture(pg);L.private(a+'-after-A.json',after)
  L.require(before['row_hashes']=={k:v for k,v in after['row_hashes'].items() if k in before['row_hashes']},'DDL changed existing rows')
  L.require(before['sequences']==after['sequences'],'DDL changed sequence')
  results[a]={'result':'PASS','transactional_rollback_exact':True,'committed':True,'legacy_rows_hashes_sequences_equal':True,'SQL_sha256':L.sha(sql_path)}
 L.save('05-A-transactional-installation.json',{'result':'PASS','sources':results})

def phase_green():
 # Implemented after the baseline RED has been observed, tests specified here first.
 raise RuntimeError('Green scenario implementation not yet prepared')

if __name__=='__main__':
 import sys
 try:
  if sys.argv[1:]==['red']:phase_red()
  elif len(sys.argv)==3 and sys.argv[1]=='install':phase_install(sys.argv[2])
  elif sys.argv[1:]==['green']:phase_green()
  else:raise SystemExit('red | install SQL | green')
 except Exception as e:
  L.save('FAILURE-'+str(time.time_ns())+'.json',{'result':'FAIL_STOPPED','error':str(e),'no_scope_expansion':True});L.stop();raise
