-- Home feed, private following relationships and 24-hour stories.
create table public.profile_follows (
 follower_id uuid not null references public.profiles(id) on delete cascade,
 author_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default clock_timestamp(),
 primary key(follower_id,author_id),check(follower_id<>author_id)
);
alter table public.profile_follows enable row level security;
revoke all on public.profile_follows from anon,authenticated;
grant select on public.profile_follows to authenticated;
grant all on public.profile_follows to service_role;
create policy "Own following" on public.profile_follows for select to authenticated using(follower_id=auth.uid());
create function public.set_profile_follow(author_uuid uuid,following boolean) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 if author_uuid=account or following is null or not exists(select 1 from public.profiles where id=author_uuid)
 or exists(select 1 from public.account_deletion_requests where user_id=author_uuid) then raise exception 'invalid_follow'; end if;
 if following then insert into public.profile_follows(follower_id,author_id) values(account,author_uuid) on conflict do nothing;
 else delete from public.profile_follows where follower_id=account and author_id=author_uuid; end if;
end; $$;

create table public.stories (
 id uuid primary key,
 author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null default '' check(char_length(body)<=500),
 image_path text unique,
 created_at timestamptz not null default clock_timestamp(),
 expires_at timestamptz not null,
 hidden boolean not null default false,
 deleted_at timestamptz,
 check(char_length(btrim(body))>0 or image_path is not null)
);
create index stories_expiration_idx on public.stories(expires_at);
create index stories_author_idx on public.stories(author_id,created_at);
create table public.story_views (
 story_id uuid not null references public.stories(id) on delete cascade,
 viewer_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default clock_timestamp(),primary key(story_id,viewer_id)
);
create table public.story_reports (
 story_id uuid not null references public.stories(id) on delete cascade,
 reporter_id uuid not null references public.profiles(id) on delete cascade,
 reason text not null check(char_length(btrim(reason)) between 5 and 500),
 created_at timestamptz not null default clock_timestamp(),primary key(story_id,reporter_id)
);
alter table public.stories enable row level security;
alter table public.story_views enable row level security;
alter table public.story_reports enable row level security;
revoke all on public.stories,public.story_views,public.story_reports from anon,authenticated;
grant select on public.stories,public.story_views,public.story_reports to authenticated;
grant all on public.stories,public.story_views,public.story_reports to service_role;
create policy "Live stories" on public.stories for select to authenticated using(
 deleted_at is null and expires_at>now() and (not hidden or public.community_is_admin())
 and public.showcase_owner_visible(author_id));
create policy "Own story views" on public.story_views for select to authenticated using(viewer_id=auth.uid());
create policy "Story reports moderation" on public.story_reports for select to authenticated using(reporter_id=auth.uid() or public.community_is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('story-images','story-images',false,4194304,array['image/png']) on conflict(id) do nothing;
create policy "Upload own story image" on storage.objects for insert to authenticated
 with check(bucket_id='story-images' and public.showcase_owner_visible(auth.uid()) and name ~ ('^'||auth.uid()::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$'));
-- Definer visibility avoids treating an RLS-hidden expired row as an orphan.
create function public.story_image_visible(image_name text) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and public.showcase_owner_visible(auth.uid()) and (
 exists(select 1 from public.stories s where s.image_path=image_name and s.deleted_at is null and s.expires_at>now()
 and (not s.hidden or public.community_is_admin()) and public.showcase_owner_visible(s.author_id))
 or (split_part(image_name,'/',1)=auth.uid()::text and not exists(select 1 from public.stories s where s.image_path=image_name)));
$$;
revoke all on function public.story_image_visible(text) from public,anon;
grant execute on function public.story_image_visible(text) to authenticated;
create policy "Read live story image" on storage.objects for select to authenticated using(bucket_id='story-images' and public.story_image_visible(name));
create policy "Delete unused story image" on storage.objects for delete to authenticated using(bucket_id='story-images'
 and (storage.foldername(name))[1]=auth.uid()::text and not exists(select 1 from public.stories s where s.image_path=name));

create function public.publish_story(story_uuid uuid,story_body text,story_image text default null) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); prior public.stories; published timestamptz:=clock_timestamp();
begin
 if story_uuid is null or story_body is null or char_length(story_body)>500 or (btrim(story_body)='' and story_image is null) then raise exception 'invalid_story'; end if;
 -- Serialize retries of the same operation before checking its journal row.
 perform pg_advisory_xact_lock(hashtextextended(story_uuid::text,0));
 select * into prior from public.stories where id=story_uuid;
 if found then
  if prior.author_id<>account or prior.body<>btrim(story_body) or prior.image_path is distinct from story_image then raise exception 'story_operation_conflict'; end if;
  return prior.id;
 end if;
 if story_image is not null and (story_image<>account::text||'/'||story_uuid::text||'.png' or not exists(select 1 from storage.objects where bucket_id='story-images' and name=story_image)) then raise exception 'invalid_story_image'; end if;
 insert into public.stories(id,author_id,body,image_path,created_at,expires_at)
 values(story_uuid,account,btrim(story_body),story_image,published,published+interval '24 hours');
 return story_uuid;
end; $$;
create function public.list_stories() returns jsonb
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); result jsonb;
begin
 select coalesce(jsonb_agg(to_jsonb(s)||jsonb_build_object('seen',exists(select 1 from public.story_views v where v.story_id=s.id and v.viewer_id=account)) order by s.created_at,s.id),'[]'::jsonb) into result
 from public.stories s where s.deleted_at is null and not s.hidden and s.expires_at>clock_timestamp()
 and not exists(select 1 from public.account_deletion_requests d where d.user_id=s.author_id);
 return jsonb_build_object('server_time',clock_timestamp(),'stories',result);
end; $$;
create function public.mark_story_seen(story_uuid uuid) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 if not exists(select 1 from public.stories s where s.id=story_uuid and not s.hidden and s.deleted_at is null and s.expires_at>clock_timestamp()
 and not exists(select 1 from public.account_deletion_requests d where d.user_id=s.author_id)) then raise exception 'story_unavailable'; end if;
 insert into public.story_views(story_id,viewer_id) values(story_uuid,account) on conflict do nothing;
end; $$;
create function public.delete_story(story_uuid uuid) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 if not exists(select 1 from public.stories where id=story_uuid and author_id=account) then raise exception 'story_permission_denied'; end if;
 update public.stories set deleted_at=coalesce(deleted_at,clock_timestamp()) where id=story_uuid;
end; $$;
create function public.report_story(story_uuid uuid,report_reason text) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 if report_reason is null or char_length(btrim(report_reason)) not between 5 and 500 then raise exception 'invalid_report'; end if;
 if not exists(select 1 from public.stories s where s.id=story_uuid and not s.hidden and s.deleted_at is null and s.expires_at>now()
 and not exists(select 1 from public.account_deletion_requests d where d.user_id=s.author_id)) then raise exception 'story_unavailable'; end if;
 insert into public.story_reports(story_id,reporter_id,reason) values(story_uuid,account,btrim(report_reason)) on conflict do nothing;
end; $$;
create function public.reported_stories() returns setof jsonb
language plpgsql security definer set search_path='' as $$
begin
 perform public.community_active_account();
 if not public.community_is_admin() then raise exception 'story_permission_denied'; end if;
 return query select to_jsonb(s)||jsonb_build_object('reports',(select jsonb_agg(jsonb_build_object('reason',r.reason,'created_at',r.created_at)) from public.story_reports r where r.story_id=s.id))
 from public.stories s where s.deleted_at is null and s.expires_at>now() and exists(select 1 from public.story_reports r where r.story_id=s.id) order by s.created_at desc;
end; $$;
create function public.moderate_story(story_uuid uuid,hide boolean) returns void
language plpgsql security definer set search_path='' as $$
begin
 perform public.community_active_account();
 if not public.community_is_admin() then raise exception 'story_permission_denied'; end if;
 update public.stories set hidden=hide where id=story_uuid and deleted_at is null;
end; $$;

-- Private snapshots freeze ordering, including trending scores, across pages.
create table public.home_feed_snapshots (
 id uuid primary key default gen_random_uuid(),viewer_id uuid not null references public.profiles(id) on delete cascade,
 filters jsonb not null, entries jsonb not null,expires_at timestamptz not null default clock_timestamp()+interval '15 minutes'
);
create index home_feed_snapshots_expiration on public.home_feed_snapshots(expires_at);
alter table public.home_feed_snapshots enable row level security;
revoke all on public.home_feed_snapshots from anon,authenticated;
grant all on public.home_feed_snapshots to service_role;

-- Rank accepted participants by their acceptance event, not application age.
alter table public.mission_applications add column accepted_at timestamptz;
update public.mission_applications set accepted_at=created_at where status='accepted';
create function public.timestamp_mission_acceptance() returns trigger
language plpgsql set search_path='' as $$
begin
 if new.status='accepted' then
  if tg_op='INSERT' then new.accepted_at:=clock_timestamp();
  elsif old.status is distinct from new.status then new.accepted_at:=clock_timestamp();
  else new.accepted_at:=old.accepted_at; end if;
 else new.accepted_at:=null; end if;
 return new;
end; $$;
create trigger mission_acceptance_time before insert or update on public.mission_applications
for each row execute function public.timestamp_mission_acceptance();

create function public.home_feed_candidates(filters jsonb) returns table(kind text,id uuid,created_at timestamptz,content jsonb,score bigint)
language sql stable security definer set search_path='' as $$
 with viewer as (select p.interests from public.profiles p where p.id=auth.uid()),
 activity as (
 select 'post'::text kind,r.post_id id,r.user_id actor from public.post_reactions r where r.created_at>=now()-interval '7 days'
 union select 'post',c.post_id,c.author_id from public.post_comments c where c.created_at>=now()-interval '7 days'
 union select 'post',s.post_id,s.user_id from public.post_saves s where s.created_at>=now()-interval '7 days'
 union select 'mission',s.mission_id,s.user_id from public.mission_saves s where s.created_at>=now()-interval '7 days'
 union select 'mission',a.mission_id,a.applicant_id from public.mission_applications a where a.status='accepted' and a.accepted_at>=now()-interval '7 days'
 ), candidates as (
 select 'post'::text kind,p.id,p.created_at,to_jsonb(p) content,p.author_id,p.category,p.location_latitude lat,p.location_longitude lng from public.posts p where not p.hidden
 union all
 select 'mission',m.id,m.created_at,to_jsonb(m)||jsonb_build_object('accepted_count',(select count(*) from public.mission_applications a where a.mission_id=m.id and a.status='accepted'),'organizer_name',p.full_name,'organizer_username',p.username),m.author_id,m.category,m.location_latitude,m.location_longitude
 from public.missions m join public.profiles p on p.id=m.author_id where not m.hidden and m.status='open' and m.starts_at>now()
 )
 select c.kind,c.id,c.created_at,c.content,(select count(distinct a.actor) from activity a where a.kind=c.kind and a.id=c.id and a.actor<>c.author_id
 and not exists(select 1 from public.account_deletion_requests d where d.user_id=a.actor)) score
 from candidates c cross join viewer v
 where not exists(select 1 from public.account_deletion_requests d where d.user_id=c.author_id)
 and (coalesce(filters->>'kind','all')='all' or c.kind=filters->>'kind')
 and (filters->>'category' is null or c.category=filters->>'category')
 and (filters->>'mode'<>'forYou' or filters->>'category' is not null or cardinality(v.interests)=0 or c.category=any(v.interests))
 and (filters->>'mode'<>'following' or exists(select 1 from public.profile_follows f where f.follower_id=auth.uid() and f.author_id=c.author_id))
 and (filters->>'mode'<>'nearby' or (c.lat is not null and c.lng is not null and
 6371.0088*2*asin(sqrt(least(1.0,power(sin(radians(c.lat-(filters->>'latitude')::double precision)/2),2)+cos(radians(c.lat))*cos(radians((filters->>'latitude')::double precision))*power(sin(radians(c.lng-(filters->>'longitude')::double precision)/2),2))))<=(filters->>'radius_km')::double precision));
$$;
create function public.home_feed(filters jsonb,page_cursor jsonb default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); snapshot public.home_feed_snapshots; pos bigint:=0; rows jsonb; count_rows int; last_pos bigint;
begin
 if filters is null or jsonb_typeof(filters)<>'object' or coalesce(filters->>'mode','') not in ('forYou','nearby','following','trending')
 or coalesce(filters->>'kind','') not in ('all','post','mission') or coalesce((filters->>'radius_km')::int,0) not in (5,10,25,50)
 or (filters->>'category' is not null and filters->>'category' not in ('arte','musica','digital','gastronomia','moda','escritura','fotografia','diseno','otros')) then raise exception 'invalid_feed_filters'; end if;
 if filters->>'mode'='nearby' and (filters->>'latitude' is null or filters->>'longitude' is null
 or not ((filters->>'latitude')::double precision between -90 and 90) or not ((filters->>'longitude')::double precision between -180 and 180)) then raise exception 'invalid_feed_location'; end if;
 if page_cursor is null then
  delete from public.home_feed_snapshots where expires_at<=now();
  insert into public.home_feed_snapshots(viewer_id,filters,entries)
  select account,filters,coalesce(jsonb_agg(jsonb_build_object('kind',c.kind,'id',c.id) order by case when filters->>'mode'='trending' then c.score else 0 end desc,c.created_at desc,c.kind desc,c.id desc),'[]'::jsonb)
  from public.home_feed_candidates(filters) c where filters->>'mode'<>'trending' or c.score>0 returning * into snapshot;
 else
  select * into snapshot from public.home_feed_snapshots where id=(page_cursor->>'snapshot')::uuid and viewer_id=account and expires_at>now() and home_feed_snapshots.filters=home_feed.filters;
  if not found then raise exception 'feed_cursor_expired'; end if;
  pos:=(page_cursor->>'position')::bigint;
  if pos is null or pos<0 then raise exception 'invalid_feed_cursor'; end if;
 end if;
 with page as (
  select x.ordinality n,c.kind,c.content from jsonb_array_elements(snapshot.entries) with ordinality x(item,ordinality)
  join public.home_feed_candidates(filters) c on c.kind=x.item->>'kind' and c.id=(x.item->>'id')::uuid
  where x.ordinality>pos order by x.ordinality limit 31
 )
 select coalesce(jsonb_agg(jsonb_build_object('kind',kind,'content',content) order by n) filter(where row_number<=30),'[]'::jsonb),count(*)::int,max(n) filter(where row_number<=30)
 into rows,count_rows,last_pos from (select *,row_number() over(order by n) from page) numbered;
 return jsonb_build_object('entries',rows,'cursor',case when count_rows>30 then jsonb_build_object('snapshot',snapshot.id,'position',last_pos) else null end);
end; $$;

-- Only the cleanup worker may enumerate unused/expired objects.
create function public.story_cleanup_images() returns setof text
language sql security definer set search_path='' as $$
 select o.name from storage.objects o where o.bucket_id='story-images'
 and (exists(select 1 from public.stories s where s.image_path=o.name and (s.expires_at<=now() or s.deleted_at is not null))
 or (not exists(select 1 from public.stories s where s.image_path=o.name) and o.created_at<now()-interval '24 hours')) limit 200;
$$;
revoke all on function public.home_feed_candidates(jsonb),public.story_cleanup_images() from public,anon,authenticated;
grant execute on function public.story_cleanup_images() to service_role;
revoke all on function public.home_feed(jsonb,jsonb),public.set_profile_follow(uuid,boolean),public.publish_story(uuid,text,text),public.list_stories(),public.mark_story_seen(uuid),public.delete_story(uuid),public.report_story(uuid,text),public.reported_stories(),public.moderate_story(uuid,boolean) from public,anon,authenticated;
grant execute on function public.home_feed(jsonb,jsonb),public.set_profile_follow(uuid,boolean),public.publish_story(uuid,text,text),public.list_stories(),public.mark_story_seen(uuid),public.delete_story(uuid),public.report_story(uuid,text),public.reported_stories(),public.moderate_story(uuid,boolean) to authenticated;
