# Ledger — plan docs/task002/E2-IMPLEMENTATION-PLAN.md, únicamente A

- Ejecutar en checkout actual, con nuevas herramientas/artefactos y copias runtime separadas; baseline documental no rastreada preservada; no commits/staging.
- Lecturas de documentación oficial no conectan entornos Supabase; imágenes fijadas sin descargas.
- Incidencia preparatoria: el primer inventario privado seleccionó por error la imagen offline Docker-offline-before.raw (994662416384 bytes) al intentar hash global. Proceso 44624 recibió SIGINT/TERM/KILL; no es insumo de E2-A, no se montó ni modificó. Se limita el manifiesto a insumos históricos de E/E1/E2-A, con hash por bloques de 1MiB, excluyendo raw y registrando sólo stat. No se han creado contenedores ni restaurado datos.
- Ruling: Docker cp archive por socket Unix local a volúmenes exclusivamente nuevos; preservar uid/gid sin capacidades adicionales ni montajes de fuentes históricas. Verificar manifiestos tras cada copia.
- Pendiente: verificador integrado en vacío; preflight completo; clones/backups; RED; implementación A; pruebas/deltas; cierre y trazabilidad.
