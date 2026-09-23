alter table public.posts
  add column location_latitude double precision,
  add column location_longitude double precision,
  add column location_precision text;

alter table public.posts
  add constraint posts_location_coordinates_check check (
    (location_latitude is null and location_longitude is null and location_precision is null)
    or (
      location_latitude between -90 and 90
      and location_longitude between -180 and 180
      and location_precision in ('exact', 'approximate')
    )
  );

grant insert(
  kind,title,body,category,location,location_latitude,location_longitude,
  location_precision,price,image_path
) on public.posts to authenticated;
grant update(
  title,body,category,location,location_latitude,location_longitude,
  location_precision,price,image_path
) on public.posts to authenticated;
