# MAREA — TASK-002 / ORG-0 + E2-C
## Implementación de organizaciones y titularidad explícita de misiones

Actúa como Principal Software Engineer, PostgreSQL Architect y Application Security Engineer.

Tu objetivo es implementar de forma incremental, verificable y mantenible el modelo organizacional y la titularidad de misiones de MAREA, respetando el SRS v5.1.1, la baseline efectiva, el código existente y todos los invariantes previamente aprobados.

**Autorizo exclusivamente ORG-0 y E2-C estructural en laboratorio local, mediante dos etapas con aceptación independiente.**

La autorización de C queda condicionada a que ORG-0 supere completamente sus criterios de aceptación. No se autoriza ningún otro incremento.

Fecha límite del proyecto académico: 19 de noviembre de 2026. Trabaja con rigor, pero evita sobreingeniería e infraestructura redundante.

## 1. Contexto

E1, E2-A, E2-S0 y E2-B cuentan con validación exclusivamente local.

E2-B implementó solicitudes privadas de eliminación, controles de ciclo de vida, bloqueo de obligaciones y preparación de manifiestos. No implementó organizaciones, acuerdos, ofertas, reservas ni eliminación integral.

Conserva íntegramente ese trabajo.

Antes de intervenir, inspecciona los expedientes E2, el SQL efectivo de laboratorio, los contratos de Auth, perfiles, misiones, membresías y las funciones existentes.

No presupongas que el perfil de tipo Negocio representa una organización.

## 2. Decisiones adoptadas para este laboratorio

### D05 — Clasificación de titularidad

Adopto clasificación explícita y verificable mediante manifiesto por misión, con identidad, versión/hash, evidencia y decisión autorizada.

Ninguna misión histórica se clasificará como propiedad personal únicamente porque su `author_id` corresponde a un perfil/Auth existente.

Los casos ambiguos, disputados o sin evidencia suficiente permanecerán `REVIEW_REQUIRED` únicamente como estado interno de migración.

Se permiten fixtures sintéticos con titularidad declarada explícitamente para probar ambas modalidades. No fabricar evidencia histórica ni atribuir automáticamente organizaciones.

### D06 — Arquitectura de titularidad

Adopto la alternativa de tabla privada de titularidad uno a uno recomendada en E2-TECHNICAL-DESIGN.

Conservar:

- `public.missions.id` como identificador estable.
- `missions.author_id` como atribución histórica.
- `collaboration.persons` como principal personal estable.
- Titularidad personal u organizacional explícita y excluyente.
- Organizaciones reales con integridad referencial.
- Control de permisos basado en representación vigente, no en autoría histórica.

No cambiar todavía la FK original de `missions.author_id` ni su cascada.

## 3. Etapa ORG-0 — Modelo organizacional real

Implementa únicamente los componentes persistentes necesarios para representar:

1. Organizaciones con identidad propia.
2. Estados organizacionales definidos conforme al SRS.
3. Membresías personales asociadas a organizaciones.
4. Roles y facultades explícitas por acción.
5. Representación vigente y autorizada.
6. Revocación o terminación de membresías.
7. Protección de la organización frente a acciones de exmiembros.
8. Restricción segura cuando no exista un representante autorizado.
9. Integridad referencial, concurrencia y auditoría mínima necesaria.

**No inventes permisos normativos.** Deriva roles, transiciones y facultades del SRS y los contratos existentes. Si una decisión esencial no está especificada, presenta el bloqueo concreto antes de implementar ese comportamiento.

Distinciones obligatorias:

- Una persona puede pertenecer a varias organizaciones sin convertirse automáticamente en su representante.
- Una membresía no implica facultad para firmar contratos.
- Un editor no puede asumir permisos reservados a un representante firmante.
- Un creador histórico no conserva permisos organizacionales después de perder representación.
- Las capacidades deben comprobarse en el servidor mediante sujeto, organización, acción, estado y autorización vigente.
- Ningún UUID, tipo de perfil o metadata suministrada por el cliente concede representación.
- No crear automáticamente una organización a partir de un perfil Negocio.

Implementa tablas, constraints, funciones internas y políticas estrictamente necesarias, con privilegios mínimos y denegación por defecto.

Usa organizaciones y membresías sintéticas auténticas para las pruebas: deben existir como registros referenciados por constraints reales, no como tablas ficticias destinadas únicamente a satisfacer compilación.

### Puerta obligatoria ORG-0

Antes de comenzar E2-C, demuestra:

- Integridad de organizaciones y membresías.
- Permisos positivos y negativos por rol.
- Revocación efectiva de representación.
- Protección frente a escalamiento de privilegios.
- Concurrencia e idempotencia aplicables.
- Conservación íntegra de datos legados.
- Ausencia de modificaciones fuera del alcance.
- Backup y restauración verificables.

Si ORG-0 no supera esta puerta, detente. No empieces C ni apliques soluciones que debiliten controles.

## 4. Etapa E2-C — Titularidad de misiones

Sólo después del PASS de ORG-0, implementa el modelo estructural de titularidad explícita.

La tabla privada `collaboration.mission_ownership` deberá vincular de manera verificable una misión existente con exactamente uno de los siguientes titulares:

- Principal personal válido.
- Organización válida.

Implementa:

1. Relación uno a uno respecto a la misión.
2. Exclusividad personal/organizacional mediante constraints efectivos.
3. Referencias reales e integridad al commit.
4. Versión de titularidad y control de concurrencia.
5. Clasificación mediante manifiestos aprobados.
6. Casos de migración no resueltos y bloqueo seguro.
7. Resolver privado de organizador autorizado.
8. Impedimento de eliminación o alteración arbitraria de titularidad.
9. Protección frente a creadores sin representación vigente.
10. Conservación del identificador y autoría históricos.

Las misiones nuevas o promovidas al nuevo modelo no podrán quedar operativas sin titular válido.

Las misiones legadas pendientes de clasificación conservarán sus datos, pero no adquirirán titularidad o permisos nuevos por inferencia.

No implementes todavía acuerdos bilaterales, ofertas, reservas, firmas, transferencias contractuales ni motores de compensación.

No alteres registros `accepted` históricos para convertirlos en contratos válidos.

La ambigüedad D10 sobre elegibilidad de personas vinculadas a organizaciones permanece bloqueada hasta contar con una decisión normativa aprobada.

## 5. Pruebas obligatorias

Utiliza como base E2-T15 a E2-T20 y E2-T23 en las partes estructurales autorizadas.

Incluye como mínimo:

- Clasificación personal con evidencia explícita.
- Clasificación organizacional con organización real.
- Rechazo de clasificación sin evidencia suficiente.
- Rechazo de titularidad doble o ausente.
- Colisiones entre clasificadores concurrentes.
- Reejecución idempotente de manifiestos.
- Revocación de representante durante una operación.
- Exrepresentante intentando administrar una misión.
- Editor intentando ejecutar acciones reservadas a representante.
- Persona intentando operar sobre organización ajena.
- Perfil Negocio sin organización formal.
- Intento de borrar misión o titularidad sin procedimiento autorizado.
- Preservación de misiones y candidaturas existentes.
- Acceso directo no autorizado a tablas privadas.
- Fallos de transacción, rollback y recuperación.

Registra las pruebas estructurales aprobadas separadamente de los escenarios integrados que dependan de eliminación real, contratos, Flutter o TASK-003.

No declares PASS para pruebas que requieran motores todavía inexistentes.

## 6. Reutilización y eficiencia

Reutiliza los componentes aprobados de aislamiento, transporte PAX, respaldos, comparación e instrumentación cuando sus versiones y procedencia sean compatibles.

No reescribas infraestructura ya validada únicamente por preferencia arquitectónica.

Puedes corregir defectos ordinarios de herramientas, fixtures y pruebas dentro del alcance autorizado, conservando la evidencia original.

Ante un defecto, usa primero una reproducción mínima y después reintenta el laboratorio completo.

Evita reconstrucciones repetitivas, informes redundantes y pruebas que no agreguen evidencia relevante.

Ante drift inexplicable, pérdida de datos, escalamiento de privilegios, exposición externa o conflicto normativo esencial, detente.

## 7. Restricciones

Toda implementación debe ejecutarse exclusivamente en copias locales nuevas, sintéticas y aisladas.

Prohibido:

- Modificar datos reales o entornos remotos.
- Tocar volúmenes históricos.
- Alterar `missions.author_id` o las FK legadas.
- Ejecutar E2-D, M, K, F, X o R.
- Ejecutar purgas Auth, perfil o Storage.
- Implementar nuevas operaciones contractuales.
- Modificar código operativo Flutter, Edge o RPC de negocio.
- Modificar el SRS sin aprobación normativa.
- Crear roles administrativos globales o bypass amplios.
- Hacer commits o staging automáticos.

Preserva U0, E1, E2-A, S0, B, TASK-001 y sus evidencias.

## 8. Entrega

Presenta resultados separados para ORG-0 y E2-C.

Para cada etapa incluye:

- Estado real PASS/FAIL/BLOCKED.
- SQL y artefactos implementados.
- Permisos efectivos y restricciones.
- Pruebas funcionales y estructurales ejecutadas.
- Pruebas negativas y de concurrencia.
- Deltas exactos respecto al legado.
- Evidencia de backup/restore.
- Defectos corregidos.
- Bloqueos pendientes.
- Riesgos de integración con Flutter y backend operativo.

Actualiza la trazabilidad sin convertir una validación local en validación integral.

**Detente después de E2-C estructural. No avances a otro incremento por inferencia.**

El objetivo es conseguir organizaciones y titularidad realmente comprobables, no aumentar artificialmente la cantidad de pruebas o documentación.