"""Transactional B installation; retain any failed attempt and verify rollback."""
import json,time
import b_lab as L
def run():
 L.require(json.loads((L.RUN/'04-contracts-RED.json').read_text())['result']=='EXPECTED_RED','B RED required');results={}
 q=(L.RUN/L.CONFIG['sql_name']).read_text();L.require(q.startswith('BEGIN;') and q.rstrip().endswith('COMMIT;'),'Explicit B transaction required')
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';before=L.capture(pg);L.private(a+'-before-B-DDL.json',before)
  r=L.sql(pg,q.rsplit('COMMIT;',1)[0]+'ROLLBACK;',write=True,check=False)
  L.require(L.capture(pg)==before,'B rehearsal changed baseline')
  if r.returncode:
   L.save('INSTALL-ATTEMPT-'+a+'-'+str(time.time_ns())+'.json',{'result':'ROLLED_BACK_SQL_ERROR','SQL_sha256':L.sha(L.RUN/L.CONFIG['sql_name']),'stderr':r.stderr,'rollback_exact':True});raise RuntimeError('B SQL rehearsal failed; preserved receipt')
  L.sql(pg,q,write=True);after=L.capture(pg);L.private(a+'-after-B-DDL.json',after)
  L.require(all(after['row_hashes'][t]==rows for t,rows in before['row_hashes'].items()) and after['sequences']==before['sequences'],'B DDL changed existing rows/sequences')
  results[a]={'result':'PASS','DDL_rollback_exact':True,'all_original_rows_sequences_equal':True,'SQL_sha256':L.sha(L.RUN/L.CONFIG['sql_name'])}
 L.save('05-B-installation.json',{'result':'PASS','sources':results,'no_purge_capability':True,'SQL_file':L.CONFIG['sql_name']})
if __name__=='__main__':run()
