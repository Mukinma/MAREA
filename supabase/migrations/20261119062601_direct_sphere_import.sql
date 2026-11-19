begin;

-- Only the Edge Function may approve a JPEG. The client cannot provide output
-- paths, mark a job ready or skip the same draft/ownership checks as captures.
create function public.tours_sphere_import_target(p_owner uuid,p_capture uuid,p_frame uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
 capture private.tour_captures;
 job private.tour_jobs;
 source_path text;
 asset_path text;
 size_text text;
begin
 if p_owner is null or p_capture is null or p_frame is null then raise exception 'invalid_import'; end if;
 select * into capture from private.tour_captures where id=p_capture and owner_id=p_owner and mode='import';
 if not found or exists(select 1 from public.account_deletion_requests where user_id=p_owner) then
  raise exception 'capture_owner_required';
 end if;
 source_path:=p_owner::text||'/'||p_capture::text||'/'||p_frame::text||'.jpg';
 asset_path:=p_owner::text||'/imports/'||p_capture::text||'/'||p_frame::text||'.jpg';
 if capture.manifest is not null and (
  capture.manifest#>>'{frames,0,path}' is distinct from source_path
  or coalesce(capture.manifest->>'panorama_kind','sphere')<>'sphere'
 ) then raise exception 'capture_immutable'; end if;
 select * into job from private.tour_jobs where capture_id=p_capture;
 if job.state='succeeded' then return jsonb_build_object('job',private.tour_job_json(job.id)); end if;
 if job.id is not null and (job.state<>'queued' or job.attempts<>0 or job.cleanup_needed) then
  raise exception 'import_job_unavailable';
 end if;
 if not exists(select 1 from public.tours where id=capture.tour_id and owner_id=p_owner and state='draft') then
  raise exception 'editable_capture_required';
 end if;
 select o.metadata->>'size' into size_text from storage.objects o
 where o.bucket_id='tour-inputs' and o.name=source_path and o.metadata->>'mimetype'='image/jpeg';
 if size_text is null or size_text !~ '^[0-9]{1,8}$' then raise exception 'import_file_required'; end if;
 if size_text::integer not between 4 and 33554432 then raise exception 'invalid_import'; end if;
 return jsonb_build_object('source_path',source_path,'size',size_text::integer,'asset_path',asset_path,
  'asset_exists',exists(select 1 from storage.objects where bucket_id='tour-assets' and name=asset_path));
end$$;

create function public.tours_sphere_import_finish(
 p_owner uuid,p_capture uuid,p_frame uuid,p_operation uuid,p_width integer,p_height integer
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
 target jsonb;
 asset_path text;
 completed_result jsonb;
 job_id uuid;
begin
 if p_width is null or p_height is null or p_width not between 128 and 8192
  or p_height not between 64 and 4096 or p_width<>2*p_height then
  raise exception 'invalid_import';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_owner::text,0));
 if not exists(select 1 from public.profile_media_operations
  where id=p_operation and user_id=p_owner and expires_at>clock_timestamp()) then
  raise exception 'media_operation_unavailable';
 end if;
 perform 1 from private.tour_captures where id=p_capture and owner_id=p_owner for update;
 perform 1 from public.tours t join private.tour_captures c on c.tour_id=t.id
  where c.id=p_capture and c.owner_id=p_owner for no key update of t;
 select id into job_id from private.tour_jobs where capture_id=p_capture for update;
 target:=public.tours_sphere_import_target(p_owner,p_capture,p_frame);
 if target ? 'job' then return target->'job'; end if;
 asset_path:=target->>'asset_path';
 if not (target->>'asset_exists')::boolean then raise exception 'import_file_required'; end if;

 completed_result:=jsonb_build_object('panorama_path',asset_path,'preview_path',asset_path,
  'thumbnail_path',asset_path,'panorama_kind','sphere','panorama_width',p_width,'panorama_height',p_height);
 update private.tour_captures set manifest=jsonb_build_object('mode','import','panorama_kind','sphere',
  'frames',jsonb_build_array(jsonb_build_object('id',p_frame,'path',target->>'source_path',
   'width',p_width,'height',p_height))) where id=p_capture and manifest is null;
 if job_id is null then
  insert into private.tour_jobs(capture_id,owner_id,state,result)
   values(p_capture,p_owner,'succeeded',completed_result) returning id into job_id;
 else
  update private.tour_jobs set state='succeeded',result=completed_result,error_code=null,message=null where id=job_id;
 end if;
 return private.tour_job_json(job_id);
end$$;

revoke all on function public.tours_sphere_import_target(uuid,uuid,uuid),
 public.tours_sphere_import_finish(uuid,uuid,uuid,uuid,integer,integer) from public,anon,authenticated;
grant execute on function public.tours_sphere_import_target(uuid,uuid,uuid),
 public.tours_sphere_import_finish(uuid,uuid,uuid,uuid,integer,integer) to service_role;
notify pgrst,'reload schema';
commit;
