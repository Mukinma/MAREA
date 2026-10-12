-- Keep a compact operation receipt after expired stories/files are cleaned.
-- It stores a payload digest, never the text/image itself, and cascades on account deletion.
create table public.story_publications (
 id uuid primary key,
 author_id uuid not null references public.profiles(id) on delete cascade,
 payload_hash text not null
);
alter table public.story_publications enable row level security;
revoke all on public.story_publications from anon,authenticated;
grant all on public.story_publications to service_role;
insert into public.story_publications(id,author_id,payload_hash)
select id,author_id,encode(sha256(convert_to(jsonb_build_array(body,image_path)::text,'UTF8')),'hex')
from public.stories;

create or replace function public.publish_story(story_uuid uuid,story_body text,story_image text default null) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid:=public.community_active_account(); receipt public.story_publications;
 published timestamptz:=clock_timestamp(); fingerprint text;
begin
 if story_uuid is null or story_body is null or char_length(story_body)>500 or (btrim(story_body)='' and story_image is null) then raise exception 'invalid_story'; end if;
 perform pg_advisory_xact_lock(hashtextextended(story_uuid::text,0));
 fingerprint:=encode(sha256(convert_to(jsonb_build_array(btrim(story_body),story_image)::text,'UTF8')),'hex');
 select * into receipt from public.story_publications where id=story_uuid;
 if found then
  if receipt.author_id<>account or receipt.payload_hash<>fingerprint then raise exception 'story_operation_conflict'; end if;
  return receipt.id;
 end if;
 if story_image is not null and (story_image<>account::text||'/'||story_uuid::text||'.png' or not exists(select 1 from storage.objects where bucket_id='story-images' and name=story_image)) then raise exception 'invalid_story_image'; end if;
 insert into public.stories(id,author_id,body,image_path,created_at,expires_at)
 values(story_uuid,account,btrim(story_body),story_image,published,published+interval '24 hours');
 insert into public.story_publications(id,author_id,payload_hash) values(story_uuid,account,fingerprint);
 return story_uuid;
end; $$;
