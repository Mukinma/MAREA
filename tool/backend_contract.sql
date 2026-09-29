-- Read-only release gate. No accounts or data are returned or modified.
select
  (select count(*) = 8 from supabase_migrations.schema_migrations
    where version in ('001','002','003','004','005','006','007','008')) as migrations_ready,
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
    ) as signup_trigger_ready;
