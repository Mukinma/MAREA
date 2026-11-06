-- Refresh PostgREST after the story RPC signature and metadata migration.
select pg_notify('pgrst', 'reload schema');
