# Mapa de misiones

Mapa reutiliza la navegación global, Mission, las fotografías privadas y el detalle `/missions/:id`. La producción consulta exclusivamente Supabase; los datos de ejemplo se limitan a pruebas y al arnés `test/browser/mission_map_probe.dart`.

## Experiencia

OpenStreetMap ocupa el área disponible. En móvil se oculta el encabezado del shell solo en `/map`; la navegación inferior y Crear permanecen. La búsqueda enviada consulta título, lugar, categoría y organizador dentro del viewport. Los chips Todo/Hoy y la hoja de filtros comparten un mismo estado. Todo limpia la categoría; Limpiar filtros restablece categoría, fecha y radio, conservando el texto de búsqueda.

Las misiones visibles son abiertas, futuras, no ocultas, con coordenadas válidas y cupo. Incluye todos los perfiles; el detalle mantiene las restricciones de participación. Fotografía, Diseño y Otros forman parte del catálogo existente. Los clusters cuentan sus miembros reales y permiten desplegar puntos coincidentes.

La selección abre una preview con categoría, título, organizador, lugar, fecha, fotografía opcional y Ver misión. La distancia aparece solo con una posición obtenida del dispositivo y es aproximada, sin estimar rutas ni tiempos. Tocar el mapa, cerrar o deslizar hacia abajo cierra la tarjeta. Volver del detalle conserva cámara/filtros y actualiza disponibilidad para retirar misiones que dejaron de estar disponibles.

Tras terminar un desplazamiento, Buscar en esta zona aparece si el centro o la extensión cambia un 25% respecto de la zona consultada. El gesto nunca dispara una consulta. Búsqueda, filtros y centrar ubicación sí consultan la nueva zona. Las respuestas antiguas se descartan; un fallo conserva resultados y ofrece reintento.

## Ubicación

DeviceLocationService extrae la lógica del selector existente. Al abrir Mapa se comprueba permiso y se obtiene una posición solo si ya está concedido. El botón de ubicación puede solicitarlo. Rechazo, rechazo permanente, servicio desactivado y timeout permiten seguir explorando. No hay stream GPS, seguimiento ni permisos de ubicación en segundo plano. Una interacción manual cancela el movimiento de cámara, incluso si la posición solicitada aún no ha llegado; la posición puede actualizar el indicador sin interrumpir la exploración.

Sin posición, se usan coordenadas válidas del perfil o el centro de CDMX del proyecto. Esa posición del perfil no se presenta como posición actual. Fechas: medianoche local a medianoche del día siguiente; próximos siete días incluye hoy y seis días más. Se envían los límites en UTC. El radio de 1/3/5/10 km se calcula alrededor del centro de la zona consultada.

## Contrato de backend

La migración `012_mission_map.sql` añade un índice parcial y `list_map_missions(south, west, north, east, query_text, category_filter, starts_from, starts_before, center_latitude, center_longitude, radius_km)`. No añade campos ni cambia los RPC de misiones existentes.

Devuelve `{missions: [...], total: N}` con un máximo de 300 filas, ordenadas por fecha e ID. La cápsula explica el recorte y pide acercar el mapa. Los límites oeste > este representan un área que cruza el antimeridiano. Las coordenadas aproximadas se utilizan como ya están guardadas; no se aumenta su precisión ni se geocodifican direcciones antiguas. Se excluyen autores en eliminación, y solo se exponen nombre/username del organizador, sin estadísticas privadas de postulaciones.

El RPC exige cuenta activa y permiso authenticated; anon no puede ejecutarlo. El gate de distribución comprueba migraciones 001–012, RPC e índice. Aplicar la migración antes de distribuir un cliente nuevo; clientes anteriores siguen funcionando. El frontend no se publica automáticamente por este cambio.

## Cartografía

Los defines MAP_TILE_URL, MAP_ATTRIBUTION y MAP_ATTRIBUTION_URL permiten cambiar el proveedor sin cambiar widgets. Por defecto: teselas raster HTTPS de OpenStreetMap, atribución visible y user-agent com.marea.app. flutter_map 8.3.2 mantiene la caché HTTP de teselas y evita peticiones obsoletas. No se ofrecen descargas ni precargas de ciudades. OSM es un servicio comunitario sin SLA; revisar su [política de uso](https://operations.osmfoundation.org/policies/tiles/) antes de escalar. No se incorpora un servicio externo de direcciones a la búsqueda de Mapa.

## Verificación

```sh
flutter analyze
flutter test
MAREA_PGLITE_MODULE=/ruta/a/pglite/dist/index.js node tool/check_map_database.mjs
node --test test/tool/backend_contract_test.mjs
node tool/check_backend_contract.mjs
flutter build web --dart-define-from-file=config/supabase.production.json
flutter build apk --debug --dart-define-from-file=config/supabase.production.json
flutter build ios --no-codesign --dart-define-from-file=config/supabase.production.json
```

Ejecutar comandos Flutter secuencialmente. Para QA de interfaz sin cuentas remotas: `flutter run -d web-server -t test/browser/mission_map_probe.dart --web-port 7377`. El arnés está limitado a pruebas, usa datos sintéticos y nunca modifica Supabase. Verificar permisos y exactitud de GPS en dispositivos reales antes de distribución.
