# Revisión independiente de diseño y secuencia E2

19 octubre 2026. Revisor interno `e2_builder_review`, exigido por el builder check de la guía brainstorming. Alcance: lectura del diseño y después plan/matriz/expediente, sin edición de archivos, SQL, Docker, consultas a bases ni delegación adicional. No es aprobación humana ni evidencia de implementación.

## Primera lectura

Hallazgo de alto impacto: delete-account elimina archivos antes de auth.admin.deleteUser y la guarda actual de imágenes omite la protección de uso con uid NULL. Una guarda Auth podría rechazar el borrado después de perder los archivos. Recomendación: cerrar/fence y drenar o invalidar ejecuciones/reintentos antiguos antes de activar parcialmente E2; comprobar bytes y referencias en una carrera con limpieza previamente iniciada.

Resolución: se añadieron puerta S0 y caso T49, verificación del orden real de Storage, quiescencia y backup revalidado; sin éxito de esa puerta no se activa B/C/D/M/X. La sola existencia de trigger sobre metadata no se presume protección física.

## Segunda lectura

El revisor confirmó que S0/T49 resuelve ese riesgo. Detectó dos inconsistencias de secuencia:

1. A excluye borrar Auth/perfiles, pero T07 exige DELETE Auth concurrente. Se debe diferir T07 y la parte de baja de T44; A usa fixtures nuevos de desvinculación/control y concurrencia de reparación sin DELETE.
2. C exigía T13 de baja/medios, mientras M dependía de C. Se debe aceptar C estructural para construir D/M, dejando integración de baja T13 pendiente hasta B/D/M/TASK-003 y obligatoria antes de X/R.

Resolución incorporada por el autor: plan, matriz y expediente distinguen A sin bajas, recibos B/C estructurales e integraciones posteriores (T07/T12/T13/T14/T48 y motores aplicables). No se interpreta el recibo estructural como prueba integrada. Tras estos cambios se hizo autorrevisión documental; no se atribuye al revisor una tercera validación que no realizó.

No señaló otros bloqueos técnicos importantes aparte de decisiones humanas ya explícitas. Quedan pendientes esas decisiones y todas las pruebas de implementación; este recibo sólo acredita revisión del diseño.
