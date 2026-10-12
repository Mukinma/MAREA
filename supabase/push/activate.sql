-- Run as postgres after 014, worker secrets and compatible clients are verified.
-- Vault must contain marea_push_url and marea_push_worker_secret.
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

do $$
declare existing bigint;
begin
 if not exists(select 1 from vault.decrypted_secrets where name='marea_push_url')
 or not exists(select 1 from vault.decrypted_secrets where name='marea_push_worker_secret' and length(decrypted_secret)>=32) then
  raise exception 'Configure the two MAREA Vault secrets before activation';
 end if;
 for existing in select jobid from cron.job where jobname='marea-push-minute' loop
  perform cron.unschedule(existing);
 end loop;
 perform cron.schedule('marea-push-minute','* * * * *','select private.wake_push_worker()');
end $$;

-- The minute schedule advances retries and inactivity reminders without Flutter.
update private.push_settings set enabled=true where singleton;
select private.wake_push_worker();

-- Pause (also prevents immediate sends and creation of MAREA reminders):
-- update private.push_settings set enabled=false where singleton;
-- select cron.unschedule('marea-push-minute');
