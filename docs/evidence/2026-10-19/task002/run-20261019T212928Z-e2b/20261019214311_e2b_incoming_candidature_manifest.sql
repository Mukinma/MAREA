BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
SET LOCAL statement_timeout='30s';
CREATE OR REPLACE FUNCTION collaboration.prepare_person_deletion_manifest(p_request uuid,p_version bigint,p_policy text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE r collaboration.deletion_requests;account uuid;h text;answer jsonb;
BEGIN
 SELECT * INTO r FROM collaboration.deletion_requests WHERE id=p_request FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='REQUEST_REQUIRED'; END IF;
 IF p_version IS NULL THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='VERSION_REQUIRED'; END IF;
 IF r.stage='BLOCKED' THEN
  IF p_policy IS DISTINCT FROM r.policy_id OR p_version NOT IN(1,2) THEN RAISE EXCEPTION USING ERRCODE='23505',MESSAGE='MANIFEST_REPLAY_CONFLICT'; END IF;
  RETURN pg_catalog.jsonb_build_object('request_id',r.id,'manifest_hash',r.manifest_hash,'stage','BLOCKED','completed',false);
 END IF;
 IF p_version<>r.version THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='DELETION_VERSION_CONFLICT'; END IF;
 IF p_policy IS NOT NULL AND NOT EXISTS(SELECT 1 FROM collaboration.deletion_policies WHERE id=p_policy AND synthetic AND approved_for_lab AND created_at+pg_catalog.make_interval(secs=>retention_seconds)>pg_catalog.clock_timestamp()) THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='APPROVED_SYNTHETIC_POLICY_REQUIRED'; END IF;
 SELECT auth_user_id INTO account FROM collaboration.persons WHERE id=r.person_id;
 IF account IS NULL THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='MAPPING_REVIEW_REQUIRED'; END IF;
 INSERT INTO collaboration.deletion_manifest_items(request_id,category,resource_id)
 SELECT r.id,'PRINCIPAL',r.person_id UNION ALL
 SELECT r.id,'MISSION',id FROM public.missions WHERE author_id=account UNION ALL
 SELECT r.id,'CANDIDATURE',id FROM public.mission_applications WHERE applicant_id=account OR mission_id IN(SELECT id FROM public.missions WHERE author_id=account) UNION ALL
 SELECT r.id,'CANDIDATURE_OPERATION',operation_id FROM public.mission_application_operations WHERE applicant_id=account UNION ALL
 SELECT r.id,'MEDIA_CANDIDATE',id FROM storage.objects WHERE owner_id=account::text OR pg_catalog.split_part(name,'/',1)=account::text;
 -- Catalog only: no copied messages, evidence bodies, profile fields or paths.
 INSERT INTO collaboration.deletion_dependency_inventory(request_id,relation_name,constraint_name,columns,referenced_relation,delete_action)
 SELECT r.id,n.nspname||'.'||t.relname,c.conname,ARRAY(SELECT a.attname::text FROM pg_catalog.pg_attribute a WHERE a.attrelid=c.conrelid AND a.attnum=ANY(c.conkey) ORDER BY a.attnum),rn.nspname||'.'||rt.relname,c.confdeltype::text
 FROM pg_catalog.pg_constraint c JOIN pg_catalog.pg_class t ON t.oid=c.conrelid JOIN pg_catalog.pg_namespace n ON n.oid=t.relnamespace JOIN pg_catalog.pg_class rt ON rt.oid=c.confrelid JOIN pg_catalog.pg_namespace rn ON rn.oid=rt.relnamespace
 WHERE c.contype='f' AND c.confrelid IN('auth.users'::regclass,'public.profiles'::regclass);
 SELECT pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(pg_catalog.jsonb_build_object('items',(SELECT jsonb_agg(to_jsonb(x) ORDER BY category,resource_id) FROM collaboration.deletion_manifest_items x WHERE request_id=r.id),'dependencies',(SELECT jsonb_agg(to_jsonb(x) ORDER BY relation_name,constraint_name) FROM collaboration.deletion_dependency_inventory x WHERE request_id=r.id),'policy',p_policy)::text,'UTF8')),'hex') INTO h;
 UPDATE collaboration.deletion_requests SET stage='BLOCKED',version=2,manifest_hash=h,policy_id=p_policy WHERE id=r.id;
 INSERT INTO collaboration.deletion_audit(request_id,actor_role,event,purpose) VALUES(r.id,'marea_deletion_operator','MANIFEST_PREPARED','DELETION_REVIEW');
 RETURN pg_catalog.jsonb_build_object('request_id',r.id,'manifest_hash',h,'stage','BLOCKED','completed',false);
END $$;

COMMIT;
