-- Some projects recorded 030 while retaining the older Android push check.
-- Keep every valid legacy row, including actorless chat alerts, and allow
-- participants to be attributed on chat request and rejection notifications.
alter table public.notifications
  drop constraint notifications_one_target,
  add constraint notifications_one_target check (
    (kind = 'marea_message' and num_nonnulls(post_id, mission_id) = 0 and (
      actor_id is null or (
        strpos(event_key, ':') > 0
        and split_part(event_key, ':', 1) in ('chat_request', 'chat_rejected')
      )
    ))
    or (kind <> 'marea_message' and actor_id is not null
      and num_nonnulls(post_id, mission_id) = 1)
  );
