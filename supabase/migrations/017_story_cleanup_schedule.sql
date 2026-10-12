-- The worker secret stays in Vault and Edge Function secrets, never in Flutter.
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;
create function public.dispatch_story_cleanup() returns void
language plpgsql security definer set search_path='' as $$
declare endpoint text; secret text;
begin
 select decrypted_secret into endpoint from vault.decrypted_secrets where name='marea_story_cleanup_url' limit 1;
 select decrypted_secret into secret from vault.decrypted_secrets where name='marea_story_worker_secret' limit 1;
 if endpoint is null or secret is null then raise exception 'story_cleanup_not_configured'; end if;
 perform net.http_post(url:=endpoint,headers:=jsonb_build_object('Content-Type','application/json','x-story-worker-secret',secret),body:='{}'::jsonb,timeout_milliseconds:=10000);
end; $$;
revoke all on function public.dispatch_story_cleanup() from public,anon,authenticated;
select cron.schedule('marea-story-cleanup','0 * * * *','select public.dispatch_story_cleanup()');
