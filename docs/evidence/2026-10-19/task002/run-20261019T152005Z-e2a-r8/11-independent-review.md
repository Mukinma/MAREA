# Revisión independiente acotada

Revisión estática del SQL privado y casos, sin Docker, ejecución SQL, cambios de archivos ni lectura de secretos. No constituye aprobación humana ni prueba funcional.

- Se encontró un vacío real en R5: la prueba anunciaba mapping no nulo pero insertaba NULL. Corregido desde R6: la nueva Auth.id colisiona con una Person vinculada a otra Auth; exige DETAIL MAPPING_CONFLICT y conserva conteos/mapping. R8 lo ejecutó en ambas fuentes.
- La revisión no encontró defectos confirmados de atomicidad/idempotencia: manifiesto bloqueado, IDs normalizados/ordenados y advisory lock por Auth con revalidación.
- Se revisó la corrección R6 de lectura Auth: política sólo SELECT para marea_person_sync_owner, columnas id/deleted_at, NOLOGIN y NOBYPASSRLS. Sin exceso de privilegio identificado. El SQL R8 conserva ese contenido.
- El rechazo de colisiones PK antes de resolver mapping es conservador y explícito; no usa igualdad de UUID como autorización.

La evidencia de ejecución se encuentra separadamente en 05, 06, 06b, 07 y 08.
