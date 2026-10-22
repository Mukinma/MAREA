BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
SET LOCAL statement_timeout='30s';
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_proc WHERE oid=to_regprocedure('collaboration.ensure_person_for_auth(uuid,text)'))
 OR (SELECT count(*) FROM pg_trigger WHERE tgname LIKE 'aa_s0_%' AND tgenabled='O')<>40
 OR EXISTS(SELECT 1 FROM pg_roles WHERE rolname LIKE 'marea_deletion_%') THEN RAISE EXCEPTION 'E2B_PRECONDITION_DRIFT'; END IF;
END $$;
CREATE ROLE marea_deletion_owner NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE ROLE marea_deletion_operator NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE ROLE marea_deletion_case_reader NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
GRANT USAGE ON SCHEMA collaboration TO marea_deletion_owner,marea_deletion_operator,marea_deletion_case_reader;
GRANT USAGE ON SCHEMA public,auth,storage TO marea_deletion_owner;

CREATE TABLE collaboration.deletion_policies(
 id text PRIMARY KEY CHECK(id LIKE 'SYNTHETIC-%'),
 category text NOT NULL CHECK(category='STRUCTURAL_REVIEW'),
 purpose text NOT NULL CHECK(purpose='DELETION_REVIEW'),
 responsible_role name NOT NULL,
 retention_seconds integer NOT NULL CHECK(retention_seconds>0),
 conservation_state text NOT NULL CHECK(conservation_state='PROTECTED_PENDING_DECISION'),
 disposition text NOT NULL CHECK(disposition='REVIEW_REQUIRED'),
 synthetic boolean NOT NULL CHECK(synthetic),approved_for_lab boolean NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE collaboration.deletion_requests(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 person_id uuid NOT NULL UNIQUE REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 stage text NOT NULL DEFAULT 'REQUESTED' CHECK(stage IN ('REQUESTED','BLOCKED')),
 version bigint NOT NULL DEFAULT 1 CHECK(version>0),
 requested_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 manifest_hash text CHECK(manifest_hash ~ '^[a-f0-9]{64}$'),
 policy_id text REFERENCES collaboration.deletion_policies(id) ON DELETE RESTRICT,
 CHECK((stage='REQUESTED' AND version=1 AND manifest_hash IS NULL AND policy_id IS NULL) OR (stage='BLOCKED' AND version=2 AND manifest_hash IS NOT NULL))
);
CREATE TABLE collaboration.deletion_operations(
 operation_id uuid PRIMARY KEY,
 person_id uuid NOT NULL REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 request_id uuid NOT NULL REFERENCES collaboration.deletion_requests(id) ON DELETE RESTRICT,
 input_hash text NOT NULL CHECK(input_hash ~ '^[a-f0-9]{64}$'),
 receipt jsonb NOT NULL CHECK(receipt->'completed'='false'::jsonb),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE collaboration.deletion_manifest_items(
 request_id uuid NOT NULL REFERENCES collaboration.deletion_requests(id) ON DELETE RESTRICT,
 category text NOT NULL CHECK(category IN ('PRINCIPAL','MISSION','CANDIDATURE','CANDIDATURE_OPERATION','MEDIA_CANDIDATE')),
 resource_id uuid NOT NULL,
 disposition text NOT NULL DEFAULT 'PROTECTED_PENDING_D_M' CHECK(disposition='PROTECTED_PENDING_D_M'),
 PRIMARY KEY(request_id,category,resource_id)
);
CREATE TABLE collaboration.deletion_dependency_inventory(
 request_id uuid NOT NULL REFERENCES collaboration.deletion_requests(id) ON DELETE RESTRICT,
 relation_name text NOT NULL,constraint_name text NOT NULL,columns text[] NOT NULL,
 referenced_relation text NOT NULL,delete_action text NOT NULL,
 treatment text NOT NULL DEFAULT 'PENDING_CATEGORY_REVIEW' CHECK(treatment='PENDING_CATEGORY_REVIEW'),
 PRIMARY KEY(request_id,relation_name,constraint_name)
);
CREATE TABLE collaboration.deletion_cases(
 id uuid PRIMARY KEY,request_id uuid NOT NULL REFERENCES collaboration.deletion_requests(id) ON DELETE RESTRICT,
 assigned_role name NOT NULL,purpose text NOT NULL CHECK(purpose='DELETION_REVIEW'),
 policy_id text NOT NULL REFERENCES collaboration.deletion_policies(id) ON DELETE RESTRICT,
 expires_at timestamptz NOT NULL,active boolean NOT NULL DEFAULT true
);
CREATE TABLE collaboration.deletion_audit(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),request_id uuid NOT NULL REFERENCES collaboration.deletion_requests(id) ON DELETE RESTRICT,
 case_id uuid REFERENCES collaboration.deletion_cases(id) ON DELETE RESTRICT,
 actor_role name NOT NULL,event text NOT NULL CHECK(event IN ('REQUEST_RECEIVED','MANIFEST_PREPARED','CASE_READ')),
 purpose text NOT NULL CHECK(purpose IN ('USER_REQUEST','DELETION_REVIEW')),
 occurred_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['deletion_policies','deletion_requests','deletion_operations','deletion_manifest_items','deletion_dependency_inventory','deletion_cases','deletion_audit'] LOOP
  EXECUTE format('ALTER TABLE collaboration.%I ENABLE ROW LEVEL SECURITY',t);
  EXECUTE format('REVOKE ALL ON collaboration.%I FROM PUBLIC,anon,authenticated,service_role',t);
  EXECUTE format('GRANT SELECT,INSERT ON collaboration.%I TO marea_deletion_owner',t);
  EXECUTE format('CREATE POLICY e2b_private_read ON collaboration.%I FOR SELECT TO marea_deletion_owner USING(true)',t);
  EXECUTE format('CREATE POLICY e2b_private_insert ON collaboration.%I FOR INSERT TO marea_deletion_owner WITH CHECK(true)',t);
 END LOOP;
END $$;
GRANT UPDATE(stage,version,manifest_hash,policy_id) ON collaboration.deletion_requests TO marea_deletion_owner;
CREATE POLICY e2b_request_update ON collaboration.deletion_requests FOR UPDATE TO marea_deletion_owner USING(true) WITH CHECK(true);
GRANT SELECT ON collaboration.persons,collaboration.person_controls TO marea_deletion_owner;
CREATE POLICY e2b_person_read ON collaboration.persons FOR SELECT TO marea_deletion_owner USING(true);
CREATE POLICY e2b_control_read ON collaboration.person_controls FOR SELECT TO marea_deletion_owner USING(true);
GRANT UPDATE(sync_blocked,obligations_blocked,blocked_reason,deletion_requested_at,control_version) ON collaboration.person_controls TO marea_deletion_owner;
CREATE POLICY e2b_control_update ON collaboration.person_controls FOR UPDATE TO marea_deletion_owner USING(true) WITH CHECK(true);
GRANT SELECT(id,deleted_at) ON auth.users TO marea_deletion_owner;
CREATE POLICY e2b_auth_read ON auth.users FOR SELECT TO marea_deletion_owner USING(true);
GRANT SELECT(user_id,requested_at),INSERT(user_id) ON public.account_deletion_requests TO marea_deletion_owner;
CREATE POLICY e2b_legacy_read ON public.account_deletion_requests FOR SELECT TO marea_deletion_owner USING(true);
CREATE POLICY e2b_legacy_insert ON public.account_deletion_requests FOR INSERT TO marea_deletion_owner WITH CHECK(true);
GRANT SELECT(id,author_id,status) ON public.missions TO marea_deletion_owner;
GRANT SELECT(id,applicant_id,mission_id,status) ON public.mission_applications TO marea_deletion_owner;
GRANT SELECT(operation_id,applicant_id) ON public.mission_application_operations TO marea_deletion_owner;
GRANT SELECT(id,name,bucket_id,owner_id) ON storage.objects TO marea_deletion_owner;
CREATE POLICY e2b_mission_read ON public.missions FOR SELECT TO marea_deletion_owner USING(true);
CREATE POLICY e2b_candidature_read ON public.mission_applications FOR SELECT TO marea_deletion_owner USING(true);
CREATE POLICY e2b_operation_read ON public.mission_application_operations FOR SELECT TO marea_deletion_owner USING(true);
CREATE POLICY e2b_media_read ON storage.objects FOR SELECT TO marea_deletion_owner USING(true);

CREATE FUNCTION collaboration.deletion_lock_person(p_auth uuid) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE person uuid;
BEGIN
 IF p_auth IS NULL THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='AUTH_ID_REQUIRED'; END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_auth::text,0));
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_auth::text,4201));
 IF NOT EXISTS(SELECT 1 FROM auth.users WHERE id=p_auth AND deleted_at IS NULL) THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='CURRENT_AUTH_REQUIRED'; END IF;
 SELECT id INTO person FROM collaboration.persons WHERE auth_user_id=p_auth;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='MAPPING_REQUIRED'; END IF;
 PERFORM 1 FROM collaboration.person_controls WHERE person_id=person FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='CONTROL_REQUIRED'; END IF;
 RETURN person;
END $$;

CREATE FUNCTION collaboration.request_person_deletion(p_auth uuid,p_operation uuid,p_version bigint,p_reason text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE person uuid;op collaboration.deletion_operations;r collaboration.deletion_requests;h text;answer jsonb;
BEGIN
 IF p_operation IS NULL OR p_version IS NULL OR p_version<1 OR p_reason IS DISTINCT FROM 'USER_REQUEST' THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='INVALID_DELETION_REQUEST'; END IF;
 person:=collaboration.deletion_lock_person(p_auth);
 -- Global operation lock precedes key lookup; cross-person key reuse is explicit.
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_operation::text,4203));
 h:=pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(pg_catalog.jsonb_build_object('person_id',person,'expected_version',p_version,'reason',p_reason)::text,'UTF8')),'hex');
 SELECT * INTO op FROM collaboration.deletion_operations WHERE operation_id=p_operation;
 IF FOUND THEN
  IF op.person_id IS DISTINCT FROM person OR op.input_hash IS DISTINCT FROM h THEN RAISE EXCEPTION USING ERRCODE='23505',MESSAGE='DELETION_OPERATION_CONFLICT'; END IF;
  RETURN op.receipt;
 END IF;
 SELECT * INTO r FROM collaboration.deletion_requests WHERE person_id=person FOR UPDATE;
 IF NOT FOUND THEN
  IF p_version<>1 THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='DELETION_VERSION_CONFLICT'; END IF;
  INSERT INTO collaboration.deletion_requests(person_id) VALUES(person) RETURNING * INTO r;
  UPDATE collaboration.person_controls SET sync_blocked=true,obligations_blocked=true,blocked_reason=coalesce(blocked_reason,'DELETION_PENDING'),deletion_requested_at=coalesce(deletion_requested_at,r.requested_at),control_version=control_version+1 WHERE person_id=person;
  INSERT INTO public.account_deletion_requests(user_id) SELECT p_auth WHERE NOT EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=p_auth);
  INSERT INTO collaboration.deletion_audit(request_id,actor_role,event,purpose) VALUES(r.id,'marea_deletion_operator','REQUEST_RECEIVED','USER_REQUEST');
 ELSE
  IF p_version<>r.version THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='DELETION_VERSION_CONFLICT'; END IF;
 END IF;
 answer:=pg_catalog.jsonb_build_object('request_id',r.id,'received_at',r.requested_at,'received',true,'completed',false,'purge_ready',false);
 INSERT INTO collaboration.deletion_operations(operation_id,person_id,request_id,input_hash,receipt) VALUES(p_operation,person,r.id,h,answer);
 RETURN answer;
END $$;

CREATE FUNCTION collaboration.person_deletion_progress(p_auth uuid,p_request uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE person uuid;r collaboration.deletion_requests;c collaboration.person_controls;consistent boolean;
BEGIN
 SELECT id INTO person FROM collaboration.persons WHERE auth_user_id=p_auth;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='CURRENT_MAPPING_REQUIRED'; END IF;
 SELECT * INTO r FROM collaboration.deletion_requests WHERE id=p_request;
 IF NOT FOUND THEN RETURN pg_catalog.jsonb_build_object('request_exists',false,'completed',false,'purge_ready',false,'status','NOT_FOUND'); END IF;
 IF r.person_id<>person THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='REQUEST_SCOPE_REQUIRED'; END IF;
 SELECT * INTO c FROM collaboration.person_controls WHERE person_id=person;
 consistent:=FOUND AND c.sync_blocked AND c.obligations_blocked AND c.deletion_requested_at IS NOT NULL AND EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=p_auth);
 RETURN pg_catalog.jsonb_build_object('request_exists',true,'request_id',r.id,'stage',r.stage,'version',r.version,'consistent',coalesce(consistent,false),'completed',false,'purge_ready',false,'manifest_hash',r.manifest_hash,'policy_status',CASE WHEN r.policy_id IS NULL THEN 'MISSING_POLICY' ELSE 'SYNTHETIC_ONLY' END,'dependencies',pg_catalog.jsonb_build_array('E2_D','E2_M','CONTRACT_ENGINES','TASK003','OPERATIONAL_POLICY','PURGE_NOT_AUTHORIZED'));
END $$;

CREATE FUNCTION collaboration.prepare_person_deletion_manifest(p_request uuid,p_version bigint,p_policy text) RETURNS jsonb
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
 SELECT r.id,'CANDIDATURE',id FROM public.mission_applications WHERE applicant_id=account UNION ALL
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

CREATE FUNCTION collaboration.deletion_case_progress(p_case uuid,p_purpose text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE c collaboration.deletion_cases;r collaboration.deletion_requests;caller name;
BEGIN
 caller:=coalesce(nullif(pg_catalog.current_setting('role'),'none'),session_user)::name;
 SELECT * INTO c FROM collaboration.deletion_cases WHERE id=p_case;
 IF NOT FOUND OR NOT c.active OR c.assigned_role<>caller OR c.purpose IS DISTINCT FROM p_purpose OR c.expires_at<=pg_catalog.clock_timestamp()
 OR NOT EXISTS(SELECT 1 FROM collaboration.deletion_policies WHERE id=c.policy_id AND synthetic AND approved_for_lab AND purpose=p_purpose AND created_at+pg_catalog.make_interval(secs=>retention_seconds)>pg_catalog.clock_timestamp() AND c.expires_at<=created_at+pg_catalog.make_interval(secs=>retention_seconds))
 THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ACTIVE_ASSIGNED_CASE_AND_PURPOSE_REQUIRED'; END IF;
 SELECT * INTO STRICT r FROM collaboration.deletion_requests WHERE id=c.request_id;
 INSERT INTO collaboration.deletion_audit(request_id,case_id,actor_role,event,purpose) VALUES(r.id,c.id,caller,'CASE_READ',p_purpose);
 RETURN pg_catalog.jsonb_build_object('request_id',r.id,'stage',r.stage,'version',r.version,'completed',false,'purge_ready',false,'resource_count',(SELECT count(*) FROM collaboration.deletion_manifest_items WHERE request_id=r.id),'pending_dependency_count',(SELECT count(*) FROM collaboration.deletion_dependency_inventory WHERE request_id=r.id));
END $$;

CREATE FUNCTION collaboration.assert_person_purge_ready(p_request uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 -- B deliberately has no successful completion or purge capability.
 IF NOT EXISTS(SELECT 1 FROM collaboration.deletion_requests WHERE id=p_request) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='PURGE_REQUEST_REQUIRED'; END IF;
 RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='PURGE_DEPENDENCIES_NOT_IMPLEMENTED_OR_AUTHORIZED';
END $$;

CREATE FUNCTION collaboration.deletion_obligation_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE account uuid;person uuid;
BEGIN
 IF TG_TABLE_NAME='missions' THEN
  IF NEW.status<>'open' OR (TG_OP='UPDATE' AND OLD.status='open') THEN RETURN NEW; END IF;
  account:=NEW.author_id;
 ELSE
  IF NEW.status NOT IN('pending','accepted') OR (TG_OP='UPDATE' AND NEW.status=OLD.status) THEN RETURN NEW; END IF;
  account:=NEW.applicant_id;
 END IF;
 person:=collaboration.deletion_lock_person(account);
 IF EXISTS(SELECT 1 FROM collaboration.person_controls WHERE person_id=person AND obligations_blocked)
 OR EXISTS(SELECT 1 FROM collaboration.deletion_requests WHERE person_id=person)
 OR EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=account) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='PERSONAL_OBLIGATIONS_BLOCKED'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER ab_e2b_obligation BEFORE INSERT OR UPDATE OF status ON public.missions FOR EACH ROW EXECUTE FUNCTION collaboration.deletion_obligation_guard();
CREATE TRIGGER ab_e2b_obligation BEFORE INSERT OR UPDATE OF status ON public.mission_applications FOR EACH ROW EXECUTE FUNCTION collaboration.deletion_obligation_guard();

CREATE FUNCTION collaboration.deletion_control_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF EXISTS(SELECT 1 FROM collaboration.deletion_requests WHERE person_id=OLD.person_id) AND
 (NEW.person_id<>OLD.person_id OR NOT NEW.sync_blocked OR NOT NEW.obligations_blocked OR NEW.blocked_reason IS NULL OR NEW.deletion_requested_at IS NULL OR NEW.control_version<=OLD.control_version) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='DELETION_CONTROL_CANNOT_BE_REOPENED'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER ab_e2b_control BEFORE UPDATE ON collaboration.person_controls FOR EACH ROW EXECUTE FUNCTION collaboration.deletion_control_guard();

CREATE FUNCTION collaboration.deletion_append_only() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$ BEGIN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='DELETION_EVIDENCE_APPEND_ONLY'; END $$;
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['deletion_policies','deletion_operations','deletion_manifest_items','deletion_dependency_inventory','deletion_audit'] LOOP
  EXECUTE format('CREATE TRIGGER e2b_append_only BEFORE UPDATE OR DELETE ON collaboration.%I FOR EACH ROW EXECUTE FUNCTION collaboration.deletion_append_only()',t);
 END LOOP;
END $$;
DO $$ DECLARE f record; BEGIN
 FOR f IN SELECT p.oid::regprocedure signature FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='collaboration' AND p.proname IN('deletion_lock_person','request_person_deletion','person_deletion_progress','prepare_person_deletion_manifest','deletion_case_progress','assert_person_purge_ready','deletion_obligation_guard','deletion_control_guard','deletion_append_only') LOOP
  EXECUTE format('ALTER FUNCTION %s OWNER TO marea_deletion_owner',f.signature);
  EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated,service_role',f.signature);
 END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION collaboration.request_person_deletion(uuid,uuid,bigint,text),collaboration.person_deletion_progress(uuid,uuid),collaboration.prepare_person_deletion_manifest(uuid,bigint,text),collaboration.assert_person_purge_ready(uuid) TO marea_deletion_operator;
GRANT EXECUTE ON FUNCTION collaboration.deletion_case_progress(uuid,text) TO marea_deletion_case_reader;
COMMIT;
