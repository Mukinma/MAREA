# MAREA v7 — integración de inicio y experiencia social

## Entrega

Implementación Flutter con persistencia Supabase de las tres etapas aprobadas.
Referencia visual v7; comportamientos v6. Fecha de verificación: 29 de septiembre
de 2026, zona America/Mexico_City.

Checkout: `/Users/crisis/.codex/worktrees/marea-home-social-v7/marea`.
Rama: `Chris/home-social-v7`. El checkout original y sus cambios pendientes se
conservaron; se copiaron al checkout aislado antes de implementar. La versión v7
se integró posteriormente en `main`. No se ha publicado el frontend en Netlify.
Las migraciones 009–011 **sí están
aplicadas** al proyecto Supabase enlazado, con gate remoto aprobado.

## Interfaz integrada

- Marca oficial como assets intactos: isotipo en escritorio, logotipo en móvil.
- Navegación web neumórfica compartida; Inicio seleccionado con mint. Guardados,
  Notificaciones y Crear fuera de la cápsula. Búsqueda únicamente en Explorar.
- Cabecera móvil compacta; dock con espacio reservado y Crear separado.
- Post reutilizable en Inicio, Explorar, perfil y detalle. Ancho máximo 820 px;
  distribución foto · lectura · acciones desde 760 px disponibles.
- Imagen 3:5 con `contain`: el original permanece completo, sin deformación ni
  visor. Sin fotografía, el bloque de lectura se centra en el espacio disponible.
- Lectura web centrada en su columna, con líneas alineadas a la izquierda;
  cuerpo 16 px, título 21 px, controles de al menos 48 px.
- Autor/avatar reales y fecha/tipo/categoría compactos. Ubicación y precio
  conservan sus flujos existentes. Ver más/Ver menos expande dentro del marco.
- Estadísticas y perfiles por lote; páginas de 30 posts, reintento sin descartar
  las páginas recibidas y protección contra respuestas antiguas.
- Moderación conserva sus permisos y acceso dentro del contenido administrativo.

## Funciones y estados

| Función | Implementación |
| --- | --- |
| Reacciones | Selector anclado: Me gusta, Me inspira, Lo apoyo. Elegir la activa la retira; otra opción la reemplaza. Selección y total confirmados por servidor. |
| Comentarios | Panel inferior móvil/lateral web; páginas de 30, comentarios planos de 1–1.000 caracteres. Borrador e identificador de operación conservados al cerrar o reintentar. Retirada autorizada con confirmación. |
| Compartir | `share_plus` 13.3, enlace a `/posts/{id}`, Clipboard y alternativa de copiar cuando no hay compartir disponible. Cancelación sin mensaje de éxito. |
| Guardados | Repositorios existentes, `/explore?section=saved`, pestañas Publicaciones/Fichas. Acción guardar/quitar, confirmación y Deshacer; sin almacenamiento paralelo. |
| Acciones | Guardar, detalles, reportar y edición/eliminación según permisos existentes; eliminar requiere confirmación. |
| Colaboración | Formulario crear/editar con invitación desactivada inicialmente. CTA solo en posts habilitados, mensaje privado de 1–1.000 caracteres, confirmación e Interés enviado. No se añade chat. |
| Notificaciones | Reacciones, comentarios e intereses reales; Todo/Sin leer, punto pendiente, lectura individual al cargar el destino y marcado total con corte temporal del servidor. Mensaje de interés solo para participantes. |

Los paneles ofrecen carga, vacío, pendiente, fallo y reintento. Los posts retirados
usan un estado explícito. El borrador no desaparece por un fallo; las mutaciones
idempotentes no duplican comentarios/intereses/notificaciones ante reintentos.
Un panel modal a la vez; cerrar/regreso/Escape restauran foco y el fondo queda
inactivo. El pie de los formularios puede desplazarse con teclado/texto ampliado.

## Backend y contratos

- `009_post_reactions.sql`: reacción única por usuario/post, notificaciones
  privadas, estadísticas agregadas, marcado de lectura y publicación Realtime.
- `010_post_comments.sql`: comentarios, identificador de operación único por
  autor, eliminación autorizada y notificación transaccional.
- `011_post_collaboration.sql`: `posts.allows_collaboration=false`, interés único
  por solicitante/post, privacidad y notificaciones.
- RLS limita las lecturas; la escritura social se realiza mediante RPC con
  identidad autenticada. No hay escritura directa de tablas sociales desde el
  cliente. Se rechazan posts no disponibles y cuentas en eliminación.
- Triggers y RPC mantienen mutación/notificación en la misma transacción; no hay
  autonotificaciones. Cambiar reacción actualiza su evento, retirarla lo elimina.
- Relaciones en cascada; sin datos sociales huérfanos al eliminar publicaciones.
- Repositorio social separado, modelos tipados y controlador de notificaciones
  asociado a sesión: Realtime, recarga al abrir/reanudar y limpieza al cerrar sesión.
- Gate ampliado a 001–011: tablas/RLS, grants, RPC, triggers y Realtime.

## Enlaces y acceso

`APP_PUBLIC_URL` configura el dominio; valor inicial
`https://marea-azul.netlify.app/`. La configuración central genera `/posts/{id}`
sin depender de componentes visuales. La lectura requiere autenticación. El
destino interno se conserva durante login, registro y pasos de cuenta; se rechazan
destinos externos y rutas inválidas. Notificaciones de comentarios localizan su
entrada. Netlify conserva `/* /index.html 200`.

## Verificación ejecutada

| Comprobación | Resultado |
| --- | --- |
| `flutter analyze` | Sin problemas |
| `flutter test` | 295 pruebas aprobadas |
| SQL aislado: social | 35 comprobaciones |
| SQL aislado: cuenta/comunidad/misiones/perfil/recuperación/acceso | 33 / 103 / 337 / 36 / 241 / 35 comprobaciones |
| Total SQL aislado | 820 comprobaciones aprobadas |
| Tests del gate | 5 aprobados |
| Integración Supabase real | 21 comprobaciones aprobadas: persistencia, reintentos concurrentes, privacidad, notificaciones, Realtime y cascadas |
| Gate Supabase remoto | Aprobado |
| Build web | Aprobado, `build/web` |
| Build Android debug | Aprobado, `build/app/outputs/flutter-apk/app-debug.apk` |
| Build iOS sin firma | Aprobado, `build/ios/iphoneos/Runner.app` |

Las pruebas de layout cubren 360, 390, 600, 900, 1.024 y 1.440 px a 100% y 200%.
Los paneles se verificaron con teclado y texto ampliado. Las regresiones incluyen
reacción seleccionada/retirada, fallo/reintento idempotente, sesión antigua,
guardados/Deshacer, compartir cancelado, retorno autenticado y rutas inválidas.

En navegador real se verificaron cabeceras accesibles, notificaciones, comentario
destacado, consulta privada del interés, guardados y retorno al enlace del post
tras login. También se comprobó recarga directa de `/posts/{id}?panel=comments`
mediante servidor local con el mismo fallback de `index.html`. El despliegue
Netlify todavía conserva el frontend anterior; no se ha distribuido este build.

Las cuentas temporales usan correos `.invalid`, sin envío de correos. Se retiraron
usuarios, posts, datos sociales y la imagen temporal al cerrar la verificación.
Las capturas usan datos reales creados exclusivamente para estas comprobaciones;
no hay contadores ilustrativos ni una entrada demo en el cliente de producción.

## Crítica final y correcciones aplicadas

1. El inicio tenía controles que retrasaban el contenido: se retiró el refresco
   aislado de Inicio y se mantuvo la actualización del feed, sin encabezado grande.
2. La marca blanca se percibía desconectada: la cabecera ahora usa una superficie
   clara continua. Los originales conservan sus proporciones y colores.
3. El bloque web se percibía lateral: se centró en su propia columna, manteniendo
   lectura izquierda. Los posts de texto no reservan una columna fotográfica vacía.
4. Formularios con teclado/texto al 200% desbordaban: el pie es flexible y
   desplazable, con el campo y la acción accesibles.
5. Navegación interna ocultaba la cabecera a accesibilidad web: se corrigió el
   límite semántico del Navigator y se añadieron nombres explícitos a sus controles.
6. Un comentario destacado alteraba la paginación: el desplazamiento de páginas
   ahora cuenta exclusivamente filas recibidas del servidor.
7. Cerrar la confirmación de colaboración no actualizaba el CTA: el estado cambia
   en cuanto se confirma el envío, independientemente del cierre del panel.
8. SnackBar persistente impedía terminar guardados: confirmación temporal con
   Deshacer; la fila se conserva hasta cerrar la ventana de deshacer.
9. El gate histórico esperaba solo ocho migraciones: su prueba de recuperación
   ahora carga 009–011 y verifica la publicación Realtime.

La compilación web emite advertencias informativas de tree shaking de iconos y
dry run Wasm; termina correctamente. iOS se verificó sin firma; no se generó una
distribución App Store. Android es un APK debug para probar, no un release firmado.

## Evidencia local (no versionada)

Capturas reales: `output/playwright/home-web-v7.png`, `home-mobile-v7.png`,
`notifications-web-v7.png`, `notifications-mobile-v7.png`, `saved-mobile-v7.png`,
`comments-web-v7.png`, `comments-mobile-v7.png`,
`collaboration-message-mobile-v7.png`.

Logs: `output/verification/v7/`. Comandos y configuración:
`tool/README.md`. Fuente de diseño: `docs/home-polished-ui-v7.md`.
