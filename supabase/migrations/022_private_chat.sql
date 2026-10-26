create table public.chat_conversations (
 id uuid primary key default gen_random_uuid(),
 requester_id uuid not null references public.profiles(id) on delete cascade,
 recipient_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','accepted','rejected','blocked')),
 blocked_until timestamptz,
 last_message_at timestamptz,
 created_at timestamptz not null default clock_timestamp(),
 check(requester_id<>recipient_id),
 unique(requester_id,recipient_id)
);
create table public.chat_messages (
 id uuid primary key default gen_random_uuid(),
 conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
 sender_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 2000),
 created_at timestamptz not null default clock_timestamp()
);
create table public.chat_blocks (
 blocker_id uuid not null references public.profiles(id) on delete cascade,
 blocked_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default clock_timestamp(),
 primary key(blocker_id,blocked_id),
 check(blocker_id<>blocked_id)
);
create table public.chat_reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null references public.profiles(id) on delete cascade,
 conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
 message_id uuid references public.chat_messages(id) on delete set null,
 reason text not null check(char_length(btrim(reason)) between 1 and 500),
 created_at timestamptz not null default clock_timestamp()
);
create table public.chat_bans (
 user_id uuid primary key references public.profiles(id) on delete cascade,
 banned_until timestamptz not null,
 reason text not null,
 created_at timestamptz not null default clock_timestamp()
);
create table public.chat_banned_words (word text primary key);
insert into public.chat_banned_words(word) values
 ('pendejo'),('pendeja'),('idiota'),('estupido'),('estupida'),
 ('cabron'),('cabrona'),('chingar'),('chingada'),('puto'),('puta')
on conflict do nothing;

create index chat_conversations_participants on public.chat_conversations(requester_id,recipient_id,last_message_at desc);
create index chat_messages_conversation_time on public.chat_messages(conversation_id,created_at asc,id asc);
alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_blocks enable row level security;
alter table public.chat_reports enable row level security;
alter table public.chat_bans enable row level security;
alter table public.chat_banned_words enable row level security;
revoke all on public.chat_conversations,public.chat_messages,public.chat_blocks,public.chat_reports,public.chat_bans,public.chat_banned_words from anon,authenticated;
grant select on public.chat_conversations,public.chat_messages to authenticated;
grant all on public.chat_conversations,public.chat_messages,public.chat_blocks,public.chat_reports,public.chat_bans,public.chat_banned_words to service_role;
create policy "Chat participants can read conversations" on public.chat_conversations for select to authenticated using(auth.uid() in (requester_id,recipient_id));
create policy "Chat participants can read messages" on public.chat_messages for select to authenticated using(exists(select 1 from public.chat_conversations c where c.id=conversation_id and auth.uid() in (c.requester_id,c.recipient_id)));

create or replace function public.chat_active_account() returns uuid
language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or exists(select 1 from public.account_deletion_requests where user_id=auth.uid()) then raise exception 'session_invalid'; end if;
 if exists(select 1 from public.chat_bans where user_id=auth.uid() and banned_until>clock_timestamp()) then raise exception 'chat_banned'; end if;
 return auth.uid();
end; $$;
create or replace function public.request_chat(target uuid) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.chat_active_account(); result uuid;
begin
 if target is null or target=account or not exists(select 1 from public.profiles where id=target) then raise exception 'chat_target_unavailable'; end if;
 if exists(select 1 from public.chat_blocks where (blocker_id=account and blocked_id=target) or (blocker_id=target and blocked_id=account)) then raise exception 'chat_blocked'; end if;
 select id into result from public.chat_conversations where (requester_id=account and recipient_id=target) or (requester_id=target and recipient_id=account);
 if result is null then
  insert into public.chat_conversations(requester_id,recipient_id) values(account,target) returning id into result;
  insert into public.notifications(recipient_id,actor_id,kind,source_id,event_key,post_title)
  values(target,null,'marea_message',result,'chat_request:'||result,'Nueva solicitud de chat')
  on conflict(event_key) do nothing;
 end if;
 return result;
end; $$;
create or replace function public.accept_chat(conversation uuid) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.chat_active_account();
begin
 update public.chat_conversations set status='accepted' where id=conversation and recipient_id=account and status='pending';
 if not found then raise exception 'chat_action_unavailable'; end if;
end; $$;
create or replace function public.reject_chat(conversation uuid) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.chat_active_account();
begin
 update public.chat_conversations set status='rejected' where id=conversation and recipient_id=account and status='pending';
 if not found then raise exception 'chat_action_unavailable'; end if;
end; $$;
create or replace function public.send_chat_message(conversation uuid,message_body text) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.chat_active_account(); target uuid; result uuid; clean text:=btrim(coalesce(message_body,''));
begin
 if char_length(clean) not between 1 and 2000 then raise exception 'invalid_chat_message'; end if;
 select case when requester_id=account then recipient_id else requester_id end into target
 from public.chat_conversations
 where id=conversation and account in (requester_id,recipient_id) and status='accepted'
 and (blocked_until is null or blocked_until<=clock_timestamp());
 if target is null then raise exception 'chat_unavailable'; end if;
 if exists(select 1 from public.chat_blocks where (blocker_id=account and blocked_id=target) or (blocker_id=target and blocked_id=account)) then raise exception 'chat_blocked'; end if;
 if exists(select 1 from public.chat_banned_words w where lower(clean) like '%'||lower(w.word)||'%') then
  insert into public.chat_bans(user_id,banned_until,reason) values(account,clock_timestamp()+interval '24 hours','Lenguaje vulgar en chat')
  on conflict(user_id) do update set banned_until=excluded.banned_until,reason=excluded.reason;
  update public.chat_conversations set status='blocked',blocked_until=clock_timestamp()+interval '24 hours' where id=conversation;
  raise exception 'vulgar_language';
 end if;
 insert into public.chat_messages(conversation_id,sender_id,body) values(conversation,account,clean) returning id into result;
 update public.chat_conversations set last_message_at=clock_timestamp() where id=conversation;
 insert into public.notifications(recipient_id,actor_id,kind,source_id,event_key,post_title)
 values(target,null,'marea_message',conversation,'chat_message:'||result,'Nuevo mensaje')
 on conflict(event_key) do nothing;
 return result;
end; $$;
create or replace function public.set_chat_block(target uuid,blocked boolean) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.chat_active_account();
begin
 if target is null or target=account then raise exception 'chat_target_unavailable'; end if;
 if blocked then insert into public.chat_blocks(blocker_id,blocked_id) values(account,target) on conflict do nothing;
 else delete from public.chat_blocks where blocker_id=account and blocked_id=target; end if;
end; $$;
create or replace function public.report_chat(conversation uuid,message uuid,report_reason text) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.chat_active_account(); result uuid;
begin
 if not exists(select 1 from public.chat_conversations where id=conversation and account in(requester_id,recipient_id)) then raise exception 'chat_unavailable'; end if;
 insert into public.chat_reports(reporter_id,conversation_id,message_id,reason) values(account,conversation,message,btrim(report_reason)) returning id into result;
 return result;
end; $$;
revoke all on function public.chat_active_account(),public.request_chat(uuid),public.accept_chat(uuid),public.reject_chat(uuid),public.send_chat_message(uuid,text),public.set_chat_block(uuid,boolean),public.report_chat(uuid,uuid,text) from public,anon;
grant execute on function public.request_chat(uuid),public.accept_chat(uuid),public.reject_chat(uuid),public.send_chat_message(uuid,text),public.set_chat_block(uuid,boolean),public.report_chat(uuid,uuid,text) to authenticated;
