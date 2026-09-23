-- Mission editing and participation are serialized on the mission row. Historical
-- conditions remain locked even when every applicant withdraws or is deleted.
alter table public.missions
  add column image_path text,
  add column location_latitude double precision,
  add column location_longitude double precision,
  add column location_precision text,
  add column requirements text check(requirements is null or char_length(requirements)<=3000),
  add column conditions text check(conditions is null or char_length(conditions)<=3000),
  add column conditions_locked_at timestamptz,
  add column cancellation_reason text check(cancellation_reason is null or char_length(btrim(cancellation_reason)) between 5 and 500);
alter table public.missions drop constraint missions_status_check;
alter table public.missions add constraint missions_status_check check(status in ('open','closed','cancelled','completed'));
alter table public.mission_applications drop constraint mission_applications_status_check;
alter table public.mission_applications add constraint mission_applications_status_check check(status in ('pending','accepted','rejected','withdrawn'));
update public.missions m set conditions_locked_at=(select min(a.created_at) from public.mission_applications a where a.mission_id=m.id);

-- Repair incomplete coordinates admitted by SQL CHECK's null semantics in 004;
-- legacy text locations remain untouched. Range comparisons also reject NaN/Inf.
update public.posts set location_latitude=null,location_longitude=null,location_precision=null
where not coalesce(location_latitude between -90 and 90 and location_longitude between -180 and 180 and location_precision in ('exact','approximate'),false);
alter table public.posts drop constraint posts_location_coordinates_check;
alter table public.posts add constraint posts_location_coordinates_check check (
  num_nonnulls(location_latitude,location_longitude,location_precision)=0 or (
    num_nonnulls(location_latitude,location_longitude,location_precision)=3
    and location_latitude between -90 and 90 and location_longitude between -180 and 180
    and location_precision in ('exact','approximate')));
alter table public.missions add constraint missions_location_coordinates_check check (
  num_nonnulls(location_latitude,location_longitude,location_precision)=0 or (
    num_nonnulls(location_latitude,location_longitude,location_precision)=3
    and location_latitude between -90 and 90 and location_longitude between -180 and 180
    and location_precision in ('exact','approximate')));

-- Direct inserts would bypass the RPC's explicit input allowlist.
revoke insert(title,body,category,location,starts_at,capacity,target_type) on public.missions from authenticated;
create function public.validate_mission_lifecycle() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  if tg_op='UPDATE' then
    if old.status in ('cancelled','completed') and new.status is distinct from old.status then raise exception 'mission_terminal'; end if;
    if old.conditions_locked_at is not null then
      if new.conditions_locked_at is distinct from old.conditions_locked_at or
        row(new.starts_at,new.location,new.location_latitude,new.location_longitude,new.location_precision,new.target_type)
          is distinct from row(old.starts_at,old.location,old.location_latitude,old.location_longitude,old.location_precision,old.target_type)
        then raise exception 'mission_conditions_locked'; end if;
      if new.capacity<old.capacity then raise exception 'mission_capacity_cannot_decrease'; end if;
    end if;
  end if;
  if new.image_path is not null and (new.image_path !~ ('^'||new.author_id::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$') or not exists(select 1 from storage.objects where bucket_id='mission-images' and name=new.image_path)) then raise exception 'invalid_mission_image'; end if;
  return new;
end;
$$;
revoke all on function public.validate_mission_lifecycle() from public,anon,authenticated;
create trigger validate_mission_lifecycle before insert or update on public.missions for each row execute function public.validate_mission_lifecycle();

create function public.create_mission(mission_input jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid := public.community_active_account(); result uuid;
begin
  if mission_input is null or jsonb_typeof(mission_input)<>'object' or exists(select 1 from jsonb_object_keys(mission_input) k where k not in ('title','body','category','location','starts_at','capacity','target_type','image_path','location_latitude','location_longitude','location_precision','requirements','conditions')) then raise exception 'invalid_mission_input'; end if;
  insert into public.missions(author_id,title,body,category,location,starts_at,capacity,target_type,image_path,location_latitude,location_longitude,location_precision,requirements,conditions)
  values(account,btrim(mission_input->>'title'),btrim(mission_input->>'body'),mission_input->>'category',btrim(mission_input->>'location'),(mission_input->>'starts_at')::timestamptz,(mission_input->>'capacity')::integer,nullif(mission_input->>'target_type',''),nullif(mission_input->>'image_path',''),(mission_input->>'location_latitude')::double precision,(mission_input->>'location_longitude')::double precision,mission_input->>'location_precision',nullif(btrim(mission_input->>'requirements'),''),nullif(btrim(mission_input->>'conditions'),'')) returning id into result;
  return result;
end;
$$;
create function public.update_mission(mission_id uuid,mission_input jsonb) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid := public.community_active_account(); mission public.missions; edited public.missions;
begin
  if mission_input is null or jsonb_typeof(mission_input)<>'object' or exists(select 1 from jsonb_object_keys(mission_input) k where k not in ('title','body','category','location','starts_at','capacity','target_type','image_path','location_latitude','location_longitude','location_precision','requirements','conditions')) then raise exception 'invalid_mission_input'; end if;
  select * into mission from public.missions m where m.id=mission_id for update;
  if not found or mission.author_id<>account then raise exception 'mission_owner_required'; end if;
  if mission.status in ('cancelled','completed') then raise exception 'mission_terminal'; end if;
  select * into edited from jsonb_populate_record(mission,mission_input);
  if edited.starts_at is distinct from mission.starts_at and edited.starts_at<=now() then raise exception 'mission_must_be_future'; end if;
  update public.missions m set title=btrim(edited.title),body=btrim(edited.body),category=edited.category,location=btrim(edited.location),starts_at=edited.starts_at,capacity=edited.capacity,target_type=nullif(edited.target_type,''),image_path=nullif(edited.image_path,''),location_latitude=edited.location_latitude,location_longitude=edited.location_longitude,location_precision=edited.location_precision,requirements=nullif(btrim(edited.requirements),''),conditions=nullif(btrim(edited.conditions),'') where m.id=mission_id;
end;
$$;
drop function public.set_mission_status(uuid,text);
create function public.set_mission_status(mission_id uuid,new_status text,cancellation_reason text default null) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid := public.community_active_account(); mission public.missions;
begin
  if new_status is null or new_status not in ('open','closed','cancelled','completed') then raise exception 'invalid_status'; end if;
  select * into mission from public.missions m where m.id=mission_id for update;
  if not found or mission.author_id<>account then raise exception 'mission_owner_required'; end if;
  if mission.status in ('cancelled','completed') then
    if mission.status=new_status then return; end if;
    raise exception 'mission_terminal';
  end if;
  if new_status='open' and (mission.hidden or mission.starts_at<=now()) then raise exception 'mission_unavailable'; end if;
  if new_status='cancelled' and (cancellation_reason is null or char_length(btrim(cancellation_reason)) not between 5 and 500) then raise exception 'invalid_cancellation_reason'; end if;
  if new_status='completed' and mission.starts_at>now() then raise exception 'mission_not_started'; end if;
  update public.missions m set status=new_status,cancellation_reason=case when new_status='cancelled' then nullif(btrim(set_mission_status.cancellation_reason),'') else null end where m.id=mission_id;
end;
$$;
create or replace function public.apply_to_mission(mission_id uuid,application_message text) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid := public.community_active_account(); mission public.missions; application uuid; account_type text;
begin
  select * into mission from public.missions m where m.id=mission_id for update;
  if not found or mission.hidden or mission.status<>'open' or mission.starts_at<=now() then raise exception 'mission_unavailable'; end if;
  if mission.author_id=account then raise exception 'cannot_apply_to_own_mission'; end if;
  select user_type into account_type from public.profiles where id=account;
  if mission.target_type is not null and mission.target_type<>account_type then raise exception 'mission_target_mismatch'; end if;
  if (select count(*) from public.mission_applications a where a.mission_id=mission.id and a.status='accepted')>=mission.capacity then raise exception 'mission_full'; end if;
  insert into public.mission_applications as a(mission_id,applicant_id,message) values(mission.id,account,btrim(application_message))
    on conflict on constraint mission_applications_mission_id_applicant_id_key do update set message=excluded.message,status='pending' where a.status='withdrawn' returning id into application;
  if application is null then raise exception 'application_already_exists'; end if;
  update public.missions m set conditions_locked_at=coalesce(m.conditions_locked_at,now()) where m.id=mission.id;
  return application;
end;
$$;
create or replace function public.withdraw_application(application_id uuid) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid := public.community_active_account(); target uuid; mission public.missions;
begin
  select a.mission_id into target from public.mission_applications a where a.id=application_id and a.applicant_id=account;
  if not found then raise exception 'application_owner_required'; end if;
  select * into mission from public.missions m where m.id=target for update;
  if not found or mission.status in ('cancelled','completed') or mission.starts_at<=now() then raise exception 'mission_unavailable'; end if;
  update public.mission_applications a set status='withdrawn' where a.id=application_id and a.applicant_id=account and a.status in ('pending','accepted');
  if not found then raise exception 'application_not_withdrawable'; end if;
end;
$$;
create or replace function public.review_application(application_id uuid,decision text) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid := public.community_active_account(); target uuid; mission public.missions; application public.mission_applications; account_type text;
begin
  if decision is null or decision not in ('accepted','rejected') then raise exception 'invalid_decision'; end if;
  select a.mission_id into target from public.mission_applications a where a.id=application_id;
  select * into mission from public.missions m where m.id=target for update;
  if not found or mission.author_id<>account then raise exception 'mission_owner_required'; end if;
  select * into application from public.mission_applications a where a.id=application_id for update;
  if not found then raise exception 'application_not_found'; end if;
  if application.status='withdrawn' then raise exception 'application_withdrawn'; end if;
  if mission.hidden or mission.status not in ('open','closed') or mission.starts_at<=now() then raise exception 'mission_unavailable'; end if;
  if decision='accepted' then
    select user_type into account_type from public.profiles p where p.id=application.applicant_id;
    if mission.target_type is not null and mission.target_type<>account_type then raise exception 'mission_target_mismatch'; end if;
    if exists(select 1 from public.account_deletion_requests where user_id=application.applicant_id) then raise exception 'account_deletion_pending'; end if;
    if (select count(*) from public.mission_applications a where a.mission_id=mission.id and a.status='accepted' and a.id<>application_id)>=mission.capacity then raise exception 'mission_full'; end if;
  end if;
  update public.mission_applications a set status=decision where a.id=application_id;
end;
$$;

create function public.list_missions(author_filter uuid default null,query_text text default '',category_filter text default null,target_filter text default null,scope_filter text default 'all',page_offset int default 0,mission_filter uuid default null)
returns setof jsonb language plpgsql stable security definer set search_path='' as $$
declare account uuid := auth.uid(); admin boolean;
begin
  if account is null then raise exception 'authentication_required'; end if;
  if scope_filter is null or scope_filter not in ('all','discover','active','history') then raise exception 'invalid_scope'; end if;
  admin:=public.community_is_admin();
  return query
  select to_jsonb(m)||jsonb_build_object('accepted_count',(select count(*) from public.mission_applications a where a.mission_id=m.id and a.status='accepted'),
    'pending_count',case when m.author_id=account or admin then (select count(*) from public.mission_applications a where a.mission_id=m.id and a.status='pending') else null end,
    'organizer_name',p.full_name,'organizer_username',p.username)
  from public.missions m join public.profiles p on p.id=m.author_id
  where (not m.hidden or m.author_id=account or admin)
    and not exists(select 1 from public.account_deletion_requests d where d.user_id=m.author_id)
    and (author_filter is null or m.author_id=author_filter)
    and (mission_filter is null or m.id=mission_filter)
    and (coalesce(query_text,'')='' or m.title ilike '%'||left(query_text,100)||'%' or m.body ilike '%'||left(query_text,100)||'%' or m.location ilike '%'||left(query_text,100)||'%')
    and (category_filter is null or m.category=category_filter)
    and (target_filter is null or m.target_type is null or m.target_type=target_filter)
    and (scope_filter='all' or (scope_filter='discover' and m.status='open' and not m.hidden and m.starts_at>now())
      or (scope_filter='active' and m.status in ('open','closed') and m.starts_at>now())
      or (scope_filter='history' and (m.status in ('cancelled','completed') or m.starts_at<=now())))
  order by m.created_at desc,m.id desc limit 30 offset greatest(coalesce(page_offset,0),0);
end;
$$;
revoke all on function public.create_mission(jsonb),public.update_mission(uuid,jsonb),public.set_mission_status(uuid,text,text),public.list_missions(uuid,text,text,text,text,int,uuid) from public,anon,authenticated;
grant execute on function public.create_mission(jsonb),public.update_mission(uuid,jsonb),public.set_mission_status(uuid,text,text),public.list_missions(uuid,text,text,text,text,int,uuid) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('mission-images','mission-images',false,4194304,array['image/png'])
on conflict(id) do update set public=false,file_size_limit=4194304,allowed_mime_types=array['image/png'];
create policy "Read visible mission images" on storage.objects for select to authenticated
using(bucket_id='mission-images' and ((storage.foldername(name))[1]=auth.uid()::text or exists(select 1 from public.missions m where m.image_path=name)));
create policy "Upload own mission images" on storage.objects for insert to authenticated
with check(bucket_id='mission-images' and name ~ ('^'||auth.uid()::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$'));
create policy "Delete own unused mission images" on storage.objects for delete to authenticated
using(bucket_id='mission-images' and (storage.foldername(name))[1]=auth.uid()::text and not exists(select 1 from public.missions m where m.image_path=name));
create function public.guard_mission_image_operation() returns trigger
language plpgsql security definer set search_path='' as $$
declare owner_id uuid;
begin
  if tg_op='DELETE' then
    if old.bucket_id<>'mission-images' then return old; end if;
    owner_id:=split_part(old.name,'/',1)::uuid;
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text,0));
    if auth.uid() is not null and exists(select 1 from public.missions where image_path=old.name) then raise exception 'mission_image_in_use'; end if;
    return old;
  end if;
  if tg_op='UPDATE' and (old.bucket_id='mission-images' or new.bucket_id='mission-images') then raise exception 'mission_image_immutable'; end if;
  if new.bucket_id<>'mission-images' then return new; end if;
  if new.name !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$' then raise exception 'invalid_mission_image'; end if;
  owner_id:=split_part(new.name,'/',1)::uuid;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text,0));
  if not exists(select 1 from public.profiles where id=owner_id) then raise exception 'account_required'; end if;
  if exists(select 1 from public.account_deletion_requests where user_id=owner_id) then raise exception 'account_deletion_pending'; end if;
  return new;
end;
$$;
revoke all on function public.guard_mission_image_operation() from public,anon,authenticated;
create trigger guard_mission_images before insert or update or delete on storage.objects for each row execute function public.guard_mission_image_operation();
