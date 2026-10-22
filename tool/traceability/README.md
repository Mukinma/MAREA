# Mantenimiento de la trazabilidad de MAREA

El SRS es la norma; sólo se modifica con autorización normativa explícita y conservación de fuentes históricas. `docs/MAREA_REQUIREMENTS_STATUS.yaml` es el único registro canónico de estados, decisiones, pruebas y evidencias. Los cuatro documentos derivados son vistas generadas. Esta herramienta no clasifica requisitos, no consulta Supabase y no ejecuta pruebas de negocio.

## Comandos reproducibles

Desde la raíz del repositorio, con Node 24:

```sh
npm ci --prefix tool/traceability --ignore-scripts --no-audit --no-fund
npm test --prefix tool/traceability
node tool/traceability/cli.mjs validate
node tool/traceability/cli.mjs render
node tool/traceability/cli.mjs check
node tool/traceability/cli.mjs metrics
```

Sólo se usa `yaml` 2.9.1, fijado también en package-lock. No requiere Python, base de datos ni credenciales. `check`, `validate` y `metrics` son de lectura. `render` sólo modifica los cuatro Markdown derivados y prepara todos los resultados antes de escribir: delimitadores inválidos abortan sin escrituras. No escribe YAML ni SRS, no cambia estados y no hace commits.

Una ejecución sin cambios no escribe ningún archivo, por lo que también conserva fechas de modificación. Los bloques están delimitados por `<!-- MAREA:GENERATED:BEGIN -->` y `<!-- MAREA:GENERATED:END -->`. El texto manual fuera de ellos se conserva byte a byte. Si un documento existente no tiene marcadores se conserva íntegro y se añade el bloque; marcadores repetidos, incompletos o invertidos fallan. Las decisiones/evidencias deben editarse en YAML; no mantener estados manuales en las vistas.

## Primera auditoría y revisiones posteriores

La línea base AUDIT-2026-10-13 registra evaluación actual, no fecha de implementación. El manifiesto conserva estado Git y SHA256 de los 571 archivos preexistentes. No se hizo commit ni staging; `outputs/` y el SRS ya eran archivos sin seguimiento. Los archivos nuevos de esta tarea están limitados a `tool/traceability/` y los documentos/recibos de auditoría.

Para actualizar un requisito:

1. Leer el fragmento normativo indicado en `source`; inspeccionar implementación, tests y configuración pertinentes. No editar SRS ni asignar fase por proximidad.
2. Añadir evidencia con ID nuevo, fecha real, revisión Git, referencia local y SHA256. Conservar la anterior y sus huellas. Las referencias a tests de la línea base acreditan relación temática, no cobertura completa.
3. Cambiar únicamente dimensiones respaldadas por esa revisión. Añadir un evento a `history` con fecha, motivo, snapshot previo/nuevo y referencias de evidencia. El último `snapshot` debe coincidir con las cuatro dimensiones, y `platform_snapshot` con las tres plataformas. La transición de implementación debe estar en `state_transitions`. No borrar eventos previos.
4. `DESCARTADO`, `REEMPLAZADO` o `FUERA_DE_ALCANCE` requieren decisión humana APROBADA con autor, fecha y evidencia explícita; una propuesta no cambia la vigencia. DUPLICADO exige canonical_id; REEMPLAZADO exige successor_id. Nunca eliminar código por evaluación de valor.
5. Añadir cada criterio verificable, su estado y justificación. IMPLEMENTADO exige todos los criterios obligatorios identificados como implementados. Porcentajes permanecen null salvo cálculo CRITERIA_EQUAL_COUNT documentado; cuenta de criterios no mide esfuerzo. Un requisito completo no queda validado por una prueba mock ni por una compilación.
6. Ejecutar tests de integridad, validate, render y check; revisar cambios Git. No agregar archivos ajenos ni hacer commits automáticamente.

`dependencies` contiene prerrequisitos de planificación comprobados y debe ser acíclico; `related_requirements` conserva cruces normativos mutuos sin interpretarlos como calendario. `known_defects` referencia FND; cada implementación puede tener requisitos justificativos y restrictivos. El inventario CMP sin correspondencia significa pendiente de investigación, no ausencia de uso. ORF son candidatos, no órdenes de retiro.

Los subcriterios `/Cxx` y los IDs `TR-S<sección>-NNN` son identificadores del seguimiento; no se insertan en SRS ni se presentan como IDs originales. Su correspondencia se congela por fragmento y hash. Una nueva versión normativa exige aprobación explícita, nueva huella y reconciliación de IDs: no volver a numerar silenciosamente las cláusulas ni regenerar este YAML desde heurísticas. El script temporal de integración de la primera auditoría no forma parte del sistema.

## Vigencia y métricas

Una huella distinta señala POTENCIALMENTE_OBSOLETA, conserva estados/historial y excluye esa evidencia de validación vigente. Para confirmar aplicabilidad, añadir `reconfirmation: {by, at, reason, file_hashes}` con las huellas actuales verificadas y conservar las referencias originales. No se confirma automáticamente por que una prueba siga existiendo. Alternativamente agregar nueva corrida como nueva evidencia.

La validación vigente exige requisito IMPLEMENTADO+VALIDADO, criterios completos, plataformas aplicables IMPLEMENTADO+VALIDADO y evidencia TEST_EXECUTION PASS con `complete_requirement_validation: true`, plataformas explícitas y huellas aplicables. No utilizar esa marca para suites parciales. Un fallo obligatorio impide VALIDADO. Las corridas actuales no tienen esa marca y no acreditan ningún RF integralmente. La evidencia completa debe incluir huellas de todos los archivos de implementación y tests asociados al requisito; cambiar un test también suspende la vigencia.

BASE y PILOTO usan sólo RF con etiqueta explícita en SRS. PRODUCTO_COMPLETO agrega todos los RF, incluidos POST y CONDICIONAL; no es fase. Los 322 controles/escenarios/cláusulas sin fase individual tienen propuesta pendiente y permanecen en cobertura total. No se les hereda fase. Tras aprobación de interpretación con respaldo normativo, actualizar la representación/versionado conscientemente; el validador actual exige etiqueta del mismo requisito.

Los ratios son cobertura por cantidad, con numerador/denominador y exclusiones, no esfuerzo ni progreso desplegado. No se publica porcentaje global definitivo con obligaciones NO_AUDITADO. El backend de desarrollo se confirma por el usuario y por snapshots de configuración; distribución web/Android/iOS permanece independiente y sin acreditar.

## Seguridad y límites

Los recibos remotos incluyen únicamente metadatos de tablas/políticas/funciones/buckets/migraciones y avisos de configuración, sin filas personales, secretos ni usuarios. No ejecutar scripts existentes `tool/check_*` o tests DB sin revisar: algunos crean fixtures. No llamar Edge Functions de negocio durante auditoría remota. Las pruebas E2E y pruebas negativas se prepararán posteriormente en staging aislado autorizado.

Las compilaciones en copia temporal con configuración pública ficticia prueban compilación, no operación, auth ni despliegue. Los tests Swift nativos ejecutados en macOS prueban matemáticas/orden de callbacks y no sustituyen ARKit o un dispositivo iOS.

## Resultado verificable de la línea base

El recibo [integrity-results.json](../../docs/evidence/2026-10-13/integrity-results.json) registra validación, pruebas, dos generaciones consecutivas sin escrituras y conservación de todos los archivos iniciales. El [log de cierre](../../docs/evidence/2026-10-13/tool-source-binding.log) conserva los 21 casos aprobados; las corridas anteriores de 20 casos permanecen como evidencia histórica. Los logs y snapshots de backend/compilación están en el mismo directorio; las evidencias previas siguen en el YAML y pueden pasar a POTENCIALMENTE_OBSOLETA sin alterar estados.

La revisión independiente encontró y corrigió cinco problemas durante la primera auditoría: identidad del catálogo manipulable, metadatos/historial incompletos, cifras narrativas congeladas, bloqueo por fallo histórico obsoleto y correspondencias semánticas de próximas tareas. Las regresiones prueban esos controles. Los resultados se refieren a esta línea base; futuras revisiones deben añadir recibos nuevos y eventos, sin sobrescribir evidencia histórica.

## Reconciliación autorizada TASK-002 / v5.1.1

Schema 1 sigue admitido para los snapshots históricos. Schema 2 conserva `baseline` de v5.0 y añade `normative_versions`, `normative_context`, `source_history`, `clause_anchors`, `test_cases`, `preservation` y `evidence_normative_bindings`. La fuente de diseño v5.1.1 y la baseline efectiva v5.0 son campos distintos; adopción sigue PENDIENTE_COMPATIBILIDAD_LOCAL. El perfil documental actual rechaza una promoción de baseline: una herramienta futura y autorización separada deberán verificar esa operación. Ningún PASS sintético autoriza remoto.

La especificación del cambio de herramienta se registró antes de implementarlo en `docs/evidence/2026-10-13/task002/run-20261014T003000Z/T-TOOLING-DESIGN.md`. Las 114 cláusulas AUX históricas tienen correspondencia revisada; las nuevas reciben IDs no usados. El extractor expandido usa sección+SHA y anclas congeladas, no la posición nueva de las tablas. DECISION-51 pertenece a decisiones; los 21 TC-51 tienen estados pendientes independientes y no aumentan los 313 RF.

La utilidad acotada `node tool/traceability/reconcile-v511.mjs` prepara un informe sin escribir. `--apply` sólo se admite sobre schema 1 y el snapshot histórico verificado; ya se ejecutó para esta corrida. Se rechaza repetirlo sobre schema 2. No usarla como generador genérico ni cambiar sus fuentes/autorización para otra tarea. Los comandos ordinarios validate/render/check/metrics siguen siendo la verificación reproducible actual.

Los estados, criterios e historiales anteriores se conservan. `assessment_normative_version` identifica su evaluación; FRAGMENTO_CONSERVADO_NO_REVALIDADO no certifica dependencias nuevas y PENDIENTE_REAUDITORIA señala contenido/dependencia afectada. La validación vigente permanece en cero mientras la adopción esté pendiente. No confundir integración documental con implementación, QA ni cierre TASK-002.

El validador comprueba hashes históricos, baseline, fuentes anteriores, prefijos de history, evidencias/corridas/hallazgos originales y TASK-001 desde el snapshot canónico. Las evidencias históricas no se reconfirman contra v5.1.1; su asociación normativa está en un registro paralelo. Los originales públicos en docs/evidence y tool/staging permanecen sin modificación.

La revisión independiente añadió controles de conservación de criterios, vínculos, plataformas/dimensiones y asociación de evaluación histórica, además de exigir huellas actuales en la autorización. Este perfil documental no permite actualizar evaluaciones de producto: su evolución futura requerirá autorización y representación separadas.
