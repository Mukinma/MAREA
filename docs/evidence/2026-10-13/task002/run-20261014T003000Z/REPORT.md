# TASK-002 — checkpoint N/T, expediente E y propuesta U0

Fecha local: 13 de octubre de 2026, America/Mexico_City. Recibos UTC del 14 de octubre. Corrida run-20261014T003000Z. **TASK-002 NO ESTÁ COMPLETA.** Se ejecutaron únicamente N/T documentales; E/U0 son propuestas, no autorización de producto.

## Resultado por hito

| Hito | Resultado | Evidencia |
|---|---|---|
| N | Consolidación documental verificada de SRS v5.1.1; adopción efectiva pendiente | 01-N-verification.json, N-authorized-diff.patch, fuentes SRS-5.0/5.1.0/5.1.1 |
| T | Herramientas versionadas y YAML reconciliado; vistas consistentes | 05-reconciliation.json, 14-T-verification.json, logs validate/render/check y segunda generación |
| E | Propuesta técnica; incompleta para autorizar ejecución | docs/task002/E-STRUCTURAL-REVIEW.md, E-PREFLIGHT.sql, E-PROPOSED-REFERENCE.sql, E-source-dependencies.json |
| U0 | Diseño funcional entregado para revisión, sin aprobación Flutter | docs/task002/U0-FUNCTIONAL-DESIGN.md, U0/index.html, screens.json, U0-browser-review.json, 16-U0-final-verification.json |

SHA256 final del SRS v5.1.1:

`4a1c28594e68d26180390b9aea3affce18a619039ad25ad1c8c528dc3d2f4388`

SHA256 histórico v5.0:

`44087ec119772779a7972063299f248ae60009b26119a5c9b179ee75a7911152`

## Norma y trazabilidad

Se conservaron los 521 IDs normativos explícitos y los 313 RF; enumeraciones canónicas intactas. ACEPTADA conserva la aceptación histórica; ACTIVO y cupo confirmado se exigen en la activación inicial atómica. La revisión de siete días naturales queda aprobada provisionalmente, calculada por servidor en UTC y limitada por ejecución. Los contratos aplican al organizador autorizado personal u organizacional.

La fuente de diseño es v5.1.1; la baseline efectiva histórica permanece v5.0. La integración documental no satisface por sí sola la puerta de compatibilidad ni autoriza remoto. No se presume que fixtures sintéticos cubran todos los datos reales.

El YAML schema 2 conserva su baseline original y añade versiones, fuentes históricas, anclas de cláusulas, decisiones y casos. Se preservan los 635 registros históricos y se añaden 49 AUX: 684 registros, con 21 TC-51 pendientes separados. Se conservan las 275 evidencias anteriores y se agregan siete, total 282. Hay 144 registros pendientes de reauditoría normativa. Las dimensiones, criterios, enlaces anteriores e historiales de producto se conservaron; no se elevaron estados de implementación/validación. TASK-001 y sus cinco FAIL permanecen históricos e intactos.

Las cuatro vistas generadas son coherentes. La segunda generación no escribe cambios. La evaluación histórica no se convierte en validación vigente de v5.1.1: validación integral de producto permanece en cero.

## Verificaciones y revisión independiente

34/34 pruebas de herramientas pasan: las 21 existentes y 13 nuevas. Se registran etapas RED/GREEN reales para protección de versiones, autorización, fuentes, criterios/historial, reauditoría y métricas. Los cinco hallazgos de revisión independiente se corrigieron mediante controles/regresiones o revisión del prototipo; los intentos fallidos se conservan como fallos de herramienta/propuesta, no como fallos nuevos de producto ni PASS retrospectivos.

U0 incluye mapa de navegación, 28 interfaces nuevas/modificadas/estados y especificación de actor/acción/estado. Logo, NunitoSans y tokens provienen de MAREA actual. Se conserva el esquema de cinco destinos de AppShell y sus utilidades; no se modifica navegación del producto. El prototipo documental se inspeccionó en navegador: 28 vistas y seis comprobaciones de diseño, incluyendo consentimiento organizador personal/organizacional, privacidad offline, aceptación vencida, destino de cancelación e historial tras terminación. Son simulaciones de propuesta: no acreditan RPC, Flutter, RLS, accesibilidad integral ni dispositivos. El servidor de vista previa sólo sirve artefactos estáticos en 127.0.0.1:8743.

## Límites y decisiones que requieren autorización

1. **E no está listo para ejecutar:** Docker no está disponible por su socket. No se obtuvieron conteos actuales, FK/grants efectivos ni ensayo de recuperación. Se entregan fuentes y consultas de sólo lectura; no se inventan cifras. Antes de aprobar el cambio de autoría/cascada se necesita inspeccionar una copia local verificada y revisar hooks de eliminación, medios y proyecciones.
2. El SQL E es un borrador fuera de supabase/migrations, con barrera de excepción y ROLLBACK. No fue ejecutado ni compilado contra PostgreSQL. Retirar esa barrera o aplicar el cambio requiere aprobación técnica específica.
3. **U0 espera revisión/aprobación:** ningún código Flutter puede implementarse antes de esa aprobación. Los atajos del prototipo hacia superficies no rediseñadas no sustituyen sus pantallas reales.
4. Cualquier implementación funcional posterior —backend, migraciones o Flutter— necesita autorización de la siguiente etapa; esta ejecución se detiene aquí.
5. TASK-003 conserva revocación JWT/Realtime y dependencias de reautenticación, Storage/supresión/restore. No se certifican requisitos integrales que dependan de esos controles. TC-51 continúa pendiente; pruebas de herramienta/prototipo no acreditan los casos de producto.
6. Retención, moderación/resolución administrativa y lanzamiento siguen sujetos a políticas jurídicas/operativas. No se garantizan pagos, indemnizaciones ni cumplimiento externo.
7. La validación local futura será independiente de cualquier autorización remota y de la revisión de datos reales.

## Conservación y alcance

00-preservation-before.json registra respaldo privado documental y manifiesto previo. 13-preservation-check.json comprueba 401 fuentes anteriores, baseline YAML literal, evidencias e historiales conservados. 17-final-checks.json registra las comprobaciones de cierre del checkpoint. Los respaldos documentales no son snapshots DB/Storage ni ensayos de restore.

No se modificaron lib, supabase, migraciones históricas ni tool/staging. No se ejecutaron migraciones TASK-002, funciones de negocio ni operaciones remotas. HEAD/branch/staged se conservan; no hay commits automáticos. La documentación nueva no equivale a implementación validada ni cierre TASK-002.
