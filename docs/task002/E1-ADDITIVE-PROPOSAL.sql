-- E1: propuesta concreta posterior al diagnóstico. NO AUTORIZADA / NO EJECUTADA.
-- Sólo futura copia local aislada; no retira ni sustituye missions.author_id.
-- No crea organizaciones ni convierte perfiles Negocio; no habilita API/Flutter.
BEGIN;
DO $$ BEGIN
 RAISE EXCEPTION 'TASK002_E1_REQUIRES_EXPLICIT_LOCAL_APPROVAL';
END $$;
-- El ejecutor futuro verificará otra vez propietario/aislamiento, backup y digests.
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname='collaboration') THEN
  RAISE EXCEPTION 'TASK002_E1_SCHEMA_ALREADY_PRESENT_REQUIRES_REVIEW';
 END IF;
 IF EXISTS (SELECT 1 FROM public.profiles p LEFT JOIN auth.users u ON u.id=p.id WHERE u.id IS NULL)
 OR EXISTS (SELECT 1 FROM public.missions m LEFT JOIN public.profiles p ON p.id=m.author_id WHERE p.id IS NULL) THEN
  RAISE EXCEPTION 'TASK002_E1_ORPHAN_REQUIRES_REVIEW';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.missions'::regclass
 AND conname='missions_author_id_fkey' AND confrelid='public.profiles'::regclass
 AND confdeltype='c' AND convalidated) THEN
  RAISE EXCEPTION 'TASK002_E1_LEGACY_REFERENCE_DRIFT';
 END IF;
END $$;
CREATE SCHEMA collaboration;
REVOKE ALL ON SCHEMA collaboration FROM PUBLIC,anon,authenticated;
CREATE TABLE collaboration.persons (
 id uuid PRIMARY KEY,
 auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE collaboration.persons ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON collaboration.persons FROM PUBLIC,anon,authenticated;
-- Copia técnica explícita UUID, sin acreditar elegibilidad, membresía o titularidad.
INSERT INTO collaboration.persons(id,auth_user_id)
 SELECT p.id,p.id FROM public.profiles p JOIN auth.users u ON u.id=p.id;
DO $$ BEGIN
 IF (SELECT count(*) FROM collaboration.persons)<>(SELECT count(*) FROM public.profiles)
 OR EXISTS(SELECT 1 FROM public.missions m LEFT JOIN collaboration.persons p ON p.id=m.author_id WHERE p.id IS NULL)
 OR NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.missions'::regclass
 AND conname='missions_author_id_fkey' AND confrelid='public.profiles'::regclass AND confdeltype='c') THEN
  RAISE EXCEPTION 'TASK002_E1_POSTCONDITION_FAILED';
 END IF;
END $$;
-- No modifica ninguna fila legada, función/RPC o policy existente; no cambia FK de misión.
-- Antes de COMMIT futuro aprobado, comparar filas/digests y permisos. ROLLBACK actual.
ROLLBACK;
