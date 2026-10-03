-- Read-only release gate. No accounts or data are returned or modified.
select
  (select count(*)=4 from pg_class where oid=any(array[to_regclass('public.mission_drafts'),to_regclass('public.mission_saves'),to_regclass('public.mission_finalists'),to_regclass('public.mission_application_operations')]) and relrowsecurity)
    and exists(select 1 from information_schema.columns where table_schema='public' and table_name='missions' and column_name='compensation_type')
    and exists(select 1 from information_schema.columns where table_schema='public' and table_name='mission_applications' and column_name='evidence') as mission_tables_ready,
  (select bool_and(coalesce(has_table_privilege('authenticated',to_regclass(name),'SELECT'),false)
      and not coalesce(has_table_privilege('authenticated',to_regclass(name),'INSERT'),true)
      and not coalesce(has_table_privilege('authenticated',to_regclass(name),'UPDATE'),true)
      and not coalesce(has_table_privilege('authenticated',to_regclass(name),'DELETE'),true)
      and not coalesce(has_table_privilege('anon',to_regclass(name),'SELECT'),true))
    from unnest(array['public.mission_drafts','public.mission_saves','public.mission_finalists']) name)
    and exists(select 1 from pg_policies where schemaname='public' and tablename='mission_drafts' and qual like '%author_id%auth.uid()%')
    and exists(select 1 from pg_policies where schemaname='public' and tablename='mission_saves' and qual like '%user_id%auth.uid()%')
    and exists(select 1 from pg_policies where schemaname='public' and tablename='mission_finalists' and qual like '%author_id%auth.uid()%') as mission_permissions_ready,
  (select bool_and(coalesce(has_function_privilege('authenticated',to_regprocedure(signature),'EXECUTE'),false)
      and not coalesce(has_function_privilege('anon',to_regprocedure(signature),'EXECUTE'),true))
    from unnest(array['public.save_mission_draft(uuid,jsonb)','public.publish_mission_draft(uuid,jsonb)','public.delete_mission_draft(uuid)',
      'public.submit_mission_application(uuid,jsonb)','public.set_mission_saved(uuid,boolean)','public.set_mission_finalist(uuid,uuid,boolean)',
      'public.confirm_mission_selection(uuid,uuid[])','public.list_saved_missions(text,text,text,integer)']) signature)
    and exists(select 1 from pg_trigger where tgrelid='public.missions'::regclass and tgfoid=to_regprocedure('public.lock_mission_compensation()') and tgenabled in ('O','A')) as mission_functions_ready,
  exists(select 1 from information_schema.columns where table_schema='public' and table_name='notifications' and column_name='mission_id')
    and exists(select 1 from information_schema.columns where table_schema='public' and table_name='notifications' and column_name='post_id' and is_nullable='YES')
    and exists(select 1 from pg_constraint where conrelid='public.notifications'::regclass and conname='notifications_one_target')
    and exists(select 1 from pg_trigger where tgrelid='public.mission_applications'::regclass and tgfoid=to_regprocedure('public.notify_mission_application()') and tgenabled in ('O','A'))
    and exists(select 1 from pg_trigger where tgrelid='public.missions'::regclass and tgfoid=to_regprocedure('public.notify_mission_status()') and tgenabled in ('O','A')) as mission_notifications_ready,
  (select count(*) = 13 from supabase_migrations.schema_migrations
    where version in ('001','002','003','004','005','006','007','008','009','010','011','012','013')) as migrations_ready,
  coalesce(has_function_privilege('authenticated',
    to_regprocedure('public.list_map_missions(double precision,double precision,double precision,double precision,text,text,timestamp with time zone,timestamp with time zone,double precision,double precision,double precision)'),
    'EXECUTE'),false)
    and not coalesce(has_function_privilege('anon',
      to_regprocedure('public.list_map_missions(double precision,double precision,double precision,double precision,text,text,timestamp with time zone,timestamp with time zone,double precision,double precision,double precision)'),
      'EXECUTE'),true)
    and exists(select 1 from pg_indexes where schemaname='public' and indexname='missions_map_coordinates_idx')
    as map_contract_ready,
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
