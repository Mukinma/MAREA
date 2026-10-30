delete from public.notifications
where event_key like 'chat_message:%';

create or replace function public.send_chat_message(conversation uuid,message_body text) returns uuid
language plpgsql security definer set search_path='' as $$
declare
 account uuid:=public.chat_active_account();
 target uuid;
 sender_name text;
 result uuid;
 clean text:=btrim(coalesce(message_body,''));
begin
 if char_length(clean) not between 1 and 2000 then
  raise exception 'invalid_chat_message';
 end if;
 select
  case when c.requester_id=account then c.recipient_id else c.requester_id end
 into target
 from public.chat_conversations c
 where c.id=conversation
   and account in (c.requester_id,c.recipient_id)
   and c.status='accepted'
   and (c.blocked_until is null or c.blocked_until<=clock_timestamp());
 if target is null then raise exception 'chat_unavailable'; end if;
 if exists(
  select 1 from public.chat_blocks
  where (blocker_id=account and blocked_id=target)
     or (blocker_id=target and blocked_id=account)
 ) then raise exception 'chat_blocked'; end if;
 select p.full_name into sender_name
 from public.profiles p
 where p.id=account;
 insert into public.chat_messages(conversation_id,sender_id,body)
 values(conversation,account,clean)
 returning id into result;
 update public.chat_conversations
 set last_message_at=clock_timestamp()
 where id=conversation;
 insert into public.notifications(
  recipient_id,actor_id,kind,source_id,event_key,post_title
 ) values(
  target,null,'marea_message',conversation,
  'chat_message:'||conversation,
  'Nuevos mensajes de '||coalesce(sender_name,'un usuario')
 )
 on conflict(event_key) do update set
  created_at=clock_timestamp(),
  read_at=null,
  post_title=excluded.post_title;
 return result;
end; $$;

revoke all on function public.send_chat_message(uuid,text) from public,anon;
grant execute on function public.send_chat_message(uuid,text) to authenticated;
