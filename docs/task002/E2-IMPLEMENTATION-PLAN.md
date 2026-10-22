# E2 — Plan de implementación por incrementos verificables

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task, únicamente tras autorización humana específica. Steps use checkbox (`- [ ]`) syntax for tracking. No delegación o ejecución se autoriza por este documento.

**Goal:** Separar misiones de perfiles sin perder identidad, titularidad, candidaturas, medios o garantías de consentimiento.

**Architecture:** Conservar missions como ancla de UUID, Person E1 como identidad privada y titularidad explícita en tabla privada. Expandir, clasificar con evidencia y adaptar permisos/consumidores antes de retirar dependencias destructivas. El borrado se prepara por recurso y se reconcilia como saga DB/Auth/Storage.

**Tech Stack:** PostgreSQL/Supabase locales fijados por imagen, RLS, Edge TypeScript y pruebas HTTP/SQL/Storage; Flutter sólo en hito posterior autorizado.

**Spec:** [E2-TECHNICAL-DESIGN.md](E2-TECHNICAL-DESIGN.md), SRS v5.1.1, [matriz de pruebas](E2-TEST-MATRIX.md) y [expediente de autorización](E2-AUTHORIZATION-DOSSIER.md).

## Global Constraints

- Estado actual: **PLAN NO AUTORIZADO PARA EJECUCIÓN. Todas las casillas pendientes.**
- No modificar SRS ni migraciones históricas; E1, propuestas con barrera/ROLLBACK y evidencias anteriores se preservan.
- Copias nuevas sintéticas aisladas con preflight/backup/restore/digests; nunca volúmenes E1/originales, remoto o datos reales por inferencia.
- Organizador autorizado incluye titular personal y representante organizacional con permiso vigente; ni perfiles Negocio ni autoría acreditan organización.
- No hacer commits ni staging automáticos. Cada tarea termina con evidencia/revisión del incremento; no con un commit.
- Ningún DROP/retirada de FK, cambio de RPC/RLS/Edge o Flutter sin autorización específica de ese incremento.
- TASK-003 no se implementa aquí; dependencia de sesión/revocación/restore no satisfecha bloquea aceptación integral dependiente.
- Conservar pantallas maduras, componentes MAREA y cinco destinos AppShell; U0 aprobado es referencia funcional, no permiso de implementación Flutter.

## Review Focus

1. Un borrado heredado ya inició la eliminación de archivos antes del bloqueo Auth: puerta S0 y T49 verifican bytes/referencias, no sólo metadata.
2. Auth se elimina mientras reparación crea/reasigna principal: A/B y T06/T07/T44 prueban no resurrección ni deadlock no gestionado.
3. Una candidata elimina su perfil y destruye candidatura/recibo aunque sobreviva misión: D y T22/T24 prueban todas las FK, no sólo author_id.
4. Un cliente consulta accepted por tabla, aviso o feed en lugar de RPC protegido: K/F y T27–32 prueban binario real y vías alternas.
5. Rollback/restore recupera PII suprimida o una FK antigua inválida tras una baja: X/R y T41–43 exigen forward fix o aislamiento, nunca fabricación de perfiles.

## Estructura y responsabilidades futuras

No se crean los siguientes archivos de producto en esta entrega. Los SQL nuevos se generarán con la CLI de migraciones en un directorio de laboratorio aprobado, sin alterar el historial; nombres/timestamps definitivos se registrarán en el recibo, sin inventar ahora archivos de migración instalables.

| Área / archivos afectados si se autoriza | Responsabilidad |
|---|---|
| SQL aditivo futuro en proyecto de laboratorio; cuerpos actuales de migrations 001/002/003/005/007/013/020/021 como referencia inmutable | Principal/control, titularidad, FK, permisos y fachadas; preservar registro, ciudad, compensación y validadores |
| `tool/task002/e2_preflight.py`, `e2_identity.py`, `e2_migration.py`, `e2_conservation.py` (nuevos futuros) | Guardas de laboratorio, binding de SQL/catálogo, ejecución por hito y comparación de deltas |
| `tool/task002/e2_scenarios.mjs`, `test_e2_safety.py` (nuevos futuros) | Casos reales HTTP/SQL/Storage/concurrencia y pruebas del harness; sin invocar funciones fuera del laboratorio |
| `supabase/functions/delete-account/index.ts`, `tour-storage.ts` y pruebas | Sustituir limpieza por prefijo por plan versionado; facade compatible y reanudación |
| Nuevo módulo Edge `supabase/functions/_shared/deletion-plan.ts` y `deletion-plan_test.ts` (futuros) | Tipos de plan, claims/leases y verificación de operaciones externas; sin duplicar orquestación en cada bucket |
| `lib/features/community/data/community_repository.dart`, `models/community_models.dart`, `models/mission_experience.dart`; pantallas afectadas actuales | DTO/contexto/capacidades/candidaturas y manejo UPDATE_REQUIRED; conservar UI madura |
| `lib/features/auth/data/auth_repository.dart` y flujo de baja existente | Diferenciar solicitud/en curso/final en v2; impedir falso 2xx legado |
| `lib/features/map/data/mission_map_repository.dart`, `lib/features/home_feed/`, `mission_social_repository.dart`, notificaciones/router | Lecturas/deep links por titular y estados seguros; adaptar sólo consumidores afectados |
| `tool/staging/` | Reutilizar regresiones y aislamiento conservados; cualquier extensión será nueva/evidenciada, sin reescribir resultados históricos |

## Hito A — Sincronización y reparación privadas del principal

**Interfaces:** consume E1 persons + Auth vigente y decisión D01. Produce `ensure_person_for_auth(uuid,text) → uuid`, `reconcile_persons(uuid,text,boolean) → summary` privados, trigger Auth registrado, tabla privada de control por Person. Sin borrar cuentas, cambiar FK de misión o crear organizaciones.

- [ ] Obtener autorización **sólo A** y registrar decisiones, hashes/procedencia de E1 y límites. Generar copia nueva; validar ausencia de drift/localidad y recuperar respaldo en otro destino nuevo antes de DDL.
- [ ] Crear primero T01–06/T08 y la concurrencia de reparación de T44; comprobar fallo esperado por ausencia del contrato/guarda, conservando resultado inicial. **T07 y la parte de baja de T44 se difieren a B/integración**, porque A no autoriza DELETE Auth/perfil. T06 usa fixtures nuevos preparados como desligados/suprimidos, sin eliminar cuentas ni modificar los seis principales E1. No ejecutar el harness E1 sobre sus volúmenes conservados.
- [ ] Implementar contrato de alta transaccional y reconciliación bajo permisos mínimos; conservar handle_new_user/registro legal/perfil y evidenciar orden de triggers. No religa NULL ni reusa supresiones.
- [ ] Ejecutar positivos, negativos, concurrencia y rollback. Oráculo: un Person por Auth legítimo, aplicación sin acceso al esquema y todas las filas/catálogos ajenos iguales; fallo de registro revierte todo.
- [ ] Entregar recibo A, SQL exacto, resultados y cambios permitidos. **Detener antes de B/S0**; A no autoriza baja, titularidad, FK, RPC de negocio ni Flutter.

## Hito S0 — Cerrar la ventana destructiva antes de activar E2 parcialmente

**Interfaces:** consume inventario de delete-account, Storage y workers/leases; produce una barrera operativa verificable con ruta para recibir solicitudes, sin limpieza vieja en ejecución ni reintentos capaces de borrar. Requiere autorización distinta por afectar Edge/guards y eventualmente permisos.

- [ ] Inventariar entrypoints reales de eliminación/subida/asociación/limpieza, incluidos admin Auth, rutas service_role, funciones Edge antiguas y workers ya iniciados. Registrar versiones y número de ejecuciones/claims en curso, no asumir que pausar ingreso las termina.
- [ ] Escribir T49: una ejecución legada iniciada antes del corte intenta borrar la imagen en uso después de la barrera. Deben permanecer archivo/digest y referencias; Auth no es el único oráculo.
- [ ] Preparar ruta que reciba solicitudes sin afirmar purga y cierre/fence de los productores destructivos antiguos. Drenar, detener o invalidar ejecuciones antiguas de forma demostrable; revalidar backup/manifiesto después de esa quiescencia y antes del DDL siguiente.
- [ ] Verificar el orden real de las operaciones de la versión Storage instalada. **Una guarda en storage.objects no se presume suficiente para impedir una eliminación física ya iniciada.** Si no se puede demostrar quiescencia y conservación de bytes, detener; no continuar porque DELETE Auth esté bloqueado.
- [ ] Comprobar T49 en ambos clones y todos los bypass inventariados; ninguna limpieza por prefijo sigue activa. Dejar el fence mientras falte el reemplazo completo. Sólo entonces habilitar B/C/D/M o cortes que dependan de esa protección. Sin solicitudes soportadas/compatibles no hay corte operativo real.

## Hito B — Solicitud durable y preparación de eliminación por recurso

**Interfaces:** consume A, S0, D02/D03/D08 y prueba de sesión/reautenticación de TASK-003 cuando corresponda. Produce `prepare_person_deletion(person_id,operation_id,expected_version) → {request_id,stage,plan_version}` interno, plan privado y fachadas v2 de solicitud/consulta. Los nombres de etapa son de proceso interno, sin alterar estados canónicos SRS.

- [ ] Escribir T09–12/T32/T46/T47, incluido reintento tras respuesta perdida y worker detenido. Una prueba mock de sesión sólo acredita estado local del procedimiento, no aceptación de seguridad.
- [ ] Añadir solicitud/control fuera de cascada Auth, bloqueo transaccional y manifiesto por recurso. Las etapas desconocidas/ausentes no permiten purga; preservar derecho a presentar solicitud.
- [ ] Diseñar y luego implementar sólo lo autorizado de cancelaciones/preliminares/casos con los motores contractuales realmente existentes. Si no existen, registrar dependencia BLOQUEADO, no crear handlers vacíos que devuelvan éxito.
- [ ] Implementar guardas Auth/perfil verificando plan/deltas/versión y workers permitidos, tras S0; el registro de solicitud no implica limpieza autorizada. No llamar Auth/Storage con una transacción DB abierta.
- [ ] Entregar **recibo B estructural** de solicitud/bloqueo/guardas negativas y privacidad; no ejecutar purga exitosa mientras falte D/M/TASK-003 o respuesta efectiva de sistemas externos. T07/T12 y la correspondencia Auth NULL resultante de una baja real quedan para B integrada, tras esas dependencias y autorización de la prueba destructiva en copia.

## Hito C — Titularidad explícita y clasificación

**Interfaces:** consume A, S0, ORG-0 implementado/aprobado y D05/D06; produce mission_ownership, manifest/casos y resolver de **organizador autorizado**. No implementa acuerdos/ofertas como efecto de la migración.

- [ ] Verificar ORG-0: organizaciones reales de fixtures explícitos, membresías/roles/estados/permisos; no crear una tabla vacía para satisfacer una FK. Sin esto no compilar variante organizacional ni marcarla cubierta.
- [ ] Escribir T15–20/T23 estructurales: XOR al commit, ancla sin titular, dos clasificadores y permiso del creador frente a membresía vigente; usar fixtures explícitos sin baja de cuentas. Preparar T13/T14 de baja y T48 contractual como pruebas de integración **diferidas**, sin marcarlas PASS por simular los estados finales. Comparar manifiesto contra versión/hash de cada misión.
- [ ] Crear titularidad privada/guardas y los casos de revisión. Clasificar sólo entradas expresamente aprobadas; Ambiguo/Negocio no acredita personal ni org por defecto.
- [ ] Probar ambas modalidades y todos los roles; falta de membresía/permiso/estado o control sin regla bloquea la acción. Revisar grants/policies combinadas y sidecar para impedir borrado directo.
- [ ] Verificar datos legados, UUID, referencias entrantes y medios intactos. Entregar **recibo C estructural**, que permite desarrollar D/M sobre titularidad comprobada; no acredita T13/T14 de baja completa ni T48 con acuerdos reales. Esas integraciones requieren B/D/M, contratos y TASK-003 aplicables y son obligatorias antes de X/R. Así se evita dependencia circular C↔M.

## Hito D — Candidaturas y disposición de hijos de perfil

**Interfaces:** consume S0, recibos estructurales B/C y D03; produce matriz resuelta de las 36 FK de perfil, candidaturas estables y recibos mínimos, sin borrado indiscriminado.

- [ ] Escribir T22–24/T38 y fallo de validación: candidata eliminada, reportante, actor sin perfil, recibo idempotente y aviso a contraparte.
- [ ] Añadir/validar referencias Person de candidatura y recibo con UUID conservados, adaptar joins/notificaciones y proteger datos de contraparte. Cada retirada de FK vieja necesita script y autorización del corte D, independientes de X.
- [ ] Resolver por finalidad cada hijo restante: dato personal purgable, vínculo anulable si admite el contrato o evidencia mínima protegida. No convertir todo a RESTRICT ni borrar para facilitar conteos.
- [ ] Ensayar delta de eliminación y conservación del resto, todos los caminos directos/privilegiados y reintentos. Prohibir purga si queda una dependencia sin disposición verificable.

## Hito M — Registro de medios y reemplazo de limpieza

**Interfaces:** consume S0, recibos estructurales B/C, D y D04; produce assets/bindings con FK, plan/claim de objeto y operaciones Storage API autorizadas/reanudables. Paths existentes permanecen hasta decisión específica de migración de objetos.

- [ ] Escribir T33–38/T49 con archivos reales sintéticos: asset compartido, fundador eliminado, service_role sin uid, sustitución de objeto y fallo tras cada llamada externa.
- [ ] Registrar bucket/key/object_id/digest y vínculos/derechos aprobados. Guardas no confían en prefijo, metadata o GUC cliente; ningún DELETE SQL sustituye eliminación física por API.
- [ ] Inventariar owner/owner_id de objetos y propiedad de buckets; comprobar si la versión Auth instalada bloquea la purga por esos objetos. Si ocurre, preparar procedimiento soportado de custodia/reasignación o copia API con hashes y nuevos bindings/URLs, sujeto a D04. No inventar endpoint de cambio de owner ni borrar archivo protegido para desbloquear Auth. Incluirlo en T33/T12 antes de autorizar baja exitosa.
- [ ] Implementar workers con claim/version fencing, bloqueo de key reuse/upsert y reconciliación. La limpieza heredada permanece cerrada hasta demostrar equivalencia y conservación por recurso.
- [ ] Probar lectura/subida/asociación/borrado/firma con actores personales/organizacionales; separar URL/revocación TASK-003. Conservar bytes de terceros y aplicar únicamente deltas permitidos del solicitante.
- [ ] Entregar manifiesto de DB/Storage, errores/reintentos y verificación final; no declarar fase completada por ausencia de filas metadata solamente.

## Hitos K/F — Compatibilidad de servidor y adaptación Flutter por permiso separado

**Interfaces:** consume C/D/M y D07/D08/D10; produce fachadas/DTO v2 y rechazos seguros de v1. F consume U0 y **autorización Flutter específica**, que hoy no existe. Conservar pantallas maduras y componentes.

- [ ] Escribir T25–32/T38/T40: consumidores directos, wrappers/sobrecargas, embeds, feed/avisos/push, binario legado y caché. Definir matriz mínima de versiones/capacidades sin confiar en headers como permisos.
- [ ] Implementar sólo las fachadas/ACL/RLS/guards aprobadas en K, preservando validaciones de ciudad/compensación/registro y campos maduros seguros. Rechazar selección unilateral sin mutar ni convertirla en oferta.
- [ ] Demostrar que no hay accepted/contador/notificación falso por ninguna superficie. Si no existe Agreement activo validado, no hay salida contractual confirmada.
- [ ] Solicitar/registrar permiso F antes de editar Dart. Adaptar repositorios/DTO y pantallas directamente afectadas según U0, sin reemplazar formularios maduros; manejar actualización requerida y fases de baja reales.
- [ ] Probar binarios viejos y nuevo, cache/deep links/offline y consumidor de cualquier 2xx. Si falta artefacto antiguo o una plataforma, reportar bloqueo; no habilitar corte operativo por pruebas JSON o prototipo.

## Hito X — Corte de author_id

**Interfaces:** consume A/S0/B/C/D/M/K/F aceptados en sus alcances, integraciones de baja B/C (T07/T12/T13/T14) y de contrato aplicables (T48), dependencias de TASK-003 para operación y D09. Los recibos estructurales B/C por sí solos no bastan. Produce nueva FK validada a Person RESTRICT; mantiene columna/UUID/ancla. No reutiliza E-PROPOSED-REFERENCE.sql.

- [ ] Preparar SQL final separado y barrera de autorización, schema/body/grants hashes esperados, backup/restore fresco, filas afectadas reales del clon y ventana/timeout medidos. Presentarlo para autorización X; no generarlo como ejecutable automático desde este documento.
- [ ] Escribir T21/T39–41/T44 y pruebas de conservación completa. Verificar que nueva referencia es válida antes de retirar la anterior; injection en cada frontera.
- [ ] Ejecutar sólo en copia nueva autorizada, transacción corta y límites aprobados. Ante drift/orfandad/locks/permiso inesperado, rollback y parada; no desactivar triggers, RLS ni constraints.
- [ ] Comparar todas las filas/catálogos salvo delta DDL expresamente enumerado, diez FK entrantes, medios y contratos. Conservar E1 y runtime anterior; rechazar down-migration que perdería datos o reabriría rutas inseguras.

## Hito R — Recuperación y aceptación integrada

**Interfaces:** consume snapshots después de X, backup DB/Storage/config/roles y ledger independiente de TASK-003. Produce informe de restore/reconciliación con capacidades aún bloqueadas si falta alguna evidencia.

- [ ] Escribir T41–45/T47; simular backup anterior a supresión, fallo de índice/objeto y pérdida del checkpoint del ledger.
- [ ] Restaurar en otro namespace nuevo aislado; comparar roles/catálogo/filas/objetos y reaplicar supresiones antes de exponer. Checkpoint faltante o fallo de derechos mantiene aislamiento.
- [ ] Reejecutar regresiones relevantes TASK-001, diferenciando cierre unilateral/material en TASK-002 y HTTP/Realtime a cargo de TASK-003. Preservar resultados históricos, no sobrescribirlos.
- [ ] Registrar criterios realmente demostrados, pendientes por modalidad/plataforma y límites de fixtures. Regenerar trazabilidad sin validar requisitos integrales parciales.
- [ ] Terminar con revisión de E2 local; **ningún permiso remoto ni cierre automático TASK-002**. Publicación/migración remota requiere evaluación de datos reales, capacidad, respaldo, rollback y autorización independientes.

## Autorrevisión del plan

Cobertura de las seis áreas solicitadas: altas A; eliminación B/D/M; titularidad C/X; compatibilidad K/F; negativas/concurrencia/restore matriz y R; límites TASK-003 en todos los gates dependientes. La revisión independiente identificó S0, T07 fuera de alcance A y dependencia circular C–M: se resolvieron con fence previo y recibos estructurales separados de integraciones posteriores obligatorias. Las decisiones D01–D10 se concentran en el expediente, sin hacer elecciones de producto por inferencia. No hay paso de commit, despliegue remoto ni ejecución autorizada por esta entrega.
