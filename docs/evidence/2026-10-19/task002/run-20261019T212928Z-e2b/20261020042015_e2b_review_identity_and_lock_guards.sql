BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
SET LOCAL statement_timeout='30s';
CREATE OR REPLACE FUNCTION collaboration.deletion_obligation_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
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
  SELECT author_id INTO STRICT owner_auth FROM public.missions WHERE id=NEW.mission_id;
  IF EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=owner_auth)
  OR EXISTS(SELECT 1 FROM collaboration.persons p JOIN collaboration.person_controls c ON c.person_id=p.id WHERE p.auth_user_id=owner_auth AND c.obligations_blocked)
  OR NOT EXISTS(SELECT 1 FROM collaboration.persons p JOIN collaboration.person_controls c ON c.person_id=p.id WHERE p.auth_user_id=owner_auth)
  THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='MISSION_OWNER_OBLIGATIONS_BLOCKED'; END IF;
 END IF;
 IF EXISTS(SELECT 1 FROM collaboration.person_controls WHERE person_id=person AND obligations_blocked)
 OR EXISTS(SELECT 1 FROM collaboration.deletion_requests WHERE person_id=person)
 OR EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=account) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='PERSONAL_OBLIGATIONS_BLOCKED'; END IF;
 RETURN NEW;
END $$;
DROP TRIGGER ab_e2b_obligation ON public.mission_applications;
CREATE TRIGGER ab_e2b_obligation BEFORE INSERT OR UPDATE OF status,id,applicant_id,mission_id ON public.mission_applications FOR EACH ROW EXECUTE FUNCTION collaboration.deletion_obligation_guard();
COMMIT;
