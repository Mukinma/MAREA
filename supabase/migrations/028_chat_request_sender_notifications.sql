update public.notifications n
set actor_id = c.requester_id,
    post_title = 'Solicitud de mensaje'
from public.chat_conversations c
where n.kind = 'marea_message'
  and n.event_key = 'chat_request:' || c.id
  and c.requester_id is not null;

create or replace function public.request_chat(target uuid) returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
 account uuid:=public.chat_active_account();
 result uuid;
begin
 if target is null
    or target=account
    or not exists(select 1 from public.profiles where id=target) then
   raise exception 'chat_target_unavailable';
 end if;
 if exists(
  select 1
  from public.chat_blocks
  where (blocker_id=account and blocked_id=target)
     or (blocker_id=target and blocked_id=account)
 ) then
   raise exception 'chat_blocked';
 end if;
 select id into result
 from public.chat_conversations
 where (requester_id=account and recipient_id=target)
    or (requester_id=target and recipient_id=account);
 if result is null then
  insert into public.chat_conversations(requester_id,recipient_id)
  values(account,target)
  returning id into result;
  insert into public.notifications(
   recipient_id,actor_id,kind,source_id,event_key,post_title
  ) values(
   target,account,'marea_message',result,'chat_request:'||result,
   'Solicitud de mensaje'
  )
  on conflict(event_key) do nothing;
 end if;
 return result;
end;
$$;

revoke all on function public.request_chat(uuid) from public,anon;
grant execute on function public.request_chat(uuid) to authenticated;
