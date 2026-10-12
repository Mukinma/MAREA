-- City is structured metadata of the content point; retain its full address.
create function public.valid_content_city(value jsonb) returns boolean
language sql immutable set search_path='' as $$
 select value is null or coalesce((jsonb_typeof(value)='object' and jsonb_typeof(value->'name')='string'
 and length(btrim(value->>'name')) between 1 and 120
 and pg_column_size(value)<2048),false);
$$;
alter table public.posts add column location_city jsonb, add column location_city_resolved_at timestamptz,
 add constraint posts_content_city_valid check(public.valid_content_city(location_city));
alter table public.missions add column location_city jsonb, add column location_city_resolved_at timestamptz,
 add constraint missions_content_city_valid check(public.valid_content_city(location_city));
grant insert(location_city),update(location_city) on public.posts to authenticated;

-- Matching provenance distinguishes newly resolved same-city metadata from a
-- stale city carried along with an edited point. Settlement identity can match.
create function public.content_city_matches_point(value jsonb,latitude double precision,longitude double precision) returns boolean
language sql immutable set search_path='' as $$
 select coalesce(case
  when jsonb_typeof(value->'point'->'latitude')='number' and jsonb_typeof(value->'point'->'longitude')='number'
  then latitude is not null and longitude is not null
   and (value->'point'->>'latitude')::double precision=latitude
   and (value->'point'->>'longitude')::double precision=longitude
  else false end,false);
$$;
create function public.invalidate_content_city() returns trigger language plpgsql set search_path='' as $$
begin
 if row(new.location_latitude,new.location_longitude) is distinct from row(old.location_latitude,old.location_longitude) then
  if not public.content_city_matches_point(new.location_city,new.location_latitude,new.location_longitude) then new.location_city=null; end if;
  new.location_city_resolved_at=null;
 end if;
 return new;
end; $$;
create trigger posts_city_point_changed before update on public.posts for each row execute function public.invalidate_content_city();
create trigger missions_city_point_changed before update on public.missions for each row execute function public.invalidate_content_city();

-- Keep all existing ownership, conditions locks, validation and draft behavior.
alter function public.create_mission(jsonb) rename to create_mission_before_city;
alter function public.update_mission(uuid,jsonb) rename to update_mission_before_city;
alter function public.save_mission_draft(uuid,jsonb) rename to save_mission_draft_before_city;
revoke all on function public.create_mission_before_city(jsonb),public.update_mission_before_city(uuid,jsonb),public.save_mission_draft_before_city(uuid,jsonb) from public,anon,authenticated;
create function public.create_mission(mission_input jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare result uuid; begin
 result=public.create_mission_before_city(mission_input-'location_city');
 update public.missions set location_city=nullif(mission_input->'location_city','null'::jsonb) where id=result;
 return result;
end; $$;
create function public.update_mission(mission_id uuid,mission_input jsonb) returns void language plpgsql security definer set search_path='' as $$
begin
 perform public.update_mission_before_city(mission_id,mission_input-'location_city');
 if mission_input ? 'location_city' then
  update public.missions set location_city=nullif(mission_input->'location_city','null'::jsonb) where id=mission_id;
 end if;
end; $$;
create function public.save_mission_draft(draft_id uuid,draft_input jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare result uuid; begin
 if not public.valid_content_city(nullif(draft_input->'location_city','null'::jsonb)) then raise exception 'invalid_mission_draft'; end if;
 result=public.save_mission_draft_before_city(draft_id,draft_input-'location_city');
 if draft_input ? 'location_city' then update public.mission_drafts set data=data || jsonb_build_object('location_city',draft_input->'location_city') where id=result; end if;
 return result;
end; $$;
revoke all on function public.create_mission(jsonb),public.update_mission(uuid,jsonb),public.save_mission_draft(uuid,jsonb) from public,anon;
grant execute on function public.create_mission(jsonb),public.update_mission(uuid,jsonb),public.save_mission_draft(uuid,jsonb) to authenticated;

-- These tables and functions are server-only. All clients use the Edge handler.
create table public.geocoding_provider (
 id boolean primary key default true check(id), base_url text not null,
 user_agent text not null, enabled boolean not null default true,
 lease_id uuid, lease_until timestamptz, next_allowed_at timestamptz not null default '-infinity'
);
insert into public.geocoding_provider(id,base_url,user_agent) values(true,'https://nominatim.openstreetmap.org','MAREA/1.0 (https://marea-azul.netlify.app/; community location picker)');
create table public.geocoding_cache(cache_key text primary key,payload jsonb not null,created_at timestamptz not null default now());
alter table public.geocoding_provider enable row level security;
alter table public.geocoding_cache enable row level security;
revoke all on public.geocoding_provider,public.geocoding_cache from public,anon,authenticated;
grant all on public.geocoding_provider,public.geocoding_cache to service_role;
create function public.claim_geocoding_request(request_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare claimed boolean; begin
 update public.geocoding_provider set lease_id=request_id,lease_until=clock_timestamp()+interval '30 seconds'
 where id=true and enabled and next_allowed_at<=clock_timestamp() and (lease_until is null or lease_until<clock_timestamp());
 get diagnostics claimed = row_count;
 return claimed;
end; $$;
create function public.finish_geocoding_request(request_id uuid) returns void language sql security definer set search_path='' as $$
 update public.geocoding_provider set lease_id=null,lease_until=null,next_allowed_at=clock_timestamp()+interval '1 second' where id=true and lease_id=request_id;
$$;
revoke all on function public.claim_geocoding_request(uuid),public.finish_geocoding_request(uuid) from public,anon,authenticated;
grant execute on function public.claim_geocoding_request(uuid),public.finish_geocoding_request(uuid) to service_role;
