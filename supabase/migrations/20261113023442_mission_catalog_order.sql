-- Read-only alternative to the recent catalog. The existing RPCs keep their
-- contracts and privileges.
create function public.list_mission_catalog_by_start(
  query_text text default '',
  category_filter text default null,
  target_filter text default null,
  page_offset integer default 0
) returns setof jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  account uuid := auth.uid();
  admin boolean;
  pattern text := '%' || left(coalesce(query_text, ''), 100) || '%';
begin
  if account is null then
    raise exception 'authentication_required';
  end if;
  admin := public.community_is_admin();

  return query
  select to_jsonb(m) || jsonb_build_object(
    'accepted_count', slots.accepted_count,
    'pending_count', case when m.author_id = account or admin then
      (select count(*) from public.mission_applications a
       where a.mission_id = m.id and a.status = 'pending')
    else null end,
    'organizer_name', p.full_name,
    'organizer_username', p.username
  )
  from public.missions m
  join public.profiles p on p.id = m.author_id
  cross join lateral (
    select count(*) as accepted_count
    from public.mission_applications a
    where a.mission_id = m.id and a.status = 'accepted'
  ) slots
  where m.status = 'open' and not m.hidden and m.starts_at > now()
    and slots.accepted_count < m.capacity
    and not exists (
      select 1 from public.account_deletion_requests d where d.user_id = m.author_id
    )
    and (coalesce(query_text, '') = '' or m.title ilike pattern
         or m.body ilike pattern or m.location ilike pattern)
    and (category_filter is null or m.category = category_filter)
    and (target_filter is null or m.target_type is null or m.target_type = target_filter)
  order by m.starts_at asc, m.id asc
  limit 30 offset greatest(coalesce(page_offset, 0), 0);
end;
$$;

revoke all on function public.list_mission_catalog_by_start(text, text, text, integer)
  from public, anon, authenticated, service_role;
grant execute on function public.list_mission_catalog_by_start(text, text, text, integer)
  to authenticated;
