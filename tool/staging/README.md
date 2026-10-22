# TASK-001 — laboratorio Supabase local

Continuación de `run-20261013T164530Z`. Se conserva el runtime bloqueado, sus logs privados y todas las evidencias anteriores. La ejecución actual está en `docs/evidence/2026-10-13/task001/run-20261013T174515Z/`. Consultar allí el informe y los recibos actuales; el catálogo original `matrix.json` conserva sus 129 escenarios y su estado histórico.

La causa de H3 se reprodujo con dos listeners sintéticos idénticos: la red Docker interna mantiene conectividad entre contenedores pero no materializa el binding publicado; el host obtiene ECONNREFUSED. El control bridge sí publica en localhost. No es una carrera que se resuelva esperando PostgreSQL. El relay publica sólo en 127.0.0.1 y une su red de ingreso propia con la red interna aislada. Los servicios Supabase tienen únicamente la red interna. El relay es un proceso sin credenciales, código de negocio ni capacidades administrativas, con rutas TCP fijas a PostgreSQL, Kong y correo local. OUTPUT/FORWARD denegados en IPv4/IPv6; respuestas establecidas y destinos IP/puerto exactos permitidos. Bootstrap comienza sin destinos y habilita únicamente los descubiertos. Los auxiliares NET_ADMIN comparten sólo su namespace y se retiran en finally.

## Procedimiento secuencial

Requiere Docker local Unix saludable, Node 24.14.0, Supabase CLI 2.117.0, Docker 29.8.2 y las imágenes arm64 verificadas en los locks. No actualiza herramientas globales ni descarga imágenes durante el arranque. La imagen de red y las dependencias de funciones tienen huellas propias. `functions-dependencies.lock.json` congela JSR/npm; Deno 2.1.4 prepara dependencias sin ejecutar handlers ni scripts de instalación. La compilación Edge completa los manifiestos JSR durante la fase de infraestructura, sin credenciales ni ejecución de handlers; exige coincidencia exacta con functions-bundles.lock.json antes de servir. El servicio de negocio usa exclusivamente la red interna y esa caché. Las descargas oficiales son infraestructura; nunca autorizan llamadas de negocio externas.

```sh
node --test tool/staging/*.test.mjs
node tool/staging/cli.mjs doctor
# Primera instalación: diagnóstico con recibo 01-backup.json verificado en la corrida.
node tool/staging/diagnose-network.mjs <directorio-nuevo-de-evidencias>
node tool/staging/cli.mjs prepare
# Usar exclusivamente el runtime privado devuelto por prepare.
node tool/staging/cli.mjs start <runtime>
node tool/staging/cli.mjs seed <runtime>
node tool/staging/cli.mjs test <runtime>
node tool/staging/cli.mjs report <runtime>
node tool/staging/cli.mjs stop <runtime>
```

`prepare` selecciona un conjunto libre 61001–61005, 62001–62005 o 63001–63005 y una identidad aleatoria. Directorios privados 0700, claves/fixtures/logs 0600; no copia `.env`, `.temp`, configuraciones ni credenciales existentes. Rechaza proyectos enlazados, symlinks, configuración alterada, endpoints remotos y secretos heredados. `start` rechaza subredes superpuestas y retiene volúmenes/logs antes del rollback automático de la CLI. No usa reset, linked, deploy, ignore-health-check ni recursos remotos.

`seed` ejecuta primero TCP/DNS con receptores positivos controlados, luego las 21 migraciones originales, inventario efectivo y seis cuentas `.invalid`. Las pruebas requieren los recibos más recientes y los mismos namespaces Docker actualmente activos; un fallo de aislamiento bloquea el runtime. No se reinicia un runtime bloqueado. Las sondas de infraestructura esperan el listener de control sintético de `diagnose-network.mjs` en 61202, cuya salud se comprueba antes de aceptar denegaciones. Este diagnóstico requiere 61202 libre en la primera instalación; no repetir sobre los recursos existentes. Debe ejecutarse antes del primer seed del laboratorio; preserva su propio recibo y no contiene negocio.

`replay.mjs` verifica orden y SHA originales contra `migrations.lock.json`. No omite ni reescribe SQL. DDL DROP únicamente sobre objetos creados localmente; backfills sobre base nueva sin usuarios. Configura cron.launch_active_jobs=off con administrador bootstrap local, comprueba valor efectivo/fuente/pending_restart antes y después de cada archivo y lo supervisa en un backend independiente cada 100 ms. Detiene ante valor desconocido, habilitado o supervisor perdido. No hay ejecuciones cron; Vault permanece vacío. Desactiva geocodificación con un overlay local registrado; fuentes intactas y egreso bloqueado durante todo el replay.

`test` sirve las seis funciones con políticas JWT originales y secretos aleatorios de worker exclusivamente locales; verifica también ingreso IPv4 local y denegación LAN/IPv6; ejecuta Node HTTP, expiración efectiva de los siete buckets, pgTAP, permisos de tablas/RPC, outbox, sesiones/Realtime, límites disponibles, Dart de repositorios y Edge. Los privilegios de servicio se limitan a preparación/postcondiciones y el principal worker explícito; autorización de negocio con JWT de usuario. La repetición sobre fixtures usados se rechaza, incluso tras una ejecución parcial. Un defecto funcional conserva FAIL y no detiene las suites independientes. Un error de infraestructura detiene la secuencia y conserva sus logs. `stop` afecta sólo recursos propios, termina antes la CLI de funciones y conserva volúmenes y retenedores.

## Lectura de resultados

La matriz es un plan histórico; los resultados de cada corrida son recibos separados. PASS exige postcondiciones, no sólo HTTP 200. pgTAP diferencia consultas reales y catálogo efectivo. Dart usa una copia privada de lib/assets y lockfile, HTTP restringido a localhost y refresh desactivado; no inicializa Firebase ni prueba Android/iOS/AR/hardware.

Las regresiones de selección unilateral, selección tras cierre, cambios materiales y revocación se conservan como fallos; no se corrige producto en TASK-001. No se fabrican organizaciones, ofertas 72h, reservas ni aceptaciones revisionadas. Cobertura de un escenario significa que tiene subcasos ejecutados, no validación integral: numerosas políticas de fila y semánticas RPC aún requieren expansión por estado/actor/acción. Todas las suites mantienen complete_requirement_validation=false. No hay mocks de proveedores ni integración FCM/Cloud Run/geocodificación externa acreditada.

No publicar logs, claves, fixtures, snapshots de procesos ni manifiestos privados. Los recibos compartibles incluyen resultados, versiones, huellas y límites. Los backups completos permanecen fuera del checkout, privados y verificados. SRS inalterable.

Referencias: [puertos Docker](https://docs.docker.com/engine/network/port-publishing/), [red interna](https://docs.docker.com/reference/cli/docker/network/create/), [pg_cron](https://github.com/citusdata/pg_cron#extension-settings), [pruebas Supabase](https://supabase.com/docs/guides/database/testing), [Deno cache](https://docs.deno.com/go/cache).
