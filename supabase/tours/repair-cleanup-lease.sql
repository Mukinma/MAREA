-- Additive correction to015, for already-migrated deployments. No table/data
-- rewrite or other migration; apply after015. Fresh deployments include this
-- exact RPC in015. Only service_role can renew a still-owned GC reservation.
create or replace function public.tours_renew_cleanup(p_job uuid,p_lease uuid) returns boolean
language plpgsql security definer set search_path='' as $$
begin
 perform pg_catalog.pg_advisory_xact_lock(360180);
 update private.tour_output_writes w set expires_at=clock_timestamp()+interval '60 seconds'
 where w.job_id=p_job and w.lease_id=p_lease and w.expires_at>clock_timestamp()
 and exists(select 1 from private.tour_jobs j where j.id=w.job_id and j.cleanup_needed and j.state in ('queued','failed','cancelled'));
 return found;
end$$;
revoke all on function public.tours_renew_cleanup(uuid,uuid) from public,anon,authenticated;
grant execute on function public.tours_renew_cleanup(uuid,uuid) to service_role;
