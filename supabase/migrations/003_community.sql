-- Authenticated community. Administrative privileges always come from profiles.role.
create function public.community_is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;
create function public.community_active_account() returns uuid
language plpgsql security definer set search_path = '' as $$
declare account uuid := auth.uid();
begin
  if account is null then raise exception 'authentication_required'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(account::text,0));
  if not exists(select 1 from public.profiles where id=account) then raise exception 'account_required'; end if;
  if exists(select 1 from public.account_deletion_requests where user_id=account) then raise exception 'account_deletion_pending'; end if;
  return account;
end;
$$;
revoke all on function public.community_is_admin(), public.community_active_account() from public,anon,authenticated;
grant execute on function public.community_is_admin() to authenticated;

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  kind text not null check(kind in ('community','project','product','service','space','event')),
  title text not null check(char_length(btrim(title)) >= 3 and char_length(title)<=100),
  body text not null check(char_length(btrim(body)) >= 1 and char_length(body)<=3000),
  category text not null check(category in ('arte','musica','digital','gastronomia','moda','escritura','fotografia','diseno','otros')),
  location text check(location is null or char_length(location)<=180),
  price numeric check(price is null or price between 0 and 99999999),
  image_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  hidden boolean not null default false,
  constraint posts_location_for_space_event check (
    kind not in ('space','event') or (location is not null and char_length(btrim(location))>0)
  ),
  constraint posts_price_for_commerce check (
    price is null or kind in ('product','service')
  )
);
create index posts_created_idx on public.posts(created_at desc);
create index posts_author_idx on public.posts(author_id);
create table public.post_saves (
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id,post_id)
);
create table public.missions (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title text not null check(char_length(btrim(title)) >= 3 and char_length(title)<=100),
  body text not null check(char_length(btrim(body)) >= 1 and char_length(body)<=3000),
  category text not null check(category in ('arte','musica','digital','gastronomia','moda','escritura','fotografia','diseno','otros')),
  location text not null check(char_length(btrim(location)) >= 1 and char_length(location)<=180),
  starts_at timestamptz not null,
  capacity integer not null check(capacity between 1 and 100),
  target_type text check(target_type is null or target_type in ('Usuario general','Artista / creador','Emprendedor','Negocio')),
  status text not null default 'open' check(status in ('open','closed')),
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);
create index missions_created_idx on public.missions(created_at desc);
create index missions_author_idx on public.missions(author_id);
create table public.mission_applications (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.missions(id) on delete cascade,
  applicant_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check(char_length(btrim(message)) >= 1 and char_length(message)<=1000),
  status text not null default 'pending' check(status in ('pending','accepted','rejected')),
  created_at timestamptz not null default now(),
  unique(mission_id,applicant_id)
);
create index mission_applications_applicant_idx on public.mission_applications(applicant_id);
create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  mission_id uuid references public.missions(id) on delete cascade,
  reason text not null check(char_length(btrim(reason)) >= 5 and char_length(reason)<=500),
  state text not null default 'open' check(state in ('open','resolved')),
  created_at timestamptz not null default now(),
  check(num_nonnulls(post_id,mission_id)=1),
  unique(reporter_id,post_id),
  unique(reporter_id,mission_id)
);
alter table public.posts enable row level security;
alter table public.post_saves enable row level security;
alter table public.missions enable row level security;
alter table public.mission_applications enable row level security;
alter table public.content_reports enable row level security;
revoke all on public.posts,public.post_saves,public.missions,public.mission_applications,public.content_reports from anon,authenticated;
grant all on public.posts,public.post_saves,public.missions,public.mission_applications,public.content_reports to service_role;
grant select,delete on public.posts,public.post_saves,public.missions to authenticated;
grant insert(kind,title,body,category,location,price,image_path) on public.posts to authenticated;
grant update(title,body,category,location,price,image_path) on public.posts to authenticated;
grant insert(post_id) on public.post_saves to authenticated;
grant insert(title,body,category,location,starts_at,capacity,target_type) on public.missions to authenticated;
grant select on public.mission_applications,public.content_reports to authenticated;
grant insert(post_id,mission_id,reason) on public.content_reports to authenticated;
create policy "Visible posts" on public.posts for select to authenticated using(not hidden or author_id=auth.uid() or public.community_is_admin());
create policy "Create own posts" on public.posts for insert to authenticated with check(author_id=auth.uid());
create policy "Edit own posts" on public.posts for update to authenticated using(author_id=auth.uid()) with check(author_id=auth.uid());
create policy "Delete own posts" on public.posts for delete to authenticated using(author_id=auth.uid());
create policy "Read own saves" on public.post_saves for select to authenticated using(user_id=auth.uid());
create policy "Save visible posts" on public.post_saves for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.posts where id=post_id));
create policy "Delete own saves" on public.post_saves for delete to authenticated using(user_id=auth.uid());
create policy "Visible missions" on public.missions for select to authenticated using(not hidden or author_id=auth.uid() or public.community_is_admin());
create policy "Create own missions" on public.missions for insert to authenticated with check(author_id=auth.uid());
create policy "Delete own missions" on public.missions for delete to authenticated using(author_id=auth.uid());
create policy "Private applications" on public.mission_applications for select to authenticated using(applicant_id=auth.uid() or exists(select 1 from public.missions where id=mission_id and author_id=auth.uid()));
create policy "Read own reports or moderate" on public.content_reports for select to authenticated using(reporter_id=auth.uid() or public.community_is_admin());
create policy "Report visible content" on public.content_reports for insert to authenticated with check(reporter_id=auth.uid() and (exists(select 1 from public.posts where id=post_id) or exists(select 1 from public.missions where id=mission_id)));

create function public.validate_community_content() returns trigger
language plpgsql security definer set search_path = '' as $$
declare account_type text;
begin
  -- Internal moderation changes only hidden. Owner writes use column grants + RLS.
  if tg_op='UPDATE' then
    if new.author_id is distinct from old.author_id then raise exception 'immutable_author'; end if;
    if tg_table_name='posts' then
      if new.kind is distinct from old.kind then raise exception 'immutable_kind'; end if;
      new.updated_at := now();
    end if;
  end if;
  -- Admin and service operations need not impersonate the author.
  if auth.uid()=new.author_id then perform public.community_active_account(); end if;
  if tg_op='INSERT' then
    if exists(select 1 from public.account_deletion_requests where user_id=new.author_id) then raise exception 'account_deletion_pending'; end if;
    if tg_table_name='posts' then
      select user_type into account_type from public.profiles where id=new.author_id;
      if not (new.kind='community' or (new.kind='project' and account_type='Artista / creador') or (new.kind in ('product','service') and account_type='Emprendedor') or (new.kind in ('space','event') and account_type='Negocio')) then raise exception 'post_kind_not_allowed'; end if;
    elsif new.starts_at <= now() then raise exception 'mission_must_be_future';
    end if;
  end if;
  if tg_table_name='posts' then
    if new.image_path is not null and (new.image_path !~ ('^'||new.author_id::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$') or not exists(select 1 from storage.objects where bucket_id='post-images' and name=new.image_path)) then raise exception 'invalid_post_image'; end if;
  end if;
  return new;
end;
$$;
revoke all on function public.validate_community_content() from public,anon,authenticated;
create trigger validate_posts before insert or update on public.posts for each row execute function public.validate_community_content();
create trigger validate_missions before insert or update on public.missions for each row execute function public.validate_community_content();

create function public.community_profiles(profile_ids uuid[] default null,query_text text default '')
returns table(id uuid,full_name text,username text,bio text,user_type text,website text)
language plpgsql stable security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  return query select p.id,p.full_name,p.username,p.bio,p.user_type,p.website from public.profiles p
    where (profile_ids is null or p.id=any(profile_ids))
      and (coalesce(query_text,'')='' or p.full_name ilike '%'||left(query_text,100)||'%' or p.username ilike '%'||left(query_text,100)||'%')
      and not exists(select 1 from public.account_deletion_requests d where d.user_id=p.id)
    order by p.username limit 100;
end;
$$;
create function public.set_mission_status(mission_id uuid,new_status text) returns void
language plpgsql security definer set search_path = '' as $$
declare account uuid := public.community_active_account(); mission public.missions;
begin
  if new_status is null or new_status not in ('open','closed') then raise exception 'invalid_status'; end if;
  select * into mission from public.missions m where m.id=mission_id for update;
  if not found or mission.author_id<>account then raise exception 'mission_owner_required'; end if;
  if new_status='open' and (mission.hidden or mission.starts_at<=now()) then raise exception 'mission_unavailable'; end if;
  update public.missions m set status=new_status where m.id=mission_id;
end;
$$;
create function public.apply_to_mission(mission_id uuid,application_message text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare account uuid := public.community_active_account(); mission public.missions; application uuid; account_type text;
begin
  select * into mission from public.missions m where m.id=mission_id for update;
  if not found or mission.hidden or mission.status<>'open' or mission.starts_at<=now() then raise exception 'mission_unavailable'; end if;
  if mission.author_id=account then raise exception 'cannot_apply_to_own_mission'; end if;
  select user_type into account_type from public.profiles where id=account;
  if mission.target_type is not null and mission.target_type<>account_type then raise exception 'mission_target_mismatch'; end if;
  if (select count(*) from public.mission_applications a where a.mission_id=mission.id and a.status='accepted')>=mission.capacity then raise exception 'mission_full'; end if;
  insert into public.mission_applications(mission_id,applicant_id,message) values(mission.id,account,btrim(application_message)) returning id into application;
  return application;
end;
$$;
create function public.withdraw_application(application_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare account uuid := public.community_active_account(); target uuid;
begin
  select a.mission_id into target from public.mission_applications a where a.id=application_id and a.applicant_id=account;
  if not found then raise exception 'application_owner_required'; end if;
  perform 1 from public.missions m where m.id=target for update;
  delete from public.mission_applications a where a.id=application_id and a.applicant_id=account;
end;
$$;
create function public.review_application(application_id uuid,decision text) returns void
language plpgsql security definer set search_path = '' as $$
declare account uuid := public.community_active_account(); target uuid; mission public.missions; application public.mission_applications; account_type text;
begin
  if decision is null or decision not in ('accepted','rejected') then raise exception 'invalid_decision'; end if;
  select a.mission_id into target from public.mission_applications a where a.id=application_id;
  select * into mission from public.missions m where m.id=target for update;
  if not found or mission.author_id<>account then raise exception 'mission_owner_required'; end if;
  select * into application from public.mission_applications a where a.id=application_id for update;
  if not found then raise exception 'application_not_found'; end if;
  if mission.hidden or mission.status<>'open' or mission.starts_at<=now() then raise exception 'mission_unavailable'; end if;
  if decision='accepted' then
    select user_type into account_type from public.profiles p where p.id=application.applicant_id;
    if mission.target_type is not null and mission.target_type<>account_type then raise exception 'mission_target_mismatch'; end if;
    if exists(select 1 from public.account_deletion_requests where user_id=application.applicant_id) then raise exception 'account_deletion_pending'; end if;
    if (select count(*) from public.mission_applications a where a.mission_id=mission.id and a.status='accepted' and a.id<>application_id)>=mission.capacity then raise exception 'mission_full'; end if;
  end if;
  update public.mission_applications a set status=decision where a.id=application_id;
end;
$$;
create function public.moderate_content(content_id uuid,content_kind text,hide_content boolean) returns void
language plpgsql security definer set search_path = '' as $$
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
  else raise exception 'invalid_content_kind'; end if;
end;
$$;
revoke all on function public.community_profiles(uuid[],text), public.set_mission_status(uuid,text), public.apply_to_mission(uuid,text), public.withdraw_application(uuid), public.review_application(uuid,text), public.moderate_content(uuid,text,boolean) from public,anon,authenticated;
grant execute on function public.community_profiles(uuid[],text), public.set_mission_status(uuid,text), public.apply_to_mission(uuid,text), public.withdraw_application(uuid), public.review_application(uuid,text), public.moderate_content(uuid,text,boolean) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('post-images','post-images',false,4194304,array['image/png'])
on conflict(id) do update set public=false,file_size_limit=4194304,allowed_mime_types=array['image/png'];
create policy "Read visible post images" on storage.objects for select to authenticated
using(bucket_id='post-images' and ((storage.foldername(name))[1]=auth.uid()::text or exists(select 1 from public.posts p where p.image_path=name)));
create policy "Upload own post images" on storage.objects for insert to authenticated
with check(bucket_id='post-images' and name ~ ('^'||auth.uid()::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$'));
create policy "Delete own unused post images" on storage.objects for delete to authenticated
using(bucket_id='post-images' and (storage.foldername(name))[1]=auth.uid()::text and not exists(select 1 from public.posts p where p.image_path=name));
-- Storage object creation and attachment serialize with the deletion marker. No
-- authenticated UPDATE policy is granted: uploads use unique paths, never upsert.
create function public.guard_post_image_operation() returns trigger
language plpgsql security definer set search_path = '' as $$
declare owner_id uuid;
begin
  if tg_op='DELETE' then
    if old.bucket_id<>'post-images' then return old; end if;
    owner_id := split_part(old.name,'/',1)::uuid;
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text,0));
    -- Service-role cleanup after the deletion marker may delete referenced media.
    if auth.uid() is not null and exists(select 1 from public.posts where image_path=old.name) then raise exception 'post_image_in_use'; end if;
    return old;
  end if;
  if new.bucket_id<>'post-images' then return new; end if;
  if tg_op='UPDATE' then raise exception 'post_image_immutable'; end if;
  if new.name !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$' then raise exception 'invalid_post_image'; end if;
  owner_id := split_part(new.name,'/',1)::uuid;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text,0));
  if not exists(select 1 from public.profiles where id=owner_id) then raise exception 'account_required'; end if;
  if exists(select 1 from public.account_deletion_requests where user_id=owner_id) then raise exception 'account_deletion_pending'; end if;
  return new;
end;
$$;
revoke all on function public.guard_post_image_operation() from public,anon,authenticated;
create trigger guard_post_images before insert or update or delete on storage.objects for each row execute function public.guard_post_image_operation();
