# MAREA — Marca, cabecera y web v5

## Referencias y alcance

- [Inicio: escritorio, móvil y visor](../output/imagegen/marea-home-brand-v5.png) · [Prompt](../output/imagegen/marea-home-brand-v5.prompt.txt).
- [Buscar y Actividad en uso](../output/imagegen/marea-home-header-v5.png) · [Prompt](../output/imagegen/marea-home-header-v5.prompt.txt).
- [Logotipo oficial](../output/imagegen/brand/MAREA_LOGOTIPO.png) y [isotipo oficial](../output/imagegen/brand/MAREA.png): copias intactas de los archivos suministrados por el usuario.

Propuesta visual creada con imagegen integrado. Esta versión actualiza la marca, añade cabecera móvil y sustituye la distribución de escritorio de [v4](home-vertical-ui-v4.md). Conserva la unidad de post y los [comportamientos sociales v3](home-social-ui-v3.md). Datos y contadores ilustrativos. No modifica Flutter, APIs ni base de datos.

## Marca

Usar los archivos oficiales como fuente de implementación, preservando sus proporciones, formas y colores. Logotipo geométrico navy e isotipo circular aqua/navy con sus gradientes. Integrarlos sobre blanco, sin deformación, margen decorativo extra ni marca provisional de ola.

Las imágenes generadas son referencias visuales de colocación; al implementar se usarán los archivos oficiales, no un recorte o redibujo de la marca tomada del mockup. Conservar los originales. Las medidas siguientes corresponden a la especificación de UI, no a una medición exacta del bitmap.

## Posts y adaptación

**Escritorio:** marco continuo de 780–860 px, autor arriba sobre las tres columnas. Foto 3:5 de unos 300 px de ancho a la izquierda, lectura de 280–320 px en el centro, controles de 56–64 px a la derecha. Espacios de unos 24 px. Agrupar título, descripción ampliable, ubicación/precio o colaboración con altura natural y alineación vertical centrada. Sin pie de texto debajo de la foto.

**Móvil:** conservar autor arriba, foto 3:5 a la izquierda y controles a la derecha, pie conectado debajo. Marco de radio 20 px y separación exterior de 20–24 px. El texto determina altura. No forzar primer post y siguiente cabecera a caber reduciendo fuentes en pantallas pequeñas.

**Texto sin foto:** altura natural, contenido y colaboración a la izquierda, controles a la derecha; no placeholder. En ambos formatos, reacción/contador, comentarios/contador, compartir y Acciones mantienen orden y significado. Guardar y gestión siguen en Acciones.

**Visor:** original completo, cerrar, descripción y Participar; sin cabecera ni dock. Restaurar posición del feed al cerrar. Preservar encuadre y evitar deformaciones; las fotos horizontales siguen teniendo acceso al original.

## Cabecera

| Superficie | Distribución |
| --- | --- |
| Móvil | Bajo safe area, blanco, 52–56 px. Isotipo 28–32 px y logotipo de unos 90 px a la izquierda; Buscar y Actividad a la derecha. Targets de 48 px. Sin Crear duplicado. |
| Escritorio | Blanco, 64–72 px. Marca oficial, navegación Inicio/Explorar/Misiones/Perfil, Buscar, Actividad y Crear. Selección mint discreta. Si falta espacio, Buscar se convierte en icono con nombre accesible. |
| Navegación móvil | Dock existente con sus cuatro destinos y Crear separado, en zona inferior reservada. No dibujar publicaciones detrás. |

Cabecera fuera del área de desplazamiento. Inicio únicamente aparece como etiqueta de navegación. En tablet o con texto ampliado, reducir etiquetas/campo de búsqueda antes de comprimir targets; conservar accesibilidad y acceso a cada destino.

## Buscar

Abrir desde campo/icono; contexto de búsqueda con entrada accesible, limpiar consulta, cerrar y filtros Todo/Publicaciones/Personas/Fichas. Todo presenta resultados agrupados por tipo; seleccionar un filtro muestra ese grupo.

Publicaciones abren su contenido; Personas, el perfil; Fichas, su detalle. Conservar consulta/filtro al volver de un resultado y cerrar devuelve al inicio sin perder scroll. Integrar las consultas de contenido, personas y fichas existentes durante la futura implementación; no mostrar resultados ilustrativos en producción.

- **Carga:** progreso discreto y conservación de consulta/filtro; descartar respuestas antiguas de búsquedas superadas.
- **Vacío inicial:** entrada e indicación breve para buscar.
- **Sin resultados:** mensaje asociado a la consulta, con posibilidad de editarla o limpiar filtro.
- **Error:** reintento preservando consulta.
- **Teclado:** entrada enfocada al abrir, enviar búsqueda con Enter; resultados desplazables sobre teclado y dock. Cerrar restaura foco al acceso de cabecera.

## Actividad

Futura actividad recibida por la cuenta actual: reacciones a sus posts, comentarios en sus posts e intereses en sus invitaciones de colaboración. No es chat privado. Los ejemplos de cerámica y taller representan publicaciones propias de la cuenta ilustrativa.

Abrir panel lateral de 330–360 px en escritorio, bajo la cabecera, y sheet inferior desplazable en móvil. Cerrar explícito, tabs Todo/Sin leer y acción Marcar todo como leído. Dock inaccesible bajo sheet modal.

Cada entrada incluye persona, acción, publicación, fecha y vista previa cuando corresponda. Solo entradas sin leer usan indicador aqua y tratamiento visual distinguible. El icono de cabecera muestra punto mientras haya actividad sin leer; sin punto cuando no haya.

- Pulsar una reacción abre su publicación; un comentario abre publicación y conversación; un interés abre contexto de invitación y mensaje recibido.
- Marcar la entrada como leída cuando se abra con éxito su destino, no por abrir únicamente el listado.
- Marcar todo como leído cambia el estado tras confirmación del servidor. Ante fallo, conservar estado anterior y ofrecer reintento.
- Si el contenido ya no está disponible, explicarlo sin abrir un detalle vacío.
- **Carga:** esqueletos de filas; **vacío:** sin actividad todavía o sin pendientes según filtro; **error:** reintento; **lectura:** filas y punto de cabecera coherentes.
- Foco contenido en el modal y restaurado al control de origen; Escape/regreso/cerrar, labels accesibles, área táctil 48 px. Con texto al 200%, permitir crecimiento y scroll, sin cortar fechas, mensajes ni botones.

## Entrega progresiva

1. Marca oficial, cabecera, nuevo inicio/visor, guardados, búsqueda e integración de reacciones; Actividad se activa al disponer de eventos persistentes de reacciones.
2. Comentarios y compartir; añadir comentarios recibidos a Actividad.
3. Interés de colaboración; añadir invitaciones y mensajes recibidos a Actividad.

Cada función se habilita con comportamiento completo. No publicar botones inertes ni contadores simulados. Los modelos y endpoints de actividad se definirán con su backend; esta entrega no crea ese contrato.

## Revisión y aceptación

Revisión visual realizada de ambas láminas: marca oficial como referencia, lectura entre foto y acciones en escritorio, cabecera móvil con Buscar/Actividad, marcos completos, búsqueda agrupada y actividad con estados de lectura coherentes entre móvil y escritorio.

Al implementar: comprobar blanco y proporciones de assets oficiales, foto 3:5, ausencia de texto bajo foto de escritorio, feed sin encabezado Inicio, scroll preservado, teclado, texto ampliado, carga/vacío/error de búsqueda y actividad, lectura individual/total, destinos y contenido no disponible. Verificar que cabecera, dock y paneles no oculten contenido ni inputs. Las pruebas de widgets y accesibilidad quedan para esa implementación.
