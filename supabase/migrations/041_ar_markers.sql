-- Prepared only: independent private marker CRUD. No automatic publication.
create table public.ar_markers (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.profiles(id) on delete cascade,
 name text not null check (length(btrim(name)) between 1 and 120),
 description text not null default '' check (length(description)<=4000),
 menu_url text check (menu_url is null or (length(menu_url)<=2048 and menu_url ~* '^https?://[^/@[:space:]]+([/:?#]|$)')),
 width_cm numeric not null check (width_cm between 1 and 1000),
 reference_version uuid not null default gen_random_uuid(),
 tested_version uuid,
 reference_path text not null,
 latitude double precision check (latitude between -90 and 90),
 longitude double precision check (longitude between -180 and 180),
 location_exact boolean not null default false,
 location_accuracy double precision check (location_accuracy>=0 and location_accuracy<'Infinity'::double precision),
 active boolean not null default false,
 review_status text not null default 'pending' check (review_status in ('pending','approved','rejected')),
 test_platform text check (test_platform in ('android','ios')),
 tracking_seconds integer not null default 0 check (tracking_seconds>=0),
 created_at timestamptz not null default clock_timestamp(),
 updated_at timestamptz not null default clock_timestamp(),
 check ((latitude is null)=(longitude is null)),
 check (not location_exact or latitude is not null),
 check (not active or (review_status='approved' and tested_version=reference_version and tested_version is not null
   and location_exact and latitude is not null and location_accuracy<=20 and location_accuracy is not null))
);
alter table public.ar_markers enable row level security;
create index ar_markers_owner_idx on public.ar_markers(owner_id,created_at desc);

create function private.ar_marker_reference_guard() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if tg_op='INSERT' then
  new.reference_version:=gen_random_uuid();new.tested_version:=null;
  new.active:=false;new.review_status:='pending';new.test_platform:=null;new.tracking_seconds:=0;
 else
  if new.id is distinct from old.id or new.owner_id is distinct from old.owner_id then raise exception 'marker_owner_immutable';end if;
  if new.reference_path is distinct from old.reference_path or new.width_cm is distinct from old.width_cm then
   new.reference_version:=gen_random_uuid();new.tested_version:=null;new.active:=false;
   new.review_status:='pending';new.test_platform:=null;new.tracking_seconds:=0;
  elsif row(new.name,new.description,new.menu_url,new.latitude,new.longitude,new.location_exact,new.location_accuracy)
      is distinct from row(old.name,old.description,old.menu_url,old.latitude,old.longitude,old.location_exact,old.location_accuracy) then
   -- Recognition remains valid, but changed public content requires review.
   new.active:=false;new.review_status:='pending';
  end if;
 end if;
 if new.reference_path !~ ('^'||new.owner_id::text||'/'||new.id::text||'/[0-9a-fA-F-]{36}\.jpg$')
   or not exists(select 1 from storage.objects where bucket_id='ar-marker-images' and name=new.reference_path) then
  raise exception 'marker_reference_required';
 end if;
 new.updated_at:=clock_timestamp();return new;
end$$;
revoke all on function private.ar_marker_reference_guard() from public,anon,authenticated;
create trigger ar_marker_reference_guard before insert or update on public.ar_markers
for each row execute function private.ar_marker_reference_guard();

-- Column privileges prevent clients from forging recognition, review or activation.
revoke all on public.ar_markers from anon,authenticated;
grant select on public.ar_markers to anon,authenticated;
grant insert(id,owner_id,name,description,menu_url,width_cm,reference_path,latitude,longitude,location_exact,location_accuracy)
 on public.ar_markers to authenticated;
grant update(name,description,menu_url,width_cm,reference_path,latitude,longitude,location_exact,location_accuracy)
 on public.ar_markers to authenticated;
grant delete on public.ar_markers to authenticated;
create policy "Marker owner reads" on public.ar_markers for select to authenticated using(owner_id=auth.uid());
create policy "Reviewed markers are public" on public.ar_markers for select to anon,authenticated
 using(active and review_status='approved' and tested_version=reference_version);
create policy "Marker owner creates" on public.ar_markers for insert to authenticated
 with check(owner_id=auth.uid() and owner_id=public.community_active_account());
create policy "Marker owner edits" on public.ar_markers for update to authenticated
 using(owner_id=auth.uid()) with check(owner_id=auth.uid() and owner_id=public.community_active_account());
create policy "Marker owner deletes" on public.ar_markers for delete to authenticated using(owner_id=auth.uid());

create function public.ar_markers_confirm_recognition(p_id uuid,p_reference_version uuid,p_platform text,p_seconds integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();marker public.ar_markers;begin
 if p_platform not in ('android','ios') or p_platform is null or p_seconds is null or p_seconds<3 or p_seconds>3600 then raise exception 'marker_recognition_required';end if;
 select * into marker from public.ar_markers where id=p_id and owner_id=account for update;
 if not found then raise exception 'marker_owner_required';end if;
 if p_reference_version is distinct from marker.reference_version then raise exception 'marker_reference_changed';end if;
 update public.ar_markers set tested_version=reference_version,test_platform=p_platform,tracking_seconds=p_seconds
 where id=marker.id returning * into marker;
 -- Deliberately preserves pending review and inactive state.
 return to_jsonb(marker);
end$$;
revoke all on function public.ar_markers_confirm_recognition(uuid,uuid,text,integer) from public,anon;
grant execute on function public.ar_markers_confirm_recognition(uuid,uuid,text,integer) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('ar-marker-images','ar-marker-images',false,8388608,array['image/jpeg']);
create policy "Marker image owner reads" on storage.objects for select to authenticated
 using(bucket_id='ar-marker-images' and split_part(name,'/',1)=auth.uid()::text);
create policy "Reviewed marker images read" on storage.objects for select to anon,authenticated
 using(bucket_id='ar-marker-images' and exists(select 1 from public.ar_markers m where m.reference_path=name
   and m.active and m.review_status='approved' and m.tested_version=m.reference_version));
create policy "Marker image owner uploads" on storage.objects for insert to authenticated
 with check(bucket_id='ar-marker-images' and split_part(name,'/',1)=auth.uid()::text
   and name ~ ('^'||auth.uid()::text||'/[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}\.jpg$'));
-- Immutable object names: replacing a reference uploads a new object.
create policy "Marker image owner removes" on storage.objects for delete to authenticated
 using(bucket_id='ar-marker-images' and split_part(name,'/',1)=auth.uid()::text);
notify pgrst,'reload schema';
