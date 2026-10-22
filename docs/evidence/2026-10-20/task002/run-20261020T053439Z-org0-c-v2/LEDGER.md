# ORG-0 + C v2 — mismo alcance, copias nuevas desde B

Autorización: AUTHORIZATION.md. Predecesor inválido indicado en 00 y configuration.json. Los hitos/criterios son los del plan E2; sin nueva arquitectura ni permisos funcionales por inferencia.

- [ ] Preflight vacío/completo, procedencia B y recuperación de dos copias nuevas.
- [ ] ORG-0: RED, implementación corregida, casos reales y marcador legado.
- [ ] Puerta ORG-0: conservación, recuperación y recibos vinculados; no aceptación invalidada.
- [ ] C sólo tras PASS: ownership/manifiestos, XOR, permisos, integridad y concurrencia.
- [ ] Revisión final, conservación, recuperación, trazabilidad y parada.

Ruling: adoptar corrección demostrada en 13a/13b del intento 1 y seleccionar identidades sin marcadores legados. Nunca borrar el marcador ni reabrir controles para permitir el fixture.
Ruling: ejecutor v2 separado; reutiliza casos y transporte probados mediante alias de módulo explícito. No modifica ni desbloquea el ejecutor/volúmenes fallidos. Sin worktree nuevo, staging o commits; fuentes no versionadas previas se conservan.
Ruling: los permisos se conceden explícitamente, no por etiqueta de rol. APIs de cliente, transferencias/reclamación, contratos, TASK-003 y purga permanecen fuera de alcance. Sesiones SQL reales son probes estructurales, no integración Auth/Flutter.
Ruling: cualquier invalidación de ORG-0 o modificación de sus recibos cierra la puerta C. Cinco pruebas unitarias RED/GREEN verifican esta condición.
