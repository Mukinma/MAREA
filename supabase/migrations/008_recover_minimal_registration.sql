-- Repair registrations made by the minimal client while the 006 trigger was
-- deployed. Only an unconfirmed profile can consume its stored signup choice.
-- This is a one-time data repair, not an ongoing trust in mutable Auth metadata.
update public.profiles as p
set user_type = u.raw_user_meta_data->>'user_type',
    onboarding_status = 'completed',
    initial_profile_completed_at = now()
from auth.users as u
where u.id = p.id
  and p.initial_profile_completed_at is null
  and u.raw_user_meta_data->>'registration_flow' = 'minimal-v1'
  and u.raw_user_meta_data->>'user_type' in
    ('Usuario general','Artista / creador','Emprendedor','Negocio')
  and not exists (
    select 1 from public.account_deletion_requests as d where d.user_id = p.id
  )
  -- Do not discard incompatible professional data to force a recovery. Such
  -- accounts keep the explicit legacy confirmation flow instead.
  and (u.raw_user_meta_data->>'user_type' = 'Negocio'
       or (p.location is null and p.business_hours = '{}'::jsonb))
  and (u.raw_user_meta_data->>'user_type' = 'Artista / creador'
       or not p.open_to_collaboration)
  and (u.raw_user_meta_data->>'user_type' <> 'Usuario general'
       or p.contact_url is null);
