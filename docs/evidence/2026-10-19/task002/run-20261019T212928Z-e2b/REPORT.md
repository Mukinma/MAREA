# MAREA — TASK-002 / E2-B estructural

**Resultado: B_STRUCTURAL_VALIDATED_LOCAL_ONLY. Ejecución detenida. TASK-002 y E2 integral continúan incompletos.**

Dos copias nuevas, sintéticas y aisladas, desde los archivos S0 v3 verificados (que conservan E1/E2-A). No se montaron volúmenes históricos, accedió a datos reales ni modificó entorno remoto. Autorización exacta en AUTHORIZATION.md. Cierre UTC 2026-10-20, corrida iniciada el 19 de octubre.

## Implementación y permisos

Se añadieron siete tablas privadas en collaboration: deletion_policies, deletion_requests, deletion_operations, deletion_manifest_items, deletion_dependency_inventory, deletion_cases y deletion_audit. RLS en todas; solicitudes y controles fuera de cascadas Auth; UUID de operación e input hash para idempotencia, versión esperada y rechazo explícito de colisiones. Un principal sólo tiene una solicitud durable.

Nueve funciones internas implementan bloqueo por mapping auth_user_id, solicitud, progreso, preparación del manifiesto, consulta de caso, denegación de purga y guardas de obligaciones/controles/inmutabilidad. El recibo diferencia received de completed; el progreso permanece BLOCKED, completed:false y purge_ready:false. No existe transición ni capacidad de purga exitosa. Un UUID proporcionado al operador no acredita por sí mismo autorización de una persona.

Tres roles técnicos NOLOGIN (owner/operator/case_reader); dos LOGIN adicionales son exclusivamente fixtures de sesión Unix, sin conexión host. Clientes y service_role no reciben acceso al esquema/tablas ni membresías nuevas. Las funciones administrativas sólo tienen EXECUTE específico; la consulta de caso exige identidad SQL real, asignación, finalidad, caso/política vigentes y tiempo de servidor. No confía en GUC de identidad libre. Se añadieron políticas técnicas mínimas de owner; no se retiraron políticas ni ampliaron privilegios de roles preexistentes. El recibo 15-conservation-v2 contiene el catálogo y ACL efectivos.

Las guardas protegen publicaciones y candidaturas existentes, incluso candidaturas recibidas por misiones de un titular bloqueado. Serialización Auth 0/4201 y misión 4204; contención del guard se rechaza con 55P03 y requiere reintento. Las identidades de candidatura permanecen estables hasta D. No se cambió ningún cuerpo RPC de negocio ni FK.

## SQL y archivos

La versión instalada es la suma, en este orden, de cuatro archivos de laboratorio generados con procedencia CLI y conservados en esta carpeta:

1. 20261019213207_e2b_private_structural_requests.sql.
2. 20261019213631_e2b_parent_obligation_serialization.sql.
3. 20261019214311_e2b_incoming_candidature_manifest.sql.
4. 20261020042015_e2b_review_identity_and_lock_guards.sql.

Cada instalación se ensayó con rollback antes del commit local. No son migraciones operativas autorizadas. tool/task002/b_contract.sql conserva la fuente inicial; por sí solo no representa la versión acumulada corregida.

Herramientas nuevas: b_lab.py y b_stages.py para preflight/etapas; b_install.py, b_cases.py, b_more.py, b_case_sessions.py y b_review_regressions.py para ejecución/pruebas; b_verify_v2.py, b_recovery_v2.py y b_preserve.py para integridad/recuperación; test_b_gates.py, register_b.mjs y seal_b.mjs para controles y trazabilidad. b_verify.py/b_recovery.py y fuentes de intentos anteriores se conservan como historia. Las primitivas S0 y ejecutores anteriores no se editaron. 21-artifact-manifest.json enumera todos los archivos nuevos y las únicas modificaciones documentales anteriores.

## Pruebas y recibos

| Área | Resultado y evidencia |
|---|---|
| Aislamiento y procedencia | PASS: 01/02/02b/03. Preflight vacío y completo antes de restaurar/arrancar servicios con datos; namespace efectivo, loopback sin salida, red none, sin puertos, capdrop ALL, volúmenes nuevos etiquetados. |
| Contratos ausentes y correcciones | RED 04, 06, 10; GREEN 05/07/11. Funciones ausentes, bypass de candidatura recibida y manifiesto incompleto reproducidos antes de corregir. |
| E2-T09 negativo | PASS estructural, 09/09a: DELETE Auth/perfil denegado por ACL o guarda S0 según rol; Auth admin API real primero GET 200 y luego eliminación denegada; cero purgas exitosas. No E2-T07. |
| E2-T10 | PASS estructural, 09/12/18f: replay exacto tras descartar respuesta del consumidor SQL después del commit, claves cruzadas/contenido distinto, versión obsoleta, estado ausente/corrupto, solicitudes simultáneas e inyección de fallo transaccional. No es prueba de pérdida HTTP ni endpoint de cliente. |
| E2-T46 | PASS estructural, 13: sesiones LOGIN reales, caso propio/finalidad/plazo válidos, auditoría; casos ajenos, vencidos, revocados, sin política o fuera de su plazo denegados; GUC falsificado/SET ROLE sin privilegio rechazados. |
| E2-T11 parcial | PASS sólo publicación/candidatura reales y su bloqueo transaccional. No existe motor real de acuerdos/ofertas/reservas ni cobertura organizacional en B. |
| Concurrencia | PASS 12 y 18c: solicitud vs candidatura en ambos órdenes; revisión/retiro de RPC reales, rechazo acotado 55P03 en lugar de 40P01. Operaciones de revisión se revirtieron, sin confirmación contractual. |
| Privacidad y permisos | 09: 70 denegaciones SELECT/INSERT por copia y ACL de funciones; 13 casos; 15-v2 CRUD efectivo denegado a clientes y roles técnicos. |
| Compatibilidad E2-A / S0 | PASS 09/14: mapping desigual Person/Auth, sync bloqueada, 40 guardas S0 intactas, Storage API real lectura 200 y borrado denegado; ingreso destructivo 503. B no expone API nueva ni convierte ese 503 en éxito. |
| Revisión final | Dos Important reproducidos en ambas copias y corregidos en un pase. REVIEW.md y 18b/18c/18e/18f. |
| Herramientas | 59 PASS, cero fallos en 19-postfix-unit-tests.log. No sustituyen pruebas reales. |
| Conservación y recuperación | PASS 15-conservation-v2, 16-final-recovery y 17-preservation. |

Los intentos CASE/MORE/VERIFY/REVIEW y los primeros recibos se conservan. La sesión falsa de SET ROLE desde administrador se sustituyó por conexiones LOGIN genuinas; se mantuvieron los seis casos extra del intento A, sin borrarlos. El delta de notification_preferences se explicó mediante el trigger real y prueba mínima con rollback (15a); no se relajaron comparaciones. Tras la pausa, sólo helpers propios B con sleep agotado se reiniciaron previa comprobación de namespace vacío (18d); no se extendieron TTL de casos ni políticas.

## Deltas exactos y recuperación

Por copia se preservan las 576/569 filas originales, salvo un control personal preexistente de mapping desigual que la solicitud bloqueó explícitamente: sync_blocked, obligations_blocked, blocked_reason, deletion_requested_at, control_version. 15-v2 reconstruye y verifica su hash original; las demás columnas permanecen iguales. Ninguna fila original fue eliminada.

Por copia: cuatro altas Auth reales, cuatro perfiles/principales/aceptaciones legales, cuatro controles nuevos y reemplazo del control anterior; cinco misiones, tres candidaturas, tres notificaciones, dos preferencias y cuatro marcadores legados de baja nuevos. Auth añade cuatro filas en cada tabla de identidad/sesión/refresh/AMR y ocho de auditoría. Sólo avanzaron cuatro posiciones las secuencias de refresh y aceptación legal. 15-v2 enumera hashes/deltas por tabla y catálogo.

Filas privadas nuevas por copia: políticas 2, solicitudes 4, operaciones 6, elementos de manifiesto 6, inventario 98 (49 FK efectivas por cada uno de dos expedientes preparados); casos 12A/6B y auditoría 8A/7B por intentos conservados. Siete tablas, nueve funciones, ocho triggers B, cinco roles (tres técnicos y dos fixtures), dos membresías de fixture y 25 políticas técnicas nuevas; objetos previos intactos.

Los manifiestos conservan IDs de principal, misiones y candidaturas propias/recibidas, operaciones propias y dependencias de catálogo; no copian perfiles, mensajes ni paths. Un prefijo de medio no prueba titularidad. Las 49 FK quedan inventariadas con disposición pendiente, sin cambios referenciales.

16 prueba backup frío PAX y restauración de DB, Storage y coordinación en volúmenes nuevos de ambas copias: bytes, tipos, atributos y timestamps nanosegundo exactos; PostgreSQL arrancó restaurado, snapshot lógico igual, controles consistentes y purga/desbloqueo/caso expirado rechazados. No equivale a E2-R integral ni a compatibilidad con datos reales.

17 demuestra conservación de 1.254 archivos preexistentes, 365 artefactos privados históricos, fuentes S0 y 106 volúmenes anteriores. Cero contenedores activos; 31 de B detenidos. Sin SRS/Flutter/Edge/migraciones operativas/RPC de negocio/FK modificados, staging, commits ni remoto. La actualización canónica posterior y sus vistas se verifican aparte en 20-traceability.json, preservando baseline e historia TASK-001.

## Bloqueos y punto de detención

D02 queda limitada a infraestructura/políticas sintéticas (plazos de prueba, no legales); falta política operacional aprobada por recurso. D03 protege IDs y registra disposición pendiente; no decide retención universal ni modifica FK. D08 separa solicitud/progreso/finalización en contrato privado; reautenticación, endpoint operativo, transporte cliente y pruebas de binarios legados siguen pendientes. No se afirma haber corregido las confirmaciones falsas de clientes fuera de este alcance.

B no implementa organizaciones, acuerdos, ofertas, reservas, revocación TASK-003, disposición física, anonimización ni eliminación integral. T07/T12 integral, T11 contractual, integraciones de titularidad/baja, K/F/X/R y toda aceptación dependiente siguen BLOQUEADOS/NO_IMPLEMENTADOS.

El siguiente bloqueo concreto para C es ORG-0 real y decisiones D05/D06 de titularidad/clasificación; no puede clasificarse Negocio como organización por inferencia. D/M requieren sus disposiciones/medios y autorización específica. Antes de purga integrada serán obligatorios contratos reales, dependencias TASK-003 y decisiones operativas D02/D03/D08. **Se requiere autorización específica del siguiente incremento; no se inició ninguno.**
