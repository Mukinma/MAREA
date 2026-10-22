# TASK-002 — Transporte PAX y aceptación E2-A local

**Resultado: E2-A IMPLEMENTADO_VALIDADO_SOLO_COPIAS_LOCALES_SINTETICAS. Ejecución detenida. TASK-002 incompleta.**

La aceptación se limita a D01/A en las dos fuentes sintéticas A/B reproducidas desde los insumos E1 autorizados. No acredita compatibilidad con todos los datos reales, despliegue, baja de cuentas, titularidad de misiones ni los contratos de ofertas/acuerdos. La comprobación final del registro canónico y sus vistas se conserva en [12-traceability.json](12-traceability.json); el manifiesto de archivos queda en [13-artifact-manifest.json](13-artifact-manifest.json).

## 1. Transporte tar PAX — PASS

Se sustituyó la exportación que perdía precisión por [pax_transport.py](../../../../../tool/task002/pax_transport.py). Emite PAX con `mtime`/`atime` decimales de nueve cifras, desde enteros nanosegundo, sin conversión a float. Verifica fuente → archivo → destino con igualdad exacta de rutas, bytes/SHA256, tamaño de archivos/enlaces, tipos, modos, uid/gid, tiempos y topología de enlaces. La materialización mediante Docker cp va seguida de restauración explícita de timestamps; se comprueban propietarios y modos, sin corregir silenciosamente discrepancias.

- Laboratorio previo a datos: nueve entradas sintéticas, directorios con distintos permisos, archivo vacío, ruta larga Unicode, enlace simbólico interno y enlace duro.
- `mtime_ns=1700000000123456789` conservado exactamente en cabecera PAX y destino; también `atime_ns` exacto por entrada.
- RED de pérdida fraccional conservado. Ocho casos negativos de manifiesto/destino y cinco archivos PAX dañados independientes detectan ausencia, pérdida temporal, propietario, permisos y bytes alterados. Rutas fuera del destino, enlaces que escapan y archivos especiales se rechazan.
- Prueba y cierre sin datos del proyecto ni volúmenes históricos. No se eliminó ninguna comparación previa.

Evidencia: [ciclo completo](../run-20261019T143903Z-e2a-r3/pax/05-PAX-cycle.json), [archivos dañados independientes](../run-20261019T143903Z-e2a-r3/pax/07-actual-negative-archives.json), [RED temporal](../run-20261019T143903Z-e2a-r3/pax/03-precision-RED.json).

**Límite técnico explícito:** `ctime`, nacimiento del inode y espacio asignado de directorios los genera el sistema de archivos; no son atributos restaurables de un tar. Se comparan entradas de directorio, tamaños de archivos/enlaces y mtime/atime a nanosegundo. Esta prueba no certifica metadatos no incluidos, ACL extendidas, otros sistemas de archivos ni propietarios heterogéneos de datos reales.

## 2. Backup/restore completo — PASS

El ejecutor R8 es nuevo; no importa ni desbloquea ejecutores fallidos. Fuentes: archivos fríos sintéticos autorizados del diagnóstico E y SQL E1 con digests verificados. Se restaura en volúmenes nuevos y se reproduce E1; sus seis principales originales y el resto del catálogo/datos permanecen intactos.

| Comprobación, en A y B | Resultado |
|---|---|
| Helpers vacíos antes de restaurar o arrancar PG/Auth | PASS |
| Network namespace declarado/efectivo; interfaces, rutas, forwarding y sockets | PASS |
| Red `none` o namespace de PG aislado; sin puertos publicados, caps añadidas o BYPASS de red | PASS |
| Backups E1: árbol PAX exacto en otro volumen y arranque real de PG | PASS |
| Catálogo, ACL, rutinas, RLS, datos/hashes y secuencias recuperados | PASS |
| Storage antes de A: recuperación física completa, A 46 entradas/B 51 | PASS |
| Backup posterior a A y fixtures, restaurado y arrancado en otros volúmenes nuevos | PASS |
| Storage después de las pruebas: bytes y metadatos/ns iguales | PASS |

Evidencias: [preflight vacío](01-empty-preflight.json), [gate completo](02-full-preflight.json), [recuperación inicial](03-new-E1-baselines.json), [recuperación final](08-final-cold-recovery.json).

Se mantiene el verificador de aislamiento aprobado. Un ensayo vacío adicional reprodujo el cambio real de namespace tras reiniciar el anchor: el helper antiguo fue rechazado y el nuevo aceptado. Cada comprobación usa ahora un probe efímero en el namespace vigente. [Regresión](../run-20261019T143903Z-e2a-r3/08-namespace-restart-regression.json).

## 3. E2-A — implementación y pruebas PASS

SQL ejecutado exclusivamente en laboratorio: [20261019152036_e2a_private_identity.sql](20261019152036_e2a_private_identity.sql), generado en un proyecto privado separado. No se añadió ni alteró una migración del producto.

Cambios del incremento: dos roles técnicos NOLOGIN/NOBYPASSRLS sin membresías; tablas privadas `person_controls` y `person_repair_manifests`; cinco funciones privadas; trigger AFTER INSERT `zz_e2a_person_after_auth`; nueve políticas técnicas estrictamente dirigidas al nuevo propietario. La política Auth concede lectura sólo mediante las columnas `id,deleted_at`; la de solicitudes de baja lee sólo `user_id,requested_at`. No se amplían privilegios de roles administrativos existentes ni se concede acceso cliente al esquema privado.

El orden real conserva `on_auth_user_created` antes del nuevo trigger. `handle_new_user`, registro mínimo/estándar y validaciones legales/perfil no cambian. La creación inicial usa Person.id=Auth.id; la resolución usa `auth_user_id`. Una colisión, principal desligado/suprimido de fixture, control ausente o bloqueo exige revisión explícita. No hay `ON CONFLICT` silencioso, relink, organización o membresía inferida.

El manifiesto administrativo normaliza UUID, fija hash, limita a cien entradas, exige dry-run explícito y sólo permite ejecutar el cuerpo registrado. Locks por lote/identidad y revalidación impiden duplicados. El operador sólo ejecuta stage/reconcile; no puede leer Person ni invocar ensure directamente.

| Casos autorizados | Evidencia real |
|---|---|
| E2-T01 | E1 reproducido, catálogo/deltas/RLS/ACL, ensayo SQL+reparación con ROLLBACK exactamente igual; commit A en ambas copias |
| E2-T02 | Tres registros HTTP reales por fuente después de A; flujos mínimo/estándar y un principal/control por alta |
| E2-T03 | Cinco errores HTTP por fuente sin alta parcial: validaciones heredadas, control privado y fallo posterior al principal; no se devuelve éxito |
| E2-T04 | Metadatos de rol/persona/organización/app_metadata falsificados no alteran autoridad |
| E2-T05 | Dry-run sin delta, lote mixto rechazado atómicamente, hash/cuerpo incorrectos denegados, dos reparaciones concurrentes, replay idempotente y carrera trigger/reparación |
| E2-T06 | Mapping vigente con PK distinta resuelto; colisión no nula MAPPING_CONFLICT rechazada; fixtures desligados/bloqueados no se revinculan; solicitud legada de baja denegada para sync |
| E2-T08 | 45 denegaciones CRUD/funciones por fuente para anon/authenticated/service_role, más claim falsificado |
| E2-T44, sólo reparación | Lock observado en servidor, timeout 55P03 ~1,57 s y un reintento acotado con mismo principal |

Se registraron 16 grupos funcionales PASS, 90 denegaciones efectivas y 32 negativos adicionales de entrada/restricciones en ambas copias. Los negativos adicionales dejan snapshot completo idéntico. La asociación de proveedor adicional se prueba mediante INSERT de fixture en `auth.identities`; no acredita OAuth externo.

Evidencias: [RED real previo](04-functional-RED.json), [ensayo/commit](05-A-transactional-installation.json), [GREEN](06-functional-GREEN.json), [restricciones/entradas](06b-constraint-input-negative.json), [conservación](07-integrity-conservation.json). Pruebas del laboratorio: [50 PASS](09-unit-tests.log). Herramienta de trazabilidad: [34 PASS](09b-traceability-tests.log).

### Deltas exactos, separados de la implementación

DDL A conserva todas las filas y secuencias preexistentes; inserta seis controles E1, uno bloqueado por la solicitud de baja ya existente. No cambia las seis Person E1.

Por fuente, los casos añaden exactamente: 7 Auth, 7 perfiles, 7 aceptaciones legales, 7 identidades de proveedor, 6 sesiones, 6 refresh tokens, 6 AMR y 12 eventos Auth. Se conservan por hash todas las filas originales, incluidas las AMR. Las seis filas nuevas de sesión/AMR/refresh se vinculan a los UUID de registros HTTP de fixtures. Person suma nueve filas de casos; dos son fixtures desligados preparados directamente. Resultado: 13 Auth/perfiles/aceptaciones, 15 Person y 15 controles. Todas las Auth vigentes tienen un mapping único; las dos Person adicionales desligadas no autorizan ninguna cuenta.

Secuencias: refresh 22→28, seis INSERT; legal 7→19, siete INSERT confirmados y cinco nextval consumidos por transacciones intencionalmente revertidas (tres colisiones y dos fallos tardíos). Todas las demás secuencias quedan iguales. No se ignoran huecos de secuencia ni deltas auxiliares de Auth.

Se compararon todos los objetos originales. Sólo se admiten las adiciones previstas y los 23 grants exactos de los dos roles nuevos. Las FK, políticas/rutinas de negocio, publicaciones/default privileges y Storage originales se conservan. No quedan funciones/triggers de inyección de fallos.

## 4. Conservación y archivos

[10-workspace-preservation.json](10-workspace-preservation.json): 1.050 archivos del inicio conservados sin cambio y 1.132 del corte anterior; 365 archivos privados previos con hashes iguales; 384 contenedores anteriores idénticos en identidad/estado/mounts; 73 volúmenes previos conservados. Diez volúmenes nuevos propios. Los 21 contenedores persistentes de R8 están detenidos; los helpers efímeros se eliminaron al terminar. Cero contenedores en ejecución.

Fuentes E1, propuesta `E1-ADDITIVE-PROPOSAL.sql` con barrera/ROLLBACK, SRS, TASK-001, U0, herramientas originales y recibos fallidos se preservan. La imagen offline Docker .raw queda fuera de todo inventario/lectura de esta entrega. No se accedió a volúmenes originales ni se invocó un servicio remoto de producto. HEAD sigue `989e5b5845deff0afd13703a067a7d7a3775d3bc`; sin staging ni commits.

Archivos nuevos: transporte PAX y pruebas; ejecutores/casos separados R3–R8 y sus herramientas de validación; recibos/SQL/informes en directorios de evidencia nuevos. Versiones fallidas se conservan. [ATTEMPT-HISTORY.json](ATTEMPT-HISTORY.json) registra causa, recibo/hash y corrección aplicada únicamente al siguiente intento. [11-independent-review.md](11-independent-review.md) conserva los hallazgos y límites de la revisión estática.

Archivos documentales que se actualizan al registrar este cierre: YAML canónico y vistas generadas que efectivamente cambien. Se preservan los 318 objetos de evidencia anteriores, los 684 requisitos, 21 TC, TASK-001 y baseline histórica byte a byte; se añaden evidencias acotadas, sin validación integral ni promoción de baseline. Las comprobaciones posteriores al registro se encuentran en 12 y el listado exacto de archivos en 13.

## 5. Bloqueos y autorización siguiente

No queda un bloqueo técnico de transporte, backup/restore o sincronización/reparación privada A en estas copias. No se ejecutó E2-T07 ni DELETE de cuentas/perfiles. La retención, supresión, eliminación de cuentas y no resurrección tras una baja real siguen sin diseñarse/validarse integralmente bajo D02 y dependencias. Los mínimos controles de A no sustituyen ese diseño.

S0 y todos los demás incrementos continúan NO AUTORIZADOS. La siguiente autorización específica sería **S0 local**, con barrera contra limpieza destructiva y conservación física T49 en copias sintéticas nuevas, conforme al expediente E2. No se inicia por este informe. Después siguen las decisiones D02–D10 y autorizaciones por incremento; las dependencias de revocación de TASK-003 impiden aceptar integralmente los flujos que dependan de ellas.

Sin cambios de `missions.author_id`, candidaturas, FK existentes, titularidad contractual, RPC de negocio, Flutter, Edge o remoto. No se han implementado ofertas, reservas, acuerdos ni organizaciones. U0 aprobado sigue siendo referencia para una futura adaptación; las pantallas maduras permanecen intactas.
