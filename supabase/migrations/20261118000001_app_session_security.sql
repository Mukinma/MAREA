-- JWT validity alone is insufficient after logout. Auth removes the sessions
-- affected by a scoped sign-out; verify existence and ownership before data access.
create function private.app_session_error()
returns text language sql stable security definer set search_path='' as $$
  select case
    when not exists (
      select 1 from auth.sessions s
      where s.id::text = (select auth.jwt()->>'session_id')
        and s.user_id = (select auth.uid())
        and (s.not_after is null or s.not_after > statement_timestamp())
    ) then 'session_invalid'
    when (select auth.jwt()->>'aal') is distinct from 'aal2'
      and exists (
        select 1 from auth.mfa_factors f
        where f.user_id = (select auth.uid()) and f.status = 'verified'
      ) then 'mfa_required'
    else null
  end;
$$;
revoke all on function private.app_session_error() from public,anon,authenticated;

create function private.session_can_access()
returns boolean language sql stable security definer set search_path='' as $$
  select private.app_session_error() is null;
$$;
revoke all on function private.session_can_access() from public,anon,authenticated;
grant execute on function private.session_can_access() to authenticated;

create function public.require_app_session()
returns void language plpgsql stable security definer set search_path='' as $$
declare denial text := private.app_session_error();
begin
  if denial is not null then
    raise exception '%', denial using errcode = 'PT403';
  end if;
end;
$$;
revoke all on function public.require_app_session() from public,anon,authenticated;
grant execute on function public.require_app_session() to authenticated;

-- PostgREST checks tables, views and RPCs, including legacy definer functions.
-- The public registration policy also supplies support details before sign-in.
create schema marea_access;
revoke all on schema marea_access from public;
grant usage on schema marea_access to anon,authenticated,service_role;

create function marea_access.enforce_app_session()
returns void language plpgsql stable security invoker set search_path='' as $$
begin
  if current_user = 'authenticated'
      and current_setting('request.path', true) is distinct from '/rpc/registration_policy' then
    perform public.require_app_session();
  end if;
end;
$$;
revoke all on function marea_access.enforce_app_session() from public;
grant execute on function marea_access.enforce_app_session() to anon,authenticated,service_role;
-- Do not silently replace an independently installed pre-request hook.
do $$
declare
  existing text;
begin
  select split_part(entry, '=', 2) into existing
  from pg_catalog.pg_roles, unnest(rolconfig) as entry
  where rolname = 'authenticator' and entry like 'pgrst.db_pre_request=%';
  if coalesce(existing, '') not in ('', 'marea_access.enforce_app_session') then
    raise exception 'Existing PostgREST pre-request hook must call marea_access.enforce_app_session()';
  end if;
end;
$$;
alter role authenticator set pgrst.db_pre_request = 'marea_access.enforce_app_session';
notify pgrst, 'reload config';
notify pgrst, 'reload schema';

-- Storage and Realtime bypass the PostgREST pre-request hook.
create policy "App sessions protect private media" on storage.objects
  as restrictive for all to authenticated
  using ((select private.session_can_access()))
  with check ((select private.session_can_access()));

create policy "App sessions protect notification changes" on public.notifications
  as restrictive for select to authenticated
  using ((select private.session_can_access()));
create policy "App sessions protect chat changes" on public.chat_messages
  as restrictive for select to authenticated
  using ((select private.session_can_access()));
