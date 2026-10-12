-- Android push is disabled until the worker and Firebase credentials are configured.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

alter table public.notifications alter column actor_id drop not null;
alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (kind in (
 'reaction','comment','interest','mission_application','mission_accepted','mission_rejected',
 'mission_withdrawn','mission_closed','mission_reopened','mission_cancelled','mission_completed','marea_message'));
alter table public.notifications drop constraint notifications_one_target;
alter table public.notifications add constraint notifications_one_target check (
 (kind='marea_message' and actor_id is null and num_nonnulls(post_id,mission_id)=0)
 or (kind<>'marea_message' and actor_id is not null and num_nonnulls(post_id,mission_id)=1));

create table public.notification_preferences (
 user_id uuid primary key references public.profiles(id) on delete cascade,
 activity_enabled boolean not null default true,
 marea_enabled boolean not null default true,
 timezone text not null default 'America/Mexico_City',
 last_seen_at timestamptz not null default clock_timestamp(),
 next_marea_at timestamptz
);
create table public.notification_devices (
 installation_id uuid primary key,
 user_id uuid not null references public.profiles(id) on delete cascade,
 token text not null unique check(length(token) between 20 and 4096),
 enabled boolean not null default false,
 updated_at timestamptz not null default clock_timestamp()
);
create table private.push_settings (
 singleton boolean primary key default true check(singleton),
 enabled boolean not null default false
);
insert into private.push_settings default values;
create table private.push_queue (
 id uuid primary key default gen_random_uuid(),
 notification_id uuid not null references public.notifications(id) on delete cascade,
 installation_id uuid not null references public.notification_devices(installation_id) on delete cascade,
 event_version timestamptz not null,
 status text not null default 'pending' check(status in ('pending','processing','sent','canceled','failed')),
 attempts integer not null default 0,
 scheduled_at timestamptz not null default clock_timestamp(),
 lease_id uuid, lease_until timestamptz, lease_token text,
 last_error text,
 unique(notification_id,event_version,installation_id)
);
create index push_queue_due on private.push_queue(scheduled_at) where status in ('pending','processing');
create index notification_devices_user on public.notification_devices(user_id) where enabled;
alter table public.notification_preferences enable row level security;
alter table public.notification_devices enable row level security;
alter table private.push_queue enable row level security;
alter table private.push_settings enable row level security;
revoke all on public.notification_preferences,public.notification_devices,private.push_queue,private.push_settings from public,anon,authenticated;
grant select on public.notification_preferences to authenticated;
grant all on public.notification_preferences,public.notification_devices,private.push_queue,private.push_settings to service_role;
grant usage on schema private to service_role;
create policy "Own notification preferences" on public.notification_preferences for select to authenticated using(user_id=auth.uid());

create function public.set_notification_preferences(activity boolean,marea_messages boolean) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 insert into public.notification_preferences(user_id,activity_enabled,marea_enabled)
 values(account,activity,marea_messages) on conflict(user_id) do update
 set activity_enabled=excluded.activity_enabled,marea_enabled=excluded.marea_enabled,
 next_marea_at=case when excluded.marea_enabled then public.notification_preferences.next_marea_at else null end;
 update private.push_queue q set status='canceled' from public.notifications n
 where q.notification_id=n.id and n.recipient_id=account and q.status in ('pending','processing')
 and ((n.kind='marea_message' and not marea_messages) or (n.kind<>'marea_message' and not activity));
end; $$;
create function public.record_notification_activity(zone text) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 if not exists(select 1 from pg_timezone_names where name=zone) then raise exception 'invalid_timezone'; end if;
 insert into public.notification_preferences(user_id,timezone,last_seen_at) values(account,zone,clock_timestamp())
 on conflict(user_id) do update set timezone=excluded.timezone,last_seen_at=excluded.last_seen_at,next_marea_at=null;
 update private.push_queue q set status='canceled' from public.notifications n
 where q.notification_id=n.id and n.recipient_id=account and n.kind='marea_message' and q.status in ('pending','processing');
end; $$;
create function public.register_notification_device(installation uuid,fcm_token text,permission_granted boolean) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account();
begin
 if installation is null or length(fcm_token) not between 20 and 4096 then raise exception 'invalid_device'; end if;
 insert into public.notification_devices(installation_id,user_id,token,enabled)
 values(installation,account,fcm_token,permission_granted)
 on conflict(installation_id) do update set user_id=excluded.user_id,token=excluded.token,
 enabled=excluded.enabled,updated_at=clock_timestamp()
 where public.notification_devices.user_id=account or public.notification_devices.token=fcm_token;
 if not found then raise exception 'device_owner_mismatch'; end if;
end; $$;
create function public.unregister_notification_device(installation uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
 delete from public.notification_devices where installation_id=installation and user_id=auth.uid();
end; $$;
revoke all on function public.set_notification_preferences(boolean,boolean),public.record_notification_activity(text),
 public.register_notification_device(uuid,text,boolean),public.unregister_notification_device(uuid) from public,anon;
grant execute on function public.set_notification_preferences(boolean,boolean),public.record_notification_activity(text),
 public.register_notification_device(uuid,text,boolean),public.unregister_notification_device(uuid) to authenticated;

-- Wake-ups are best effort; the durable queue survives network/pg_net outages.
create function private.wake_push_worker() returns void language plpgsql security definer set search_path='' as $$
declare worker_url text; worker_secret text;
begin
 if not (select enabled from private.push_settings where singleton) then return; end if;
 if to_regclass('vault.decrypted_secrets') is null or to_regnamespace('net') is null then return; end if;
 execute 'select decrypted_secret from vault.decrypted_secrets where name=$1' into worker_url using 'marea_push_url';
 execute 'select decrypted_secret from vault.decrypted_secrets where name=$1' into worker_secret using 'marea_push_worker_secret';
 if worker_url is null or worker_secret is null then return; end if;
 execute 'select net.http_post(url := $1, headers := $2, body := $3, timeout_milliseconds := 10000)'
 using worker_url,jsonb_build_object('Content-Type','application/json','x-marea-worker-secret',worker_secret),'{}'::jsonb;
exception when others then
 -- Do not make a comment/reaction fail because delivery is unavailable.
 return;
end; $$;
create function private.enqueue_notification_push() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if tg_op='UPDATE' and new.created_at=old.created_at then return new; end if;
 insert into public.notification_preferences(user_id) values(new.recipient_id) on conflict do nothing;
 insert into private.push_queue(notification_id,installation_id,event_version)
 select new.id,d.installation_id,new.created_at from public.notification_devices d
 join public.notification_preferences p on p.user_id=d.user_id
 where d.user_id=new.recipient_id and d.enabled
 and (case when new.kind='marea_message' then p.marea_enabled else p.activity_enabled end)
 on conflict do nothing;
 perform private.wake_push_worker();
 return new;
end; $$;
create trigger notification_push after insert or update of created_at on public.notifications
 for each row execute function private.enqueue_notification_push();

create function private.schedule_marea_messages(at_time timestamptz) returns void
language plpgsql security definer set search_path='' as $$
declare p public.notification_preferences; local_time timestamp; candidate timestamp;
 messages text[]:=array[
 '¿Qué anda creando esa cabecita? 👀 Tu próxima idea puede empezar en MAREA.',
 'Una idea pequeña también puede hacer olas 👀 ¿La compartimos en MAREA?',
 'Tu creatividad tiene lugar aquí 👀 Vuelve a MAREA cuando te nazca.'
 ];
begin
 if not (select enabled from private.push_settings where singleton) then return; end if;
 for p in select pref.* from public.notification_preferences pref
 where pref.marea_enabled and pref.last_seen_at<=at_time-interval '72 hours'
 and exists(select 1 from public.notification_devices d where d.user_id=pref.user_id and d.enabled)
 and not exists(select 1 from public.account_deletion_requests a where a.user_id=pref.user_id)
 and (select count(*) from public.notifications n where n.recipient_id=pref.user_id and n.kind='marea_message' and n.created_at>at_time-interval '7 days')<2
 and not exists(select 1 from public.notifications n where n.recipient_id=pref.user_id and n.kind='marea_message' and n.created_at>at_time-interval '72 hours')
 order by pref.last_seen_at limit 200 for update skip locked
 loop
  local_time:=at_time at time zone p.timezone;
  if p.next_marea_at is null then
   candidate:=date_trunc('day',local_time)+interval '10 hours'+random()*interval '9 hours';
   if candidate<=local_time then candidate:=date_trunc('day',local_time)+interval '1 day 10 hours'+random()*interval '9 hours'; end if;
   update public.notification_preferences set next_marea_at=candidate at time zone p.timezone where user_id=p.user_id;
  elsif p.next_marea_at<=at_time then
   -- A delayed worker must never deliver a reminder at night.
   if extract(hour from local_time)<10 or extract(hour from local_time)>=19 then
    update public.notification_preferences set next_marea_at=null where user_id=p.user_id;
    continue;
   end if;
   insert into public.notifications(recipient_id,actor_id,post_id,mission_id,kind,event_key,post_title,created_at)
   values(p.user_id,null,null,null,'marea_message','marea:'||p.user_id||':'||extract(epoch from at_time),
    messages[1+floor(random()*array_length(messages,1))::integer],at_time);
   update public.notification_preferences set next_marea_at=null where user_id=p.user_id;
  end if;
 end loop;
end; $$;

create function public.claim_push_jobs(batch_size integer default 20) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not (select enabled from private.push_settings where singleton) then return '[]'::jsonb; end if;
 perform private.schedule_marea_messages(clock_timestamp());
 update private.push_queue q set status='canceled' from public.notifications n,
 public.notification_devices d,public.notification_preferences p
 where q.notification_id=n.id and q.installation_id=d.installation_id and p.user_id=d.user_id
 and q.status in ('pending','processing') and (
  d.user_id<>n.recipient_id or n.created_at<>q.event_version or n.read_at is not null or not d.enabled
  or exists(select 1 from public.account_deletion_requests a where a.user_id=n.recipient_id)
  or (n.kind='marea_message' and (not p.marea_enabled or p.last_seen_at>n.created_at or p.last_seen_at>clock_timestamp()-interval '72 hours'))
  or (n.kind<>'marea_message' and not p.activity_enabled));
 update private.push_queue set status='failed',lease_id=null,lease_until=null,lease_token=null,
 last_error='lease_expired' where status='processing' and attempts>=5 and lease_until<clock_timestamp();
 with picked as (
  select q.id from private.push_queue q where q.attempts<5
  and q.scheduled_at<=clock_timestamp()
  and (q.status='pending' or (q.status='processing' and q.lease_until<clock_timestamp()))
  order by q.scheduled_at limit greatest(1,least(batch_size,50)) for update skip locked
 ), claimed as (
  update private.push_queue q set status='processing',attempts=attempts+1,
  lease_id=gen_random_uuid(),lease_until=clock_timestamp()+interval '2 minutes',
  lease_token=(select token from public.notification_devices d where d.installation_id=q.installation_id)
  from picked where q.id=picked.id returning q.*
 )
 select coalesce(jsonb_agg(jsonb_build_object('queue_id',q.id,'lease_id',q.lease_id,
 'notification_id',n.id,'recipient_id',n.recipient_id,'kind',n.kind,
 'event_version',q.event_version,'token',d.token,'title','MAREA',
 'ttl_seconds',case when n.kind='marea_message' then greatest(1,least(1800,extract(epoch from ((date_trunc('day',clock_timestamp() at time zone pref.timezone)+interval '19 hours') at time zone pref.timezone)-clock_timestamp()))::integer) else 86400 end,
 'body',case when n.kind='marea_message' then n.post_title else
 coalesce(actor.full_name,'Tu comunidad')||' '||case n.kind
 when 'reaction' then 'reaccionó a' when 'comment' then 'comentó en' when 'interest' then 'quiere colaborar en'
 when 'mission_application' then 'envió una candidatura a' when 'mission_accepted' then 'aceptó tu candidatura en'
 when 'mission_rejected' then 'revisó tu candidatura en' when 'mission_withdrawn' then 'retiró su candidatura de'
 when 'mission_closed' then 'cerró la convocatoria de' when 'mission_reopened' then 'reabrió la convocatoria de'
 when 'mission_cancelled' then 'canceló' when 'mission_completed' then 'finalizó' else 'actualizó' end||' «'||n.post_title||'».' end)), '[]'::jsonb)
 into result from claimed q join public.notifications n on n.id=q.notification_id
 join public.notification_devices d on d.installation_id=q.installation_id
 join public.notification_preferences pref on pref.user_id=n.recipient_id
 left join public.profiles actor on actor.id=n.actor_id;
 return result;
end; $$;
create function public.finish_push_job(job uuid,lease uuid,result text) returns void
language plpgsql security definer set search_path='' as $$
declare q private.push_queue;
begin
 select * into q from private.push_queue where id=job and lease_id=lease and status='processing' for update;
 if not found then return; end if;
 if result='invalid_token' then
  update public.notification_devices set enabled=false where installation_id=q.installation_id and token=q.lease_token;
  -- Rotation during delivery preserves the new token and retries this event.
  if not found then result:='retry'; end if;
 end if;
 update private.push_queue set status=case when result='sent' then 'sent'
 when result='canceled' then 'canceled' when result='retry' and attempts<5 then 'pending' else 'failed' end,
 scheduled_at=clock_timestamp()+least(3600,power(2,attempts)::integer*30)*interval '1 second',
 lease_id=null,lease_until=null,lease_token=null,last_error=case when result='sent' then null else left(result,100) end where id=job;
end; $$;
revoke all on function public.claim_push_jobs(integer),public.finish_push_job(uuid,uuid,text),
 private.schedule_marea_messages(timestamptz),private.wake_push_worker(),private.enqueue_notification_push() from public,anon,authenticated;
grant execute on function public.claim_push_jobs(integer),public.finish_push_job(uuid,uuid,text),
 private.schedule_marea_messages(timestamptz),private.wake_push_worker() to service_role;

-- Recheck cancellation/preferences/device ownership immediately before delivery.
create function public.push_job_is_current(job uuid,lease uuid) returns boolean
language sql security definer set search_path='' as $$
 select exists(select 1 from private.push_queue q
 join public.notifications n on n.id=q.notification_id
 join public.notification_devices d on d.installation_id=q.installation_id
 join public.notification_preferences p on p.user_id=n.recipient_id
 where q.id=job and q.lease_id=lease and q.status='processing'
 and q.lease_until>clock_timestamp() and n.created_at=q.event_version and n.read_at is null
 and d.enabled and d.user_id=n.recipient_id
 and (select enabled from private.push_settings where singleton)
 and not exists(select 1 from public.account_deletion_requests a where a.user_id=n.recipient_id)
 and case when n.kind='marea_message' then p.marea_enabled
  and p.last_seen_at<=clock_timestamp()-interval '72 hours' and p.last_seen_at<n.created_at
  and extract(hour from clock_timestamp() at time zone p.timezone)>=10
  and extract(hour from clock_timestamp() at time zone p.timezone)<19
 else p.activity_enabled end);
$$;
revoke all on function public.push_job_is_current(uuid,uuid) from public,anon,authenticated;
grant execute on function public.push_job_is_current(uuid,uuid) to service_role;
