create table public.post_comments (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.posts(id) on delete cascade,
 author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 1000),
 operation_id uuid not null,
 created_at timestamptz not null default clock_timestamp(),
 unique(author_id,operation_id)
);
create index post_comments_time on public.post_comments(post_id,created_at desc,id desc);
alter table public.post_comments enable row level security;
revoke all on public.post_comments from anon,authenticated;
grant all on public.post_comments to service_role;
grant select on public.post_comments to authenticated;
create policy "Visible conversation" on public.post_comments for select to authenticated
 using(exists(select 1 from public.posts p where p.id=post_id and not p.hidden));

create function public.create_post_comment(post_uuid uuid,comment_body text,operation_uuid uuid) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); content public.posts; result uuid; prior public.post_comments;
begin
 content:=public.social_post(post_uuid);
 if operation_uuid is null or comment_body is null or char_length(btrim(comment_body)) not between 1 and 1000 then raise exception 'invalid_comment'; end if;
 select * into prior from public.post_comments where author_id=account and operation_id=operation_uuid;
 if found then
  if prior.post_id<>post_uuid or prior.body<>btrim(comment_body) then raise exception 'operation_conflict'; end if;
  return prior.id;
 end if;
 insert into public.post_comments(post_id,author_id,body,operation_id)
 values(post_uuid,account,btrim(comment_body),operation_uuid) returning id into result;
 if content.author_id<>account then
  insert into public.notifications(recipient_id,actor_id,post_id,kind,source_id,event_key,post_title)
  values(content.author_id,account,post_uuid,'comment',result,'comment:'||result,content.title);
 end if;
 return result;
end; $$;
create function public.delete_post_comment(comment_uuid uuid) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); comment public.post_comments; owner uuid;
begin
 select * into comment from public.post_comments where id=comment_uuid for update;
 if not found then raise exception 'comment_unavailable'; end if;
 select author_id into owner from public.posts where id=comment.post_id;
 if comment.author_id<>account and owner<>account and not public.community_is_admin() then raise exception 'comment_permission_denied'; end if;
 delete from public.notifications where kind='comment' and source_id=comment_uuid;
 delete from public.post_comments where id=comment_uuid;
end; $$;
create or replace function public.post_social_stats(post_ids uuid[]) returns table(
 post_id uuid,reaction_count bigint,comment_count bigint,my_reaction text,interest_sent boolean)
language plpgsql stable security invoker set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 return query select p.id,
 (select count(*) from public.post_reactions r where r.post_id=p.id),
 (select count(*) from public.post_comments c where c.post_id=p.id),
 (select r.kind from public.post_reactions r where r.post_id=p.id and r.user_id=auth.uid()),false
 from public.posts p where p.id=any(post_ids) and not p.hidden;
end; $$;
revoke all on function public.create_post_comment(uuid,text,uuid),public.delete_post_comment(uuid) from public,anon;
grant execute on function public.create_post_comment(uuid,text,uuid),public.delete_post_comment(uuid) to authenticated;
