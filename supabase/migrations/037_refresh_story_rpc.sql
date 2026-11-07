-- Refresh PostgREST after the story RPC was repaired in production.
select pg_notify('pgrst', 'reload schema');
