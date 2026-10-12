# Feed principal — implementación del plan aprobado

Autoridad: plan aprobado en la conversación del 7 de octubre de 2026.
Checkout: /Users/crisis/Proyectos/marea. Se preserva el estado local previo; no se crea un commit que mezcle trabajo ajeno.

- Modelos y repositorios de Inicio/historias: implementados. Primeras pruebas de modelos fallaron por ausencia de implementación y luego pasaron.
- Migraciones 016–019: implementadas, validadas en PostgreSQL aislado (53 comprobaciones) y aplicadas al proyecto vinculado.
- Inicio: historias de usuarios, filtros, feed combinado, tarjetas y seguimiento conectados.
- Barra: se conserva su navegación; se elimina el fondo de la franja y se bloquean toques al contenido detrás.
- Limpieza: worker autenticado mediante secreto, pruebas de orden de borrado y retención ante fallo; cron horario en 017.
- Moderación y eliminación de cuenta: integradas con historias.
- Verificación final: 507 pruebas Flutter aprobadas, dos omisiones configuradas; análisis sin incidencias. Compilación web y APK Android debug aprobadas.
- Supabase: 38 comprobaciones con cuentas temporales aprobadas; se eliminaron las cuentas y sus recursos al finalizar. Contratos anteriores y nuevos verificados.
- Worker y delete-account desplegados. Secreto generado y configurado en Edge/Vault sin guardarlo en Flutter. Cron horario activo; llamada desde pg_net comprobada con HTTP 200.
- Interfaz revisada a 360, 390, 600 y 1440 px, con texto al 100 % y 200 %. Las capturas usan fixtures separados del producto y fotografías locales del proyecto.

Ruling: las páginas fijan el orden mediante un snapshot privado de identificadores por sesión de consulta, que dura 15 minutos. El payload se vuelve a leer y validar en cada página, por lo que contenido retirado, oculto o misiones vencidas no reaparecen.
Ruling: las tarjetas nuevas se activan exclusivamente mediante homePresentation; las otras pantallas conservan su presentación.
Ruling: la actividad de Tendencias cuenta usuarios distintos que no sean el autor, evitando inflar el ranking por repetir comentarios o guardar/reaccionar al mismo contenido.

Ruling: el recibo de publicación de historias conserva únicamente autor, UUID y hash del payload después de la limpieza. Impide resucitar una historia mediante reintentos tardíos y se elimina al borrar la cuenta. La migración 019 cubre escritores que atraviesan el backfill durante una actualización.
Ruling: accepted_at registra las nuevas aceptaciones para Tendencias. Las candidaturas aceptadas antes de 016 usan created_at como referencia histórica, porque ese evento no tenía fecha propia persistida. La consulta final al proyecto vinculado confirmó cero candidaturas afectadas por ese caso.

Revisión independiente: se corrigieron la pausa del visor al abrir menús/perfiles, el payload de reintentos del compositor y la carrera del backfill. La revisión final no dejó hallazgos accionables.
Regresiones adicionales: respuestas pendientes descartadas al cambiar sesión y visor abierto en el navegador raíz, cubriendo toda la navegación.

Entrega: implementación en el checkout actual, capturas e informe de verificación y APK debug. Sin commit que mezcle cambios pendientes, sin despliegue web y sin publicación en tiendas.
