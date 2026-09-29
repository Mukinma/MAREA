alter table public.posts add column allows_collaboration boolean not null default false;
grant insert(allows_collaboration),update(allows_collaboration) on public.posts to authenticated;
create table public.post_collaboration_interests (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.posts(id) on delete cascade,
 applicant_id uuid not null references public.profiles(id) on delete cascade,
 message text not null check(char_length(btrim(message)) between 1 and 1000),
 created_at timestamptz not null default clock_timestamp(),
 unique(post_id,applicant_id)
);
alter table public.post_collaboration_interests enable row level security;
revoke all on public.post_collaboration_interests from anon,authenticated;
grant all on public.post_collaboration_interests to service_role;
grant select on public.post_collaboration_interests to authenticated;
create policy "Interest participants" on public.post_collaboration_interests for select to authenticated
 using(applicant_id=auth.uid() or exists(select 1 from public.posts p where p.id=post_id and p.author_id=auth.uid()));
create function public.send_post_interest(post_uuid uuid,interest_message text) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); content public.posts; result uuid;
begin
 content:=public.social_post(post_uuid);
 if content.author_id=account then raise exception 'self_collaboration_denied'; end if;
 if not content.allows_collaboration then raise exception 'collaboration_closed'; end if;
 if interest_message is null or char_length(btrim(interest_message)) not between 1 and 1000 then raise exception 'invalid_interest'; end if;
 select id into result from public.post_collaboration_interests where post_id=post_uuid and applicant_id=account;
 if found then return result; end if;
 insert into public.post_collaboration_interests(post_id,applicant_id,message)
 values(post_uuid,account,btrim(interest_message)) returning id into result;
 insert into public.notifications(recipient_id,actor_id,post_id,kind,source_id,event_key,post_title)
 values(content.author_id,account,post_uuid,'interest',result,'interest:'||result,content.title);
 return result;
end; $$;
create or replace function public.post_social_stats(post_ids uuid[]) returns table(
 post_id uuid,reaction_count bigint,comment_count bigint,my_reaction text,interest_sent boolean)
language plpgsql stable security invoker set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 return query select p.id,
 (select count(*) from public.post_reactions r where r.post_id=p.id),
 (select count(*) from public.post_comments c where c.post_id=p.id),
 (select r.kind from public.post_reactions r where r.post_id=p.id and r.user_id=auth.uid()),
 exists(select 1 from public.post_collaboration_interests i where i.post_id=p.id and i.applicant_id=auth.uid())
 from public.posts p where p.id=any(post_ids) and not p.hidden;
end; $$;
revoke all on function public.send_post_interest(uuid,text) from public,anon;
grant execute on function public.send_post_interest(uuid,text) to authenticated;
