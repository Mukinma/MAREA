begin;

-- The shared account check is intentionally internal. Give marker policies a
-- narrowly scoped check without granting callers access to that public RPC.
create function private.ar_marker_owner_can_write(p_owner uuid) returns boolean
language sql security definer set search_path='' as $$
 select case when p_owner=(select auth.uid())
  then p_owner=public.community_active_account()
  else false end;
$$;
revoke all on function private.ar_marker_owner_can_write(uuid) from public,anon,authenticated;
grant execute on function private.ar_marker_owner_can_write(uuid) to authenticated;

alter policy "Marker owner creates" on public.ar_markers
 with check (private.ar_marker_owner_can_write(owner_id));
alter policy "Marker owner edits" on public.ar_markers
 with check (private.ar_marker_owner_can_write(owner_id));

commit;
