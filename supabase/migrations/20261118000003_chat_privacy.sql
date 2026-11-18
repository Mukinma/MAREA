create table public.chat_request_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  request_audience text not null default 'everyone'
    check (request_audience in ('everyone', 'following', 'nobody'))
);

alter table public.chat_request_preferences enable row level security;
revoke all on public.chat_request_preferences from public, anon, authenticated;
grant all on public.chat_request_preferences to service_role;

-- Either direction uses the same lock. Blocking and beginning, accepting or
-- sending in a chat all evaluate the relationship after acquiring it.
create function private.lock_chat_pair(first_user uuid, second_user uuid)
returns void language sql set search_path = '' as $$
  select pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    'marea-chat-pair:' || least(first_user, second_user)::text || ':' ||
    greatest(first_user, second_user)::text, 0
  ));
$$;

create function private.lock_chat_request_audience(account uuid)
returns void language sql set search_path = '' as $$
  select pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('marea-chat-audience:' || account::text, 0)
  );
$$;

create function private.chat_pair_is_blocked(first_user uuid, second_user uuid)
returns boolean language sql stable set search_path = '' as $$
  select exists (
    select 1 from public.chat_blocks
    where (blocker_id = first_user and blocked_id = second_user)
       or (blocker_id = second_user and blocked_id = first_user)
  );
$$;

revoke all on function private.lock_chat_pair(uuid, uuid),
  private.lock_chat_request_audience(uuid),
  private.chat_pair_is_blocked(uuid, uuid)
  from public, anon, authenticated;

create function public.get_chat_privacy() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  account uuid := public.chat_active_account();
  audience text;
  blocks jsonb;
begin
  select p.request_audience into audience
  from public.chat_request_preferences p where p.user_id = account;

  select jsonb_agg(
    jsonb_build_object('id', b.blocked_id, 'full_name', p.full_name, 'username', p.username)
    order by b.created_at desc, b.blocked_id
  ) into blocks
  from public.chat_blocks b
  left join public.profiles p on p.id = b.blocked_id and not exists (
    select 1 from public.account_deletion_requests d where d.user_id = p.id
  )
  where b.blocker_id = account;

  return jsonb_build_object(
    'request_audience', coalesce(audience, 'everyone'),
    'blocked_accounts', coalesce(blocks, '[]'::jsonb)
  );
end;
$$;

create function public.set_chat_request_audience(audience text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  account uuid := public.chat_active_account();
begin
  if audience is null or audience not in ('everyone', 'following', 'nobody') then
    raise exception 'invalid_chat_request_audience';
  end if;

  perform private.lock_chat_request_audience(account);
  insert into public.chat_request_preferences (user_id, request_audience)
  values (account, audience)
  on conflict (user_id) do update
  set request_audience = excluded.request_audience;
end;
$$;

revoke all on function public.get_chat_privacy(),
  public.set_chat_request_audience(text) from public, anon, authenticated;
grant execute on function public.get_chat_privacy(),
  public.set_chat_request_audience(text) to authenticated;

create or replace function public.request_chat(target uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  account uuid := public.chat_active_account();
  result uuid;
  audience text;
begin
  if target is null or target = account then
    raise exception 'chat_target_unavailable';
  end if;

  perform private.lock_chat_pair(account, target);
  if not exists (select 1 from public.profiles where id = target)
      or exists (select 1 from public.account_deletion_requests where user_id = target) then
    raise exception 'chat_target_unavailable';
  end if;
  if private.chat_pair_is_blocked(account, target) then raise exception 'chat_blocked'; end if;

  select c.id into result from public.chat_conversations c
  where (c.requester_id = account and c.recipient_id = target)
     or (c.requester_id = target and c.recipient_id = account)
  order by (c.status = 'accepted') desc, (c.status = 'pending') desc, c.created_at, c.id
  limit 1;
  if found then return result; end if;

  perform private.lock_chat_request_audience(target);
  select p.request_audience into audience
  from public.chat_request_preferences p where p.user_id = target;
  if audience = 'nobody' or (audience = 'following' and not exists (
    select 1 from public.profile_follows f where f.follower_id = target and f.author_id = account
  )) then
    raise exception 'chat_request_not_allowed';
  end if;

  insert into public.chat_conversations (requester_id, recipient_id)
  values (account, target) returning id into result;
  insert into public.notifications (recipient_id, actor_id, kind, source_id, event_key, post_title)
  values (target, account, 'marea_message', result, 'chat_request:' || result, 'Solicitud de mensaje')
  on conflict (event_key) do nothing;
  return result;
end;
$$;

create or replace function public.accept_chat(conversation uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  account uuid := public.chat_active_account();
  target uuid;
begin
  select c.requester_id into target from public.chat_conversations c
  where c.id = conversation and c.recipient_id = account;
  if not found then raise exception 'chat_action_unavailable'; end if;

  perform private.lock_chat_pair(account, target);
  if private.chat_pair_is_blocked(account, target) then raise exception 'chat_blocked'; end if;
  update public.chat_conversations set status = 'accepted'
  where id = conversation and recipient_id = account and status = 'pending';
  if not found then raise exception 'chat_action_unavailable'; end if;
end;
$$;

create or replace function public.send_chat_message(conversation uuid, message_body text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  account uuid := public.chat_active_account();
  target uuid;
  sender_name text;
  result uuid;
  clean text := btrim(coalesce(message_body, ''));
begin
  if char_length(clean) not between 1 and 2000 then raise exception 'invalid_chat_message'; end if;

  select case when c.requester_id = account then c.recipient_id else c.requester_id end
  into target from public.chat_conversations c
  where c.id = conversation and account in (c.requester_id, c.recipient_id);
  if not found then raise exception 'chat_unavailable'; end if;

  perform private.lock_chat_pair(account, target);
  if private.chat_pair_is_blocked(account, target) then raise exception 'chat_blocked'; end if;
  if not exists (
    select 1 from public.chat_conversations c where c.id = conversation and c.status = 'accepted'
      and (c.blocked_until is null or c.blocked_until <= clock_timestamp())
  ) then
    raise exception 'chat_unavailable';
  end if;

  clean := public.chat_censor_message(clean);
  select p.full_name into sender_name from public.profiles p where p.id = account;
  insert into public.chat_messages (conversation_id, sender_id, body)
  values (conversation, account, clean) returning id into result;
  update public.chat_conversations set last_message_at = clock_timestamp()
  where id = conversation;
  insert into public.notifications (recipient_id, actor_id, kind, source_id, event_key, post_title)
  values (target, null, 'marea_message', conversation, 'chat_message:' || conversation,
    'Hay mensajes nuevos de ' || coalesce(sender_name, 'un usuario'))
  on conflict (event_key) do update
  set created_at = clock_timestamp(), read_at = null, post_title = excluded.post_title;
  return result;
end;
$$;

create or replace function public.set_chat_block(target uuid, blocked boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  account uuid := public.chat_active_account();
begin
  if target is null or target = account or blocked is null then
    raise exception 'chat_target_unavailable';
  end if;

  perform private.lock_chat_pair(account, target);
  if blocked then
    insert into public.chat_blocks (blocker_id, blocked_id)
    values (account, target) on conflict do nothing;
  else
    delete from public.chat_blocks where blocker_id = account and blocked_id = target;
  end if;
end;
$$;

notify pgrst, 'reload schema';
