"""Preserve B actor gates; resolve parent obligations by explicit C ownership."""
import json,re,subprocess,shutil,time
from pathlib import Path
import orgc_lab as L
from org0_cases import lit,write

def red():
 results={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text());c=json.loads((L.PRIVATE/(a+'-C-fixture.json')).read_text());before=L.capture(pg)
  q="INSERT INTO public.mission_applications(mission_id,applicant_id,message) VALUES("+lit(c['legacy_org']['mission'])+','+lit(f['users']['last']['auth'])+",'Synthetic C authority probe');"
  r=write(pg,q,'service_role',rollback=True,check=False);L.require(r.returncode and '55000' in r.stderr and 'MISSION_OWNER_OBLIGATIONS_BLOCKED' in r.stderr and L.capture(pg)==before,'B attribution dependency not reproduced');results[a]={'result':'EXPECTED_RED','blocked_historical_author_confused_with_org_owner':True,'rollback_exact':True}
 L.save('17-C-parent-author-RED.json',{'result':'EXPECTED_RED','sources':results})

def install():
 L.require(json.loads((L.RUN/'17-C-parent-author-RED.json').read_text())['result']=='EXPECTED_RED','RED required')
 helper=(L.ROOT/'tool/task002/c_owner_guard.sql').read_text();pg=L.OWNER+'-a-pg';old=L.val(pg,"SELECT to_jsonb(pg_get_functiondef('collaboration.deletion_obligation_guard()'::regprocedure));");pattern=r'  SELECT author_id INTO STRICT owner_auth FROM public.missions WHERE id=NEW.mission_id;.*?MESSAGE=\'MISSION_OWNER_OBLIGATIONS_BLOCKED\'; END IF;'
 updated,n=re.subn(pattern,'  PERFORM collaboration.mission_obligations_guard(NEW.mission_id);',old,flags=re.S);L.require(n==1,'Pinned B guard parent branch mismatch')
 q="BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL lock_timeout='1500ms';SET LOCAL statement_timeout='20s';\n"+helper+'\n'+updated.rstrip()+';\nCOMMIT;\n';project=L.PRIVATE/'c-parent-cli-v2';(project/'supabase').mkdir(parents=True);(project/'supabase/config.toml').write_text('project_id="synthetic-orgc-parent"\n');cmd=['supabase','--workdir',str(project),'migration','new','e2c_explicit_parent_obligations_v2'];r=subprocess.run(cmd,capture_output=True,text=True);L.require(r.returncode==0,'CLI failed');files=list((project/'supabase/migrations').glob('*.sql'));L.require(len(files)==1,'CLI ambiguous');dest=L.RUN/files[0].name;dest.write_text(q);L.save('17d-C-parent-SQL-provenance-v2.json',{'result':'PASS','command':cmd,'stdout':r.stdout,'stderr':r.stderr,'SQL_file':dest.name,'SQL_sha256':L.sha(dest),'changes_existing_private_routine_only':'collaboration.deletion_obligation_guard()','business_RPC_FK_unchanged':True})
 results={}
 for a in ['a','b']:
  pg=L.OWNER+'-'+a+'-pg';before=L.capture(pg);r=L.sql(pg,q.rsplit('COMMIT;',1)[0]+'ROLLBACK;',True,False);L.require(r.returncode==0 and L.capture(pg)==before,'Parent guard rehearsal failed '+r.stderr[-250:]);L.sql(pg,q,True);now=L.capture(pg);L.require(now['row_hashes']==before['row_hashes'] and now['sequences']==before['sequences'],'Parent guard changed rows');L.private(a+'-C-parent-function-before.json',{'definition':old});results[a]={'result':'PASS','rehearsal_rollback_exact':True,'all_rows_sequences_equal':True,'only_B_parent_branch_replaced':True}
 L.save('17b-C-parent-installation.json',{'result':'PASS','sources':results,'SQL_file':dest.name})
if __name__=='__main__':
 import sys
 {'red':red,'install':install}[sys.argv[1]]()
