-- Mission conversations use the existing reaction/comment notification kinds so
-- older clients continue to parse inbox events during rollout.
create table public.mission_reactions (
 mission_id uuid not null references public.missions(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 kind text not null check(kind in ('like','inspire','support')),
 created_at timestamptz not null default clock_timestamp(),
 primary key(mission_id,user_id)
);
create table public.mission_comments (
 id uuid primary key default gen_random_uuid(),
 mission_id uuid not null references public.missions(id) on delete cascade,
 author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 1000),
 operation_id uuid not null,
 created_at timestamptz not null default clock_timestamp(),
 unique(author_id,operation_id)
);
-- Compact receipts prevent a delayed retry from recreating a moderated comment.
-- No comment text survives moderation in this private operation journal.
create table public.mission_comment_operations (
 author_id uuid not null references public.profiles(id) on delete cascade,
 operation_id uuid not null,
 mission_id uuid not null references public.missions(id) on delete cascade,
 comment_id uuid not null,
 payload_hash text not null,
 primary key(author_id,operation_id)
);
alter table public.mission_comment_operations enable row level security;
revoke all on public.mission_comment_operations from anon,authenticated;
grant all on public.mission_comment_operations to service_role;
create index mission_comments_time on public.mission_comments(mission_id,created_at desc,id desc);
alter table public.mission_reactions enable row level security;
alter table public.mission_comments enable row level security;
revoke all on public.mission_reactions,public.mission_comments from anon,authenticated;
grant select on public.mission_reactions,public.mission_comments to authenticated;
grant all on public.mission_reactions,public.mission_comments to service_role;

create function public.mission_social_visible(mission_uuid uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null
 and not exists(select 1 from public.account_deletion_requests where user_id=auth.uid())
 and exists(select 1 from public.missions m where m.id=mission_uuid and not m.hidden
 and not exists(select 1 from public.account_deletion_requests d where d.user_id=m.author_id));
$$;
revoke all on function public.mission_social_visible(uuid) from public,anon;
grant execute on function public.mission_social_visible(uuid) to authenticated;
create policy "Visible mission reactions" on public.mission_reactions for select to authenticated
 using(public.mission_social_visible(mission_id) and public.showcase_owner_visible(user_id));
create policy "Visible mission conversation" on public.mission_comments for select to authenticated
 using(public.mission_social_visible(mission_id) and public.showcase_owner_visible(author_id));
-- A shared row lock keeps hiding/deletion from racing a social write.
create function public.social_mission(mission_uuid uuid) returns public.missions
language plpgsql security definer set search_path='' as $$
declare content public.missions;
begin
 perform public.community_active_account();
 select * into content from public.missions m where m.id=mission_uuid and not m.hidden for share;
 if not found then raise exception 'mission_unavailable'; end if;
 if exists(select 1 from public.account_deletion_requests d where d.user_id=content.author_id) then raise exception 'mission_unavailable'; end if;
 return content;
end; $$;
revoke all on function public.social_mission(uuid) from public,anon,authenticated;

create function public.notify_mission_reaction() returns trigger
language plpgsql security definer set search_path='' as $$
declare recipient uuid; title text; event text;
begin
 if tg_op='DELETE' then
  delete from public.notifications where event_key='mission_reaction:'||old.mission_id||':'||old.user_id;
  return old;
 end if;
 if tg_op='UPDATE' and old.kind=new.kind then return new; end if;
 select m.author_id,m.title into recipient,title from public.missions m where m.id=new.mission_id;
 if recipient<>new.user_id then
  event:='mission_reaction:'||new.mission_id||':'||new.user_id;
  insert into public.notifications(recipient_id,actor_id,mission_id,kind,event_key,post_title)
  values(recipient,new.user_id,new.mission_id,'reaction',event,title)
  on conflict(event_key) do update set created_at=clock_timestamp(),read_at=null;
 end if;
 return new;
end; $$;
revoke all on function public.notify_mission_reaction() from public,anon,authenticated;
create trigger mission_reaction_notification after insert or update or delete on public.mission_reactions
for each row execute function public.notify_mission_reaction();

create function public.set_mission_reaction(mission_uuid uuid,reaction_type text) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 perform public.social_mission(mission_uuid);
 if reaction_type is null then
  delete from public.mission_reactions where mission_id=mission_uuid and user_id=account;
 elsif reaction_type in ('like','inspire','support') then
  insert into public.mission_reactions(mission_id,user_id,kind) values(mission_uuid,account,reaction_type)
  on conflict(mission_id,user_id) do update set kind=excluded.kind;
 else raise exception 'invalid_reaction'; end if;
end; $$;

create function public.create_mission_comment(mission_uuid uuid,comment_body text,operation_uuid uuid) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); content public.missions; prior public.mission_comment_operations; result uuid; fingerprint text;
begin
 if operation_uuid is null or comment_body is null or char_length(btrim(comment_body)) not between 1 and 1000 then raise exception 'invalid_comment'; end if;
 -- Serialize the receipt check and insert for concurrent retries from one author.
 perform pg_advisory_xact_lock(hashtextextended(account::text||':'||operation_uuid::text,0));
 content:=public.social_mission(mission_uuid);
 fingerprint:=encode(sha256(convert_to(btrim(comment_body),'UTF8')),'hex');
 select * into prior from public.mission_comment_operations where author_id=account and operation_id=operation_uuid;
 if found then
  if prior.mission_id<>mission_uuid or prior.payload_hash<>fingerprint then raise exception 'operation_conflict'; end if;
  return prior.comment_id;
 end if;
 insert into public.mission_comments(mission_id,author_id,body,operation_id)
 values(mission_uuid,account,btrim(comment_body),operation_uuid) returning id into result;
 insert into public.mission_comment_operations(author_id,operation_id,mission_id,comment_id,payload_hash)
 values(account,operation_uuid,mission_uuid,result,fingerprint);
 if content.author_id<>account then
  insert into public.notifications(recipient_id,actor_id,mission_id,kind,source_id,event_key,post_title)
  values(content.author_id,account,mission_uuid,'comment',result,'mission_comment:'||result,content.title);
 end if;
 return result;
end; $$;
create function public.retract_mission_comment_notification() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 delete from public.notifications where mission_id=old.mission_id and kind='comment' and source_id=old.id;
 return old;
end; $$;
revoke all on function public.retract_mission_comment_notification() from public,anon,authenticated;
create trigger mission_comment_notification_delete after delete on public.mission_comments
for each row execute function public.retract_mission_comment_notification();

create function public.delete_mission_comment(comment_uuid uuid) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); comment public.mission_comments; owner uuid;
begin
 select * into comment from public.mission_comments where id=comment_uuid for update;
 if not found then raise exception 'comment_unavailable'; end if;
 select author_id into owner from public.missions where id=comment.mission_id;
 if comment.author_id<>account and owner<>account and not public.community_is_admin() then raise exception 'comment_permission_denied'; end if;
 delete from public.mission_comments where id=comment_uuid;
end; $$;
create function public.mission_social_stats(mission_ids uuid[]) returns table(
 mission_id uuid,reaction_count bigint,comment_count bigint,my_reaction text)
language plpgsql stable security invoker set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 return query select m.id,
 (select count(*) from public.mission_reactions r where r.mission_id=m.id),
 (select count(*) from public.mission_comments c where c.mission_id=m.id),
 (select r.kind from public.mission_reactions r where r.mission_id=m.id and r.user_id=auth.uid())
 from public.missions m where m.id=any(mission_ids) and public.mission_social_visible(m.id);
end; $$;
revoke all on function public.set_mission_reaction(uuid,text),public.create_mission_comment(uuid,text,uuid),public.delete_mission_comment(uuid),public.mission_social_stats(uuid[]) from public,anon;
grant execute on function public.set_mission_reaction(uuid,text),public.create_mission_comment(uuid,text,uuid),public.delete_mission_comment(uuid),public.mission_social_stats(uuid[]) to authenticated;

-- Add mission conversation activity to the same distinct-actor ranking. Only
-- candidate scores change: existing home_feed snapshots retain their ordering.
create or replace function public.home_feed_candidates(filters jsonb) returns table(kind text,id uuid,created_at timestamptz,content jsonb,score bigint)
language sql stable security definer set search_path='' as $$
 with viewer as (select p.interests from public.profiles p where p.id=auth.uid()),
 activity as (
 select 'post'::text kind,r.post_id id,r.user_id actor from public.post_reactions r where r.created_at>=now()-interval '7 days'
 union select 'post',c.post_id,c.author_id from public.post_comments c where c.created_at>=now()-interval '7 days'
 union select 'post',s.post_id,s.user_id from public.post_saves s where s.created_at>=now()-interval '7 days'
 union select 'mission',s.mission_id,s.user_id from public.mission_saves s where s.created_at>=now()-interval '7 days'
 union select 'mission',a.mission_id,a.applicant_id from public.mission_applications a where a.status='accepted' and a.accepted_at>=now()-interval '7 days'
 union select 'mission',r.mission_id,r.user_id from public.mission_reactions r where r.created_at>=now()-interval '7 days'
 union select 'mission',c.mission_id,c.author_id from public.mission_comments c where c.created_at>=now()-interval '7 days'
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
