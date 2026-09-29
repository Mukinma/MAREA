# Integración de MAREA v7

Plan aprobado en la conversación: UI v7 y comportamientos v6, todos con persistencia real.

1. Migraciones 009–011: reacciones, notificaciones privadas, comentarios idempotentes, colaboración explícita y estadísticas por lote.
2. Contratos Dart: repositorio social separado, modelos, controlador de notificaciones ligado a sesión, APP_PUBLIC_URL.
3. UI: cabeceras oficiales, post adaptable y paneles sociales, detalle y retorno del login, guardados existentes.
4. Verificación: SQL/RLS, Flutter, layout, builds, gate remoto y cuentas temporales.

URL inicial: https://marea-azul.netlify.app/. Compartir requiere cuenta y abre /posts/{id}.
Comentarios y mensajes: 1–1000 caracteres. Una reacción y un interés por usuario/post.
Sin visor, chat privado, push del sistema ni segundo almacenamiento de guardados.
Conservar permisos, moderación, preferencias de perfil y reglas de Misiones existentes.
