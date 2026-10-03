-- Additive mission experience. Drafts never enter public discovery.
alter table public.missions add column compensation_type text,
 add column compensation_amount_cents bigint,
 add column lifecycle_event_version bigint not null default 0,
 add constraint missions_compensation_check check (coalesce(
  (compensation_type is null and compensation_amount_cents is null) or
  (compensation_type in ('unpaid','negotiable') and compensation_amount_cents is null) or
  (compensation_type='paid' and compensation_amount_cents between 1 and 9999999900),false));
-- SQL CHECK admits null expressions; explicitly enforce paid amounts.
alter table public.missions add constraint missions_paid_amount_required check(compensation_type is distinct from 'paid' or compensation_amount_cents is not null);
create function public.lock_mission_compensation() returns trigger language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
begin
 if old.conditions_locked_at is not null and row(new.compensation_type,new.compensation_amount_cents) is distinct from row(old.compensation_type,old.compensation_amount_cents) then raise exception 'mission_conditions_locked'; end if;
 return new;
end $$;
revoke all on function public.lock_mission_compensation() from public,anon,authenticated;
create trigger lock_mission_compensation before update on public.missions for each row execute function public.lock_mission_compensation();
-- Retain the existing validated CRUD implementations behind private wrappers.
alter function public.create_mission(jsonb) rename to create_mission_legacy;
alter function public.update_mission(uuid,jsonb) rename to update_mission_legacy;
revoke all on function public.create_mission_legacy(jsonb),public.update_mission_legacy(uuid,jsonb) from public,anon,authenticated;
create function public.create_mission(mission_input jsonb) returns uuid language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare result uuid;
begin
 if mission_input ? 'compensation_amount_cents' and mission_input->>'compensation_amount_cents' is not null and mission_input->>'compensation_amount_cents' !~ '^[0-9]+$' then raise exception 'invalid_mission_compensation'; end if;
 result:=public.create_mission_legacy(mission_input-'compensation_type'-'compensation_amount_cents');
 update public.missions set compensation_type=mission_input->>'compensation_type',compensation_amount_cents=(mission_input->>'compensation_amount_cents')::bigint where id=result;
 return result;
end $$;
create function public.update_mission(mission_id uuid,mission_input jsonb) returns void language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
begin
 if mission_input ? 'compensation_amount_cents' and mission_input->>'compensation_amount_cents' is not null and mission_input->>'compensation_amount_cents' !~ '^[0-9]+$' then raise exception 'invalid_mission_compensation'; end if;
 perform public.update_mission_legacy(mission_id,mission_input-'compensation_type'-'compensation_amount_cents');
 update public.missions m set compensation_type=case when mission_input ? 'compensation_type' then mission_input->>'compensation_type' else m.compensation_type end,
 compensation_amount_cents=case when mission_input ? 'compensation_amount_cents' then (mission_input->>'compensation_amount_cents')::bigint else m.compensation_amount_cents end where m.id=mission_id;
end $$;

create table public.mission_drafts (
 id uuid primary key,
 author_id uuid not null references public.profiles(id) on delete cascade,
 data jsonb not null check(jsonb_typeof(data)='object' and pg_column_size(data)<=65536),
 updated_at timestamptz not null default clock_timestamp(),
 published_mission_id uuid references public.missions(id) on delete set null,
 published_at timestamptz
);
create index mission_drafts_author_time on public.mission_drafts(author_id,updated_at desc);
create table public.mission_saves (
 user_id uuid not null references public.profiles(id) on delete cascade,
 mission_id uuid not null references public.missions(id) on delete cascade,
 created_at timestamptz not null default clock_timestamp(),primary key(user_id,mission_id)
);
create table public.mission_finalists (
 mission_id uuid not null references public.missions(id) on delete cascade,
 application_id uuid not null references public.mission_applications(id) on delete cascade,
 created_at timestamptz not null default clock_timestamp(),primary key(mission_id,application_id)
);
alter table public.mission_drafts enable row level security;
alter table public.mission_saves enable row level security;
alter table public.mission_finalists enable row level security;
revoke all on public.mission_drafts,public.mission_saves,public.mission_finalists from anon,authenticated;
grant select on public.mission_drafts,public.mission_saves,public.mission_finalists to authenticated;
grant all on public.mission_drafts,public.mission_saves,public.mission_finalists to service_role;
create policy "Private mission drafts" on public.mission_drafts for select to authenticated using(author_id=auth.uid());
create policy "Private mission saves" on public.mission_saves for select to authenticated using(user_id=auth.uid());
create policy "Organizer finalists" on public.mission_finalists for select to authenticated using(exists(select 1 from public.missions m where m.id=mission_id and m.author_id=auth.uid()));
create function public.save_mission_draft(draft_id uuid,draft_input jsonb) returns uuid language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare account uuid:=public.community_active_account(); existing public.mission_drafts; image text; field record; text_value text; max_length int; parsed_time timestamptz; parsed_date date;
begin
 if draft_id is null or draft_input is null or jsonb_typeof(draft_input)<>'object' or pg_column_size(draft_input)>65536 or exists(select 1 from jsonb_object_keys(draft_input) k where k not in ('title','body','category','location','starts_at','capacity','target_type','image_path','location_latitude','location_longitude','location_precision','requirements','conditions','compensation_type','compensation_amount_cents','starts_date','starts_hour','starts_minute','compensation_amount_text','capacity_text')) then raise exception 'invalid_mission_draft'; end if;
 -- community_active_account() holds the same owner advisory transaction lock as
 -- guard_mission_image_operation(), serializing save/publish/delete with storage.
 -- Drafts allow empty/incomplete values and invalid business numbers (e.g. 101
 -- places, zero cents); types, representation bounds and text limits remain safe.
 for field in select key,value from jsonb_each(draft_input) loop
  if jsonb_typeof(field.value)='null' then continue; end if;
  text_value:=field.value #>> '{}';
  if field.key in ('title','body','category','location','target_type','image_path','location_precision','requirements','conditions','compensation_type','starts_at','starts_date','compensation_amount_text','capacity_text') then
   if jsonb_typeof(field.value)<>'string' then raise exception 'invalid_mission_draft'; end if;
   max_length:=case field.key when 'title' then 100 when 'body' then 3000 when 'location' then 180 when 'requirements' then 3000 when 'conditions' then 3000 when 'image_path' then 80 when 'starts_at' then 64 when 'starts_date' then 64 else 100 end;
   if char_length(text_value)>max_length then raise exception 'invalid_mission_draft'; end if;
   if field.key='category' and text_value<>'' and text_value not in ('arte','musica','digital','gastronomia','moda','escritura','fotografia','diseno','otros') then raise exception 'invalid_mission_draft'; end if;
   if field.key='target_type' and text_value<>'' and text_value not in ('Usuario general','Artista / creador','Emprendedor','Negocio') then raise exception 'invalid_mission_draft'; end if;
   if field.key='location_precision' and text_value<>'' and text_value not in ('exact','approximate') then raise exception 'invalid_mission_draft'; end if;
   if field.key='compensation_type' and text_value<>'' and text_value not in ('paid','unpaid','negotiable') then raise exception 'invalid_mission_draft'; end if;
   if field.key='starts_at' and text_value<>'' then
    if text_value !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' then raise exception 'invalid_mission_draft'; end if;
    parsed_time:=text_value::timestamptz;
   elsif field.key='starts_date' and text_value<>'' then
    if text_value !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}(T00:00:00(\.[0-9]{1,6})?)?$' then raise exception 'invalid_mission_draft'; end if;
    parsed_date:=text_value::date;
   end if;
  elsif field.key in ('capacity','compensation_amount_cents','starts_hour','starts_minute') then
   if jsonb_typeof(field.value)<>'number' or text_value !~ '^-?[0-9]+$' then raise exception 'invalid_mission_draft'; end if;
   if field.key='capacity' and text_value::numeric not between -2147483648 and 2147483647 then raise exception 'invalid_mission_draft'; end if;
   if field.key='compensation_amount_cents' and text_value::numeric not between 0 and 9999999999 then raise exception 'invalid_mission_draft'; end if;
   if field.key='starts_hour' and text_value::numeric not between 0 and 23 then raise exception 'invalid_mission_draft'; end if;
   if field.key='starts_minute' and text_value::numeric not between 0 and 59 then raise exception 'invalid_mission_draft'; end if;
  elsif field.key in ('location_latitude','location_longitude') then
   if jsonb_typeof(field.value)<>'number' then raise exception 'invalid_mission_draft'; end if;
   if field.key='location_latitude' and text_value::numeric not between -90 and 90 then raise exception 'invalid_mission_draft'; end if;
   if field.key='location_longitude' and text_value::numeric not between -180 and 180 then raise exception 'invalid_mission_draft'; end if;
  end if;
 end loop;
 image:=nullif(draft_input->>'image_path','');
 if image is not null and (image !~ ('^'||account::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$') or not exists(select 1 from storage.objects where bucket_id='mission-images' and name=image)) then raise exception 'invalid_mission_image'; end if;
 select * into existing from public.mission_drafts d where d.id=draft_id for update;
 if found and existing.author_id<>account then raise exception 'mission_owner_required'; end if;
 if existing.published_at is not null then raise exception 'mission_draft_published'; end if;
 insert into public.mission_drafts(id,author_id,data) values(draft_id,account,draft_input)
 on conflict(id) do update set data=excluded.data,updated_at=clock_timestamp() where mission_drafts.author_id=account and mission_drafts.published_at is null;
 if not found then raise exception 'mission_owner_required'; end if;
 return draft_id;
end $$;
create function public.publish_mission_draft(draft_id uuid,mission_input jsonb) returns uuid language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare account uuid:=public.community_active_account(); draft public.mission_drafts; result uuid;
begin
 select * into draft from public.mission_drafts d where d.id=draft_id for update;
 if not found or draft.author_id<>account then raise exception 'mission_owner_required'; end if;
 if draft.published_at is not null then
  if draft.published_mission_id is null then raise exception 'mission_draft_published'; end if;
  return draft.published_mission_id;
 end if;
 result:=public.create_mission(mission_input);
 update public.mission_drafts d set data=mission_input,published_mission_id=result,published_at=clock_timestamp(),updated_at=clock_timestamp() where d.id=draft_id;
 return result;
end $$;
create function public.delete_mission_draft(draft_id uuid) returns void language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare account uuid:=public.community_active_account();
begin
 if exists(select 1 from public.mission_drafts d where d.id=draft_id and d.author_id=account and d.published_at is not null) then raise exception 'mission_draft_published'; end if;
 delete from public.mission_drafts d where d.id=draft_id and d.author_id=account;
 if not found then raise exception 'mission_owner_required'; end if;
end $$;
create function public.set_mission_saved(mission_id uuid,is_saved boolean) returns void language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare account uuid:=public.community_active_account();
begin
 if is_saved is null then raise exception 'invalid_mission_save'; end if;
 if is_saved then
  if not exists(select 1 from public.missions m where m.id=mission_id and not m.hidden and not exists(select 1 from public.account_deletion_requests d where d.user_id=m.author_id)) then raise exception 'mission_unavailable'; end if;
  insert into public.mission_saves(user_id,mission_id) values(account,mission_id) on conflict do nothing;
 else delete from public.mission_saves s where s.user_id=account and s.mission_id=set_mission_saved.mission_id;
 end if;
end $$;

alter table public.mission_applications add column availability_confirmed boolean,
 add column evidence jsonb not null default '[]' check(jsonb_typeof(evidence)='array' and jsonb_array_length(evidence)<=3),
 add column event_version bigint not null default 0;
create table public.mission_application_operations (
 applicant_id uuid not null references public.profiles(id) on delete cascade,
 operation_id uuid not null,
 mission_id uuid not null references public.missions(id) on delete cascade,
 application_id uuid not null references public.mission_applications(id) on delete cascade,
 input jsonb not null,primary key(applicant_id,operation_id)
);
alter table public.mission_application_operations enable row level security;
revoke all on public.mission_application_operations from public,anon,authenticated;
grant all on public.mission_application_operations to service_role;
create function public.submit_mission_application(mission_id uuid,application_input jsonb) returns uuid language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare account uuid:=public.community_active_account(); operation uuid; existing public.mission_application_operations; result uuid; sample jsonb; samples jsonb;
begin
 if application_input is null or jsonb_typeof(application_input)<>'object' or exists(select 1 from jsonb_object_keys(application_input) k where k not in ('operation_id','message','availability_confirmed','evidence')) then raise exception 'invalid_application_input'; end if;
 operation:=(application_input->>'operation_id')::uuid;
 if operation is null then raise exception 'invalid_application_operation'; end if;
 select * into existing from public.mission_application_operations o where o.applicant_id=account and o.operation_id=operation;
 if found then
  if existing.mission_id<>mission_id or existing.input<>application_input then raise exception 'application_operation_conflict'; end if;
  return existing.application_id;
 end if;
 if jsonb_typeof(application_input->'message') is distinct from 'string' then raise exception 'invalid_application_input'; end if;
 if application_input->'availability_confirmed' is distinct from 'true'::jsonb then raise exception 'application_availability_required'; end if;
 samples:=coalesce(application_input->'evidence','[]'::jsonb);
 if jsonb_typeof(samples)<>'array' or jsonb_array_length(samples)>3 then raise exception 'invalid_application_evidence'; end if;
 for sample in select value from jsonb_array_elements(samples) loop
  if jsonb_typeof(sample)<>'object' or jsonb_typeof(sample->'title') is distinct from 'string' or (sample ? 'url' and jsonb_typeof(sample->'url') not in ('string','null')) or (sample ? 'showcase_id' and jsonb_typeof(sample->'showcase_id') not in ('string','null')) or char_length(sample->>'title')>100 or exists(select 1 from jsonb_object_keys(sample) k where k not in ('title','url','showcase_id')) or not coalesce(char_length(btrim(sample->>'title')) between 1 and 100,false) or num_nonnulls(nullif(sample->>'url',''),nullif(sample->>'showcase_id',''))<>1 then raise exception 'invalid_application_evidence'; end if;
  if nullif(sample->>'url','') is not null then
   if char_length(sample->>'url')>2000 or sample->>'url' !~ '^https://[^[:space:]/?#@]+([/?#][^[:space:]]*)?$' then raise exception 'invalid_application_evidence_url'; end if;
  else
   perform 1 from public.showcase_items s where s.id=(sample->>'showcase_id')::uuid and s.owner_id=account and s.status='published' and s.available and not s.hidden for share;
   if not found then raise exception 'application_showcase_unavailable'; end if;
  end if;
 end loop;
 result:=public.apply_to_mission(mission_id,application_input->>'message');
 update public.mission_applications a set availability_confirmed=true,evidence=samples where a.id=result;
 insert into public.mission_application_operations(applicant_id,operation_id,mission_id,application_id,input) values(account,operation,mission_id,result,application_input);
 return result;
end $$;
create function public.set_mission_finalist(mission_id uuid,application_id uuid,is_finalist boolean) returns void language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare account uuid:=public.community_active_account(); mission public.missions;
begin
 select * into mission from public.missions m where m.id=mission_id for update;
 if not found or mission.author_id<>account then raise exception 'mission_owner_required'; end if;
 if is_finalist is null then raise exception 'invalid_finalist'; end if;
 if not exists(select 1 from public.mission_applications a where a.id=application_id and a.mission_id=mission_id) then raise exception 'application_not_found'; end if;
 if is_finalist then
  if mission.hidden or mission.status not in ('open','closed') or mission.starts_at<=now() then raise exception 'mission_unavailable'; end if;
  if not exists(select 1 from public.mission_applications a where a.id=application_id and a.status='pending') then raise exception 'application_not_pending'; end if;
  insert into public.mission_finalists(mission_id,application_id) values(mission_id,application_id) on conflict do nothing;
 else delete from public.mission_finalists f where f.mission_id=set_mission_finalist.mission_id and f.application_id=set_mission_finalist.application_id;
 end if;
end $$;
create function public.confirm_mission_selection(mission_id uuid,application_ids uuid[]) returns void language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare account uuid:=public.community_active_account(); mission public.missions; item uuid; current_status text;
begin
 select * into mission from public.missions m where m.id=mission_id for update;
 if not found or mission.author_id<>account then raise exception 'mission_owner_required'; end if;
 if mission.hidden or mission.status not in ('open','closed') or mission.starts_at<=now() then raise exception 'mission_unavailable'; end if;
 if application_ids is null or cardinality(application_ids)=0 or cardinality(application_ids)>100 or array_position(application_ids,null) is not null then raise exception 'invalid_mission_selection'; end if;
 if exists(select 1 from unnest(application_ids) selected where not exists(select 1 from public.mission_applications a where a.id=selected and a.mission_id=mission_id and a.status in ('pending','accepted'))) then raise exception 'invalid_mission_selection'; end if;
 if (select count(*) from public.mission_applications a where a.mission_id=mission_id and (a.status='accepted' or a.id=any(application_ids)))>mission.capacity then raise exception 'mission_full'; end if;
 for item in select distinct unnest(application_ids) loop
  select a.status into current_status from public.mission_applications a where a.id=item;
  if current_status='pending' then perform public.review_application(item,'accepted'); end if;
 end loop;
end $$;

-- Mission events use monotonic transition versions: retried requests produce no event,
-- but closing/reopening and a new application after withdrawal each remain visible.
alter table public.notifications alter column post_id drop not null,
 add column mission_id uuid references public.missions(id) on delete cascade;
alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check(kind in ('reaction','comment','interest','mission_application','mission_accepted','mission_rejected','mission_withdrawn','mission_closed','mission_reopened','mission_cancelled','mission_completed')),
 add constraint notifications_one_target check(num_nonnulls(post_id,mission_id)=1);
create function public.version_mission_event() returns trigger language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
begin
 if tg_table_name='missions' then
  new.lifecycle_event_version:=old.lifecycle_event_version+case when new.status is distinct from old.status then 1 else 0 end;
 else
  if tg_op='INSERT' then new.event_version:=1;
  else new.event_version:=old.event_version+case when new.status is distinct from old.status then 1 else 0 end;
   if old.status='withdrawn' and new.status='pending' then new.availability_confirmed:=null; new.evidence:='[]'; end if;
  end if;
 end if;
 return new;
end $$;
create trigger mission_event_version before update on public.missions for each row execute function public.version_mission_event();
create trigger application_event_version before insert or update on public.mission_applications for each row execute function public.version_mission_event();
create function public.notify_mission_application() returns trigger language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare mission public.missions; recipient uuid; actor uuid; event_kind text;
begin
 if tg_op='UPDATE' and new.status is not distinct from old.status then return new; end if;
 select * into mission from public.missions m where m.id=new.mission_id;
 if new.status<>'pending' then delete from public.mission_finalists f where f.application_id=new.id; end if;
 if new.status='pending' then recipient:=mission.author_id; actor:=new.applicant_id; event_kind:='mission_application';
 elsif new.status='withdrawn' then recipient:=mission.author_id; actor:=new.applicant_id; event_kind:='mission_withdrawn';
 else recipient:=new.applicant_id; actor:=mission.author_id; event_kind:='mission_'||new.status;
 end if;
 if recipient<>actor and not exists(select 1 from public.account_deletion_requests where user_id=recipient) then
  insert into public.notifications(recipient_id,actor_id,mission_id,kind,source_id,event_key,post_title)
   values(recipient,actor,mission.id,event_kind,new.id,'mission-application:'||new.id||':'||new.event_version,mission.title) on conflict(event_key) do nothing;
 end if;
 return new;
end $$;
create trigger mission_application_notification after insert or update on public.mission_applications for each row execute function public.notify_mission_application();
create function public.notify_mission_status() returns trigger language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare event_kind text;
begin
 if new.status is not distinct from old.status then return new; end if;
 event_kind:=case new.status when 'open' then 'mission_reopened' else 'mission_'||new.status end;
 insert into public.notifications(recipient_id,actor_id,mission_id,kind,event_key,post_title)
 select a.applicant_id,new.author_id,new.id,event_kind,'mission-status:'||new.id||':'||new.lifecycle_event_version||':'||a.applicant_id,new.title
 from public.mission_applications a where a.mission_id=new.id and a.status in ('pending','accepted') and a.applicant_id<>new.author_id
 and not exists(select 1 from public.account_deletion_requests d where d.user_id=a.applicant_id)
 on conflict(event_key) do nothing;
 return new;
end $$;
create trigger mission_status_notification after update on public.missions for each row execute function public.notify_mission_status();
revoke all on function public.version_mission_event(),public.notify_mission_application(),public.notify_mission_status() from public,anon,authenticated;

-- Keep unpublished covers private and referenced covers protected from deletion.
drop policy "Delete own unused mission images" on storage.objects;
create policy "Delete own unused mission images" on storage.objects for delete to authenticated
 using(bucket_id='mission-images' and (storage.foldername(name))[1]=auth.uid()::text
 and not exists(select 1 from public.missions m where m.image_path=name)
 and not exists(select 1 from public.mission_drafts d where d.published_at is null and d.data->>'image_path'=name));
create or replace function public.guard_mission_image_operation() returns trigger
language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare owner_id uuid;
begin
 if tg_op='DELETE' then
  if old.bucket_id<>'mission-images' then return old; end if;
  owner_id:=split_part(old.name,'/',1)::uuid;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text,0));
  if auth.uid() is not null and (exists(select 1 from public.missions where image_path=old.name) or exists(select 1 from public.mission_drafts where published_at is null and data->>'image_path'=old.name)) then raise exception 'mission_image_in_use'; end if;
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
end $$;
revoke all on function public.create_mission(jsonb),public.update_mission(uuid,jsonb),public.save_mission_draft(uuid,jsonb),public.publish_mission_draft(uuid,jsonb),public.delete_mission_draft(uuid),public.set_mission_saved(uuid,boolean),public.submit_mission_application(uuid,jsonb),public.set_mission_finalist(uuid,uuid,boolean),public.confirm_mission_selection(uuid,uuid[]) from public,anon,authenticated;
grant execute on function public.create_mission(jsonb),public.update_mission(uuid,jsonb),public.save_mission_draft(uuid,jsonb),public.publish_mission_draft(uuid,jsonb),public.delete_mission_draft(uuid),public.set_mission_saved(uuid,boolean),public.submit_mission_application(uuid,jsonb),public.set_mission_finalist(uuid,uuid,boolean),public.confirm_mission_selection(uuid,uuid[]) to authenticated;

create function public.list_saved_missions(query_text text default '',category_filter text default null,target_filter text default null,page_offset int default 0)
returns setof jsonb language plpgsql stable security definer set search_path='' as $$
#variable_conflict use_variable
declare account uuid:=public.community_active_account(); admin boolean:=public.community_is_admin();
begin
 return query select to_jsonb(m)||jsonb_build_object('accepted_count',(select count(*) from public.mission_applications a where a.mission_id=m.id and a.status='accepted'),
 'pending_count',case when m.author_id=account or admin then (select count(*) from public.mission_applications a where a.mission_id=m.id and a.status='pending') else null end,
 'organizer_name',p.full_name,'organizer_username',p.username,'organizer_avatar_path',p.avatar_path)
 from public.mission_saves s join public.missions m on m.id=s.mission_id join public.profiles p on p.id=m.author_id
 where s.user_id=account and (not m.hidden or m.author_id=account or admin)
 and not exists(select 1 from public.account_deletion_requests d where d.user_id=m.author_id)
 and (coalesce(query_text,'')='' or m.title ilike '%'||left(query_text,100)||'%' or m.body ilike '%'||left(query_text,100)||'%' or m.location ilike '%'||left(query_text,100)||'%')
 and (category_filter is null or m.category=category_filter) and (target_filter is null or m.target_type is null or m.target_type=target_filter)
 order by s.created_at desc,m.id desc limit 30 offset greatest(coalesce(page_offset,0),0);
end $$;
revoke all on function public.list_saved_missions(text,text,text,integer) from public,anon,authenticated;
grant execute on function public.list_saved_missions(text,text,text,integer) to authenticated;
