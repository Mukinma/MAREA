-- Authenticated social reactions and recipient-only notification events.
create table public.post_reactions (
 post_id uuid not null references public.posts(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 kind text not null check(kind in ('like','inspire','support')),
 created_at timestamptz not null default clock_timestamp(),
 primary key(post_id,user_id)
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(),
 recipient_id uuid not null references public.profiles(id) on delete cascade,
 actor_id uuid not null references public.profiles(id) on delete cascade,
 post_id uuid not null references public.posts(id) on delete cascade,
 kind text not null check(kind in ('reaction','comment','interest')),
 source_id uuid,
 event_key text not null unique,
 post_title text not null,
 created_at timestamptz not null default clock_timestamp(),
 read_at timestamptz,
 check(recipient_id<>actor_id)
);
create index notifications_recipient_time on public.notifications(recipient_id,created_at desc,id desc);
create index notifications_unread on public.notifications(recipient_id) where read_at is null;
alter table public.post_reactions enable row level security;
alter table public.notifications enable row level security;
revoke all on public.post_reactions,public.notifications from anon,authenticated;
grant all on public.post_reactions,public.notifications to service_role;
grant select on public.post_reactions,public.notifications to authenticated;
create policy "Visible reaction totals" on public.post_reactions for select to authenticated
 using(exists(select 1 from public.posts p where p.id=post_id and not p.hidden));
create policy "Recipient notifications" on public.notifications for select to authenticated
 using(recipient_id=auth.uid());

create function public.social_post(post_uuid uuid) returns public.posts
language plpgsql security definer set search_path='' as $$
declare content public.posts;
begin
 perform public.community_active_account();
 select * into content from public.posts where id=post_uuid and not hidden for share;
 if exists(select 1 from public.account_deletion_requests where user_id=content.author_id) then raise exception 'post_unavailable'; end if;
 if not found then raise exception 'post_unavailable'; end if;
 return content;
end; $$;
revoke all on function public.social_post(uuid) from public,anon,authenticated;

create function public.notify_post_reaction() returns trigger
language plpgsql security definer set search_path='' as $$
declare recipient uuid; title text; event text;
begin
 if tg_op='DELETE' then
  delete from public.notifications where event_key='reaction:'||old.post_id||':'||old.user_id;
  return old;
 end if;
 if tg_op='UPDATE' and old.kind=new.kind then return new; end if;
 select author_id,p.title into recipient,title from public.posts p where p.id=new.post_id;
 if recipient<>new.user_id then
  event := 'reaction:'||new.post_id||':'||new.user_id;
  insert into public.notifications(recipient_id,actor_id,post_id,kind,event_key,post_title)
   values(recipient,new.user_id,new.post_id,'reaction',event,title)
  on conflict(event_key) do update set created_at=clock_timestamp(),read_at=null;
 end if;
 return new;
end; $$;
revoke all on function public.notify_post_reaction() from public,anon,authenticated;
create trigger reaction_notification after insert or update or delete on public.post_reactions
 for each row execute function public.notify_post_reaction();

create function public.set_post_reaction(post_uuid uuid,reaction_type text) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 perform public.social_post(post_uuid);
 if reaction_type is null then
  delete from public.post_reactions where post_id=post_uuid and user_id=account;
 elsif reaction_type in ('like','inspire','support') then
  insert into public.post_reactions(post_id,user_id,kind) values(post_uuid,account,reaction_type)
   on conflict(post_id,user_id) do update set kind=excluded.kind;
 else raise exception 'invalid_reaction'; end if;
end; $$;

create function public.post_social_stats(post_ids uuid[]) returns table(
 post_id uuid,reaction_count bigint,comment_count bigint,my_reaction text,interest_sent boolean)
language plpgsql stable security invoker set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 return query select p.id,
 (select count(*) from public.post_reactions r where r.post_id=p.id),
 0::bigint,(select r.kind from public.post_reactions r where r.post_id=p.id and r.user_id=auth.uid()),false
 from public.posts p where p.id=any(post_ids) and not p.hidden;
end; $$;

create function public.mark_notifications_read(notification_uuid uuid default null,before_time timestamptz default null) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 if notification_uuid is null and before_time is null then raise exception 'notification_cutoff_required'; end if;
 update public.notifications set read_at=clock_timestamp()
 where recipient_id=account and read_at is null
 and ((notification_uuid is not null and id=notification_uuid)
   or (notification_uuid is null and created_at<=before_time));
end; $$;
revoke all on function public.set_post_reaction(uuid,text),public.post_social_stats(uuid[]),public.mark_notifications_read(uuid,timestamptz) from public,anon;
grant execute on function public.set_post_reaction(uuid,text),public.post_social_stats(uuid[]),public.mark_notifications_read(uuid,timestamptz) to authenticated;
do $$ begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
  alter publication supabase_realtime add table public.notifications;
 end if;
end $$;
