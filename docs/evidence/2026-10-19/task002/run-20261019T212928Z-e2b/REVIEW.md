# E2-B — revisión final y correcciones

Revisión independiente de contexto fresco, sólo lectura, del contrato, guardas y pruebas. Dos hallazgos Important y cero Critical. Un único pase de corrección, sin iniciar otro incremento.

| Hallazgo | Reproducción real | Corrección y comprobación |
|---|---|---|
| La guarda de candidaturas sólo vigilaba status; UPDATE de applicant_id, mission_id o id con status estable eludía el control. | 18b-review-RED.json, ambas copias, cambios revertidos. | Trigger B ampliado a las cuatro columnas; cambio de identidad/referencia rechazado con 55000 hasta D. 18c-review-GREEN.json demuestra los tres rechazos. |
| La espera bloqueante Auth 0 bajo el lock de misión del RPC review_application podía cruzarse con withdraw_application (Auth 0 → misión). | Intercalado real de ambos RPC, 40P01 en 18b, todo revertido. | Adquisición no bloqueante de Auth 0 y 4201 en la guarda B; contención devuelve 55P03 OBLIGATION_LOCK_BUSY_RETRY. 18c demuestra ausencia de 40P01 y retiro permitido antes del rollback. |

El parche 20261020042015_e2b_review_identity_and_lock_guards.sql modifica exclusivamente la función y el trigger creados por B. 18e verifica primero rollback exacto y luego instalación sin mutar filas, FK, cuerpos RPC ni permisos preexistentes. 18f revalida recibos, progreso, versiones, purga denegada y operaciones permitidas reales.

Los prelocks de instrumentación pertenecen a la sesión técnica antes de SET ROLE; no se otorgó SELECT FOR UPDATE a authenticated. Los intentos fallidos de instrumentación se conservan como REVIEW-ATTEMPT y fuentes anteriores. Ningún accepted legado persistió ni se presentó como Agreement.

La recuperación de la versión corregida figura en 16-final-recovery.json. No se realizó una ronda adicional de revisión ni se amplió el alcance.
