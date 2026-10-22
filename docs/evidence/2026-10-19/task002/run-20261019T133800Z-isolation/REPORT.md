# TASK-002 — diagnóstico y corrección del verificador de aislamiento

Fecha: 2026-10-19. Resultado del diagnóstico: **AISLAMIENTO EFECTIVO VERIFICADO SÓLO EN CONTENEDORES NUEVOS VACÍOS**. Estado de E2-A: **BLOQUEADO_NO_IMPLEMENTADO**. Su reanudación requiere autorización humana nueva y específica. TASK-002 continúa incompleta.

## Causa raíz reproducida

El predicado anterior exigía literalmente `[nombre for índice, nombre in socket.if_nameindex()] == ['lo']`. En un contenedor recién creado con `--network none`, Python enumera diez interfaces: `lo` y nueve plantillas de túnel del kernel. El resultado es idéntico en el helper que comparte namespace y en otro namespace independiente, ambos sin datos, montajes ni capacidades.

[03-reproduction.json](03-reproduction.json), [04-netlink.json](04-netlink.json) y [13-kernel-provenance.json](13-kernel-provenance.json) demuestran:

| Índice | Interfaz | Tipo rtnetlink | Estado | Configuración |
|---|---|---|---|---|
| 1 | lo | loopback, ARPHRD 772 | UP | 127.0.0.1/8 y ::1/128 |
| 2 | tunl0 | ipip | DOWN | sin enlace subyacente, extremos no especificados |
| 3 | gre0 | gre | DOWN | ídem |
| 4 | gretap0 | gretap | DOWN | ídem |
| 5 | erspan0 | erspan | DOWN | ídem |
| 6 | ip_vti0 | vti | DOWN | ídem |
| 7 | ip6_vti0 | vti6 | DOWN | ídem |
| 8 | sit0 | sit | DOWN | ídem |
| 9 | ip6tnl0 | ip6tnl | DOWN | ídem |
| 10 | ip6gre0 | ip6gre | DOWN | ídem |

Las nueve plantillas carecen de direcciones IP y rutas. No hay veth, interfaz física ni puerta de enlace. `/sys/class/net` las identifica como dispositivos virtuales; `socket.if_nameindex()`, `/proc/net/dev` y rtnetlink coinciden. La API de Python funciona correctamente.

El kernel observado es `7.0.14-linuxkit`, aarch64. `/proc/config.gz` confirma `CONFIG_NET_IPIP=y`, `CONFIG_NET_IPGRE=y`, `CONFIG_NET_IPVTI=y`, `CONFIG_IPV6_VTI=y`, `CONFIG_IPV6_SIT=y`, `CONFIG_IPV6_TUNNEL=y` y `CONFIG_IPV6_GRE=y`. Los tipos están compilados dentro del kernel; las plantillas aparecen desde la creación de namespaces vacíos, antes de ejecutar aplicación alguna. No las crea Auth ni una restauración del producto. No se ha modificado el kernel o Docker Desktop.

**Conclusión:** falso positivo del predicado de enumeración ante esta configuración legítima del kernel. Las vistas efectivas no muestran exposición externa en los contenedores examinados. Esto no certifica retrospectivamente los namespaces del intento anterior, que no se han vuelto a arrancar.

Además había un defecto independiente de orden: el guard de interfaces estaba dentro de `http()`, llamado desde el health check posterior al arranque de Auth. El preflight inicial sólo comprobaba metadatos/archivos. La fuente exacta anterior se conserva en [e2a_lab.before.py](e2a_lab.before.py); el fallo original permanece íntegro en su ejecución histórica.

## Cambio exacto y garantías

Archivos nuevos:

- `tool/task002/e2a_isolation.py`: verificador con errores explícitos que funcionan también con Python `-O`; comparación de vistas independientes; primitivas de captura vacía y orden de preflight.
- `tool/task002/e2a_isolation_probe.py`: consultas locales de kernel por rtnetlink, `/proc`, sysfs, `socket.if_nameindex()` y comandos BusyBox compatibles. No realiza conexiones IP ni configura la red.
- `tool/task002/e2a_isolation_policy.json`: perfil fijo de configuración completa observado y revisado; no aprende ni amplía permisos durante la verificación.
- `tool/task002/test_e2a_isolation.py`: regresiones positivas/negativas y barreras de arranque.

Archivo existente modificado: exclusivamente `tool/task002/e2a_lab.py`, para bloquear su dispatcher Docker, arranques y CLI antes de cualquier efecto. Este ejecutor apunta a un run archivado y no puede reutilizar sus volúmenes ni escribir nuevos recibos. [15-exact-existing-verifier.patch](15-exact-existing-verifier.patch) contiene el diff completo; [20-verifier-source-manifest.json](20-verifier-source-manifest.json) fija los bytes de los cinco archivos. La aserción histórica queda inaccesible, preservada para diagnóstico; el verificador nuevo la sustituye en el laboratorio vacío. No se ha conectado el nuevo verificador a una ejecución de E2-A ni se ha arrancado E2-A.

La comprobación nueva exige conjuntamente:

1. Imagen local fijada por ID; usuario 1000:1000; rootfs de sólo lectura; `CapDrop=ALL`, ninguna capacidad añadida, `no-new-privileges`, cero capacidades efectivas/permitidas/heredables/bounding/ambient.
2. `NetworkMode=none` en el ancla y `container:<ID completo del ancla>` en el helper; ninguna red adicional, IP/gateway Docker, puertos publicados, montajes o dispositivos.
3. Igualdad de namespaces efectivos entre ancla y helper, incluyendo inode, `/proc/self/ns/net`, PID 1 y captura rtnetlink. Un namespace independiente debe ser diferente.
4. Inventario exacto de enlaces con índices, tipos, flags, configuración completa LINKINFO, direcciones de enlace, iflink y sysfs. Sólo las plantillas inactivas concretas, sin extremos ni enlace subyacente, satisfacen el perfil; nombres conocidos por sí solos no bastan. Un túnel activado o configurado se rechaza.
5. Únicamente las direcciones de loopback, rutas locales IPv4/IPv6 y reglas exactas capturadas. Se consultan todas las tablas por rtnetlink y `ip ... route show table all`. Cualquier ruta, dirección, regla, gateway o multipath adicional se rechaza. Las entradas de rechazo IPv6 de `/proc` se conservan y verifican; no son rutas utilizables de salida.
6. Forwarding IPv4 e IPv6 explícitamente deshabilitado. La captura inicial tenía IPv4 forwarding=1, sin enlace ni ruta de salida; no se usó como prueba suficiente. Se crearon otras tres copias vacías con `--sysctl net.ipv4.ip_forward=0 --sysctl net.ipv6.conf.all.forwarding=0`; el helper hereda el namespace, sin capacidades adicionales. No se tocó ninguna copia anterior.
7. Coincidencia entre API Python, sysfs, `/proc`, rtnetlink y herramientas locales. Ausencia de sockets de servicio en el laboratorio vacío. Información faltante, incoherente, dump interrumpido, error de herramienta o configuración desconocida cierran la comprobación.

Se excluyen sólo contadores/cache temporales de rtnetlink al comparar configuración; no se omiten interfaces, direcciones, tablas, gateways, reglas ni configuración de túneles. No hay excepción genérica para interfaces DOWN ni lista permisiva por nombres. El perfil es deliberadamente restrictivo para este laboratorio y falla ante drift. No sustituye el preflight futuro de versiones, datos, catálogo y permisos de E2-A.

## Pruebas y recibos

| Control solicitado | Evidencia y resultado |
|---|---|
| Reproducción real del fallo | Tres helpers vacíos originales; el predicado devuelve falso en los tres, con vistas concordantes. `03`, `04`, RED `07`. |
| Aislamiento positivo real | Otros tres helpers vacíos con forwarding=0; ancla y helper comparten `net:[4026532842]`; independiente usa `net:[4026532982]`. `09`, `10`: PASS. |
| Interfaces/rutas inesperadas | Fixtures negativos de interfaz adicional, activación, extremo remoto, direcciones, defaults IPv4/IPv6, tabla adicional, multipath y reglas: rechazo. `11`, `12`. |
| Configuración incompatible | Fixtures host/bridge/default/shared incorrecto, IP efectiva, puertos publicados, capacidades, privilegios, montajes y forwarding: rechazo. No se crearon redes inseguras para probarlo. |
| Correspondencia de namespaces | Positivos reales compartido/independiente; negativos con destino declarado distinto, namespace efectivo distinto, PID 1/inode/rtnetlink incoherentes: rechazo. |
| Información incompleta | Omisiones de vistas, rutas, enlaces, privilegios, sockets, comando fallido/ausente y discrepancias de índices: rechazo. |
| Orden de arranque | Callback de servicio vacío sólo después de PASS; ante FAIL, excepción o respuesta incompleta nunca se invoca. Dispatcher/arranques/CLI del ejecutor histórico bloqueados antes de Docker. `17` registra rechazo real del CLI con exit 1, sin escribir en el run antiguo. |

[11-isolation-tests.log](11-isolation-tests.log): **12 métodos PASS**, con **51 subcasos parametrizados** registrados además de los métodos en [12-isolation-tests.json](12-isolation-tests.json). [16-tests-optimized-python.log](16-tests-optimized-python.log): 12 PASS con `-O`. [18-traceability-tests.log](18-traceability-tests.log): 34 PASS.

Las negativas de configuraciones peligrosas utilizan copias manipuladas de los recibos, no interfaces ni rutas inseguras reales. Las positivas de aislamiento y namespaces sí se ejecutaron en contenedores nuevos. No se probó arranque real de Auth ni PostgreSQL: está prohibido en esta autorización. La barrera de orden está comprobada mediante callbacks y denegación del ejecutor, sin simular un registro exitoso.

Incidencias auxiliares conservadas en el diagnóstico: el primer recolector trató `bonding_masters` como symlink y falló; se identificó como entrada de control regular vacía, que ahora se registra y compara. BusyBox rechaza `ip -details`; esa salida está en `03`. La captura definitiva usa `ip link show`, más rtnetlink estructurado para los detalles completos. Una primera lectura de metadatos usó la clave opcional `Config.Volumes` como obligatoria y falló antes de crear contenedores; la imagen carece de volúmenes declarados. Ninguna incidencia habilitó acceso o una excepción de red.

## Conservación y límites

[19-command-scope-audit.json](19-command-scope-audit.json): 53 comandos registrados; exactamente seis arranques de la imagen helper fijada, con Python durmiendo; ningún montaje, volumen creado, puerto publicado o capacidad adicional. Los exec y stop corresponden exclusivamente a esos helpers nuevos. No hubo conexión IP de prueba, descarga de imágenes, SQL/DDL/fixture, Auth, Supabase, PostgreSQL ni acceso remoto. El Docker endpoint verificado es el socket Unix local; posteriormente se fijó explícitamente en las llamadas del reproductor.

[14-closed-and-preserved.json](14-closed-and-preserved.json): los seis helpers están detenidos, cero contenedores en ejecución; inventario de volúmenes igual. Los 280 contenedores previos conservan exactamente estado de ejecución, montajes, imagen y NetworkSettings.

**Diferencia de metadatos declarada:** la primera comparación exacta detectó `HostConfig.Dns: null → []` en tres contenedores del intento E2-A anterior; se conserva en [14-preservation-first-check-drift.json](14-preservation-first-check-drift.json). Ambas representaciones carecen de servidores DNS explícitos. No se ha establecido la causa de esa diferencia de representación, ni se ha reparado o modificado ningún contenedor antiguo. No se afirma igualdad byte a byte de todo su HostConfig. Los comandos sólo consultan metadatos de contenedores antiguos; no los arrancan, actualizan ni montan. Esta salvedad no afecta las pruebas de aislamiento de los seis helpers nuevos, pero permanece disponible para revisión.

El manifiesto inicial `00` protege los archivos y evidencias previos; `02` fija también digests de los respaldos y recibos privados anteriores sin exponer secretos. La verificación final coteja estos manifiestos, los outputs históricos, el SRS, código de producto y ausencia de cambios staged/HEAD. La única modificación permitida de herramienta anterior es el guard documentado en `e2a_lab.py`; sus bytes originales se conservan. El hash histórico de esa herramienta se mantiene en el YAML y se refiere a su versión anterior, disponible en el snapshot; no se reconfirma artificialmente como código vigente.

El registro canónico sólo añade evidencia de diagnóstico y la barrera de reanudación. No cambia evaluaciones de requisitos ni casos de producto, ni promueve la evidencia fallida a PASS. Los recibos originales del fallo, E1, TASK-001 y su baseline permanecen conservados. La sincronización de identidades y las pruebas E2-T01–06/T08/T44 siguen sin implementar/ejecutar en E2-A; no se amplía ninguna autorización.

## Autorización específica pendiente y detención

Se solicita autorización **para reanudar exclusivamente E2-A bajo sus condiciones originales, en copias locales nuevas, sintéticas y aisladas**, usando el preflight corregido ANTES de restaurar/arrancar cualquier servicio con datos. La integración de ese preflight con el nuevo ejecutor debe verificarse primero en vacío; después deberán repetirse las precondiciones de E1, backups, versiones, catálogo, permisos y digests. No se reutilizará el run bloqueado. Si falla una precondición, se detendrá sin ampliar el alcance.

No se solicitan E2-T07, eliminación de cuentas, otros incrementos E2, migraciones de misiones, Flutter ni remoto. **La ejecución se detiene aquí. Un PASS del laboratorio vacío no autoriza E2-A, E2 completo ni TASK-002.**
