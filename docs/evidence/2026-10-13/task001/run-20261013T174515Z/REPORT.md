# TASK-001 — informe de cierre local

Corrida `run-20261013T174515Z`, 13 de octubre de 2026. Revisión Git `989e5b5845deff0afd13703a067a7d7a3775d3bc`. TASK-001 cumple su aceptación de laboratorio aislado, fixtures, pruebas reales de permitido/denegado/concurrencia/expiración y reproducción independiente. El producto conserva cinco regresiones fallidas; ningún requisito se declara integralmente validado. TASK-002 no se implementó.

## Causa y solución de H3

El fallo se reprodujo con listeners sintéticos idénticos dentro de la misma imagen oficial de PostgreSQL. En el bridge interno, el listener respondía desde su red, pero el binding solicitado en `127.0.0.1` no aparecía en los puertos efectivos (`[]`), y el host recibía `ECONNREFUSED`. En el bridge de control, el mismo listener sí era accesible por localhost. No se utilizó el healthcheck de PostgreSQL como prueba de salud de esos listeners. Posteriormente PostgreSQL real inicializó correctamente y completó el replay por el relay.

La causa demostrada es la omisión de publicación/NAT para el endpoint exclusivamente interno sin gateway en esta versión de Docker. No se corrigió esperando más ni cambiando PostgreSQL. El log privado completo del intento original permanece protegido; su huella y las observaciones están en `02-network-resolution.json`. El primer recibo diagnóstico permanece BLOQUEADO porque su predicado esperaba `null` en vez de aceptar también `[]`; no se sustituyó el recibo.

La configuración se contrastó con [publicación de puertos Docker](https://docs.docker.com/engine/network/port-publishing/), [redes internas](https://docs.docker.com/reference/cli/docker/network/create/) y [código oficial del bridge](https://github.com/moby/moby/blob/8af9fe3a36bab3e039862a2ab1cef1880c9b4d03/daemon/libnetwork/drivers/bridge/bridge_linux.go). La atribución causal corresponde a la reproducción observada en Docker Engine 29.8.2/Desktop 4.94, no a una presunción de que toda instalación se comporta igual.

Se aplicó el relay autorizado: proceso UID 10001, sólo lectura, sin capacidades administrativas, credenciales ni código de negocio. Conecta una red de ingreso propia y la red interna de su stack. Publica únicamente API, PostgreSQL y correo local en `127.0.0.1`. OUTPUT/FORWARD IPv4/IPv6 denegados; sólo IP/puerto internos exactos y respuestas establecidas permitidos. El bootstrap del tercer runtime comienza sin destinos y habilita los descubiertos. Los auxiliares NET_ADMIN operaron sólo en el namespace del relay y fueron retirados; ningún servicio operativo conserva ese privilegio.

Las descargas oficiales preparan infraestructura. Los handlers de MAREA permanecen exclusivamente en la red interna, sin rutas a proveedores externos. El arranque en frío detectó un manifiesto JSR faltante y un nombre de auxiliar retenido; se conservaron ambos intentos. La compilación controlada, sin evaluar handlers, produjo los seis bundles con SHA idénticos antes de servirlos. No se abrió egreso de negocio para resolver la caché.

## Infraestructura y H4

Node 24.14.0, Supabase CLI 2.117.0, PostgreSQL 17.6.1.167, Edge Runtime 1.74.3/Deno 2.1.4. Imágenes, paquetes, dependencias y bundles se fijan en los locks de `tool/staging/`. El artefacto privado de la imagen de red permite reutilizar exactamente el image ID; no se afirma que reconstruir desde un mirror APK mutable produzca el mismo digest.

Dos runtimes independientes, `marea-task001-d7522760bb90` y `marea-task001-fd0edb3330b2`, conservan ocho servicios Supabase y relay saludables. Puertos respectivos: API 62001/63001, DB 62002/63002, correo 62004/63004. El primer stack de la continuación, `marea-task001-8798fbb703ba`, fue detenido mediante `stop`, conservando tres volúmenes y retenedores; los otros dos quedaron intactos. El runtime bloqueado original nunca se reinició. Todas las credenciales y datos sintéticos permanecen en directorios privados fuera del checkout.

Las 21 migraciones originales se ejecutaron completas, sin omisiones ni cambio de orden/contenido. Los DROP sustituyen objetos creados anteriormente en esas bases nuevas; los backfills se ejecutaron sin datos de personas. No se usó db reset, linked, deploy ni scripts remotos. `migrations.lock.json` documenta revisión y hashes. El overlay local de integración externa se registra separadamente.

`cron.launch_active_jobs=off` se verificó efectivo, con fuente `configuration file` y `pending_restart=false`, antes/después de cada migración y mediante un backend supervisor cada 100 ms. Se conservaron 2616 muestras off en cada uno de los dos runtimes comparados (2619 en el primero), con cero ejecuciones automáticas. El muestreo no se presenta como observación infinitamente continua: además se inspeccionaron las fuentes y se aborta ante pérdida del supervisor. Vault vacío; push/geocodificación desactivados. Referencia: [configuración oficial de pg_cron](https://github.com/citusdata/pg_cron#extension-settings).

Inventario efectivo: 46 tablas, 139 rutinas, grants de tablas/columnas, RLS/policies, firmas RPC, publicación Realtime y siete buckets: mission-images, post-images, profile-media, showcase-media, story-images, tour-assets, tour-inputs. Las seis funciones conservaron sus políticas JWT originales. No se presume equivalencia con el backend remoto.

## H5: resultados separados

Las cifras siguientes son por runtime; los dos runtimes comparados reprodujeron exactamente los resultados. No se suman reintentos históricos ni ejecuciones duplicadas para aparentar mayor cobertura.

| Unidad | Definidos/cubiertos | PASS | FAIL | NO_IMPLEMENTADO | PENDIENTE | BLOQUEADO |
|---|---:|---:|---:|---:|---:|---:|
| Escenarios de la matriz | 129 / 119 | 113 | 5 | 5 | 6 | 0 |
| Subcasos registrados | 734 | 726 | 5 | 3 | 0 | 0 |

Los cinco escenarios NO_IMPLEMENTADO comprenden cuatro contratos ausentes y un escenario de límites de sesión con tres restricciones sin configurar. Los seis escenarios PENDIENTE corresponden a Android/iOS/hardware. Hay 621 subcasos reales y 113 de inspección (110 catálogos/grants aprobados y tres controles ausentes); cero mocks. PASS de escenario significa únicamente que aprobaron los subcasos registrados, no aceptación exhaustiva ni validación del RF. Los casos no ejecutables carecen de subcasos reales y no se cuentan como ejecuciones.

| Suite | Subcasos | PASS | FAIL | NO_IMPLEMENTADO |
|---|---:|---:|---:|---:|
| Node HTTP | 72 | 68 | 4 | 0 |
| Expiración real adicional de siete buckets | 7 | 7 | 0 | 0 |
| pgTAP | 300 | 300 | 0 | 0 |
| Permisos DML de tablas/columnas | 150 | 150 | 0 | 0 |
| Permisos de invocación RPC | 151 | 151 | 0 | 0 |
| Sesiones JWT y Realtime | 5 | 4 | 1 | 0 |
| Restricciones disponibles de sesión | 4 | 1 | 0 | 3 |
| Edge Functions | 30 | 30 | 0 | 0 |
| Dart de repositorios contra Supabase local | 6 | 6 | 0 | 0 |
| Outbox/leases/idempotencia | 9 | 9 | 0 | 0 |

Separadamente, por runtime comparado: 58 sondas TCP de aislamiento, 10 DNS y 9 de ingreso PASS. Los receptores sintéticos positivos acreditan que la denegación no se deduce sólo de ausencia de conectividad. Se probaron destinos autorizados, red ajena, host/gateway, dirección externa sintética/IPv6 y DNS. La comprobación de ingreso permitió localhost y denegó la interfaz LAN propia e IPv6 localhost; Docker no tiene bindings IPv6 ni LAN. La prueba real de `stop` aprobó. Otros controles: 21 pruebas de integridad y 10 guards PASS.

HTTP se comprobó con datos y postcondiciones SQL; las pruebas de permisos utilizaron usuarios locales y las administrativas sólo preparación/postcondiciones o el worker explícito. Se probaron último cupo concurrente, publicación y candidatura duplicadas, payload distinto, atomicidad, leases, expiración de candidatura, JWT sin refresh y URL firmada de cada bucket con datos almacenados conservados. Se probó el socket Realtime ya abierto sin reconexión voluntaria. Dart ejecutó repositorios reales en host, con red restringida; no certifica dispositivos ni Firebase/proveedores. pgTAP sigue el enfoque de [pruebas de Supabase](https://supabase.com/docs/guides/database/testing).

Los siete casos adicionales de expiración y el ingreso se ejecutaron separadamente en ambos runtimes y después se incorporaron a la CLI para corridas futuras. La ejecución monolítica exacta de esa última lista ampliada no se repitió sobre fixtures usados; sus componentes reales sí se comprobaron. Los resultados originales fallidos del harness, fixtures y caché siguen en los historiales 10/12 con SHA y clasificación. Ningún fallo válido se convierte en PASS.

## Defectos y contratos pendientes

| Regresión fallida | Evidencia funcional | Hallazgos |
|---|---|---|
| Selección unilateral | Candidatura pasa a accepted sin consentimiento bilateral | FND-001 / FND-027 |
| Selección tras cierre | Backend acepta selección de misión closed | FND-011 / FND-028 |
| Cambio material | Cambia título y mantiene aceptación sin revisión/renovación | FND-002 / FND-034 |
| Revocación HTTP | Logout revoca refresh pero el JWT previo conserva lectura privada hasta expirar | FND-037 |
| Revocación Realtime | Socket abierto recibe evento privado tras logout sin reconectar | FND-037 |

Los defectos permanecen FAIL y no se corrigieron. La expiración JWT sí impide acceso después de su plazo y tolerancia observada; no acredita revocación inmediata. No existe modelo organizacional para ensayar expulsión de membresía. No se fabricaron organizaciones, ofertas 72h, reservas ni aceptaciones revisionadas. Esos cuatro escenarios siguen NO_IMPLEMENTADO. Tiempo máximo de sesión, inactividad y sesión única no están configurados en este laboratorio; no se afirma ausencia de capacidades en GoTrue ni el estado remoto.

Se actualizaron mínimamente evidencias e historial de 15 obligaciones normativas, incluyendo RF-23-001, RF-25-007/008, CTR5-01/02/03, CT-SEC-ID-006, CT-SEC-AUT-005, ADR42-02/03/06, AC-08/16 y AT5-03/05. Las regresiones correspondientes pasan a PRUEBAS_FALLIDAS; las dimensiones de implementación/plataformas/distribución no se alteran. Se conservaron 41 FND y todos los eventos anteriores. Todas las suites mantienen `complete_requirement_validation: false`.

La cobertura de filas RLS y la semántica de RPC concedidas por estado/actor/acción sigue parcial: los 150 y 151 casos negativos de grants no sustituyen pruebas completas de cada política. QA Android/iOS, hardware, integraciones externas y aceptación integral permanecen pendientes.

## Evidencias, archivos y aceptación

El YAML canónico incorpora 17 evidencias nuevas (275 en total) y conserva la ejecución BLOQUEADO anterior. Recibos principales: E-TASK001-CONT-BACKUP, CAUSE, STACK, ISOLATION, DNS, INGRESS, SCHEMA, CATALOG, SUITES, REPRO, SOURCE, INTEGRITY, PRESERVATION, PRESERVATION-FINAL, STOP, CHECKS y ATTEMPTS. Cada entrada tiene revisión Git, fecha, referencias y SHA256; los inventarios sensibles no se publican.

`18-change-set.json` enumera las 42 herramientas/locks/tests nuevas, las cinco herramientas modificadas (README, CLI, guards y catálogo) y los cinco documentos modificados: YAML canónico y las cuatro vistas TRACKING/AUDIT_REPORT/TRACEABILITY/CHANGELOG. Incluye huellas de fuentes Dart conservadas. `13-source-binding.json` vincula herramientas, migraciones, funciones y locks. Esta carpeta contiene recibos nuevos, historiales, logs sin secretos y el informe; ninguna evidencia anterior fue sobrescrita. El SRS, SQL, funciones y código del producto no se modificaron.

| Hito | Aceptación de TASK-001 | Evidencia |
|---|---|---|
| H1 | PASS: respaldo completo privado, verificado y origen conservado | 01, 15 |
| H2/H3 diagnóstico | PASS: Docker identificado y mecanismo reproducido | 02-resolution, locks |
| H3 stack/aislamiento | PASS: PG/Auth/Storage/Realtime/Edge locales; puertos y egreso comprobados | stack, isolation, dns, ingress, edge-serve |
| H4 | PASS: replay íntegro, cron off y cero ejecución automática | schema, inventory |
| H5 | PASS de ejecución requerida: permitido/denegado/concurrencia/expiración reales; cinco FAIL del producto conservados | suites de ambos runtimes |
| H6 | PASS: reproducción, historial, controles y SRS intacto | 11, 14, 17 y final-checks |

Los dos respaldos completos anteriores fueron reverificados: 39,879 archivos del original; 39,949 del proyecto de continuación y 11 del runtime bloqueado; también sus 11 archivos de origen. Acceso restringido 0700. Se verificaron permisos/enlaces/fechas/ACL; ditto modificó 1332 atributos xattr durante la copia y sus valores originales se conservaron en manifiestos privados. No se afirma identidad de esos xattrs en la copia. Los sockets son copias dormidas y no se hizo un ensayo de restauración. La copia restringida de cierre de los artefactos se registra en 21-work-backup.json, sin sustituir esos respaldos. Es incremental (docs y tool/staging), no un snapshot de los volúmenes Docker activos.

HEAD, rama y entradas staged se conservan. La app reescribió estadísticas del índice y retiró seis rutas efímeras refs/codex; sus objetos siguen disponibles y los metadatos anteriores están en el respaldo verificado. No se afirma identidad byte a byte de esos metadatos Git. No se hicieron commits, staging, reset ni cambios rastreados.

SHA256 del SRS: `44087ec119772779a7972063299f248ae60009b26119a5c9b179ee75a7911152`. Los controles validate/render/check y segunda generación verifican vistas coherentes, sin nuevas escrituras. No se conectó ni modificó ningún entorno remoto de MAREA; no se modificaron datos reales. La conectividad externa controlada se limitó a documentación y dependencias/imágenes de infraestructura.

Riesgos/límites operativos: stacks, redes, volúmenes, caches y diagnóstico se conservan y consumen recursos. Existen tres conjuntos de puertos aprobados y subredes reservadas; detener un stack conserva su red y no libera automáticamente ese slot para una identidad nueva. La CLI rechaza conflictos, no elimina recursos para reutilizarlos. Para más corridas debe planificarse capacidad local libre preservando los artefactos. No se acreditan equivalencia remota, restore completo, QA de dispositivo ni proveedor real. Estos límites no convierten resultados parciales en validación integral.

Para TASK-002: partir de esta línea base y de las regresiones FAIL, diseñar migraciones aditivas de organizaciones/permisos, ofertas de 72 horas, reservas transaccionales y aceptaciones bilaterales revisionadas; conservar compatibilidad de clientes y ampliar permisos por estado/actor/acción. Tratar FND-037 en el trabajo de revocación correspondiente a TASK-003, con las pruebas de JWT y socket ya abiertas como regresiones obligatorias. Ninguno de esos cambios se adelantó en TASK-001.
