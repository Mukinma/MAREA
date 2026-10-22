BEGIN;
SET LOCAL transaction_read_only=off;
SET LOCAL lock_timeout='1500ms';
SET LOCAL statement_timeout='30s';
CREATE OR REPLACE FUNCTION collaboration.request_person_deletion(p_auth uuid,p_operation uuid,p_version bigint,p_reason text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE person uuid;op collaboration.deletion_operations;r collaboration.deletion_requests;h text;answer jsonb;
BEGIN
 IF p_operation IS NULL OR p_version IS NULL OR p_version<1 OR p_reason IS DISTINCT FROM 'USER_REQUEST' THEN RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='INVALID_DELETION_REQUEST'; END IF;
 person:=collaboration.deletion_lock_person(p_auth);
 FOR h IN SELECT id::text FROM public.missions WHERE author_id=p_auth ORDER BY id LOOP
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(h,4204));
 END LOOP;
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

CREATE OR REPLACE FUNCTION collaboration.deletion_obligation_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' SET lock_timeout='1500ms' AS $$
DECLARE account uuid;person uuid;owner_auth uuid;
BEGIN
 IF TG_TABLE_NAME='missions' THEN
  IF NEW.status<>'open' OR (TG_OP='UPDATE' AND OLD.status='open') THEN RETURN NEW; END IF;
  account:=NEW.author_id;
 ELSE
  IF NEW.status NOT IN('pending','accepted') OR (TG_OP='UPDATE' AND NEW.status=OLD.status) THEN RETURN NEW; END IF;
  account:=NEW.applicant_id;
 END IF;
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
COMMIT;
