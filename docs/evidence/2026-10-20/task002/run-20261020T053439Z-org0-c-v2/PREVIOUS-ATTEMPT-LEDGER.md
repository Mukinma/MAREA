# ORG-0 + E2-C — ejecución local autorizada

Plan y especificación: E2-IMPLEMENTATION-PLAN.md, E2-TECHNICAL-DESIGN.md, SRS 5.1.1 y AUTHORIZATION.md de esta corrida.

- [ ] Preflight vacío/completo y dos copias B nuevas con recuperación previa a DDL.
- [ ] ORG-0 RED, modelo real, permisos/membresías, positivos/negativos/concurrencia.
- [ ] ORG-0 conservación, backup/restore y puerta de aceptación independiente.
- [ ] Sólo tras puerta PASS: C RED, clasificación explícita y titularidad XOR.
- [ ] C positivos/negativos/concurrencia, conservación y recuperación final.
- [ ] Revisión final acotada, trazabilidad, recibos y parada.

Ruling: continuar en checkout Chris existente; la baseline no versionada se perdería en un worktree creado desde HEAD. Todos los cambios funcionales se limitan a archivos nuevos de laboratorio y clones nuevos. Sin commits/staging.
Ruling: D05/D06 autorizadas sólo para estas pruebas. Ningún legacy se clasifica por author_id ni perfil Negocio. Toda clasificación exige manifiesto aprobado, evidencia sintética explícita, versión/hash y permiso vigente.
Ruling: los cuatro roles visibles proceden de RF-02-004; los permisos son explícitos según 3.4, sin herencia por etiqueta. Editor no firma ni emite ofertas por el rol. No se elige una matriz universal de permisos por defecto no definida por el SRS.
Ruling: la identidad de probes privados se deriva de sesiones SQL reales vinculadas por fixtures administrativos; nunca de UUID/GUC libre. La integración de endpoints Auth/cliente y TASK-003 sigue fuera de alcance; no se simula como completa.
Ruling: la última persona propietaria no puede abandonar por revocación ordinaria (RF-02-010). Transferencia, reclamación, disolución y elevación de suspensión no se implementan por inferencia. Estados canónicos se conservan; sólo se ejecutan transiciones cubiertas y autorizadas.
Pre-flight: ORG-0 → C requiere FK reales y resolver de representación vigente. B → ORG/C requiere mantener bloqueo del principal y todos los datos/objetos B/S0. C → K no autoriza modificar RPC: las mutaciones legadas incompatibles del clon se rechazarán con guardas nuevas; integración productiva permanece pendiente.

ORG-0: 04 RED; 05 instalación/rollback exacto; 07 positivos/negativos; 08 revocación concurrente/estados/ACL; 08b expiración real de servidor, idempotencia y FK. 09b conservación final: todas las filas previas y secuencias iguales, 5 tablas/12 funciones/3 roles NOLOGIN +6 LOGIN de fixture. Un INSERT de membresía con vencimiento es fixture explícito separado de operaciones.
Ruling: el verificador lee signature (campo real del snapshot) y versiona los nuevos snapshots tras añadir el fixture de expiración; los intentos originales se conservan. No se relajó comparación ni se repitió una recuperación por estos ajustes.

STOP: ORG-0 acceptance invalidated by 12b. Legacy account_deletion_requests was not included in resolver readiness although B correctly blocked the same identity. Actual RED 13a, minimal correction GREEN inside exact rollback 13b. C fixtures only A partly prepared; no C acceptance. Fresh run required after this minimal fix; old receipts/volumes retained stopped.
