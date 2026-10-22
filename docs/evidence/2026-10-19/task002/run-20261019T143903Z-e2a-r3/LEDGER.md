# Ledger — plan docs/task002/E2-IMPLEMENTATION-PLAN.md, sólo A

Etapa 1: pruebas PAX sintéticas completas antes de Etapa 2. Ejecutores históricos intactos/bloqueados; sin commits/staging. Checkout actual para nuevos artefactos/herramientas; datos en destinos nuevos aislados.

- Inventario acotado por listado previo de insumos; no incluir, leer ni stat de imagen offline .raw. Hashes por bloques 1MiB.
- Precisión: mtime/atime representados en PAX como decimales exactos de nanosegundos. ctime/birthtime del inode nuevo son atributos del filesystem no restituibles por utime; documentar límite, nunca afirmar conservación de esas fechas. Oráculo mtime previo se mantiene y se amplía con ns.
- Pendiente: RED transporte, implementación/ciclo/negativos, recibo PAX; nuevo ejecutor/preflight/clones/backups/restores; RED funcional; A; GREEN/deltas/concurrencia; conservación/trazabilidad y cierre.

## Etapa 1 completada

- PASS: PAX ciclo completo con snapshot fuente, manifest tar, materialización y fase de restore metadata ns; raíz/directorios/archivos/permisos/enlaces seguros; fuente estable. 3 unit tests, 8 negativos de manifiesto/archivos y 5 tar dañados independientes rechazados.
- Incidencia sintética: Docker cp no ve el tmpfs privado del fixture; no se usa para exportar. El RED sintético compara formato USTAR de segundos enteros con st_mtime_ns; el fallo Docker cp previo sigue en R2 intacto. La exportación aprobada usa python exec → stdout PAX; Docker cp sólo materializa el tar validado, seguido de utime(ns) de sus cabeceras exactas como fase de restauración.
- Stage 2: ejecutor nuevo e2a_r3.py, sin importar/desbloquear el histórico. Snapshot lógico SQL se agrupa en dos llamadas en transacciones read-only, manteniendo consultas/hashes y filas; evita cientos de subprocess por snapshot. Ningún oráculo se elimina.
