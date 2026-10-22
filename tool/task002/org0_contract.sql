BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
SET LOCAL statement_timeout='20s';
CREATE ROLE marea_org_owner NOLOGIN NOINHERIT;
CREATE ROLE marea_org_operator NOLOGIN NOINHERIT;
CREATE ROLE marea_org_actor NOLOGIN NOINHERIT;
GRANT USAGE ON SCHEMA collaboration TO marea_org_owner,marea_org_operator,marea_org_actor;
GRANT USAGE ON SCHEMA auth,public TO marea_org_owner;
GRANT SELECT(id,auth_user_id) ON collaboration.persons TO marea_org_owner;
GRANT SELECT(person_id,sync_blocked,obligations_blocked) ON collaboration.person_controls TO marea_org_owner;
GRANT SELECT(id,deleted_at,banned_until,is_anonymous) ON auth.users TO marea_org_owner;
GRANT SELECT(id,initial_profile_completed_at) ON public.profiles TO marea_org_owner;
GRANT SELECT(user_id,adult_confirmed) ON public.legal_acceptances TO marea_org_owner;
GRANT SELECT(user_id) ON public.account_deletion_requests TO marea_org_owner;
CREATE POLICY org0_legacy_deletion_read ON public.account_deletion_requests FOR SELECT TO marea_org_owner USING(true);
CREATE POLICY org0_person_read ON collaboration.persons FOR SELECT TO marea_org_owner USING(true);
CREATE POLICY org0_control_read ON collaboration.person_controls FOR SELECT TO marea_org_owner USING(true);
CREATE POLICY org0_auth_read ON auth.users FOR SELECT TO marea_org_owner USING(true);
CREATE POLICY org0_profile_read ON public.profiles FOR SELECT TO marea_org_owner USING(true);
CREATE POLICY org0_legal_read ON public.legal_acceptances FOR SELECT TO marea_org_owner USING(true);

CREATE TABLE collaboration.organizations(
 id uuid PRIMARY KEY,name text NOT NULL CHECK(length(name) BETWEEN 1 AND 160),
 ownership_status text NOT NULL DEFAULT 'ACTIVE' CHECK(ownership_status IN('ACTIVE','TRANSFER_PENDING','UNOWNED_RESTRICTED','CLOSING','CLOSED')),
 operational_status text NOT NULL DEFAULT 'NORMAL' CHECK(operational_status IN('NORMAL','PAUSED','SUSPENDED')),
 version bigint NOT NULL DEFAULT 1 CHECK(version>0),created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 approval_ref text NOT NULL CHECK(length(approval_ref)>0)
);
CREATE TABLE collaboration.organization_memberships(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL REFERENCES collaboration.organizations(id) ON DELETE RESTRICT,
 person_id uuid NOT NULL REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 role text NOT NULL CHECK(role IN('owner','administrator','editor','member')),
 status text NOT NULL CHECK(status IN('INVITED','ACTIVE','DECLINED','REVOKED')),
 permissions text[] NOT NULL CHECK(permissions <@ ARRAY['organization.view','venue.manage','mission.manage','application.review','agreement.offer','agreement.accept','event.manage','member.manage']::text[] AND array_position(permissions,NULL) IS NULL),
 representative boolean NOT NULL DEFAULT false,
 invited_by uuid NOT NULL REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 valid_from timestamptz NOT NULL DEFAULT clock_timestamp(),valid_until timestamptz NOT NULL DEFAULT 'infinity',
 version bigint NOT NULL DEFAULT 1 CHECK(version>0),created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(valid_until>valid_from),CHECK(role<>'editor' OR NOT permissions && ARRAY['agreement.offer','agreement.accept']::text[]),
 UNIQUE(organization_id,person_id)
);
CREATE INDEX org0_member_person ON collaboration.organization_memberships(person_id,organization_id);
CREATE TABLE collaboration.org_session_bindings(
 role_name text PRIMARY KEY CHECK(role_name LIKE 'marea_org_fixture_%'),person_id uuid NOT NULL REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 approval_ref text NOT NULL CHECK(approval_ref LIKE 'SYNTHETIC-%')
);
CREATE TABLE collaboration.org_operations(
 id uuid PRIMARY KEY,actor_person_id uuid NOT NULL REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 input_hash text NOT NULL CHECK(length(input_hash)=64),result jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE collaboration.org_audit(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL REFERENCES collaboration.organizations(id) ON DELETE RESTRICT,
 actor_person_id uuid NOT NULL REFERENCES collaboration.persons(id) ON DELETE RESTRICT,
 action text NOT NULL,resource_id uuid NOT NULL,operation_id uuid NOT NULL UNIQUE REFERENCES collaboration.org_operations(id) ON DELETE RESTRICT,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['organizations','organization_memberships','org_session_bindings','org_operations','org_audit'] LOOP
 EXECUTE format('ALTER TABLE collaboration.%I OWNER TO marea_org_owner',t);
 EXECUTE format('ALTER TABLE collaboration.%I ENABLE ROW LEVEL SECURITY',t);
 EXECUTE format('REVOKE ALL ON collaboration.%I FROM PUBLIC,anon,authenticated,service_role,marea_org_actor,marea_org_operator',t);
 END LOOP;
END $$;

CREATE FUNCTION collaboration.org_person_ready(p_person uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE a uuid;sb boolean;ob boolean;
BEGIN
 IF current_setting('transaction_isolation') IS DISTINCT FROM 'read committed' THEN RAISE EXCEPTION USING ERRCODE='0A000',MESSAGE='FRESH_READ_COMMITTED_REQUIRED';END IF;
 SELECT auth_user_id INTO a FROM collaboration.persons WHERE id=p_person;
 IF a IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_PRINCIPAL_NOT_CURRENT'; END IF;
 IF NOT pg_try_advisory_xact_lock(hashtextextended(a::text,0)) OR NOT pg_try_advisory_xact_lock(hashtextextended(a::text,4201)) THEN RAISE EXCEPTION USING ERRCODE='55P03',MESSAGE='ORG_PERSON_BUSY_RETRY'; END IF;
 SELECT sync_blocked,obligations_blocked INTO sb,ob FROM collaboration.person_controls WHERE person_id=p_person;
 IF NOT FOUND OR sb OR ob OR EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id=a) OR NOT EXISTS(SELECT 1 FROM auth.users u WHERE u.id=a AND u.deleted_at IS NULL AND NOT u.is_anonymous AND (u.banned_until IS NULL OR u.banned_until<=clock_timestamp())) OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=a AND initial_profile_completed_at IS NOT NULL) OR NOT EXISTS(SELECT 1 FROM public.legal_acceptances WHERE user_id=a AND adult_confirmed) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_PERSON_NOT_ELIGIBLE_OR_BLOCKED'; END IF;
 RETURN a;
END $$;
CREATE FUNCTION collaboration.org_actor_person() RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid;r text:=coalesce(nullif(current_setting('role',true),'none'),session_user);
BEGIN
 SELECT person_id INTO p FROM collaboration.org_session_bindings WHERE role_name=r;
 IF p IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_VERIFIED_SUBJECT_REQUIRED'; END IF;
 PERFORM collaboration.org_person_ready(p);RETURN p;
END $$;
CREATE FUNCTION collaboration.org_require(p_org uuid,p_action text) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
END $$;
CREATE FUNCTION collaboration.org_authorize(p_org uuid,p_action text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid;BEGIN p:=collaboration.org_require(p_org,p_action);RETURN jsonb_build_object('authorized',true,'actor_person_id',p,'organization_id',p_org,'action',p_action,'contract_executed',false);END $$;
CREATE FUNCTION collaboration.org_replay(p_op uuid,p_actor uuid,p_body jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE x collaboration.org_operations;h text:=encode(sha256(convert_to(p_body::text,'UTF8')),'hex');
BEGIN
 IF p_op IS NULL THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='OPERATION_REQUIRED'; END IF;
 IF NOT pg_try_advisory_xact_lock(hashtextextended(p_op::text,4300)) THEN RAISE EXCEPTION USING ERRCODE='55P03',MESSAGE='ORG_OPERATION_BUSY_RETRY'; END IF;
 SELECT * INTO x FROM collaboration.org_operations WHERE id=p_op;
 IF FOUND THEN IF x.actor_person_id<>p_actor OR x.input_hash<>h THEN RAISE EXCEPTION USING ERRCODE='23505',MESSAGE='ORG_OPERATION_CONTENT_CONFLICT';END IF;RETURN x.result;END IF;
 RETURN NULL;
END $$;
CREATE FUNCTION collaboration.org_record(p_op uuid,p_actor uuid,p_body jsonb,p_result jsonb,p_org uuid,p_action text,p_resource uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 INSERT INTO collaboration.org_operations(id,actor_person_id,input_hash,result) VALUES(p_op,p_actor,encode(sha256(convert_to(p_body::text,'UTF8')),'hex'),p_result);
 INSERT INTO collaboration.org_audit(organization_id,actor_person_id,action,resource_id,operation_id) VALUES(p_org,p_actor,p_action,p_resource,p_op);RETURN p_result;
END $$;
CREATE FUNCTION collaboration.org_provision(p_manifest jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid:=(p_manifest->>'owner_person_id')::uuid;o uuid:=(p_manifest->>'organization_id')::uuid;op uuid:=(p_manifest->>'operation_id')::uuid;caps text[];m uuid;r jsonb;
BEGIN
 IF p_manifest->>'synthetic' IS DISTINCT FROM 'true' OR p_manifest->>'approval_ref' IS NULL OR p_manifest->>'approval_ref' NOT LIKE 'SYNTHETIC-%' OR p_manifest->>'name' NOT LIKE 'Synthetic %' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='LAB_APPROVED_MANIFEST_REQUIRED';END IF;
 PERFORM collaboration.org_person_ready(p);r:=collaboration.org_replay(op,p,p_manifest);IF r IS NOT NULL THEN RETURN r;END IF;
 SELECT array_agg(v) INTO caps FROM jsonb_array_elements_text(p_manifest->'permissions') v;
 INSERT INTO collaboration.organizations(id,name,approval_ref) VALUES(o,p_manifest->>'name',p_manifest->>'approval_ref');
 INSERT INTO collaboration.organization_memberships(organization_id,person_id,role,status,permissions,representative,invited_by) VALUES(o,p,'owner','ACTIVE',caps,true,p) RETURNING id INTO m;
 RETURN collaboration.org_record(op,p,p_manifest,jsonb_build_object('organization_id',o,'membership_id',m,'version',1),o,'LAB_EXPLICIT_PROVISION',m);
END $$;
CREATE FUNCTION collaboration.org_invite(p_op uuid,p_org uuid,p_target uuid,p_role text,p_permissions text[],p_representative boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid;b jsonb;r jsonb;caps text[];m uuid;
BEGIN
 p:=collaboration.org_require(p_org,'member.manage');
 b:=jsonb_build_object('action','invite','org',p_org,'target',p_target,'role',p_role,'permissions',p_permissions,'representative',p_representative);r:=collaboration.org_replay(p_op,p,b);IF r IS NOT NULL THEN RETURN r;END IF;
 SELECT permissions INTO caps FROM collaboration.organization_memberships WHERE organization_id=p_org AND person_id=p;
 IF p_role IS NULL OR p_role NOT IN('administrator','editor','member') OR p_permissions IS NULL OR NOT p_permissions<@caps OR array_position(p_permissions,NULL) IS NOT NULL OR (p_role='editor' AND p_permissions&&ARRAY['agreement.offer','agreement.accept']::text[]) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_DELEGATION_NOT_AUTHORIZED';END IF;
 PERFORM collaboration.org_person_ready(p_target);
 INSERT INTO collaboration.organization_memberships(organization_id,person_id,role,status,permissions,representative,invited_by) VALUES(p_org,p_target,p_role,'INVITED',p_permissions,p_representative,p) RETURNING id INTO m;
 RETURN collaboration.org_record(p_op,p,b,jsonb_build_object('membership_id',m,'status','INVITED','version',1),p_org,'INVITE',m);
END $$;
CREATE FUNCTION collaboration.org_respond(p_op uuid,p_membership uuid,p_accept boolean,p_version bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid;o collaboration.organizations;m collaboration.organization_memberships;b jsonb;r jsonb;oid uuid;
BEGIN
 p:=collaboration.org_actor_person();SELECT organization_id INTO oid FROM collaboration.organization_memberships WHERE id=p_membership;
 SELECT * INTO o FROM collaboration.organizations WHERE id=oid FOR UPDATE NOWAIT;
 IF NOT FOUND OR o.ownership_status<>'ACTIVE' OR o.operational_status<>'NORMAL' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='ORG_STATE_RESTRICTED';END IF;
 SELECT * INTO m FROM collaboration.organization_memberships WHERE id=p_membership FOR UPDATE NOWAIT;
 IF m.person_id IS DISTINCT FROM p THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='INVITATION_RECIPIENT_REQUIRED';END IF;
 b:=jsonb_build_object('action','respond','membership',p_membership,'accept',p_accept,'version',p_version);r:=collaboration.org_replay(p_op,p,b);IF r IS NOT NULL THEN RETURN r;END IF;
 IF m.status<>'INVITED' OR m.valid_until<=clock_timestamp() OR m.valid_from>clock_timestamp() OR p_accept IS NULL OR p_version IS NULL OR m.version<>p_version THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='INVITATION_VERSION_OR_STATE_CONFLICT';END IF;
 IF p_accept THEN
 PERFORM collaboration.org_person_ready(m.invited_by);
 -- The delegator must still hold the delegated authority at acceptance time.
 IF NOT EXISTS(SELECT 1 FROM collaboration.organization_memberships x JOIN collaboration.person_controls c ON c.person_id=x.person_id WHERE x.organization_id=oid AND x.person_id=m.invited_by AND x.status='ACTIVE' AND x.representative AND 'member.manage'=ANY(x.permissions) AND m.permissions<@x.permissions AND x.valid_from<=clock_timestamp() AND x.valid_until>clock_timestamp() AND NOT c.sync_blocked AND NOT c.obligations_blocked) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='INVITATION_DELEGATOR_NOT_CURRENT';END IF;
 END IF;
 UPDATE collaboration.organization_memberships SET status=CASE WHEN p_accept THEN 'ACTIVE' ELSE 'DECLINED' END,version=version+1 WHERE id=p_membership RETURNING * INTO m;
 RETURN collaboration.org_record(p_op,p,b,jsonb_build_object('membership_id',m.id,'status',m.status,'version',m.version),oid,'RESPOND',m.id);
END $$;
CREATE FUNCTION collaboration.org_revoke(p_op uuid,p_membership uuid,p_version bigint) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid;m collaboration.organization_memberships;oid uuid;b jsonb;r jsonb;
BEGIN
 SELECT organization_id INTO oid FROM collaboration.organization_memberships WHERE id=p_membership;p:=collaboration.org_require(oid,'member.manage');
 b:=jsonb_build_object('action','revoke','membership',p_membership,'version',p_version);r:=collaboration.org_replay(p_op,p,b);IF r IS NOT NULL THEN RETURN r;END IF;
 SELECT * INTO m FROM collaboration.organization_memberships WHERE id=p_membership FOR UPDATE NOWAIT;
 IF p_version IS NULL OR m.version<>p_version OR m.status NOT IN('ACTIVE','INVITED') THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='MEMBERSHIP_VERSION_OR_STATE_CONFLICT';END IF;
 UPDATE collaboration.organization_memberships SET status='REVOKED',version=version+1 WHERE id=m.id RETURNING * INTO m;
 RETURN collaboration.org_record(p_op,p,b,jsonb_build_object('membership_id',m.id,'status',m.status,'version',m.version),oid,'REVOKE',m.id);
END $$;
CREATE FUNCTION collaboration.org_membership_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF TG_OP='DELETE' THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='ORG_MEMBERSHIP_DELETE_FORBIDDEN';END IF;
 IF (NEW.id,NEW.organization_id,NEW.person_id,NEW.role,NEW.permissions,NEW.representative,NEW.invited_by,NEW.valid_from,NEW.valid_until,NEW.created_at) IS DISTINCT FROM (OLD.id,OLD.organization_id,OLD.person_id,OLD.role,OLD.permissions,OLD.representative,OLD.invited_by,OLD.valid_from,OLD.valid_until,OLD.created_at) OR NEW.version<>OLD.version+1 OR NOT((OLD.status='INVITED' AND NEW.status IN('ACTIVE','DECLINED','REVOKED')) OR (OLD.status='ACTIVE' AND NEW.status='REVOKED')) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='ORG_MEMBERSHIP_TRANSITION_FORBIDDEN';END IF;
 IF OLD.role='owner' AND OLD.status='ACTIVE' AND NEW.status<>'ACTIVE' AND NOT EXISTS(SELECT 1 FROM collaboration.organization_memberships x WHERE x.organization_id=OLD.organization_id AND x.id<>OLD.id AND x.role='owner' AND x.status='ACTIVE' AND x.valid_from<=clock_timestamp() AND x.valid_until>clock_timestamp()) THEN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='LAST_OWNER_REQUIRES_APPROVED_TRANSFER_OR_CLOSURE';END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER org0_membership_guard BEFORE UPDATE OR DELETE ON collaboration.organization_memberships FOR EACH ROW EXECUTE FUNCTION collaboration.org_membership_guard();
CREATE FUNCTION collaboration.org_append_only() RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$ BEGIN RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='ORG_EVIDENCE_APPEND_ONLY';END $$;
CREATE TRIGGER org0_operations_immutable BEFORE UPDATE OR DELETE ON collaboration.org_operations FOR EACH ROW EXECUTE FUNCTION collaboration.org_append_only();
CREATE TRIGGER org0_audit_immutable BEFORE UPDATE OR DELETE ON collaboration.org_audit FOR EACH ROW EXECUTE FUNCTION collaboration.org_append_only();
CREATE TRIGGER org0_bindings_immutable BEFORE UPDATE OR DELETE ON collaboration.org_session_bindings FOR EACH ROW EXECUTE FUNCTION collaboration.org_append_only();
CREATE TRIGGER org0_organization_delete BEFORE DELETE ON collaboration.organizations FOR EACH ROW EXECUTE FUNCTION collaboration.org_append_only();
DO $$ DECLARE f record;BEGIN
 FOR f IN SELECT p.oid::regprocedure signature FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='collaboration' AND p.proname LIKE 'org\_%' ESCAPE '\' LOOP
 EXECUTE format('ALTER FUNCTION %s OWNER TO marea_org_owner',f.signature);
 EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated,service_role',f.signature);
 END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION collaboration.org_provision(jsonb) TO marea_org_operator;
GRANT EXECUTE ON FUNCTION collaboration.org_authorize(uuid,text),collaboration.org_invite(uuid,uuid,uuid,text,text[],boolean),collaboration.org_respond(uuid,uuid,boolean,bigint),collaboration.org_revoke(uuid,uuid,bigint) TO marea_org_actor;
COMMIT;
