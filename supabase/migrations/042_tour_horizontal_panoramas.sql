-- Horizontal JPEG imports retain their aspect ratio and are never a sphere.
-- Prepare locally; apply to an approved development database before enabling.
-- Ownership, storage paths, immutable captures, AR proofs and publication
-- permissions continue to be checked by the original functions.
begin;

create or replace function public.tours_capture_submit(p_capture uuid,p_manifest jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();cap private.tour_captures;f jsonb;ids uuid[]:='{}';ident uuid;job uuid;horizontal boolean;begin
 select * into cap from private.tour_captures where id=p_capture and owner_id=account for update;
 if not found then raise exception 'capture_owner_required';end if;
 if cap.manifest is not null then
 if cap.manifest is distinct from p_manifest then raise exception 'capture_immutable';end if;select id into job from private.tour_jobs where capture_id=p_capture;return private.tour_job_json(job);end if;
 if not exists(select 1 from public.tours where id=cap.tour_id and state='draft') then raise exception 'editable_capture_required';end if;
 horizontal:=coalesce(p_manifest->>'panorama_kind'='horizontal',false);
 if coalesce(p_manifest->>'panorama_kind','sphere') not in ('sphere','horizontal') or (horizontal and cap.mode<>'import') then raise exception 'invalid_manifest';end if;
 if p_manifest is null or jsonb_typeof(p_manifest)<>'object' or p_manifest->>'mode' is distinct from cap.mode or jsonb_typeof(p_manifest->'frames') is distinct from 'array' or jsonb_array_length(p_manifest->'frames') not between 1 and 96 or (cap.mode='import' and jsonb_array_length(p_manifest->'frames')<>1) or length(p_manifest::text)>200000 then raise exception 'invalid_manifest';end if;
 for f in select value from jsonb_array_elements(p_manifest->'frames') loop
 ident:=(f->>'id')::uuid;
 if ident is null or ident=any(ids) or f->>'path' is distinct from account::text||'/'||p_capture::text||'/'||ident::text||'.jpg' or not exists(select 1 from storage.objects where bucket_id='tour-inputs' and name=f->>'path') or coalesce((f->>'width')::int,0) not between 64 and 24000 or coalesce((f->>'height')::int,0) not between 64 and 24000 or ((f->>'width')::bigint*(f->>'height')::bigint)>120000000 or (not horizontal and (coalesce((f->>'yaw')::numeric,999) not between -180 and 179.999999 or coalesce((f->>'pitch')::numeric,999) not between -90 and 90 or coalesce((f->>'roll')::numeric,999) not between -180 and 180 or coalesce((f->>'hfov')::numeric,0) not between 1 and 360 or coalesce((f->>'vfov')::numeric,0) not between 1 and 180)) or (horizontal and ((f->>'width')::int<=(f->>'height')::int or f ?| array['yaw','pitch','roll','hfov','vfov'])) then raise exception 'invalid_frame';end if;ids:=array_append(ids,ident);
 end loop;
 update private.tour_captures set manifest=p_manifest where id=p_capture;
 insert into private.tour_jobs(capture_id,owner_id) values(p_capture,account) returning id into job;return private.tour_job_json(job);
end$$;

create or replace function private.tour_document(p_tour uuid,p_owner uuid,p_doc jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare z jsonb;s jsonb;pt jsonb;c jsonb;ar jsonb;ln jsonb;job private.tour_jobs;test private.tour_ar_tests;
 zones jsonb:='[]';scenes jsonb;points jsonb;connections jsonb;scene_ids uuid[]:='{}';point_ids uuid[]:='{}';all_ids uuid[]:='{}';ident uuid;target uuid;path text;start_id uuid;horizontal boolean;
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
 horizontal:=coalesce(job.result->>'panorama_kind'='horizontal',false);
 connections:='[]';for c in select value from jsonb_array_elements(coalesce(s->'connections','[]')) loop
 ident:=(c->>'id')::uuid;target:=(c->>'target_scene_id')::uuid;
 if ident is null or ident=any(all_ids) or target is null or not target=any(scene_ids) or target=(s->>'id')::uuid or (coalesce((c->>'needs_review')::boolean,false)=false and (case when horizontal then (c->>'yaw') is not null or (c->>'pitch') is not null else (coalesce((c->>'yaw')::numeric,999) not between -180 and 179.999999 or coalesce((c->>'pitch')::numeric,999) not between -90 and 90) end)) or length(coalesce(c->>'label',''))>120 or length(coalesce(c->>'instruction',''))>1000 then raise exception 'invalid_connection';end if;
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
 points:=points||jsonb_build_array(jsonb_build_object('id',ident,'name',coalesce(pt->>'name',''),'description',coalesce(pt->>'description',''),'needs_review',coalesce((pt->>'needs_review')::boolean,false),'yaw',case when coalesce((pt->>'needs_review')::boolean,false) or horizontal then null else (pt->>'yaw')::numeric end,'pitch',case when coalesce((pt->>'needs_review')::boolean,false) or horizontal then null else (pt->>'pitch')::numeric end,'link',ln,'ar',ar));end loop;
 scenes:=scenes||jsonb_build_array(jsonb_build_object('id',(s->>'id')::uuid,'name',coalesce(s->>'name',''),'job_id',job.id,'panorama_path',job.result->>'panorama_path','preview_path',job.result->>'preview_path','thumbnail_path',job.result->>'thumbnail_path','panorama_kind',case when horizontal then 'horizontal' else 'sphere' end,'panorama_width',(job.result->>'panorama_width')::int,'panorama_height',(job.result->>'panorama_height')::int,'initial_yaw',coalesce((s->>'initial_yaw')::numeric,0),'connections',connections,'points',points));end loop;
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

create or replace function public.tours_media_capabilities() returns jsonb
language sql stable set search_path='' as $$
 select jsonb_build_object('horizontal_panorama',true);
$$;
revoke all on function public.tours_media_capabilities() from public,anon;
grant execute on function public.tours_media_capabilities() to authenticated;
notify pgrst, 'reload schema';
commit;
