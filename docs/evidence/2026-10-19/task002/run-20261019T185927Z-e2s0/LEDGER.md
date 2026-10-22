# S0 — ledger

Alcance: sólo copias sintéticas nuevas; fuentes operativas, E1/E2-A y evidencias intactas. Sin commits ni E2-B.

- [x] Autorización leída y fuentes iniciales hasheadas.
- [x] Inspección efectiva y diagnóstico breve: DIAGNOSIS.md.
- [x] Preflight en vacío, clones E2-A y recuperación: 01–03.
- [x] RED por Storage API físico: 06.
- [x] Barrera GREEN, concurrencia, evasiones, fallos: 10, 14–18.
- [x] Revisión independiente y corrección `space`: REVIEW.md, 22–23.
- [x] Conservación y recuperación de versión corregida: 25–26.
- [x] Conservación global: 27; ejecución detenida: 99-stopped-v3.
- [x] Registro de aceptación local y verificación de trazabilidad: REPORT.md, 30-traceability.json; ningún requisito integral promovido.

Se mantiene el checkout con sus documentos no versionados; la implementación se aísla en herramientas/variantes y clones locales nuevos. No se crea un worktree que omitiría la baseline no versionada.
