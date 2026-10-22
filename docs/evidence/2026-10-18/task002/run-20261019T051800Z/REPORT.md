# TASK-002 — U0 aprobado y diagnóstico E completado localmente

Fecha de la autorización: **18 octubre 2026, America/Mexico_City**. Recibos UTC: 19 octubre. **TASK-002 incompleta. Ningún cambio estructural, Flutter o remoto autorizado/ejecutado.**

## Estado de aceptación

- **U0: APROBADO_DISEÑO_FUNCIONAL**, registrado en documento y YAML por autorización directa del usuario. Matriz, prototipo y evidencias verificadas permanecen intactos; sus etiquetas de revisión anteriores son parte del snapshot histórico. La aprobación no concede elegibilidad ambigua, autoriza Flutter o reemplaza pantallas maduras.
- **E diagnóstico: COMPLETADO_LOCAL**, con inventario efectivo y pruebas reales de recuperación en copias de los dos laboratorios TASK-001. **E corte estructural: NO AUTORIZADO y no listo para ejecutar** mientras falten conservación por recurso, medios y adaptadores. `E-PROPOSED-REFERENCE.sql` conserva su hash/barrera y no se ejecutó.

Informe técnico y decisión concreta: `docs/task002/E-DIAGNOSTIC-REPORT.md`. Propuesta siguiente, aún sin ejecutar/compilar: `docs/task002/E1-ADDITIVE-PROPOSAL.sql`.

## Evidencia ejecutada

| Hito / comprobación | Resultado | Recibo |
|---|---|---|
| Preservación offline previa a Docker | Copia APFS estable y seis muestras; sin checksum integral ni falsa prueba DB | 01-offline-preservation.json |
| Docker local 29.8.2 / inventario / quiescencia | PASS; 14 servicios históricos reanudados por Docker y detenidos de forma ordenada | 02-docker-inventory.json, 03-source-quiescence.json |
| Archivos DB/Storage en frío | Dos orígenes × dos volúmenes × dos destinos: ocho restores con igualdad de contenido/metadatos | 04-cold-backup-restore.json |
| Catálogo y filas de copias físicas | PASS; 100 tablas, siete secuencias, 31 roles, 25 membresías; conteos/digests iguales | 08-effective-inventory-canonical.json |
| Restauración lógica desde dump + globals, creación de DB/locale/ACL | PASS en ambos orígenes, con comparación posterior de filas, catálogo normalizado, roles/grants y GUC | 09-logical-backup-restore.json |
| FK/referencias efectivas | 101 FK por origen; cero huérfanos | 10-reference-conservation-checks.json |
| Storage | 13/13 y 15/15 metadatos/archivos; cero ausentes o sin referencia | 10-reference-conservation-checks.json |
| Riesgo de cascada legado | Perfil autor borrado sólo en copia: 6→0 misiones y 8→0 candidaturas; rollback recupera digests y secuencias | 10-reference-conservation-checks.json |
| Denegaciones SQL | anon sin lectura private (42501); escritura bloqueada en READ ONLY (25006) | 10-reference-conservation-checks.json |
| Comparador y guardas de restauración | 8/8 pruebas: privilegios, orden visible/GUC, digest incorrecto y destino original inadmisible | 11-safety-tests.log |
| Permisos efectivos | Catálogo compartible sin filas personales, cuerpos completos privados | 12-effective-permissions.json |
| Volúmenes originales tras ensayos | Contenidos y metadatos iguales al punto de respaldo en frío | 13-original-volume-conservation.json |
| Cierre | Nueve servidores diagnósticos detenidos, sin red/puertos; originales y runtime bloqueado detenidos; volúmenes/logs conservados | 14-final-isolation.json |
| Herramientas trazabilidad | 34/34 PASS; sin cambiar sus fuentes | 15-traceability-tests.log |

Los dos laboratorios tienen seis usuarios/perfiles, seis misiones de un autor y ocho candidaturas (cinco pending, tres accepted legados). No hay perfiles Negocio/espacio u organizaciones; no se fabricó clasificación ni aceptación bilateral. Se confirmó la FK validada `missions_author_id_fkey → profiles ON DELETE CASCADE` y la ausencia del hook de preparación del borrado.

## Ensayos intermedios y conservación

Se preservan los intentos fallidos: bootstrap/grantor de roles distinto, pg_net sin precarga, diferencias de locale/metadatos y sesiones de workers en la base vacía del destino. No se reescriben como PASS. La recuperación final usa el bootstrap original, dump con creación/ACL/ICU, precarga sólo durante restore y comparación con collation C. La normalización del catálogo sólo elimina identificadores/orden internos documentados; las ocho pruebas conservan detección de diferencias de permisos/tipos/orden visible/configuración. Los dumps originales y logs de todos los intentos permanecen privados.

El respaldo en frío corresponde al punto posterior al arranque/quiescencia, no se afirma identidad física antes/después del arranque de PostgreSQL. La copia offline previa está conservada por separado. No hay garantías de PITR, retención/supresión durable o equivalencia remota acreditadas.

El comando de verificación `supabase --version` actualizó su caché ignorada `supabase/.temp/cli-latest`. Se recuperaron los bytes originales y se verificó su SHA: `17-cli-cache-recovery.json`. No se modificó código funcional; el manifiesto final incluye esa caché restaurada.

## Autorización específica requerida

Solicitar **E1, sólo en copia local nueva: implementar/probar la migración aditiva del principal personal privado**, conforme al SQL adjunto, manteniendo la referencia/cascada actual de misión. Alcance: crear collaboration.persons, RLS/denegación a clientes y backfill técnico de UUID verificados; abortar ante huérfanos, schema existente o drift. Sin organizaciones automáticas, cambio de misión/FK, funciones de producto, Flutter o remoto. Sigue siendo una propuesta con barrera y ROLLBACK, no implementación validada.

E1 prepara la identidad estable; **no corrige aún la cascada**. E2 (sustituir/retirar referencia) requiere protecciones de eliminación, Storage y proyecciones implementadas y verificadas en un incremento posterior. No pedir ni asumir autorización de E2 ahora.

## Alcance y límites

No se aplicaron migraciones TASK-002 ni se cambiaron fuentes SRS/Flutter/RPC/Edge/migraciones/staging. La recreación de objetos legados mediante restore sólo ocurrió en copias nuevas y aisladas. No se hicieron commits ni operaciones remotas de negocio. Las fuentes y evidencias TASK-001, incluido el runtime bloqueado, se conservan.

Los PASS de recuperación no validan organizaciones/ofertas/reservas/acuerdos implementados ni la compatibilidad con todos los datos reales. TC-51 y los cinco FAIL históricos permanecen; la revocación JWT/Realtime y supresión durable TASK-003 siguen fuera de alcance. Las dimensiones de requisitos y la baseline normativa efectiva no se elevan. Se añadieron únicamente herramientas nuevas de diagnóstico, documentación y evidencias trazables.
