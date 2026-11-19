-- Owner publication replaces administrative review. Apply after 015 and 042.
-- Media validation, frozen revisions and consent for other authors stay intact.
begin;
create function public.tours_publish(p_tour uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 account uuid:=public.community_active_account();
 t public.tours;
 s jsonb;
 pt jsonb;
 space_id uuid;
 space_owner uuid;
begin
 select * into t from public.tours where id=p_tour and owner_id=account for update;
 if not found then raise exception 'tour_owner_required'; end if;
 -- A retried response never creates another public revision or unpauses a tour.
 if t.state='published' and t.public_revision_id=t.revision_id then
  return private.tour_json(p_tour,true);
 end if;
 if t.state not in ('draft','submitted','rejected') then raise exception 'editable_tour_required'; end if;
 t.document:=private.tour_document(t.id,account,t.document);
 if t.document->>'start_scene_id' is null or length(btrim(coalesce(t.space->>'name','')))<3 then
  raise exception 'tour_incomplete';
 end if;
 if t.document->>'ends_at' is not null and (t.document->>'ends_at')::timestamptz<=clock_timestamp() then
  raise exception 'tour_expired';
 end if;
 for s in select sc.value from jsonb_array_elements(t.document->'zones') z
  cross join lateral jsonb_array_elements(z.value->'scenes') sc loop
  if s->>'job_id' is null then raise exception 'panorama_required'; end if;
  if exists(select 1 from jsonb_array_elements(s->'connections') c
   where coalesce((c.value->>'needs_review')::boolean,false)) then raise exception 'panorama_review_required'; end if;
  for pt in select value from jsonb_array_elements(s->'points') loop
   if coalesce((pt->>'needs_review')::boolean,false) then raise exception 'panorama_review_required'; end if;
   if pt->'link'<>'null' and pt#>>'{link,status}' is distinct from 'approved'
    and length(btrim(coalesce(pt->>'description','')))<3 then
    raise exception 'independent_point_description_required';
   end if;
  end loop;
 end loop;

 space_id:=nullif(t.space->>'id','')::uuid;
 space_owner:=account;
 if space_id is not null then
  select author_id into space_owner from public.posts where id=space_id and kind='space' and not hidden;
  if not found or exists(select 1 from public.account_deletion_requests where user_id=space_owner) then
   raise exception 'space_unavailable';
  end if;
  -- Self-publishing does not authorize claiming another person's space.
  if space_owner<>account and not private.tour_space_verified(t.id,account,t.space)
   and not exists(select 1 from public.tour_requests req
    join public.tour_revisions rev on rev.id=req.revision_id and rev.tour_id=t.id
    where req.tour_id=t.id and req.kind='space' and req.status='approved'
     and req.requester_id=account and req.reviewer_id=space_owner
     and req.payload-'verified'=t.space-'verified'
     and rev.space-'verified'=t.space-'verified'
     and req.reviewed_at is not null
     and not exists(select 1 from public.tour_requests withdrawn
      where withdrawn.tour_id=t.id and withdrawn.kind='space'
       and withdrawn.status='revoked' and withdrawn.reviewed_at>=req.reviewed_at)) then
   raise exception 'space_permission_required';
  end if;
 end if;

 -- A legacy submission already owns an immutable snapshot; preserve it.
 if exists(select 1 from public.tour_revisions where id=t.revision_id) then
  t.revision_id:=gen_random_uuid();
 end if;
 insert into public.tour_revisions(id,tour_id,owner_id,title,space,document)
 values(t.revision_id,t.id,account,t.title,t.space,private.tour_public_document(t.document));
 insert into private.tour_permissions(tour_id,kind,target_id,owner_id,scope)
 values(t.id,'space',coalesce(space_id,t.id),space_owner,t.space-'verified')
 on conflict(tour_id,kind,target_id) do update set owner_id=excluded.owner_id,scope=excluded.scope;
 update public.tours set state='published',document=t.document,revision_id=t.revision_id,
  public_revision_id=t.revision_id,updated_at=clock_timestamp() where id=t.id;
 update public.tour_requests set status='superseded',reviewed_at=clock_timestamp()
 where tour_id=t.id and kind in ('space','publication') and status='pending';
 return private.tour_json(t.id,true);
end$$;
revoke all on function public.tours_publish(uuid) from public,anon;
grant execute on function public.tours_publish(uuid) to authenticated;

-- Old clients also publish directly, rather than creating new review requests.
create or replace function public.tours_submit(p_tour uuid) returns jsonb
language sql security definer set search_path='' as $$
 select public.tours_publish(p_tour);
$$;
revoke all on function public.tours_submit(uuid) from public,anon;
grant execute on function public.tours_submit(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
