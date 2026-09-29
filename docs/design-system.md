# Sistema visual de MAREA — MVP

Este sistema implementa el rediseño neumórfico de MAREA en Flutter. La referencia de imagegen está en `output/imagegen/marea-neumorphic-navigation.png`: navegación superior en web, dock flotante en móvil y relieve moderado. Las fotografías y personas del concepto son ejemplos visuales; la aplicación muestra los datos reales y conserva su logo original.

## Personalidad

Social, creativa, cercana, tecnológica, joven, amigable y expresiva. La interfaz prioriza el contenido y usa relieve moderado, sin textos decorativos ni bloques de presentación repetidos. Los encabezados identifican la sección; las ayudas explican decisiones, validaciones y estados reales.

## Tokens

| Token | Valor | Uso |
|---|---:|---|
| Brand Navy | `#0B255E` | Marca, titulares, avatar |
| Action Blue | `#0D4397` | CTA y selección |
| Aqua | `#22C5C1` | Acentos, guía y progreso |
| Mist | `#EAF6FD` | Bloques suaves |
| Canvas | `#F7FBFF` | Fondo frío secundario |
| Paper | `#FAF9F6` | Fondo general cálido, panel de bienvenida e inputs |
| Surface | `#FFFFFF` | Cards, navegación y área de autenticación |
| Text | `#102149` | Texto principal |
| Secondary | `#66738B` | Texto secundario |
| Border | `#D9E5F0` | Contornos ligeros |
| Soft Border | `#E9E8E4` | Contornos neutros de inputs y separación lateral |
| Error | `#C93F58` | Acciones destructivas |
| Success | `#128C78` | Confirmaciones |

Las categorías usan lavanda, durazno, rosa y menta. Nunca sustituyen el azul del CTA principal.

El pulido visual conserva todos los colores originales de marca y añade un neutro cálido para reducir la asociación clínica de grandes superficies celestes. Mist queda reservado para contextos puntuales. Los pasteles se concentran en la ilustración de bienvenida, la portada social y pequeños acentos; no tiñen toda la interfaz.

## Tipografía y geometría

- Nunito Sans local: 400, 600, 700 y 800.
- Escala de espacios: `4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 / 64`.
- Radios: `12 / 16 / 20 / 28 / pill`.
- Botones: 52 px de alto; inputs: alrededor de 58 px; targets táctiles: mínimo 48 px.
- Sombras dobles con luz desde arriba a la izquierda y profundidad compartida en `AppDepth`. Relieve interior en campos y selectores; contornos de foco y error visibles. Movimiento funcional de 150–300 ms.

## Componentes

- **Botón principal:** azul sólido, texto blanco, radio 16, sombra azul discreta y loading integrado.
- **Input:** superficie Paper con relieve interior, contorno neutro discreto, foco azul y error traducido. Se conservan etiquetas, validación y autofill.
- **Card:** superficie blanca sobre Paper, radio 24 y sombras compartidas. `MareaSurface` conserva tinta Material y `MareaCard` unifica publicaciones, fichas, onboarding y estados.
- **Chip:** pastel contextual con texto navy; no actúa como CTA.
- **Navegación:** cinco destinos. En móvil, cápsula flotante con Inicio, Explorar, Misiones y Perfil más botón Crear separado. La selección muestra una etiqueta si cabe; todos los destinos tienen tooltip, semántica y acción accesible. A partir de 600 px se usa una barra superior con marca, navegación central y Crear. Las etiquetas completas aparecen desde 1024 px cuando el tamaño de texto lo permite.
- **Perfil:** identidad compacta sin título ni regreso en el perfil propio. Portada de 80 px en móvil y 96 px en escritorio, avatar de 76 px que se superpone 20 px al borde inferior, nombre de 24 px y username debajo. Editar perfil es una acción de texto compacta junto al avatar; Configuración usa un icono de ajustes discreto en esa misma fila, fuera de la portada y sin superficie elevada propia. El tipo usa un acento por perfil. Desde 1024 px, identidad de 300 px a la izquierda y contenido a la derecha. Los perfiles públicos tienen regreso y acciones de visitante. Correo queda en Configuración; UUID y role no se muestran.
- **Autenticación:** formulario elevado de radio 32, títulos breves y marca original. En escritorio desde 1024 px, ilustración lateral y formulario compacto; en móvil, logo compacto y formulario desplazable sobre el teclado. Bienvenida con composición protagonista y Crear cuenta como acción principal. Tipo con icono, nombre y frase corta; selección con borde navy y fondo mint. La elección se confirma dentro del registro y la guía posterior es opcional. Ver [acceso y guías](access-redesign.md) y las [cuatro láminas de imagegen](../output/imagegen/README-access.md).

`CreativeArtwork` y `MareaCover` son ilustraciones vectoriales de interfaz, excluidas de la semántica accesible. No sustituyen ni rediseñan el logo o la mascota, no son contenido personalizable y no añaden nuevas funciones.

## Responsive

- Mobile: `<600 px`, dock inferior con margen y safe area, sin cubrir contenido.
- Tablet: `600–1023 px`, navegación superior adaptativa.
- Desktop: `>=1024 px`, navegación superior; autenticación en composición dividida.
- Inicio limita el feed a 760 px; el perfil, a 1200 px; las páginas de comunidad, a 960 px. Las fichas del perfil usan dos columnas cuando caben tarjetas de al menos 160 px, y una en espacios menores. Portafolio/Catálogo/Servicios y Publicaciones conservan contenido y desplazamiento al cambiar de pestaña; los perfiles públicos también ofrecen Misiones.
- Edición de perfil separa Identidad y Profesional, conserva sus campos y abre la sección del primer error. Las secciones ocultas no reciben foco. Las barras de guardar quedan sobre el teclado. Configuración, seguridad y fichas reutilizan las superficies y secciones neumórficas sin duplicar encabezados ni agregar texto decorativo.
- Herramientas del perfil abre un panel desplazable sobre la navegación global: publicación, misión y colaboraciones compatibles para todos; obra, producto o servicio según capacidades, guía y datos profesionales. Moderación mantiene su acceso directo para administradores. El acceso profesional abre esa pestaña del editor.
- Misiones ofrece un acceso rápido a convocatorias compatibles (incluye las abiertas a todos), filtros por respuesta de postulación y tarjetas sin portada decorativa cuando no hay fotografía. El detalle explica la restricción concreta y las condiciones de gestión del organizador.
- Texto ampliado: se ocultan etiquetas de navegación que no caben; permanecen los nombres accesibles y los controles de al menos 48 px.

## Mascota

Es una voz contextual: bienvenida, guía, ayuda, vacío y celebración. No aparece en perfil normal, edición, configuración, loading rutinario ni eliminación. Los assets provisionales deben aprobarse antes de integrarse y se mantendrán reemplazables sin modificar widgets o arquitectura.
