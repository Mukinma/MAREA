# TASK-002 / E1 — principal personal privado, implementación local

**E1 IMPLEMENTADO Y VALIDADO EN DOS COPIAS LOCALES NUEVAS Y SINTÉTICAS. TASK-002 INCOMPLETA.** Autorización humana: 18 octubre 2026, America/Mexico_City; recibos UTC: 19 octubre. Alcance limitado por [AUTHORIZATION.md](AUTHORIZATION.md). U0 conserva APROBADO_DISEÑO_FUNCIONAL; E2, Flutter y remoto siguen sin autorización.

## Resultado y objetos creados

Se restauraron desde archivos de respaldo previamente conservados cuatro volúmenes nuevos: DB y Storage de cada origen A/B. Nunca se montaron ni arrancaron volúmenes originales. Cada PostgreSQL nuevo usó la imagen fijada, red `none`, sin puertos, raíz sólo lectura, usuario 100:101, sin capacidades; SQL exclusivamente por socket Unix interno mediante `docker exec`. No se arrancaron Auth, PostgREST, Realtime, Edge ni Storage API. Cron apagado, sin precarga pg_net, Vault vacío, push/geocodificación apagados. Se verificó la configuración local y sintética antes del DDL.

En cada copia, una transacción creó exclusivamente:

- Esquema privado `collaboration`, propietario `supabase_admin`, sin USAGE/CREATE para PUBLIC, anon o authenticated.
- `collaboration.persons`: `id uuid PRIMARY KEY`; `auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL`; `created_at timestamptz NOT NULL DEFAULT clock_timestamp()`.
- RLS habilitado, sin policies permisivas; permisos cliente revocados. Sin nuevas rutinas persistidas/RPC, triggers de aplicación, organizaciones, ofertas o acuerdos.
- Seis principales técnicos por copia, `id = profiles.id = auth.users.id`, sin inferir membresía, representación, elegibilidad ni legitimidad contractual de registros accepted legados.

El catálogo incorpora dos índices, tres constraints y cuatro triggers internos RI por la nueva FK, dos de ellos en Auth. Estas son adiciones esperadas y verificadas por su vínculo con la FK nueva; **ninguna FK, policy, rutina o trigger preexistente fue sustituido o modificado**. La FK de misión permanece validada: `missions_author_id_fkey → profiles(id) ON DELETE CASCADE`. Su riesgo legado sigue vigente.

`E1-ADDITIVE-PROPOSAL.sql` permanece byte por byte igual, SHA-256 `c0bd95c94fdde1fb55b17533debc939cae9c7fa8c7d77d2b194e8862978cedde`, con barrera y ROLLBACK. Se ejecutaron los artefactos separados [E1-LAB-A-EXECUTABLE.sql](E1-LAB-A-EXECUTABLE.sql) y [E1-LAB-B-EXECUTABLE.sql](E1-LAB-B-EXECUTABLE.sql), con diffs explícitos. Sólo se retiró la barrera en estos derivados autorizados, se usó BEGIN READ WRITE/COMMIT y se añadieron comparaciones de los 100 digests legados **dentro de la transacción antes de COMMIT**. No son migraciones instalables en remoto ni modifican el historial Supabase.

## Pruebas reales y recibos

| Verificación | Resultado | Evidencia |
|---|---|---|
| Socket Unix local / Docker 29.8.2 / imágenes fijadas / cero contenedores previos activos | PASS; sin pull, actualización ni conexión a proyecto remoto | 01-preflight.json |
| Cuatro archivos de respaldo y manifiestos completos contra hashes del diagnóstico E | PASS antes y después; origen de respaldo sólo lectura | 01-preflight.json, 07-backup-and-proposal-preservation.json |
| Cuatro restauraciones físicas DB/Storage en volúmenes nuevos | PASS; contenido y metadatos completos iguales | 02-restoration.json |
| Esquema, catálogo, filas y siete secuencias por copia contra snapshot verificado | PASS, sin drift; collaboration inicialmente ausente | 03-schema-and-digests-before.json |
| DDL/backfill E1 completo seguido de ROLLBACK, antes del commit real | PASS en A/B; catálogo completo, filas y secuencias recuperados | 04-transactional-execution.json; logs privados |
| Commit transaccional / correspondencia | PASS; 6 persons = 6 profiles = 6 Auth por copia; cero identidades sin correspondencia | 04-transactional-execution.json, 05-permissions-constraints-tests.json |
| SELECT, INSERT, UPDATE, DELETE como anon y authenticated | **16/16 PASS**, SQLSTATE 42501; SET ROLE real verificado; claims locales de sujeto existente, sin otorgar privilegios | 05-permissions-constraints-tests.json |
| Unicidad id/Auth, FK inexistente en INSERT/UPDATE, id y created_at no nulos | **12/12 PASS**, 23505 / 23503 / 23502 | 05-permissions-constraints-tests.json |
| Reejecución de E1 en esquema existente | **2/2 PASS**, P0001; aborta sin duplicar ni cambiar filas/catálogo | 04-transactional-execution.json |
| Privilegios efectivos, RLS y constraints | PASS; anon/authenticated sin uso/creación de schema ni SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER; RLS ON; cero policies | 05-permissions-constraints-tests.json |
| Legado | PASS; 100 tablas con mismos conteos/digests, siete secuencias iguales por copia; todos los objetos preexistentes comparados exactamente | 06-legacy-and-storage-conservation.json |
| Storage | PASS; 13 y 15 archivos, mismos hashes y metadatos; datos SQL Storage también iguales | 06-legacy-and-storage-conservation.json |
| Guardas del ejecutor y regresión del comparador | **8/8 PASS** finales, incluida detección de trigger extra no autorizado | 12-comparator-regression-green.log, 18-executor-final-tests.log |
| Trazabilidad | **34/34 PASS**; validación, regeneración e idempotencia en recibos finales | 15-traceability-tests.log, 19–22 logs |
| Cierre | Ambos PostgreSQL E1 apagados; 275 contenedores previos con estado/montajes/imagen idénticos; volúmenes nuevos retenidos | 17-final-isolation-and-close.json |

Son 30 denegaciones SQL esperadas en total, además de inspecciones positivas y dos pruebas de reversión transaccional. Las denegaciones CRUD se producen por ACL del esquema (42501); la defensa RLS se comprueba en catálogo con política implícita de denegación. No se concedieron privilegios temporales para simular acceso, ni se presentan estas pruebas SQL como ensayos HTTP/JWT/Realtime o prueba integral de revocación.

La comparación de conservación incluye definiciones de tablas, columnas, constraints/FK, policies, rutinas/cuerpos/ACL, triggers, vistas, grants, roles/membresías, extensiones y configuración; añade schemas, default ACL, índices, todas las rutinas no sistema y publicaciones/tablas publicadas. No se normalizan ni omiten cambios legados en esta corrida física. Sólo se separan los objetos nuevos enumerados arriba y los triggers Auth ligados por OID a la FK de persons. Los cuerpos completos y filas permanecen privados fuera del checkout (directorio 0700, archivos 0600).

## Interrupciones del verificador conservadas

El primer intento confirmó E1 en A y detuvo la corrida al fallar una comparación de catálogo; B aún no tenía E1. `FAILURE.json` conserva el fallo. La inspección posterior fue de sólo lectura: todas las filas y secuencias coincidían; la única diferencia eran los dos triggers internos Auth esperados. El comparador asumía texto `auth.users`, pero el catálogo devolvía `users` por visibilidad en search_path. Se corrigió exclusivamente la identificación mediante el mismo OID de relación; una regresión mostró FAIL antes y PASS después, y sigue rechazando triggers extra. No se alteró el SQL para resolverlo.

Una reanudación se detuvo antes de ejecutar más SQL por comparar la serialización de objetos JSON de los digests con sus claves en distinto orden. `RESUMPTION-FAILURE.json` conserva ese intento. El SQL original A se reprodujo **byte por byte** desde el recibo inicial ordenado; no se reescribió el ejecutable ya utilizado. Se confirmó otra vez A en lectura y ausencia total de drift en B antes de continuar exclusivamente la verificación A y el E1 originalmente autorizado en B. Recibos 10–14 y 16 conservan diagnóstico, parada, regresión y reanudación acotada. Los fallos históricos no se sustituyen por PASS.

## Archivos y conservación

Creados: `tool/task002/e1_lab.py`, `tool/task002/test_e1_lab.py` y esta carpeta de evidencia (autorización, ejecutables/diffs por origen, snapshots/digests, resultados y reportes). Archivos preexistentes modificados: YAML canónico y vista AUDIT. Las cuatro vistas TRACKING/AUDIT/TRACEABILITY/CHANGELOG se regeneraron; tres conservaron exactamente sus bytes. El YAML incorpora historial de progreso y evidencia limitada a E1 local.

Permanecen idénticos: propuesta E1 original, propuesta E/E2 y preflight anteriores, SRS, U0/matriz/evidencias, código Flutter, migraciones/RPC/Edge, herramientas de staging/trazabilidad previas, baseline y evidencias TASK-001, archivos del diagnóstico E y los respaldos usados. El recibo final de integridad detalla los hashes y la comparación de las 684 fichas de requisito, 21 casos TC-51 y 292 evidencias previas. No hubo commits ni cambios al área de staging Git.

Los volúmenes originales no se leyeron ni se rehashearon: no se pretende una prueba nueva de su contenido físico sin acceso. La garantía de esta corrida es ausencia de montajes/operaciones sobre ellos y estado de sus contenedores intacto, junto con el recibo histórico de conservación del diagnóstico E. Los destinos nuevos retienen las modificaciones físicas normales de PostgreSQL y los objetos E1 autorizados; no se exige identidad binaria de su directorio DB después de arrancar el motor.

## Bloqueos y límites pendientes

**Sincronización de futuras identidades:** no hay hook, job ni contrato de alta implementado. El backfill es una operación puntual sobre los perfiles/Auth verificados. Crear usuarios futuros no crea principals automáticamente. El diseño de reintentos, reparación, privilegios y consistencia de altas sigue pendiente.

**Eliminación de cuentas:** no se implementó ni probó borrado Auth/perfil, revocación, hook de preparación, limpieza o preservación de medios. La FK nueva declara SET NULL para desligar Auth sin usarlo como PK vital del principal; no valida por sí sola un flujo completo de eliminación. El id estable sigue siendo administrable por el propietario SQL; no se añadió un trigger general de inmutabilidad. La aplicación carece de permisos sobre el principal. Retirar la cascada de misión y proteger hijos/medios siguen bloqueados en E2.

**Retención del principal:** conservar su identificador tras unlink no define plazos, base de retención, minimización, supresión ni reaplicación durable de borrados al restaurar. Requiere sus propios diseños, controles y autorización. No se promete conservación indefinida ni cumplimiento integral a partir de esta FK.

**Compatibilidad y siguiente autorización:** los dos snapshots sintéticos tienen un autor de misiones, seis perfiles Artista/creador y ningún perfil Negocio u organización. Estos ensayos no demuestran compatibilidad con todos los datos reales ni autorizan despliegue remoto. Antes de E2 hacen falta diseños y controles verificables de eliminación/medios/adaptadores, inventario del entorno que se autorice y aprobación técnica específica. Flutter sigue sin autorización de implementación. No se solicita autorización general de TASK-002 ni se ejecuta ningún siguiente hito por inferencia. TASK-003 y sus fallos de revocación siguen fuera de alcance y bloquean la validación integral dependiente.

Las fuentes normativas, la baseline efectiva v5.0 y la adopción pendiente de compatibilidad local del diseño SRS v5.1.1 permanecen iguales; ninguna ficha de requisito o TC-51 se eleva a validación integral por E1. `normative_context` conserva el recibo histórico de N/T (14 octubre), que no concedía autorización general de migraciones. La autorización posterior, específica y limitada de E1 se registra en sus nuevas evidencias y en `TASK-002.documentary_progress.E1_authorization`; no se convierte en permiso general para migrar.

Referencias técnicas consultadas (sin acceso a proyectos): [privilegios y esquemas Supabase](https://supabase.com/docs/guides/api/securing-your-api), [RLS PostgreSQL 17](https://www.postgresql.org/docs/17/ddl-rowsecurity.html) y changelog Supabase. Se mantuvo la imagen de laboratorio 17.6.1.167 fijada y no se aplicaron actualizaciones ni cambios de plataforma; no se certifica preparación de producción por esta corrida.
