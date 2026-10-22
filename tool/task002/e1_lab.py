#!/usr/bin/env python3
"""Fixed, explicitly authorized E1 run. No original-volume or remote operations.

The SQL is a lab artifact, not a deployment migration. Failure stops this run;
only its own containers may be stopped in finally. Backups remain read-only.
"""
import copy, datetime, difflib, hashlib, json, os, re, subprocess, sys, time
from pathlib import Path
from e_diagnostics import MANIFEST, PG, HELPER
from e_inventory import CATALOG, quoted

ROOT = Path(__file__).resolve().parents[2]
RUN = ROOT / 'docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1'
PRIVATE = Path('/Users/crisis/Proyectos/marea-backups/task002-e1-20261019T055200Z')
BACKUPS = Path('/Users/crisis/Proyectos/marea-backups/task002-e-20261019T051800Z')
PREVIOUS = ROOT / 'docs/evidence/2026-10-18/task002/run-20261019T051800Z'
OWNER = 'task002-e1-20261019t055200z'
LABEL = 'marea.task002.e1.owner'
PROPOSAL = ROOT / 'docs/task002/E1-ADDITIVE-PROPOSAL.sql'
PROPOSAL_SHA = 'c0bd95c94fdde1fb55b17533debc939cae9c7fa8c7d77d2b194e8862978cedde'
BARRIER = "DO $$ BEGIN\n RAISE EXCEPTION 'TASK002_E1_REQUIRES_EXPLICIT_LOCAL_APPROVAL';\nEND $$;\n"
ENV = {k:v for k,v in os.environ.items() if k in ['PATH','HOME','LANG','TMPDIR']}
os.umask(0o077)

def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for b in iter(lambda:f.read(1048576), b''): h.update(b)
    return h.hexdigest()

def json_hash(obj):
    return hashlib.sha256(json.dumps(obj,sort_keys=True,separators=(',',':')).encode()).hexdigest()

def receipt(name, obj):
    p = RUN / name
    assert not p.exists(), 'Evidence already exists; do not overwrite'
    p.write_text(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),**obj},indent=2)+'\n')

def destination(name):
    assert re.fullmatch(re.escape(OWNER)+r'-[ab]-(db|storage|postgres)',name), 'Non-E1 destination refused'

def docker(*args, input=None, check=True, timeout=120):
    # Audit command names/arguments only; SQL results/rows and Docker config stay private.
    with (PRIVATE/'docker-commands.jsonl').open('a') as f: f.write(json.dumps(list(args))+'\n')
    r = subprocess.run(['docker',*args],input=input,text=True,capture_output=True,env=ENV,timeout=timeout)
    if check and r.returncode:
        p = PRIVATE / f'error-{time.time_ns()}.log'; p.write_text(r.stderr)
        raise RuntimeError('Docker operation failed; see private '+p.name)
    return r

def inspect(name, kind=None):
    return json.loads(docker('inspect',*(['--type',kind] if kind else []),name).stdout)[0]

def owned(name):
    destination(name)
    c = inspect(name)
    assert c['Config']['Labels'].get(LABEL)==OWNER
    assert c['Image']==PG and c['HostConfig']['NetworkMode']=='none'
    assert not c['HostConfig'].get('PortBindings') and not c['NetworkSettings']['Ports']
    assert not c['HostConfig']['Privileged'] and c['HostConfig']['ReadonlyRootfs']
    assert c['Config']['User']=='100:101'
    assert c['HostConfig']['CapDrop']==['ALL']
    assert all(m['Type']=='volume' and m['Name']==name.removesuffix('-postgres')+'-db' for m in c['Mounts'])
    return c

def helper(code, volume, args=(), writable=False):
    destination(volume)
    assert inspect(volume,'volume')['Labels'][LABEL]==OWNER
    mount = f'type=volume,src={volume},dst=/dest'+('' if writable else ',readonly')
    return docker('run','--rm','--pull','never','--network','none','--read-only','--user','0:0',
                  '--cap-drop','ALL','--cap-add','DAC_OVERRIDE','--cap-add','CHOWN','--cap-add','FOWNER',
                  '--security-opt','no-new-privileges','--mount',mount,'--mount',
                  f'type=bind,src={BACKUPS},dst=/backup,readonly','--entrypoint','python',HELPER,'-c',code,*args)

def preflight():
    assert PRIVATE.is_dir() and PRIVATE.stat().st_mode & 0o077 == 0
    assert docker('context','inspect','--format','{{.Endpoints.docker.Host}}').stdout.strip()=='unix:///Users/crisis/.docker/run/docker.sock'
    assert docker('version','--format','{{.Server.Version}}').stdout.strip()=='29.8.2'
    assert not docker('ps','-q').stdout.strip(), 'Precondition failed: existing running containers'
    for img in [PG,HELPER]: assert inspect(img,'image')['Id']==img
    assert digest(PROPOSAL)==PROPOSAL_SHA
    # The exact receipt hashes were registered in the canonical evidence before this run.
    assert digest(PREVIOUS/'04-cold-backup-restore.json')=='d46b994aa2a332d789b8d8ab4ee3755664aaebba01fce3ec8a65f858d9ae7ef5'
    assert digest(PREVIOUS/'08-effective-inventory-canonical.json')=='638395d4bd6b8edac7f6b1400eeae8576bf96d40a5d461356f5c2595a921a979'
    backup = json.loads((PREVIOUS/'04-cold-backup-restore.json').read_text())
    inventory = json.loads((PREVIOUS/'08-effective-inventory-canonical.json').read_text())
    verified = {}
    for a in ['a','b']:
        verified[a] = {}
        source = json.loads((BACKUPS/f'{a}-effective-v2-private.json').read_text())
        assert source['rows']==inventory['sources'][a]['tables']
        assert json_hash(source['catalog'])==inventory['sources'][a]['catalog_sha256']
        for kind in ['db','storage']:
            f = BACKUPS/f'{a}-{kind}-cold.tar'
            expected = backup['sources'][a][kind]['backup']
            assert not f.is_symlink() and digest(f)==expected['archive_sha256']
            assert digest(str(f)+'.manifest.json')==expected['tree_sha256']
            verified[a][kind] = expected
        for kind in ['db','storage','postgres']:
            name=f'{OWNER}-{a}-{kind}'
            assert docker('volume','inspect',name,check=False).returncode!=0
            assert docker('inspect',name,check=False).returncode!=0
    # Metadata only: never mount, start, stop or query any original volume/runtime.
    old = json.loads(docker('ps','-aq','--no-trunc').stdout.replace('\n', ' ') and
                     docker('inspect',*docker('ps','-aq','--no-trunc').stdout.split()).stdout)
    original_state = [{'id':c['Id'],'name':c['Name'],'state':c['State'],
                       'mounts':c['Mounts'],'image':c['Image']} for c in old]
    (PRIVATE/'previous-container-state.json').write_text(json.dumps(original_state,sort_keys=True))
    receipt('01-preflight.json',{'result':'PASS','docker_socket':'unix:///Users/crisis/.docker/run/docker.sock',
        'docker_version':'29.8.2','postgres_image':PG,'helper_image':HELPER,'running_containers_before':0,
        'backup_receipt_sha256':digest(PREVIOUS/'04-cold-backup-restore.json'),
        'proposal_sha256':PROPOSAL_SHA,'backups_verified':verified,
        'backup_source':'Existing immutable archives only; no original volume mounted',
        'remote_connections_used':False,'original_volume_access':False})
    return verified

def restore(a, kind, expected):
    name=f'{OWNER}-{a}-{kind}'; destination(name)
    docker('volume','create','--label',LABEL+'='+OWNER,name)
    code='import pathlib,json,hashlib,tarfile,os,sys\n'+MANIFEST+r'''
root=pathlib.Path('/dest');assert not list(root.iterdir())
with tarfile.open('/backup/'+sys.argv[1]) as t:
 for m in t.getmembers():
  assert m.name=='data' or m.name.startswith('data/')
  assert '..' not in pathlib.PurePosixPath(m.name).parts and not m.issym() and not m.islnk()
 t.extractall('/dest',filter='fully_trusted')
expected=json.loads(pathlib.Path('/backup/'+sys.argv[1]+'.manifest.json').read_text())
actual=tree(root/'data');assert actual==expected
print(json.dumps({'entries':len(actual),'tree_sha256':hashlib.sha256(json.dumps(actual,sort_keys=True,separators=(',',':')).encode()).hexdigest(),'content_and_metadata_equal':True}))
'''
    r=json.loads(helper(code,name,[f'{a}-{kind}-cold.tar'],writable=True).stdout)
    assert r['tree_sha256']==expected['tree_sha256']
    return {'volume':name,**r}

def start(a):
    name=f'{OWNER}-{a}-postgres'; v=f'{OWNER}-{a}-db'; destination(name)
    assert inspect(v,'volume')['Labels'][LABEL]==OWNER
    script="printf 'local all all trust\\nhost all all all reject\\n' >/tmp/diag-hba; touch /tmp/diag.conf; exec postgres -D /pg/data -c config_file=/tmp/diag.conf -c hba_file=/tmp/diag-hba -c listen_addresses= -c unix_socket_directories=/tmp -c shared_preload_libraries=pg_stat_statements,pg_cron -c cron.launch_active_jobs=off -c default_transaction_read_only=on -c ssl=off -c archive_mode=off -c max_connections=30"
    docker('run','-d','--pull','never','--name',name,'--label',LABEL+'='+OWNER,'--network','none',
           '--read-only','--user','100:101','--cap-drop','ALL','--security-opt','no-new-privileges',
           '--mount',f'type=volume,src={v},dst=/pg','--tmpfs','/tmp:rw,noexec,nosuid,size=64m,mode=1777',
           '--shm-size','128m','--entrypoint','sh',PG,'-ec',script)
    for _ in range(80):
        assert owned(name)['State']['Running'], 'Precondition failed: lab boot'
        if docker('exec',name,'pg_isready','-h','/tmp','-U','supabase_admin','-d','postgres',check=False).returncode==0:return name
        time.sleep(.25)
    raise RuntimeError('Precondition failed: readiness timeout')

def sql(name, query, readonly=True, check=True):
    owned(name)
    if readonly:query="BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY; SET LOCAL statement_timeout='30s';\n"+query+'\nROLLBACK;'
    return docker('exec','-i',name,'psql','-X','-h','/tmp','-U','supabase_admin','-d','postgres',
                  '-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose','-Atq',input=query,check=check)

def row_query(table, label):
    return f"SELECT jsonb_build_object('table','{label}','rows',count(*),'sha256',encode(sha256(convert_to(coalesce(string_agg(to_jsonb(t)::text,E'\\n' ORDER BY to_jsonb(t)::text COLLATE \"C\"),''),'UTF8')),'hex')) FROM {table} t;"

EXTRA = r'''
SELECT jsonb_build_object(
 'schemas',(SELECT jsonb_agg(to_jsonb(x) ORDER BY name) FROM (SELECT nspname name,nspowner::regrole::text owner,nspacl::text acl FROM pg_namespace WHERE nspname NOT LIKE 'pg_%' AND nspname<>'information_schema')x),
 'defaults',(SELECT jsonb_agg(to_jsonb(x) ORDER BY defaclrole,defaclnamespace,defaclobjtype) FROM pg_default_acl x),
 'indexes',(SELECT jsonb_agg(to_jsonb(x) ORDER BY schemaname,tablename,indexname) FROM pg_indexes x WHERE schemaname NOT LIKE 'pg_%' AND schemaname<>'information_schema'),
 'publications',(SELECT jsonb_agg(to_jsonb(x) ORDER BY pubname) FROM pg_publication x),
 'publication_tables',(SELECT jsonb_agg(to_jsonb(x) ORDER BY pubname,schemaname,tablename) FROM pg_publication_tables x),
 'all_routines',(SELECT jsonb_agg(to_jsonb(x) ORDER BY schema,signature) FROM (SELECT n.nspname schema,p.oid::regprocedure::text signature,p.proowner::regrole::text owner,p.proacl::text acl,p.proconfig settings,p.prosecdef security_definer,pg_get_functiondef(p.oid) definition FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname<>'information_schema' AND p.prokind IN ('f','p'))x)
);
'''

def capture(name):
    cat=json.loads(sql(name,CATALOG).stdout)
    assert cat['safety']=={'cron_runs':0,'vault_secrets':0,'push_enabled':False,'geocoding_enabled':False,'non_synthetic_users':0}
    settings={x['name']:x['setting'] for x in cat['settings']}
    assert settings['listen_addresses']=='' and settings['cron.launch_active_jobs']=='off'
    assert settings['default_transaction_read_only']=='on' and 'pg_net' not in settings['shared_preload_libraries']
    tables=[t for t in cat['tables'] if t['relkind'] in ['r','p']]
    rows=[json.loads(line) for line in sql(name,'\n'.join(row_query(quoted(t['schema'])+'.'+quoted(t['name']),t['schema']+'.'+t['name']) for t in tables)).stdout.splitlines()]
    sequences=[]
    for t in cat['tables']:
        if t['relkind']=='S':
            q="SELECT jsonb_build_object('last_value',last_value,'is_called',is_called) FROM "+quoted(t['schema'])+'.'+quoted(t['name'])
            sequences.append({'name':t['schema']+'.'+t['name'],**json.loads(sql(name,q).stdout)})
    return {'catalog':cat,'rows':rows,'sequences':sequences,'extra':json.loads(sql(name,EXTRA).stdout)}

def legacy_equal(before, after, name):
    # All old definitions match exactly. Allow only the new persons table/FK and
    # the two PostgreSQL RI triggers added to auth.users by that new FK.
    c=copy.deepcopy(after['catalog'])
    c['tables']=[x for x in c['tables'] if x['schema']!='collaboration']
    c['constraints']=[x for x in c['constraints'] if x['schema']!='collaboration']
    q="""SELECT jsonb_build_object('relation','auth.users'::regclass::text,'names',coalesce(jsonb_agg(t.tgname),'[]'::jsonb)) FROM pg_trigger t JOIN pg_constraint c ON c.oid=t.tgconstraint
    WHERE t.tgisinternal AND t.tgrelid='auth.users'::regclass AND c.conrelid='collaboration.persons'::regclass;"""
    trigger_identity=json.loads(sql(name,q).stdout)
    new_trigger_names=trigger_identity['names']
    assert len(new_trigger_names)==2
    c['triggers']=[x for x in c['triggers'] if not (x['relation']==trigger_identity['relation'] and x['internal'] and x['name'] in new_trigger_names)]
    assert c==before['catalog'], 'Unexpected legacy catalog change'
    assert [x for x in after['rows'] if x['table']!='collaboration.persons']==before['rows']
    assert after['sequences']==before['sequences']
    extra=copy.deepcopy(after['extra'])
    extra['schemas']=[x for x in extra['schemas'] if x['name']!='collaboration']
    newindexes=[x for x in extra['indexes'] if x['schemaname']=='collaboration']
    assert len(newindexes)==2
    extra['indexes']=[x for x in extra['indexes'] if x['schemaname']!='collaboration']
    assert extra==before['extra'], 'Unexpected legacy schema/index/default/publication/routine change'
    return {'legacy_tables':len(before['rows']),'sequences':len(before['sequences']),
            'all_old_catalog_and_extra_definitions_equal':True,'rows_digests_equal':True,
            'expected_added_auth_internal_fk_triggers':len(new_trigger_names),'expected_new_indexes':len(newindexes)}

def executable(before):
    source=PROPOSAL.read_text(); assert digest(PROPOSAL)==PROPOSAL_SHA
    assert source.count(BARRIER)==1 and source.count('BEGIN;')==1 and source.endswith('ROLLBACK;\n')
    body=source.replace(BARRIER,'',1).replace('BEGIN;','BEGIN READ WRITE;',1).removesuffix('ROLLBACK;\n')
    # Verify every legacy table digest inside the transaction, before COMMIT.
    checks=[]
    for r in before['rows']:
        table='.'.join(quoted(x) for x in r['table'].split('.'))
        query=row_query(table,r['table']).removesuffix(';')
        checks.append("IF ("+query+") IS DISTINCT FROM '"+json.dumps(r,separators=(',',':'))+"'::jsonb THEN RAISE EXCEPTION 'E1_LEGACY_DIGEST_CHANGED'; END IF;")
    tail="DO $e1$ BEGIN\n"+'\n'.join(checks)+"\nEND $e1$;\nCOMMIT;\n"
    return '-- EXECUTABLE ONLY: authorized new synthetic E1 lab copies. Never remote/originals.\n-- Original proposal SHA256: '+PROPOSAL_SHA+'\n-- Authorization: '+str((RUN/'AUTHORIZATION.md').relative_to(ROOT))+'\n'+body+tail

PERSON = r'''
SELECT jsonb_build_object(
 'persons',(SELECT count(*) FROM collaboration.persons),
 'profiles',(SELECT count(*) FROM public.profiles),
 'auth_users',(SELECT count(*) FROM auth.users),
 'exact_mapping',(SELECT count(*) FROM collaboration.persons p JOIN public.profiles pr ON pr.id=p.id JOIN auth.users u ON u.id=p.auth_user_id WHERE p.id=p.auth_user_id),
 'unmapped_profiles',(SELECT count(*) FROM public.profiles p LEFT JOIN collaboration.persons cp ON cp.id=p.id AND cp.auth_user_id=p.id WHERE cp.id IS NULL),
 'unmapped_auth',(SELECT count(*) FROM auth.users u LEFT JOIN collaboration.persons cp ON cp.auth_user_id=u.id WHERE cp.id IS NULL),
 'invalid_created_at',(SELECT count(*) FROM collaboration.persons WHERE created_at IS NULL OR created_at>clock_timestamp()),
 'rls',(SELECT relrowsecurity FROM pg_class WHERE oid='collaboration.persons'::regclass),
 'force_rls',(SELECT relforcerowsecurity FROM pg_class WHERE oid='collaboration.persons'::regclass),
 'owner',(SELECT relowner::regrole::text FROM pg_class WHERE oid='collaboration.persons'::regclass),
 'policies',(SELECT count(*) FROM pg_policies WHERE schemaname='collaboration'),
 'columns',(SELECT jsonb_agg(to_jsonb(x) ORDER BY ordinal_position) FROM information_schema.columns x WHERE table_schema='collaboration'),
 'constraints',(SELECT jsonb_agg(jsonb_build_object('name',conname,'type',contype,'definition',pg_get_constraintdef(oid),'validated',convalidated,'delete_action',confdeltype) ORDER BY conname) FROM pg_constraint WHERE conrelid='collaboration.persons'::regclass),
 'privileges',(SELECT jsonb_agg(jsonb_build_object('role',r,'schema_usage',has_schema_privilege(r,'collaboration','USAGE'),'schema_create',has_schema_privilege(r,'collaboration','CREATE'),'select',has_table_privilege(r,'collaboration.persons','SELECT'),'insert',has_table_privilege(r,'collaboration.persons','INSERT'),'update',has_table_privilege(r,'collaboration.persons','UPDATE'),'delete',has_table_privilege(r,'collaboration.persons','DELETE'),'truncate',has_table_privilege(r,'collaboration.persons','TRUNCATE'),'references',has_table_privilege(r,'collaboration.persons','REFERENCES'),'trigger',has_table_privilege(r,'collaboration.persons','TRIGGER'))) FROM unnest(ARRAY['anon','authenticated'])r)
);
'''

def expect_error(name, label, query, expected, role=None, claims=None, whole_transaction=False):
    assert not whole_transaction or (role is None and claims is None)
    prefix='' if whole_transaction else 'BEGIN READ WRITE;\n'
    if claims: prefix+='SET LOCAL request.jwt.claims = \''+json.dumps(claims)+'\';\n'
    if role:prefix+='SET LOCAL ROLE '+role+';\nSELECT current_user;\n'
    r=sql(name,prefix+query+('' if whole_transaction else '\nROLLBACK;'),readonly=False,check=False)
    (PRIVATE/f'{name}-{label}.log').write_text(r.stdout+r.stderr)
    match=re.search(r'ERROR:\s+([0-9A-Z]{5}):',r.stderr)
    assert r.returncode!=0 and match and match[1]==expected, f'{label}: unexpected result; see private log'
    if role:assert r.stdout.strip()==role, 'SET ROLE was not effective'
    return {'test':label,'role':role or 'supabase_admin','sqlstate':match[1],'result':'PASS',
            'error':r.stderr.splitlines()[0] if role else 'Expected constraint/guard rejection'}

def tests(name):
    p=json.loads(sql(name,PERSON).stdout)
    assert p['persons']==p['profiles']==p['auth_users']==p['exact_mapping']==6
    assert p['unmapped_profiles']==p['unmapped_auth']==p['invalid_created_at']==0
    assert p['rls'] and not p['force_rls'] and p['policies']==0 and p['owner']=='supabase_admin'
    assert len(p['columns'])==3 and len(p['constraints'])==3
    assert all(x['validated'] for x in p['constraints'])
    fk=next(x for x in p['constraints'] if x['type']=='f');assert fk['delete_action']=='n' and 'ON DELETE SET NULL' in fk['definition']
    for grant in p['privileges']:assert all(v is False for k,v in grant.items() if k!='role')
    identity=sql(name,'SELECT id FROM collaboration.persons ORDER BY id LIMIT 1;').stdout.strip()
    new='00000000-0000-4000-8000-000000000001'; absent='00000000-0000-4000-8000-000000000002'
    assert sql(name,f"SELECT count(*) FROM auth.users WHERE id IN ('{new}','{absent}');").stdout.strip()=='0'
    cases=[]
    crud={'select':f"SELECT * FROM collaboration.persons WHERE id='{identity}';",
          'insert':f"INSERT INTO collaboration.persons(id) VALUES ('{new}');",
          'update':f"UPDATE collaboration.persons SET created_at=created_at WHERE id='{identity}';",
          'delete':f"DELETE FROM collaboration.persons WHERE id='{identity}';"}
    for role in ['anon','authenticated']:
        for action,query in crud.items():
            cases.append(expect_error(name,role+'-'+action,query,'42501',role,{'sub':identity,'role':role}))
    constraints=[('duplicate-id',f"INSERT INTO collaboration.persons(id) VALUES ('{identity}');",'23505'),
        ('duplicate-auth',f"INSERT INTO collaboration.persons(id,auth_user_id) VALUES ('{new}','{identity}');",'23505'),
        ('missing-auth',f"INSERT INTO collaboration.persons(id,auth_user_id) VALUES ('{new}','{absent}');",'23503'),
        ('null-id','INSERT INTO collaboration.persons(id) VALUES (NULL);','23502'),
        ('null-created-at',f"INSERT INTO collaboration.persons(id,created_at) VALUES ('{new}',NULL);",'23502'),
        ('update-missing-auth',f"UPDATE collaboration.persons SET auth_user_id='{absent}' WHERE id='{identity}';",'23503')]
    for label,q,code in constraints:cases.append(expect_error(name,label,q,code))
    return {'inspection':p,'negative_tests':cases}

def storage_check(a, expected):
    code='import pathlib,json,hashlib,os\n'+MANIFEST+"\nactual=tree(pathlib.Path('/dest/data'));print(json.dumps({'tree_sha256':hashlib.sha256(json.dumps(actual,sort_keys=True,separators=(',',':')).encode()).hexdigest(),'files':sum(x['type']=='file' for x in actual)}))"
    result=json.loads(helper(code,f'{OWNER}-{a}-storage').stdout)
    assert result['tree_sha256']==expected['tree_sha256'] and result['files']==expected['files']
    return result

def cleanup(receipt_name='09-isolation-and-close.json'):
    closed=[]
    for a in ['a','b']:
        name=f'{OWNER}-{a}-postgres'
        if docker('inspect',name,check=False).returncode!=0:continue
        c=owned(name)
        if c['State']['Running']:docker('stop','--time','30',name)
        c=owned(name);assert not c['State']['Running']
        (PRIVATE/f'{name}-server.log').write_text(docker('logs',name).stderr)
        closed.append({'name':name,'running':False,'network':c['HostConfig']['NetworkMode'],'ports':c['NetworkSettings']['Ports']})
    old=json.loads((PRIVATE/'previous-container-state.json').read_text())
    for c in old:
        now=inspect(c['id'])
        assert {k:now[{'id':'Id','name':'Name','state':'State','mounts':'Mounts','image':'Image'}[k]] for k in c}==c
    assert not docker('ps','-q').stdout.strip()
    receipt(receipt_name,{'result':'PASS','closed':closed,'previous_containers_metadata_unchanged':len(old),
        'original_volumes_mounted':False,'original_contents_rehashed':False,
        'reason':'No original-volume access authorized; original runtime metadata only compared',
        'all_containers_stopped':True,'volumes_and_logs_retained':True})

def run():
    verified=preflight()
    try:
        restored={a:{kind:restore(a,kind,verified[a][kind]) for kind in ['db','storage']} for a in ['a','b']}
        receipt('02-restoration.json',{'result':'PASS','copies':restored})
        names={a:start(a) for a in ['a','b']}
        befores={a:capture(names[a]) for a in ['a','b']}
        for a,before in befores.items():
            expected=json.loads((BACKUPS/f'{a}-effective-v2-private.json').read_text())
            assert {k:before[k] for k in expected}==expected, 'Precondition failed: source drift'
            assert sql(names[a],"SELECT count(*) FROM pg_namespace WHERE nspname='collaboration';").stdout.strip()=='0'
            (PRIVATE/f'{a}-before.json').write_text(json.dumps(before,sort_keys=True,indent=2))
        receipt('03-schema-and-digests-before.json',{'result':'PASS','sources':{a:{'catalog_sha256':json_hash(b['catalog']),'extra_catalog_sha256':json_hash(b['extra']),'rows':b['rows'],'sequences':b['sequences'],'no_drift':True,'collaboration_absent':True} for a,b in befores.items()}})
        # Same table counts/digests across the two fixtures except Storage; generate each exact precommit assertion set.
        executions={}; checks={}; conservation={}
        for a,name in names.items():
            before=befores[a]; text=executable(before); path=RUN/f'E1-LAB-{a.upper()}-EXECUTABLE.sql'
            assert not path.exists();path.write_text(text)
            (RUN/f'E1-LAB-{a.upper()}-DIFF.patch').write_text(''.join(difflib.unified_diff(PROPOSAL.read_text().splitlines(True),text.splitlines(True),fromfile='E1-ADDITIVE-PROPOSAL.sql',tofile=path.name)))
            # Verify DDL + complete backfill can roll back atomically before committing.
            rollback=text.removesuffix('COMMIT;\n')+'ROLLBACK;\n'
            rr=sql(name,rollback,readonly=False)
            assert capture(name)==before, 'E1 rollback did not restore full logical state'
            (PRIVATE/f'{a}-transactional-rollback.log').write_text(rr.stdout+rr.stderr)
            committed=sql(name,text,readonly=False)
            (PRIVATE/f'{a}-commit.log').write_text(committed.stdout+committed.stderr)
            after=capture(name); legacy=legacy_equal(before,after,name)
            checks[a]=tests(name)
            # A repeated execution must reject schema drift, never double-backfill or overwrite.
            retry=expect_error(name,'repeat-execution',text, 'P0001',whole_transaction=True)
            assert capture(name)==after, 'Negatives/re-execution changed data or catalog'
            conservation[a]={**legacy,'storage':storage_check(a,verified[a]['storage']),
                             'new_persons_digest':next(x for x in after['rows'] if x['table']=='collaboration.persons'),
                             'negative_tests_preserved_all_rows_and_catalog':True}
            executions[a]={'result':'PASS','sql':str(path.relative_to(ROOT)),'sql_sha256':digest(path),
                'rollback_all_objects_and_rows_proved':True,'committed':True,'reexecution':retry,
                'legacy_author_fk':next(x for x in after['catalog']['constraints'] if x['relation']=='missions' and x['name']=='missions_author_id_fkey')}
            (PRIVATE/f'{a}-after.json').write_text(json.dumps(after,sort_keys=True,indent=2))
            print(json.dumps({'source':a,'E1_commit':'PASS','persons':checks[a]['inspection']['persons'],'negative_tests':len(checks[a]['negative_tests']),'legacy_preserved':True}),flush=True)
        receipt('04-transactional-execution.json',{'result':'PASS','proposal_sha256':digest(PROPOSAL),'sources':executions})
        receipt('05-permissions-constraints-tests.json',{'result':'PASS','sources':checks,'negative_crud_tests':16,'constraint_rejections':12,'reexecution_rejections':2})
        receipt('06-legacy-and-storage-conservation.json',{'result':'PASS','sources':conservation,
            'original_volume_access':False,'missions_author_id_or_fk_modified':False,
            'expected_additions':'Schema, persons, two indexes, three constraints (PK/UNIQUE/FK), four internal RI triggers (two on auth.users) per copy; no policy or routine added'})
        for a in ['a','b']:
            for kind in ['db','storage']:
                assert digest(BACKUPS/f'{a}-{kind}-cold.tar')==verified[a][kind]['archive_sha256']
                assert digest(BACKUPS/f'{a}-{kind}-cold.tar.manifest.json')==verified[a][kind]['tree_sha256']
        assert digest(PROPOSAL)==PROPOSAL_SHA
        receipt('07-backup-and-proposal-preservation.json',{'result':'PASS','all_four_backup_archives_and_manifests_unchanged':True,'original_proposal_identical':True,'proposal_sha256':PROPOSAL_SHA})
    except Exception as ex:
        receipt('FAILURE.json',{'result':'FAIL_STOPPED','error':str(ex),'no_scope_expansion':True})
        raise
    finally:
        cleanup()

def resume_comparator_only():
    """Resume an interrupted verifier, never bypass a failed SQL/data precondition.

    A is already committed; B must match its original preflight exactly. There
    is no new DDL on A and no schema change beyond the original E1 on B.
    """
    assert json.loads((RUN/'FAILURE.json').read_text())['error']=='Unexpected legacy catalog change'
    diagnosis=json.loads((RUN/'10-readonly-failure-diagnosis.json').read_text())
    assert diagnosis['legacy_rows_equal'] and diagnosis['sequences_equal']
    assert list(diagnosis['changes'])==['triggers']
    diff=diagnosis['changes']['triggers']; assert not diff['removed'] and len(diff['added'])==2
    assert all(x['internal'] and 'FROM collaboration.persons' in x['definition'] for x in diff['added'])
    assert digest(PROPOSAL)==PROPOSAL_SHA
    assert not docker('ps','-q').stdout.strip()
    assert docker('context','inspect','--format','{{.Endpoints.docker.Host}}').stdout.strip()=='unix:///Users/crisis/.docker/run/docker.sock'
    assert docker('version','--format','{{.Server.Version}}').stdout.strip()=='29.8.2'
    verified=json.loads((RUN/'01-preflight.json').read_text())['backups_verified']
    for a in ['a','b']:
        for kind in ['db','storage']:
            assert digest(BACKUPS/f'{a}-{kind}-cold.tar')==verified[a][kind]['archive_sha256']
            assert digest(BACKUPS/f'{a}-{kind}-cold.tar.manifest.json')==verified[a][kind]['tree_sha256']
    executions={};checks={};conservation={}
    try:
        names={}
        for a in ['a','b']:
            name=f'{OWNER}-{a}-postgres';owned(name);docker('start',name);names[a]=name
            for _ in range(80):
                if docker('exec',name,'pg_isready','-h','/tmp','-U','supabase_admin','-d','postgres',check=False).returncode==0:break
                time.sleep(.25)
            else:raise RuntimeError('Resume readiness precondition failed')
        befores={a:json.loads((PRIVATE/f'{a}-before.json').read_text()) for a in ['a','b']}
        a_now=capture(names['a'])
        assert a_now==json.loads((PRIVATE/'a-failure-after-readonly.json').read_text())
        legacy_equal(befores['a'],a_now,names['a'])
        assert capture(names['b'])==befores['b'], 'B precondition failed: drift'
        note_name='16-bounded-verifier-resumption-serialization.json' if (RUN/'13-bounded-verifier-resumption.json').exists() else '13-bounded-verifier-resumption.json'
        receipt(note_name,{'result':'PASS','preconditions_still_valid':True,
            'cause':'regclass uses visible name users under search_path; comparator qualified-name assumption',
            'fix':'Resolve relation text from the same auth.users OID; permit only two triggers joined to persons FK',
            'sql_or_schema_changed_to_fix':False,'new_scope':False,'first_failure_retained':True,
            'comparator_regression_red_then_green':True,'A_existing_commit_verified_readonly':True,
            'B_still_exact_initial_state':True,
            'serialization_note':'Private snapshot sorted JSON keys; executable is reproduced byte-for-byte using original ordered public digest receipt. No SQL applied during failed serialization check.'})
        for a,name in names.items():
            before=befores[a];path=RUN/f'E1-LAB-{a.upper()}-EXECUTABLE.sql'
            original_rows=json.loads((RUN/'03-schema-and-digests-before.json').read_text())['sources'][a]['rows']
            assert original_rows==before['rows']
            text=executable({'rows':original_rows})
            if a=='a':
                assert path.read_text()==text
            else:
                assert not path.exists();path.write_text(text)
                (RUN/f'E1-LAB-{a.upper()}-DIFF.patch').write_text(''.join(difflib.unified_diff(PROPOSAL.read_text().splitlines(True),text.splitlines(True),fromfile='E1-ADDITIVE-PROPOSAL.sql',tofile=path.name)))
                rr=sql(name,text.removesuffix('COMMIT;\n')+'ROLLBACK;\n',readonly=False)
                (PRIVATE/f'{a}-transactional-rollback.log').write_text(rr.stdout+rr.stderr)
                assert capture(name)==before
                committed=sql(name,text,readonly=False)
                (PRIVATE/f'{a}-commit.log').write_text(committed.stdout+committed.stderr)
            after=capture(name); legacy=legacy_equal(before,after,name)
            checks[a]=tests(name)
            retry=expect_error(name,'repeat-execution',text,'P0001',whole_transaction=True)
            assert capture(name)==after
            conservation[a]={**legacy,'storage':storage_check(a,verified[a]['storage']),
                'new_persons_digest':next(x for x in after['rows'] if x['table']=='collaboration.persons'),
                'negative_tests_preserved_all_rows_and_catalog':True}
            executions[a]={'result':'PASS','sql':str(path.relative_to(ROOT)),'sql_sha256':digest(path),
                'rollback_all_objects_and_rows_proved':True,'committed':True,'reexecution':retry,
                'legacy_author_fk':next(x for x in after['catalog']['constraints'] if x['name']=='missions_author_id_fkey' and x['schema']=='public')}
            (PRIVATE/f'{a}-after.json').write_text(json.dumps(after,sort_keys=True,indent=2))
            print(json.dumps({'source':a,'E1_commit':'PASS','persons':checks[a]['inspection']['persons'],'negative_tests':len(checks[a]['negative_tests']),'legacy_preserved':True}),flush=True)
        receipt('04-transactional-execution.json',{'result':'PASS','proposal_sha256':digest(PROPOSAL),'sources':executions})
        receipt('05-permissions-constraints-tests.json',{'result':'PASS','sources':checks,'negative_crud_tests':16,'constraint_rejections':12,'reexecution_rejections':2})
        receipt('06-legacy-and-storage-conservation.json',{'result':'PASS','sources':conservation,
            'original_volume_access':False,'missions_author_id_or_fk_modified':False,
            'expected_additions':'Schema, persons, two indexes, three constraints (PK/UNIQUE/FK), four internal RI triggers (two on auth.users) per copy; no policy or routine added'})
        for a in ['a','b']:
            for kind in ['db','storage']:
                assert digest(BACKUPS/f'{a}-{kind}-cold.tar')==verified[a][kind]['archive_sha256']
                assert digest(BACKUPS/f'{a}-{kind}-cold.tar.manifest.json')==verified[a][kind]['tree_sha256']
        assert digest(PROPOSAL)==PROPOSAL_SHA
        receipt('07-backup-and-proposal-preservation.json',{'result':'PASS','all_four_backup_archives_and_manifests_unchanged':True,'original_proposal_identical':True,'proposal_sha256':PROPOSAL_SHA})
    except Exception as ex:
        receipt('RESUMPTION-FAILURE-2.json' if (RUN/'RESUMPTION-FAILURE.json').exists() else 'RESUMPTION-FAILURE.json',{'result':'FAIL_STOPPED','error':str(ex),'no_scope_expansion':True})
        raise
    finally:cleanup('17-final-isolation-and-close.json' if (RUN/'14-final-isolation-and-close.json').exists() else '14-final-isolation-and-close.json')

if __name__=='__main__':
    if sys.argv[1:]==['execute-authorized-e1']:run()
    elif sys.argv[1:]==['resume-comparator-only']:resume_comparator_only()
    else:raise SystemExit('Fixed authorized run only: execute-authorized-e1 | resume-comparator-only')
