-- Re-register the story RPC with the parameter names used by PostgREST.
-- Keeping the existing body avoids changing story publication behavior.
do $$
declare
  function_body text;
begin
  select p.prosrc
    into function_body
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'publish_story'
    and p.proargtypes = '2950 25 25 25 25'::oidvector;

  if function_body is null then
    raise exception 'publish_story RPC is missing';
  end if;

  execute format(
    'create or replace function public.publish_story(
       story_uuid uuid,
       story_body text,
       story_image text default null,
       story_category text default ''otros'',
       story_target_type text default null
     ) returns uuid
     language plpgsql security definer set search_path=''''
     as %L',
    function_body
  );
end;
$$;

grant execute on function public.publish_story(uuid, text, text, text, text)
to authenticated;

select pg_notify('pgrst', 'reload schema');
select pg_notify('pgrst', 'reload config');
