-- Keep an account-scoped receipt when reported content is removed.
create table public.profile_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_profile_id uuid references public.profiles(id) on delete set null,
  reason text not null check (char_length(btrim(reason)) between 5 and 500),
  state text not null default 'open' check (state in ('open', 'resolved')),
  created_at timestamptz not null default clock_timestamp(),
  check (reporter_id <> target_profile_id),
  unique (reporter_id, target_profile_id)
);

create table public.report_receipts (
  id uuid primary key,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('account', 'post', 'mission', 'showcase')),
  state text not null check (state in ('open', 'resolved')),
  target_unavailable boolean not null default false,
  created_at timestamptz not null
);

create index profile_reports_newest on public.profile_reports(created_at desc, id desc);
create index report_receipts_owner_newest
  on public.report_receipts(reporter_id, created_at desc, id desc);

alter table public.profile_reports enable row level security;
alter table public.report_receipts enable row level security;
revoke all on public.profile_reports, public.report_receipts from public, anon, authenticated;
grant select on public.profile_reports, public.report_receipts to authenticated;
grant all on public.profile_reports, public.report_receipts to service_role;

create policy "Moderators read account reports"
  on public.profile_reports for select to authenticated
  using ((select public.community_is_admin()));
create policy "Own report receipts"
  on public.report_receipts for select to authenticated
  using (reporter_id = (select auth.uid()));

create function private.sync_report_receipt() returns trigger
language plpgsql security definer set search_path = '' as $$
declare report_kind text; unavailable boolean := false;
begin
  if tg_op = 'DELETE' then
    update public.report_receipts set target_unavailable = true where id = old.id;
    return old;
  end if;
  if tg_table_name = 'profile_reports' then
    report_kind := 'account';
    unavailable := new.target_profile_id is null;
  elsif new.post_id is not null then
    report_kind := 'post';
  elsif new.mission_id is not null then
    report_kind := 'mission';
  else
    report_kind := 'showcase';
  end if;

  insert into public.report_receipts(id, reporter_id, kind, state, target_unavailable, created_at)
  values(new.id, new.reporter_id, report_kind, new.state, unavailable, new.created_at)
  on conflict (id) do update
    set state = excluded.state, target_unavailable = excluded.target_unavailable;
  return new;
end;
$$;
revoke all on function private.sync_report_receipt() from public, anon, authenticated;

create trigger sync_content_report_receipt
  after insert or update of state or delete on public.content_reports
  for each row execute function private.sync_report_receipt();
create trigger sync_profile_report_receipt
  after insert or update of state, target_profile_id or delete on public.profile_reports
  for each row execute function private.sync_report_receipt();

insert into public.report_receipts(id, reporter_id, kind, state, created_at)
select id, reporter_id,
  case when post_id is not null then 'post' when mission_id is not null then 'mission' else 'showcase' end,
  state, created_at
from public.content_reports
on conflict (id) do nothing;

create function public.report_profile(target_profile uuid, reason_text text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare account uuid := public.community_active_account(); result uuid;
begin
  if target_profile is null or target_profile = account
     or not exists(select 1 from public.profiles where id = target_profile)
     or exists(select 1 from public.account_deletion_requests where user_id = target_profile)
     or char_length(btrim(coalesce(reason_text, ''))) not between 5 and 500 then
    raise exception 'invalid_account_report';
  end if;

  insert into public.profile_reports(reporter_id, target_profile_id, reason)
    values(account, target_profile, btrim(reason_text))
    on conflict (reporter_id, target_profile_id) do nothing
    returning id into result;
  if result is null then
    select id into result from public.profile_reports
      where reporter_id = account and target_profile_id = target_profile;
  end if;
  return result;
end;
$$;

create function public.mark_report_reviewed(report_uuid uuid, is_account boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.community_active_account();
  if not public.community_is_admin() then raise exception 'moderation_denied'; end if;
  if is_account then
    update public.profile_reports set state = 'resolved' where id = report_uuid;
  else
    update public.content_reports set state = 'resolved' where id = report_uuid;
  end if;
  if not found then raise exception 'report_unavailable'; end if;
end;
$$;

revoke all on function public.report_profile(uuid, text), public.mark_report_reviewed(uuid, boolean)
  from public, anon, authenticated;
grant execute on function public.report_profile(uuid, text), public.mark_report_reviewed(uuid, boolean)
  to authenticated;

notify pgrst, 'reload schema';
