alter table public.notifications
drop constraint notifications_one_target;

alter table public.notifications
add constraint notifications_one_target check (
  (
    kind='marea_message'
    and event_key like 'chat_request:%'
    and actor_id is not null
    and num_nonnulls(post_id,mission_id)=0
  )
  or (
    kind='marea_message'
    and event_key like 'chat_rejected:%'
    and actor_id is not null
    and num_nonnulls(post_id,mission_id)=0
  )
  or (
    kind='marea_message'
    and actor_id is null
    and num_nonnulls(post_id,mission_id)=0
    and event_key not like 'chat_request:%'
    and event_key not like 'chat_rejected:%'
  )
  or (
    kind<>'marea_message'
    and actor_id is not null
    and num_nonnulls(post_id,mission_id)=1
  )
);
