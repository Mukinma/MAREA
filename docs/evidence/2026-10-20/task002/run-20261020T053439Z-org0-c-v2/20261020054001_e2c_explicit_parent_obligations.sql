BEGIN;SET LOCAL transaction_read_only=off;SET LOCAL lock_timeout='1500ms';SET LOCAL statement_timeout='20s';
CREATE FUNCTION collaboration.mission_obligations_guard(p_mission uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE w collaboration.mission_ownership;o collaboration.organizations;m record;owner_ready boolean:=false;representative_ready boolean:=false;
BEGIN
 SELECT * INTO w FROM collaboration.mission_ownership WHERE mission_id=p_mission;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='OWNERSHIP_REVIEW_REQUIRED';END IF;
 IF w.owner_person_id IS NOT NULL THEN PERFORM collaboration.org_person_ready(w.owner_person_id);RETURN;END IF;
 SELECT id,ownership_status,operational_status INTO o.id,o.ownership_status,o.operational_status FROM collaboration.organizations WHERE id=w.owner_organization_id FOR UPDATE NOWAIT;
 IF NOT FOUND OR o.ownership_status<>'ACTIVE' OR o.operational_status<>'NORMAL' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORGANIZATION_OBLIGATIONS_RESTRICTED';END IF;
 FOR m IN SELECT person_id,role,permissions,representative FROM collaboration.organization_memberships WHERE organization_id=o.id AND status='ACTIVE' AND valid_from<=clock_timestamp() AND valid_until>clock_timestamp() ORDER BY person_id LOOP
  BEGIN
   PERFORM collaboration.org_person_ready(m.person_id);
   IF m.role='owner' THEN owner_ready:=true;END IF;
   IF m.representative AND 'mission.manage'=ANY(m.permissions) THEN representative_ready:=true;END IF;
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
 END LOOP;
 IF NOT owner_ready OR NOT representative_ready THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORGANIZATION_NO_CURRENT_AUTHORIZED_REPRESENTATIVE';END IF;
END $$;
ALTER FUNCTION collaboration.mission_obligations_guard(uuid) OWNER TO marea_mission_owner;
REVOKE ALL ON FUNCTION collaboration.mission_obligations_guard(uuid) FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION collaboration.mission_obligations_guard(uuid) TO marea_deletion_owner;

CREATE OR REPLACE FUNCTION collaboration.deletion_obligation_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
 SET lock_timeout TO '1500ms'
AS $function$
DECLARE account uuid;person uuid;owner_auth uuid;
BEGIN
 IF TG_TABLE_NAME='missions' THEN
  IF NEW.status<>'open' OR (TG_OP='UPDATE' AND OLD.status='open') THEN RETURN NEW; END IF;
  account:=NEW.author_id;
 ELSE
  IF TG_OP='UPDATE' AND (NEW.id IS DISTINCT FROM OLD.id OR NEW.applicant_id IS DISTINCT FROM OLD.applicant_id OR NEW.mission_id IS DISTINCT FROM OLD.mission_id) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='CANDIDATURE_IDENTITY_REBINDING_REQUIRES_D'; END IF;
  IF NEW.status NOT IN('pending','accepted') OR (TG_OP='UPDATE' AND NEW.status=OLD.status) THEN RETURN NEW; END IF;
  account:=NEW.applicant_id;
 END IF;
 IF NOT pg_catalog.pg_try_advisory_xact_lock(pg_catalog.hashtextextended(account::text,0)) THEN RAISE EXCEPTION USING ERRCODE='55P03',MESSAGE='OBLIGATION_LOCK_BUSY_RETRY'; END IF;
 IF NOT pg_catalog.pg_try_advisory_xact_lock(pg_catalog.hashtextextended(account::text,4201)) THEN RAISE EXCEPTION USING ERRCODE='55P03',MESSAGE='OBLIGATION_LOCK_BUSY_RETRY'; END IF;
 person:=collaboration.deletion_lock_person(account);
 IF TG_TABLE_NAME='mission_applications' THEN
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(NEW.mission_id::text,4204));
  PERFORM collaboration.mission_obligations_guard(NEW.mission_id);
 END IF;
 IF EXISTS(SELECT 1 FROM collaboration.person_controls WHERE person_id=person AND obligations_blocked)
 OR EXISTS(SELECT 1 FROM collaboration.deletion_requests WHERE person_id=person)
 OR EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=account) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='PERSONAL_OBLIGATIONS_BLOCKED'; END IF;
 RETURN NEW;
END $function$

COMMIT;
