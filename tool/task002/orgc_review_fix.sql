BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
GRANT SELECT(initial_profile_completed_at) ON public.profiles TO marea_org_owner;
CREATE OR REPLACE FUNCTION collaboration.org_person_ready(p_person uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE a uuid;sb boolean;ob boolean;
BEGIN
 IF current_setting('transaction_isolation') IS DISTINCT FROM 'read committed' THEN RAISE EXCEPTION USING ERRCODE='0A000',MESSAGE='FRESH_READ_COMMITTED_REQUIRED';END IF;
 SELECT auth_user_id INTO a FROM collaboration.persons WHERE id=p_person;
 IF a IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_PRINCIPAL_NOT_CURRENT'; END IF;
 IF NOT pg_try_advisory_xact_lock(hashtextextended(a::text,0)) OR NOT pg_try_advisory_xact_lock(hashtextextended(a::text,4201)) THEN RAISE EXCEPTION USING ERRCODE='55P03',MESSAGE='ORG_PERSON_BUSY_RETRY'; END IF;
 SELECT sync_blocked,obligations_blocked INTO sb,ob FROM collaboration.person_controls WHERE person_id=p_person;
 IF NOT FOUND OR sb OR ob OR EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=a) OR NOT EXISTS(SELECT 1 FROM auth.users u WHERE u.id=a AND u.deleted_at IS NULL AND NOT u.is_anonymous AND (u.banned_until IS NULL OR u.banned_until<=clock_timestamp())) OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=a AND initial_profile_completed_at IS NOT NULL) OR NOT EXISTS(SELECT 1 FROM public.legal_acceptances WHERE user_id=a AND adult_confirmed) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_PERSON_NOT_ELIGIBLE_OR_BLOCKED'; END IF;
 RETURN a;
END $function$;
CREATE OR REPLACE FUNCTION collaboration.org_require(p_org uuid, p_action text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE p uuid;o collaboration.organizations;m collaboration.organization_memberships;
BEGIN
 p:=collaboration.org_actor_person();
 IF p_action IS NULL OR p_action NOT IN('organization.view','venue.manage','mission.manage','application.review','agreement.offer','agreement.accept','event.manage','member.manage') THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_UNKNOWN_ACTION'; END IF;
 SELECT * INTO o FROM collaboration.organizations WHERE id=p_org FOR UPDATE NOWAIT;
 IF NOT FOUND OR o.ownership_status<>'ACTIVE' OR o.operational_status<>'NORMAL' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_STATE_RESTRICTED'; END IF;
 SELECT * INTO m FROM collaboration.organization_memberships WHERE organization_id=p_org AND person_id=p;
 IF NOT FOUND OR m.status<>'ACTIVE' OR m.valid_from>clock_timestamp() OR m.valid_until<=clock_timestamp() OR NOT p_action=ANY(m.permissions) OR (p_action<>'organization.view' AND NOT m.representative) OR (m.role='editor' AND p_action IN('agreement.offer','agreement.accept')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_CURRENT_REPRESENTATION_REQUIRED'; END IF;
 IF p_action<>'organization.view' AND NOT EXISTS(SELECT 1 FROM collaboration.organization_memberships x JOIN collaboration.person_controls c ON c.person_id=x.person_id JOIN collaboration.persons q ON q.id=x.person_id JOIN auth.users u ON u.id=q.auth_user_id WHERE x.organization_id=p_org AND x.role='owner' AND x.status='ACTIVE' AND x.valid_from<=clock_timestamp() AND x.valid_until>clock_timestamp() AND NOT c.sync_blocked AND NOT c.obligations_blocked AND u.deleted_at IS NULL AND NOT u.is_anonymous AND (u.banned_until IS NULL OR u.banned_until<=clock_timestamp()) AND NOT EXISTS(SELECT 1 FROM public.account_deletion_requests d WHERE d.user_id=u.id) AND EXISTS(SELECT 1 FROM public.profiles f WHERE f.id=u.id AND f.initial_profile_completed_at IS NOT NULL)) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_NO_CURRENT_OWNER_RESTRICTED'; END IF;
 RETURN p;
END $function$;
CREATE OR REPLACE FUNCTION collaboration.mission_classify(p_manifest uuid, p_version bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE m collaboration.mission_ownership_manifests;c collaboration.mission_migration_cases;h text;r jsonb;
BEGIN
 SELECT * INTO m FROM collaboration.mission_ownership_manifests WHERE id=p_manifest;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='APPROVED_MANIFEST_REQUIRED';END IF;
 PERFORM collaboration.mission_manifest_authority(m.owner_person_id,m.owner_organization_id,m.authorizer_person_id);
 SELECT * INTO c FROM collaboration.mission_migration_cases WHERE mission_id=m.mission_id FOR UPDATE NOWAIT;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='MIGRATION_CASE_REQUIRED';END IF;
 IF p_version IS NULL OR p_version<>m.expected_case_version THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='OWNERSHIP_REPLAY_VERSION_CONFLICT';END IF;
 SELECT result INTO r FROM collaboration.mission_classification_operations WHERE manifest_id=p_manifest;
 IF FOUND THEN RETURN r;END IF;
 IF p_version IS NULL OR p_version<>m.expected_case_version OR c.version<>p_version OR c.migration_state<>'REVIEW_REQUIRED' OR EXISTS(SELECT 1 FROM collaboration.mission_ownership WHERE mission_id=m.mission_id) THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='OWNERSHIP_CLASSIFIER_CONFLICT';END IF;
 SELECT encode(sha256(convert_to(to_jsonb(x)::text,'UTF8')),'hex') INTO h FROM public.missions x WHERE x.id=m.mission_id;
 IF h IS DISTINCT FROM m.mission_hash OR c.mission_hash IS DISTINCT FROM h THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='OWNERSHIP_MANIFEST_HASH_DRIFT';END IF;
 INSERT INTO collaboration.mission_ownership(mission_id,owner_person_id,owner_organization_id,manifest_id) VALUES(m.mission_id,m.owner_person_id,m.owner_organization_id,m.id);
 UPDATE collaboration.mission_migration_cases SET migration_state='CLASSIFIED',version=version+1 WHERE mission_id=m.mission_id;
 r:=jsonb_build_object('mission_id',m.mission_id,'manifest_id',m.id,'ownership_version',1,'case_version',p_version+1,'context',CASE WHEN m.owner_person_id IS NOT NULL THEN 'PERSONAL' ELSE 'ORGANIZATION' END);
 INSERT INTO collaboration.mission_classification_operations(manifest_id,result) VALUES(m.id,r);RETURN r;
END $function$;
COMMIT;
