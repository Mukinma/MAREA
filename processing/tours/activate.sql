-- Apply only after deployment/credential validation. Never executed by migration.
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;
do $$declare old_job bigint;begin
 if not exists(select 1 from vault.decrypted_secrets where name='marea_tour_dispatch_url' and decrypted_secret~'^https://')
 or not exists(select 1 from vault.decrypted_secrets where name='marea_tour_worker_secret' and length(decrypted_secret)>=32) then raise exception 'configure_tour_vault_secrets';end if;
 for old_job in select jobid from cron.job where jobname='marea-tour-minute' loop perform cron.unschedule(old_job);end loop;
 perform cron.schedule('marea-tour-minute','* * * * *','select private.wake_tour_dispatcher()');
end$$;
select private.wake_tour_dispatcher();
-- Disable: select cron.unschedule(jobid) from cron.job where jobname='marea-tour-minute';
-- Remove/rotate the wake secret to disable insert-trigger dispatch as well.
