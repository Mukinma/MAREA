# MAREA — Post vertical v4

## Referencias y alcance

- [Modelo principal: escritorio, móvil y visor](../output/imagegen/marea-home-vertical-v4.png).
- [Variantes: texto, descripción expandida y reacciones](../output/imagegen/marea-home-vertical-states-v4.png).
- [Prompt principal y refinamientos](../output/imagegen/marea-home-vertical-v4.prompt.txt).
- [Prompt de variantes y refinamiento](../output/imagegen/marea-home-vertical-states-v4.prompt.txt).

Propuesta visual generada con imagegen integrado. Esta versión sustituye la distribución de posts de v3; conserva los comportamientos, estados y entrega progresiva de [Inicio social v3](home-social-ui-v3.md). Los datos son ilustrativos. No modifica Flutter, APIs ni base de datos.

## Unidad y límites

Un solo marco blanco con contorno suave y radio de 20 px contiene **cabecera, contenido con controles y pie**. Separación de 20–24 px de fondo cálido entre publicaciones. El principio se reconoce por el autor; el final, por el cierre del marco tras el texto. Las rayas no son el único indicador.

- **Cabecera:** avatar, nombre, fecha y categoría secundaria. Sin controles de participación.
- **Con fotografía:** imagen vertical 3:5 a la izquierda; columna de controles a la derecha, externa a los píxeles de imagen e interna al marco.
- **Columna:** reacción con total, comentarios con total, compartir y Acciones, en ese orden. Ancho orientativo 56–64 px, separación de 8–12 px de la imagen, targets de al menos 48 px. Selección mint con icono y estado accesible.
- **Pie unido:** título de 20–22 px y descripción de 16 px, hasta tres líneas en reposo. Ver más amplía dentro del mismo marco; Ver menos lo contrae. Ubicación/precio solo cuando existan. El contenido determina altura, sin reserva vacía.
- **Sin fotografía:** texto y CTA de colaboración a la izquierda, controles a la derecha; cabecera y marco conservados. Altura natural suficiente para lectura y controles, sin placeholder ni proporción fotográfica impuesta.

Fondo Paper, superficies blancas, navy y aqua existentes, Nunito Sans. Mantener iconos de 20–24 px y metadatos de 12–13 px.

## Adaptación y fotografías

Móvil: márgenes exteriores de unos 12 px y una columna de posts. El área desplazable termina antes del espacio reservado al dock; no dibujar texto o imágenes detrás de él. El primer post completo y la siguiente cabecera son la referencia de composición, no una obligación de encoger contenido en pantallas pequeñas.

Escritorio: mismo modelo, centrado, ancho máximo aproximado de 440 px; puede ser más estrecho para conservar una altura razonable. La navegación global conserva sus destinos y Crear. No se añade encabezado de sección: Inicio únicamente identifica el destino activo.

En implementación fijar la caja de imagen a 3:5. Las láminas raster son referencias visuales, no mediciones exactas. Preservar el original, sin estirar. Comprobar encuadres horizontales: si el recorte elimina contenido esencial, mostrar la imagen completa dentro del espacio disponible. Pulsar siempre permite consultar el original en el visor.

## Interacciones

- El selector de reacciones se ancla al primer control de la columna derecha y abre hacia el espacio disponible, sin quedar fuera del viewport. Elegir Me gusta, Me inspira o Lo apoyo; cambiar o quitar según v3.
- Comentarios y compartir mantienen sus paneles. El autor no comparte fila con guardar o gestión.
- Acciones concentra Guardar/Quitar guardado, detalles y opciones según propiedad. Confirmación de guardado con Deshacer.
- Me interesa colaborar pertenece al texto de invitaciones explícitas; abre mensaje y conserva confirmación Interés enviado y protección de duplicados.
- Visor con fotografía completa, cerrar, descripción y acceso a participación; restaurar el mismo scroll al volver.
- Expandir descripción conserva la cabecera y la posición del post. En texto ampliado, crecer o desplazar sin reducir tipografía ni zonas táctiles; la columna sigue ligada a su post.

## Estados y entrega progresiva

Conservar carga, vacío, selección, operación pendiente, error/reintento y confirmación definidos en v3. Mantener borradores ante fallo, foco al abrir/cerrar paneles, teclado, safe areas y nombres accesibles. Un modal activo a la vez.

1. **Inicio, visor, guardados y reacciones:** integrar la nueva unidad visual y persistencia.
2. **Comentarios y compartir:** conversación, compositor y enlaces estables de detalle.
3. **Interés de colaboración:** invitación explícita, mensaje, confirmación y prevención de duplicados.

Activar cada función cuando disponga de comportamiento completo. La propuesta visual muestra el destino futuro.

## Revisión y aceptación

Revisión visual realizada: marco continuo, cabeceras reconocibles, primer cierre visible, controles a la derecha y pies conectados; variante sin fotografía, texto expandido y selector apuntando al control de reacción. Se corrigieron el formato casi cuadrado de escritorio y la fotografía de relleno que imagegen añadió inicialmente al siguiente post.

Al implementar, verificar: tamaños móviles y escritorio, foto vertical/horizontal, post de texto, descripciones largas, ausencia de datos opcionales, todas las reacciones, guardado/deshacer y retorno del visor. Comprobar con teclado y texto al 200% que el marco crezca, los targets se mantengan y el dock no tape contenido. Estas pruebas de widgets y accesibilidad no se ejecutan en esta entrega exclusivamente visual.
