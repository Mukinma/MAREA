-- Additive map discovery contract. Existing mission CRUD/listing stays unchanged.
create index missions_map_coordinates_idx
  on public.missions(location_latitude, location_longitude, starts_at)
  where status='open' and not hidden
    and location_latitude is not null and location_longitude is not null;

create function public.list_map_missions(
  south double precision, west double precision,
  north double precision, east double precision,
  query_text text default '', category_filter text default null,
  starts_from timestamptz default null, starts_before timestamptz default null,
  center_latitude double precision default null,
  center_longitude double precision default null,
  radius_km double precision default null
) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare
  account uuid := public.community_active_account();
  pattern text;
  result jsonb;
begin
  if not coalesce(south between -90 and 90 and north between -90 and 90
      and south < north and west between -180 and 180 and east between -180 and 180
      and west <> east, false) then raise exception 'invalid_map_bounds'; end if;
  if category_filter is not null and category_filter not in
    ('arte','musica','digital','gastronomia','moda','escritura','fotografia','diseno','otros')
    then raise exception 'invalid_map_category'; end if;
  if starts_from is not null and starts_before is not null and starts_from>=starts_before
    then raise exception 'invalid_map_dates'; end if;
  if radius_km is not null and not coalesce(radius_km>0 and radius_km<=100
      and center_latitude between -90 and 90 and center_longitude between -180 and 180,false)
    then raise exception 'invalid_map_radius'; end if;
  pattern := '%' || replace(replace(replace(left(btrim(coalesce(query_text,'')),100),
    E'\\', E'\\\\'), '%', E'\\%'), '_', E'\\_') || '%';

  with candidates as (
    select m.*, p.full_name as organizer_name, p.username as organizer_username,
      (select count(*)::int from public.mission_applications a
        where a.mission_id=m.id and a.status='accepted') as accepted_count
    from public.missions m join public.profiles p on p.id=m.author_id
    where m.status='open' and not m.hidden and m.starts_at>now()
      and m.location_latitude between south and north
      and ((west<east and m.location_longitude between west and east)
        or (west>east and (m.location_longitude>=west or m.location_longitude<=east)))
      and not exists(select 1 from public.account_deletion_requests d where d.user_id=m.author_id)
      and (category_filter is null or m.category=category_filter)
      and (starts_from is null or m.starts_at>=starts_from)
      and (starts_before is null or m.starts_at<starts_before)
      and (m.title ilike pattern or m.location ilike pattern
        or p.full_name ilike pattern or p.username ilike pattern
        or (case m.category when 'musica' then 'Música' when 'gastronomia' then 'Gastronomía'
          when 'fotografia' then 'Fotografía' when 'diseno' then 'Diseño' else m.category end) ilike pattern)
      and (radius_km is null or 6371.0088 * 2 * asin(sqrt(least(1.0,
        power(sin(radians(m.location_latitude-center_latitude)/2),2)
        + cos(radians(center_latitude))*cos(radians(m.location_latitude))
        * power(sin(radians(m.location_longitude-center_longitude)/2),2)))) <= radius_km)
  ), matched as (
    select * from candidates where accepted_count<capacity
  ), limited as (
    select * from matched order by starts_at,id limit 300
  )
  select jsonb_build_object(
    'total',(select count(*) from matched),
    'missions',coalesce((select jsonb_agg(to_jsonb(l) order by l.starts_at,l.id) from limited l),'[]'::jsonb)
  ) into result;
  return result;
end;
$$;

revoke all on function public.list_map_missions(double precision,double precision,
  double precision,double precision,text,text,timestamptz,timestamptz,
  double precision,double precision,double precision) from public,anon,authenticated;
grant execute on function public.list_map_missions(double precision,double precision,
  double precision,double precision,text,text,timestamptz,timestamptz,
  double precision,double precision,double precision) to authenticated;
