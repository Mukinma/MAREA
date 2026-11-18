alter table public.notification_preferences
  add column chat_enabled boolean not null default true,
  add column missions_enabled boolean not null default true,
  add column collaborations_enabled boolean not null default true,
  add column reactions_enabled boolean not null default true,
  add column comments_enabled boolean not null default true;

-- Preserve what was delivered under the original switches, including the chat
-- events that used the same wire kind as editorial reminders.
update public.notification_preferences
set chat_enabled = marea_enabled,
    missions_enabled = activity_enabled,
    collaborations_enabled = activity_enabled,
    reactions_enabled = activity_enabled,
    comments_enabled = activity_enabled;

alter table public.notification_devices
  add column session_id uuid references auth.sessions(id) on delete cascade;
create index notification_devices_session on public.notification_devices(session_id)
  where session_id is not null;

-- Existing installations and queued deliveries keep their state until the
-- device registers again. On revocation, suspend unattributed installations
-- for the affected account, because their original session is unknowable.
create function private.disable_unbound_push_after_session_delete()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.notification_devices
  set enabled = false
  where user_id = old.user_id and session_id is null and enabled;
  return old;
end;
$$;
revoke all on function private.disable_unbound_push_after_session_delete()
  from public, anon, authenticated;
create trigger disable_unbound_push_after_session_delete
after delete on auth.sessions for each row
execute function private.disable_unbound_push_after_session_delete();

create function private.push_category(event_kind text, event_key text) returns text
language sql immutable set search_path = '' as $$
  select case
    when event_kind = 'marea_message' then
      case when strpos(event_key, ':') > 0
        and split_part(event_key, ':', 1) in ('chat_message', 'chat_request', 'chat_rejected')
        then 'chat' else 'reminders' end
    when left(event_kind, 8) = 'mission_' then 'missions'
    when event_kind = 'interest' then 'collaborations'
    when event_kind = 'reaction' then 'reactions'
    when event_kind = 'comment' then 'comments'
  end;
$$;

create function private.push_category_enabled(
  prefs public.notification_preferences, category text
) returns boolean
language sql immutable set search_path = '' as $$
  select case category
    when 'chat' then prefs.chat_enabled
    when 'missions' then prefs.missions_enabled
    when 'collaborations' then prefs.collaborations_enabled
    when 'reactions' then prefs.reactions_enabled
    when 'comments' then prefs.comments_enabled
    when 'reminders' then prefs.marea_enabled
    else false
  end;
$$;

create function private.push_session_has_access(account uuid, session uuid) returns boolean
language sql stable set search_path = '' as $$
  select exists (
    select 1 from auth.sessions s
    where s.user_id = account
      and (s.not_after is null or s.not_after > statement_timestamp())
      and (session is null or s.id = session)
      and ((session is not null and s.aal::text = 'aal2') or not exists (
        select 1 from auth.mfa_factors f
        where f.user_id = account and f.status::text = 'verified'
      ))
  );
$$;

create function private.cancel_muted_push(prefs public.notification_preferences) returns void
language sql set search_path = '' as $$
  update private.push_queue q
  set status = 'canceled', lease_id = null, lease_until = null, lease_token = null
  from public.notifications n
  where q.notification_id = n.id and n.recipient_id = prefs.user_id
    and q.status in ('pending', 'processing')
    and not private.push_category_enabled(prefs, private.push_category(n.kind, n.event_key));
$$;

create function public.set_notification_category(category text, enabled boolean) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  account uuid := public.community_active_account();
  prefs public.notification_preferences;
begin
  if enabled is null or category is null or category not in (
    'chat', 'missions', 'collaborations', 'reactions', 'comments', 'reminders'
  ) then
    raise exception 'invalid_notification_category';
  end if;

  insert into public.notification_preferences(user_id) values (account)
  on conflict (user_id) do nothing;

  update public.notification_preferences p
  set chat_enabled = case when category = 'chat' then enabled else p.chat_enabled end,
      missions_enabled = case when category = 'missions' then enabled else p.missions_enabled end,
      collaborations_enabled = case when category = 'collaborations' then enabled else p.collaborations_enabled end,
      reactions_enabled = case when category = 'reactions' then enabled else p.reactions_enabled end,
      comments_enabled = case when category = 'comments' then enabled else p.comments_enabled end,
      marea_enabled = case when category = 'reminders' then enabled else p.marea_enabled end,
      next_marea_at = case when category = 'reminders' and not enabled then null else p.next_marea_at end
  where p.user_id = account
  returning p.* into prefs;

  -- The older UI displays community activity as enabled if any of its
  -- categories are enabled. Keep that projection in the same transaction.
  update public.notification_preferences p
  set activity_enabled = prefs.missions_enabled or prefs.collaborations_enabled
    or prefs.reactions_enabled or prefs.comments_enabled
  where p.user_id = account
  returning p.* into prefs;

  perform private.cancel_muted_push(prefs);
  return jsonb_build_object(
    'activity_enabled', prefs.activity_enabled,
    'chat_enabled', prefs.chat_enabled,
    'missions_enabled', prefs.missions_enabled,
    'collaborations_enabled', prefs.collaborations_enabled,
    'reactions_enabled', prefs.reactions_enabled,
    'comments_enabled', prefs.comments_enabled,
    'marea_enabled', prefs.marea_enabled
  );
end;
$$;

create or replace function public.set_notification_preferences(activity boolean, marea_messages boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  account uuid := public.community_active_account();
  prefs public.notification_preferences;
begin
  -- Older clients post both switches. Only a change in a bundled value
  -- should update the categories for that bundle.
  insert into public.notification_preferences as p (
    user_id, activity_enabled, marea_enabled, chat_enabled, missions_enabled,
    collaborations_enabled, reactions_enabled, comments_enabled
  ) values (
    account, activity, marea_messages, marea_messages, activity, activity, activity, activity
  )
  on conflict (user_id) do update set
    chat_enabled = case when p.marea_enabled <> excluded.marea_enabled then excluded.marea_enabled else p.chat_enabled end,
    missions_enabled = case when p.activity_enabled <> excluded.activity_enabled then excluded.activity_enabled else p.missions_enabled end,
    collaborations_enabled = case when p.activity_enabled <> excluded.activity_enabled then excluded.activity_enabled else p.collaborations_enabled end,
    reactions_enabled = case when p.activity_enabled <> excluded.activity_enabled then excluded.activity_enabled else p.reactions_enabled end,
    comments_enabled = case when p.activity_enabled <> excluded.activity_enabled then excluded.activity_enabled else p.comments_enabled end,
    next_marea_at = case when excluded.marea_enabled then p.next_marea_at else null end,
    activity_enabled = excluded.activity_enabled,
    marea_enabled = excluded.marea_enabled
  returning p.* into prefs;
  perform private.cancel_muted_push(prefs);
end;
$$;

create or replace function public.record_notification_activity(zone text) returns void
language plpgsql security definer set search_path = '' as $$
declare account uuid := public.community_active_account();
begin
  if not exists (select 1 from pg_timezone_names where name = zone) then
    raise exception 'invalid_timezone';
  end if;

  insert into public.notification_preferences(user_id, timezone, last_seen_at)
  values (account, zone, clock_timestamp())
  on conflict (user_id) do update set
    timezone = excluded.timezone, last_seen_at = excluded.last_seen_at, next_marea_at = null;

  update private.push_queue q
  set status = 'canceled', lease_id = null, lease_until = null, lease_token = null
  from public.notifications n
  where q.notification_id = n.id and n.recipient_id = account
    and private.push_category(n.kind, n.event_key) = 'reminders'
    and q.status in ('pending', 'processing');
end;
$$;

create or replace function public.register_notification_device(
  installation uuid, fcm_token text, permission_granted boolean
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  account uuid := public.community_active_account();
  current_session uuid := nullif(auth.jwt()->>'session_id', '')::uuid;
begin
  if current_session is null or not private.push_session_has_access(account, current_session) then
    raise exception 'session_invalid';
  end if;
  if installation is null or fcm_token is null or length(fcm_token) not between 20 and 4096 then
    raise exception 'invalid_device';
  end if;

  insert into public.notification_devices as d (
    installation_id, user_id, token, enabled, session_id
  ) values (installation, account, fcm_token, permission_granted, current_session)
  on conflict (installation_id) do update set
    user_id = excluded.user_id, token = excluded.token, enabled = excluded.enabled,
    session_id = excluded.session_id, updated_at = clock_timestamp()
  where d.user_id = account or d.token = fcm_token;

  if not found then raise exception 'device_owner_mismatch'; end if;
end;
$$;

create or replace function private.enqueue_notification_push() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and new.created_at = old.created_at then return new; end if;
  insert into public.notification_preferences(user_id) values (new.recipient_id)
  on conflict do nothing;

  insert into private.push_queue(notification_id, installation_id, event_version)
  select new.id, d.installation_id, new.created_at
  from public.notification_devices d
  join public.notification_preferences p on p.user_id = d.user_id
  where d.user_id = new.recipient_id and d.enabled
    and private.push_session_has_access(d.user_id, d.session_id)
    and private.push_category_enabled(p, private.push_category(new.kind, new.event_key))
  on conflict do nothing;

  if found then perform private.wake_push_worker(); end if;
  return new;
end;
$$;

create or replace function private.schedule_marea_messages(at_time timestamptz) returns void
language plpgsql security definer set search_path = '' as $$
declare
  p public.notification_preferences;
  local_time timestamp;
  candidate timestamp;
  messages text[] := array[
    '¿Qué anda creando esa cabecita? 👀 Tu próxima idea puede empezar en MAREA.',
    'Una idea pequeña también puede hacer olas 👀 ¿La compartimos en MAREA?',
    'Tu creatividad tiene lugar aquí 👀 Vuelve a MAREA cuando te nazca.'
  ];
begin
  if not (select enabled from private.push_settings where singleton) then return; end if;

  for p in select pref.* from public.notification_preferences pref
    where pref.marea_enabled and pref.last_seen_at <= at_time - interval '72 hours'
      and exists (
        select 1 from public.notification_devices d
        where d.user_id = pref.user_id and d.enabled
          and private.push_session_has_access(d.user_id, d.session_id)
      )
      and not exists (
        select 1 from public.account_deletion_requests a where a.user_id = pref.user_id
      )
      and (select count(*) from public.notifications n
           where n.recipient_id = pref.user_id
             and private.push_category(n.kind, n.event_key) = 'reminders'
             and n.created_at > at_time - interval '7 days') < 2
      and not exists (
        select 1 from public.notifications n
        where n.recipient_id = pref.user_id
          and private.push_category(n.kind, n.event_key) = 'reminders'
          and n.created_at > at_time - interval '72 hours'
      )
    order by pref.last_seen_at limit 200 for update skip locked
  loop
    local_time := at_time at time zone p.timezone;
    if p.next_marea_at is null then
      candidate := date_trunc('day', local_time) + interval '10 hours' + random() * interval '9 hours';
      if candidate <= local_time then
        candidate := date_trunc('day', local_time) + interval '1 day 10 hours' + random() * interval '9 hours';
      end if;
      update public.notification_preferences
      set next_marea_at = candidate at time zone p.timezone where user_id = p.user_id;
    elsif p.next_marea_at <= at_time then
      if extract(hour from local_time) < 10 or extract(hour from local_time) >= 19 then
        update public.notification_preferences set next_marea_at = null where user_id = p.user_id;
        continue;
      end if;
      insert into public.notifications (
        recipient_id, actor_id, post_id, mission_id, kind, event_key, post_title, created_at
      ) values (
        p.user_id, null, null, null, 'marea_message', 'marea:' || p.user_id || ':' || extract(epoch from at_time),
        messages[1 + floor(random() * array_length(messages, 1))::integer], at_time
      );
      update public.notification_preferences set next_marea_at = null where user_id = p.user_id;
    end if;
  end loop;
end;
$$;

create function private.push_job_allowed(
  n public.notifications, d public.notification_devices,
  prefs public.notification_preferences, event_version timestamptz, at_time timestamptz
) returns boolean
language sql stable set search_path = '' as $$
  select d.user_id = n.recipient_id and prefs.user_id = d.user_id
    and n.created_at = event_version and n.read_at is null and d.enabled
    and private.push_session_has_access(d.user_id, d.session_id)
    and not exists (
      select 1 from public.account_deletion_requests a where a.user_id = n.recipient_id
    )
    and private.push_category_enabled(prefs, category.value)
    and (category.value <> 'reminders' or (
      prefs.last_seen_at <= at_time - interval '72 hours'
      and prefs.last_seen_at < n.created_at
      and extract(hour from at_time at time zone prefs.timezone) >= 10
      and extract(hour from at_time at time zone prefs.timezone) < 19
    ))
  from (select private.push_category(n.kind, n.event_key) as value) category;
$$;

create or replace function public.claim_push_jobs(batch_size integer default 20) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  result jsonb;
  at_time timestamptz := clock_timestamp();
begin
  if not (select enabled from private.push_settings where singleton) then return '[]'::jsonb; end if;
  perform private.schedule_marea_messages(at_time);

  update private.push_queue q
  set status = 'canceled', lease_id = null, lease_until = null, lease_token = null
  from public.notifications n, public.notification_devices d, public.notification_preferences p
  where q.notification_id = n.id and q.installation_id = d.installation_id and p.user_id = d.user_id
    and q.status in ('pending', 'processing')
    and not private.push_job_allowed(n, d, p, q.event_version, at_time);

  update private.push_queue
  set status = 'failed', lease_id = null, lease_until = null, lease_token = null, last_error = 'lease_expired'
  where status = 'processing' and attempts >= 5 and lease_until < at_time;

  with picked as (
    select q.id from private.push_queue q
    join public.notifications n on n.id = q.notification_id
    where q.attempts < 5 and q.scheduled_at <= at_time
      and (q.status = 'pending' or (q.status = 'processing' and q.lease_until < at_time))
    order by case private.push_category(n.kind, n.event_key) when 'chat' then 0 when 'reminders' then 2 else 1 end,
             q.scheduled_at
    limit greatest(1, least(batch_size, 50)) for update of q skip locked
  ), claimed as (
    update private.push_queue q
    set status = 'processing', attempts = attempts + 1, lease_id = gen_random_uuid(),
        lease_until = at_time + interval '2 minutes',
        lease_token = (select token from public.notification_devices d where d.installation_id = q.installation_id)
    from picked where q.id = picked.id returning q.*
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'queue_id', q.id, 'lease_id', q.lease_id,
    'notification_id', n.id, 'recipient_id', n.recipient_id, 'kind', n.kind,
    'category', category.value, 'event_version', q.event_version, 'token', q.lease_token, 'title', 'MAREA',
    'ttl_seconds', case when category.value = 'reminders' then greatest(1, least(1800,
      extract(epoch from ((date_trunc('day', at_time at time zone prefs.timezone) +
        interval '19 hours') at time zone prefs.timezone) - at_time)
      ))::integer else 86400 end,
    'body', case when category.value in ('chat', 'reminders') then n.post_title else
      coalesce(actor.full_name, 'Tu comunidad') || ' ' || case n.kind
        when 'reaction' then 'reaccionó a' when 'comment' then 'comentó en' when 'interest' then 'quiere colaborar en'
        when 'mission_application' then 'envió una candidatura a' when 'mission_accepted' then 'aceptó tu candidatura en'
        when 'mission_rejected' then 'revisó tu candidatura en' when 'mission_withdrawn' then 'retiró su candidatura de'
        when 'mission_closed' then 'cerró la convocatoria de' when 'mission_reopened' then 'reabrió la convocatoria de'
        when 'mission_cancelled' then 'canceló' when 'mission_completed' then 'finalizó' else 'actualizó'
      end || ' «' || n.post_title || '».' end
  ) order by case category.value when 'chat' then 0 when 'reminders' then 2 else 1 end, q.scheduled_at), '[]'::jsonb)
  into result
  from claimed q join public.notifications n on n.id = q.notification_id
  join public.notification_devices d on d.installation_id = q.installation_id
  join public.notification_preferences prefs on prefs.user_id = d.user_id
  cross join lateral (select private.push_category(n.kind, n.event_key) as value) category
  left join public.profiles actor on actor.id = n.actor_id;
  return result;
end;
$$;

create or replace function public.push_job_is_current(job uuid, lease uuid) returns boolean
language sql security definer set search_path = '' as $$
  select exists (
    select 1 from private.push_queue q
    join public.notifications n on n.id = q.notification_id
    join public.notification_devices d on d.installation_id = q.installation_id
    join public.notification_preferences p on p.user_id = d.user_id
    where q.id = job and q.lease_id = lease and q.status = 'processing'
      and q.lease_until > clock_timestamp() and q.lease_token = d.token
      and (select enabled from private.push_settings where singleton)
      and private.push_job_allowed(n, d, p, q.event_version, clock_timestamp())
  );
$$;

revoke all on function private.push_category(text, text),
  private.push_category_enabled(public.notification_preferences, text),
  private.push_session_has_access(uuid, uuid),
  private.cancel_muted_push(public.notification_preferences),
  private.push_job_allowed(public.notifications, public.notification_devices,
    public.notification_preferences, timestamptz, timestamptz),
  public.set_notification_category(text, boolean)
from public, anon, authenticated;
grant execute on function public.set_notification_category(text, boolean) to authenticated;
