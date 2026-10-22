-- BORRADOR PARA REVISIÓN. NO ES MIGRACIÓN. NO SE HA EJECUTADO.
-- Requiere aprobación técnica E y preflight/backup/restore verificados.
-- Esta barrera evita ejecución accidental; su retiro exige revisión y autorización.
BEGIN;
DO $$ BEGIN RAISE EXCEPTION 'TASK002_PROPOSAL_NOT_APPROVED_FOR_EXECUTION'; END $$;

-- Diseño de referencia, todavía sujeto al inventario efectivo local.
CREATE SCHEMA collaboration;
REVOKE ALL ON SCHEMA collaboration FROM PUBLIC,anon,authenticated;
CREATE TABLE collaboration.persons (
 id uuid PRIMARY KEY,
 auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE collaboration.persons ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON collaboration.persons FROM PUBLIC,anon,authenticated;

-- Principal técnico estable: no acredita elegibilidad ni titularidad organizacional.
INSERT INTO collaboration.persons(id,auth_user_id)
 SELECT p.id,p.id FROM public.profiles p JOIN auth.users u ON u.id=p.id;

-- Abortará si falta un principal. No se inventan autores ni se suprimen misiones.
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.missions m LEFT JOIN collaboration.persons p
 ON p.id=m.author_id WHERE p.id IS NULL) THEN
  RAISE EXCEPTION 'TASK002_AUTHOR_REFERENCE_REQUIRES_REVIEW';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint
 WHERE conrelid='public.missions'::regclass AND conname='missions_author_id_fkey'
 AND confrelid='public.profiles'::regclass AND confdeltype='c') THEN
  RAISE EXCEPTION 'TASK002_UNEXPECTED_LEGACY_CONSTRAINT';
 END IF;
END $$;

-- Añadir/validar antes de retirar la referencia anterior, dentro de la misma transacción.
ALTER TABLE public.missions ADD CONSTRAINT missions_author_person_fkey
 FOREIGN KEY(author_id) REFERENCES collaboration.persons(id) ON DELETE RESTRICT NOT VALID;
ALTER TABLE public.missions VALIDATE CONSTRAINT missions_author_person_fkey;

-- PRECONDICIÓN DE SEGURIDAD AÚN NO IMPLEMENTADA:
-- Deben estar revisados los hooks de eliminación por recurso, proyecciones y medios.
-- No basta cambiar la FK: el Edge actual borra Storage por prefijo personal.
-- No se habilitan nuevas organizaciones/acuerdos ni eliminación destructiva incompatible.
DO $$ BEGIN
 IF to_regprocedure('collaboration.prepare_principal_deletion(uuid)') IS NULL THEN
  RAISE EXCEPTION 'TASK002_DOMAIN_DELETION_PRECONDITION_NOT_IMPLEMENTED';
 END IF;
END $$;
ALTER TABLE public.missions DROP CONSTRAINT missions_author_id_fkey;

-- author_id, UUID, contenido y referencias entrantes no cambian.
-- Este borrador termina en ROLLBACK; el SQL final debe aprobarse por separado.
ROLLBACK;
