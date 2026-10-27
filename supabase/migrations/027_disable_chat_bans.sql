delete from public.chat_bans;

update public.chat_conversations
set status = 'accepted',
    blocked_until = null
where status = 'blocked';

create or replace function public.chat_active_account() returns uuid
language plpgsql
stable
security definer
set search_path=''
as $$
begin
 if auth.uid() is null
    or exists(
      select 1
      from public.account_deletion_requests
      where user_id=auth.uid()
    ) then
   raise exception 'session_invalid';
 end if;
 return auth.uid();
end;
$$;

drop table if exists public.chat_banned_words;
drop table if exists public.chat_bans;

revoke all on function public.chat_active_account() from public,anon;
grant execute on function public.chat_active_account() to authenticated;
