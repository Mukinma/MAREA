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
 insert into public.chat_messages(conversation_id,sender_id,body) values(conversation,account,clean) returning id into result;
 update public.chat_conversations set last_message_at=clock_timestamp() where id=conversation;
 insert into public.notifications(recipient_id,actor_id,kind,source_id,event_key,post_title)
 values(target,null,'marea_message',conversation,'chat_message:'||result,'Nuevo mensaje')
 on conflict(event_key) do nothing;
 return result;
end; $$;
revoke all on function public.send_chat_message(uuid,text) from public,anon;
grant execute on function public.send_chat_message(uuid,text) to authenticated;
