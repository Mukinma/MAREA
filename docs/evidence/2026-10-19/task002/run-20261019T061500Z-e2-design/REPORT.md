# TASK-002 / E2 — diseño técnico y expediente, sin ejecución

**19 octubre 2026. Análisis y planificación entregados. E2 NO AUTORIZADO / NO IMPLEMENTADO / NO EJECUTADO. TASK-002 INCOMPLETA.** E1 y sus evidencias se preservan con el mismo alcance sintético local; no se reinterpretan como compatibilidad universal ni permiso remoto.

## Entregables

| Artefacto | Contenido |
|---|---|
| `docs/task002/E2-TECHNICAL-DESIGN.md` | Alternativas, recomendación de titularidad privada, 12 invariantes, sincronización/reparación, eliminación/minimización, medios, migración, compatibilidad, locks y recuperación |
| `docs/task002/E2-AUTHORIZATION-DOSSIER.md` | Diez decisiones pendientes, alcance exacto propuesto de E2-A, puertas independientes posteriores, riesgos y límites de aceptación |
| `docs/task002/E2-IMPLEMENTATION-PLAN.md` | Incrementos A/S0/B/C/D/M/K/F/X/R; recibos estructurales e integrados; ORG-0 y TASK-003 explícitos, sin commit ni despliegue |
| `docs/task002/E2-TEST-MATRIX.md` | 49 casos propuestos, positivos/negativos/concurrentes/compatibilidad/recuperación; todos NO EJECUTADOS |
| `docs/task002/E2-DEPENDENCY-INVENTORY.json` | 85 fuentes con SHA, 116 anclas, catálogo derivado de snapshots E1: 36 FK de perfil, diez entrantes a misión, 56 rutinas relevantes |

## Conclusiones concretas

Cambiar sólo la FK de autoría no preserva candidaturas, medios o permisos. Se recomienda conservar ancla/UUID y autoría, separar titularidad personal/organizacional con integridad referencial y clasificar por evidencia. La tabla organizacional y sus membresías no existen: ORG-0 debe implementarse/validarse en su propio incremento antes de esa FK; no se fabrican placeholders ni propietarios.

Antes de activar el cambio estructural se necesita S0: neutralizar la limpieza por prefijo y sus ejecuciones ya iniciadas, comprobar bytes en la versión Storage real y revalidar backup. Guardar Auth al final no devuelve un archivo ya eliminado.

Flutter trata todo 2xx de delete-account como eliminación completada; cambiarlo a 202 sin adaptar el consumidor sería un éxito falso. accepted_count, tablas de candidaturas, notificaciones, feed y wrappers son vías que requieren protección; bloquear sólo la selección RPC no satisface el SRS. No se transforma accepted histórico en acuerdo.

La documentación Supabase también advierte que propiedad técnica de objetos Storage puede impedir borrar Auth. El registry por recurso no resuelve por sí solo owner/owner_id: M/D04/T33 deben verificar el mecanismo instalado y una custodia o copia soportada con hashes/derechos/URLs, sin borrar evidencia ni fabricar otra cuenta. No se afirma haber ensayado esa restricción en esta revisión.

La retención, derechos de medios, clasificación y elegibilidad relacionada permanecen pendientes de decisiones explícitas. El UUID de Person coincidente con Auth no es anonimización irreversible. Los defectos HTTP/Realtime de TASK-003 no se implementan ni se elevan a PASS; bloquean la aceptación integral dependiente.

## Revisión y controles de esta entrega

La revisión independiente encontró y permitió corregir S0, T07 fuera del alcance de A y dependencia circular C–M. Recibo `02-independent-review.md`. La autorrevisión posterior verifica coherencia, casos numerados y referencias. No se solicitan rondas generales nuevas: el expediente concentra decisiones D01–D10 y propone **sólo A** como siguiente permiso implementable por separado.

Se ejecutan controles documentales de preservación, consistencia y las 34 pruebas existentes de herramientas de trazabilidad; **ninguno es prueba funcional de E2**. No se ejecutaron los harness E1/E, Docker, SQL, APIs Auth/Storage o migraciones. Las referencias externas consultadas son documentación pública, no proyectos ni bases remotas.

El YAML registra evidencia documental y progreso de diseño E2 sin cambiar fichas/criterios de requisitos, TC-51, resultados anteriores o autorización de E1. Sus vistas se regeneran y se comprueba idempotencia. Los recibos de esta carpeta enumeran cambios y huellas; todo el SRS, producto, herramientas previas, evidencias TASK-001/E1/E/U0 y propuestas SQL anteriores deben permanecer iguales.

## Autorización todavía necesaria

El siguiente paso propuesto es revisar/aprobar D01 y autorizar **E2-A local** con SQL separado, altas/reparación privadas y controles mínimos, copias nuevas sintéticas y pruebas sin DELETE Auth/perfil. A no toca author_id/FK/candidaturas, medios, organizaciones, RPC de negocio, Edge de baja, Flutter o remoto y se detiene antes de S0/B/C/D/M/K/F/X/R.

Corte X requiere expediente SQL final y todas sus precondiciones/validaciones; no se solicita ejecutarlo ahora. Las pruebas con fixtures no autorizan migración remota. TASK-002 sólo podrá completarse con sus criterios integrales demostrados, no con estos documentos.
