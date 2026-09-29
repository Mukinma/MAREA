# MAREA — Inicio definitivo v6

## Entrega y precedencia

- [Inicio en escritorio y móvil](../output/imagegen/marea-home-final-v6.png) · [Prompt y correcciones completas](../output/imagegen/marea-home-final-v6.prompt.txt).
- [Guardados móvil y Notificaciones en móvil/escritorio](../output/imagegen/marea-home-header-final-v6.png) · [Prompt y corrección completa](../output/imagegen/marea-home-header-final-v6.prompt.txt).
- [Logotipo oficial](../output/imagegen/brand/MAREA_LOGOTIPO.png) · [Isotipo oficial](../output/imagegen/brand/MAREA.png): copias intactas de los archivos proporcionados.

Entrega exclusivamente visual creada y corregida con imagegen. Personas, publicaciones y contadores ilustrativos. No modifica Flutter, APIs ni base de datos.

Esta versión sustituye las cabeceras, Buscar/Actividad y visor de [v5](home-brand-ui-v5.md). Conserva el marco de [v4](home-vertical-ui-v4.md), la distribución web de v5 y los comportamientos sociales de [v3](home-social-ui-v3.md), con participación en la columna derecha. Ante diferencias, prevalece este documento. No hay visor de fotografía independiente.

Los bitmaps comunican jerarquía y distribución; las medidas, fuente y proporción 3:5 siguientes son criterios para la implementación. Usar los assets oficiales, no redibujos ni recortes del mockup, para reproducir la marca exacta.

## Cabeceras y navegación

| Superficie | Diseño |
| --- | --- |
| Escritorio | Barra blanca plana de 64 px. Solo isotipo de 32–36 px a la izquierda. Inicio, Explorar, Misiones y Perfil en texto; activo navy y línea aqua inferior. Sin cápsulas ni sombra marcada. A la derecha, separadas de los destinos: Guardados, Notificaciones y botón azul Crear. |
| Móvil | Barra blanca de 52–56 px bajo la zona segura. Solo logotipo oficial a la izquierda; Guardados y Notificaciones a la derecha. Sin isotipo ni Crear duplicado. |
| Dock móvil | Cápsula flotante con Inicio/Explorar/Misiones/Perfil y botón circular Crear separado. Solo destino activo etiquetado. Fondo inferior opaco y espacio reservado por su altura más safe area. |

Cabecera fuera del scroll del feed. Ningún buscador ni acceso extra a búsqueda en ambas cabeceras. La búsqueda y descubrimiento pertenecen a Explorar, cuyo icono de navegación se conserva. Inicio aparece únicamente en navegación.

Guardados usa bookmark; Notificaciones usa campana con punto aqua solo si existen entradas sin leer. Nombres accesibles: Guardados, Notificaciones, Crear; las notificaciones pendientes tienen descripción de estado accesible. Mantener targets de 48 px, iconos de 20–24 px y contraste legible. Si falta ancho, adaptar espaciamiento y distribución sin solapar destinos ni comprimir targets.

## Post y lectura

**Escritorio:** marco continuo de 780–860 px, autor y fecha arriba sobre las tres columnas. Foto 3:5, aproximadamente 300 × 500 px, a la izquierda; lectura de 280–320 px en el centro; acciones de 56–64 px al extremo derecho. Lectura agrupada con altura natural y centrada verticalmente; si es más larga, el marco crece. Sin pie de texto debajo de la foto.

**Móvil:** autor arriba, foto 3:5 y controles a su derecha dentro del marco, título y descripción conectados debajo. Sin controles sociales junto al autor. El post siguiente empieza tras un espacio real de 20–24 px; la continuidad del contorno permite reconocer cada unidad. Radio de 20 px, superficie blanca sobre fondo cálido. Cuerpo de 16 px, títulos de 20–22 px, Nunito Sans.

**Texto sin fotografía:** mismo autor, marco y orden de controles, altura determinada por texto. Sin hueco reservado ni fotografía de relleno. Ubicación, precio y Me interesa colaborar aparecen solo cuando aplican. El CTA de colaboración pertenece al contenido, no a la cabecera.

**Foto:** permanece dentro del post. Sin icono de ampliación, navegación a visor, doble toque para zoom ni affordance de apertura. Conservar el contenido esencial y no estirar. Para originales horizontales, elegir encuadre seguro; si el recorte elimina información necesaria, ajustar el contenido dentro del área de referencia con márgenes discretos. Nunca depender de un visor para entender la imagen.

**Descripción:** hasta tres líneas de vista previa. Ver más expande dentro del mismo marco; Ver menos vuelve a plegar. No navegar ni superponer un panel de lectura. Preservar el ancla del post y el foco del control al cambiar altura; permitir scroll y crecimiento con texto ampliado.

## Guardados

Acceso directo a la colección existente: **`/explore?section=saved`**. La ruta y parámetro están presentes en `app_router.dart`, y `explore_screen.dart` aplica el estado saved tanto a publicaciones como a fichas. La lámina propone organizar su lectura en Publicaciones/Fichas sin crear otra colección ni otro almacenamiento.

El bookmark de la cabecera representa la colección, no alterna el guardado del post visible. En ese destino, Explorar sigue seleccionado en el dock y el bookmark de cabecera indica el contexto. Seleccionar una vista previa abre la publicación o ficha correspondiente; volver conserva pestaña y posición.

Guardar/Quitar guardado continúa en Acciones del post. Persistir en el sistema existente, confirmar con Deshacer y actualizar la colección. Deshacer revierte la última operación confirmada. Ante fallo, conservar el estado confirmado y ofrecer reintento.

- Carga: esqueletos discretos; vacío por tipo: mensaje y acceso a Explorar.
- Error: reintento sin perder pestaña; contenido retirado: explicación y posibilidad de quitar el guardado.
- Las vistas previas de la colección no son un segundo tipo de post con participación diferente.

## Notificaciones

Renombra Actividad de v5 y conserva sus funciones. Panel lateral de 330–360 px bajo la cabecera en escritorio; panel inferior modal en móvil. En escritorio, redistribuir el ancho disponible del feed para que texto y controles no queden ocultos. En móvil, el fondo queda inactivo y el dock se oculta bajo el sheet. Cerrar devuelve al mismo punto y restaura foco a la campana.

Filtros Todo/Sin leer y acción Marcar todo como leído. Cada entrada contiene persona, acción, publicación y fecha; vista previa para comentarios e intereses. El ejemplo tiene dos sin leer y una leída, coherentes entre las dos superficies.

| Tipo | Destino al pulsar |
| --- | --- |
| Reacción recibida | Su publicación. |
| Comentario recibido | Publicación y conversación correspondiente. |
| Interés de colaboración recibido | Invitación y mensaje recibido. |

Marcar una entrada como leída al abrir con éxito su destino, no por abrir el listado. Marcar todo como leído requiere confirmación del servidor; un fallo conserva estados anteriores y permite reintentar. El punto de campana se actualiza al cambiar pendientes. Contenido retirado muestra explicación.

Carga con esqueletos; vacío inicial con mensaje breve; Sin leer vacío con Sin notificaciones pendientes; error con reintento conservando filtro. Filas crecen con texto y permiten desplazamiento; ningún mensaje accionable queda cortado.

## Participación y accesibilidad

Columna derecha, con y sin foto: **reacción/total → comentarios/total → compartir → Acciones**.

- Reacciones: selector anclado al control, Me gusta/Me inspira/Lo apoyo. Una selección por persona y publicación; elegir otra reemplaza, elegir la activa permite retirar. Icono, nombre y mint indican selección; contador total.
- Comentarios: panel inferior móvil/lateral web, conversación desplazable y respuesta accesible sobre teclado. Conservar borrador ante error y bloquear envíos repetidos.
- Compartir: Compartir enlace/Copiar enlace, confirmación de copia.
- Acciones: Guardar/Quitar guardado, detalles y reportar; propietario dispone de editar/eliminar según permisos. Ver detalles abre el detalle de publicación, nunca un visor de foto.
- Colaboración: formulario breve con mensaje, carga, error/reintento, confirmación e Interés enviado; impedir duplicados.

Carga, vacío, fallo y confirmación se muestran en el componente afectado, sin contadores simulados en producción. Un modal a la vez; cerrar/Escape/regreso; foco contenido y restaurado al control de origen. Usar teclado para Tab/Enter y respuesta, objetivos de 48 px y estados distinguibles además del color. Con texto al 200%, permitir crecimiento y scroll, sin tapar contenido, compositor ni botón de envío.

## Entrega progresiva

1. Marca, cabeceras, nuevo inicio, lectura inline, guardados existentes y reacciones. Notificaciones de reacciones se activa cuando existan eventos persistentes y estados de lectura.
2. Comentarios y compartir; incorporar comentarios recibidos a Notificaciones.
3. Interés de colaboración y mensajes; incorporar esos intereses a Notificaciones.

Los mockups muestran el destino completo. Cada control se habilitará cuando exista su comportamiento real y persistencia; no publicar botones inertes. Explorar mantiene la búsqueda existente. Esta entrega no define ni modifica contratos del backend.

## Revisión realizada y verificación posterior

Revisadas ambas láminas y corregidas con imagegen: dock móvil convencional sustituido por cápsula, restitución de Crear web y Ver más móvil, y etiqueta errónea de guardados en Notificaciones. Verificados visualmente: marca por superficie, ausencia de buscador en cabeceras y visor, navegación web plana, texto entre foto y acciones, límites continuos y distinción entre colección y panel.

En implementación se comprobarán dimensiones exactas, encuadre 3:5, assets originales, selección de destinos, persistencia y Deshacer, cambios de altura inline, estados de lectura individual/total, carga/vacío/error, teclado y texto ampliado. Las imágenes no constituyen pruebas de widgets ni de accesibilidad.
