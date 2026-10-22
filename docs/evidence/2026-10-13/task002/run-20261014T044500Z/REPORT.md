# TASK-002 — Corrección acotada U0 y diagnóstico independiente E

Fecha local de inicio: 13 octubre 2026, America/Mexico_City. Recibos UTC del 14 octubre. **TASK-002 incompleta. U0 pendiente de aprobación formal; E sin aprobación estructural.**

## U0 corregido para decisión formal

Se conserva la identidad MAREA y el AppShell con sus cinco destinos. Se corrigió el sistema compartido de recursos, facultades y acciones sin rediseñar 28 pantallas ni modificar Flutter. El prototipo sigue siendo referencia funcional, no reemplazo autorizado de pantallas maduras.

El selector de estado es específico de cada recurso. Se separan comunicación/operación y estado contractual. La política devuelve contenido, acciones visibles, acciones habilitadas, consentimiento y motivos de bloqueo por pantalla/actor/titular. Terminales U16/U25/U26 y consultas posteriores no reabren operaciones resueltas. ACEPTADA histórica no obliga a ACTIVO permanente. Aceptar, rechazar, cancelar, consultar y reconocer tienen intenciones/textos/estilos diferenciados.

Enviar sólo muestra incertidumbre: no cambia recurso ni navega a confirmación. Reintento conserva clave/versión y requiere respuesta NO_APLICADA; se deniega sin operación original o si cambió el cuerpo/versión. Protección personal no se bloquea por envío contractual; su aviso es independiente y necesita conexión/permiso para registro remoto. Offline y permiso perdido retiran contenido privado. Estas comprobaciones del prototipo no reparan ni validan revocación JWT/Realtime de TASK-003.

Lucía externa C, invitada I, editora vigente M y vinculada V son escenarios separados; Sofía es editora en C. U09 deriva autopostulación personal propia prohibida y firmas por humanos distintos del SRS vigente. El alcance exacto de control organizacional impeditivo necesita decisión normativa; no se prohíbe postular a todos los miembros. El caso sin elegibilidad resuelta permanece sin acción habilitada.

Artefactos: `docs/task002/U0-FUNCTIONAL-DESIGN.md`, `U0/state-model.mjs`, `U0/screens.json`, `U0/MATRIX.md`, `U0/matrix.json`, `U0/index.html`, láminas `proof-terminal.html` y `proof-uncertainty.html`.

## Verificación y recibos

- **20/20** pruebas del modelo de propuesta, incluidos consentimiento, terminales, roles, ambas modalidades, aislamiento de estados, incertidumbre/protección y proyecciones de navegación. La matriz recorre **7.944** combinaciones de 28 interfaces, seis perfiles de revisión y dos tipos de titular. La matriz es exhaustiva respecto de las muestras declaradas, no de todos los posibles estados/datos reales.
- Navegador final: **31** combinaciones críticas solicitadas, **28** inspecciones de interfaz, **24** casos de comunicación/privacidad; todos PASS. Ensayos adicionales verifican navegación U25→U16 CANCELADO, U16→U18 TERMINADO, U07 membresía vigente→U05 autorizada y flujo consentimiento→envío→error→consulta→reintento con clave estable→seguridad independiente sin confirmación ficticia.
- **34/34** pruebas existentes de herramientas de trazabilidad pasan; no se cambian las herramientas ni los contratos de producto.
- `U0-browser-release.json` vincula recibo a hashes exactos de index/modelo/inventario. `U0-terminal-release.png` y `U0-uncertainty-release.png` junto con `U0-actions-release.png` muestran nueve casos agrupados de las interfaces reales del prototipo. Las capturas iniciales y verificaciones intermedias se conservan.
- `00-before.json`, `08-file-conservation.json` y comprobación de cierre conservan SRS, producto, migraciones/RPC, tool/staging, evidencia TASK-001 y checkpoint previo. La versión previa U0/E y el YAML previo se archivaron antes de corregir.
- El primer ensayo del modelo detectó un booleano indefinido en contenido no visible; se corrigió con coerción explícita. El fallo intermedio permanece en `02-model-tests.log`; no se convirtió retrospectivamente en PASS.

Estas son pruebas documentales/prototipo. No son pruebas concurrentes DB, implementación Flutter, RPC/RLS, cumplimiento integral del SRS ni pruebas con datos reales. TC-51 sigue pendiente y no se elevan estados históricos.

## E: diagnóstico local y límite técnico

`E-local-diagnosis.json` confirma Docker Desktop instalado, daemon/proceso/socket ausentes y psql no disponible en PATH. Los recibos históricos siguen presentes; no se obtuvo conexión local para catálogo/filas/digests o ensayo DB/Storage. Las entradas SQL históricas no se tratan como respaldos y sus recibos de recuperación no se presentan como conservación nueva.

**Diagnóstico de entorno concluido: BLOQUEADO_SIN_BASE_LOCAL_OPERATIVA.** Conservación documental/archivos verificada; **conteos actuales, FK/ACL/RLS efectivos y respaldo/restauración de filas/Storage NO EJECUTADOS**. El expediente técnico se actualizó con este límite, pruebas pendientes y procedimiento de continuación únicamente en copia local identificada/aislada. Sus SQL propuestos siguen intactos y sin ejecutar. Ningún negocio se clasificó automáticamente como organización.

## Dos decisiones independientes

1. **U0:** solicitar aprobación formal del diseño funcional corregido para futura adaptación Flutter acotada, conservando pantallas maduras. La elegibilidad de organizaciones controladas requiere precisión normativa/servidor antes de habilitar ese caso; la interfaz no inventa el permiso ni bloquea todo miembro.
2. **E:** no apto para aprobar el cambio estructural. Requiere laboratorio local operativo, inventario real y ensayo de conservación/recuperación antes de presentar autorización técnica sobre SQL final. Aprobar U0 no aprueba E, migraciones, backend o entornos remotos.

No hubo cambios Flutter, SRS, migraciones históricas/TASK-002, RPC, Supabase remoto ni commits. HEAD se conserva. U0/E documentales no completan TASK-002. Los cinco fallos TASK-001 se mantienen; los de revocación TASK-003 permanecen fuera de alcance.
