# TASK-001 — Entrega de ejecución parcial

**Resultado: BLOQUEADO, no completado.** Se ejecutaron H1 y H2. H3 falló y se detuvieron H4/H5 según el plan aprobado. H6 conserva las evidencias y la trazabilidad. No hay ejecución esencial de autorizado/denegado, concurrencia o expiración contra MAREA real.

Revisión Git: `989e5b5845deff0afd13703a067a7d7a3775d3bc`, rama `Chris/modern-interactions-push`. Fecha: 2026-10-13; recibos con timestamp UTC. Sin commits ni staging automáticos.

| Hito | Resultado | Criterios acreditados y pendientes |
| --- | --- | --- |
| 1 · Respaldo | PASS | 39,879 archivos, 111 symlinks y 5.96 GB comprobados; 122 rutas sin seguimiento incluidas. Bytes, modos, mtimes, flags, enlaces y ACL verificados; xattrs originales preservados y verificados en archivo privado. Cinco sockets IPC de Git representados como endpoints inactivos. No serializan conexiones vivas. |
| 2 · Docker | PASS | Desktop iniciado; daemon 29.8.2 saludable, 10 CPU y unos 8.3 GB disponibles al runtime. No había contenedores en ejecución. No se alteraron otros stacks. Siete imágenes oficiales descargadas y sus digests registrados. |
| 3 · Supabase | BLOQUEADO | Runtime privado, ID/red propios y puertos 61001–61005 preparados. `start` devolvió ECONNREFUSED al conectar PostgreSQL en 127.0.0.1:61002 con red interna. No hay servicios saludables, claves obtenidas de un stack funcional ni prueba conductual de egreso. Causa raíz exacta pendiente. |
| 4 · Esquema | BLOQUEADO | No iniciado por H3. Inventario de fuentes y riesgos preparado; cero migraciones ejecutadas. Esquema, grants, RLS, RPC, buckets y publicación Realtime efectivos aún sin verificar. |
| 5 · Suites | BLOQUEADO | 129 escenarios especificados; no son suites ejecutables. 117 bloqueados, seis contratos ausentes y seis escenarios de dispositivo pendientes. Cero fixtures, Node HTTP, pgTAP, Dart de repositorio, mocks o QA de dispositivo ejecutados. |
| 6 · Trazabilidad | PASS | Ocho evidencias añadidas al YAML; cuatro corridas y una limitación nuevas. Historial añadido a RF-25-007/008 sin cambiar estados. 21 controles PASS, validate/render/check PASS y segunda generación sin escrituras ni cambio de mtimes. Conservación comprobada con la limitación de índice Git descrita abajo. |

## Infraestructura conservada

Supabase CLI 2.117.0, Node 24.14.0 y Docker 29.8.2; sin actualización global. Runtime fuera del checkout bajo almacenamiento local 0700; marcador, configuración y logs 0600. Proyecto/red `marea-task001-f539874f1218`; red Docker bridge `Internal=true`. Correo local configurado; Edge Runtime, analytics y servicios auxiliares de consola deshabilitados durante esta preparación vacía.

La descarga de imágenes fue tráfico de infraestructura. No se copiaron `.temp`, producción, `.env` ni credenciales existentes. No se suministraron secretos de SMTP externo, FCM o Cloud Run. No se sirvieron funciones MAREA, ni se ejecutaron jobs, geocodificación o peticiones de negocio a proveedores.

La CLI imprimió `Stopping containers` automáticamente tras el fallo. No quedaron contenedores ni volúmenes; se conservaron el runtime, configuración, log íntegro privado, red e imágenes. El agente no ejecutó limpieza ni borrado de volúmenes. No se reintentó el arranque ni se debilitó el aislamiento. Un marcador privado impide reiniciar ese runtime sin revisión del bloqueo.

## Archivos

Nuevos bajo `tool/staging/`:

- [cli.mjs](../../../../../tool/staging/cli.mjs): doctor, prepare, start, report y stop; seed/test son puertas explícitamente bloqueadas, aún sin fixtures/suites implementadas.
- [guard.mjs](../../../../../tool/staging/guard.mjs) y [guard.test.mjs](../../../../../tool/staging/guard.test.mjs): identidad/destino local, permisos, symlinks, hash de configuración y segregación de variables.
- [inventory.mjs](../../../../../tool/staging/inventory.mjs): lectura de fuentes, sin ejecutar SQL; inventario léxico con huellas y referencias.
- [images.lock.json](../../../../../tool/staging/images.lock.json): versiones, siete imágenes arm64 y digests descargados.
- [matrix.json](../../../../../tool/staging/matrix.json): 129 escenarios, identidades, normas, FND, resultados pendientes y postcondiciones.
- [README.md](../../../../../tool/staging/README.md): uso, límites y puertas pendientes.

Modificados: `docs/MAREA_REQUIREMENTS_STATUS.yaml` y las cuatro vistas generadas `MAREA_TRACKING.md`, `MAREA_AUDIT_REPORT.md`, `MAREA_TRACEABILITY.md`, `MAREA_CHANGELOG.md`. El texto manual de las vistas permanece idéntico. El SRS, código de producto, migraciones, funciones, dependencias Flutter y evidencias anteriores permanecen intactos.

Todos los recibos nuevos están en este directorio: 01–07, inventario, logs red/green e integridad, recibos de ediciones canónicas, comprobación de conservación y resolución, controles finales, ledger e informe. No se sustituyeron evidencias de la auditoría anterior. Los inventarios privados del respaldo y las claves/logs locales no se incluyen aquí.

## Pruebas y evidencias

| Modalidad | Ejecución | Resultado |
| --- | --- | --- |
| Unidad en host / filesystem privado | Cuatro casos: URL remota/credenciales, runtime ajeno/enlazado/symlink, variables secretas heredadas, configuración alterada/external y permisos públicos | PASS |
| CLI en host | seed, test y start de runtime bloqueado | Tres rechazos comprobados antes de efectos de negocio |
| Integridad de seguimiento | 21 casos; validate, render, check; segunda generación | PASS; cero escrituras y mtimes iguales en la segunda generación |
| Infraestructura real Docker/Supabase | Descarga de siete imágenes y arranque | Descarga realizada; arranque BLOQUEADO por conexión PostgreSQL rechazada |
| Inspección | Fuentes SQL/funciones, matriz, referencias normativas y FND | 46 tablas declaradas, siete buckets esperados y seis funciones inventariados; no inventario desplegado |
| Negocio real / mock / dispositivos | Node HTTP, pgTAP, Dart local y Android/iOS | Ninguno ejecutado; sin resultados PASS de autorización |

IDs canónicos, sufijo común `20261013T164530Z`:

- `E-TASK001-BACKUP-…`: [01-backup.json](01-backup.json), respaldo `task001-20261013T164144Z`; manifiesto SHA256 `46597bafc0c48e08d8fc04b155666d3b5f7ddd84759dfa31473d741902ff347e`.
- `E-TASK001-DOCKER-…`: [02-docker.json](02-docker.json).
- `E-TASK001-SUPABASE-…`: [03-supabase.json](03-supabase.json); huella del log privado, sin sus contenidos.
- `E-TASK001-SCHEMA-…`: [04-schema.json](04-schema.json) y [source-inventory.json](source-inventory.json).
- `E-TASK001-SUITES-…`: [05-suites.json](05-suites.json).
- `E-TASK001-GUARDS-…`: [06-guards.json](06-guards.json) y log green. El log red inicial conserva el fallo por módulo todavía inexistente; no prueba un rechazo de negocio.
- `E-TASK001-INTEGRITY-…`: [07-integrity-tests.json](07-integrity-tests.json) y log de 21 casos.

También registrado: `E-TASK001-PRESERVATION-20261013T1704Z`, [preservation-resolution.json](preservation-resolution.json). Control final independiente: `E-TASK001-CONTROLS-FINAL-20261013T1710Z`, [final-integrity.json](final-integrity.json), con SHA del YAML, vistas, comandos y log. Los sufijos son identificadores; la fecha efectiva está en `captured_at`.

`complete_requirement_validation: false` en todas las evidencias nuevas. Ningún RF ni plataforma pasa a VALIDADO. Se preservaron por comparación estructurada los 635 registros, estados, asociaciones anteriores y eventos históricos. No se regeneró el YAML desde heurísticas.

## Bloqueos, límites y contratos pendientes

1. H3: conexión rechazada a PostgreSQL con la configuración interna. Resolver en una revisión que mantenga aislamiento efectivo y permita comprobar salud local y egreso. No cambiar a remoto ni abrir la red de negocio como workaround. El bloqueo detuvo las etapas dependientes.
2. Replay: 002:115 elimina una política RLS; 005:12/14/22 elimina restricciones y 005:79 una firma RPC; hay otros DROP inventariados. 017:14 programa un job y 021 configura proveedor real enabled. La prohibición vigente impide aplicar ese replay sin un procedimiento revisado. No se omitió ni reescribió ninguna migración.
3. Organización/membresía, oferta 72h, reserva y aceptación revisionada siguen ausentes. No se crearon entidades ficticias. Las regresiones de selección unilateral, selección tras cierre, cambio material, último cupo y aceptación vencida son especificaciones futuras. Se conservan FND-001/002/011/027/028/029 y los demás FND asociados.
4. Revocación, JWT vencido, Storage firmado/expirado y socket Realtime abierto siguen sin evidencia real. Los dobles futuros no acreditarán proveedores externos. La matriz Android/iOS y degradación ante hardware ausente permanecen pendientes; un test Dart de host no las valida.
5. Conservación: se cotejaron otra vez 39,879 archivos y 111 enlaces, sin rutas perdidas ni enlaces alterados. `.git/index` cambió en bytes durante el uso de Git, pero entradas de staging y flags son idénticos al respaldo, sin cambios rastreados/staged. La comprobación inicial FAIL se conserva y la resolución registra PASS con esta limitación. No se restauró ni reseteó el índice; el original sigue en el respaldo restringido.
6. macOS modifica tags de procedencia/cuarentena al copiar. Los valores originales completos permanecen en el archivo privado verificado; los sockets IPC activos no pueden serializarse. No se realizó un simulacro de restauración funcional y este respaldo no acredita por sí solo CT-OPS-REL-002 o CTR5-06.

Referencias realmente aplicables: RF-23-001, RF-25-007/008, CTR5-01/02/03; CT-SEC-ID-005/006/007/008 y CT-SEC-AUT; ADR42-02/03/05/06/07/15/16; AC-01/02/03/07/08/16/22; AT5-01/02/03/05/06/14/15/19, según cada caso de la matriz. La asociación es trazabilidad temática, sin afirmar cumplimiento integral.

## Conservación normativa y siguiente paso

SRS SHA256 confirmado: `44087ec119772779a7972063299f248ae60009b26119a5c9b179ee75a7911152`.

**Ningún entorno remoto fue modificado ni se crearon recursos remotos.** Ningún dato real fue leído/modificado en esta ejecución. No se ejecutaron reset, linked, deploy, migraciones destructivas, scripts de activación ni verificadores remotos. No se retiraron funcionalidades ni se cambió el alcance.

TASK-002 conserva su dependencia de TASK-001. Primero resolver H3 y el replay seguro; después implementar y ejecutar las suites pendientes para obtener el baseline real. Con ese baseline y las regresiones, iniciar el diseño aditivo de organizaciones/permisos, ofertas 72h, reservas transaccionales y aceptaciones revisionadas, preservando contratos de clientes soportados. Este trabajo no implementó TASK-002.
