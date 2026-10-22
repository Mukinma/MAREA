# E — Diagnóstico estructural local y recuperación

**Diagnóstico E completado en dos laboratorios locales sintéticos. Cambio estructural E NO AUTORIZADO y todavía NO APTO para retirar la cascada.** U0 figura como APROBADO_DISEÑO_FUNCIONAL desde el 18 de octubre de 2026 (America/Mexico_City), sin autorización Flutter/backend/remoto. Fecha de los recibos UTC: 19 octubre 2026. Corrida `docs/evidence/2026-10-18/task002/run-20261019T051800Z/`.

## Resultados efectivos

| Medición | Laboratorio A | Laboratorio B |
|---|---:|---:|
| Procedencia | TASK001 d7522760bb90 | TASK001 fd0edb3330b2 |
| Usuarios / perfiles | 6 / 6 | 6 / 6 |
| Misiones / autores distintos | 6 / 1 | 6 / 1 |
| Misiones abiertas / cerradas | 5 / 1 | 5 / 1 |
| Candidaturas pendientes / accepted legado | 5 / 3 | 5 / 3 |
| Misiones sin perfil/Auth | 0 / 0 | 0 / 0 |
| FK comprobadas / filas huérfanas | 101 / 0 | 101 / 0 |
| Objetos Storage / archivos físicos | 13 / 13 | 15 / 15 |
| Archivos ausentes / sin referencia | 0 / 0 | 0 / 0 |
| Objetos mission-images | 1 | 1 |
| Perfiles de tipo Negocio/espacio | 0 | 0 |
| collaboration / hook prepare_principal_deletion | Ausentes | Ausentes |

El dominio public/private conserva 46 tablas y 139 rutinas. Hay 55 policies entre public/private/storage; al incluir Auth son 57. El inventario completo compara 100 tablas con filas, siete secuencias, 31 roles, 25 membresías de roles, 367 constraints y 429 triggers, incluidos los internos de FK. No hay vistas de aplicación persistidas: las proyecciones problemáticas están en rutinas/consultas y en sus consumidores, no en vistas SQL inventadas.

`08-effective-inventory-canonical.json` registra catálogo, permisos, RLS, FKs, triggers y dependencias efectivas. Los cuerpos completos, respaldos, claves locales y datos de prueba quedan fuera del checkout en almacenamiento privado 0700/0600. Los recibos compartibles usan conteos, definiciones de catálogo no personales y hashes; no contienen filas de usuarios o términos.

## Docker, procedencia y aislamiento

Docker Desktop se arrancó explícitamente tras comprobar su ausencia. Responde por socket Unix local con Docker 29.8.2; Node 24.14.0, CLI Supabase 2.117.0 e imágenes arm64 fijadas se conservaron, sin upgrades ni pulls. Se guardó una copia APFS offline del disco Docker antes del arranque, comprobando estabilidad y seis muestras. No tiene checksum integral de su tamaño lógico de ~995 GB ni constituye por sí sola un ensayo de restauración PostgreSQL.

Al arrancar Docker se reanudaron 14 servicios de los dos laboratorios históricos. Se verificaron sus etiquetas y redes internas y se detuvieron ordenadamente antes del respaldo en frío. No se arrancó el laboratorio bloqueado 8798fbb703ba. Los volúmenes originales se montaron sólo lectura al respaldarlos. El punto de los respaldos en frío es posterior a este arranque/quiescencia; no se afirma identidad física del volumen entre antes y después de iniciar/apagar PostgreSQL. La copia offline anterior queda conservada aparte.

Los servidores de diagnóstico se ejecutan sólo sobre volúmenes nuevos, con imagen PostgreSQL por SHA, `--network none`, sin puertos, usuario postgres, raíz sólo lectura y sin capacidades. Sin Auth, Edge, Storage API, workers de negocio o relay de aplicación. Cron permanece deshabilitado y sus ejecuciones en cero; Vault vacío, push/geocodificación apagados. pg_net sólo se precargó para restaurar su extensión, con red inexistente y cola vacía; se retiró de la precarga antes de comparar. No hay conexión remota ni ejecución de RPC de negocio.

## Respaldo y restauración reales

1. Se archivó íntegramente cada volumen DB y Storage en frío. Se verificaron SHA-256, estabilidad de origen y manifiestos de contenido, propietario, grupo, modo, mtime y enlaces. Los volúmenes no contenían enlaces externos ni tablespaces fuera del respaldo. DB: 2.099 archivos por laboratorio, ~82,8 MB. Storage: 13 y 15 archivos.
2. Cada archivo DB/Storage se restauró en **dos volúmenes nuevos**, comprobando igualdad de contenido y metadatos antes del arranque. Se iniciaron ambas copias DB y se comprobó igualdad de catálogo, conteos y digests lógicos. Son ocho restauraciones físicas de volumen en total.
3. Se generaron `pg_dump` custom, esquema y `pg_dumpall --globals-only`. Se restauraron roles y base completa en un clúster vacío por origen. El dump con `--create` conserva locale ICU `en-US`, versión 153.121, encoding UTF8, owner y ACL de la base. El rol bootstrap original es supabase_admin: sólo se omite su CREATE duplicado por initdb; todos sus atributos y grants se restauran y comparan. No se excluye ningún rol de la comparación final.
4. La restauración lógica final coincide en todas las filas/digests, secuencias, definiciones, RLS, permisos, roles, membresías y valores de configuración medidos. `pg_restore --create` no es una restauración atómica de todo el clúster: cada fallo conservó su destino desechable y ninguna copia se expuso a la aplicación.
5. El orden de los digests usa collation C explícita. Para comparar el catálogo lógico sólo se normalizan el orden de elementos ACL/conjuntos, números internos de triggers FK, huecos internos de columnas eliminadas (se conserva el orden visible) y procedencia del GUC (se compara su valor). No se omiten permisos, tipos, restricciones, propietarios, firmas ni cuerpos de rutinas. Ocho pruebas adicionales detectan ampliación de privilegios, cambios de orden visible, cambios de GUC y destinos/archivos inadmisibles.

Los intentos intermedios detectaron condiciones reales: grantor bootstrap distinto, pg_net sin precarga, locale/ACL de base omitidos y sesiones de workers que impedían eliminar la base vacía del destino. Se conservaron sus logs privados y recibos de fallo. La corrección afectó sólo al procedimiento de recuperación y clústeres desechables, nunca a los respaldos, migraciones/RPC históricos o datos de origen. No se acepta un exit code cero sin comparación posterior.

Recibos principales: `04-cold-backup-restore.json`, `08-effective-inventory-canonical.json`, `09-logical-backup-restore.json`, `10-reference-conservation-checks.json`, `11-safety-tests.log` y recibo final de conservación/aislamiento.

## Impacto real y bloqueo estructural

La FK efectiva es `missions_author_id_fkey`, validada: `FOREIGN KEY (author_id) REFERENCES profiles(id) ON DELETE CASCADE`. Los seis registros de misión pertenecen a un autor distinto; no hay huérfanos que justifiquen inventar identidades. Los seis perfiles tienen Auth enlazado. El backfill técnico propuesto cubriría seis UUID personales; **ninguna organización, membresía, aceptación o legitimidad de accepted se deriva de ellos**.

En una copia de recuperación de cada laboratorio se borró un perfil autor dentro de una transacción de prueba: **6→0 misiones y 8→0 candidaturas**. El rollback recuperó todos los digests y secuencias. Esta prueba reproduce el riesgo legado y acredita la reversión del ensayo, **no acredita que E ya impida esa pérdida**. El original no sufrió borrados ni cambios de FK.

Los 101 vínculos y las dependencias de rutinas completan el análisis estático previo. Siguen siendo necesarios antes de sustituir la referencia: protección de todas las entradas de eliminación Auth/perfil, tratamiento explícito de hijos que aún dependen de perfiles, adaptación de JOIN/author_id a la representación real, y conservación de medios frente a `delete-account` y borrados por prefijo personal. El hook propuesto no existe; no hay trigger de eliminación de aplicación registrado en auth.users. Una FK distinta por sí sola no protege Storage ni valida al representante.

Las denegaciones SQL restauradas también se comprobaron: anon no lee private (42501) y la conexión READ ONLY rechaza una escritura (25006). No son pruebas de revocación de JWT/sockets ni cierran TASK-003. Restore completo con reaplicación durable de supresiones y elegibilidad normativa integral siguen pendientes de sus dependencias.

## Autorización específica siguiente

**No solicitar aprobación del script E de sustitución/cascada como conjunto:** sus precondiciones siguen incumplidas. `E-PROPOSED-REFERENCE.sql` permanece idéntico, con su barrera y ROLLBACK, sin ejecutar ni certificar compilación.

Se entrega para autorización **E1: implementar y verificar únicamente el principal personal estable, aditivo y privado, en una copia local nueva**, según `E1-ADDITIVE-PROPOSAL.sql`. La propuesta crea collaboration.persons, habilita RLS/deniega acceso cliente y copia UUID técnicos de perfiles/Auth verificados. No altera `missions.author_id`, su FK/cascada, tablas/RPC/policies legados, Flutter o remoto; no clasifica negocios, asigna organizaciones o habilita contratos. La barrera y ROLLBACK siguen activos: el SQL E1 todavía no se ha ejecutado ni compilado. La futura autorización deberá permitir preparar su migración nueva y ensayar ese alcance exacto en laboratorio, con abortos y conservación de filas/digests, no el corte estructural E2.

Impacto esperado E1: seis filas nuevas exclusivamente en la tabla privada; ninguna actualización/borrado legado. Un esquema ya existente, huérfanos o drift de la FK hacen abortar. Riesgo: breves bloqueos DDL/referencia a Auth y necesidad de comprobar permisos efectivos; sin inferencia de duración en producción por tener sólo seis registros. Antes de commit aprobado se compararán digests; ante fallo, rollback de toda la transacción. Un rollback posterior sólo retiraría objetos nuevos después de verificar que ningún contrato/dato posterior depende de ellos; no se ejecuta automáticamente DROP.

**E2 (retirar/reemplazar FK) queda fuera de esa autorización** hasta implementar y probar sus protecciones, medios y adaptadores. Autorizar E1 no autoriza E2, Flutter, remoto ni cierre de TASK-002.

## Límites de compatibilidad

Se inspeccionaron dos datasets históricos de pruebas locales; no datos reales/remotos. Sólo tienen un autor de misiones, perfiles Artista/creador y ninguna organización. No cubren perfiles Negocio, propiedad disputada, múltiples autores reales ni volúmenes/condiciones operativas de producción. Los tres accepted por origen siguen siendo compromisos legados, no ofertas ni acuerdos bilaterales. Se conservaron SRS, matriz/evidencias U0 y TASK-001; no se elevaron requisitos o TC-51 a validación integral. TASK-002 continúa incompleta.

Métodos contrastados con documentación PostgreSQL 17: [respaldo físico en frío](https://www.postgresql.org/docs/17/backup-file.html), [dump y roles globales](https://www.postgresql.org/docs/17/backup-dump.html), [restauración y creación de base](https://www.postgresql.org/docs/17/app-pgrestore.html).
