-- Read-only readiness gate; never return decrypted secrets or account data.
select
 (select count(*)=4 from supabase_migrations.schema_migrations where version in ('016','017','018','019')) as migrations_ready,
 (select count(*)=6 and bool_and(relrowsecurity) from pg_class where oid in
  ('public.profile_follows'::regclass,'public.stories'::regclass,'public.story_views'::regclass,
   'public.story_reports'::regclass,'public.home_feed_snapshots'::regclass,'public.story_publications'::regclass)) as rls_ready,
 (select count(*)=9 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'
  and p.proname in ('home_feed','set_profile_follow','publish_story','list_stories','mark_story_seen','delete_story','report_story','reported_stories','moderate_story')
  and has_function_privilege('authenticated',p.oid,'EXECUTE') and not has_function_privilege('anon',p.oid,'EXECUTE')) as functions_ready,
 (not has_table_privilege('authenticated','public.home_feed_snapshots','SELECT')
  and not has_table_privilege('authenticated','public.stories','INSERT')
  and not has_table_privilege('authenticated','public.profile_follows','INSERT')
  and not has_table_privilege('authenticated','public.story_publications','SELECT')
  and not has_function_privilege('authenticated','public.story_cleanup_images()','EXECUTE')) as private_writes_ready,
 exists(select 1 from storage.buckets where id='story-images' and not public and file_size_limit=4194304) as storage_ready,
 exists(select 1 from information_schema.columns where table_schema='public' and table_name='mission_applications' and column_name='accepted_at') as acceptance_ready,
 exists(select 1 from cron.job where jobname='marea-story-cleanup' and schedule='0 * * * *' and active) as cleanup_schedule_ready,
 (select count(*)=2 from vault.secrets where name in ('marea_story_cleanup_url','marea_story_worker_secret')) as cleanup_config_ready;
