"""Small transactional patches; no restore repetition or historical source edit."""
import json,subprocess
import orgc_lab as L
def install(source,name,receipt):
 from orgc_gate import validate_org0_gate
 validate_org0_gate(L.RUN,json.loads((L.RUN/'12-ORG0-ACCEPTANCE.json').read_text()));q=(L.ROOT/source).read_text();L.require(q.startswith('BEGIN;') and q.rstrip().endswith('COMMIT;'),'Bound transactional patch required')
 project=L.PRIVATE/name;(project/'supabase').mkdir(parents=True);(project/'supabase/config.toml').write_text('project_id="synthetic-orgc-patch"\n');cmd=['supabase','--workdir',str(project),'migration','new',name];r=subprocess.run(cmd,capture_output=True,text=True);L.require(r.returncode==0,'CLI generation failed');files=list((project/'supabase/migrations').glob('*.sql'));L.require(len(files)==1,'Patch name ambiguous');dest=L.RUN/files[0].name;L.require(not dest.exists(),'Preserve previous SQL');dest.write_text(q);results={}
 for a in ['a','b']:
  pg=L.OWNER+'-'+a+'-pg';before=L.capture(pg);r=L.sql(pg,q.rsplit('COMMIT;',1)[0]+'ROLLBACK;',True,False);L.require(r.returncode==0 and L.capture(pg)==before,'Patch rehearsal failed: '+r.stderr[-300:]);L.sql(pg,q,True);after=L.capture(pg);L.require(after['row_hashes']==before['row_hashes'] and after['sequences']==before['sequences'],'Patch mutated data');results[a]={'result':'PASS','rollback_exact':True,'all_rows_sequences_equal':True}
 L.save(receipt,{'result':'PASS','command':cmd,'SQL_file':dest.name,'SQL_sha256':L.sha(dest),'source':source,'source_sha256':L.sha(L.ROOT/source),'sources':results})
