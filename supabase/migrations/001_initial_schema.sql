create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  username text not null,
  bio text,
  user_type text not null default 'Usuario general',
  role text not null default 'user',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_full_name_valid check (
    full_name = btrim(full_name)
    and char_length(full_name) between 1 and 80
  ),
  constraint profiles_username_valid check (
    username = lower(username)
    and username ~ '^[a-z0-9._]{3,24}$'
  ),
  constraint profiles_bio_length check (
    bio is null or char_length(bio) <= 160
  ),
  constraint profiles_user_type_valid check (
    user_type in (
      'Usuario general',
      'Artista / creador',
      'Emprendedor',
      'Negocio'
    )
  ),
  constraint profiles_role_valid check (role in ('user', 'admin'))
);

create unique index profiles_username_lower_idx
  on public.profiles (lower(username));

alter table public.profiles enable row level security;
alter table public.profiles force row level security;

revoke all on table public.profiles from anon, authenticated;
grant select (username) on table public.profiles to anon;
grant select on table public.profiles to authenticated;
grant insert (id, full_name, username, bio, user_type, avatar_url)
  on table public.profiles to authenticated;
grant update (full_name, username, bio, user_type, avatar_url)
  on table public.profiles to authenticated;
grant all on table public.profiles to service_role;

create policy "Public usernames are discoverable"
  on public.profiles
  for select
  to anon
  using (true);

create policy "Users can read their profile"
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can create their profile"
  on public.profiles
  for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users can update their profile"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create or replace function public.is_username_available(candidate text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    candidate ~ '^[a-z0-9._]{3,24}$'
    and not exists (
      select 1
      from public.profiles
      where username = candidate
    );
$$;

revoke all on function public.is_username_available(text) from public;
grant execute on function public.is_username_available(text) to anon, authenticated;

create or replace function public.set_profile_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.set_profile_updated_at() from public, anon, authenticated;

create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_profile_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_full_name text := btrim(coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  new_username text := lower(btrim(coalesce(new.raw_user_meta_data ->> 'username', '')));
begin
  if char_length(new_full_name) not between 1 and 80 then
    raise exception using
      errcode = '22023',
      message = 'invalid full_name signup metadata';
  end if;

  if new_username !~ '^[a-z0-9._]{3,24}$' then
    raise exception using
      errcode = '22023',
      message = 'invalid username signup metadata';
  end if;

  insert into public.profiles (
    id,
    full_name,
    username,
    user_type,
    role
  ) values (
    new.id,
    new_full_name,
    new_username,
    'Usuario general',
    'user'
  );

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();
