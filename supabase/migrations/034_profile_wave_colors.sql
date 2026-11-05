-- Two opaque ARGB colors, matching Flutter's Color.toARGB32().
-- No existing profile fields, timestamps, policies, or media are updated.
begin;

alter table public.profiles
  add column wave_colors bigint[] not null
    default array[4280923848, 4289325541]::bigint[],
  add constraint profile_wave_colors_valid check (
    cardinality(wave_colors) = 2
    and array_ndims(wave_colors) = 1
    and array_lower(wave_colors, 1) = 1
    and array_position(wave_colors, null) is null
    and wave_colors[1] between 4278190080 and 4294967295
    and wave_colors[2] between 4278190080 and 4294967295
  );

-- Existing owner-only UPDATE RLS still governs this column.
grant update(wave_colors) on public.profiles to authenticated;

-- PostgreSQL requires recreation to extend a RETURNS TABLE signature.
-- RESTRICT is intentional: abort rather than cascade to any dependencies.
drop function public.community_profiles(uuid[], text) restrict;
create function public.community_profiles(
  profile_ids uuid[] default null,
  query_text text default ''
)
returns table(
  id uuid, full_name text, username text, bio text, user_type text,
  website text, avatar_path text, cover_path text, cover_preset text,
  contact_url text, open_to_collaboration boolean, location text,
  location_latitude double precision, location_longitude double precision,
  location_precision text, business_hours jsonb, wave_colors bigint[]
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  return query
    select p.id, p.full_name, p.username, p.bio, p.user_type,
      p.website, p.avatar_path, p.cover_path, p.cover_preset,
      p.contact_url, p.open_to_collaboration, p.location,
      p.location_latitude, p.location_longitude, p.location_precision,
      p.business_hours, p.wave_colors
    from public.profiles p
    where (profile_ids is null or p.id = any(profile_ids))
      and (coalesce(query_text, '') = ''
        or p.full_name ilike '%' || left(query_text, 100) || '%'
        or p.username ilike '%' || left(query_text, 100) || '%')
      and not exists (
        select 1 from public.account_deletion_requests d where d.user_id = p.id
      )
    order by p.username limit 100;
end;
$$;
revoke all on function public.community_profiles(uuid[], text) from public, anon;
grant execute on function public.community_profiles(uuid[], text) to authenticated;

notify pgrst, 'reload schema';
commit;
