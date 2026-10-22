#!/usr/bin/env python3
"""Read-only orphan/reference preflight + reversible destructive probe in E recovery copy only."""
import json,hashlib,datetime,re
import e_diagnostics as e
import e_inventory as inv
SUMMARY=r'''
SELECT jsonb_build_object(
 'missions',(SELECT count(*) FROM public.missions),'authors',(SELECT count(DISTINCT author_id) FROM public.missions),
 'profiles',(SELECT count(*) FROM public.profiles),'auth_users',(SELECT count(*) FROM auth.users),
 'missing_profile',(SELECT count(*) FROM public.missions m LEFT JOIN public.profiles p ON p.id=m.author_id WHERE p.id IS NULL),
 'missing_auth',(SELECT count(*) FROM public.missions m LEFT JOIN auth.users u ON u.id=m.author_id WHERE u.id IS NULL),
 'mission_statuses',(SELECT jsonb_object_agg(status,n) FROM (SELECT status,count(*) n FROM public.missions GROUP BY status)x),
 'application_statuses',(SELECT jsonb_object_agg(status,n) FROM (SELECT status,count(*) n FROM public.mission_applications GROUP BY status)x),
 'profile_types',(SELECT jsonb_object_agg(user_type,n) FROM (SELECT coalesce(user_type,'NULL') user_type,count(*) n FROM public.profiles GROUP BY user_type)x),
 'business_profiles',(SELECT count(*) FROM public.profiles WHERE user_type ILIKE '%negocio%' OR user_type ILIKE '%espacio%'),
 'collaboration_schema',(SELECT count(*) FROM pg_namespace WHERE nspname='collaboration'),
 'mission_images',(SELECT count(*) FROM storage.objects WHERE bucket_id='mission-images'),
 'storage_objects',(SELECT count(*) FROM storage.objects),
 'deletion_prepare_hook',to_regprocedure('collaboration.prepare_principal_deletion(uuid)') IS NOT NULL,
 'delete_hooks',(SELECT count(*) FROM pg_trigger WHERE tgrelid='auth.users'::regclass AND NOT tgisinternal AND (tgtype&8)=8)
);
'''
FKS=r'''
SELECT jsonb_agg(to_jsonb(x)) FROM (
 SELECT c.conname name,ns.nspname source_schema,cs.relname source_table,nt.nspname target_schema,ct.relname target_table,
 ARRAY(SELECT a.attname FROM unnest(c.conkey) WITH ORDINALITY k(n,i) JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k.n ORDER BY k.i) source_columns,
 ARRAY(SELECT a.attname FROM unnest(c.confkey) WITH ORDINALITY k(n,i) JOIN pg_attribute a ON a.attrelid=c.confrelid AND a.attnum=k.n ORDER BY k.i) target_columns,
 c.confdeltype delete_action,c.convalidated validated
 FROM pg_constraint c JOIN pg_class cs ON cs.oid=c.conrelid JOIN pg_namespace ns ON ns.oid=cs.relnamespace
 JOIN pg_class ct ON ct.oid=c.confrelid JOIN pg_namespace nt ON nt.oid=ct.relnamespace
 WHERE c.contype='f' AND ns.nspname NOT LIKE 'pg_%' ORDER BY ns.nspname,cs.relname,c.conname)x;
'''
def lit(s):return "'"+s.replace("'","''")+"'"
def refs(name):
 fk=json.loads(e.sql(name,FKS).stdout);queries=[]
 for i,x in enumerate(fk):
  src=inv.quoted(x['source_schema'])+'.'+inv.quoted(x['source_table']);dst=inv.quoted(x['target_schema'])+'.'+inv.quoted(x['target_table']);nonnull=' AND '.join('s.'+inv.quoted(c)+' IS NOT NULL' for c in x['source_columns']);eq=' AND '.join('s.'+inv.quoted(a)+'=t.'+inv.quoted(b) for a,b in zip(x['source_columns'],x['target_columns']));queries.append(f"SELECT jsonb_build_object('index',{i},'orphans',count(*)) FROM {src} s WHERE {nonnull} AND NOT EXISTS(SELECT 1 FROM {dst} t WHERE {eq});")
 result=[json.loads(l) for l in e.sql(name,'\n'.join(queries)).stdout.splitlines() if l.startswith('{')]
 for x in result:fk[x['index']]['orphan_rows']=x['orphans']
 return fk

def storage(name,alias):
 objs=json.loads(e.sql(name,"SELECT coalesce(jsonb_agg(jsonb_build_object('bucket_id',bucket_id,'name',name,'version',version) ORDER BY id),'[]') FROM storage.objects;").stdout)
 manifest=json.loads((e.PRIVATE/f'{alias}-storage-cold.tar.manifest.json').read_text());files={x['path'] for x in manifest if x['type']=='file'}
 expected={'stub/stub/'+o['bucket_id']+'/'+o['name']+'/'+o['version'] for o in objs};assert all(x.startswith('stub/stub/') for x in files)
 return {'metadata_objects':len(objs),'physical_files':len(files),'missing_files':len(expected-files),'unreferenced_files':len(files-expected),'matching_layout':'Observed local file backend stub/stub/bucket/name/version; not a remote S3 equivalence claim'}

def cascade_probe(alias):
 name=f'{e.OWNER}-{alias}-recovery-postgres';c=e.owned(name);assert c['Mounts'][0]['Name']==f'{e.OWNER}-{alias}-recovery-db'
 before=inv.capture(name)
 query=r'''
BEGIN READ WRITE;
SELECT jsonb_build_object('stage','before','profiles',(SELECT count(*) FROM public.profiles),'missions',(SELECT count(*) FROM public.missions),'applications',(SELECT count(*) FROM public.mission_applications));
DELETE FROM public.profiles WHERE id=(SELECT author_id FROM public.missions ORDER BY id LIMIT 1);
SELECT jsonb_build_object('stage','after_delete','profiles',(SELECT count(*) FROM public.profiles),'missions',(SELECT count(*) FROM public.missions),'applications',(SELECT count(*) FROM public.mission_applications));
ROLLBACK;
'''
 rows=[json.loads(l) for l in e.sql(name,query,readonly=False).stdout.splitlines() if l.startswith('{')];assert len(rows)==2 and rows[1]['missions']<rows[0]['missions']
 after=inv.capture(name);assert before['rows']==after['rows'] and before['sequences']==after['sequences'],'Rollback conservation differs'
 return {'result':'PASS_REPRODUCED_LEGACY_CASCADE_AND_ROLLBACK','steps':rows,'all_table_digests_equal_after_rollback':True,'sequences_equal_after_rollback':True,'scope':'Dedicated recovery clone; no source profile/Auth deletion or FK replacement'}

def negative(name):
 q=e.docker('exec','-i',name,'psql','-X','-h','/tmp','-U','supabase_admin','-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input='BEGIN READ ONLY;SET LOCAL ROLE anon;SELECT count(*) FROM private.push_settings;ROLLBACK;',check=False)
 assert q.returncode!=0 and '42501' in q.stderr
 # No mutation may accidentally run through the read-only diagnostic connection.
 r=e.docker('exec','-i',name,'psql','-X','-h','/tmp','-U','supabase_admin','-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input='BEGIN READ ONLY;UPDATE public.missions SET title=title WHERE false;ROLLBACK;',check=False)
 assert r.returncode!=0 and '25006' in r.stderr
 return {'private_schema_read_denied_to_anon':'42501','read_only_write_denied':'25006'}

def main():
 e.guard();results={}
 for a in e.SOURCES:
  name=f'{e.OWNER}-{a}-work-postgres';summary=json.loads(e.sql(name,SUMMARY).stdout);fk=refs(name);media=storage(name,a)
  raw=(e.ROOT/'docs/task002/E-PREFLIGHT.sql').read_text();assert 'BEGIN READ ONLY;' in raw and raw.rstrip().endswith('ROLLBACK;');out=e.sql(name,raw,readonly=False);(e.PRIVATE/f'{a}-preflight-private.log').write_text(out.stdout+out.stderr)
  probe=cascade_probe(a);denial=negative(name)
  results[a]={'summary':summary,'fk_checked':len(fk),'orphan_rows_total':sum(x['orphan_rows'] for x in fk),'fk_graph':fk,'storage':media,'legacy_cascade_probe':probe,'negative':denial,'preflight_sql_sha256':hashlib.sha256(raw.encode()).hexdigest(),'preflight_execution':'PASS','complete_requirement_validation':False}
  assert summary['missing_profile']==summary['missing_auth']==0 and summary['collaboration_schema']==0 and not summary['deletion_prepare_hook'];assert sum(x['orphan_rows'] for x in fk)==0;assert media['missing_files']==media['unreferenced_files']==0
  (e.RUN/'10-reference-conservation-checks.json').write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'result':'PASS','sources':results},indent=2)+'\n');print(a,json.dumps({'summary':summary,'fk_checked':len(fk),'orphans':0,'storage':media,'cascade_and_rollback':probe['result']}))
if __name__=='__main__':main()
