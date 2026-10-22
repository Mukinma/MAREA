-- PROPUESTA DE INSPECCIÓN: no ejecutada. Sólo en copia local identificada y aislada.
-- El cliente ejecutor futuro debe comprobar namespace/loopback/aislamiento antes de psql.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '30s';
SELECT count(*) AS missions,
       count(DISTINCT m.author_id) AS mission_authors,
       count(*) FILTER (WHERE p.id IS NULL) AS missing_profiles,
       count(*) FILTER (WHERE u.id IS NULL) AS missing_auth_users,
       count(*) FILTER (WHERE m.hidden) AS hidden_missions
FROM public.missions m
LEFT JOIN public.profiles p ON p.id=m.author_id
LEFT JOIN auth.users u ON u.id=m.author_id;
SELECT status,count(*) FROM public.missions GROUP BY status ORDER BY status;
SELECT a.status,count(*) FROM public.mission_applications a GROUP BY a.status ORDER BY a.status;
SELECT count(*) AS application_mission_orphans FROM public.mission_applications a
LEFT JOIN public.missions m ON m.id=a.mission_id WHERE m.id IS NULL;
SELECT count(*) AS drafts_with_missing_published_mission FROM public.mission_drafts d
LEFT JOIN public.missions m ON m.id=d.published_mission_id
WHERE d.published_mission_id IS NOT NULL AND m.id IS NULL;
SELECT count(*) AS mission_images FROM storage.objects WHERE bucket_id='mission-images';
SELECT c.conrelid::regclass::text AS source,c.conname,c.confrelid::regclass::text AS target,
       pg_get_constraintdef(c.oid) AS definition,c.convalidated
FROM pg_constraint c WHERE c.contype='f'
AND (c.conrelid IN ('public.missions'::regclass,'public.profiles'::regclass)
 OR c.confrelid IN ('public.missions'::regclass,'public.profiles'::regclass))
ORDER BY source,c.conname;
SELECT schemaname,tablename,policyname,cmd,roles,qual,with_check
FROM pg_policies WHERE tablename IN
 ('missions','mission_applications','mission_drafts','mission_finalists','mission_saves',
  'mission_comments','mission_reactions','notifications','objects')
ORDER BY schemaname,tablename,policyname;
-- Digests only: no filas personales, textos contractuales ni credenciales en recibos públicos.
SELECT count(*) AS rows,encode(sha256(convert_to(
 coalesce(jsonb_agg(to_jsonb(m) ORDER BY m.id),'[]'::jsonb)::text,'UTF8')),'hex') AS mission_digest
FROM public.missions m;
SELECT count(*) AS rows,encode(sha256(convert_to(
 coalesce(jsonb_agg(to_jsonb(a) ORDER BY a.id),'[]'::jsonb)::text,'UTF8')),'hex') AS application_digest
FROM public.mission_applications a;
ROLLBACK;
