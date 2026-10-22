BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
SET LOCAL statement_timeout='25s';
DO $$ BEGIN
 IF to_regprocedure('collaboration.org_require(uuid,text)') IS NULL OR to_regclass('collaboration.mission_ownership') IS NOT NULL THEN RAISE EXCEPTION 'C_PRECONDITION_DRIFT';END IF;
END $$;
CREATE ROLE marea_mission_owner NOLOGIN NOINHERIT;
CREATE ROLE marea_mission_operator NOLOGIN NOINHERIT;
GRANT USAGE ON SCHEMA collaboration,public TO marea_mission_owner;
GRANT USAGE ON SCHEMA collaboration TO marea_mission_operator;
GRANT SELECT ON public.missions TO marea_mission_owner;
CREATE POLICY e2c_mission_read ON public.missions FOR SELECT TO marea_mission_owner USING(true);
GRANT SELECT(id,auth_user_id) ON collaboration.persons TO marea_mission_owner;
CREATE POLICY e2c_person_read ON collaboration.persons FOR SELECT TO marea_mission_owner USING(true);
GRANT SELECT(id,ownership_status,operational_status) ON collaboration.organizations TO marea_mission_owner;
-- PostgreSQL row locks require UPDATE privilege on at least one column.
GRANT UPDATE(version) ON collaboration.organizations TO marea_mission_owner;
CREATE POLICY e2c_org_lock ON collaboration.organizations FOR UPDATE TO marea_mission_owner USING(true) WITH CHECK(true);
GRANT SELECT(organization_id,person_id,role,status,permissions,representative,valid_from,valid_until) ON collaboration.organization_memberships TO marea_mission_owner;
CREATE POLICY e2c_org_read ON collaboration.organizations FOR SELECT TO marea_mission_owner USING(true);
CREATE POLICY e2c_membership_read ON collaboration.organization_memberships FOR SELECT TO marea_mission_owner USING(true);
GRANT EXECUTE ON FUNCTION collaboration.org_person_ready(uuid),collaboration.org_actor_person(),collaboration.org_require(uuid,text) TO marea_mission_owner;

CREATE TABLE collaboration.mission_migration_cases(
 mission_id uuid PRIMARY KEY REFERENCES public.missions(id) ON DELETE RESTRICT,
 migration_state text NOT NULL DEFAULT 'REVIEW_REQUIRED' CHECK(migration_state IN('REVIEW_REQUIRED','CLASSIFIED')),
 source_kind text NOT NULL CHECK(source_kind IN('LEGACY','NEW')),
 mission_hash text NOT NULL CHECK(length(mission_hash)=64),version bigint NOT NULL DEFAULT 1 CHECK(version>0),created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE collaboration.mission_ownership_manifests(
 id uuid PRIMARY KEY,mission_id uuid NOT NULL REFERENCES public.missions(id) ON DELETE RESTRICT,
 mission_hash text NOT NULL CHECK(length(mission_hash)=64),expected_case_version bigint NOT NULL CHECK(expected_case_version>0),
 owner_person_id uuid REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 owner_organization_id uuid REFERENCES collaboration.organizations(id) ON DELETE RESTRICT,
 authorizer_person_id uuid NOT NULL REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 approval_ref text NOT NULL CHECK(approval_ref LIKE 'SYNTHETIC-%'),
 evidence_kind text NOT NULL CHECK(evidence_kind='LAB_DECLARED_OWNERSHIP'),approved boolean NOT NULL CHECK(approved),synthetic boolean NOT NULL CHECK(synthetic),
 input_hash text NOT NULL CHECK(length(input_hash)=64),created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(num_nonnulls(owner_person_id,owner_organization_id)=1)
);
CREATE TABLE collaboration.mission_ownership(
 mission_id uuid PRIMARY KEY REFERENCES public.missions(id) ON DELETE RESTRICT,
 owner_person_id uuid REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 owner_organization_id uuid REFERENCES collaboration.organizations(id) ON DELETE RESTRICT,
 version bigint NOT NULL DEFAULT 1 CHECK(version=1),manifest_id uuid NOT NULL UNIQUE REFERENCES collaboration.mission_ownership_manifests(id) ON DELETE RESTRICT,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),CHECK(num_nonnulls(owner_person_id,owner_organization_id)=1)
);
CREATE TABLE collaboration.mission_classification_operations(
 manifest_id uuid PRIMARY KEY REFERENCES collaboration.mission_ownership_manifests(id) ON DELETE RESTRICT,
 result jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
INSERT INTO collaboration.mission_migration_cases(mission_id,source_kind,mission_hash)
SELECT m.id,'LEGACY',encode(sha256(convert_to(to_jsonb(m)::text,'UTF8')),'hex') FROM public.missions m;
DO $$ DECLARE t text;BEGIN
 FOREACH t IN ARRAY ARRAY['mission_migration_cases','mission_ownership_manifests','mission_ownership','mission_classification_operations'] LOOP
 EXECUTE format('ALTER TABLE collaboration.%I OWNER TO marea_mission_owner',t);
 EXECUTE format('ALTER TABLE collaboration.%I ENABLE ROW LEVEL SECURITY',t);
 EXECUTE format('REVOKE ALL ON collaboration.%I FROM PUBLIC,anon,authenticated,service_role,marea_mission_operator,marea_org_actor',t);
 END LOOP;
END $$;
CREATE FUNCTION collaboration.mission_manifest_authority(p_person uuid,p_org uuid,p_authorizer uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE o collaboration.organizations;
BEGIN
 IF p_authorizer IS NULL OR num_nonnulls(p_person,p_org)<>1 THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='EXPLICIT_OWNERSHIP_AUTHORITY_REQUIRED';END IF;
 PERFORM collaboration.org_person_ready(p_authorizer);
 IF p_person IS NOT NULL THEN
  IF p_person<>p_authorizer THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='PERSONAL_TITULAR_DECLARATION_REQUIRED';END IF;
 ELSE
  SELECT id,ownership_status,operational_status INTO o.id,o.ownership_status,o.operational_status FROM collaboration.organizations WHERE id=p_org FOR UPDATE NOWAIT;
  IF NOT FOUND OR o.ownership_status<>'ACTIVE' OR o.operational_status<>'NORMAL' OR NOT EXISTS(SELECT 1 FROM collaboration.organization_memberships m WHERE m.organization_id=p_org AND m.person_id=p_authorizer AND m.role='owner' AND m.status='ACTIVE' AND m.representative AND 'mission.manage'=ANY(m.permissions) AND m.valid_from<=clock_timestamp() AND m.valid_until>clock_timestamp()) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORGANIZATIONAL_TITULAR_DECLARATION_REQUIRED';END IF;
 END IF;
END $$;
CREATE FUNCTION collaboration.mission_submit_manifest(p_body jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE m collaboration.mission_ownership_manifests;h text:=encode(sha256(convert_to(p_body::text,'UTF8')),'hex');mid uuid:=(p_body->>'id')::uuid;
BEGIN
 IF p_body->>'approved' IS DISTINCT FROM 'true' OR p_body->>'synthetic' IS DISTINCT FROM 'true' OR p_body->>'evidence_kind' IS DISTINCT FROM 'LAB_DECLARED_OWNERSHIP' OR p_body->>'approval_ref' IS NULL OR p_body->>'approval_ref' NOT LIKE 'SYNTHETIC-%' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='EXPLICIT_APPROVED_LAB_EVIDENCE_REQUIRED';END IF;
 PERFORM collaboration.mission_manifest_authority((p_body->>'owner_person_id')::uuid,(p_body->>'owner_organization_id')::uuid,(p_body->>'authorizer_person_id')::uuid);
 IF mid IS NULL OR NOT pg_try_advisory_xact_lock(hashtextextended(mid::text,4400)) THEN RAISE EXCEPTION USING ERRCODE='55P03',MESSAGE='MANIFEST_BUSY_RETRY';END IF;
 SELECT * INTO m FROM collaboration.mission_ownership_manifests WHERE id=mid;
 IF FOUND THEN IF m.input_hash<>h THEN RAISE EXCEPTION USING ERRCODE='23505',MESSAGE='MANIFEST_CONTENT_CONFLICT';END IF;RETURN jsonb_build_object('manifest_id',m.id,'stored',true);END IF;
 INSERT INTO collaboration.mission_ownership_manifests(id,mission_id,mission_hash,expected_case_version,owner_person_id,owner_organization_id,authorizer_person_id,approval_ref,evidence_kind,approved,synthetic,input_hash)
 VALUES(mid,(p_body->>'mission_id')::uuid,p_body->>'mission_hash',(p_body->>'expected_case_version')::bigint,(p_body->>'owner_person_id')::uuid,(p_body->>'owner_organization_id')::uuid,(p_body->>'authorizer_person_id')::uuid,p_body->>'approval_ref',p_body->>'evidence_kind',true,true,h);
 RETURN jsonb_build_object('manifest_id',mid,'stored',true);
END $$;
CREATE FUNCTION collaboration.mission_classify(p_manifest uuid,p_version bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE m collaboration.mission_ownership_manifests;c collaboration.mission_migration_cases;h text;r jsonb;
BEGIN
 SELECT * INTO m FROM collaboration.mission_ownership_manifests WHERE id=p_manifest;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='APPROVED_MANIFEST_REQUIRED';END IF;
 PERFORM collaboration.mission_manifest_authority(m.owner_person_id,m.owner_organization_id,m.authorizer_person_id);
 SELECT * INTO c FROM collaboration.mission_migration_cases WHERE mission_id=m.mission_id FOR UPDATE NOWAIT;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='MIGRATION_CASE_REQUIRED';END IF;
 SELECT result INTO r FROM collaboration.mission_classification_operations WHERE manifest_id=p_manifest;
 IF FOUND THEN RETURN r;END IF;
 IF p_version IS NULL OR p_version<>m.expected_case_version OR c.version<>p_version OR c.migration_state<>'REVIEW_REQUIRED' OR EXISTS(SELECT 1 FROM collaboration.mission_ownership WHERE mission_id=m.mission_id) THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='OWNERSHIP_CLASSIFIER_CONFLICT';END IF;
 SELECT encode(sha256(convert_to(to_jsonb(x)::text,'UTF8')),'hex') INTO h FROM public.missions x WHERE x.id=m.mission_id;
 IF h IS DISTINCT FROM m.mission_hash OR c.mission_hash IS DISTINCT FROM h THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='OWNERSHIP_MANIFEST_HASH_DRIFT';END IF;
 INSERT INTO collaboration.mission_ownership(mission_id,owner_person_id,owner_organization_id,manifest_id) VALUES(m.mission_id,m.owner_person_id,m.owner_organization_id,m.id);
 UPDATE collaboration.mission_migration_cases SET migration_state='CLASSIFIED',version=version+1 WHERE mission_id=m.mission_id;
 r:=jsonb_build_object('mission_id',m.mission_id,'manifest_id',m.id,'ownership_version',1,'case_version',p_version+1,'context',CASE WHEN m.owner_person_id IS NOT NULL THEN 'PERSONAL' ELSE 'ORGANIZATION' END);
 INSERT INTO collaboration.mission_classification_operations(manifest_id,result) VALUES(m.id,r);RETURN r;
END $$;
CREATE FUNCTION collaboration.mission_authorize(p_mission uuid,p_action text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid;o collaboration.mission_ownership;
BEGIN
 p:=collaboration.org_actor_person();
 IF p_action IS NULL OR p_action NOT IN('mission.manage','application.review') THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='MISSION_ACTION_NOT_IMPLEMENTED';END IF;
 SELECT * INTO o FROM collaboration.mission_ownership WHERE mission_id=p_mission;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='OWNERSHIP_REVIEW_REQUIRED';END IF;
 IF o.owner_person_id IS NOT NULL THEN
  IF o.owner_person_id<>p THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='PERSONAL_OWNER_REQUIRED';END IF;
  PERFORM collaboration.org_person_ready(o.owner_person_id);
 ELSE PERFORM collaboration.org_require(o.owner_organization_id,p_action);END IF;
 RETURN jsonb_build_object('authorized',true,'actor_person_id',p,'mission_id',p_mission,'context',CASE WHEN o.owner_person_id IS NOT NULL THEN 'PERSONAL' ELSE 'ORGANIZATION' END,'ownership_version',o.version,'contract_executed',false);
END $$;
CREATE FUNCTION collaboration.mission_new_case() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 INSERT INTO collaboration.mission_migration_cases(mission_id,source_kind,mission_hash) VALUES(NEW.id,'NEW',encode(sha256(convert_to(to_jsonb(NEW)::text,'UTF8')),'hex'));RETURN NEW;
END $$;
CREATE FUNCTION collaboration.mission_owner_at_commit() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM collaboration.mission_ownership WHERE mission_id=NEW.id) THEN RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='MISSION_VALID_OWNER_REQUIRED_AT_COMMIT';END IF;RETURN NULL;
END $$;
CREATE TRIGGER ac_e2c_new_case AFTER INSERT ON public.missions FOR EACH ROW EXECUTE FUNCTION collaboration.mission_new_case();
CREATE CONSTRAINT TRIGGER e2c_owner_at_commit AFTER INSERT ON public.missions DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION collaboration.mission_owner_at_commit();
CREATE FUNCTION collaboration.mission_legacy_write_guard() RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
BEGIN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='UPDATE_REQUIRED_EXPLICIT_OWNERSHIP_PROCEDURE';END $$;
CREATE TRIGGER ac_e2c_legacy_write BEFORE UPDATE OR DELETE ON public.missions FOR EACH ROW EXECUTE FUNCTION collaboration.mission_legacy_write_guard();
CREATE FUNCTION collaboration.mission_ownership_immutable() RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
BEGIN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='OWNERSHIP_EVIDENCE_IMMUTABLE_REQUIRES_APPROVED_PROCEDURE';END $$;
CREATE TRIGGER e2c_ownership_immutable BEFORE UPDATE OR DELETE ON collaboration.mission_ownership FOR EACH ROW EXECUTE FUNCTION collaboration.mission_ownership_immutable();
CREATE TRIGGER e2c_manifest_immutable BEFORE UPDATE OR DELETE ON collaboration.mission_ownership_manifests FOR EACH ROW EXECUTE FUNCTION collaboration.mission_ownership_immutable();
CREATE TRIGGER e2c_receipt_immutable BEFORE UPDATE OR DELETE ON collaboration.mission_classification_operations FOR EACH ROW EXECUTE FUNCTION collaboration.mission_ownership_immutable();
CREATE FUNCTION collaboration.mission_candidature_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE o collaboration.mission_ownership;p uuid;
BEGIN
 IF TG_OP='UPDATE' AND NEW.status NOT IN('pending','accepted') THEN RETURN NEW;END IF;
 IF NEW.status='accepted' THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='UPDATE_REQUIRED_NO_CONTRACTUAL_ENGINE';END IF;
 SELECT * INTO o FROM collaboration.mission_ownership WHERE mission_id=NEW.mission_id;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='OWNERSHIP_REVIEW_REQUIRED';END IF;
 SELECT id INTO p FROM collaboration.persons WHERE auth_user_id=NEW.applicant_id;
 IF p IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='CANDIDATE_PRINCIPAL_REQUIRED';END IF;
 IF o.owner_person_id=p THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='PERSONAL_SELF_APPLICATION_FORBIDDEN';END IF;
 IF o.owner_organization_id IS NOT NULL AND EXISTS(SELECT 1 FROM collaboration.organization_memberships WHERE organization_id=o.owner_organization_id AND person_id=p) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='D10_RELATED_ELIGIBILITY_PENDING';END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER ac_e2c_candidature BEFORE INSERT OR UPDATE OF status,id,applicant_id,mission_id ON public.mission_applications FOR EACH ROW EXECUTE FUNCTION collaboration.mission_candidature_guard();
DO $$ DECLARE f record;BEGIN
 FOR f IN SELECT p.oid::regprocedure signature FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='collaboration' AND p.proname IN('mission_manifest_authority','mission_submit_manifest','mission_classify','mission_authorize','mission_new_case','mission_owner_at_commit','mission_legacy_write_guard','mission_ownership_immutable','mission_candidature_guard') LOOP
 EXECUTE format('ALTER FUNCTION %s OWNER TO marea_mission_owner',f.signature);
 EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated,service_role',f.signature);
 END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION collaboration.mission_submit_manifest(jsonb),collaboration.mission_classify(uuid,bigint) TO marea_mission_operator;
GRANT EXECUTE ON FUNCTION collaboration.mission_authorize(uuid,text) TO marea_org_actor;
COMMIT;
