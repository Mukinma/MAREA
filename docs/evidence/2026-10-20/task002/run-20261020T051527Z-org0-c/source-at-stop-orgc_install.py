"""New local CLI artefact, fail-closed preconditions and exact DDL rehearsal."""
import json,subprocess,shutil,sys,time
from pathlib import Path
import orgc_lab as L
def run(stage):
 L.require_preflight();red='04-ORG0-RED.json' if stage=='ORG0' else '14-C-RED.json';L.require(json.loads((L.RUN/red).read_text())['result']=='EXPECTED_RED','Real RED required')
 if stage!='ORG0':L.require(json.loads((L.RUN/'12-ORG0-ACCEPTANCE.json').read_text())['result']=='PASS','ORG0 acceptance gate required')
 source=L.ROOT/('tool/task002/org0_contract.sql' if stage=='ORG0' else 'tool/task002/c_contract.sql');project=L.PRIVATE/(stage.lower()+'-cli');(project/'supabase').mkdir(parents=True);(project/'supabase/config.toml').write_text('project_id = "synthetic-orgc-lab"\n')
 cmd=['supabase','--workdir',str(project),'migration','new',stage.lower()+'_private_structural'];r=subprocess.run(cmd,cwd=L.ROOT,capture_output=True,text=True);L.require(r.returncode==0,'CLI generation failed');generated=list((project/'supabase/migrations').glob('*.sql'));L.require(len(generated)==1,'CLI artefact ambiguous');dest=L.RUN/generated[0].name;L.require(not dest.exists(),'Do not overwrite SQL');shutil.copyfile(source,dest)
 L.save(('05a-ORG0' if stage=='ORG0' else '15a-C')+'-SQL-provenance.json',{'result':'PASS','command':cmd,'stdout':r.stdout,'stderr':r.stderr,'source':str(source.relative_to(L.ROOT)),'source_sha256':L.sha(source),'SQL_file':dest.name,'SQL_sha256':L.sha(dest),'no_operational_migration_written':True})
 results={};q=dest.read_text();L.require(q.startswith('BEGIN;') and q.rstrip().endswith('COMMIT;'),'Transaction required')
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);L.private(a+'-before-'+stage+'-DDL.json',before)
  L.require(L.val(pg,"SELECT count(*) FROM pg_trigger WHERE tgname LIKE 'aa_s0_%' AND tgenabled='O';")==40,'S0 drift')
  if stage=='ORG0':L.require(before==json.loads((L.PRIVATE/(a+'-orgc-base.json')).read_text()),'Pre-DDL drift')
  r=L.sql(pg,q.rsplit('COMMIT;',1)[0]+'ROLLBACK;',True,False);L.require(L.capture(pg)==before,'DDL rehearsal changed baseline')
  if r.returncode:L.save('INSTALL-ATTEMPT-'+str(time.time_ns())+'.json',{'result':'ROLLED_BACK','stage':stage,'stderr':r.stderr,'rollback_exact':True});raise RuntimeError('DDL error preserved; diagnose minimal rehearsal')
  L.sql(pg,q,True);after=L.capture(pg);L.require(all(after['row_hashes'][t]==h for t,h in before['row_hashes'].items()) and after['sequences']==before['sequences'],'DDL changed existing rows or sequences');L.private(a+'-after-'+stage+'-DDL.json',after);results[a]={'result':'PASS','DDL_rollback_exact':True,'all_preexisting_rows_sequences_equal':True}
 L.save(('05-ORG0' if stage=='ORG0' else '15-C')+'-installation.json',{'result':'PASS','sources':results,'SQL_file':dest.name,'SQL_sha256':L.sha(dest)})
if __name__=='__main__':run(sys.argv[1])
