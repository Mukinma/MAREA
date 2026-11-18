# Migración Mapbox: implementación y verificación

Fecha: 7 de noviembre de 2026. Base de comparación: `e27f6ae4e3fb2a63f7287bbd486e989745bab216`.

La exploración de misiones, el selector y el visor de ubicaciones utilizan el SDK oficial Mapbox 3.34.2. La lógica de datos de Supabase, las rutas y la geocodificación siguen utilizando sus contratos existentes. La verificación de cartografía real está pendiente de un token público válido. Las tres compilaciones se repitieron correctamente tras la última corrección y la limpieza de dependencias.

## Cambios y finalidad

| Archivos o grupo | Motivo |
|---|---|
| `pubspec.yaml`, `pubspec.lock` | Mapbox y protección de overlays; retiro de flutter_map, clusters anteriores y transitivas sin consumidores. Interfaz oficial del SDK como dependencia de pruebas para comprobar capacidades sin GPU/red. |
| `lib/core/config/mapbox_configuration.dart`, `lib/main.dart` | Token público por define e inicialización compartida/idempotente. |
| `lib/core/maps/` | Adaptador de vista/cámara, Standard, sprites, coordenadas, agrupación acotada, interacciones por plataforma, overlays y modo cenital. |
| `lib/features/map/presentation/mission_map_canvas.dart`, `mission_map_screen.dart` | Integración con las misiones y ubicación reales, cámara asíncrona y conservación de tarjetas, filtros, dock y RA. |
| `lib/features/community/presentation/post_location_picker.dart` | Migración del selector/visor compartido, preservando firmas, búsqueda, precisión y consumidores. |
| `lib/core/config/map_tile_configuration.dart` | Retirado: configuración raster sin consumidores. |
| `android/build.gradle.kts` | Compatibilidad Kotlin limitada al módulo Mapbox con Flutter 3.44/AGP 9 y Kotlin integrado desactivado. |
| `ios/.../swiftpm/Package.resolved` | Resolución nativa de Mapbox mediante Swift Package Manager. |
| `.vscode/launch.json`, `.gitignore`, `config/mapbox.example.json` | Define Mapbox sin sustituir los parámetros Supabase; ejemplo vacío y exclusión del archivo local. |
| Pruebas de mapa/selector y `test/support/fake_map_surface.dart` | Conservar pruebas de producto reemplazando únicamente el límite de renderizado; añadir regresiones geográficas, de ciclo de vida, clusters, configuración y capacidades Web. |
| Probes de mapa/RA, fixtures locales y `tool/ar-local.ps1` | El probe cartográfico inicia Mapbox; el laboratorio RA conserva su aislamiento mediante el renderer de prueba, retirando sus antiguas teselas loopback. |
| `docs/map.md`, `docs/community.md` | Configuración, arquitectura, comportamientos preservados y comandos actualizados. |

## Resultados

Los comandos Flutter se ejecutaron secuencialmente. No se proporcionó `MAPBOX_ACCESS_TOKEN`; las compilaciones se realizaron con el estado de configuración pendiente.

| Comando | Resultado |
|---|---|
| `flutter pub get` | Correcto, incluida la resolución posterior al retiro de dependencias raster. |
| `flutter analyze --no-pub` | Sin incidencias. |
| `flutter test --no-pub test/features/map test/features/community/location_picker_test.dart test/features/tours/business_ar_local_fixture_test.dart` | **54 aprobadas**. |
| `flutter test --no-pub` | **649 aprobadas, 2 omitidas, 17 fallidas**. |
| `flutter build apk --debug --dart-define-from-file=config/supabase.production.json` | Correcto; se corrigió la incompatibilidad Kotlin del módulo Mapbox detectada por la primera compilación. |
| `flutter build web --dart-define-from-file=config/supabase.production.json` | Correcto, incluida comprobación de compatibilidad Wasm. |
| `flutter build ios --no-codesign --dart-define-from-file=config/supabase.production.json` | Correcto; aplicación iOS sin firma, con frameworks Mapbox. |

Las 17 pruebas fallidas pertenecen a `mobile_intro_test.dart` (7), `home_feed_experience_test.dart` (3) y `showcase_flow_test.dart` (7). Se reprodujeron **los mismos 17 casos** en una copia temporal del commit original, antes de esta migración; la comparación se hizo por nombres completos de archivo y caso. No se modificaron esas pantallas para subsanar problemas ajenos al mapa.

### Cobertura comprobada automáticamente

- Búsqueda explícita por zona y umbral del 25 %, fechas/radios/categorías, respuestas obsoletas y conservación de resultados ante error.
- Selección, preview, detalle y RA, refresco al regresar y conservación de cámara en pruebas de widgets.
- Permisos GPS bajo acción explícita, cierre/desmontaje seguro y cancelación del recentrado pendiente al explorar; también en el selector.
- Clusters acotados frente a cadenas de puntos, 300 identidades coincidentes y acceso a miembros.
- Orden longitud/latitud, cruces del antimeridiano, cobertura mundial y descarte de capturas antiguas o desmontadas; la primera búsqueda se conserva cuando idle sustituye la captura inicial.
- Estado local sin token, formatos pequeños, texto ampliado y controles sobre el dock.
- Capacidades de interacción por plataforma: Web no registra `LongTapInteraction`, no implementado en SDK 3.34.2; nativo conserva pulsación larga y Web utiliza hover.
- El selector mantiene coordenadas aproximadas redondeadas antes de consultar geocodificación/persistir.

Los tests de pantallas utilizan el adaptador falso; no certifican renderizado GPU, gestos nativos ni cartografía del proveedor. La prueba de capacidades usa la fachada real del SDK con transporte de plataforma de prueba.

## Comprobaciones de arranque

- Android: `flutter run -d emulator-5554 --no-resident --no-pub -t test/browser/mission_map_probe.dart --dart-define=MAREA_ENV=development` instaló y arrancó correctamente la app de desarrollo con datos locales de QA. Se inspeccionó la pantalla y se abrió la hoja de filtros: mensaje de configuración pendiente, buscador, categorías, radios, fechas y navegación utilizables, sin diálogo de permisos al abrir.
- Chrome: se compiló el mismo probe en una carpeta temporal, se sirvió en localhost y se inspeccionó Google Chrome mediante Computer Use. Se verificaron el mensaje sin token y la apertura de filtros con categorías, radios, fechas y acciones. Estas comprobaciones no validan el lienzo Mapbox, que no se crea sin token.
- iOS: compilación verificada; no se ejecutó una inspección cartográfica en simulador/dispositivo al faltar el token.

## Configuración y validación pendiente

Configurar un token público válido siguiendo `docs/map.md`. El comando habitual mantiene el archivo de Supabase y añade:

```sh
--dart-define=MAPBOX_ACCESS_TOKEN="$MAPBOX_ACCESS_TOKEN"
```

Con ese token todavía deben comprobarse: carga de Standard, personalización efectiva, edificios donde haya cobertura, gestos reales, selección sobre edificios, agrupación proyectada y despliegue, recuperación de conectividad, logo/atribución/telemetría accesibles, y las mismas rutas sobre mapas reales en Android, iOS y Chrome.

No se ha certificado rendimiento en un Android físico de gama media. La prueba de 300 puntos comprueba lógica y conservación de identidades; no constituye una medición de FPS o memoria nativa.

## Riesgos y deuda técnica

- La integración está preparada y compila; **la aceptación visual y cartográfica permanece pendiente del token**.
- El ajuste Kotlin se limita al plugin Mapbox y a la configuración actual. Reevaluarlo al actualizar Flutter y plugins a Kotlin integrado; la compilación actual continúa avisando de plugins que utilizan KGP, incluidos otros ya presentes.
- Los 17 fallos previos de bienvenida, historias y escaparates requieren trabajo independiente si se necesita una suite completamente verde.

## Inventario de archivos

| Archivo | Razón principal |
|---|---|
| `.gitignore` | Excluir el archivo local del token. |
| `.vscode/launch.json` | Añadir el define público conservando configuraciones existentes. |
| `android/build.gradle.kts` | Compatibilidad Kotlin del módulo Mapbox con AGP9. |
| `config/mapbox.example.json` | Ejemplo vacío del define público. |
| `docs/community.md` | Actualizar el proveedor cartográfico del selector. |
| `docs/map.md` | Documentar arquitectura, matriz de migración y configuración. |
| `docs/mapbox-validation.md` | Registrar resultados y límites comprobados. |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | Resolver dependencias nativas Mapbox mediante Swift Package Manager. |
| `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved` | Resolver dependencias nativas Mapbox mediante Swift Package Manager. |
| `lib/core/config/map_tile_configuration.dart` | Retirar configuración raster sin consumidores. |
| `lib/core/config/mapbox_configuration.dart` | Define público e inicialización idempotente. |
| `lib/core/maps/location_map.dart` | Modo cenital compartido por selector y visor. |
| `lib/core/maps/map_clustering.dart` | Agrupación acotada con miembros reales. |
| `lib/core/maps/map_overlay.dart` | Protección de controles sobre el mapa Web. |
| `lib/core/maps/map_surface.dart` | Adaptador y descarte de capturas obsoletas. |
| `lib/core/maps/mapbox_geography.dart` | Orden de coordenadas y normalización de límites. |
| `lib/core/maps/mapbox_interactions.dart` | Selección y tooltips según capacidades de plataforma. |
| `lib/core/maps/mapbox_style.dart` | Standard y sprites reutilizables. |
| `lib/core/maps/mapbox_surface.dart` | Vista nativa, cámara, capas, gestos y recuperación. |
| `lib/features/community/presentation/post_location_picker.dart` | Migrar selector/visor y conservar precisión y servicios. |
| `lib/features/map/presentation/mission_map_canvas.dart` | Adaptar misiones, categorías y posición a Mapbox. |
| `lib/features/map/presentation/mission_map_screen.dart` | Cámara asíncrona, primera búsqueda y overlays existentes. |
| `lib/main.dart` | Inicialización común del SDK al arrancar. |
| `pubspec.lock` | Resolución reproducible y retiro de transitivas obsoletas. |
| `pubspec.yaml` | Dependencias cartográficas y transporte de pruebas. |
| `test/browser/mission_map_probe.dart` | Inicializador del SDK en el probe real. |
| `test/features/community/location_picker_test.dart` | Pruebas del selector mediante adaptador y GPS pendiente. |
| `test/features/map/map_clustering_test.dart` | Cadenas, coincidencias e identidades. |
| `test/features/map/map_surface_controller_test.dart` | Capturas obsoletas, desmontaje y configuración pública. |
| `test/features/map/mapbox_configuration_ui_test.dart` | Estado local sin token. |
| `test/features/map/mapbox_geography_test.dart` | Orden longitud/latitud y antimeridiano. |
| `test/features/map/mapbox_interactions_test.dart` | Compatibilidad Web y selección nativa mediante fachada SDK. |
| `test/features/map/mission_map_ui_test.dart` | Regresión de pantalla, navegación y carrera de primera búsqueda. |
| `test/manual/business_ar_probe.dart` | Mantener el laboratorio estrictamente local. |
| `test/support/business_ar_fixture.dart` | Retirar endpoint local de teselas obsoleto. |
| `test/support/business_ar_reference.dart` | Retirar generación de teselas obsoleta. |
| `test/support/fake_map_surface.dart` | Renderer determinista para widgets y QA local. |
| `tool/ar-local.ps1` | Retirar define de teselas del laboratorio. |
