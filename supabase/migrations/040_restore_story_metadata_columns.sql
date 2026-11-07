-- The metadata migration was recorded remotely without changing the stories
-- table. Restore the columns required by the metadata-aware story RPC.
alter table public.stories
  add column if not exists category text not null default 'otros',
  add column if not exists target_type text;

alter table public.stories
  drop constraint if exists stories_category_check,
  add constraint stories_category_check check (
    category in (
      'arte', 'gastronomia', 'moda', 'digital', 'musica',
      'escritura', 'fotografia', 'diseno', 'otros'
    )
  ),
  drop constraint if exists stories_target_type_check,
  add constraint stories_target_type_check check (
    target_type is null or target_type in (
      'Usuario general', 'Artista / creador', 'Emprendedor', 'Negocio'
    )
  );

update public.story_publications p
set payload_hash = encode(
  sha256(convert_to(jsonb_build_array(
    s.body, s.image_path, s.category, s.target_type
  )::text, 'UTF8')),
  'hex'
)
from public.stories s
where s.id = p.id;

select pg_notify('pgrst', 'reload schema');
select pg_notify('pgrst', 'reload config');
