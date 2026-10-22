# TASK-002 / E2-A — reanudación R2 detenida por recuperación

**Estado: BLOQUEADO_NO_IMPLEMENTADO. TASK-002 continúa incompleta.** Se cumplió la parada solicitada ante una falla nueva de integridad. No se aplicó DDL de A, no se arrancó Auth ni se ejecutaron fixtures de registro. No hay validación funcional de sincronización/reparación.

## Resultado y causa

El ejecutor nuevo superó el aislamiento en contenedores vacíos y el preflight completo antes de restaurar datos. Se restauró A en volúmenes nuevos y se reprodujo E1 con sus SQL y datos sintéticos verificados, conservando el catálogo y todos los digests/secuencias de las tablas legadas. Se obtuvo el nuevo respaldo frío y se intentó restaurarlo en otro volumen nuevo antes de implementar A. **La igualdad estricta del árbol restaurado falló.** B no llegó a prepararse.

El nuevo ejecutor eligió `docker cp --archive` para exportar el respaldo sin añadir capacidades a los contenedores. Esa exportación conservó bytes, tamaños, modos y uid/gid, pero truncó el `mtime` a segundos enteros. Fue una elección del nuevo ejecutor cuya conservación de precisión temporal no se comprobó antes en vacío. No se atribuye el fallo al verificador de red.

[06-backup-archive-diagnosis.json](06-backup-archive-diagnosis.json) compara **el archivo tar nuevo con su manifiesto frío estable**, sin arrancar servicios ni montar de nuevo volúmenes después de la parada:

| Propiedad | Resultado |
|---|---|
| Entradas esperadas y archivadas | 2.131 / 2.131; mismo conjunto de rutas |
| SHA256 de bytes de todos los archivos | Iguales |
| Tipos, tamaños, modos, uid/gid | Iguales |
| Entradas con mtime distinto | 2.131 |
| Ejemplo PG_VERSION | esperado 1791916126.971736; tar 1791916126 |
| Recuperación exacta | FALLIDA; no aceptada |

El método `cold_backup()` comprobó que el árbol fuente nuevo no cambiara durante la exportación; el tar ya pierde la fracción temporal frente a ese manifiesto. El restore posterior detectó la discrepancia y lanzó `Restored tree mismatch`. No se certifican los bytes del volumen restaurado después de la parada, pues no se ha vuelto a montar/arrancar para inspeccionarlo. El resultado de igualdad de bytes de la tabla se refiere al tar frente al manifiesto, no a una recuperación aceptada.

No se cambió la tolerancia, no se eliminó mtime del oráculo y no se aplicó reparación compensatoria. El recibo [FAILURE-1792418995136753000.json](FAILURE-1792418995136753000.json) permanece intacto.

## Ejecutor nuevo e integración del aislamiento

- Nuevo `tool/task002/e2a_r2.py`; no importa ni llama al ejecutor histórico fallido. Su versión ejecutada está congelada en [EXECUTOR-AS-RUN.py](EXECUTOR-AS-RUN.py), cuyo hash coincide con `executor_sha256` del preflight.
- Usa el socket Unix local Docker explícito y entorno sin overrides de Docker. Imágenes PG/Auth/helper fijadas por ID; sin pull, bridge, host network, puertos publicados o capacidades añadidas.
- `preflight_before_data()` exige primero la prueba en vacío y después el preflight completo. Restore, SQL, PG y Auth exigen los recibos, sus hashes y la versión del ejecutor.
- Reutiliza intactos `e2a_isolation.py`, su probe y el perfil aprobados. Se probaron ancla `none`, helper compartido e independiente nuevos; los tres quedaron detenidos antes de cualquier restore/PG.
- Nuevo `e2a_r2_network.py` verifica la misma configuración de interfaces, túneles inactivos, direcciones, rutas, reglas, forwarding y capacidades durante la ejecución; sólo permite listeners TCP explícitos de loopback. El runtime PG fue verificado antes de SQL. No se llegó a Auth.
- La preparación utiliza sólo copias de archivos de respaldo verificadas, nunca montajes de volúmenes históricos/E1/producto. Los helpers de copia tienen `CapDrop=ALL`, sin CapAdd; los únicos montajes son volúmenes nuevos etiquetados del run.
- Tras el fallo, el ejecutor nuevo también quedó bloqueado mediante la existencia de `FAILURE-*.json`. No puede restaurar, arrancar Auth/PG o ejecutar SQL. Esa barrera es la única diferencia posterior respecto de su versión ejecutada; el hash de ambas versiones consta en [STOP-STATUS.json](STOP-STATUS.json).

El ejecutor histórico `tool/task002/e2a_lab.py` y el verificador previamente aprobado no se modificaron ni desbloquearon.

## Pruebas reales y criterios no alcanzados

| Recibo | Qué demuestra |
|---|---|
| [01-empty-preflight.json](01-empty-preflight.json) | PASS real en tres contenedores vacíos nuevos, sin montajes, capacidades añadidas, puertos o conectividad externa habilitada. Ancla/helper mismo namespace; independiente distinto. Antes de datos/PG/Auth. |
| [02-full-preflight.json](02-full-preflight.json) | PASS de Docker 29.8.2, imágenes, fuente de verificador, hash del ejecutor, archivos fríos y SQL E1, socket local y ausencia de servicios activos tras la prueba vacía. |
| [03-partial-preparation.json](03-partial-preparation.json) | A reproduce catálogo E1 y todas las tablas legadas/secuencias; relojes nuevos de created_at de Person declarados. No certifica backup/restore completo ni B. |
| [06-backup-archive-diagnosis.json](06-backup-archive-diagnosis.json) | Falla de metadatos reproducible a partir de tar/manifiesto nuevos. Sin SQL posterior al fallo. |
| [08-final-verifier-tests.log](08-final-verifier-tests.log) | 20 tests de herramientas PASS: aislamiento, negativos, orden, listeners, fallo cerrado y barrera posterior al error; no son pruebas funcionales A. |
| [09-traceability-tests.log](09-traceability-tests.log) | 34 tests de trazabilidad PASS. |
| [10-functional-status.json](10-functional-status.json) | Cero casos funcionales A aceptados. T01 parcial/no aceptado; T02–06/T08/T44 reparación no ejecutados. T07 excluido. |

No se ejecutaron TDD RED por Auth, implementación ni GREEN del contrato A: el fallo ocurrió durante la recuperación preparatoria anterior a esos pasos. `e2a_r2_cases.py` contiene sólo un scaffolding de los pasos futuros y no se ejecutó. No existe SQL ejecutable de A, nuevo rol/función/trigger/control E2-A ni asignación automática de organizaciones.

La única ejecución DDL fue la reproducción autorizada de **E1** en la nueva copia A, trazada a `E1-LAB-A-EXECUTABLE.sql`; sus principales tienen el reloj del nuevo laboratorio. No se modificaron los E1 históricos. No se confunde esa reproducción con una implementación de E2-A.

## Incidencias auxiliares y conservación

El inventario privado inicial seleccionó por error un archivo que no es insumo de A: la copia offline de imagen de VM `Docker-offline-before.raw`, de 994.662.416.384 bytes. Se solicitó la terminación del proceso propio mediante SIGINT/TERM/KILL; no se montó ni modificó esa imagen ni se arrancó un servicio desde ella. Se corrigió el alcance del inventario a los insumos/recibos E/E1/E2-A, con hash por bloques de 1 MiB; la imagen no insumo se excluye y sólo se registra su stat. No se usa ese intento como evidencia de integridad de la imagen completa. El estado final observable del proceso se registra en el cierre; no se debe presumir su terminación sólo por haber enviado señales.

Una consulta final masiva de metadatos Docker agotó el timeout de 30 s. La verificación de cierre se limita a consultas de metadatos por lotes acotados; no se reanuda ninguna carga de datos ni prueba funcional por ese timeout.

[07-stop-and-conservation.json](07-stop-and-conservation.json) confirma ocho contenedores nuevos detenidos, cero contenedores Docker en ejecución, tres volúmenes nuevos conservados y ningún contenedor Auth creado. Los 286 contenedores previos conservan exactamente los campos auditados: identidad, nombre, State, Mounts e Image. No se afirma igualdad de todos los campos no auditados de Docker.

**Cierre del inventario del host:** [11-initial-inventory-process-status.json](11-initial-inventory-process-status.json) conservó la observación transitoria `Us` tras las señales. La comprobación posterior [11b-inventory-exit-confirmed.json](11b-inventory-exit-confirmed.json) acredita salida del proceso: sesión original terminada con exit 137 y `ps` sin ese PID. Se conserva la observación previa; ya no queda ese proceso de lectura activo. No se reinició el host, Docker ni la VM. La versión del informe anterior a esta confirmación se conserva en REPORT-BEFORE-INVENTORY-EXIT.md.


Los archivos anteriores, SRS, ejecutores históricos, baseline y evidencias de TASK-001/E1 se cotejan con `00-before.json`; los archivos privados relevantes se cotejan con su manifiesto sin exponer secretos. La nueva evidencia de preparación/fallo se añade al YAML conservando los 312 registros previos, los 684 requisitos y los 21 casos de producto. No hay commits, staging, cambios de producto o remoto. El informe de cierre explicita cualquier comprobación que no haya podido concluir; no la convierte en PASS.

Archivos de herramientas nuevos de esta entrega: `e2a_r2.py`, `e2a_r2_network.py`, `e2a_r2_cases.py`, `test_e2a_r2_gate.py`, `test_e2a_r2_network.py`. Artefactos nuevos: este run público y su directorio privado de respaldos/snapshots/comandos. Las únicas modificaciones documentales canónicas permitidas son el YAML y sus vistas generadas; las evidencias históricas se preservan.

## Punto de detención y autorización pendiente

**No se continúa E2-A.** Se requiere autorización específica para corregir y verificar el transporte de respaldo antes de otro intento. La propuesta concreta es exportar un tar PAX por un helper del laboratorio, con el usuario propietario de sus archivos y sin capacidades adicionales, transmitiendo stdout al archivo privado sin montar fuentes históricas; verificar primero con archivos sintéticos de mtime fraccional y después con respaldos/copias nuevos. Deben seguir comparándose exactamente rutas, bytes, modos, uid/gid y mtime. No se propone reetiquetar el backup actual como válido ni debilitar su manifiesto.

La corrección del exportador y otra reanudación requieren aprobación; no se han ejecutado. Las decisiones D02 y siguientes, S0/B/C/D/M/K/F/X/R y TASK-003 permanecen fuera de este intento. Las limitaciones de fixtures y laboratorio no autorizan entornos remotos. **E2-A y TASK-002 permanecen incompletos.**
