# TASK-002 / E2-A — ejecución detenida por precondición de aislamiento

**19 octubre 2026. D01 APROBADO; E2-A AUTORIZADO LOCAL, BLOQUEADO / NO IMPLEMENTADO / NO ACEPTADO. TASK-002 INCOMPLETA.** La arquitectura E2 está aprobada conceptualmente; esto no autoriza ejecutar otros incrementos. Instrucción humana y límites en AUTHORIZATION.md.

## Bloqueo verificado

La comprobación dentro del helper, configurado con `--network container:<PG nuevo>` sobre un PG con NetworkMode `none`, exigía `socket.if_nameindex()` igual a `['lo']`. **Falló esa condición.** No se imprimió la lista de interfaces y no se afirma cuál adicional existía ni que se haya realizado conexión externa. La guarda abortó antes de construir/enviar la petición HTTP `/health`.

`FAILURE-1792416399489362000.json` conserva el fallo; el error privado contiene `AssertionError: Non-loopback interface`. El código de reproducción está en tool/task002/e2a_lab.py, función http. No se relaja la guarda ni se cambia red/privilegios para seguir. Conforme a la instrucción explícita del usuario de parar ante fallo de aislamiento, **se detuvo la ejecución**.

Auth alcanzó a arrancar en la copia A antes de esa comprobación. Sus logs indican versión v2.196.0 y cero migraciones aplicadas; no acreditan que el aislamiento efectivo o la integridad completa posterior sean correctos. Quedaron apagados los tres contenedores nuevos de A (PG, PG de recuperación y Auth). No se arrancó B. El recibo STOP-AFTER-FAILURE acredita cierre y estado/montajes/imagen de contenedores anteriores iguales, sin montar volúmenes originales.

## Trabajo realmente ejecutado

| Control / operación | Resultado real | Alcance acreditado |
|---|---|---|
| Socket Unix local, Docker 29.8.2, cero contenedores previos activos | PASS | Identidad inicial del motor, no prueba conductual completa de red |
| Imágenes PG/Auth/helper fijadas por SHA y archivos fríos/E1 SQL | PASS | Fuentes locales verificadas; sin upgrade/pull ni acceso a proyecto remoto |
| Restauración de DB/Storage A desde archivos conservados, en nuevos volúmenes | PASS parcial de preparación | Igualdad de manifiesto físico antes de arrancar, sin tocar volúmenes E1 |
| Reproducción E1 en la nueva DB A | PASS | Catálogo normalizado y 100 tablas legadas iguales; seis mappings correctos. created_at técnico nuevo declarado, no hash histórico idéntico de persons |
| Respaldo frío de esta nueva baseline A y restore en otro volumen nuevo | PASS | Igualdad de catálogo/filas/secuencias entre ambas copias antes de arrancar Auth |
| Arranque Auth A | Iniciado; no aceptado como preflight completo | Log de versión y cero migraciones; HTTP health no llegó a enviarse |
| Comprobación de interfaces efectivas del helper | **FAIL / BLOQUEANTE** | No se acredita namespace exclusivamente loopback |
| Copia B / fixtures INSERT / RED / DDL A / GREEN | **NO EJECUTADOS** | No hay nuevas identidades de fixture ni implementación de A |
| E2-T02–06, T08 y reparación concurrente T44 | **NO EJECUTADOS** | No se presentan como PASS o validación parcial del incremento |
| E2-T07 y pruebas de baja | NO EJECUTADOS, prohibidos | Ningún DELETE Auth/perfil |
| Contenedores nuevos y preservación anterior | PASS de cierre | Nuevos apagados, volúmenes/logs retenidos, originales no montados |

El preflight inicial aprobado no se convierte en aprobación de aislamiento tras el fallo conductual. E2-T01 queda bloqueado en su condición de entorno; detectar el problema no equivale a aceptar E2-A. No se vuelve a arrancar ninguna copia ni se consulta SQL para completar pruebas después de esta parada.

## Archivos, datos y permisos

Creado: `tool/task002/e2a_lab.py` (harness de preparación/guardas, sin implementación de las funciones de identidad A) y esta carpeta de autorización, ledger, snapshots, fallo, cierre, informe y controles documentales. El proyecto privado CLI generó `20261019132322_e2a_private_identity.sql`, que permanece **vacío**; no se añadió ni cambió ninguna migración en supabase/migrations.

No se crearon roles PostgreSQL E2-A, policies, controles, reconciliador o trigger de A. No se modificaron handle_new_user, RPC de negocio, author_id/FK, candidaturas, Edge de eliminación ni Flutter. La única creación de esquema ejecutada fue la reproducción del E1 ya verificado en una **nueva copia A**, no en sus volúmenes originales. No se introdujeron fixtures de alta ni se alteraron datos reales; no hubo commits, staging ni modificaciones de entornos remotos.

Los archivos y evidencias históricos E1/E2/U0/TASK-001 y SRS deben conservar sus hashes; el recibo final de esta corrida comprueba esas fuentes y las evaluaciones de requisitos. El YAML añade la aprobación de D01, la autorización exclusiva de A y su bloqueo; no eleva requisitos/TC o implementación a validación integral. Las comprobaciones de trazabilidad son documentales, no pruebas funcionales de A.

**Límite de conservación de datos:** se verificó la baseline nueva A antes de Auth y se conservaron sus archivos/backup. No se afirma una comparación SQL final después de arrancar Auth, porque ello exigiría reabrir la copia tras el fallo. Se preservan el volumen detenido y logs para un diagnóstico posterior expresamente autorizado. No hubo acceso a los volúmenes originales para obtener ni para «reparar» esa evidencia.

## Autorización concreta necesaria para desbloquear

Se solicita autorizar **diagnóstico y corrección exclusivamente del aislamiento de laboratorio**, reproduciendo primero el comportamiento de namespace/interfaces en contenedores nuevos **sin datos ni volúmenes de producto**, sin arrancar E1/originales, sin Auth/SQL de negocio, sin puertos externos ni remoto. Determinar por qué la red efectiva no satisface la guarda y presentar/verificar una solución acotada antes de reintentar el preflight de E2-A. No se presupone permiso para bridge/host network, privilegios amplios o desactivar protecciones.

D01 y la autorización de A se conservan, pero no se intenta continuar automáticamente después de este fallo. S0/B/C/D/M/K/F/X/R, retención/supresión definitivas D02 y TASK-003 permanecen fuera de alcance. E2-A y TASK-002 siguen incompletos.
