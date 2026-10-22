BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
CREATE FUNCTION collaboration.mission_validate_ownership_evidence() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE m collaboration.mission_ownership_manifests;h text;
BEGIN
 SELECT * INTO m FROM collaboration.mission_ownership_manifests WHERE id=NEW.manifest_id;
 IF NOT FOUND OR (NEW.mission_id,NEW.owner_person_id,NEW.owner_organization_id) IS DISTINCT FROM (m.mission_id,m.owner_person_id,m.owner_organization_id) THEN RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='OWNERSHIP_MANIFEST_RESOURCE_OR_PARTY_MISMATCH';END IF;
 SELECT encode(sha256(convert_to(to_jsonb(x)::text,'UTF8')),'hex') INTO h FROM public.missions x WHERE x.id=NEW.mission_id;
 IF h IS DISTINCT FROM m.mission_hash THEN RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='OWNERSHIP_MANIFEST_CONTENT_MISMATCH';END IF;
 RETURN NEW;
END $$;
ALTER FUNCTION collaboration.mission_validate_ownership_evidence() OWNER TO marea_mission_owner;
REVOKE ALL ON FUNCTION collaboration.mission_validate_ownership_evidence() FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER e2c_ownership_evidence BEFORE INSERT ON collaboration.mission_ownership FOR EACH ROW EXECUTE FUNCTION collaboration.mission_validate_ownership_evidence();
CREATE OR REPLACE FUNCTION collaboration.mission_owner_at_commit() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE mid uuid;
BEGIN
 IF TG_TABLE_SCHEMA='public' THEN mid:=NEW.id;ELSE mid:=NEW.mission_id;END IF;
 IF NOT EXISTS(SELECT 1 FROM collaboration.mission_ownership w JOIN collaboration.mission_ownership_manifests m ON m.id=w.manifest_id JOIN collaboration.mission_migration_cases c ON c.mission_id=w.mission_id JOIN collaboration.mission_classification_operations p ON p.manifest_id=m.id WHERE w.mission_id=mid AND m.mission_id=w.mission_id AND c.migration_state='CLASSIFIED' AND c.version=m.expected_case_version+1 AND c.mission_hash=m.mission_hash AND p.result->>'mission_id'=mid::text AND p.result->>'manifest_id'=m.id::text AND (w.owner_person_id,w.owner_organization_id) IS NOT DISTINCT FROM (m.owner_person_id,m.owner_organization_id)) THEN RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='MISSION_VALID_OWNER_CLASSIFIED_CASE_RECEIPT_REQUIRED_AT_COMMIT';END IF;
 RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER e2c_ownership_at_commit AFTER INSERT ON collaboration.mission_ownership DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION collaboration.mission_owner_at_commit();
COMMIT;
