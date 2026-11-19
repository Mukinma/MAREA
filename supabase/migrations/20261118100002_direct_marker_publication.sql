-- Apply after 041_ar_markers. Publication and proximity notices are separate:
-- a tested image can be public without coordinates or background location.
begin;
alter table public.ar_markers add column published boolean not null default false;
-- Only markers that were already publicly accessible keep that visibility.
update public.ar_markers set published=true where active and review_status='approved'
 and tested_version=reference_version and test_platform in ('android','ios') and tracking_seconds>=3;
alter table public.ar_markers add constraint ar_markers_publication_requires_recognition
 check(not published or (review_status='approved' and tested_version is not null
  and tested_version=reference_version and test_platform is not null
  and test_platform in ('android','ios') and tracking_seconds>=3));

create or replace function private.ar_marker_reference_guard() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if tg_op='INSERT' then
  new.reference_version:=gen_random_uuid(); new.tested_version:=null;
  new.active:=false; new.published:=false; new.review_status:='pending';
  new.test_platform:=null; new.tracking_seconds:=0;
 else
  if new.id is distinct from old.id or new.owner_id is distinct from old.owner_id then
   raise exception 'marker_owner_immutable';
  end if;
  if new.reference_path is distinct from old.reference_path or new.width_cm is distinct from old.width_cm then
   new.reference_version:=gen_random_uuid(); new.tested_version:=null;
   new.active:=false; new.published:=false; new.review_status:='pending';
   new.test_platform:=null; new.tracking_seconds:=0;
  elsif row(new.latitude,new.longitude,new.location_exact,new.location_accuracy)
    is distinct from row(old.latitude,old.longitude,old.location_exact,old.location_accuracy) then
   new.active:=false;
  end if;
  -- Text edits keep real recognition and publication; no review queue.
 end if;
 if new.reference_path !~ ('^'||new.owner_id::text||'/'||new.id::text||'/[0-9a-fA-F-]{36}\.jpg$')
  or not exists(select 1 from storage.objects where bucket_id='ar-marker-images' and name=new.reference_path) then
  raise exception 'marker_reference_required';
 end if;
 new.updated_at:=clock_timestamp(); return new;
end$$;

create function public.ar_markers_set_publication(
 p_id uuid,p_reference_version uuid,p_published boolean,p_active boolean default false
) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); marker public.ar_markers;
begin
 select * into marker from public.ar_markers where id=p_id and owner_id=account for update;
 if not found then raise exception 'marker_owner_required'; end if;
 if p_reference_version is distinct from marker.reference_version then raise exception 'marker_reference_changed'; end if;
 if p_published is null or p_active is null or (p_active and not p_published) then raise exception 'invalid_marker_publication'; end if;
 if p_published and (marker.tested_version is distinct from marker.reference_version
  or marker.test_platform is null or marker.tracking_seconds<3) then raise exception 'marker_recognition_required'; end if;
 if p_active and (not marker.location_exact or marker.latitude is null
  or marker.location_accuracy is null or marker.location_accuracy>20) then raise exception 'marker_precise_location_required'; end if;
 update public.ar_markers set published=p_published,active=p_active,
  review_status=case when p_published then 'approved' else review_status end
 where id=marker.id returning * into marker;
 return to_jsonb(marker);
end$$;
revoke all on function public.ar_markers_set_publication(uuid,uuid,boolean,boolean) from public,anon;
grant execute on function public.ar_markers_set_publication(uuid,uuid,boolean,boolean) to authenticated;

create or replace function public.ar_markers_confirm_recognition(p_id uuid,p_reference_version uuid,p_platform text,p_seconds integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); marker public.ar_markers;
begin
 if p_platform not in ('android','ios') or p_platform is null or p_seconds is null
  or p_seconds<3 or p_seconds>3600 then raise exception 'marker_recognition_required'; end if;
 select * into marker from public.ar_markers where id=p_id and owner_id=account for update;
 if not found then raise exception 'marker_owner_required'; end if;
 if p_reference_version is distinct from marker.reference_version then raise exception 'marker_reference_changed'; end if;
 update public.ar_markers set tested_version=reference_version,test_platform=p_platform,
  tracking_seconds=p_seconds,published=true,review_status='approved' where id=marker.id returning * into marker;
 return to_jsonb(marker);
end$$;

create function private.ar_marker_owner_available(p_owner uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select not exists(select 1 from public.account_deletion_requests where user_id=p_owner);
$$;
revoke all on function private.ar_marker_owner_available(uuid) from public;
grant execute on function private.ar_marker_owner_available(uuid) to anon,authenticated;

drop policy "Reviewed markers are public" on public.ar_markers;
create policy "Published markers are public" on public.ar_markers for select to anon,authenticated
 using(published and review_status='approved' and tested_version=reference_version
  and private.ar_marker_owner_available(owner_id));
drop policy "Reviewed marker images read" on storage.objects;
create policy "Published marker images read" on storage.objects for select to anon,authenticated
 using(bucket_id='ar-marker-images' and exists(select 1 from public.ar_markers m
  where m.reference_path=storage.objects.name and m.published
   and m.review_status='approved' and m.tested_version=m.reference_version));
-- Clients still cannot write recognition, published, active or legacy review columns.
notify pgrst,'reload schema';
commit;
