# MAREA — Acabado neumórfico y composición equilibrada v7

## Entrega

- [Inicio: escritorio y móvil](../output/imagegen/marea-home-polished-v7.png) · [Prompt completo y correcciones](../output/imagegen/marea-home-polished-v7.prompt.txt).
- [Guardados y Notificaciones](../output/imagegen/marea-home-header-polished-v7.png) · [Prompt completo y correcciones](../output/imagegen/marea-home-header-polished-v7.prompt.txt).
- [Referencia de navegación del usuario](../output/imagegen/brand/marea-navigation-reference-v7.png), conservada intacta.
- [Logotipo oficial](../output/imagegen/brand/MAREA_LOGOTIPO.png) · [Isotipo oficial](../output/imagegen/brand/MAREA.png).

Mockups generados y refinados con imagegen integrado. Entrega exclusivamente visual: imágenes, prompts y especificación. Sin modificaciones en Flutter, APIs ni base de datos. Contenido, personas y contadores ilustrativos.

Esta versión sustituye el acabado visual y la navegación web subrayada de [v6](home-final-ui-v6.md). Conserva su estructura, comportamientos, destinos, estados y entrega progresiva. No incorpora funciones adicionales.

## Paleta y profundidad

La fuente de valores es el tema existente de MAREA, especialmente AppColors y AppDepth. La siguiente tabla es el contrato visual para implementar; el raster generado no garantiza reproducción exacta de cada hexadecimal.

| Uso | Token y valor |
| --- | --- |
| Fondo general | Paper #FAF9F6 |
| Post, panel y navegación | Surface #FFFFFF |
| Títulos y lectura | TextPrimary #102149 |
| Fecha, categoría, ubicación e iconos inactivos | TextSecondary #66738B |
| Marca y selección de navegación | BrandNavy #0B255E |
| Crear y CTA principal sólido | ActionBlue #0D4397 |
| Selección y colaboración contextual | Mint #DDF5EF |
| Indicador de pendientes y acento discreto | Aqua #22C5C1 |
| Contorno neutro suave | SoftBorder #E9E8E4 |

Eliminar azul eléctrico de párrafos, iconos ordinarios y contornos. Ver más y otras acciones de texto usan navy con peso y nombre reconocibles; no necesitan un gran botón azul. Los colores de la fotografía pertenecen al contenido y no tiñen el resto del post.

Neumorfismo moderno moderado: luz superior izquierda, sombra inferior derecha y brillo superior izquierdo. Referencia AppDepth.raised: sombra #E1E5EA, desplazamiento 6/6 y blur 18; brillo blanco, desplazamiento -5/-5 y blur 14. Navegación flotante usa el relieve de AppDepth.floating. Crear usa su sombra de acción discreta.

Concentrar elevación en el marco del post, cápsula de navegación y paneles. Los controles ordinarios y filas de notificaciones no llevan una elevación individual. Los límites no dependen solo de sombras: blanco sobre Paper, contorno neutro y separación de 20–24 px. Sin biseles gruesos, reflejos brillantes ni superficies celestes extensas.

## Navegación y marca

**Escritorio:** mantener isotipo oficial a la izquierda. Navegación central dentro de una única cápsula elevada, como la referencia adjunta: casa/Inicio, lupa/Explorar, bandera/Misiones y persona/Perfil. Activo sobre mint con icono y texto navy; inactivos grises. Inicio es activo en ambas vistas web de esta entrega. Sustituir el subrayado de v6, sin añadir un segundo indicador. Fuera de la cápsula, a la derecha: Guardados, Notificaciones y Crear.

La lupa es el icono del destino Explorar, no un acceso independiente a Buscar. Mantener nombres y orden de destinos. La cabecera debe dejar altura suficiente para la cápsula y sus márgenes sin comprimir los targets de 48 px.

**Móvil:** solo logotipo oficial a la izquierda; Guardados y Notificaciones a la derecha. Sin isotipo, buscador ni Crear duplicado. Cabecera de 52–56 px bajo zona segura, fuera del scroll. Mantener dock aprobado con cápsula de cuatro destinos y Crear circular separado; zona inferior opaca reservada. Solo destino activo etiquetado.

En Guardados móvil, bookmark de cabecera lleno y Explorar seleccionado en dock. Detrás de Notificaciones móvil, el feed de Inicio mantiene bookmark de cabecera en contorno. La campana muestra punto aqua mientras existan pendientes.

Usar los archivos originales para reproducir marca exacta; no tomar un redibujo del bitmap. Mantener proporciones y colores sobre blanco.

## Posts y equilibrio

**Web con foto:** feed centrado en la página, marco de referencia de 780–860 px. Autor arriba sobre foto, lectura y acciones. Foto vertical 3:5, aproximadamente 300 × 500 px; preservar sujeto esencial y evitar deformación. Lectura de 280–320 px agrupada con altura natural y centrada horizontal y verticalmente en el espacio intermedio. Las líneas de título, descripción y metadatos permanecen alineadas a la izquierda. No hay texto debajo de la foto.

**Web sin foto:** no conservar una columna vacía para imagen. Debajo del autor, agrupar título, descripción y colaboración en un bloque compacto de lectura; centrarlo en el área disponible antes de las acciones. Texto alineado a la izquierda. El marco crece con su contenido.

**Móvil:** autor arriba, foto 3:5 a la izquierda y controles externos a su derecha, todos dentro del mismo marco. Pie compacto conectado: título, descripción y ubicación o colaboración cuando correspondan. El pie puede usar el ancho disponible completo del post. No comprimir fuentes para forzar un número de posts visibles.

**Participación:** columna neutra dentro del post, en orden reacción/total, comentarios/total, compartir y Acciones. Iconos ordinarios grises; reacción seleccionada con icono reconocible sobre mint. Retirar la franja aqua continua. Mantener targets de 48 px, contadores y nombres accesibles. La columna pertenece inequívocamente a su publicación.

Nunito Sans, cuerpo 16 px, títulos 20–22 px. Radios de 20–24 px y separación exterior de 20–24 px. Ver más/Ver menos expande o pliega lectura dentro del marco, conservando ancla y foco. La foto no abre visor, no tiene zoom ni control de ampliación.

Con Notificaciones web abierto, reservar espacio lateral y redistribuir el feed sin tapar lectura ni acciones. Si la pantalla no puede acomodar ambos, adaptar el panel sin reducir tipografía ni targets por debajo de la especificación.

## Destinos y estados conservados

Guardados conduce al sistema existente en **/explore?section=saved**, con publicaciones y fichas. El acceso de cabecera abre colección; Guardar/Quitar guardado sigue en Acciones. Conservar confirmación y Deshacer.

Notificaciones mantiene panel lateral web y sheet inferior móvil, Todo/Sin leer y Marcar todo como leído. Cada fila identifica persona, acción, publicación y fecha. La lámina muestra dos pendientes y una entrada leída, con los mismos datos en ambas superficies. Texto primario oscuro, metadata gris y tintado mint muy tenue solo para pendientes.

Conservar carga, vacío, error/reintento, leído/sin leer, destino retirado y marcado tras apertura exitosa; el marcado total requiere confirmación de persistencia. El sheet móvil deja inactivo el fondo y oculta el dock. Cerrar restaura foco y posición.

Reacciones Me gusta/Me inspira/Lo apoyo, comentarios, compartir y colaboración conservan paneles, formularios, confirmaciones y errores de v6. No modificar contratos públicos, modelos ni almacenamiento.

## Crítica final y mejoras aplicadas

| Hallazgo durante la revisión | Corrección realizada con imagegen |
| --- | --- |
| V6 parecía un esquema por la tinta azul repetida y la franja aqua de acciones. | Paleta neutral, controles discretos, franja eliminada y color concentrado en selección, pendientes y Crear. |
| La navegación plana no seguía la referencia de la aplicación. | Cápsula compartida con icono y etiqueta, relieve suave y activo mint. |
| La primera generación dejaba el post de texto pegado al borde. | Bloque compacto separado del borde y equilibrado en el área de contenido; descripción con ancho de lectura natural. |
| El cuerpo tenía un tono demasiado parecido a la metadata. | Solicitud de mayor contraste y texto principal oscuro, manteniendo metadata secundaria. |
| Las generaciones ensancharon las fotos web. | Refinamientos para recuperar la presentación vertical y preservar el cuenco; la proporción exacta se fijará en componentes reales. |
| El bookmark del feed detrás del sheet aparecía activo como si fuera Guardados. | Contorno en Inicio; lleno únicamente en la colección. |
| Un exceso de relieve podía hacer competir los controles con el contenido. | Elevación concentrada en superficies principales; acciones y filas conservan un tratamiento ligero. |

La versión final reduce el peso visual de la interfaz y mantiene una unidad clara de publicación. La lectura web conserva la estructura asimétrica aprobada, con el bloque de texto equilibrado y párrafos alineados a la izquierda. No se añadieron funciones para llenar espacios.

## Validación y entrega progresiva

Revisión visual realizada de las dos láminas finales: marca por superficie, navegación tipo referencia, ausencia de buscador adicional y visor, lectura entre foto/acciones en web, continuidad del post, orden de participación y destinos distintos de Guardados/Notificaciones.

Los hexadecimales, dimensiones, relación 3:5, contraste medido y fuente exacta son criterios de implementación, no mediciones certificadas del bitmap. Verificar entonces: texto al 200%, teclado/foco, targets de 48 px, descripción larga, post sin foto, encuadre horizontal, carga/vacío/error, estados de lectura y persistencia de guardados. Las imágenes no son pruebas de widgets ni de accesibilidad.

1. Cabeceras, inicio, lectura inline, guardados existentes y reacciones; activar notificaciones de reacciones con eventos persistentes.
2. Comentarios y compartir; sumar comentarios recibidos a Notificaciones.
3. Colaboración con mensaje y confirmación; sumar intereses recibidos.

Habilitar cada función al disponer de su comportamiento real. Conservar originales y versiones anteriores.
