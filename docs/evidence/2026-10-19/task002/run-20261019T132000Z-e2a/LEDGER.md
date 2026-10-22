# Ledger — E2-A; plan docs/task002/E2-IMPLEMENTATION-PLAN.md

Alcance único A / D01; siguientes hitos no autorizados. Sin commits ni staging.

- Preflight host: socket Unix esperado, Docker 29.8.2, cero contenedores activos. Falta preflight completo de imágenes/archivos y clones antes del DDL.
- Ruling: se trabaja con nuevos artefactos/herramientas en el checkout actual y proyectos privados de laboratorio. No se crea worktree Git: la baseline documental E1/E2 es trabajo no rastreado preservado, y no se modifica producto; la separación transaccional/runtime la dan copias nuevas. No se interpreta la guía de worktrees como permiso para copiar o alterar otros checkouts.
- Ruling: se reproduce E1 desde sus archivos fríos + SQL validado en destinos nuevos; no se accede a sus volúmenes. Se verifican datos legados y catálogo; el reloj de created_at de los principales reproducidos es del nuevo laboratorio y se declara.
- Ruling: Auth/helper comparten el network namespace `none` de PostgreSQL, sólo loopback; sin bridge/host bindings ni proveedores externos. DB cleanup Auth desactivado expresamente según configuración de v2.196.0, sin tocar fuentes.
- Ruling: roles PostgreSQL internos NOLOGIN son propietarios/operadores técnicos explícitos para privilegio mínimo, no roles organizacionales inferidos. Ninguna membresía para roles de aplicación ni EXECUTE administrativo añadido a service_role.
- Pendiente: RED, SQL A, GREEN, API Auth y deltas, negativos/concurrencia, revisión final, trazabilidad/cierre.

## Parada obligatoria — precondición de aislamiento

- PASS parcial: imágenes/archivos verificados, baseline A reproducida en volumen nuevo, respaldo frío nuevo restaurado en otra copia con igualdad de catálogo/filas/secuencias antes de Auth. E1 original no se montó.
- Auth v2.196.0 arrancó sólo en la copia A; startup informa cero migraciones aplicadas. La comprobación de interfaces del helper compartiendo namespace no devolvió exclusivamente `lo`; falló antes de construir/enviar HTTP. No se inventa la lista concreta de interfaces: la guarda no la imprimió.
- La hipótesis de loopback exclusivo no quedó acreditada. Se detuvo bootstrap y se apagaron Auth/PG/recuperación nuevos; no se cambia a bridge, host network, reglas privilegiadas o pruebas alternativas.
- No se alcanzó RED, no hay fixtures signup ni SQL A implementado/aplicado, roles/control/funciones/trigger E2-A inexistentes. El archivo generado por CLI en el proyecto privado sigue vacío.
- No se verifica conservación integral postarranque Auth de los datos de esa copia detenida: no se reabre para SQL después del fallo. Se conserva su snapshot previo, volumen y logs para diagnóstico autorizado futuro.
- E2-A: BLOQUEADO_PRECONDICION_AISLAMIENTO, no aceptado ni completo. Autorización siguiente solicitada: diagnóstico/corrección de aislamiento en contenedores nuevos sin datos, antes de reintentar A. No S0 ni siguientes.
