-- PostgREST cannot resolve publish_story while the legacy three-argument
-- overload exists alongside the metadata-aware five-argument RPC.
drop function if exists public.publish_story(uuid, text, text);

grant execute on function public.publish_story(uuid, text, text, text, text)
to authenticated;

select pg_notify('pgrst', 'reload schema');
select pg_notify('pgrst', 'reload config');
