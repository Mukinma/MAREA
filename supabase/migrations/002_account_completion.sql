-- Mexico, adults only. No production legal document is invented by this migration.
create table public.legal_documents (
  kind text not null check (kind in ('terms', 'privacy')),
  version text not null check (char_length(version) between 1 and 80),
  title text not null,
  body text not null check (char_length(body) > 100),
  published_at timestamptz,
  primary key (kind, version)
);
create table public.registration_settings (
  id boolean primary key default true check (id),
  signup_enabled boolean not null default false,
  terms_version text,
  privacy_version text,
  support_email text,
  country text not null default 'MX' check (country = 'MX'),
  minimum_age integer not null default 18 check (minimum_age = 18)
);
insert into public.registration_settings(id) values (true);
create table public.legal_acceptances (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  terms_version text not null,
  privacy_version text not null,
  adult_confirmed boolean not null check (adult_confirmed),
  accepted_at timestamptz not null default now(),
  unique(user_id, terms_version, privacy_version)
);
alter table public.legal_documents enable row level security;
alter table public.registration_settings enable row level security;
alter table public.legal_acceptances enable row level security;
revoke all on public.legal_documents, public.registration_settings, public.legal_acceptances from anon, authenticated;
grant all on public.legal_documents, public.registration_settings, public.legal_acceptances to service_role;
grant select on public.legal_acceptances to authenticated;
create policy "Own legal history" on public.legal_acceptances for select to authenticated using (user_id = (select auth.uid()));

create function public.protect_published_legal() returns trigger
language plpgsql set search_path = '' as $$
begin
  if old.published_at is not null then
    raise exception 'Published legal documents are immutable; create a new version';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
revoke all on function public.protect_published_legal() from public, anon, authenticated;
create trigger immutable_published_legal before update or delete on public.legal_documents for each row execute function public.protect_published_legal();

create function public.registration_policy() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'signup_enabled', s.signup_enabled and t.version is not null and p.version is not null and coalesce(s.support_email, '') <> '',
    'support_email', s.support_email,
    'terms', case when t.version is null then null else jsonb_build_object('version',t.version,'title',t.title,'body',t.body) end,
    'privacy', case when p.version is null then null else jsonb_build_object('version',p.version,'title',p.title,'body',p.body) end
  ) from public.registration_settings s
  left join public.legal_documents t on t.kind = 'terms' and t.version = s.terms_version and t.published_at <= now()
  left join public.legal_documents p on p.kind = 'privacy' and p.version = s.privacy_version and p.published_at <= now()
  where s.id;
$$;
revoke all on function public.registration_policy() from public;
grant execute on function public.registration_policy() to anon, authenticated, service_role;

create function public.accept_current_legal(terms text, privacy text, adult boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare policy jsonb := public.registration_policy();
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  if adult is distinct from true or terms is distinct from policy #>> '{terms,version}' or privacy is distinct from policy #>> '{privacy,version}' or terms is null or privacy is null then
    raise exception 'legal_acceptance_required';
  end if;
  insert into public.legal_acceptances(user_id,terms_version,privacy_version,adult_confirmed)
  values(auth.uid(),terms,privacy,true) on conflict do nothing;
end;
$$;
revoke all on function public.accept_current_legal(text,text,boolean) from public;
grant execute on function public.accept_current_legal(text,text,boolean) to authenticated;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  policy jsonb := public.registration_policy();
  metadata jsonb := new.raw_user_meta_data;
  new_name text := btrim(coalesce(metadata->>'full_name',''));
  new_username text := lower(btrim(coalesce(metadata->>'username','')));
begin
  if (policy->>'signup_enabled')::boolean is distinct from true then raise exception 'registration_closed'; end if;
  if metadata->>'adult_confirmed' is distinct from 'true' or metadata->>'accepted_terms' is distinct from 'true'
    or metadata->>'terms_version' is distinct from policy #>> '{terms,version}'
    or metadata->>'privacy_version' is distinct from policy #>> '{privacy,version}' then
    raise exception 'legal_acceptance_required';
  end if;
  if char_length(new_name) not between 1 and 80 or new_username !~ '^[a-z0-9._]{3,24}$' then raise exception 'invalid_signup_metadata'; end if;
  insert into public.profiles(id,full_name,username,user_type,role)
  values(new.id,new_name,new_username,'Usuario general','user');
  insert into public.legal_acceptances(user_id,terms_version,privacy_version,adult_confirmed)
  values(new.id,metadata->>'terms_version',metadata->>'privacy_version',true);
  return new;
end;
$$;

alter table public.profiles
  add column avatar_path text,
  add column cover_path text,
  add column cover_preset text not null default 'marea' check (cover_preset in ('marea','lavanda','durazno','menta')),
  add column website text check (website is null or (char_length(website) <= 300 and website ~ '^https://[^/@[:space:]]+\.[^/@[:space:]]+([/?#][^[:space:]]*)?$')),
  add column interests text[] not null default '{}' check (interests <@ array['arte','musica','digital','gastronomia','moda','escritura','fotografia','diseno']::text[] and cardinality(interests) <= 8 and array_position(interests,null) is null),
  add column goals text[] not null default '{}' check (goals <@ array['inspiracion','compartir','colaborar']::text[] and cardinality(goals) <= 3 and array_position(goals,null) is null),
  add column onboarding_status text not null default 'pending' check (onboarding_status in ('pending','completed','skipped'));
revoke update(avatar_url), insert(avatar_url) on public.profiles from authenticated;
grant update(avatar_path,cover_path,cover_preset,website,interests,goals,onboarding_status) on public.profiles to authenticated;
-- Username availability is exposed only as a boolean RPC, not an enumerable table.
revoke select(username) on public.profiles from anon;
drop policy "Public usernames are discoverable" on public.profiles;

create table public.account_deletion_requests (
  user_id uuid primary key references auth.users(id) on delete cascade,
  requested_at timestamptz not null default now()
);
alter table public.account_deletion_requests enable row level security;
revoke all on public.account_deletion_requests from anon, authenticated;
grant all on public.account_deletion_requests to service_role;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('profile-media','profile-media',false,4194304,array['image/png'])
on conflict(id) do update set public=false,file_size_limit=4194304,allowed_mime_types=array['image/png'];
-- Writes go through the validating Edge Function. Signed reads stay owner-only.
create policy "Read own profile media" on storage.objects for select to authenticated
using (bucket_id='profile-media' and (storage.foldername(name))[1]=(select auth.uid())::text);

create function public.validate_profile_media() returns trigger
language plpgsql security definer set search_path = '' as $$
declare path text;
begin
  if exists(select 1 from public.account_deletion_requests where user_id=new.id) then raise exception 'account_deletion_pending'; end if;
  foreach path in array array[new.avatar_path,new.cover_path] loop
    if path is not null and (path !~ ('^' || new.id::text || '/[0-9a-f-]{36}\.png$') or not exists(select 1 from storage.objects where bucket_id='profile-media' and name=path)) then
      raise exception 'invalid_profile_media';
    end if;
  end loop;
  return new;
end;
$$;
revoke all on function public.validate_profile_media() from public, anon, authenticated;
create trigger validate_profile_media before insert or update on public.profiles for each row execute function public.validate_profile_media();

-- Upload leases close the race between a Storage upload and account deletion.
create table public.profile_media_operations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz not null default (now() + interval '10 minutes')
);
alter table public.profile_media_operations enable row level security;
revoke all on public.profile_media_operations from anon, authenticated;
grant all on public.profile_media_operations to service_role;
create function public.begin_profile_media_operation(owner_id uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare operation uuid;
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text, 0));
  if exists(select 1 from public.account_deletion_requests where user_id=owner_id) then raise exception 'account_deletion_pending'; end if;
  if exists(select 1 from public.profile_media_operations where user_id=owner_id and expires_at > now()) then raise exception 'media_operation_in_progress'; end if;
  delete from public.profile_media_operations where user_id=owner_id;
  insert into public.profile_media_operations(user_id) values(owner_id) returning id into operation;
  return operation;
end;
$$;
create function public.request_account_deletion(owner_id uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text, 0));
  insert into public.account_deletion_requests(user_id) values(owner_id) on conflict do nothing;
  return not exists(select 1 from public.profile_media_operations where user_id=owner_id and expires_at > now());
end;
$$;
revoke all on function public.begin_profile_media_operation(uuid), public.request_account_deletion(uuid) from public, anon, authenticated;
grant execute on function public.begin_profile_media_operation(uuid), public.request_account_deletion(uuid) to service_role;
