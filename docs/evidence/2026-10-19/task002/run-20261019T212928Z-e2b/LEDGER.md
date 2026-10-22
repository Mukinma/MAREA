# E2-B — ejecución estructural local

Plan: docs/task002/E2-IMPLEMENTATION-PLAN.md, sólo B autorizado por AUTHORIZATION.md.

- [x] Autorización y huellas iniciales; reutilizar primitivas verificadas S0.
- [x] Preflight vacío y procedencia de fuentes S0 corregidas.
- [x] Dos clones nuevos, recuperación y catálogo inicial.
- [x] RED de contratos privados faltantes.
- [x] SQL privado, ensayo rollback, instalación y GREEN.
- [x] Negativos, permisos, concurrencia y conservación.
- [x] Revisión final, recuperación, trazabilidad y parada.

Ruling: el checkout contiene la baseline no versionada; conservarlo y aislar implementación en archivos nuevos y clones nuevos, sin commits ni staging. Un worktree desde HEAD omitiría las fuentes verificadas.

Ruling: B no implementa una API de cliente. Los contratos SQL son privados para un operador técnico NOLOGIN sin membresías de clientes. La autorización/reautenticación del usuario y el transporte v2 son dependencias posteriores; un UUID recibido no es prueba de autorización.

Ruling: sincronizar el marcador legado en la misma transacción que solicitud/controles y adquirir locks Auth 0 (legado) y 4201 (A) en ese orden, antes del control. No llamar request_account_deletion, que además borra resultados de tours.

Ruling: las guardas B de publicación/candidatura consumen el mapping real y comparten los locks, sin cambiar cuerpos de RPC ni FK. La aceptación contractual y las obligaciones organizacionales no se simulan; quedan fuera de la prueba T11 parcial.

Ruling: no hay transición COMPLETED ni función capaz de purgar en B. Cualquier falta de política/disposición/contratos/revocación mantiene bloqueo. Las políticas son exclusivamente sintéticas y no autorizan destrucción.

Ruling: acceso de soporte por rol técnico PostgreSQL autenticado (role GUC protegido por PostgreSQL), caso asignado, finalidad y plazo. No confiar en GUC de identidad/finalidad libre ni abrir acceso a service_role. Sólo salida mínima de expediente, sin perfil/mensajes/paths.

Ruling: lock 0 precede a 4201 porque community_active_account ya adquiere 0; el orden inverso produciría una inversión con su trigger B. A sólo necesita 4201. Se verificará la serialización real y timeout acotado.

- [x] Dos clones: 03, contratos RED: 04; instalación/rollback: 05.
- [x] Guardar candidaturas también frente a baja del titular: 06 RED / 07 GREEN, lock por misión 4204.
- [x] Contratos y permisos: 09; concurrencia real en ambos órdenes: 12.
- [x] Manifestar candidaturas propias y recibidas: 10 RED / 11 GREEN; operaciones propias y demás relaciones quedan inventariadas para D.
- [x] Casos con sesiones PostgreSQL auténticas: 13; S0 real conservado: 14; integridad exacta: 15.
Ruling: dos roles LOGIN son exclusivamente fixtures Unix del laboratorio; B mantiene tres roles NOLOGIN, sin nuevas membresías para clientes. SET ROLE desde supabase_admin no modelaba una sesión no privilegiada. 13a explica la corrección; se conservan seis casos y una lectura del intento A anterior.
Ruling: el delta de preferencias de notificación proviene del trigger real de las dos candidaturas positivas; 15a reproduce dentro de rollback. No se amplían tolerancias genéricas: se verifican exactamente los dos destinatarios de fixture.
Ruling: el test de respuesta descartada prueba el contrato SQL tras commit; no se presenta como pérdida de respuesta HTTP ni integración Flutter/Edge.


## Cierre verificado

- Revisión independiente final: dos hallazgos Important, cero Critical. Se reprodujeron ambos con rollback y se corrigieron en un único pase acotado. Véase REVIEW.md, 18b/18c/18e/18f.
- Ruling final: las candidaturas no permiten cambiar id/applicant_id/mission_id durante B; su disposición requiere D. La guarda B usa adquisición no bloqueante de Auth 0/4201 antes del helper. Una inversión con el lock de misión del RPC legado se rechaza con 55P03 y debe reintentarse; no se cambió el RPC.
- La instrumentación de concurrencia toma el lock de misión con la sesión técnica antes de SET ROLE; authenticated no recibió permisos adicionales para instrumentar la prueba.
- Los helpers propios B que agotaron su sleep durante la pausa se reiniciaron sólo tras preflight vacío dentro de sus namespaces. No se reiniciaron recursos históricos. No se extendieron plazos de políticas/casos.
- Conservación final 15-conservation-v2: deltas exactos de fixtures y un control personal preexistente bloqueado explícitamente por copia; todos los demás originales conservados. La primera verificación 15 permanece histórica.
- Recuperación final 16: DB arrancada restaurada y árboles DB/Storage/coordinación exactos mediante PAX en volúmenes nuevos; progreso consistente, purga/desbloqueo/caso vencido denegados.
- Conservación 17: 1.254 archivos y 365 artefactos privados anteriores preservados; 106 volúmenes históricos intactos; cero contenedores en ejecución. Caché CLI restaurada a los bytes iniciales, sin upgrade.
- Herramientas: 59 pruebas PASS en 19-postfix-unit-tests.log. La aceptación estructural depende además de las pruebas reales A/B.
- Registro canónico y recibo final: 20-traceability.json; listado completo con hashes: 21-artifact-manifest.json.
- **B_STRUCTURAL_VALIDATED_LOCAL_ONLY. Detenido. TASK-002 y E2 integral incompletos. Ningún siguiente incremento autorizado.**
