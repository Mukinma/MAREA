BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
SET LOCAL statement_timeout='30s';
-- E2-A / D01 lab-only. New synthetic copies and verified backup/restore required.
-- No change to missions, applications, legacy trigger bodies or business RPCs.
DO $$ BEGIN
 IF (SELECT count(*) FROM collaboration.persons)<>6
 OR EXISTS(SELECT 1 FROM public.profiles p LEFT JOIN auth.users u ON u.id=p.id WHERE u.id IS NULL)
 OR NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.missions'::regclass AND conname='missions_author_id_fkey' AND confrelid='public.profiles'::regclass AND confdeltype='c' AND convalidated)
 OR EXISTS(SELECT 1 FROM pg_roles WHERE rolname IN ('marea_person_sync_owner','marea_person_repair_operator'))
 OR EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='collaboration' AND c.relname<>'persons' AND c.relkind IN ('r','p')) THEN
  RAISE EXCEPTION 'E2A_SOURCE_DRIFT';
 END IF;
END $$;
CREATE ROLE marea_person_sync_owner NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE ROLE marea_person_repair_operator NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
GRANT USAGE ON SCHEMA collaboration TO marea_person_sync_owner,marea_person_repair_operator;
GRANT USAGE ON SCHEMA auth,public TO marea_person_sync_owner;
GRANT SELECT(id,deleted_at) ON auth.users TO marea_person_sync_owner;
GRANT SELECT(user_id,requested_at) ON public.account_deletion_requests TO marea_person_sync_owner;
-- Private technical read of an already recorded deletion request; no client grant.
CREATE POLICY e2a_sync_deletion_status_read ON public.account_deletion_requests FOR SELECT TO marea_person_sync_owner USING(true);
GRANT SELECT,INSERT ON collaboration.persons TO marea_person_sync_owner;
CREATE POLICY e2a_person_private_read ON collaboration.persons FOR SELECT TO marea_person_sync_owner USING(true);
CREATE POLICY e2a_person_private_insert ON collaboration.persons FOR INSERT TO marea_person_sync_owner WITH CHECK(true);
CREATE TABLE collaboration.person_controls (
 person_id uuid PRIMARY KEY REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 sync_blocked boolean NOT NULL,
 obligations_blocked boolean NOT NULL,
 control_version bigint NOT NULL DEFAULT 1 CHECK(control_version>0),
 blocked_reason text CHECK(blocked_reason IN ('DELETION_PENDING','IDENTITY_REVIEW','SUPPRESSION_REVIEW')),
 deletion_requested_at timestamptz,
 created_source text NOT NULL CHECK(created_source IN ('E1_BACKFILL','AUTH_TRIGGER','ADMIN_REPAIR','FIXTURE')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(sync_blocked=(blocked_reason IS NOT NULL))
);
ALTER TABLE collaboration.person_controls ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON collaboration.person_controls FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT,INSERT ON collaboration.person_controls TO marea_person_sync_owner;
CREATE POLICY e2a_control_private_read ON collaboration.person_controls FOR SELECT TO marea_person_sync_owner USING(true);
CREATE POLICY e2a_control_private_insert ON collaboration.person_controls FOR INSERT TO marea_person_sync_owner WITH CHECK(true);
-- Preserve the existing server-side deletion request as a block, without deleting
-- accounts or deciding retention/suppression policy. Six E1 rows remain unchanged.
INSERT INTO collaboration.person_controls(person_id,sync_blocked,obligations_blocked,blocked_reason,deletion_requested_at,created_source)
 SELECT p.id,d.user_id IS NOT NULL,d.user_id IS NOT NULL,CASE WHEN d.user_id IS NOT NULL THEN 'DELETION_PENDING' END,d.requested_at,'E1_BACKFILL'
 FROM collaboration.persons p LEFT JOIN public.account_deletion_requests d ON d.user_id=p.auth_user_id;
CREATE TABLE collaboration.person_repair_manifests (
 batch_id uuid PRIMARY KEY,
 auth_ids uuid[] NOT NULL CHECK(cardinality(auth_ids) BETWEEN 1 AND 100),
 manifest_hash text NOT NULL CHECK(manifest_hash ~ '^[a-f0-9]{64}$'),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 executed_at timestamptz,
 result jsonb,
 CHECK((executed_at IS NULL)=(result IS NULL))
);
ALTER TABLE collaboration.person_repair_manifests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON collaboration.person_repair_manifests FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT,INSERT ON collaboration.person_repair_manifests TO marea_person_sync_owner;
GRANT UPDATE(executed_at,result) ON collaboration.person_repair_manifests TO marea_person_sync_owner;
CREATE POLICY e2a_manifest_read ON collaboration.person_repair_manifests FOR SELECT TO marea_person_sync_owner USING(true);
CREATE POLICY e2a_manifest_insert ON collaboration.person_repair_manifests FOR INSERT TO marea_person_sync_owner WITH CHECK(true);
CREATE POLICY e2a_manifest_execute ON collaboration.person_repair_manifests FOR UPDATE TO marea_person_sync_owner USING(true) WITH CHECK(true);

CREATE FUNCTION collaboration.person_sync_status(p_auth_id uuid) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p collaboration.persons; c collaboration.person_controls;
BEGIN
 IF p_auth_id IS NULL THEN RETURN 'AUTH_NOT_FOUND'; END IF;
 IF NOT EXISTS(SELECT 1 FROM auth.users WHERE id=p_auth_id) THEN RETURN 'AUTH_NOT_FOUND'; END IF;
 IF EXISTS(SELECT 1 FROM auth.users WHERE id=p_auth_id AND deleted_at IS NOT NULL) THEN RETURN 'AUTH_SUPPRESSED'; END IF;
 IF EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=p_auth_id) THEN RETURN 'DELETION_PENDING'; END IF;
 SELECT * INTO p FROM collaboration.persons WHERE id=p_auth_id;
 IF FOUND AND p.auth_user_id IS DISTINCT FROM p_auth_id THEN
  RETURN CASE WHEN p.auth_user_id IS NULL THEN 'DETACHED_COLLISION' ELSE 'MAPPING_CONFLICT' END;
 END IF;
 SELECT * INTO p FROM collaboration.persons WHERE auth_user_id=p_auth_id;
 IF NOT FOUND THEN RETURN 'MISSING'; END IF;
 SELECT * INTO c FROM collaboration.person_controls WHERE person_id=p.id;
 IF NOT FOUND THEN RETURN 'CONTROL_MISSING'; END IF;
 IF c.sync_blocked OR c.obligations_blocked THEN RETURN 'SYNC_BLOCKED'; END IF;
 RETURN 'READY';
END $$;
ALTER FUNCTION collaboration.person_sync_status(uuid) OWNER TO marea_person_sync_owner;
REVOKE ALL ON FUNCTION collaboration.person_sync_status(uuid) FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION collaboration.ensure_person_for_auth(p_auth_id uuid,p_source text) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE status text; result uuid;
BEGIN
 IF p_auth_id IS NULL OR p_source IS NULL OR p_source NOT IN ('auth_trigger','administrative_repair') THEN
  RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='INVALID_PRIVATE_SYNC_INPUT';
 END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_auth_id::text,4201));
 status:=collaboration.person_sync_status(p_auth_id);
 IF status='READY' THEN
  SELECT id INTO STRICT result FROM collaboration.persons WHERE auth_user_id=p_auth_id;
  RETURN result;
 END IF;
 IF status<>'MISSING' THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='PRINCIPAL_MAPPING_CONFLICT',DETAIL=status;
 END IF;
 -- Equality is a creation convention only. Existing identities always resolve by mapping.
 INSERT INTO collaboration.persons(id,auth_user_id) VALUES(p_auth_id,p_auth_id) RETURNING id INTO result;
 INSERT INTO collaboration.person_controls(person_id,sync_blocked,obligations_blocked,created_source)
 VALUES(result,false,false,CASE WHEN p_source='auth_trigger' THEN 'AUTH_TRIGGER' ELSE 'ADMIN_REPAIR' END);
 RETURN result;
END $$;
ALTER FUNCTION collaboration.ensure_person_for_auth(uuid,text) OWNER TO marea_person_sync_owner;
REVOKE ALL ON FUNCTION collaboration.ensure_person_for_auth(uuid,text) FROM PUBLIC,anon,authenticated,service_role;

CREATE FUNCTION collaboration.person_after_auth_insert() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM collaboration.ensure_person_for_auth(NEW.id,'auth_trigger');
 RETURN NEW;
END $$;
ALTER FUNCTION collaboration.person_after_auth_insert() OWNER TO marea_person_sync_owner;
REVOKE ALL ON FUNCTION collaboration.person_after_auth_insert() FROM PUBLIC,anon,authenticated,service_role;
-- Alphabetically AFTER on_auth_user_created: preserve all legal/profile validators.
CREATE TRIGGER zz_e2a_person_after_auth AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION collaboration.person_after_auth_insert();

CREATE FUNCTION collaboration.stage_person_repair(p_batch_id uuid,p_auth_ids uuid[]) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE ids uuid[]; h text; existing collaboration.person_repair_manifests;
BEGIN
 IF p_batch_id IS NULL OR p_auth_ids IS NULL OR cardinality(p_auth_ids) NOT BETWEEN 1 AND 100
 OR EXISTS(SELECT 1 FROM pg_catalog.unnest(p_auth_ids) i WHERE i IS NULL)
 OR cardinality(p_auth_ids)<>(SELECT count(DISTINCT i) FROM pg_catalog.unnest(p_auth_ids) i) THEN
  RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='INVALID_REPAIR_MANIFEST';
 END IF;
 SELECT pg_catalog.array_agg(i ORDER BY i) INTO ids FROM pg_catalog.unnest(p_auth_ids) i;
 h:=pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(pg_catalog.array_to_string(ids,E'\n'),'UTF8')),'hex');
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_batch_id::text,4202));
 SELECT * INTO existing FROM collaboration.person_repair_manifests WHERE batch_id=p_batch_id;
 IF FOUND THEN
  IF existing.auth_ids IS DISTINCT FROM ids OR existing.manifest_hash IS DISTINCT FROM h THEN
   RAISE EXCEPTION USING ERRCODE='23505',MESSAGE='REPAIR_MANIFEST_CONFLICT';
  END IF;
  RETURN h;
 END IF;
 INSERT INTO collaboration.person_repair_manifests(batch_id,auth_ids,manifest_hash) VALUES(p_batch_id,ids,h);
 RETURN h;
END $$;
ALTER FUNCTION collaboration.stage_person_repair(uuid,uuid[]) OWNER TO marea_person_sync_owner;
REVOKE ALL ON FUNCTION collaboration.stage_person_repair(uuid,uuid[]) FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION collaboration.stage_person_repair(uuid,uuid[]) TO marea_person_repair_operator;

CREATE FUNCTION collaboration.reconcile_persons(p_batch_id uuid,p_manifest_hash text,p_dry_run boolean) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE manifest collaboration.person_repair_manifests; account uuid; status text; person uuid; items jsonb:='[]'::jsonb; conflicts integer:=0; missing integer:=0; ready integer:=0; v_result jsonb;
BEGIN
 IF p_dry_run IS NULL THEN RAISE EXCEPTION USING ERRCODE='22004',MESSAGE='DRY_RUN_REQUIRED'; END IF;
 IF p_dry_run THEN
  SELECT * INTO manifest FROM collaboration.person_repair_manifests WHERE batch_id=p_batch_id;
 ELSE
  SELECT * INTO manifest FROM collaboration.person_repair_manifests WHERE batch_id=p_batch_id FOR UPDATE;
 END IF;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='REPAIR_MANIFEST_REQUIRED'; END IF;
 IF p_manifest_hash IS NULL OR manifest.manifest_hash IS DISTINCT FROM p_manifest_hash THEN
  RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='REPAIR_HASH_MISMATCH';
 END IF;
 IF NOT p_dry_run AND manifest.executed_at IS NOT NULL THEN RETURN manifest.result; END IF;
 FOREACH account IN ARRAY manifest.auth_ids LOOP
  status:=collaboration.person_sync_status(account);
  IF status='MISSING' THEN missing:=missing+1;
  ELSIF status='READY' THEN ready:=ready+1;
  ELSE conflicts:=conflicts+1;
  END IF;
  items:=items||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('auth_id',account,'status',status));
 END LOOP;
 IF p_dry_run THEN RETURN pg_catalog.jsonb_build_object('batch_id',p_batch_id,'manifest_hash',p_manifest_hash,'missing',missing,'ready',ready,'conflicts',conflicts,'items',items,'dry_run',true); END IF;
 IF conflicts<>0 THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='REPAIR_REVIEW_REQUIRED'; END IF;
 items:='[]'::jsonb;
 FOREACH account IN ARRAY manifest.auth_ids LOOP
  person:=collaboration.ensure_person_for_auth(account,'administrative_repair');
  items:=items||pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object('auth_id',account,'person_id',person));
 END LOOP;
 v_result:=pg_catalog.jsonb_build_object('batch_id',p_batch_id,'manifest_hash',p_manifest_hash,'count',cardinality(manifest.auth_ids),'items',items,'dry_run',false);
 UPDATE collaboration.person_repair_manifests SET executed_at=pg_catalog.clock_timestamp(),result=v_result WHERE batch_id=p_batch_id;
 RETURN v_result;
END $$;
ALTER FUNCTION collaboration.reconcile_persons(uuid,text,boolean) OWNER TO marea_person_sync_owner;
REVOKE ALL ON FUNCTION collaboration.reconcile_persons(uuid,text,boolean) FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION collaboration.reconcile_persons(uuid,text,boolean) TO marea_person_repair_operator;
-- No grants to service_role, Auth admin or application roles. Trigger uses NEW.id.
DO $$ BEGIN
 IF (SELECT count(*) FROM collaboration.person_controls)<>6
 OR has_schema_privilege('anon','collaboration','USAGE')
 OR has_schema_privilege('authenticated','collaboration','USAGE')
 OR has_function_privilege('service_role','collaboration.reconcile_persons(uuid,text,boolean)','EXECUTE') THEN
  RAISE EXCEPTION 'E2A_PRIVATE_POSTCONDITION_FAILED';
 END IF;
END $$;
COMMIT;
