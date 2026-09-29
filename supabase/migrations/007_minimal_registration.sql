-- Minimal registration confirms profile type once; optional setup is independent.
-- Existing profiles and content remain intact. Preferences stay private and editable.
alter table public.profiles add column setup_step integer not null default 0;
alter table public.profiles add constraint profile_setup_step_valid check (
  setup_step between 0 and case user_type when 'Usuario general' then 2 when 'Negocio' then 4 else 3 end
);
grant update(interests,goals,setup_step) on public.profiles to authenticated;

create or replace function public.validate_profile_presentation() returns trigger
language plpgsql security definer set search_path='' as $$
declare day text; hours jsonb; value text;
begin
  if old.initial_profile_completed_at is not null and row(new.user_type,new.onboarding_status,new.initial_profile_completed_at) is distinct from row(old.user_type,old.onboarding_status,old.initial_profile_completed_at) then raise exception 'initial_profile_already_confirmed'; end if;
  if jsonb_typeof(new.business_hours)<>'object' then raise exception 'invalid_business_hours'; end if;
  for day,hours in select * from jsonb_each(new.business_hours) loop
    if day not in ('mon','tue','wed','thu','fri','sat','sun') then raise exception 'invalid_business_hours'; end if;
    if hours='null'::jsonb then continue; end if;
    value := hours#>>'{}';
    if jsonb_typeof(hours)<>'string' or value !~ '^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$' or left(value,5)>=right(value,5) then raise exception 'invalid_business_hours'; end if;
  end loop;
  if new.user_type<>'Negocio' and (new.location is not null or new.business_hours<>'{}'::jsonb) then raise exception 'business_profile_required'; end if;
  if new.user_type<>'Artista / creador' and new.open_to_collaboration then raise exception 'creator_profile_required'; end if;
  if new.user_type='Usuario general' and new.contact_url is not null then raise exception 'professional_profile_required'; end if;
  return new;
end;
$$;
revoke all on function public.validate_profile_presentation() from public,anon,authenticated;

create or replace function public.complete_initial_profile(profile_type text,selected_interests text[],selected_goals text[]) returns jsonb
language plpgsql security definer set search_path='' as $$
declare account uuid := auth.uid(); current_profile public.profiles; result public.profiles;
begin
  if account is null then raise exception 'authentication_required'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(account::text,0));
  select * into current_profile from public.profiles where id=account for update;
  if not found then raise exception 'account_required'; end if;
  if exists(select 1 from public.account_deletion_requests where user_id=account) then raise exception 'account_deletion_pending'; end if;
  if current_profile.initial_profile_completed_at is not null then raise exception 'initial_profile_already_confirmed'; end if;
  if profile_type is null or profile_type not in ('Usuario general','Artista / creador','Emprendedor','Negocio') or selected_interests is null or selected_goals is null then raise exception 'initial_profile_choices_required'; end if;
  -- Catalog, null and cardinality checks remain enforced by the profiles constraints.
  update public.profiles set user_type=profile_type,
    interests=array(select distinct x from unnest(selected_interests) x order by x),
    goals=array(select distinct x from unnest(selected_goals) x order by x),
    onboarding_status='completed',initial_profile_completed_at=now() where id=account returning * into result;
  return to_jsonb(result);
end;
$$;
revoke all on function public.complete_initial_profile(text,text[],text[]) from public,anon;
grant execute on function public.complete_initial_profile(text,text[],text[]) to authenticated;


create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  policy jsonb := public.registration_policy();
  metadata jsonb := new.raw_user_meta_data;
  new_name text := btrim(coalesce(metadata->>'full_name',''));
  new_username text := lower(btrim(coalesce(metadata->>'username','')));
  profile_type text := metadata->>'user_type';
  minimal boolean := metadata->>'registration_flow' = 'minimal-v1';
begin
  if (policy->>'signup_enabled')::boolean is distinct from true then raise exception 'registration_closed'; end if;
  if metadata->>'adult_confirmed' is distinct from 'true' or metadata->>'accepted_terms' is distinct from 'true'
    or metadata->>'terms_version' is distinct from policy #>> '{terms,version}'
    or metadata->>'privacy_version' is distinct from policy #>> '{privacy,version}' then
    raise exception 'legal_acceptance_required';
  end if;
  if char_length(new_name) not between 1 and 80 or new_username !~ '^[a-z0-9._]{3,24}$' then raise exception 'invalid_signup_metadata'; end if;
  if metadata ? 'registration_flow' and metadata->>'registration_flow' is distinct from 'minimal-v1' then raise exception 'invalid_registration_flow'; end if;
  if minimal and (profile_type is null or profile_type not in ('Usuario general','Artista / creador','Emprendedor','Negocio')) then raise exception 'invalid_profile_type'; end if;
  insert into public.profiles(id,full_name,username,user_type,role,onboarding_status,initial_profile_completed_at)
  values(new.id,new_name,new_username,case when minimal then profile_type else 'Usuario general' end,'user',
    case when minimal then 'completed' else 'pending' end,case when minimal then now() else null end);
  insert into public.legal_acceptances(user_id,terms_version,privacy_version,adult_confirmed)
  values(new.id,metadata->>'terms_version',metadata->>'privacy_version',true);
  return new;
end;
$$;
