-- Recreate the story RPC if the metadata migration was recorded without
-- installing the five-argument function.
drop function if exists public.publish_story(uuid, text, text, text, text);

create function public.publish_story(
  story_uuid uuid,
  story_body text,
  story_image text default null,
  story_category text default 'otros',
  story_target_type text default null
) returns uuid
language plpgsql security definer set search_path=''
as $$
declare
  account uuid := public.community_active_account();
  receipt public.story_publications;
  prior public.stories;
  published timestamptz := clock_timestamp();
  fingerprint text;
begin
  if story_uuid is null
    or story_body is null
    or char_length(story_body) > 500
    or (btrim(story_body) = '' and story_image is null)
    or story_category not in (
      'arte', 'gastronomia', 'moda', 'digital', 'musica',
      'escritura', 'fotografia', 'diseno', 'otros'
    )
    or (story_target_type is not null and story_target_type not in (
      'Usuario general', 'Artista / creador', 'Emprendedor', 'Negocio'
    ))
  then
    raise exception 'invalid_story';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(story_uuid::text, 0));
  fingerprint := encode(sha256(convert_to(jsonb_build_array(
    btrim(story_body), story_image, story_category, story_target_type
  )::text, 'UTF8')), 'hex');

  select * into receipt from public.story_publications where id = story_uuid;
  if found then
    if receipt.author_id <> account or receipt.payload_hash <> fingerprint then
      raise exception 'story_operation_conflict';
    end if;
    return receipt.id;
  end if;

  select * into prior from public.stories where id = story_uuid;
  if found then
    if prior.author_id <> account
      or prior.body <> btrim(story_body)
      or prior.image_path is distinct from story_image
      or prior.category <> story_category
      or prior.target_type is distinct from story_target_type
    then
      raise exception 'story_operation_conflict';
    end if;
    insert into public.story_publications(id, author_id, payload_hash)
    values (story_uuid, account, fingerprint)
    on conflict(id) do nothing;
    return prior.id;
  end if;

  if story_image is not null and (
    story_image <> account::text || '/' || story_uuid::text || '.png'
    or not exists (
      select 1
      from storage.objects
      where bucket_id = 'story-images' and name = story_image
    )
  ) then
    raise exception 'invalid_story_image';
  end if;

  insert into public.stories(
    id, author_id, body, image_path, category, target_type, created_at, expires_at
  )
  values (
    story_uuid, account, btrim(story_body), story_image,
    story_category, story_target_type, published, published + interval '24 hours'
  );
  return story_uuid;
end;
$$;

grant execute on function public.publish_story(uuid, text, text, text, text)
to authenticated;

select pg_notify('pgrst', 'reload schema');
