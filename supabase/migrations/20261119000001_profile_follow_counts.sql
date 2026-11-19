begin;

create index profile_follows_author_idx
  on public.profile_follows (author_id, follower_id);

-- The directory can show totals without changing who can read individual follows.
create function public.profile_follow_counts(profile_uuid uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  perform public.community_active_account();
  if not public.showcase_owner_visible(profile_uuid) then return null; end if;
  return jsonb_build_object(
    'followers', (
      select count(*) from public.profile_follows f
      where f.author_id = profile_uuid and not exists (
        select 1 from public.account_deletion_requests d where d.user_id = f.follower_id
      )
    ),
    'following', (
      select count(*) from public.profile_follows f
      where f.follower_id = profile_uuid and not exists (
        select 1 from public.account_deletion_requests d where d.user_id = f.author_id
      )
    )
  );
end;
$$;

revoke all on function public.profile_follow_counts(uuid) from public, anon, authenticated;
grant execute on function public.profile_follow_counts(uuid) to authenticated;
notify pgrst, 'reload schema';

commit;
