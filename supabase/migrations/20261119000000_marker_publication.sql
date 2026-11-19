alter table public.ar_markers
  add column submitted_at timestamptz,
  add column review_reason text check (char_length(review_reason) <= 500);

create index ar_markers_review_queue_idx on public.ar_markers (submitted_at, id)
  where submitted_at is not null and review_status = 'pending';

-- The account guard is deliberately unavailable to direct client calls.
create function private.ar_marker_owner_can_write(p_owner uuid) returns boolean
language sql security definer set search_path = '' as $$
  select p_owner = auth.uid() and p_owner = public.community_active_account();
$$;
revoke all on function private.ar_marker_owner_can_write(uuid) from public, anon, authenticated;
grant execute on function private.ar_marker_owner_can_write(uuid) to authenticated;

drop policy "Marker owner creates" on public.ar_markers;
drop policy "Marker owner edits" on public.ar_markers;
create policy "Marker owner creates" on public.ar_markers for insert to authenticated
  with check (private.ar_marker_owner_can_write(owner_id));
create policy "Marker owner edits" on public.ar_markers for update to authenticated
  using (owner_id = auth.uid()) with check (private.ar_marker_owner_can_write(owner_id));

create or replace function private.ar_marker_reference_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.reference_version := gen_random_uuid();
    new.tested_version := null;
    new.active := false;
    new.review_status := 'pending';
    new.test_platform := null;
    new.tracking_seconds := 0;
    new.submitted_at := null;
    new.review_reason := null;
  else
    if new.id is distinct from old.id or new.owner_id is distinct from old.owner_id then
      raise exception 'marker_owner_immutable';
    end if;
    if new.reference_path is distinct from old.reference_path or new.width_cm is distinct from old.width_cm then
      new.reference_version := gen_random_uuid();
      new.tested_version := null;
      new.test_platform := null;
      new.tracking_seconds := 0;
      new.active := false;
      new.review_status := 'pending';
      new.submitted_at := null;
      new.review_reason := null;
    elsif row(new.name, new.description, new.menu_url, new.latitude, new.longitude, new.location_exact, new.location_accuracy)
        is distinct from row(old.name, old.description, old.menu_url, old.latitude, old.longitude, old.location_exact, old.location_accuracy) then
      new.active := false;
      new.review_status := 'pending';
      new.submitted_at := null;
      new.review_reason := null;
    end if;
  end if;
  if new.reference_path !~ ('^' || new.owner_id::text || '/' || new.id::text || '/[0-9a-fA-F-]{36}\.jpg$')
      or not exists (select 1 from storage.objects where bucket_id = 'ar-marker-images' and name = new.reference_path) then
    raise exception 'marker_reference_required';
  end if;
  new.updated_at := clock_timestamp();
  return new;
end;
$$;

create function private.ar_marker_publishable(marker public.ar_markers) returns boolean
language sql stable set search_path = '' as $$
  select marker.tested_version is not null
    and marker.tested_version = marker.reference_version
    and marker.tracking_seconds >= 3
    and marker.location_exact
    and marker.latitude is not null
    and marker.longitude is not null
    and marker.location_accuracy is not null
    and marker.location_accuracy <= 20
    and exists (
      select 1 from public.profiles
      where id = marker.owner_id and user_type::text in ('Negocio', 'Emprendedor')
    );
$$;
revoke all on function private.ar_marker_publishable(public.ar_markers) from public, anon, authenticated;

create function public.ar_marker_submit(p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := public.community_active_account();
  marker public.ar_markers;
begin
  select * into marker from public.ar_markers where id = p_id and owner_id = actor for update;
  if not found then raise exception 'marker_owner_required'; end if;
  if marker.active or marker.submitted_at is not null then return to_jsonb(marker); end if;
  if not private.ar_marker_publishable(marker) then raise exception 'marker_publication_requirements'; end if;
  if marker.review_status = 'rejected' then raise exception 'marker_changes_required'; end if;
  update public.ar_markers
    set submitted_at = clock_timestamp(), review_status = 'pending', review_reason = null
    where id = p_id returning * into marker;
  return to_jsonb(marker);
end;
$$;

create function public.ar_marker_withdraw(p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := public.community_active_account();
  marker public.ar_markers;
begin
  select * into marker from public.ar_markers where id = p_id and owner_id = actor for update;
  if not found then raise exception 'marker_owner_required'; end if;
  if not marker.active and marker.submitted_at is null then return to_jsonb(marker); end if;
  update public.ar_markers
    set active = false, submitted_at = null, review_status = 'pending', review_reason = null
    where id = p_id returning * into marker;
  return to_jsonb(marker);
end;
$$;

create function public.ar_marker_review_queue(p_offset integer) returns setof public.ar_markers
language plpgsql security definer set search_path = '' as $$
declare actor uuid := public.community_active_account();
begin
  if actor is null or not public.community_is_admin() then raise exception 'marker_reviewer_required'; end if;
  return query select m.* from public.ar_markers m
    where m.submitted_at is not null and m.review_status = 'pending' and m.owner_id <> actor
    order by m.submitted_at, m.id limit 30 offset greatest(0, p_offset);
end;
$$;

create function public.ar_marker_review(p_id uuid, p_updated_at timestamptz, p_approve boolean, p_reason text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := public.community_active_account();
  marker public.ar_markers;
  reason text := nullif(btrim(p_reason), '');
begin
  if actor is null or not public.community_is_admin() then raise exception 'marker_reviewer_required'; end if;
  select * into marker from public.ar_markers where id = p_id for update;
  if not found or marker.owner_id = actor then raise exception 'marker_reviewer_required'; end if;
  if marker.review_status <> 'pending' or marker.submitted_at is null
      or marker.updated_at is distinct from p_updated_at then raise exception 'marker_review_changed'; end if;
  if p_approve is null or (not p_approve and reason is null) or char_length(reason) > 500 then
    raise exception 'marker_review_reason_required';
  end if;
  if p_approve and not private.ar_marker_publishable(marker) then raise exception 'marker_publication_requirements'; end if;
  update public.ar_markers
    set active = p_approve, submitted_at = null,
        review_status = case when p_approve then 'approved' else 'rejected' end,
        review_reason = case when p_approve then null else reason end
    where id = p_id returning * into marker;
  return to_jsonb(marker);
end;
$$;

revoke all on function public.ar_marker_submit(uuid), public.ar_marker_withdraw(uuid),
  public.ar_marker_review_queue(integer), public.ar_marker_review(uuid, timestamptz, boolean, text)
  from public, anon, authenticated;
grant execute on function public.ar_marker_submit(uuid), public.ar_marker_withdraw(uuid),
  public.ar_marker_review_queue(integer), public.ar_marker_review(uuid, timestamptz, boolean, text)
  to authenticated;

create policy "Marker reviewer reads submissions" on public.ar_markers for select to authenticated
  using (submitted_at is not null and review_status = 'pending' and public.community_is_admin());

drop policy "Reviewed marker images read" on storage.objects;
create policy "Reviewed marker images read" on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'ar-marker-images' and exists (select 1 from public.ar_markers m
      where m.reference_path = storage.objects.name
        and m.active and m.review_status = 'approved' and m.tested_version = m.reference_version)
  );

create policy "Marker reviewer reads submitted images" on storage.objects for select to authenticated
  using (
    bucket_id = 'ar-marker-images' and public.community_is_admin()
    and exists (select 1 from public.ar_markers m
      where m.reference_path = storage.objects.name and m.submitted_at is not null and m.review_status = 'pending')
  );

drop policy "Marker image owner removes" on storage.objects;
create policy "Marker image owner removes" on storage.objects for delete to authenticated
  using (
    bucket_id = 'ar-marker-images' and split_part(name, '/', 1) = auth.uid()::text
    and not exists (select 1 from public.ar_markers m where m.reference_path = storage.objects.name)
  );

drop policy "Marker image owner uploads" on storage.objects;
create policy "Marker image owner uploads" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'ar-marker-images'
    and name ~ ('^' || auth.uid()::text || '/[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}\.jpg$')
    and private.ar_marker_owner_can_write(auth.uid())
  );

notify pgrst, 'reload schema';
