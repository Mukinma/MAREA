# Herramientas y ejecución local

La entrada de demostración `ui_preview.dart` fue retirada. La aplicación se ejecuta exclusivamente desde `lib/main.dart`. Los fakes de cuentas solo viven en las pruebas automatizadas.

```sh
flutter run -d chrome -t lib/main.dart --web-port 7357 --dart-define-from-file=config/supabase.local.json
```

El archivo local debe contener únicamente la URL y la clave publicable de tu proyecto. Nunca agregar claves `service_role`, `sb_secret` ni contraseñas. No se deben versionar archivos locales de configuración.

`check_database.mjs` valida migraciones en un PostgreSQL aislado para pruebas, sin modificar Supabase. Las pruebas de layout están en `test/features/presentation/responsive_test.dart`.

## Gate de despliegue

Antes de distribuir cada build, ejecutar en orden:

```sh
supabase migration list --linked
supabase db push --linked --dry-run
supabase db push --linked
node tool/check_backend_contract.mjs
flutter build web -t lib/main.dart --dart-define-from-file=config/supabase.production.json
flutter build apk --debug -t lib/main.dart --dart-define-from-file=config/supabase.production.json
```

El gate consulta el historial 001–014, la columna/grants de `setup_step`, las
preferencias editables y los contratos de registro, confirmación, experiencia social y push Android.
Comprueba tablas, RLS, grants, RPC, triggers y publicación Realtime de notificaciones. Si falla, no
distribuir el build. No consulta datos de cuentas ni modifica el proyecto remoto.
La 008 recupera una sola vez elecciones guardadas por el cliente mínimo antes de
aplicar la 007; conserva los datos y no toca cuentas ya confirmadas, en eliminación
o con presentación incompatible. Los pendientes restantes confirman el tipo una vez.

`check_registration_recovery.mjs` verifica esa actualización y su idempotencia en
PostgreSQL aislado; usa `MAREA_PGLITE_MODULE` igual que las otras pruebas SQL.

Para verificar persistencia real, `node tool/check_live_account_flow.mjs --run`
crea cinco cuentas temporales con correo ya confirmado y dirección `.invalid`;
prueba JWT de usuario, guía, avatar/portada, posts con imágenes y aislamiento, y
elimina exclusivamente esas cuentas y sus archivos. Requiere la CLI administrativa
autenticada; las claves se mantienen en memoria. No envía correos ni valida la
entrega/verificación por SMTP. Sin `--run`, solo muestra instrucciones.

Las regresiones de formato y rechazo del gate se ejecutan con
`node --test test/tool/backend_contract_test.mjs`.

## Experiencia social v7

`APP_PUBLIC_URL` configura el dominio de los enlaces compartidos. Su valor por
omisión es `https://marea-azul.netlify.app/`; los enlaces usan `/posts/{id}`.
Puede añadirse al archivo de defines o pasarse mediante `--dart-define`.
Las credenciales administrativas nunca forman parte del build Flutter.

Las migraciones 009–011 agregan reacciones, notificaciones, comentarios e intereses
privados. Aplicarlas y pasar el gate antes de distribuir el cliente. La lectura de
posts requiere sesión; Netlify conserva el rewrite a `index.html`.

```sh
node tool/check_social_database.mjs
node --test test/tool/backend_contract_test.mjs
flutter analyze
flutter test
```

Las pruebas SQL usan `MAREA_PGLITE_MODULE` para resolver la instalación local de
PGlite, igual que las herramientas históricas. Son aisladas y no modifican Supabase.

`node tool/check_live_social_flow.mjs --run` crea tres cuentas temporales confirmadas
con correos `.invalid`; verifica persistencia, privacidad, concurrencia, notificaciones,
Realtime y cascadas, y elimina exclusivamente sus datos. Requiere la CLI administrativa
autenticada. Guarda un journal privado de sus IDs en `/tmp` para recuperar limpieza si
el proceso se interrumpe. Sin `--run` no modifica datos.

Ejecutar builds web, Android e iOS **secuencialmente**: Flutter comparte archivos
intermedios. Para comprobar iOS sin distribución: `flutter build ios --no-codesign
--dart-define-from-file=config/supabase.production.json`.

En Android, el acceso con Google requiere registrar
`com.marea.app://login-callback` en las URLs de redirección permitidas de Supabase.

## Mapa de misiones

La migración 012 añade el RPC geográfico y su índice; el gate comprueba ambos y sus permisos. `check_map_database.mjs` valida filtros, visibilidad, radio, antimeridiano y límite de resultados en PostgreSQL aislado. Si la conexión directa por IPv6 no está disponible, `supabase db query --linked` permite inspeccionar el contrato mediante la API de administración; aplicar cambios y su registro de migración en una sola transacción. Ver [Mapa](../docs/map.md).

## Rediseño de misiones

check_missions_redesign_database.mjs verifica privacidad, borradores, compensación, muestras, finalistas, selección y avisos en PostgreSQL aislado. check_live_missions_flow.mjs --run prueba persistencia y concurrencia con usuarios temporales propios y limpieza final en el proyecto conectado. Véase [misiones](../docs/missions-redesign.md).

## Interacciones y avisos Android

Reacciones con toque/mantener/deslizar, paneles coordinados y esqueletos están incluidos. La migración 014 y la función `send-push` preparan FCM sin reemplazar Supabase. La activación externa, cron, Vault, credenciales y pruebas en celular se describen en [notificaciones Android](../docs/android-push.md). Mantener la bandera de envíos desactivada hasta completar esas verificaciones.

Recorridos360: `check_tours_database.mjs` comprueba permisos/RLS, snapshots, cola,
leases, GC, aprobación de alcance, progress y límites de reintentos en PostgreSQL
local. `check_tours_migrations.mjs` aplica001–015 y ejecuta los17 flags reales del
release gate. Usan `MAREA_PGLITE_MODULE` igual que el resto de pruebas; nunca
contactan producción. Worker, configuración y límites de validación real están
explicados en `processing/tours/README.md`.

## Inicio e historias

Las migraciones 016–019 incorporan feed combinado, seguimiento privado, historias
y recibos de publicación que sobreviven a la limpieza. Ejecutar
`node tool/check_home_feed_contract.mjs` además del gate existente antes de distribuir.
`check_home_feed_database.mjs` valida el contrato en PostgreSQL aislado usando
`MAREA_PGLITE_MODULE`. `check_live_home_feed.mjs --run` verifica Supabase con cuentas
temporales `.invalid`, limpia sus recursos y conserva solo un journal de IDs si
la limpieza necesita recuperación. Sin `--run` no modifica datos.

La limpieza horaria y su configuración están documentadas en
`supabase/functions/story-cleanup/README.md`; el progreso y la verificación final,
en `docs/implementation/home-feed-redesign-progress.md`.

## Corrección del feed, ciudades y acciones de misiones

Las migraciones020–021 incorporan conversación/reacciones de misiones y ciudad
persistida. Después de validar las migraciones, desplegar la función `geocoding`
y ejecutar `node tool/check_feed_correction_contract.mjs`. El contrato comprueba
RLS, permisos de RPC, escrituras privadas y campos de ciudad.

`check_mission_social_database.mjs`, `check_location_full_database.mjs` y
`check_location_city_provenance.mjs` usan PostgreSQL aislado mediante
`MAREA_PGLITE_MODULE`. El segundo aplica020+021 junto con el esquema anterior.
`node --test supabase/functions/geocoding/*test.mjs` verifica parser, caché,
respuestas atrasadas y presupuesto del lease global. La configuración del
proveedor permanece privada en `geocoding_provider`; el cliente usa Supabase
y muestra «Ver ubicación» cuando falta ciudad, conservando las coordenadas.

`node tool/check_live_feed_correction.mjs --run` es una comprobación voluntaria
del proyecto conectado: crea tres usuarios `.invalid`, verifica ocho reintentos
simultáneos del mismo comentario, permisos, notificaciones, ranking y cascadas,
y elimina sus recursos al terminar. Nunca imprimir claves. Si la limpieza
falla conserva un journal de IDs con permisos0600 para recuperación.

El registro de entrega está en `docs/implementation/feed-correction-progress.md`.
