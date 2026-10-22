# TASK-002 / E2-S0 — aceptación local

**Resultado: PASS — VALIDADO_LOCALMENTE, exclusivamente en dos copias sintéticas nuevas y aisladas. Ejecución detenida. TASK-002 y E2 continúan incompletos.**

S0 contiene la limpieza heredada que podía borrar medios por prefijo personal antes de intentar DELETE Auth. Demuestra un corte real anterior al borrado físico, preservación de recursos y rechazo de reintentos. No implementa la baja completa ni autoriza activar estos cambios en el producto.

## Implementación y alcance

Se inspeccionaron los entrypoints, repositorios Flutter, workers existentes y el código de Storage instalado; el [diagnóstico](DIAGNOSIS.md) explica el orden efectivo. Storage v1.72.1 elimina metadatos dentro de una transacción, llama al backend de archivos y después confirma: el rollback DB por sí solo no recupera bytes.

La solución de laboratorio combina PREPARING, invalidación del proceso antiguo, comprobación de quiescencia, guardas SQL constantes y reinicio de Storage con volumen físico RO. Una variante de ingreso bloquea nuevos productores y mutaciones, conserva lecturas y registra únicamente el marcador existente de solicitud tras validar Auth y confirmar REST. Devuelve **503, `completed:false`**, incluso al confirmar recepción; el Flutter legado interpreta cualquier 2xx como purga completa.

No se llama la RPC de baja heredada: también limpia resultados/leases de tours. No se modificaron sus fuentes operativas. El epoch/digest persiste en un volumen de coordinación montado RO en el ingreso. Un estado desconocido, PREPARING o inconsistente falla cerrado. Las guardas y el montaje RO no dependen de que ese archivo afirme ACTIVE.

Es una contención de mantenimiento: las escrituras Storage quedan suspendidas. El operador Docker conserva acceso de inspección; no se afirma resistencia frente a un operador que cambie montajes o un superusuario que deshabilite controles.

## Pruebas y resultados reales

| Verificación | Resultado y evidencia |
|---|---|
| Preflight y procedencia | PASS. [Vacío](01-empty-preflight.json), [completo](02-full-preflight.json) antes de restaurar/servicios; [recuperación inicial](03-clones-recovery.json). Sólo socket Docker local, namespace `none`/loopback compartido, sin puertos publicados, host/bridge ni capacidades añadidas. Imágenes fijadas por digest. |
| E2-T49 RED | [Reproducido A/B](06-T49-RED.json): Storage API real borró bytes del fixture nuevo mientras sobrevivían dos referencias de misión. Se repuso sólo ese fixture por API; sus nuevos UUID/versiones se registran, sin fingir identidad original. |
| E2-T49 GREEN | [PASS A/B](10-T49-GREEN.json). Petición real suspendida en `FileBackend.deleteObjects` antes del borrado; PREPARING, proceso antiguo terminado, PID=0, salida 137, sesiones Storage=0 y transacción revertida. Petición antigua invalidada; reintento privilegiado rechazado. Dos referencias, metadatos y árbol físico exactos: bytes, SHA, tipo, permisos, uid/gid, mtime/atime ns. |
| Rutas y fallos | [70 comprobaciones, 35 por copia](15-additional-tests.json): APIs single/bulk/empty/delete bucket/copy/move/upsert y objetos existentes de siete buckets; Auth admin/perfil; SQL privilegiado/GUC; backstop físico `EROFS`; productores e ingreso REST/TUS/S3 bloqueados; estados desconocidos; reinicios y lecturas válidas. |
| Idempotencia y concurrencia | Respuesta descartada después del commit observable; dos reintentos concurrentes y uno secuencial conservan un único marcador sin alterarlo. Fallo de Auth no confirma registro; ninguna respuesta afirma purga. Pruebas anteriores no dependen de JWT vencidos, 404 o payload inválido. |
| Revisión final | [Hallazgo y cierre](REVIEW.md): faltaba `space` en dos guardas de tours. [RED con rollback](22-space-reference-RED.json), [GREEN SQL/REST](23-space-reference-GREEN.json), sin pérdida persistente. Sólo cambian dos triggers añadidos por S0. |
| Recuperación final corregida | [PASS A/B](26-final-recovery-v3.json): backup frío PostgreSQL y PAX de Storage/coordinación, restauración en nuevos volúmenes, arranque, igualdad lógica/física y temporal exacta. Las guardas `space`, el rechazo Storage y el ingreso cerrado funcionan después de restaurar. |
| Herramientas | [54 pruebas PASS](24-unit-tests-v3.log). Complementan las pruebas reales; no sustituyen la aceptación funcional. |

El hook de T49 sólo controla el interleaving del test sobre el backend instalado; no simula la eliminación ni constituye la protección. La medida es terminar el proceso, comprobar rollback/quiescencia y reiniciar RO. Nunca se reabrió el backend antiguo escribible. Los probes TUS/S3 corresponden al cierre del ingreso local; **no** prueban un backend S3 remoto ni Cloud Run.

El SQL directo de eliminación Storage puede fallar por la guarda instalada `storage.protect_delete()` con 42501; se [clasificó como protección preexistente](17-SQL-denial-classification.json). El rechazo de la API real alcanza la guarda S0 y produce DatabaseError/55000. No se deshabilitó el control del proveedor para fabricar un PASS.

## Conservación y cambios

[Conservación corregida](25-data-conservation-v3.json): las **550 filas originales A y 554 B** permanecen por hash. No hay bajas Auth/perfil. Se contabilizan por separado los INSERT de fixtures y sus nextval; no se normalizan deltas. La estructura sólo añade una función privada SECURITY INVOKER, sin EXECUTE de clientes, y 40 guardas en 14 tablas. No cambian roles, grants, RLS, FK, rutinas preexistentes, `missions.author_id` ni su cascada.

Los 46/51 elementos físicos originales se conservan. Crear el fixture RED cambió el mtime del directorio padre de mission-images **antes de S0**; se registra expresamente. Desde la baseline completa T49, el árbol físico entero coincide sin excepciones, también tras la corrección y recuperación.

[Control global](27-workspace-preservation.json): 1.168 archivos previos, 365 archivos privados históricos, archivos/manifiestos y snapshots fuente E2-A, 405 contenedores históricos y 83 volúmenes históricos conservados. No se montaron volúmenes originales. 23 volúmenes nuevos pertenecen exclusivamente a S0. Los 96 contenedores S0 están detenidos; ningún contenedor corre. Sin commits, staging, remoto, datos reales ni lectura/inventario de la imagen Docker `.raw`.

Archivos nuevos principales:

- SQL ejecutado inicial: [guardas](20261019191834_e2s0_local_fence.sql); [corrección separada ejecutada](20261019210000_e2s0_space_reference_fix.sql), preservando ambos originales. La [copia generada por CLI](20261019205128_e2s0_space_reference_review.sql) tiene bytes idénticos; [procedencia explícita](28-SQL-artifact-provenance.json). Ninguna migración/historia del producto se modificó.
- Ejecutores y pruebas en `tool/task002/s0_*.py`, política SQL y variante `tool/task002/s0/ingress.ts`; versiones históricas conservadas. `s0_fence_v3.py`, `s0_verify_v3.py` y `s0_recovery_v3.py` verifican el resultado corregido.
- Recibos numerados, hashes, manifiestos y este informe. Respaldos y credenciales sintéticas permanecen privados en `marea-backups/task002-s0-20261019T185927Z` (0700), fuera del YAML y del informe.
- Únicos archivos previos actualizados al cierre: YAML canónico y MAREA_AUDIT_REPORT.md. Se regeneraron las cuatro vistas; las otras tres quedaron idénticas. [Sello final](30-traceability.json) y [manifiesto de archivos](31-artifact-manifest.json) comprueban conservación, bindings e idempotencia del render.

Se conservaron los fallos de herramientas y sus recibos: argv Node del helper, desconexión transitoria del daemon Docker (causa interna no determinada), gate léxico que confundía CREATE TRIGGER con TRUNCATE ejecutable, clasificación 42501/55000 y preflight CORS. Las correcciones fueron acotadas y verificadas. La CLI refrescó su caché de versión disponible; el control se detuvo ante esa diferencia y se [restauraron sus bytes originales probados por SHA](29-CLI-cache-restoration.json), sin actualizar la CLI. La revisión `space` se cerró con RED/GREEN y una nueva recuperación, conservando la recuperación anterior como histórica.

## Punto de detención y siguiente autorización

S0 queda validado **sólo** en este laboratorio y detenido; [recibo de parada](99-stopped-v3.json). No hay bloqueo técnico pendiente dentro del alcance S0 probado. Los hashes y recibos demuestran esas copias, no compatibilidad con todos los datos reales ni permiso remoto.

Recomiendo evaluar **E2-B estructural** después de resolver D02 (política de datos), D03 (candidaturas/hijos) y D08 (solicitud/progreso y cliente legado), delimitando TASK-003 y los motores contractuales efectivos. La purga positiva requiere además D/M y autorización de sus pruebas destructivas; no se ejecutó E2-T07. D02–D10 y los demás incrementos conservan sus puertas independientes.

Se requiere autorización humana específica para el siguiente incremento y, por separado, para cualquier parche operativo Edge/Storage, Flutter, FK, entorno remoto o datos reales. **No se inicia E2-B automáticamente ni se declara completa TASK-002.**
