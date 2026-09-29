-- Initial choices are confirmed once, independently of public profile edits.
-- All existing accounts deliberately receive a final confirmation; no content is moved.
alter table public.profiles
  add column initial_profile_completed_at timestamptz,
  add column contact_url text check(contact_url is null or (char_length(contact_url)<=300 and contact_url ~ '^https://[^/@[:space:]]+\.[^/@[:space:]]+([/?#][^[:space:]]*)?$')),
  add column open_to_collaboration boolean not null default false,
  add column location text check(location is null or char_length(btrim(location)) between 1 and 180),
  add column location_latitude double precision,
  add column location_longitude double precision,
  add column location_precision text,
  add column business_hours jsonb not null default '{}',
  add constraint profile_coordinates_valid check(num_nonnulls(location_latitude,location_longitude,location_precision)=0 or (num_nonnulls(location_latitude,location_longitude,location_precision)=3 and location is not null and location_latitude between -90 and 90 and location_longitude between -180 and 180 and location_precision in ('exact','approximate')));
revoke insert(id,full_name,username,bio,user_type) on public.profiles from authenticated;
revoke update(user_type,interests,goals,onboarding_status) on public.profiles from authenticated;
grant update(contact_url,open_to_collaboration,location,location_latitude,location_longitude,location_precision,business_hours) on public.profiles to authenticated;

create function public.validate_profile_presentation() returns trigger
language plpgsql security definer set search_path='' as $$
declare day text; hours jsonb; value text;
begin
  if old.initial_profile_completed_at is not null and row(new.user_type,new.interests,new.goals,new.onboarding_status,new.initial_profile_completed_at) is distinct from row(old.user_type,old.interests,old.goals,old.onboarding_status,old.initial_profile_completed_at) then raise exception 'initial_profile_already_confirmed'; end if;
  if jsonb_typeof(new.business_hours)<>'object' then raise exception 'invalid_business_hours'; end if;
  for day,hours in select * from jsonb_each(new.business_hours) loop
    if day not in ('mon','tue','wed','thu','fri','sat','sun') then raise exception 'invalid_business_hours'; end if;
    if hours='null'::jsonb then continue; end if;
    value := hours#>>'{}';
    if jsonb_typeof(hours)<>'string' or value !~ '^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$' or left(value,5)>=right(value,5) then raise exception 'invalid_business_hours'; end if;
  end loop;
  if new.user_type<>'Negocio' and (new.location is not null or new.business_hours<>'{}'::jsonb) then raise exception 'business_profile_required'; end if;
  if new.user_type<>'Artista / creador' and new.open_to_collaboration then raise exception 'creator_profile_required'; end if;
  if new.user_type='Usuario general' and new.contact_url is not null then raise exception 'professional_profile_required'; end if;
  return new;
end;
$$;
revoke all on function public.validate_profile_presentation() from public,anon,authenticated;
create trigger validate_profile_presentation before update on public.profiles for each row execute function public.validate_profile_presentation();

create function public.complete_initial_profile(profile_type text,selected_interests text[],selected_goals text[]) returns jsonb
language plpgsql security definer set search_path='' as $$
declare account uuid := auth.uid(); current_profile public.profiles; result public.profiles;
begin
  if account is null then raise exception 'authentication_required'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(account::text,0));
  select * into current_profile from public.profiles where id=account for update;
  if not found then raise exception 'account_required'; end if;
  if exists(select 1 from public.account_deletion_requests where user_id=account) then raise exception 'account_deletion_pending'; end if;
  if current_profile.initial_profile_completed_at is not null then raise exception 'initial_profile_already_confirmed'; end if;
  if profile_type is null or profile_type not in ('Usuario general','Artista / creador','Emprendedor','Negocio') or selected_interests is null or cardinality(selected_interests)<1 or selected_goals is null or cardinality(selected_goals)<1 then raise exception 'initial_profile_choices_required'; end if;
  -- Catalog, null and cardinality checks remain enforced by the profiles constraints.
  update public.profiles set user_type=profile_type,
    interests=array(select distinct x from unnest(selected_interests) x order by x),
    goals=array(select distinct x from unnest(selected_goals) x order by x),
    onboarding_status='completed',initial_profile_completed_at=now() where id=account returning * into result;
  return to_jsonb(result);
end;
$$;
revoke all on function public.complete_initial_profile(text,text[],text[]) from public,anon;
grant execute on function public.complete_initial_profile(text,text[],text[]) to authenticated;

create or replace function public.community_active_account() returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid := auth.uid();
begin
  if account is null then raise exception 'authentication_required'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(account::text,0));
  if not exists(select 1 from public.profiles where id=account) then raise exception 'account_required'; end if;
  if exists(select 1 from public.account_deletion_requests where user_id=account) then raise exception 'account_deletion_pending'; end if;
  if not exists(select 1 from public.profiles where id=account and initial_profile_completed_at is not null) then raise exception 'initial_profile_required'; end if;
  return account;
end;
$$;
-- Keep historical kind edits intact, but require capabilities for new content.
create or replace function public.validate_community_content() returns trigger
language plpgsql security definer set search_path='' as $$
declare account_type text;
begin
  if tg_op='UPDATE' then
    if new.author_id is distinct from old.author_id then raise exception 'immutable_author'; end if;
    if tg_table_name='posts' then
      if new.kind is distinct from old.kind then raise exception 'immutable_kind'; end if;
      new.updated_at:=now();
    end if;
  end if;
  if auth.uid()=new.author_id then perform public.community_active_account(); end if;
  if tg_op='INSERT' then
    if exists(select 1 from public.account_deletion_requests where user_id=new.author_id) then raise exception 'account_deletion_pending'; end if;
    if tg_table_name='posts' then
      select user_type into account_type from public.profiles where id=new.author_id;
      if not (new.kind='community' or (new.kind='project' and account_type='Artista / creador') or (new.kind in ('product','service') and account_type='Emprendedor') or (new.kind in ('service','space','event') and account_type='Negocio')) then raise exception 'post_kind_not_allowed'; end if;
    elsif new.starts_at<=now() then raise exception 'mission_must_be_future'; end if;
  end if;
  if tg_table_name='posts' and new.image_path is not null and (new.image_path !~ ('^'||new.author_id::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$') or not exists(select 1 from storage.objects where bucket_id='post-images' and name=new.image_path)) then raise exception 'invalid_post_image'; end if;
  return new;
end;
$$;

-- Public presentation still requires authentication; private fields never enter the directory.
drop function public.community_profiles(uuid[],text);
create function public.community_profiles(profile_ids uuid[] default null,query_text text default '')
returns table(id uuid,full_name text,username text,bio text,user_type text,website text,avatar_path text,cover_path text,cover_preset text,contact_url text,open_to_collaboration boolean,location text,location_latitude double precision,location_longitude double precision,location_precision text,business_hours jsonb)
language plpgsql stable security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  return query select p.id,p.full_name,p.username,p.bio,p.user_type,p.website,p.avatar_path,p.cover_path,p.cover_preset,p.contact_url,p.open_to_collaboration,p.location,p.location_latitude,p.location_longitude,p.location_precision,p.business_hours from public.profiles p
    where (profile_ids is null or p.id=any(profile_ids)) and (coalesce(query_text,'')='' or p.full_name ilike '%'||left(query_text,100)||'%' or p.username ilike '%'||left(query_text,100)||'%')
    and not exists(select 1 from public.account_deletion_requests d where d.user_id=p.id) order by p.username limit 100;
end;
$$;
revoke all on function public.community_profiles(uuid[],text) from public,anon;
grant execute on function public.community_profiles(uuid[],text) to authenticated;
create function public.visible_profile_media(media_path text) returns boolean
language sql stable security definer set search_path='' as $$
  select auth.uid() is not null and exists(select 1 from public.profiles p where (p.avatar_path=media_path or p.cover_path=media_path) and not exists(select 1 from public.account_deletion_requests d where d.user_id=p.id));
$$;
revoke all on function public.visible_profile_media(text) from public,anon;
grant execute on function public.visible_profile_media(text) to authenticated;
create policy "Read presented profile photos" on storage.objects for select to authenticated using(bucket_id='profile-media' and public.visible_profile_media(name));

create table public.showcase_items(
  id uuid primary key default gen_random_uuid(),owner_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check(kind in ('project','product','service')),
  title text not null check(char_length(btrim(title)) between 3 and 100),
  body text not null default '' check(char_length(body)<=3000),
  category text not null check(category in ('arte','musica','digital','gastronomia','moda','escritura','fotografia','diseno','otros')),
  status text not null default 'draft' check(status in ('draft','published','archived')),
  available boolean not null default true,
  price numeric(10,2) check(price is null or (kind in ('product','service') and price between 0 and 99999999)),
  project_url text check(project_url is null or (kind='project' and char_length(project_url)<=300 and project_url ~ '^https://[^/@[:space:]]+\.[^/@[:space:]]+([/?#][^[:space:]]*)?$')),
  hidden boolean not null default false,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
  check(status<>'published' or char_length(btrim(body))>=1)
);
create index showcase_owner_idx on public.showcase_items(owner_id,created_at desc,id desc);
create index showcase_discovery_idx on public.showcase_items(kind,category,created_at desc,id desc) where status='published' and available and not hidden;
create table public.showcase_images(
  item_id uuid not null references public.showcase_items(id) on delete cascade,
  position integer not null check(position between 0 and 5),path text not null unique,
  primary key(item_id,position)
);
create table public.showcase_saves(
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  item_id uuid not null references public.showcase_items(id) on delete cascade,
  created_at timestamptz not null default now(),primary key(user_id,item_id)
);
alter table public.showcase_items enable row level security;
alter table public.showcase_images enable row level security;
alter table public.showcase_saves enable row level security;
revoke all on public.showcase_items,public.showcase_images,public.showcase_saves from anon,authenticated;
grant all on public.showcase_items,public.showcase_images,public.showcase_saves to service_role;
grant select on public.showcase_items,public.showcase_images,public.showcase_saves to authenticated;
grant insert(item_id),delete on public.showcase_saves to authenticated;
create function public.showcase_owner_visible(owner_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
  select auth.uid() is not null and exists(select 1 from public.profiles p where p.id=owner_id) and not exists(select 1 from public.account_deletion_requests d where d.user_id=owner_id);
$$;
revoke all on function public.showcase_owner_visible(uuid) from public,anon;
grant execute on function public.showcase_owner_visible(uuid) to authenticated;
create policy "Read available showcases or own management" on public.showcase_items for select to authenticated using(owner_id=auth.uid() or public.community_is_admin() or (status='published' and available and not hidden and public.showcase_owner_visible(owner_id)));
-- Account deletion hides the public directory immediately; media/content cleanup is coordinated by the marker.
create policy "Read visible showcase images" on public.showcase_images for select to authenticated using(exists(select 1 from public.showcase_items s where s.id=item_id));
create policy "Read own showcase saves" on public.showcase_saves for select to authenticated using(user_id=auth.uid());
create policy "Save published showcases" on public.showcase_saves for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.showcase_items s where s.id=item_id and s.status='published' and s.available and not s.hidden));
create policy "Remove own showcase saves" on public.showcase_saves for delete to authenticated using(user_id=auth.uid());

create function public.save_showcase(item_input jsonb,item_id uuid default null) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); account_type text; existing public.showcase_items; result uuid; paths text[]; photo text; n integer:=0; requested_kind text;
begin
  if item_input is null or jsonb_typeof(item_input)<>'object' or exists(select 1 from jsonb_object_keys(item_input) k where k not in ('kind','title','body','category','status','available','price','project_url','image_paths')) then raise exception 'invalid_showcase_input'; end if;
  requested_kind:=item_input->>'kind';
  if item_id is not null then
    select * into existing from public.showcase_items s where s.id=item_id for update;
    if not found or existing.owner_id<>account then raise exception 'showcase_owner_required'; end if;
    if existing.kind is distinct from requested_kind then raise exception 'immutable_kind'; end if;
  else
    select user_type into account_type from public.profiles where id=account;
    if not ((account_type='Artista / creador' and requested_kind='project') or (account_type='Emprendedor' and requested_kind in ('product','service')) or (account_type='Negocio' and requested_kind='service')) then raise exception 'showcase_kind_not_allowed'; end if;
  end if;
  if jsonb_typeof(item_input->'image_paths') is distinct from 'array' then raise exception 'invalid_showcase_images'; end if;
  paths:=array(select jsonb_array_elements_text(item_input->'image_paths'));
  if cardinality(paths)>6 or cardinality(paths)<>(select count(distinct x) from unnest(paths) x) then raise exception 'invalid_showcase_images'; end if;
  if item_input->>'status'='published' and requested_kind in ('project','product') and cardinality(paths)=0 then raise exception 'showcase_photo_required'; end if;
  foreach photo in array paths loop
    if photo is null or photo !~ ('^'||account::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$') or not exists(select 1 from storage.objects where bucket_id='showcase-media' and name=photo) then raise exception 'invalid_showcase_image'; end if;
  end loop;
  if item_id is null then
    insert into public.showcase_items(owner_id,kind,title,body,category,status,available,price,project_url)
    values(account,requested_kind,btrim(item_input->>'title'),coalesce(btrim(item_input->>'body'),''),item_input->>'category',item_input->>'status',coalesce((item_input->>'available')::boolean,true),(item_input->>'price')::numeric,nullif(btrim(item_input->>'project_url'),'')) returning id into result;
  else
    update public.showcase_items s set title=btrim(item_input->>'title'),body=coalesce(btrim(item_input->>'body'),''),category=item_input->>'category',status=item_input->>'status',available=coalesce((item_input->>'available')::boolean,true),price=(item_input->>'price')::numeric,project_url=nullif(btrim(item_input->>'project_url'),''),updated_at=now() where s.id=item_id;
    result:=item_id;
    delete from public.showcase_images i where i.item_id=result;
  end if;
  foreach photo in array paths loop
    insert into public.showcase_images(item_id,position,path) values(result,n,photo); n:=n+1;
  end loop;
  return result;
end;
$$;
create function public.delete_showcase(item_id uuid) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
  delete from public.showcase_items s where s.id=item_id and s.owner_id=account;
  if not found then raise exception 'showcase_owner_required'; end if;
end;
$$;
revoke all on function public.save_showcase(jsonb,uuid),public.delete_showcase(uuid) from public,anon;
grant execute on function public.save_showcase(jsonb,uuid),public.delete_showcase(uuid) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('showcase-media','showcase-media',false,4194304,array['image/png']);
create policy "Read attached showcase photos" on storage.objects for select to authenticated using(bucket_id='showcase-media' and ((storage.foldername(name))[1]=auth.uid()::text or exists(select 1 from public.showcase_images i where i.path=name)));
create policy "Upload own showcase photos" on storage.objects for insert to authenticated with check(bucket_id='showcase-media' and name ~ ('^'||auth.uid()::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$'));
create policy "Delete unused showcase photos" on storage.objects for delete to authenticated using(bucket_id='showcase-media' and (storage.foldername(name))[1]=auth.uid()::text and not exists(select 1 from public.showcase_images i where i.path=name));
create function public.guard_showcase_photo() returns trigger
language plpgsql security definer set search_path='' as $$
declare owner_id uuid;
begin
  if tg_op='DELETE' then
    if old.bucket_id<>'showcase-media' then return old; end if;
    owner_id:=split_part(old.name,'/',1)::uuid;
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text,0));
    if auth.uid() is not null and exists(select 1 from public.showcase_images where path=old.name) then raise exception 'showcase_image_in_use'; end if;
    return old;
  end if;
  if new.bucket_id<>'showcase-media' then return new; end if;
  if tg_op='UPDATE' then raise exception 'showcase_image_immutable'; end if;
  if new.name !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$' then raise exception 'invalid_showcase_image'; end if;
  owner_id:=split_part(new.name,'/',1)::uuid;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text,0));
  if not exists(select 1 from public.profiles where id=owner_id and initial_profile_completed_at is not null) then raise exception 'initial_profile_required'; end if;
  if exists(select 1 from public.account_deletion_requests where user_id=owner_id) then raise exception 'account_deletion_pending'; end if;
  return new;
end;
$$;
revoke all on function public.guard_showcase_photo() from public,anon,authenticated;
create trigger guard_showcase_photos before insert or update or delete on storage.objects for each row execute function public.guard_showcase_photo();

alter table public.content_reports add column showcase_id uuid references public.showcase_items(id) on delete cascade;
alter table public.content_reports drop constraint content_reports_check;
alter table public.content_reports add constraint report_one_target check(num_nonnulls(post_id,mission_id,showcase_id)=1),add constraint report_showcase_unique unique(reporter_id,showcase_id);
create function public.report_showcase(item_id uuid,report_reason text) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
  if not exists(select 1 from public.showcase_items where id=item_id and status='published' and available and not hidden) then raise exception 'showcase_unavailable'; end if;
  insert into public.content_reports(reporter_id,showcase_id,reason) values(account,item_id,btrim(report_reason));
end;
$$;
revoke all on function public.report_showcase(uuid,text) from public,anon;
grant execute on function public.report_showcase(uuid,text) to authenticated;
create or replace function public.moderate_content(content_id uuid,content_kind text,hide_content boolean) returns void
language plpgsql security definer set search_path='' as $$
begin
  perform public.community_active_account();
  if not public.community_is_admin() then raise exception 'admin_required'; end if;
  if hide_content is null then raise exception 'invalid_visibility'; end if;
  if content_kind='post' then
    update public.posts set hidden=hide_content where id=content_id;
    if not found then raise exception 'content_not_found'; end if;
    update public.content_reports set state='resolved' where post_id=content_id;
  elsif content_kind='mission' then
    update public.missions set hidden=hide_content where id=content_id;
    if not found then raise exception 'content_not_found'; end if;
    update public.content_reports set state='resolved' where mission_id=content_id;
  elsif content_kind='showcase' then
    update public.showcase_items set hidden=hide_content where id=content_id;
    if not found then raise exception 'content_not_found'; end if;
    update public.content_reports set state='resolved' where showcase_id=content_id;
  else raise exception 'invalid_content_kind'; end if;
end;
$$;
