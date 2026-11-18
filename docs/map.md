# Mapa de misiones

Mapa reutiliza la navegación global, Mission, las fotografías privadas y el detalle `/missions/:id`. La producción consulta exclusivamente Supabase; los datos de ejemplo se limitan a pruebas y al arnés `test/browser/mission_map_probe.dart`.

## Experiencia

El mapa abre en 3D con inclinación de 45° y orientación norte. Los botones 2D y 3D cambian solo la inclinación, y 3D recupera la última inclinación utilizada. La brújula aparece cuando la cámara está girada y permite volver al norte. Los controles y el panel inferior se colocan según el espacio que ocupan en cada tamaño de pantalla.

El buscador «Buscar misiones» consulta título, lugar, categoría y organizador dentro del área visible. «Filtros» muestra cuántos filtros están activos. Los accesos «Categorías» y «Hoy» comparten el estado de la hoja. El radio aparece cuando está activo. «Aplicar» y «Limpiar» permanecen accesibles mientras se desplazan los campos. En móvil el mapa ocupa el área sobre el dock global.

Las misiones visibles son abiertas, futuras, no ocultas, con coordenadas válidas y cupo. Incluye todos los perfiles; el detalle mantiene las restricciones de participación. Fotografía, Diseño y Otros forman parte del catálogo existente. Los clusters cuentan sus miembros reales y permiten desplegar puntos coincidentes.

La selección abre una preview con categoría, título, organizador, lugar, fecha, fotografía opcional y Ver misión. La distancia aparece solo con una posición obtenida del dispositivo y es aproximada, sin estimar rutas ni tiempos. Tocar el mapa, cerrar o deslizar hacia abajo cierra la tarjeta. Volver del detalle conserva cámara/filtros y actualiza disponibilidad para retirar misiones que dejaron de estar disponibles.

Tras un desplazamiento o zoom significativo, el panel inferior integra «Buscar en esta zona» con el recuento o la misión seleccionada. El umbral es del 25 % respecto de la zona consultada. Cambiar perspectiva, recuperar el norte y enfocar una selección preservan el estado de búsqueda. Búsqueda, filtros y centrado por ubicación capturan los límites vigentes antes de consultar. Los puntos permanecen mientras se actualiza la búsqueda y ante errores de datos.

## Ubicación

DeviceLocationService extrae la lógica del selector existente. Al abrir Mapa se comprueba permiso y se obtiene una posición solo si ya está concedido. El botón de ubicación puede solicitarlo. Rechazo, rechazo permanente, servicio desactivado y timeout permiten seguir explorando. No hay stream GPS, seguimiento ni permisos de ubicación en segundo plano. Una interacción manual cancela el movimiento de cámara, incluso si la posición solicitada aún no ha llegado; la posición puede actualizar el indicador sin interrumpir la exploración.

Sin posición, se usan coordenadas válidas del perfil o el centro de CDMX del proyecto. Esa posición del perfil no se presenta como posición actual. Fechas: medianoche local a medianoche del día siguiente; próximos siete días incluye hoy y seis días más. Se envían los límites en UTC. El radio de 1/3/5/10 km se calcula alrededor del centro de la zona consultada.

## Contrato de backend

La migración `012_mission_map.sql` añade un índice parcial y `list_map_missions(south, west, north, east, query_text, category_filter, starts_from, starts_before, center_latitude, center_longitude, radius_km)`. No añade campos ni cambia los RPC de misiones existentes.

Devuelve `{missions: [...], total: N}` con un máximo de 300 filas, ordenadas por fecha e ID. El panel inferior explica el recorte y pide acercar el mapa. Los límites oeste > este representan un área que cruza el antimeridiano. Las coordenadas aproximadas se utilizan como ya están guardadas; no se aumenta su precisión ni se geocodifican direcciones antiguas. Se excluyen autores en eliminación, y solo se exponen nombre/username del organizador, sin estadísticas privadas de postulaciones.

El RPC exige cuenta activa y permiso authenticated; anon no puede ejecutarlo. El gate de distribución comprueba migraciones 001–012, RPC e índice. Aplicar la migración antes de distribuir un cliente nuevo; clientes anteriores siguen funcionando. El frontend no se publica automáticamente por este cambio.

## Cartografía: Mapbox 3D

Se utiliza `mapbox_maps_flutter` **3.34.2**, oficial, con renderizado nativo en Android/iOS y Mapbox GL JS a través de la implementación web oficial. Android conserva minSdk24 e iOS15 con Swift Package Manager. Los colores globales de MAREA no cambian.

Exploración usa Standard `default` con iluminación `day`, agua `#38AFC2`, vegetación `#5B9B68`, suelo `#F1F4EE`, calles blancas y vías principales cálidas. Standard coloca las etiquetas y dibuja edificios y monumentos 3D donde tiene cobertura. Árboles y fachadas detalladas están desactivados. El adaptador aplica las opciones presentes en el esquema del estilo importado. El selector y el visor conservan su estilo `faded` y su cámara cenital. [Configuración de Mapbox Standard](https://docs.mapbox.com/map-styles/guides/standard-styles/).

### Configuración

Copia `config/mapbox.example.json` a `config/mapbox.local.json` y pon el token **público** de Mapbox (`pk.`) en `MAPBOX_ACCESS_TOKEN`. El archivo local está ignorado por Git. Para Android con notificaciones push, incorpora también `config/firebase.android.json` junto con la configuración de Supabase.

```sh
flutter run -d emulator-5554 -t lib/main.dart \
  --dart-define-from-file=config/supabase.production.json \
  --dart-define-from-file=config/firebase.android.json \
  --dart-define-from-file=config/mapbox.local.json
```

Puedes usar también `--dart-define=MAPBOX_ACCESS_TOKEN="$MAPBOX_ACCESS_TOKEN"` si el token ya está exportado en tu shell. Los perfiles de VS Code leen `${env:MAPBOX_ACCESS_TOKEN}`.

El inicializador común se utiliza antes de crear cualquier mapa y en el probe cartográfico. Si falta el token, el mapa muestra un estado de configuración pendiente y los demás flujos siguen disponibles. Un token con prefijo correcto todavía puede ser inválido/revocado: esos errores se presentan con reintento. No se necesitan tokens privados de descarga para esta versión.

Logo, atribución y control nativo de privacidad/telemetría se mantienen visibles. La atribución OSM que forma parte del mapa de Mapbox sigue siendo legítima; no equivale a usar el renderizador anterior.

### Superficies y responsabilidades

| Componente | Responsabilidad |
|---|---|
| `core/config/mapbox_configuration.dart`, `main.dart` | Define público e inicialización idempotente. |
| `core/maps/map_surface.dart` | Contrato del renderer/controlador, viewport asíncrono y descarte de capturas obsoletas. |
| `core/maps/mapbox_surface.dart` | Vista nativa, eventos, cámara, selección, reintento y recursos del SDK. |
| `core/maps/mapbox_style.dart`, `mapbox_geography.dart` | Standard, sprites cacheados y conversión longitud/latitud/antimeridiano. |
| `core/maps/map_clustering.dart` | Grupos deterministas dentro de 48 px del ancla; no se unen cadenas transitivas. |
| `core/maps/location_map.dart`, `map_overlay.dart` | Modo cenital de ubicación y protección de controles sobre vistas web. |
| `features/map/presentation/mission_map_canvas.dart`, `mission_map_screen.dart` | Adaptación de misiones, ubicación y recorridos al renderer, conservando overlays y navegación. |
| `features/community/presentation/post_location_picker.dart` | Selector/visor comunes a perfiles, feed, publicaciones, misiones y recorridos. |
| `test/support/fake_map_surface.dart` | Límite de renderizado para pruebas de widgets y laboratorio RA estrictamente local. |

### Comportamientos preservados

| Antes | Ahora |
|---|---|
| RPC autenticado, filtros de fecha/categoría/radio, búsqueda enviada y máximo 300 | Mismo repositorio, modelos, parámetros y restricciones. |
| Pan sin consultar; «Buscar en esta zona» al superar 25 % | Se conserva; cada búsqueda espera una captura vigente. |
| Marcador por categoría, selección y preview | Símbolos nativos con IDs reales en propiedades GeoJSON; misma tarjeta y acciones. |
| Clusters con conteo real y puntos coincidentes | Agrupación Dart común a las tres plataformas; zoom progresivo o despliegue de miembros. Si no caben, hoja desplazable para acceder a todos. |
| Entrada RA y detalle de misión | Se mantienen las mismas rutas, reglas y refresco al regresar. |
| GPS puntual, permisos solo bajo acción explícita | Mismo servicio; indicador solo para posición real; gestos cancelan recentrado pendiente. |
| Selección exacta/aproximada, búsqueda y geocodificación | Mismo contrato público y backend; aproximación y consultas inversas conservan redondeo a dos decimales. |
| Encabezado con marca, gradiente y fila de categorías | Buscador compacto, accesos rápidos y panel inferior único sobre el dock. |

El agrupamiento nativo y las anotaciones no se usan porque la implementación web aún no ofrece paridad completa en esas APIs. La selección usa interacciones por capa; las pulsaciones largas se registran solo en plataformas nativas porque Web no las implementa. Los tooltips web se muestran por hover. Los puntos se proyectan por lotes al finalizar movimientos y se dibujan en capas Mapbox; nunca se reconstruye el mapa al cambiar filtros/selección. Se descartan proyecciones antiguas, se reutilizan sprites y se evita reenviar la misma fuente, impidiendo ciclos de renderizado por eventos `idle`.

Abrir/cerrar una tarjeta no consulta ni cambia por sí solo la zona de búsqueda. El enfoque desplaza lo mínimo necesario para mostrar el punto en el espacio útil. La orientación e inclinación se conservan. En el selector, explorar mientras GPS está pendiente también cancela su recentrado sin dejar el estado de carga bloqueado. Tocar fondo, cerrar o deslizar hacia abajo sigue cerrando la preview.

Los entrypoints de QA usan datos sintéticos únicamente en `test/`. El laboratorio RA local conserva su aislamiento de red mediante el renderer de pruebas y ya no necesita teselas loopback. El probe `test/browser/mission_map_probe.dart` utiliza el mapa real y requiere el define público para visualizar cartografía.

## Verificación

Ejecutar Flutter secuencialmente:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/supabase.production.json --dart-define-from-file=config/firebase.android.json --dart-define-from-file=config/mapbox.local.json
flutter build web --dart-define-from-file=config/supabase.production.json --dart-define=MAPBOX_ACCESS_TOKEN="$MAPBOX_ACCESS_TOKEN"
flutter build ios --no-codesign --dart-define-from-file=config/supabase.production.json --dart-define=MAPBOX_ACCESS_TOKEN="$MAPBOX_ACCESS_TOKEN"
flutter run -d web-server -t test/browser/mission_map_probe.dart --web-port=7377 --dart-define=MAPBOX_ACCESS_TOKEN="$MAPBOX_ACCESS_TOKEN"
```

Para QA real, comprobar Android, Chrome e iOS: carga, edificios en zona con cobertura, rotación/inclinación/pan/zoom, cancelación de GPS, filtros y búsqueda explícita, clusters/coincidencias, preview/detalle/RA, regreso, selector exacto/aproximado, pérdida de red/reintento y atribución accesible con texto grande. Probar 300 puntos. Las mediciones de emulador no certifican rendimiento en Android de gama media.

Sin token se pueden verificar compilaciones, lógica y el estado de configuración pendiente; **no se consideran validados la cartografía, los edificios 3D, el rendimiento nativo ni sus interacciones visuales**. Consulta [la migración a Mapbox](mapbox-validation.md) y [la verificación del rediseño](map-redesign.md).

### Compatibilidad Android

Flutter 3.44 mantiene `android.builtInKotlin=false` con AGP 9. El plugin Mapbox 3.34.2 comprueba únicamente la versión de AGP y omite aplicar Kotlin en ese caso. `android/build.gradle.kts` aplica el plugin Kotlin ya disponible solo a ese módulo y solo cuando Kotlin integrado está desactivado. No requiere editar la caché de paquetes ni cambiar globalmente Flutter. Al actualizar Flutter y los plugins, reevaluar este ajuste junto con la migración oficial a Kotlin integrado.
