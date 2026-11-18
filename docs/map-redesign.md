# Rediseño del mapa de misiones

La cabecera anterior usaba una marca adicional, un gradiente y una fila extensa de categorías. El aviso de zona y el estado de los resultados estaban en dos lugares. El rediseño deja espacio para la ciudad con un buscador compacto, dos accesos rápidos, controles de cámara agrupados y un panel inferior que pasa de resultados a misión seleccionada.

| Cambio | Archivos principales |
|---|---|
| Búsqueda «Buscar misiones», contador de filtros, accesos a Categorías y Hoy y acciones de filtro fijas | `map_search_bar.dart`, `map_filter_sheet.dart` |
| Estado de resultados y preview en el mismo panel, área de enfoque medida y espacio para el teclado | `mission_map_screen.dart`, `mission_map_preview.dart` |
| Inicio en 3D, selector de perspectiva, brújula contextual y ubicación puntual | `map_camera_controls.dart`, `mission_map_canvas.dart`, `map_surface.dart`, `mapbox_surface.dart` |
| Colores, etiquetas y volumen de Standard para exploración | `mapbox_style.dart` |
| Pruebas de cámara, búsquedas, layout y navegación con renderer falso | `map_camera_experience_test.dart`, `mission_map_ui_test.dart`, `fake_map_surface.dart` |

Las consultas conservan el RPC, el umbral del 25 % y el máximo de 300 resultados. Cada consulta explícita espera la captura de su viewport. Los cambios de presentación actualizan el control de cámara sin cambiar la zona de resultados. La preview mantiene los datos y acciones de la misión. La entrada a RA sigue sujeta a la disponibilidad de una referencia publicada y probada. El selector y el visor de ubicación conservan el preset cenital.

La verificación en Android reveló dos diferencias entre el renderer falso y el SDK. Se aplica la cámara inicial al cargar el primer estilo para abrir en CDMX a 45° cuando no hay coordenadas de perfil ni GPS. Los símbolos conservan su dibujo en Mapbox y tienen objetivos táctiles Flutter alineados con la proyección nativa. La cancelación por gesto se limita a animaciones iniciadas por MAREA para que el zoom nativo continúe.

## Evidencia de Android

Las capturas se tomaron en `emulator-5554` con cartografía real. Para las capturas con misiones se usó el laboratorio local `test/browser/mission_map_probe.dart`. Las misiones de ese laboratorio son datos de prueba y la cartografía y los monumentos son de Mapbox. En la aplicación con los tres archivos de configuración se comprobaron la entrada, la vista vacía, el desplazamiento y los filtros.

| Estado | Captura |
|---|---|
| Entrada con GPS y estado vacío en la app Android | [Abrir captura](../output/map-redesign/00-android.png) |
| Entrada en 3D sin GPS, centro de CDMX | [Abrir captura](../output/map-redesign/01-3d-cdmx.png) |
| Vista 2D | [Abrir captura](../output/map-redesign/02-2d.png) |
| 3D girado, brújula contextual y volumen de monumentos | [Abrir captura](../output/map-redesign/03-rotated.png) |
| Zona desplazada, actualización explícita integrada | [Abrir captura](../output/map-redesign/04-zone.png) |
| Hoja de filtros | [Abrir captura](../output/map-redesign/05-filters.png) |
| Categoría, fecha y radio aplicados con contador | [Abrir captura](../output/map-redesign/06-applied.png) |
| Despliegue de tres misiones coincidentes | [Abrir captura](../output/map-redesign/07-cluster.png) |
| Misión seleccionada y acción «Ver misión» | [Abrir captura](../output/map-redesign/08-selected.png) |
| Detalle y regreso con selección y perspectiva | [Detalle](../output/map-redesign/09-detail.png) · [Regreso](../output/map-redesign/10-return.png) |

La auditoría previa alcanzó a inspeccionar el mapa anterior y un desplazamiento en Android. El emulador se desconectó antes de completar filtros, selección y regreso. La captura temporal previa no sobrevivió al reinicio de la sesión, por lo que falta una comparación completa antes y después a idéntico centro y zoom. Algunas capturas del emulador omitieron texto de Flutter de forma intermitente. El árbol de accesibilidad conservaba esos controles y se descartaron las capturas incompletas para la tabla. Se comprobó que la vista 2D y la 3D conservaran el centro, el zoom y la selección. También se abrió el menú nativo de atribución y se comprobó que incluyera el control de telemetría.

## Comprobaciones

| Comprobación | Resultado |
|---|---|
| `flutter analyze --no-pub` | Sin avisos ni errores. |
| Compilación y ejecución Android | Aprobadas en `emulator-5554` con `config/supabase.production.json`, `config/firebase.android.json` y `config/mapbox.local.json`. |
| Compilación Web | Aprobada en `build/web`. Flutter informó un aviso de fuentes Cupertino. |
| Compilación iOS `--no-codesign` | Aprobada en `build/ios/iphoneos/Runner.app`. |
| Mapa, selector y laboratorio de RA | 61 pruebas aprobadas. Incluyen 320, 390, 800 y 1366 px, texto ampliado, teclado, cámara y consultas fuera de orden. |
| Suite completa | 656 aprobadas, 2 omitidas y 17 fallos ya reproducidos en la línea base. Los fallos corresponden a `mobile_intro_test.dart` (7), `home_feed_experience_test.dart` (3) y `showcase_flow_test.dart` (7). |

La interacción de RA se verificó mediante pruebas automatizadas. Quedan por comprobar el aspecto en Web e iOS y el rendimiento en un dispositivo Android de gama media. Las capturas y la interacción del emulador no miden ese rendimiento.
