-- Read-only release gate. No accounts or data are returned or modified.
select
  (select count(*) = 11 from supabase_migrations.schema_migrations
    where version in ('001','002','003','004','005','006','007','008','009','010','011')) as migrations_ready,
  exists(select 1 from information_schema.columns
    where table_schema='public' and table_name='profiles' and column_name='setup_step'
      and data_type='integer' and is_nullable='NO') as guide_column_ready,
  exists(select 1 from information_schema.column_privileges
    where table_schema='public' and table_name='profiles' and column_name='setup_step'
      and grantee='authenticated' and privilege_type='UPDATE') as guide_grant_ready,
  coalesce(has_column_privilege('authenticated','public.profiles','interests','UPDATE'),false)
    and coalesce(has_column_privilege('authenticated','public.profiles','goals','UPDATE'),false) as preferences_grants_ready,
  position('cardinality(selected_interests)' in pg_get_functiondef('public.complete_initial_profile(text,text[],text[])'::regprocedure)) = 0
    and position('cardinality(selected_goals)' in pg_get_functiondef('public.complete_initial_profile(text,text[],text[])'::regprocedure)) = 0
    and has_function_privilege('authenticated','public.complete_initial_profile(text,text[],text[])','EXECUTE') as confirmation_ready,
  position('minimal-v1' in pg_get_functiondef('public.handle_new_user()'::regprocedure)) > 0
    and position('initial_profile_completed_at' in pg_get_functiondef('public.handle_new_user()'::regprocedure)) > 0
    and exists(select 1 from pg_trigger
      where tgrelid='auth.users'::regclass
        and tgfoid='public.handle_new_user()'::regprocedure
        and not tgisinternal and tgenabled in ('O','A')
        and (tgtype & 4) = 4 -- INSERT
        and (tgtype & 1) = 1 -- FOR EACH ROW
        and (tgtype & 2) = 0 and (tgtype & 64) = 0 -- AFTER, not BEFORE/INSTEAD OF
    ) as signup_trigger_ready,
  (select count(*)=4 from pg_class where oid in ('public.post_reactions'::regclass,'public.post_comments'::regclass,'public.post_collaboration_interests'::regclass,'public.notifications'::regclass) and relrowsecurity)
    and exists(select 1 from information_schema.columns where table_schema='public' and table_name='posts' and column_name='allows_collaboration' and is_nullable='NO') as social_tables_ready,
  (select bool_and(has_table_privilege('authenticated',name,'SELECT') and not has_table_privilege('authenticated',name,'INSERT') and not has_table_privilege('authenticated',name,'UPDATE') and not has_table_privilege('authenticated',name,'DELETE') and not has_table_privilege('anon',name,'SELECT')) from unnest(array['public.post_reactions','public.post_comments','public.post_collaboration_interests','public.notifications']) name)
    and has_column_privilege('authenticated','public.posts','allows_collaboration','UPDATE')
    and exists(select 1 from pg_policies where schemaname='public' and tablename='notifications' and qual like '%recipient_id%auth.uid()%') as social_permissions_ready,
  (select bool_and(has_function_privilege('authenticated',signature,'EXECUTE') and not has_function_privilege('anon',signature,'EXECUTE')) from unnest(array['public.post_social_stats(uuid[])','public.set_post_reaction(uuid,text)','public.mark_notifications_read(uuid,timestamp with time zone)','public.create_post_comment(uuid,text,uuid)','public.delete_post_comment(uuid)','public.send_post_interest(uuid,text)']) signature)
    and not has_function_privilege('authenticated','public.social_post(uuid)','EXECUTE')
    and exists(select 1 from pg_trigger where tgrelid='public.post_reactions'::regclass and tgfoid='public.notify_post_reaction()'::regprocedure and tgenabled in ('O','A')) as social_functions_ready,
  exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='notifications') as realtime_ready;
