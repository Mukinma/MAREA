# Ledger — MAREA v7

## Entrega completada

- Checkout: `/Users/crisis/.codex/worktrees/marea-home-social-v7/marea`, rama `Chris/home-social-v7`.
- Original `/Users/crisis/Proyectos/marea` conservado, incluidos sus cambios pendientes durante la implementación aislada; el trabajo se integró después en `main`.
- Tres etapas implementadas: UI/reacciones, comentarios/compartir, colaboración privada y notificaciones.
- SQL 009–011 aplicado a Supabase remoto; gate extendido aprobado. Frontend no publicado en Netlify.
- APP_PUBLIC_URL central, detalle autenticado, retorno interno tras login/registro/pasos de cuenta.

## Verificación final

- Flutter: 295 pruebas aprobadas; analyze sin problemas.
- SQL aislado: 820 comprobaciones (35 sociales, 33 base, 103 comunidad, 337 misiones, 36 perfil, 241 recuperación, 35 acceso).
- Gate: cinco tests aprobados y consulta remota aprobada.
- Integración real: 21 comprobaciones de persistencia, privacidad, concurrencia, Realtime y cascadas.
- Builds secuenciales web, Android debug e iOS sin firma aprobados.
- Navegador real: capturas web/móvil, notificaciones/comentarios/interés privado/guardados; login desde enlace directo y recarga `/posts/{id}?panel=comments` verificados.
- Usuarios temporales y archivo temporal de Storage eliminados; browser y servidores locales cerrados.
- Evidencia local no versionada: `output/playwright/`, `output/verification/v7/`; documento final `docs/home-social-v7-integration.md`.

## Revisión y correcciones

Revisión independiente `/root/review_social_v7` concluida. Corregidos paginación de comentario destacado, CTA de interés al cerrar, retirada de reacción activa, footer con teclado/200%, SnackBar Deshacer y semántica accesible de la cabecera bajo Navigator. La prueba histórica del gate carga ahora 009–011 y Realtime.

## Estado de distribución

Código integrado en `main`. No hay release firmado ni despliegue frontend. Los cambios previos del usuario se conservaron en un commit separado antes del merge v7.
