# Sistema visual de MAREA — MVP

Este sistema traduce el mockup oficial a componentes Flutter. El mockup manda sobre cualquier referencia secundaria.

## Personalidad

Social, creativa, cercana, tecnológica, joven, amigable y expresiva. La interfaz evita el lenguaje de ficha CRUD, las sombras pesadas, el dark-first y una estética corporativa o nightlife.

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
- Bordes ligeros, superficies claras y movimiento funcional de 150–300 ms.

## Componentes

- **Botón principal:** azul, texto blanco, radio 16, loading integrado.
- **Input:** superficie Paper, contorno neutro discreto, foco azul, error traducido.
- **Card:** superficie blanca sobre Paper, sin borde en perfil y vacíos; sin elevación pesada.
- **Chip:** pastel contextual con texto navy; no actúa como CTA.
- **Navegación:** cinco destinos; `+` central circular en móvil, rail de 88 px en tablet y lateral de al menos 260 px en desktop. Etiquetas desktop de 18 px, peso 600/800, iconos de 27 px y selección menta. Crear conserva un círculo azul de 48 px también en desktop.
- **Perfil:** portada abstracta pastel con un trazo aqua, avatar superpuesto sin sombra, nombre de 28/34 px, username, tipo y bio. Editar queda junto al avatar en ancho amplio y debajo de la bio en móvil. Correo queda en Configuración; UUID y role no se muestran.
- **Autenticación:** panel de marca cálido separado del formulario; título y composición de mundos creativos en desktop. En móvil se priorizan logo y formulario para no alargar el acceso. No hay tarjetas de contenido ficticio ni acciones decorativas.

`CreativeArtwork` y `MareaCover` son ilustraciones vectoriales de interfaz, excluidas de la semántica accesible. No sustituyen ni rediseñan el logo o la mascota, no son contenido personalizable y no añaden nuevas funciones.

## Responsive

- Mobile: `<600 px`, navegación inferior.
- Tablet: `600–1023 px`, rail compacto.
- Desktop: `>=1024 px`, rail extendido; autenticación en composición dividida.
- El contenido social del perfil se limita aproximadamente a 960 px.

## Mascota

Es una voz contextual: bienvenida, guía, ayuda, vacío y celebración. No aparece en perfil normal, edición, configuración, loading rutinario ni eliminación. Los assets provisionales deben aprobarse antes de integrarse y se mantendrán reemplazables sin modificar widgets o arquitectura.
