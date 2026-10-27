create or replace function public.reject_chat(conversation uuid) returns void
language plpgsql
security definer
set search_path=''
as $$
declare
 account uuid:=public.chat_active_account();
 requester uuid;
begin
 select c.requester_id
 into requester
 from public.chat_conversations c
 where c.id=conversation
   and c.recipient_id=account
   and c.status='pending';
 if requester is null then
   raise exception 'chat_action_unavailable';
 end if;

 update public.chat_conversations
 set status='rejected',
     blocked_until=null
 where id=conversation
   and recipient_id=account
   and status='pending';

 insert into public.notifications(
  recipient_id,actor_id,kind,source_id,event_key,post_title
 ) values(
  requester,account,'marea_message',conversation,
  'chat_rejected:'||conversation,
  'Solicitud de mensaje rechazada'
 )
 on conflict(event_key) do update set
  created_at=clock_timestamp(),
  read_at=null,
  actor_id=excluded.actor_id,
  post_title=excluded.post_title;
end;
$$;

revoke all on function public.reject_chat(uuid) from public,anon;
grant execute on function public.reject_chat(uuid) to authenticated;
