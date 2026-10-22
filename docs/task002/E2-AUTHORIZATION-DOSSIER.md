# E2 — Expediente de decisiones y autorización por incremento

**19 octubre 2026. ANÁLISIS ENTREGADO; E2 NO AUTORIZADO NI EJECUTADO. TASK-002 INCOMPLETA.** La instrucción actual autoriza análisis y planificación; no es permiso para modificar producto o datos. U0 continúa APROBADO_DISEÑO_FUNCIONAL como referencia; E1 y su evidencia conservan exactamente su alcance local original.

## Recomendación técnica que se somete a revisión

Conservar UUID/ancla de misiones y autoría histórica, mantener Person E1 privado y separar titularidad en relación privada XOR personal/organizacional. Expandir/sincronizar, cerrar rutas destructivas heredadas, preparar eliminación por recurso y proteger candidaturas/medios/compatibilidad antes del corte de FK. No ejecutar el antiguo borrador E, recrear E1 ni convertir perfiles Negocio en organizaciones.

El cambio aislado de FK no basta y no se solicita su aprobación como conjunto ejecutable. La variante organizacional depende de ORG-0 real. Se puede avanzar primero con **E2-A: sincronización y reparación privadas de principales**, sin habilitar eliminación, titularidad o contratos.

Material revisable:

- [Diseño técnico](E2-TECHNICAL-DESIGN.md): alternativas, entidades, contratos, permisos, invariantes, ciclo de vida y recuperación.
- [Plan](E2-IMPLEMENTATION-PLAN.md): A → S0 → B/C → D/M → K/F → X → R, con dependencias explícitas y puertas independientes.
- [Matriz](E2-TEST-MATRIX.md): 49 casos diseñados, **ninguno ejecutado** en esta entrega.
- [Inventario](E2-DEPENDENCY-INVENTORY.json): 85 fuentes/116 anclas y datos de snapshots E1; 36 FK entrantes a perfiles, diez a misiones y 56 rutinas relevantes. No es consulta actual al runtime ni prueba de datos reales.

## Decisiones humanas pendientes antes de implementar su alcance

| ID | Decisión concreta | Recomendación técnica | Bloquea | Estado |
|---|---|---|---|---|
| D01 | Alta transaccional y esquema de ID de futuros Person; alcance de reparación | Trigger Auth independiente, conservar validadores de registro, nuevo id=Auth.id como E1; resolver siempre por mapping actual. Sin religar NULL/reusar identidades suprimidas. Aceptar que fallo de alta revierte toda la transacción | A | PENDIENTE |
| D02 | Política de retención/minimización/supresión por categoría y acceso al expediente | Plazo/finalidad/base/responsable/expiración explícitos. UUID/hash vinculable es dato seudonimizado; no retención perpetua implícita. Fixtures pueden tener política sintética etiquetada, sin extrapolarla a personas reales | B/D/M/R operativos; no bloquea diseño A | PENDIENTE, con responsables de privacidad/operación |
| D03 | Ampliar el corte a candidata/recibos y disponer los otros hijos de perfil | Preservar IDs e identidad técnica de candidaturas protegidas; tratamiento específico de cada FK. No eliminar todo ni aplicar RESTRICT universal | D y purga B/X | PENDIENTE |
| D04 | Derechos de uso/retiro y custodia técnica de medios personales usados por organización/tercero | Registry/bindings sin licencia inferida; si owner/owner_id Storage bloquea Auth, procedimiento soportado de reasignación o copia con hash/URLs/delta aprobados. No borrar un medio protegido ni inventar cuenta sustitutiva | M y purga B | PENDIENTE |
| D05 | Regla y evidencia de clasificación, incluidos los seis fixtures | Manifest por misión/versión con ground truth explícito; REVIEW_REQUIRED si incierto. Auth/perfil válido no acredita por sí solo titularidad personal | C | PENDIENTE |
| D06 | Adoptar tabla privada de titularidad y dependencia ORG-0 | Alternativa C del diseño; organizaciones/membresías implementadas y probadas antes de FK organizacional. No UUID sin integridad ni tabla ficticia | C completo | PENDIENTE |
| D07 | Mínimo de cliente/capacidad y alcance de bloqueo de superficies legadas | UPDATE_REQUIRED/rechazo seguro para selección/estados incompatibles, incluidas tablas/avisos/feed; no mensajes de éxito inventados ni reescritura de accepted histórico | K/F y corte operativo X | PENDIENTE; requiere binarios y matriz de versiones soportadas |
| D08 | Nuevo protocolo de eliminación y compatibilidad del consumidor antiguo | Solicitud/progreso v2; 204 legado sólo con purga compatible realmente completada. No enviar 202 a código que considera cualquier 2xx eliminación final. Mantener vía soportada para solicitar baja | S0/B/F operativo | PENDIENTE |
| D09 | Corte final y límites de reversión | Revisar SQL final, delta/cuerpos/ACL/locks/timeouts y backup/restore de cada copia. Después de supresión o perfiles ausentes, forward fix, no volver a cascada ni fabricar perfiles | X y autorización de rollback posterior | PENDIENTE; no se solicita ahora ejecutar X |
| D10 | Regla normativa de elegibilidad de personas vinculadas/controlantes de organizaciones | Mantener la ambigüedad ya registrada y caso no habilitado sin regla aprobada y validación servidor. Membresía no concede elegibilidad ni prohibición universal inferida | Caso relacionado en C/K y contratación posterior | PENDIENTE; no modifica el SRS en esta entrega |

Las firmas organizadora/destinataria, 72 horas, XOR de titulares y no autocontratación personal ya son requisitos del SRS; no se someten como opciones negociables. Las decisiones anteriores concretan mecanismos/políticas pendientes. Toda futura aclaración normativa se tramitará con su autorización y trazabilidad; no se deduce de aprobar este expediente.

## Solicitud siguiente propuesta: autorización estricta E2-A local

**Todavía NO concedida.** Para comenzar A haría falta aprobación explícita de D01 y del alcance siguiente:

1. Preparar SQL ejecutable separado y herramientas nuevas, trazados a E1, exclusivamente para clones **nuevos**, sintéticos y aislados. No reutilizar/tocar volúmenes E1/originales ni reescribir sus artefactos.
2. Implementar sólo sincronización transaccional del principal en altas Auth, control privado mínimo de ciclo de vida y reconciliación/dry-run administrativa. Se permiten las funciones/triggers internos nuevos y grants mínimos exactos de ese diseño; **no RPC de negocio ni cambio de handle_new_user/validación legal**.
3. Ensayar altas/reparación con datos sintéticos, colisiones, reversión, concurrencia y roles negativos; preservar todas las tablas existentes salvo los INSERT de fixture expresamente declarados y las nuevas filas de Person/control. Registrar por separado delta de preparación y delta de implementación.
4. Antes de cada DDL: entorno/imagen/aislamiento, backups/restores, digests y catálogo E1 sin drift. No retirar ningún control si falla una precondición; detener y presentar el bloqueo.
5. Concluir con SQL exacto, permisos efectivos, casos A reales, pruebas de conservación/rollback, fuentes/hashes y recibo. **Detener antes de S0/B/C/D/M/K/F/X/R** y no declarar E2 completado.

Exclusiones de A: borrar Auth/perfiles/medios; cambiar missions.author_id, cualquier FK de misión o candidatura; titularidad de misión; organizaciones/membresías; acuerdos/ofertas/reservas; rutas de selección; Edge de borrado operativo; modificaciones Flutter; arreglos TASK-003; remoto, commits o volúmenes originales. El control de vida añadido en A no se presenta como un flujo de eliminación terminado.

## Puertas posteriores y autorización independiente

| Incremento | Qué deberá aprobarse antes de ejecutar | Recibo que permite evaluar el siguiente |
|---|---|---|
| S0 | Cierre/fence y drenaje de rutas destructivas legadas sin perder vía de solicitud; versiones/ejecuciones en curso y autorización Edge/Storage precisa | T49: limpieza legada iniciada antes del corte no puede borrar bytes/referencias tras barrera; backup fresco; ninguna ejecución incompatible activa |
| B | Política de datos y protocolo de solicitud; contratos TASK-003 y motor contractual que realmente exista | Recibo estructural de solicitud/bloqueo/guardas; baja completa y T07/T12 sólo tras D/M y dependencias reales |
| ORG-0 / C | Diseño/implementación organizacional en su propio incremento; clasificación/propiedad XOR y regla de casos ambiguos | Recibo estructural de ambas titularidades sin dueño inventado; D/M pueden consumirlo. T13/T14/T48 de baja/contratos permanecen pendientes hasta integración antes de X/R |
| D | SQL y disposición por cada FK de candidata/recibos/hijos; cambios de RLS/notificaciones | Candidaturas protegidas y resto del dominio conservados con delta mínimo aprobado |
| M | Derecho/uso/retención, registry/claims y reemplazo de limpieza; acceso Storage por operación | Bytes/objetos y bindings preservados; errores/reintentos reales; sin limpieza por prefijo |
| K | Fachadas/contratos/ACL/RLS/guards exactos y compatibilidad de wrappers/superficies | Sin bypass ni confirmación falsa, incluyendo notificaciones/feed/raw REST |
| F | **Permiso Flutter específico**, artefactos de versiones y alcance de pantallas maduras U0 | Binarios reales/cache/deep links/baja probados; cinco destinos y componentes preservados |
| X | SQL definitivo nuevo, catálogo esperado, filas afectadas del clon, backup/restore, ventanas/locks y condiciones de rollback | Nueva FK validada antes de retirar la vieja; invariantes de datos y referencias preservados |
| R | Procedimiento y fuentes de supresión/secretos actualizadas, namespace nuevo de recuperación | Restore DB/Storage/config/roles y supresiones previas a exposición, con evidencia TASK-003 |

Un PASS de A no autoriza S0 ni un cambio de FK. Un PASS estructural local no autoriza datos reales/remoto. Ni siquiera una aprobación de D09 deberá interpretarse como permiso remoto: requiere expediente independiente del entorno concreto, datos efectivos, capacidad, política de privacidad, backup y recuperación verificados.

## Riesgos principales y mitigación verificable

| Riesgo | Impacto / condición | Mitigación y aceptación |
|---|---|---|
| Storage borrado antes de que falle DELETE Auth | Pérdida irreversible en transición parcial | S0 previo y T49 con operación ya iniciada; probar bytes en versión Storage fijada, no sólo trigger/metadata |
| Propiedad técnica Storage impide eliminar Auth | Conservar el asset por registry no elimina la restricción de la API | Inventariar owner/owner_id/buckets y T33/T12; D04 exige custodia/copia soportada antes de purga, con derechos/hashes/compatibilidad y sin borrar evidencia |
| Reconciliador resucita principal desligado | Acceso indebido y correlación de identidad | D01; no relink automático; T06/T07 con supresión y alta concurrente |
| Política de retención ausente | Conservar más datos de los justificados o perder derechos de contraparte | D02/D03, caso mínimo/finalidad/plazo y gates; sin aceptación operativa con política pendiente |
| Se borra candidata, reportante o autor de aviso | Se pierde evidencia pese a misión superviviente | Matriz completa de FK, cortes acotados y T22/T24/T38 |
| Creador confundido con dueño o miembro vigente | Permisos cruzados o pérdida de gestión org | Sidecar/resolver; pruebas actor–contexto–acción–estado y ORG-0 real |
| Supuesto de compatibilidad por mantener UUID/JSON | Cliente antiguo sigue confirmando accepted o baja asíncrona | K/F, binario real y rutas alternativas; gates hasta cliente soportado |
| Deadlock o carrera de clasificación/baja/media | Esperas, duplicados o recursos perdidos | Orden de locks compatible, límites/reintentos y barreras concurrentes con postcondiciones |
| Rollback recrea datos personales | Reaparición de PII, pérdida de supresiones | Forward fix tras punto irreversible; ledger independiente y restore aislado TASK-003 |
| Protección sólo RLS frente a service_role | Bypass de eliminación/autorización | Guardas/claims privados/worker verificado y pruebas privilegiadas; no se promete defensa ante superusuario que deshabilite controles |

## Criterios de aceptación y estado presente

El E2 futuro requiere todos los invariantes I01–I12, matriz aplicable por ambas modalidades, conservación/deltas, compatibilidad y recuperación; los casos de seguridad dependientes necesitan TASK-003 realmente validado. Fixtures sólo personales no cierran organizaciones. Un deny-all puede ser contención segura, pero no demuestra que el flujo autorizado positivo funcione.

En esta entrega se puede aceptar **el expediente de diseño**, no una implementación: fuentes vinculadas, decisiones/alternativas, plan y pruebas propuestas, revisión independiente de secuencia y hashes de preservación. No hay SQL E2 ejecutable ni cambios de producto. Requisitos y TC-51 conservan sus estados; E1 permanece válido con su alcance anterior; TASK-002 sigue incompleta.
