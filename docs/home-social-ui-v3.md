# MAREA — Inicio social v3

## Referencias y alcance

- [Experiencia principal](../output/imagegen/marea-home-social-v3.png): escritorio, móvil y visor.
- [Interacciones abiertas](../output/imagegen/marea-home-social-interactions-v3.png): reacciones, comentarios, acciones y colaboración.
- [Prompt principal](../output/imagegen/marea-home-social-v3.prompt.txt) y [prompt de interacciones y refinamiento](../output/imagegen/marea-home-social-interactions-v3.prompt.txt).

Propuesta de UI futura generada con imagegen integrado y revisada visualmente. Personas, publicaciones, mensajes y contadores son ilustrativos. Esta entrega contiene imágenes y especificación; Flutter, APIs y base de datos no se modificaron. Los tamaños exactos, accesibilidad y comportamiento se comprobarán al implementar widgets reales.

## Estructura

Escritorio: fotografía a la izquierda, lectura lateral y participación al pie. Móvil: imagen primero, lectura ligeramente desplazada, autor compacto y participación; dock con espacio reservado. No existe encabezado de sección: Inicio solo aparece en navegación.

Paleta MAREA navy/aqua/paper, Nunito Sans, cuerpo de 16 px, títulos de 20–22 px y controles con áreas táctiles de al menos 48 px. Estas medidas son criterios de implementación; el bitmap no es una medición de widgets.

La banda mantiene el orden **reacción y total · comentarios y total · compartir · Acciones**, con y sin fotografía. Autor y fecha no contienen guardar ni opciones. Colaborar es una acción contextual junto al texto, únicamente para invitaciones explícitas de su autor.

## Comportamientos

| Entrada | Comportamiento esperado |
| --- | --- |
| Reacción | Pulsar abre selector anclado al primer control: Me gusta, Me inspira y Lo apoyo. Una reacción por persona y post. Elegir otra reemplaza la anterior; elegir la activa o Quitar reacción la retira. Color, icono y nombre accesible indican selección. El número es el total de reacciones, no solo las del tipo seleccionado. |
| Comentarios | Panel inferior móvil y lateral en escritorio. Conversación desplazable y compositor fijo sobre teclado/safe area. Enviar texto no vacío; conservar borrador ante fallo. Actualizar lista y contador tras éxito, sin duplicar envíos. |
| Compartir | Abrir opciones Compartir enlace y Copiar enlace. Usar enlace estable de publicación; confirmar copia. Resolver la ruta pública de detalle al implementar esta etapa. |
| Acciones | Visitante: Guardar/Quitar guardado, Ver detalles y Reportar. Propietario: Guardar/Quitar guardado, Ver detalles, Editar y Eliminar. Conservar reglas de propiedad y moderación existentes. |
| Guardar | Alternar estado; confirmación discreta con Deshacer que revierte la última operación. La lámina muestra guardado confirmado, por eso el menú indica Quitar guardado. |
| Reportar / Eliminar | Solicitar motivo de reporte y confirmar eliminación en sus flujos correspondientes. Cerrar el menú no ejecuta acciones. |
| Colaborar | Abrir contexto de publicación y mensaje. Enviar interés no vacío; tras éxito cerrar formulario y sustituir CTA por Interés enviado. Reabrir muestra confirmación sin otro envío. Bloquear duplicados y no mostrar CTA al autor del post. No equivale a postularse automáticamente a una misión. |
| Foto / visor | Abrir foto completa y conservar posición del feed. Cerrar devuelve al mismo punto. Ver descripción despliega lectura; Participar da acceso a la misma banda. La foto permanece despejada y el visor no muestra dock global. |

## Estados y accesibilidad

- **Carga inicial:** esqueletos discretos de contenido; conservar la estructura sin mostrar contadores ficticios.
- **Vacío:** feed con acceso a Crear; comentarios con mensaje breve y compositor disponible; reacciones con total cero.
- **Operación pendiente:** progreso en el control afectado y bloqueo de envíos repetidos; mantener el resto de la lectura disponible.
- **Error y reintento:** explicación breve junto a la operación; conservar formulario/comentario y revertir cualquier estado optimista no confirmado.
- **Confirmación:** reacción seleccionada, guardado con Deshacer, comentario incorporado, enlace copiado e Interés enviado.
- **Paneles:** un modal a la vez, cerrar por botón/regreso/Escape, foco contenido y restaurado al control de origen. La navegación global queda cubierta e inaccesible bajo sheets modales; el selector pequeño mantiene su anclaje.
- **Teclado y texto ampliado:** Tab/Enter y nombres accesibles para iconos, lectura y contadores; contraste y selección independientes del color. Compositor y envío sobre el teclado. A 200% de texto, permitir crecimiento y scroll; banda adaptable manteniendo orden y targets de 48 px.

## Entrega progresiva

1. **Inicio, visor, guardados y reacciones:** construir estructura y selector; integrar persistencia de reacciones, permisos y contadores antes de activar la función.
2. **Comentarios y compartir:** integrar conversación, envío, estados, moderación aplicable y enlaces de detalle.
3. **Interés de colaboración:** permitir invitación explícita, guardar interés y mensaje, mostrar confirmación y evitar duplicados.

Activar solo funciones disponibles en cada etapa. El diseño completo es la referencia de destino; la UI distribuida no incluye controles sin comportamiento. Las estructuras y endpoints nuevos se definirán con el backend de cada etapa, no a partir de los contadores del mockup.

## Revisión y criterios para implementación

Las láminas finales muestran participación reunida, guardado fuera del autor, selector anclado a reacción, conversación sin acciones adicionales, menú en estado coherente de guardado y formulario previo al envío. Se retiró la barra superior que imagegen había añadido al móvil.

Al implementar: verificar posts con/sin foto, propietario/visitante, cada reacción y su retirada, guardado/deshacer, comentarios vacíos y fallidos, compartir/copia, colaboración enviada/fallida y retorno del visor al mismo scroll. Revisar móvil y escritorio con teclado y texto ampliado; ningún control debe tapar fotografía, lectura, compositor ni dock.
