-- Private 360 captures, frozen editorial revisions and a globally bounded queue.
create schema if not exists private;
revoke all on schema private from public,anon,authenticated;
create table public.tours(
 id uuid primary key default gen_random_uuid(),owner_id uuid not null references public.profiles(id) on delete cascade,
 title text not null check(length(btrim(title)) between 3 and 120),state text not null default 'draft' check(state in ('draft','submitted','published','rejected')),
 revision_id uuid not null default gen_random_uuid(),public_revision_id uuid,space jsonb not null default '{}',
 document jsonb not null default '{"zones":[],"ar_order":[]}',paused boolean not null default false,updated_at timestamptz not null default clock_timestamp()
);
create table public.tour_revisions(
 id uuid primary key,tour_id uuid not null references public.tours(id) on delete cascade,owner_id uuid not null references public.profiles(id) on delete cascade,
 title text not null,space jsonb not null,document jsonb not null,created_at timestamptz not null default clock_timestamp()
);
create table private.tour_captures(
 id uuid primary key default gen_random_uuid(),tour_id uuid not null references public.tours(id) on delete cascade,owner_id uuid not null references public.profiles(id) on delete cascade,
 scene_id uuid not null,mode text not null check(mode in ('photos','import')),manifest jsonb,created_at timestamptz not null default clock_timestamp()
);
create table private.tour_jobs(
 id uuid primary key default gen_random_uuid(),capture_id uuid not null unique references private.tour_captures(id) on delete cascade,
 owner_id uuid not null references public.profiles(id) on delete cascade,state text not null default 'queued' check(state in ('queued','processing','succeeded','failed','cancelled')),
 attempts integer not null default 0 check(attempts between 0 and 3),lease_id uuid,lease_until timestamptz,completed_lease_id uuid,
 scheduled_at timestamptz not null default clock_timestamp(),cleanup_needed boolean not null default false,result jsonb,error_code text,message text,created_at timestamptz not null default clock_timestamp()
);
create index tour_queue_idx on private.tour_jobs(scheduled_at) where state in ('queued','processing');
-- Writes get an owner lock shared with account deletion. A deletion waits for the
-- in-flight network operation (max 60 seconds), then recursively removes its files.
create table private.tour_output_writes(
 job_id uuid primary key references private.tour_jobs(id) on delete cascade,owner_id uuid not null references public.profiles(id) on delete cascade,
 lease_id uuid not null,expires_at timestamptz not null default(clock_timestamp()+interval '60 seconds')
);
create table public.tour_requests(
 id uuid primary key default gen_random_uuid(),tour_id uuid not null references public.tours(id) on delete cascade,revision_id uuid not null,
 requester_id uuid not null references public.profiles(id) on delete cascade,reviewer_id uuid references public.profiles(id) on delete cascade,
 kind text not null check(kind in ('space','publication','link')),payload jsonb not null default '{}',
 status text not null default 'pending' check(status in ('pending','approved','rejected','superseded','revoked')),reason text,
 created_at timestamptz not null default clock_timestamp(),reviewed_at timestamptz
);
create table private.tour_permissions(
 tour_id uuid not null references public.tours(id) on delete cascade,kind text not null,target_id uuid not null,owner_id uuid not null references public.profiles(id) on delete cascade,scope jsonb,
 primary key(tour_id,kind,target_id)
);
create table private.tour_ar_tests(
 tour_id uuid not null references public.tours(id) on delete cascade,point_id uuid not null,reference_version uuid not null,reference_path text not null,width_cm numeric not null,
 platform text not null,tracking_seconds integer not null,reported_at timestamptz not null default clock_timestamp(),primary key(tour_id,point_id)
);
create table public.tour_progress(
 tour_id uuid not null references public.tours(id) on delete cascade,revision_id uuid not null references public.tour_revisions(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,progress jsonb not null,updated_at timestamptz not null default clock_timestamp(),primary key(revision_id,user_id)
);
do $$declare tab text;begin
 foreach tab in array array['public.tours','public.tour_revisions','public.tour_requests','public.tour_progress','private.tour_captures','private.tour_jobs','private.tour_output_writes','private.tour_permissions','private.tour_ar_tests'] loop
 execute 'alter table '||tab||' enable row level security';
 execute 'revoke all on '||tab||' from public,anon,authenticated';
 execute 'grant all on '||tab||' to service_role';
 end loop;
end$$;

create function private.tour_visible(p_tour uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.tours t join public.tour_revisions r on r.id=t.public_revision_id
 where t.id=p_tour and not t.paused and exists(select 1 from private.tour_permissions perm where perm.tour_id=t.id and perm.kind='space' and perm.target_id=coalesce(nullif(r.space->>'id','')::uuid,t.id) and perm.scope=r.space-'verified' and not exists(select 1 from public.account_deletion_requests a where a.user_id=perm.owner_id)) and not exists(select 1 from public.account_deletion_requests a where a.user_id=t.owner_id)
 and (nullif(r.document->>'starts_at','') is null or (r.document->>'starts_at')::timestamptz<=now())
 and (nullif(r.document->>'ends_at','') is null or (r.document->>'ends_at')::timestamptz>now()));
$$;
create function private.tour_live_document(p_tour uuid,p_owner uuid,p_doc jsonb) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare z jsonb;s jsonb;p jsonb;ln jsonb;zones jsonb:='[]';scenes jsonb;points jsonb;begin
 for z in select value from jsonb_array_elements(p_doc->'zones') loop scenes:='[]';
 for s in select value from jsonb_array_elements(z->'scenes') loop points:='[]';
 for p in select value from jsonb_array_elements(s->'points') loop
 if p->'link' is not null and p->'link'<>'null' then
   begin ln:=private.tour_link(p#>>'{link,kind}',(p#>>'{link,id}')::uuid,p_tour,p_owner);
   exception when raise_exception then if SQLERRM<>'link_unavailable' then raise;end if;ln:=null;end;
   if ln->>'status' is distinct from 'approved' then ln:=null;end if;
   p:=p||jsonb_build_object('link',ln);
   -- A purely linked stop disappears when the linked content is unavailable.
   if ln is null and length(btrim(coalesce(p->>'description','')))=0 and (p->'ar' is null or p->'ar'='null') then continue;end if;
 end if;
 points:=points||jsonb_build_array(p);end loop;
 scenes:=scenes||jsonb_build_array(s||jsonb_build_object('points',points));end loop;
 zones:=zones||jsonb_build_array(z||jsonb_build_object('scenes',scenes));end loop;
 return p_doc||jsonb_build_object('zones',zones);
end$$;
create function private.tour_json(p_tour uuid,p_edit boolean default false) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('id',t.id,'owner_id',t.owner_id,'title',case when p_edit then t.title else r.title end,
 'state',case when p_edit then t.state else 'published' end,'revision_id',case when p_edit then t.revision_id else r.id end,
 'public_revision_id',t.public_revision_id,'space',case when p_edit then t.space else (r.space-'context'-'evidence_paths')||jsonb_build_object('verified',coalesce((r.space->>'verified')::boolean,false) or exists(select 1 from public.tour_requests req where req.tour_id=t.id and req.revision_id=r.id and req.kind='space' and req.status='approved')) end,
 'document',case when p_edit then t.document else private.tour_live_document(t.id,t.owner_id,r.document) end,'paused',t.paused)
 from public.tours t left join public.tour_revisions r on r.id=t.public_revision_id where t.id=p_tour;
$$;
create function public.tours_get(p_tour uuid,p_edit boolean default false) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 perform public.community_active_account();
 if p_edit and exists(select 1 from public.tours where id=p_tour and owner_id=auth.uid()) then return private.tour_json(p_tour,true);end if;
 if not p_edit and private.tour_visible(p_tour) then return private.tour_json(p_tour,false);end if;
 return null;
end$$;
create function public.tours_list(p_owner uuid default null,p_lat double precision default null,p_lng double precision default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;begin
 perform public.community_active_account();
 if (p_lat is null)<>(p_lng is null) or p_lat not between -90 and 90 or p_lng not between -180 and 180 then raise exception 'invalid_coordinates';end if;
 select coalesce(jsonb_agg(data order by distance,updated_at desc),'[]') into result from (
 select private.tour_json(t.id,p_owner=auth.uid()) data,t.updated_at,
 case when p_lat is null then 0 else power((r.space->>'latitude')::float8-p_lat,2)+power(((r.space->>'longitude')::float8-p_lng)*cos(radians(p_lat)),2) end distance
 from public.tours t left join public.tour_revisions r on r.id=t.public_revision_id
 where ((p_owner=auth.uid() and t.owner_id=auth.uid()) or (private.tour_visible(t.id) and (p_owner is null or t.owner_id=p_owner))) limit 200) x;
 return result;
end$$;

create function private.tour_link(p_kind text,p_id uuid,p_tour uuid,p_owner uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare target_owner uuid;target_title text;begin
 if p_kind='showcase' then select owner_id,title into target_owner,target_title from public.showcase_items where id=p_id and status='published' and available and not hidden;
 elsif p_kind='post' then select author_id,title into target_owner,target_title from public.posts where id=p_id and not hidden;
 elsif p_kind='mission' then select author_id,title into target_owner,target_title from public.missions where id=p_id and not hidden;
 else raise exception 'invalid_link_kind';end if;
 if target_owner is null or exists(select 1 from public.account_deletion_requests where user_id=target_owner) then raise exception 'link_unavailable';end if;
 return jsonb_build_object('kind',p_kind,'id',p_id,'owner_id',target_owner,'title',target_title,'status',case when target_owner=p_owner or exists(select 1 from private.tour_permissions where tour_id=p_tour and kind=p_kind and target_id=p_id and owner_id=target_owner) then 'approved' else 'pending' end);
end$$;
create function public.tours_link_search(p_query text) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;begin
 perform public.community_active_account();
 if length(coalesce(p_query,''))>120 then raise exception 'invalid_query';end if;
 select coalesce(jsonb_agg(jsonb_build_object('kind',kind,'id',id,'owner_id',owner_id,'title',title,'status',case when owner_id=auth.uid() then 'approved' else 'pending' end)),'[]') into result from (
 select * from (select 'post' kind,id,author_id owner_id,title from public.posts where not hidden union all
 select 'mission',id,author_id,title from public.missions where not hidden union all
 select 'showcase',id,owner_id,title from public.showcase_items where status='published' and available and not hidden) all_links
 where title ilike '%'||coalesce(p_query,'')||'%' and not exists(select 1 from public.account_deletion_requests where user_id=owner_id) limit 40) x;
 return result;
end$$;

-- Canonicalize all editorial fields. No client status/job URL/test result is trusted.
create function private.tour_document(p_tour uuid,p_owner uuid,p_doc jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare z jsonb;s jsonb;pt jsonb;c jsonb;ar jsonb;ln jsonb;job private.tour_jobs;test private.tour_ar_tests;
 zones jsonb:='[]';scenes jsonb;points jsonb;connections jsonb;scene_ids uuid[]:='{}';point_ids uuid[]:='{}';all_ids uuid[]:='{}';ident uuid;target uuid;path text;start_id uuid;
begin
 if p_doc is null or jsonb_typeof(p_doc)<>'object' or jsonb_typeof(p_doc->'zones') is distinct from 'array' or jsonb_array_length(p_doc->'zones')>40 then raise exception 'invalid_document';end if;
 for z in select value from jsonb_array_elements(p_doc->'zones') loop
 ident:=(z->>'id')::uuid;if ident is null or ident=any(all_ids) then raise exception 'duplicate_or_invalid_id';end if;all_ids:=array_append(all_ids,ident);
 if length(coalesce(z->>'name',''))>120 or length(coalesce(z->>'description',''))>3000 or jsonb_typeof(z->'scenes') is distinct from 'array' then raise exception 'invalid_zone';end if;
 for s in select value from jsonb_array_elements(z->'scenes') loop
 ident:=(s->>'id')::uuid;if ident is null or ident=any(all_ids) then raise exception 'duplicate_or_invalid_id';end if;all_ids:=array_append(all_ids,ident);scene_ids:=array_append(scene_ids,ident);
 end loop;end loop;
 if cardinality(scene_ids)>80 then raise exception 'too_many_scenes';end if;
 for z in select value from jsonb_array_elements(p_doc->'zones') loop
 scenes:='[]';for s in select value from jsonb_array_elements(z->'scenes') loop
 if length(coalesce(s->>'name',''))>120 or coalesce((s->>'initial_yaw')::numeric,0) not between -180 and 179.999999 then raise exception 'invalid_scene';end if;
 job:=null;
 if nullif(s->>'job_id','') is not null then
 select j.* into job from private.tour_jobs j join private.tour_captures cap on cap.id=j.capture_id where j.id=(s->>'job_id')::uuid and j.owner_id=p_owner and cap.tour_id=p_tour and cap.scene_id=(s->>'id')::uuid and j.state='succeeded';
 if not found then raise exception 'invalid_scene_job';end if;
 foreach path in array array['panorama_path','preview_path','thumbnail_path'] loop
 if s->>path is distinct from job.result->>path or not exists(select 1 from storage.objects where bucket_id='tour-assets' and name=job.result->>path) then raise exception 'invalid_scene_media';end if;
 end loop;
 elsif nullif(s->>'panorama_path','') is not null or nullif(s->>'preview_path','') is not null or nullif(s->>'thumbnail_path','') is not null then raise exception 'job_required_for_media';end if;
 connections:='[]';for c in select value from jsonb_array_elements(coalesce(s->'connections','[]')) loop
 ident:=(c->>'id')::uuid;target:=(c->>'target_scene_id')::uuid;
 if ident is null or ident=any(all_ids) or target is null or not target=any(scene_ids) or target=(s->>'id')::uuid or (coalesce((c->>'needs_review')::boolean,false)=false and (coalesce((c->>'yaw')::numeric,999) not between -180 and 179.999999 or coalesce((c->>'pitch')::numeric,999) not between -90 and 90)) or length(coalesce(c->>'label',''))>120 or length(coalesce(c->>'instruction',''))>1000 then raise exception 'invalid_connection';end if;
 all_ids:=array_append(all_ids,ident);connections:=connections||jsonb_build_array(jsonb_build_object('id',ident,'target_scene_id',target,'needs_review',coalesce((c->>'needs_review')::boolean,false),'yaw',case when coalesce((c->>'needs_review')::boolean,false) then null else (c->>'yaw')::numeric end,'pitch',case when coalesce((c->>'needs_review')::boolean,false) then null else (c->>'pitch')::numeric end,'label',coalesce(c->>'label',''),'instruction',coalesce(c->>'instruction','')));
 end loop;
 points:='[]';for pt in select value from jsonb_array_elements(coalesce(s->'points','[]')) loop
 ident:=(pt->>'id')::uuid;
 if ident is null or ident=any(all_ids) or (coalesce((pt->>'needs_review')::boolean,false)=false and (((pt->>'yaw') is null)<>((pt->>'pitch') is null) or (pt->>'yaw')::numeric not between -180 and 179.999999 or (pt->>'pitch')::numeric not between -90 and 90)) or length(coalesce(pt->>'name',''))>120 or length(coalesce(pt->>'description',''))>3000 then raise exception 'invalid_point';end if;
 all_ids:=array_append(all_ids,ident);point_ids:=array_append(point_ids,ident);ln:=null;ar:=null;
 if pt->'link' is not null and pt->'link'<>'null' then ln:=private.tour_link(pt#>>'{link,kind}',(pt#>>'{link,id}')::uuid,p_tour,p_owner);end if;
 if pt->'ar' is not null and pt->'ar'<>'null' then
 ar:=pt->'ar';path:=ar->>'reference_path';
 if path is null or path!~('^'||p_owner::text||'/references/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$') or not exists(select 1 from storage.objects where bucket_id='tour-assets' and name=path) or coalesce((ar->>'width_cm')::numeric,0) not between 1 and 1000 or (ar->>'reference_version')::uuid is null then raise exception 'invalid_ar_reference';end if;
 select * into test from private.tour_ar_tests where tour_id=p_tour and point_id=ident and reference_version=(ar->>'reference_version')::uuid and reference_path=path and width_cm=(ar->>'width_cm')::numeric;
 ar:=jsonb_build_object('reference_path',path,'width_cm',(ar->>'width_cm')::numeric,'reference_version',(ar->>'reference_version')::uuid,'tested_version',test.reference_version,'test_kind',case when test.reference_version is not null then 'user_reported_tracking' end);
 end if;
 points:=points||jsonb_build_array(jsonb_build_object('id',ident,'name',coalesce(pt->>'name',''),'description',coalesce(pt->>'description',''),'needs_review',coalesce((pt->>'needs_review')::boolean,false),'yaw',case when coalesce((pt->>'needs_review')::boolean,false) then null else (pt->>'yaw')::numeric end,'pitch',case when coalesce((pt->>'needs_review')::boolean,false) then null else (pt->>'pitch')::numeric end,'link',ln,'ar',ar));end loop;
 scenes:=scenes||jsonb_build_array(jsonb_build_object('id',(s->>'id')::uuid,'name',coalesce(s->>'name',''),'job_id',job.id,'panorama_path',job.result->>'panorama_path','preview_path',job.result->>'preview_path','thumbnail_path',job.result->>'thumbnail_path','initial_yaw',coalesce((s->>'initial_yaw')::numeric,0),'connections',connections,'points',points));end loop;
 zones:=zones||jsonb_build_array(jsonb_build_object('id',(z->>'id')::uuid,'name',coalesce(z->>'name',''),'description',coalesce(z->>'description',''),'scenes',scenes));end loop;
 start_id:=nullif(p_doc->>'start_scene_id','')::uuid;
 if start_id is not null and not start_id=any(scene_ids) then raise exception 'invalid_start_scene';end if;
 if jsonb_typeof(coalesce(p_doc->'ar_order','[]'))<>'array' then raise exception 'invalid_ar_order';end if;
 for c in select value from jsonb_array_elements(coalesce(p_doc->'ar_order','[]')) loop
 if not (c#>>'{}')::uuid=any(point_ids) then raise exception 'invalid_ar_order';end if;end loop;
 if (select count(*)<>count(distinct value) from jsonb_array_elements(coalesce(p_doc->'ar_order','[]'))) then raise exception 'duplicate_ar_order';end if;
 if nullif(p_doc->>'starts_at','')::timestamptz>=nullif(p_doc->>'ends_at','')::timestamptz then raise exception 'invalid_validity';end if;
 return jsonb_build_object('start_scene_id',coalesce(start_id,scene_ids[1]),'zones',zones,'ar_order',coalesce(p_doc->'ar_order','[]'),'starts_at',nullif(p_doc->>'starts_at','')::timestamptz,'ends_at',nullif(p_doc->>'ends_at','')::timestamptz);
end$$;
create function private.tour_space_verified(p_tour uuid,p_owner uuid,p_space jsonb) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from private.tour_permissions perm where perm.tour_id=p_tour and perm.kind='space' and perm.target_id=coalesce(nullif(p_space->>'id','')::uuid,p_tour) and perm.scope=p_space-'verified'
 and (nullif(p_space->>'id','') is null or exists(select 1 from public.posts where id=(p_space->>'id')::uuid and kind='space' and not hidden)) and perm.owner_id=coalesce((select author_id from public.posts where id=nullif(p_space->>'id','')::uuid and kind='space' and not hidden),p_owner)
 and not exists(select 1 from public.account_deletion_requests where user_id=perm.owner_id));
$$;
create function public.tours_save(p_tour uuid,p_title text,p_space jsonb,p_document jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();t public.tours;space_id uuid;space_owner uuid;path text;canonical_space jsonb;begin
 if p_tour is null then insert into public.tours(owner_id,title) values(account,p_title) returning * into t;
 else select * into t from public.tours where id=p_tour for update;
 if not found then insert into public.tours(id,owner_id,title) values(p_tour,account,p_title) returning * into t;
 elsif t.owner_id<>account then raise exception 'tour_owner_required';end if;end if;
 if p_space is null or jsonb_typeof(p_space)<>'object' then raise exception 'invalid_space';end if;
 space_id:=nullif(p_space->>'id','')::uuid;
 if space_id is not null then select author_id into space_owner from public.posts where id=space_id and kind='space' and not hidden;
 if not found or exists(select 1 from public.account_deletion_requests where user_id=space_owner) then raise exception 'space_unavailable';end if;end if;
 if (nullif(p_space->>'latitude','') is null)<>(nullif(p_space->>'longitude','') is null) or (p_space->>'latitude')::numeric not between -90 and 90 or (p_space->>'longitude')::numeric not between -180 and 180 or length(coalesce(p_space->>'name',''))>120 or length(coalesce(p_space->>'context',''))>3000 or length(coalesce(p_space->>'location_label',''))>180 then raise exception 'invalid_space';end if;
 for path in select jsonb_array_elements_text(coalesce(p_space->'evidence_paths','[]')) loop
 if path!~('^'||account::text||'/references/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$') or not exists(select 1 from storage.objects where bucket_id='tour-assets' and name=path) then raise exception 'invalid_space_evidence';end if;end loop;
 canonical_space:=jsonb_build_object('id',space_id,'name',coalesce(p_space->>'name',''),'location_label',coalesce(p_space->>'location_label',''),'latitude',(p_space->>'latitude')::numeric,'longitude',(p_space->>'longitude')::numeric,'context',coalesce(p_space->>'context',''),'evidence_paths',coalesce(p_space->'evidence_paths','[]'),'verified',false);
 canonical_space:=canonical_space||jsonb_build_object('verified',private.tour_space_verified(t.id,account,canonical_space));
 update public.tours set title=p_title,space=canonical_space,document=private.tour_document(t.id,account,p_document),state='draft',revision_id=case when t.state in ('published','rejected','submitted') then gen_random_uuid() else t.revision_id end,updated_at=clock_timestamp() where id=t.id;
 return private.tour_json(t.id,true);
end$$;

create function public.tours_ar_report_test(p_tour uuid,p_point uuid,p_reference_version uuid,p_platform text,p_tracking_seconds integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();t public.tours;ar jsonb;begin
 select * into t from public.tours where id=p_tour and owner_id=account for update;
 if not found or t.state<>'draft' then raise exception 'editable_tour_required';end if;
 select p.value->'ar' into ar from jsonb_array_elements(t.document->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') s cross join lateral jsonb_array_elements(s.value->'points') p where (p.value->>'id')::uuid=p_point;
 if ar is null or ar='null' or (ar->>'reference_version')::uuid is distinct from p_reference_version or p_platform is null or p_platform not in ('android','ios') or p_tracking_seconds is null or p_tracking_seconds not between 3 and 3600 then raise exception 'real_tracking_report_required';end if;
 insert into private.tour_ar_tests(tour_id,point_id,reference_version,reference_path,width_cm,platform,tracking_seconds) values(p_tour,p_point,p_reference_version,ar->>'reference_path',(ar->>'width_cm')::numeric,p_platform,p_tracking_seconds)
 on conflict(tour_id,point_id) do update set reference_version=excluded.reference_version,reference_path=excluded.reference_path,width_cm=excluded.width_cm,platform=excluded.platform,tracking_seconds=excluded.tracking_seconds,reported_at=clock_timestamp();
 update public.tours set document=private.tour_document(p_tour,account,t.document) where id=p_tour;
 return private.tour_json(p_tour,true);
end$$;

create function private.tour_public_document(p_doc jsonb) returns jsonb language plpgsql immutable set search_path='' as $$
declare z jsonb;s jsonb;p jsonb;zones jsonb:='[]';scenes jsonb;points jsonb;begin
 for z in select value from jsonb_array_elements(p_doc->'zones') loop scenes:='[]';
 for s in select value from jsonb_array_elements(z->'scenes') loop points:='[]';
 for p in select value from jsonb_array_elements(s->'points') loop
 if p->'link'<>'null' and p#>>'{link,status}' is distinct from 'approved' then p:=p||jsonb_build_object('link',null);end if;
 if p->'ar'<>'null' and (p#>>'{ar,tested_version}' is null or p#>>'{ar,tested_version}' is distinct from p#>>'{ar,reference_version}') then p:=p||jsonb_build_object('ar',null);end if;
 points:=points||jsonb_build_array(p);end loop;
 scenes:=scenes||jsonb_build_array(s||jsonb_build_object('points',points));end loop;
 zones:=zones||jsonb_build_array(z||jsonb_build_object('scenes',scenes));end loop;
 return p_doc||jsonb_build_object('zones',zones,'ar_order',coalesce((select jsonb_agg(ar.value) from jsonb_array_elements(p_doc->'ar_order') ar where exists(select 1 from jsonb_array_elements(zones) z cross join lateral jsonb_array_elements(z.value->'scenes') s cross join lateral jsonb_array_elements(s.value->'points') p where p.value->>'id'=ar.value#>>'{}' and p.value->'ar'<>'null')),'[]'));
end$$;
create function public.tours_submit(p_tour uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();t public.tours;s jsonb;pt jsonb;space_owner uuid;space_id uuid;begin
 select * into t from public.tours where id=p_tour and owner_id=account for update;
 if not found then raise exception 'tour_owner_required';end if;
 if t.state='submitted' then return private.tour_json(p_tour,true);end if;
 if t.state<>'draft' then raise exception 'editable_tour_required';end if;
 t.document:=private.tour_document(p_tour,account,t.document);
 if t.document->>'start_scene_id' is null or length(btrim(coalesce(t.space->>'name','')))<3 or length(btrim(coalesce(t.space->>'context','')))<3 then raise exception 'tour_incomplete';end if;
 if t.document->>'ends_at' is not null and (t.document->>'ends_at')::timestamptz<=clock_timestamp() then raise exception 'tour_expired';end if;
 for s in select sc.value from jsonb_array_elements(t.document->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') sc loop
 if s->>'job_id' is null then raise exception 'panorama_required';end if;
 if exists(select 1 from jsonb_array_elements(s->'connections') c where coalesce((c.value->>'needs_review')::boolean,false)) then raise exception 'panorama_review_required';end if;
 for pt in select value from jsonb_array_elements(s->'points') loop
 if coalesce((pt->>'needs_review')::boolean,false) then raise exception 'panorama_review_required';end if;
 if pt->'link'<>'null' and pt#>>'{link,status}' is distinct from 'approved' and length(btrim(coalesce(pt->>'description','')))<3 then raise exception 'independent_point_description_required';end if;
 -- Untested AR stays in the draft and is omitted by tour_public_document.
 end loop;end loop;
 t.space:=t.space||jsonb_build_object('verified',private.tour_space_verified(t.id,account,t.space));
 insert into public.tour_revisions(id,tour_id,owner_id,title,space,document) values(t.revision_id,t.id,t.owner_id,t.title,t.space,private.tour_public_document(t.document));
 if (t.space->>'verified')::boolean then update public.tours set state='published',space=t.space,document=t.document,public_revision_id=t.revision_id where id=p_tour;return private.tour_json(p_tour,true);end if;
 update public.tours set state='submitted',space=t.space,document=t.document where id=p_tour;
 space_id:=nullif(t.space->>'id','')::uuid;select author_id into space_owner from public.posts where id=space_id and kind='space' and not hidden;
 -- Even an owner needs an administrator's publication review; unlinked spaces need admin evidence review too.
 if coalesce((t.space->>'verified')::boolean,false) is not true then
 insert into public.tour_requests(tour_id,revision_id,requester_id,reviewer_id,kind,payload) values(p_tour,t.revision_id,account,space_owner,'space',t.space);end if;
 insert into public.tour_requests(tour_id,revision_id,requester_id,kind,payload) values(p_tour,t.revision_id,account,'publication',jsonb_build_object('title',t.title));
 return private.tour_json(p_tour,true);
end$$;
create function public.tours_link_request(p_tour uuid,p_point uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();t public.tours;ln jsonb;rid uuid;begin
 select * into t from public.tours where id=p_tour and owner_id=account for update;
 if not found or t.state<>'draft' then raise exception 'editable_tour_required';end if;
 select p.value->'link' into ln from jsonb_array_elements(t.document->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') s cross join lateral jsonb_array_elements(s.value->'points') p where (p.value->>'id')::uuid=p_point;
 if ln is null or ln='null' then raise exception 'point_link_required';end if;
 ln:=private.tour_link(ln->>'kind',(ln->>'id')::uuid,p_tour,account);
 if ln->>'status'='approved' then return ln;end if;
 select id into rid from public.tour_requests where tour_id=p_tour and revision_id=t.revision_id and kind='link' and status='pending' and payload->>'point_id'=p_point::text and payload->'link'=ln limit 1;
 if rid is null then insert into public.tour_requests(tour_id,revision_id,requester_id,reviewer_id,kind,payload) values(p_tour,t.revision_id,account,(ln->>'owner_id')::uuid,'link',jsonb_build_object('point_id',p_point,'link',ln)) returning id into rid;end if;
 return jsonb_build_object('id',rid,'status','pending');
end$$;
create function public.tours_requests() returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();result jsonb;begin
 select coalesce(jsonb_agg(to_jsonb(r)||jsonb_build_object('title',coalesce((select title from public.tour_revisions where id=r.revision_id),(select title from public.tours where id=r.tour_id)),'context',r.payload,'space',case when r.kind='link' and r.requester_id<>account and not public.community_is_admin() then null else coalesce((select space from public.tour_revisions where id=r.revision_id),(select space from public.tours where id=r.tour_id)) end,'evidence_paths',case when r.kind='link' and r.requester_id<>account and not public.community_is_admin() then '[]'::jsonb else coalesce((select space->'evidence_paths' from public.tour_revisions where id=r.revision_id),'[]') end,'captures',case when r.kind='link' and r.requester_id<>account and not public.community_is_admin() then '[]'::jsonb else coalesce((select jsonb_agg(jsonb_build_object('id',cap.id,'scene_id',cap.scene_id,'mode',cap.mode,'manifest',cap.manifest)) from private.tour_captures cap join private.tour_jobs j on j.capture_id=cap.id where cap.tour_id=r.tour_id and j.state='succeeded' and exists(select 1 from public.tour_revisions rev cross join lateral jsonb_array_elements(rev.document->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') s where rev.id=r.revision_id and s.value->>'job_id'=j.id::text)),'[]') end,'tour',case when r.kind='link' and r.requester_id<>account and not public.community_is_admin() then null else coalesce((select jsonb_build_object('id',rev.tour_id,'owner_id',rev.owner_id,'title',rev.title,'state','submitted','revision_id',rev.id,'public_revision_id',(select public_revision_id from public.tours where id=rev.tour_id),'space',rev.space,'document',rev.document) from public.tour_revisions rev where rev.id=r.revision_id),private.tour_json(r.tour_id,true)) end) order by r.created_at desc),'[]') into result from public.tour_requests r where r.requester_id=account or ((r.status='pending' or (r.status='approved' and r.kind in ('link','space'))) and (r.reviewer_id=account or public.community_is_admin()));return result;
end$$;
create function public.tours_review(p_request uuid,p_approve boolean,p_reason text) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();r public.tour_requests;t public.tours;target_owner uuid;ln jsonb;begin
 select * into r from public.tour_requests where id=p_request for update;
 if not found or r.status<>'pending' or p_approve is null then raise exception 'pending_request_required';end if;
 select * into t from public.tours where id=r.tour_id for update;
 if r.kind='link' and t.revision_id<>r.revision_id then raise exception 'request_superseded';end if;
 if exists(select 1 from public.account_deletion_requests where user_id=t.owner_id) then raise exception 'account_deletion_pending';end if;
 if not public.community_is_admin() and (r.reviewer_id is null or r.reviewer_id<>account or r.kind='publication') then raise exception 'reviewer_required';end if;
 if account=t.owner_id then raise exception 'independent_review_required';end if;
 if length(coalesce(p_reason,''))>1000 or (not p_approve and length(btrim(coalesce(p_reason,'')))<3) then raise exception 'review_reason_required';end if;
 if r.kind='link' then
 ln:=r.payload->'link';ln:=private.tour_link(ln->>'kind',(ln->>'id')::uuid,t.id,t.owner_id);
 if (ln->>'owner_id')::uuid is distinct from r.reviewer_id or not exists(select 1 from jsonb_array_elements(t.document->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') s cross join lateral jsonb_array_elements(s.value->'points') p where p.value->>'id'=r.payload->>'point_id' and p.value#>>'{link,id}'=ln->>'id' and p.value#>>'{link,kind}'=ln->>'kind') then raise exception 'link_changed';end if;
 if p_approve then insert into private.tour_permissions(tour_id,kind,target_id,owner_id) values(t.id,ln->>'kind',(ln->>'id')::uuid,(ln->>'owner_id')::uuid) on conflict do nothing;update public.tours set document=private.tour_document(t.id,t.owner_id,t.document) where id=t.id;end if;
 elsif r.kind='space' then
 if not exists(select 1 from public.tour_revisions where id=r.revision_id and tour_id=t.id) then raise exception 'submitted_revision_required';end if;
 if nullif(r.payload->>'id','') is not null then select author_id into target_owner from public.posts where id=(r.payload->>'id')::uuid and kind='space' and not hidden;
 if target_owner is distinct from r.reviewer_id or exists(select 1 from public.account_deletion_requests where user_id=target_owner) then raise exception 'space_changed';end if;end if;
 -- The approval belongs to this frozen revision, never arbitrary client metadata.
 elsif r.kind='publication' then
 if not exists(select 1 from public.tour_revisions where id=r.revision_id and tour_id=t.id) then raise exception 'submitted_revision_required';end if;
 if p_approve and exists(select 1 from public.tour_requests where tour_id=t.id and revision_id=r.revision_id and kind='space' and status<>'approved') then raise exception 'space_approval_required';end if;
 if p_approve then
 if exists(select 1 from public.tour_revisions rev where rev.id=r.revision_id and nullif(rev.space->>'id','') is not null and not exists(select 1 from public.posts p where p.id=(rev.space->>'id')::uuid and p.kind='space' and not p.hidden and not exists(select 1 from public.account_deletion_requests a where a.user_id=p.author_id))) then raise exception 'space_unavailable';end if;
 perform private.tour_document(t.id,t.owner_id,(select document from public.tour_revisions where id=r.revision_id));
 if t.document->>'ends_at' is not null and (t.document->>'ends_at')::timestamptz<=now() then raise exception 'tour_expired';end if;
 if exists(select 1 from public.tour_revisions old_rev join public.tour_revisions reviewed on reviewed.id=r.revision_id where old_rev.id=t.public_revision_id and old_rev.created_at>reviewed.created_at) then raise exception 'request_superseded';end if;
 insert into private.tour_permissions(tour_id,kind,target_id,owner_id,scope) select t.id,'space',coalesce(nullif(rev.space->>'id','')::uuid,t.id),coalesce((select author_id from public.posts where id=nullif(rev.space->>'id','')::uuid and kind='space' and not hidden),t.owner_id),rev.space-'verified' from public.tour_revisions rev where rev.id=r.revision_id on conflict(tour_id,kind,target_id) do update set owner_id=excluded.owner_id,scope=excluded.scope;
 update public.tours set state=case when revision_id=r.revision_id then 'published' else state end,public_revision_id=r.revision_id where id=t.id;
 else update public.tours set state='rejected' where id=t.id and revision_id=r.revision_id;end if;
 end if;
 update public.tour_requests set status=case when p_approve then 'approved' else 'rejected' end,reason=p_reason,reviewed_at=clock_timestamp() where id=r.id;
 if not p_approve and r.kind='space' then update public.tours set state='rejected' where id=t.id and revision_id=r.revision_id;update public.tour_requests set status='superseded' where tour_id=t.id and revision_id=r.revision_id and status='pending';end if;
 return jsonb_build_object('id',r.id,'status',case when p_approve then 'approved' else 'rejected' end);
end$$;
create function public.tours_pause(p_tour uuid,p_paused boolean) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();begin
 if p_paused is null then raise exception 'invalid_pause';end if;
 if not p_paused and not exists(select 1 from public.tours t join public.tour_revisions r on r.id=t.public_revision_id join private.tour_permissions perm on perm.tour_id=t.id and perm.kind='space' and perm.target_id=coalesce(nullif(r.space->>'id','')::uuid,t.id) and perm.scope=r.space-'verified' where t.id=p_tour and not exists(select 1 from public.account_deletion_requests a where a.user_id=perm.owner_id)) then raise exception 'space_permission_required';end if;
 update public.tours set paused=p_paused where id=p_tour and (owner_id=account or public.community_is_admin());if not found then raise exception 'tour_owner_required';end if;return private.tour_json(p_tour,true);
end$$;
create function public.tours_progress(p_tour uuid,p_revision uuid,p_progress jsonb default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();doc jsonb;item jsonb;result jsonb;previous uuid;begin
 if not private.tour_visible(p_tour) or not exists(select 1 from public.tours where id=p_tour and public_revision_id=p_revision) then raise exception 'published_revision_required';end if;
 select document into doc from public.tour_revisions where id=p_revision;
 if p_progress is not null then
 if jsonb_typeof(p_progress)<>'object' or length(p_progress::text)>16000 or exists(select 1 from jsonb_object_keys(p_progress) k where k not in ('scene_id','visited','skipped','revision_id')) or nullif(p_progress->>'revision_id','')::uuid is distinct from p_revision then raise exception 'invalid_progress';end if;
 if nullif(p_progress->>'scene_id','') is not null and not exists(select 1 from jsonb_array_elements(doc->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') s where s.value->>'id'=p_progress->>'scene_id') then raise exception 'invalid_progress_scene';end if;
 for item in select value from jsonb_array_elements(coalesce(p_progress->'visited','[]')) union all select value from jsonb_array_elements(coalesce(p_progress->'skipped','[]')) loop
 if not exists(select 1 from jsonb_array_elements(doc->'ar_order') ar where ar.value=item) then raise exception 'invalid_progress_point';end if;end loop;
 if exists(select 1 from jsonb_array_elements(coalesce(p_progress->'visited','[]')) v join jsonb_array_elements(coalesce(p_progress->'skipped','[]')) sk on sk.value=v.value) then raise exception 'progress_overlap';end if;
 insert into public.tour_progress values(p_tour,p_revision,account,p_progress,clock_timestamp()) on conflict(revision_id,user_id) do update set progress=excluded.progress,updated_at=clock_timestamp();end if;
 select progress into result from public.tour_progress where revision_id=p_revision and user_id=account;
 if result is not null then return result||jsonb_build_object('revision_id',p_revision);end if;
 select revision_id into previous from public.tour_progress where tour_id=p_tour and user_id=account and revision_id<>p_revision order by updated_at desc limit 1;
 if previous is not null then return jsonb_build_object('revision_id',previous);end if;return null;
end$$;

create function private.tour_job_json(p_job uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('id',id,'capture_id',capture_id,'state',case state when 'processing' then 'running' when 'succeeded' then 'ready' when 'failed' then case when error_code in ('incomplete_sphere_coverage','disconnected_control_points','gpano_full_sphere_required','insufficient_frames','invalid_image','image_dimensions_mismatch','image_orientation_not_normalized') then 'needs_recapture' else state end else state end,'error_code',error_code,'message',message,'result',result,'attempts',attempts) from private.tour_jobs where id=p_job;
$$;
create function public.tours_capture_begin(p_tour uuid,p_scene uuid,p_mode text) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();cap uuid;begin
 if p_scene is null or p_mode not in ('photos','import') or not exists(select 1 from public.tours where id=p_tour and owner_id=account and state='draft') then raise exception 'editable_capture_required';end if;
 insert into private.tour_captures(tour_id,owner_id,scene_id,mode) values(p_tour,account,p_scene,p_mode) returning id into cap;return jsonb_build_object('id',cap);
end$$;
create function public.tours_capture_submit(p_capture uuid,p_manifest jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();cap private.tour_captures;f jsonb;ids uuid[]:='{}';ident uuid;job uuid;begin
 select * into cap from private.tour_captures where id=p_capture and owner_id=account for update;
 if not found then raise exception 'capture_owner_required';end if;
 if cap.manifest is not null then
 if cap.manifest is distinct from p_manifest then raise exception 'capture_immutable';end if;select id into job from private.tour_jobs where capture_id=p_capture;return private.tour_job_json(job);end if;
 if not exists(select 1 from public.tours where id=cap.tour_id and state='draft') then raise exception 'editable_capture_required';end if;
 if p_manifest is null or jsonb_typeof(p_manifest)<>'object' or p_manifest->>'mode' is distinct from cap.mode or jsonb_typeof(p_manifest->'frames') is distinct from 'array' or jsonb_array_length(p_manifest->'frames') not between 1 and 96 or (cap.mode='import' and jsonb_array_length(p_manifest->'frames')<>1) or length(p_manifest::text)>200000 then raise exception 'invalid_manifest';end if;
 for f in select value from jsonb_array_elements(p_manifest->'frames') loop
 ident:=(f->>'id')::uuid;
 if ident is null or ident=any(ids) or f->>'path' is distinct from account::text||'/'||p_capture::text||'/'||ident::text||'.jpg' or not exists(select 1 from storage.objects where bucket_id='tour-inputs' and name=f->>'path') or coalesce((f->>'width')::int,0) not between 64 and 24000 or coalesce((f->>'height')::int,0) not between 64 and 24000 or coalesce((f->>'yaw')::numeric,999) not between -180 and 179.999999 or coalesce((f->>'pitch')::numeric,999) not between -90 and 90 or coalesce((f->>'roll')::numeric,999) not between -180 and 180 or coalesce((f->>'hfov')::numeric,0) not between 1 and 360 or coalesce((f->>'vfov')::numeric,0) not between 1 and 180 then raise exception 'invalid_frame';end if;ids:=array_append(ids,ident);
 end loop;
 update private.tour_captures set manifest=p_manifest where id=p_capture;
 insert into private.tour_jobs(capture_id,owner_id) values(p_capture,account) returning id into job;return private.tour_job_json(job);
end$$;
create function public.tours_job_get(p_job uuid) returns jsonb language plpgsql security definer set search_path='' as $$
begin perform public.community_active_account();if exists(select 1 from private.tour_jobs where id=p_job and owner_id=auth.uid()) then return private.tour_job_json(p_job);end if;return null;end$$;
create function public.tours_job_cancel(p_job uuid) returns jsonb language plpgsql security definer set search_path='' as $$
begin perform public.community_active_account();update private.tour_jobs set state='cancelled',cleanup_needed=true,lease_id=null,lease_until=null,result=null where id=p_job and owner_id=auth.uid() and state in ('queued','processing');if not exists(select 1 from private.tour_jobs where id=p_job and owner_id=auth.uid()) then raise exception 'job_owner_required';end if;return private.tour_job_json(p_job);end$$;
create function public.tours_attach_result(p_tour uuid,p_scene uuid,p_job uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();t public.tours;j private.tour_jobs;z jsonb;s jsonb;zones jsonb:='[]';scenes jsonb;hit boolean:=false;begin
 select * into t from public.tours where id=p_tour and owner_id=account and state='draft' for update;if not found then raise exception 'editable_tour_required';end if;
 select job.* into j from private.tour_jobs job join private.tour_captures c on c.id=job.capture_id where job.id=p_job and job.owner_id=account and job.state='succeeded' and c.tour_id=p_tour and c.scene_id=p_scene;if not found then raise exception 'successful_scene_job_required';end if;
 if exists(select 1 from private.tour_captures newer join private.tour_captures selected on selected.id=j.capture_id where newer.tour_id=p_tour and newer.scene_id=p_scene and newer.manifest is not null and newer.created_at>selected.created_at) then raise exception 'capture_superseded';end if;
 for z in select value from jsonb_array_elements(t.document->'zones') loop
 scenes:='[]';for s in select value from jsonb_array_elements(z->'scenes') loop
 if s->>'id'=p_scene::text then if s->>'job_id' is not null and s->>'job_id'<>j.id::text then
 s:=s||jsonb_build_object('points',coalesce((select jsonb_agg(p.value||jsonb_build_object('yaw',null,'pitch',null,'needs_review',true)) from jsonb_array_elements(s->'points') p),'[]'),'connections',coalesce((select jsonb_agg(c.value||jsonb_build_object('yaw',null,'pitch',null,'needs_review',true)) from jsonb_array_elements(s->'connections') c),'[]'));
 end if;s:=s||j.result||jsonb_build_object('job_id',j.id);hit:=true;end if;scenes:=scenes||jsonb_build_array(s);end loop;
 zones:=zones||jsonb_build_array(z||jsonb_build_object('scenes',scenes));end loop;
 if not hit then
 s:=jsonb_build_object('id',p_scene,'name','Escena','job_id',j.id,'initial_yaw',0,'connections','[]'::jsonb,'points','[]'::jsonb)||j.result;
 zones:=zones||jsonb_build_array(jsonb_build_object('id',gen_random_uuid(),'name','Zona','description','','scenes',jsonb_build_array(s)));end if;
 update public.tours set document=private.tour_document(p_tour,account,t.document||jsonb_build_object('zones',zones)) where id=p_tour;return private.tour_json(p_tour,true);
end$$;

-- Service RPCs. The global lock makes the two-slot check and CAS atomic.
create function public.tours_claim_jobs() returns jsonb language plpgsql security definer set search_path='' as $$
declare slots integer;result jsonb;begin
 perform pg_catalog.pg_advisory_xact_lock(360180);
 update private.tour_jobs set state='cancelled',cleanup_needed=true,lease_id=null,lease_until=null where state in ('queued','processing') and exists(select 1 from public.account_deletion_requests a where a.user_id=owner_id);
 update private.tour_jobs set state=case when attempts>=3 then 'failed' else 'queued' end,error_code='lease_expired',cleanup_needed=true,lease_id=null,lease_until=null where state='processing' and lease_until<=clock_timestamp() and not exists(select 1 from private.tour_output_writes w where w.job_id=private.tour_jobs.id and w.expires_at>clock_timestamp());
 select greatest(0,2-count(*)::integer) into slots from private.tour_jobs where state='processing' and (lease_until>clock_timestamp() or exists(select 1 from private.tour_output_writes w where w.job_id=private.tour_jobs.id and w.expires_at>clock_timestamp()));
 with picked as(select id from private.tour_jobs where state='queued' and attempts<3 and scheduled_at<=clock_timestamp() and not exists(select 1 from private.tour_output_writes w where w.job_id=private.tour_jobs.id and w.expires_at>clock_timestamp()) order by scheduled_at limit slots for update skip locked), claimed as(
 update private.tour_jobs j set state='processing',attempts=attempts+1,lease_id=gen_random_uuid(),lease_until=clock_timestamp()+interval '16 minutes',error_code=null,message=null from picked where j.id=picked.id returning j.*)
 select coalesce(jsonb_agg(jsonb_build_object('id',j.id,'capture_id',j.capture_id,'owner_id',j.owner_id,'lease_id',j.lease_id,'lease_until',j.lease_until,'manifest',c.manifest)),'[]') into result from claimed j join private.tour_captures c on c.id=j.capture_id;return result;
end$$;
create function public.tours_job_is_current(p_job uuid,p_lease uuid) returns boolean language sql security definer set search_path='' as $$
 select exists(select 1 from private.tour_jobs j where id=p_job and lease_id=p_lease and state='processing' and lease_until>clock_timestamp() and not exists(select 1 from public.account_deletion_requests a where a.user_id=j.owner_id));
$$;
create function public.tours_begin_output_write(p_job uuid,p_lease uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare owner uuid;begin
 select owner_id into owner from private.tour_jobs where id=p_job;
 if owner is null then return false;end if;perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner::text,0));
 if not public.tours_job_is_current(p_job,p_lease) then return false;end if;
 insert into private.tour_output_writes(job_id,owner_id,lease_id) values(p_job,owner,p_lease) on conflict(job_id) do update set lease_id=excluded.lease_id,expires_at=clock_timestamp()+interval '60 seconds';return true;
end$$;
create function public.tours_end_output_write(p_job uuid,p_lease uuid) returns void language sql security definer set search_path='' as $$
 delete from private.tour_output_writes where job_id=p_job and lease_id=p_lease;
$$;
create function public.tours_finish_job(p_job uuid,p_lease uuid,p_state text,p_result jsonb default null,p_error text default null) returns boolean language plpgsql security definer set search_path='' as $$
declare j private.tour_jobs;path text;begin
 select * into j from private.tour_jobs where id=p_job for update;
 if not found then return false;end if;
 if j.state='succeeded' and j.completed_lease_id=p_lease and p_state='succeeded' and j.result=p_result then return true;end if;
 if not public.tours_job_is_current(p_job,p_lease) then return false;end if;
 if p_state='succeeded' then
 foreach path in array array['panorama_path','preview_path','thumbnail_path'] loop
 if p_result->>path is distinct from j.owner_id::text||'/jobs/'||j.id::text||'/'||replace(path,'_path','')||'.jpg' or not exists(select 1 from storage.objects where bucket_id='tour-assets' and name=p_result->>path) then raise exception 'invalid_worker_output';end if;end loop;
 elsif p_state not in ('retry','failed') then raise exception 'invalid_job_state';end if;
 update private.tour_jobs set state=case when p_state='succeeded' then 'succeeded' when p_state='retry' and p_error in ('network','storage_unavailable','dispatch_unavailable','timeout','lease_expired') and attempts<3 then 'queued' else 'failed' end,
 completed_lease_id=case when p_state='succeeded' then p_lease end,cleanup_needed=p_state<>'succeeded',result=case when p_state='succeeded' then p_result end,error_code=case when p_state='succeeded' then null else left(p_error,80) end,message=case when p_state='succeeded' then null when p_error='gpano_full_sphere_required' then 'Importa una esfera completa con metadatos GPano; una imagen 2:1 no basta.' when p_error='incomplete_sphere_coverage' then 'Faltan zonas de la esfera, techo o suelo; completa la captura.' when p_error='disconnected_control_points' then 'Las fotos no tienen suficiente solapamiento para formar una esfera conectada.' when p_error in ('network','storage_unavailable','dispatch_unavailable','timeout','lease_expired') then 'El procesamiento se interrumpió temporalmente.' else 'No se pudo procesar esta captura. Revisa las fotos e inténtalo de nuevo.' end,
 scheduled_at=clock_timestamp()+power(2,attempts)*interval '15 seconds',lease_id=null,lease_until=null where id=p_job;
 return true;
end$$;
create or replace function public.request_account_deletion(owner_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
begin
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text,0));
 insert into public.account_deletion_requests(user_id) values(owner_id) on conflict do nothing;
 update private.tour_jobs set state='cancelled',cleanup_needed=true,lease_id=null,lease_until=null,result=null where private.tour_jobs.owner_id=request_account_deletion.owner_id and state in ('queued','processing');
 update public.tours set paused=true where public.tours.owner_id=request_account_deletion.owner_id;
 return not exists(select 1 from public.profile_media_operations where user_id=owner_id and expires_at>now()) and not exists(select 1 from private.tour_output_writes w where w.owner_id=request_account_deletion.owner_id and w.expires_at>clock_timestamp());
end$$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
 ('tour-inputs','tour-inputs',false,33554432,array['image/jpeg']),('tour-assets','tour-assets',false,33554432,array['image/jpeg'])
on conflict(id) do update set public=false,file_size_limit=33554432,allowed_mime_types=array['image/jpeg'];
create function private.tour_input_write(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin
 perform public.community_active_account();
 return p_path~('^'||auth.uid()::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$')
 and exists(select 1 from private.tour_captures c join public.tours t on t.id=c.tour_id where c.id=split_part(p_path,'/',2)::uuid and c.owner_id=auth.uid() and c.manifest is null and t.state='draft');
end$$;
create function private.tour_asset_read(p_path text) returns boolean language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null then return false;end if;
 if split_part(p_path,'/',1)=auth.uid()::text and not exists(select 1 from public.account_deletion_requests where user_id=auth.uid()) then return true;end if;
 return exists(select 1 from public.tours t join public.tour_revisions r on r.id=t.public_revision_id where private.tour_visible(t.id) and (
 exists(select 1 from jsonb_array_elements(r.document->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') s where p_path in (s.value->>'panorama_path',s.value->>'preview_path',s.value->>'thumbnail_path') or exists(select 1 from jsonb_array_elements(s.value->'points') p where p.value#>>'{ar,reference_path}'=p_path))));
end$$;
create function private.tour_reference_write(p_path text) returns boolean language plpgsql security definer set search_path='' as $$
begin perform public.community_active_account();return p_path~('^'||auth.uid()::text||'/references/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$');end$$;
-- No UPDATE policies: submitted originals and references are immutable.
create policy "Tour input owner reads" on storage.objects for select to authenticated using(bucket_id='tour-inputs' and split_part(name,'/',1)=auth.uid()::text and not exists(select 1 from public.account_deletion_requests where user_id=auth.uid()));
-- Use helper for deletion marker, avoiding privilege exposure to private tables.
drop policy "Tour input owner reads" on storage.objects;
create policy "Tour input owner reads" on storage.objects for select to authenticated using(bucket_id='tour-inputs' and private.tour_asset_read(name) and split_part(name,'/',1)=auth.uid()::text);
create policy "Tour input draft writes" on storage.objects for insert to authenticated with check(bucket_id='tour-inputs' and private.tour_input_write(name));
create policy "Tour assets permitted reads" on storage.objects for select to authenticated using(bucket_id='tour-assets' and private.tour_asset_read(name));
create policy "Tour reference inserts" on storage.objects for insert to authenticated with check(bucket_id='tour-assets' and private.tour_reference_write(name));
-- RPC-only editorial tables avoid exposing drafts in the published tour.
-- Helpers are callable only as needed for RLS. They expose booleans, not data.
grant usage on schema private to authenticated;
revoke all on all functions in schema private from public,anon,authenticated;
grant execute on function private.tour_input_write(text),private.tour_asset_read(text),private.tour_reference_write(text) to authenticated;
do $$declare f record;begin
 for f in select p.oid::regprocedure signature,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like 'tours_%' loop
 execute 'revoke all on function '||f.signature||' from public,anon,authenticated';
 if f.proname in ('tours_claim_jobs','tours_job_is_current','tours_finish_job','tours_begin_output_write','tours_end_output_write') then execute 'grant execute on function '||f.signature||' to service_role';
 else execute 'grant execute on function '||f.signature||' to authenticated';end if;
 end loop;
end$$;
revoke all on function public.request_account_deletion(uuid) from public,anon,authenticated;
grant execute on function public.request_account_deletion(uuid) to service_role;

create function public.tours_job_context(p_job uuid,p_lease uuid) returns jsonb language sql security definer set search_path='' as $$
 select jsonb_build_object('id',j.id,'capture_id',j.capture_id,'owner_id',j.owner_id,'lease_id',j.lease_id,'lease_until',j.lease_until,'manifest',c.manifest)
 from private.tour_jobs j join private.tour_captures c on c.id=j.capture_id where j.id=p_job and public.tours_job_is_current(p_job,p_lease);
$$;
revoke all on function public.tours_job_context(uuid,uuid) from public,anon,authenticated;
grant execute on function public.tours_job_context(uuid,uuid) to service_role;

create function private.wake_tour_dispatcher() returns void language plpgsql security definer set search_path='' as $$
declare endpoint text;secret text;begin
 if to_regclass('vault.decrypted_secrets') is null or to_regprocedure('net.http_post(text,jsonb,jsonb,jsonb,integer)') is null then return;end if;
 execute 'select decrypted_secret from vault.decrypted_secrets where name=''marea_tour_dispatch_url'' limit 1' into endpoint;
 execute 'select decrypted_secret from vault.decrypted_secrets where name=''marea_tour_worker_secret'' limit 1' into secret;
 if endpoint is null or length(coalesce(secret,''))<32 then return;end if;
 execute 'select net.http_post(url:=$1,body:=''{}''::jsonb,headers:=jsonb_build_object(''Content-Type'',''application/json'',''Authorization'',''Bearer ''||$2),timeout_milliseconds:=10000)' using endpoint,secret;
 exception when others then null; -- Cron repairs lost wakes; queue insert stays durable.
end$$;
create function private.tour_queue_wake() returns trigger language plpgsql security definer set search_path='' as $$
begin if new.state='queued' then perform private.wake_tour_dispatcher();end if;return new;end$$;
create trigger tour_queue_wake after insert or update of state on private.tour_jobs for each row execute function private.tour_queue_wake();
revoke all on function private.wake_tour_dispatcher(),private.tour_queue_wake() from public,anon,authenticated;
grant execute on function private.wake_tour_dispatcher() to service_role;

-- Reserve canonical paths for GC before deletion. Claims wait for this guard,
-- so a stale cleanup can never delete a newer execution's results.
create function public.tours_claim_cleanup() returns jsonb language plpgsql security definer set search_path='' as $$
declare j private.tour_jobs;token uuid;result jsonb:='[]';begin
 perform pg_catalog.pg_advisory_xact_lock(360180);
 for j in select q.* from private.tour_jobs q where q.cleanup_needed and q.state in ('queued','failed','cancelled') and not exists(select 1 from private.tour_output_writes w where w.job_id=q.id and w.expires_at>clock_timestamp()) limit 20 for update skip locked loop
 token:=gen_random_uuid();insert into private.tour_output_writes(job_id,owner_id,lease_id) values(j.id,j.owner_id,token) on conflict(job_id) do update set lease_id=excluded.lease_id,expires_at=clock_timestamp()+interval '60 seconds';
 result:=result||jsonb_build_array(jsonb_build_object('id',j.id,'lease_id',token,'paths',jsonb_build_array(j.owner_id::text||'/jobs/'||j.id::text||'/panorama.jpg',j.owner_id::text||'/jobs/'||j.id::text||'/preview.jpg',j.owner_id::text||'/jobs/'||j.id::text||'/thumbnail.jpg')));
 end loop;return result;
end$$;
create function public.tours_finish_cleanup(p_job uuid,p_lease uuid,p_success boolean) returns boolean language plpgsql security definer set search_path='' as $$
begin
 perform pg_catalog.pg_advisory_xact_lock(360180);
 if not exists(select 1 from private.tour_output_writes where job_id=p_job and lease_id=p_lease and expires_at>clock_timestamp()) then return false;end if;
 if p_success then update private.tour_jobs set cleanup_needed=false where id=p_job and state in ('queued','failed','cancelled');end if;
 delete from private.tour_output_writes where job_id=p_job and lease_id=p_lease;return true;
end$$;
revoke all on function public.tours_claim_cleanup(),public.tours_finish_cleanup(uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function public.tours_claim_cleanup(),public.tours_finish_cleanup(uuid,uuid,boolean) to service_role;

create function private.tour_input_read(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from private.tour_captures c where c.id::text=split_part(p_path,'/',2) and c.owner_id::text=split_part(p_path,'/',1) and (
 (c.owner_id=auth.uid() and not exists(select 1 from public.account_deletion_requests a where a.user_id=c.owner_id)) or
 exists(select 1 from public.tour_requests req join public.tour_revisions rev on rev.id=req.revision_id where req.tour_id=c.tour_id and req.status='pending' and ((req.kind in ('space','publication') and req.reviewer_id=auth.uid()) or public.community_is_admin())
 and exists(select 1 from jsonb_array_elements(rev.document->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') s join private.tour_jobs j on j.id::text=s.value->>'job_id' where j.capture_id=c.id))
 ) and (c.manifest is null or exists(select 1 from jsonb_array_elements(c.manifest->'frames') f where f.value->>'path'=p_path)));
$$;
drop policy "Tour input owner reads" on storage.objects;
create policy "Tour inputs permitted reads" on storage.objects for select to authenticated using(bucket_id='tour-inputs' and private.tour_input_read(name));
revoke all on function private.tour_input_read(text) from public,anon,authenticated;
grant execute on function private.tour_input_read(text) to authenticated;

create function private.tour_review_asset(p_path text) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.tour_requests req join public.tour_revisions r on r.id=req.revision_id
 where req.status='pending' and ((req.kind in ('space','publication') and req.reviewer_id=auth.uid()) or public.community_is_admin()) and (
 exists(select 1 from jsonb_array_elements_text(r.space->'evidence_paths') e where e=p_path) or
 exists(select 1 from jsonb_array_elements(r.document->'zones') z cross join lateral jsonb_array_elements(z.value->'scenes') s where p_path in (s.value->>'panorama_path',s.value->>'preview_path',s.value->>'thumbnail_path') or exists(select 1 from jsonb_array_elements(s.value->'points') p where p.value#>>'{ar,reference_path}'=p_path))));
$$;
revoke all on function private.tour_review_asset(text) from public,anon,authenticated;
grant execute on function private.tour_review_asset(text) to authenticated;
create policy "Tour review asset reads" on storage.objects for select to authenticated using(bucket_id='tour-assets' and private.tour_review_asset(name));

-- Resolve a lost finish response without exposing jobs or allowing an old lease
-- to adopt another execution's result. Only backend credentials can call this.
create function public.tours_completion_receipt(p_job uuid,p_lease uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('committed',state='succeeded' and completed_lease_id=p_lease,'result',case when state='succeeded' and completed_lease_id=p_lease then result end) from private.tour_jobs where id=p_job;
$$;
revoke all on function public.tours_completion_receipt(uuid,uuid) from public,anon,authenticated;
grant execute on function public.tours_completion_receipt(uuid,uuid) to service_role;

create function public.tours_permission_revoke(p_request uuid) returns void language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();r public.tour_requests;begin
 select * into r from public.tour_requests where id=p_request for update;
 if not found or r.status<>'approved' or r.kind not in ('link','space') then raise exception 'approved_permission_required';end if;
 if r.requester_id=account or (not public.community_is_admin() and r.reviewer_id is distinct from account) then raise exception 'permission_owner_required';end if;
 if r.kind='link' then delete from private.tour_permissions where tour_id=r.tour_id and kind=r.payload#>>'{link,kind}' and target_id=(r.payload#>>'{link,id}')::uuid and owner_id=(r.payload#>>'{link,owner_id}')::uuid;
 else delete from private.tour_permissions where tour_id=r.tour_id and kind='space';update public.tours set paused=true where id=r.tour_id;end if;
 update public.tour_requests set status='revoked',reason='Permiso retirado',reviewed_at=clock_timestamp() where id=p_request;
end$$;
revoke all on function public.tours_permission_revoke(uuid) from public,anon,authenticated;
grant execute on function public.tours_permission_revoke(uuid) to authenticated;

-- Public profile cards always resolve the active version, even for its author
-- while a new private draft exists. Management continues using tours_list.
create function public.tours_public_list(p_owner uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;begin
 perform public.community_active_account();
 select coalesce(jsonb_agg(data),'[]') into result from (select private.tour_json(t.id,false) data from public.tours t where t.owner_id=p_owner and private.tour_visible(t.id) order by t.updated_at desc limit 200) x;
 return result;
end$$;
revoke all on function public.tours_public_list(uuid) from public,anon,authenticated;
grant execute on function public.tours_public_list(uuid) to authenticated;

-- Additive correction to015, for already-migrated deployments. No table/data
-- rewrite or other migration; apply after015. Fresh deployments include this
-- exact RPC in015. Only service_role can renew a still-owned GC reservation.
create or replace function public.tours_renew_cleanup(p_job uuid,p_lease uuid) returns boolean
language plpgsql security definer set search_path='' as $$
begin
 perform pg_catalog.pg_advisory_xact_lock(360180);
 update private.tour_output_writes w set expires_at=clock_timestamp()+interval '60 seconds'
 where w.job_id=p_job and w.lease_id=p_lease and w.expires_at>clock_timestamp()
 and exists(select 1 from private.tour_jobs j where j.id=w.job_id and j.cleanup_needed and j.state in ('queued','failed','cancelled'));
 return found;
end$$;
revoke all on function public.tours_renew_cleanup(uuid,uuid) from public,anon,authenticated;
grant execute on function public.tours_renew_cleanup(uuid,uuid) to service_role;
