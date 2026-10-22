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
