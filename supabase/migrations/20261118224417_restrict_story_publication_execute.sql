-- Refreshing the story function recreated PostgreSQL's default public execute grant.
revoke execute on function public.publish_story(uuid, text, text, text, text) from public, anon;
grant execute on function public.publish_story(uuid, text, text, text, text) to authenticated;
