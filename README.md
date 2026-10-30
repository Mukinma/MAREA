# MAREA

SMTP de Gmail está activo y la plantilla publicada de confirmación incluye el código. Consulta el [estado y las pruebas de correo](docs/email-setup.md); la entrega con cuentas nuevas todavía requiere validación real.

Para preparar un equipo desde cero, consulta la [guía de instalación local para Android y Web](docs/instalacion-local.md).

MAREA para Android, Web e iOS, con publicaciones y funciones diferenciadas por perfil. Consulta [Comunidad y misiones](docs/community.md) para los flujos y permisos de esta entrega. La app incluye registro e inicio de sesión con persistencia, perfil social editable, portafolio/catálogo/servicios independientes, cierre de sesión y eliminación completa de cuenta. La interfaz parte del mockup oficial: azul marino, aqua, superficies claras, pasteles, formas suaves y navegación social responsive.

## Stack

La ampliación de bienvenida, consentimiento legal (México, 18+), recuperación, confirmación inicial obligatoria y personalización está documentada en [Acceso y perfil](docs/account-completion.md). Las migraciones y funciones de Supabase están incluidas como código fuente; cada instalación debe usar su propio proyecto y sus propias políticas operativas.

- Flutter 3.44.1 y Dart 3.12.1
- Material 3 personalizado y Nunito Sans local (OFL)
- `go_router` para rutas y guards
- `supabase_flutter` para Auth, PostgreSQL y Edge Functions
- Android Kotlin, application ID `com.marea.app`, `minSdk 24`

Supabase sigue siendo el backend; Firebase Cloud Messaging sólo transporta notificaciones a Android. Ver [configuración de avisos Android](docs/android-push.md). No se requiere Docker, librería externa de estado ni AR. La aplicación usa Supabase Storage privado para avatar, portada y fotografías de contenido. Se retiró la entrada de demostración: `lib/main.dart` es la única aplicación ejecutable y los repositorios falsos se limitan a pruebas automatizadas.

## Estructura importante

```text
lib/
  core/          configuración, errores, sesión, tema, rutas y validación
  features/
    auth/        repositorio y pantallas de autenticación
    profile/     modelo, repositorio y experiencia de perfil
    community/   publicaciones, descubrimiento, misiones y moderación
    showcase/    fichas profesionales, fotografías, guardados y edición
    shell/       navegación adaptativa
  shared/        componentes visuales de MAREA
supabase/
  migrations/001_initial_schema.sql
  migrations/002_account_completion.sql
  migrations/003_community.sql
  migrations/004_post_locations.sql
  migrations/005_mission_management.sql
  migrations/006_profile_experience.sql
  migrations/007_minimal_registration.sql
  migrations/008_recover_minimal_registration.sql
  functions/delete-account/index.ts
test/            unitarias, controlador, guards y widgets
```

El nuevo [acceso y registro guiado](docs/access-redesign.md) requiere la migración 007 y tiene cuatro [referencias de imagegen](output/imagegen/README-access.md).

La migración 008 recupera las elecciones de registros mínimos creados antes de
aplicar la 007, conservando sus datos. Antes de distribuir Web o Android, ejecutar
`node tool/check_backend_contract.mjs` desde la raíz del proyecto: impide distribuir
un cliente contra un esquema desactualizado. Ver [gate de despliegue](tool/README.md).

Los tokens visuales están documentados en [`docs/design-system.md`](docs/design-system.md). Los assets provisionales de mascota permanecen desacoplados hasta su aprobación; logo y estados actuales usan recursos vectoriales propios del código.

## Crear y configurar Supabase

La configuración del backend se realiza con la CLI o desde el panel de
Supabase por la persona responsable del proyecto. Para instalar y ejecutar
MAREA con un proyecto ya preparado no necesitas instalar Supabase CLI; consulta
la [guía de instalación local](docs/instalacion-local.md) y utiliza únicamente
la URL y la clave pública que te proporcione el equipo.

1. Crea un proyecto hospedado en Supabase y ejecuta `supabase login`.
2. Vincula este repositorio:

   ```bash
   supabase link --project-ref TU_PROJECT_REF
   ```

3. Aplica la migración remota:

   ```bash
   supabase db push --linked
   ```

4. Despliega la función sin Docker:

   ```bash
   supabase functions deploy profile-media --use-api
   supabase functions deploy delete-account --use-api
   ```

5. En Authentication > URL Configuration establece:

   - Site URL local: `http://localhost:7357`
   - Redirect URL permitida: `http://localhost:7357/**`

6. Mantén **Confirm Email** activo para el flujo recomendado. Si se desactiva, el registro inicia sesión inmediatamente y carga el perfil creado por el trigger.

Supabase inyecta `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` a la Edge Function. La service-role nunca debe copiarse a Flutter, archivos locales ni Git.

## Ejecutar

Para ejecutar la app, copia `config/supabase.example.json` a un archivo local no versionado y reemplaza sus valores con los de tu propio proyecto. Nunca uses una clave `service_role` o `sb_secret_` en Flutter.

```bash
cp config/supabase.example.json config/supabase.local.json
flutter run -d chrome -t lib/main.dart --web-port 7357 --dart-define-from-file=config/supabase.local.json
```

El botón `Continuar con Google` usa el proveedor OAuth de Supabase. Antes de probarlo,
habilita Google en **Supabase > Authentication > Providers > Google**, configura allí
las credenciales OAuth de Google. En Google Cloud, registra como URI de redirección
autorizada `https://<tu-project-ref>.supabase.co/auth/v1/callback`; en **Supabase >
Authentication > URL Configuration**, agrega `http://localhost:7357` como URL de
redirección permitida. Para producción, agrega también el dominio HTTPS publicado de
la aplicación.

Para Android, selecciona el dispositivo real que aparece en `flutter devices` y usa `-d ID_DEL_DISPOSITIVO` con el mismo archivo. VS Code incluye configuraciones que apuntan a la plantilla de ejemplo; cámbialas a tu archivo local para probar un backend propio.

Para el acceso con Google en Android, agrega `com.marea.app://login-callback` a las
URLs de redirección permitidas en Supabase, en Authentication > URL Configuration.
La aplicación abre el navegador para autenticar y vuelve a la APK mediante ese
enlace.

Para compilar con tu backend local:

```bash
flutter build web -t lib/main.dart --dart-define-from-file=config/supabase.local.json
flutter build apk --debug -t lib/main.dart --dart-define-from-file=config/supabase.local.json
```

Aunque el nombre histórico del define es `SUPABASE_ANON_KEY`, se entrega al argumento actual `publishableKey` del SDK.

Si faltan valores, MAREA muestra una pantalla segura de configuración y no intenta iniciar Supabase.

### Hosting Web sin `#`

La app usa URLs limpias. El hosting debe redirigir rutas desconocidas a `/index.html` con estado 200. Ejemplos equivalentes:

- Netlify: `/* /index.html 200`
- Vercel: rewrite de `/(.*)` a `/index.html`
- Firebase Hosting: rewrite `**` a `/index.html`

Sin este rewrite, actualizar directamente `/profile` o `/settings` producirá un 404 del servidor.

## Verificación local

```bash
dart format .
flutter analyze
flutter test
flutter build web \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=example-public-key
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=example-public-key
```

Las pruebas remotas requieren dos cuentas temporales y deben comprobar:

- cada persona solo puede leer y actualizar su fila privada de perfil; el directorio de comunidad devuelve únicamente campos de presentación;
- un cliente anónimo solo puede consultar disponibilidad de username mediante RPC booleano;
- `id`, `role`, timestamps y tipo confirmado no pueden modificarse directamente; el registro mínimo confirma el tipo en servidor y las cuentas pendientes lo confirman una sola vez; preferencias y avance de guía permanecen privados y editables;
- la Edge Function rechaza peticiones sin JWT;
- eliminar una cuenta borra `auth.users` y el perfil por cascade;
- nombre, username y bio persisten entre Web y Android.

## Decisiones de seguridad

- El perfil se crea desde un trigger `security definer` con `search_path = ''`; el cliente nunca decide el role.
- RLS y grants por columna protegen filas y campos internos.
- La disponibilidad de username usa una función que solo devuelve un booleano.
- Flutter no tiene permiso de `DELETE` sobre `profiles`; la Edge Function obtiene la identidad del JWT y elimina el usuario con la service-role alojada en Supabase.
- Tras eliminar una cuenta, un JWT previamente robado puede conservar validez criptográfica hasta expirar, aunque la sesión ya no puede renovarse.

## Alcance y limitaciones del MVP

Inicio, Explorar, Crear y Misiones utilizan datos persistentes de Supabase. Incluye publicaciones por tipo de perfil, fichas profesionales independientes, fotografías, guardados, búsqueda, perfiles de la comunidad, postulaciones y moderación. Las limitaciones concretas se documentan en [Comunidad y misiones](docs/community.md). El módulo de recorridos 360° y AR se incorpora con la migración 015 y requiere completar el piloto descrito abajo antes de distribuirlo.

## Mapa

Descubrimiento geográfico de misiones con clustering, búsqueda, filtros, ubicación puntual y preview integrada al detalle existente. Requiere la migración 012 antes de distribuir. Consulta [Mapa de misiones](docs/map.md).

## Rediseño de misiones

Creación y edición en cuatro pasos, candidaturas en tres, confirmación, borradores privados, guardados, compensación y gestión propia con finalistas y selección atómica. Requiere la migración 013 y el gate de backend antes de distribuir. Consulta [flujos y contrato](docs/missions-redesign.md).

## Recorridos 360° y AR

Editor desde Crear y perfil profesional, captura esférica guiada Android/iOS o importación GPano, visita por panoramas y conexiones, referencias AR con ancho físico, solicitudes y revisión de espacios. Supabase mantiene originales y borradores privados; Cloud Run Jobs procesa con Hugin/Enblend. Negocios conservan Servicios.

La implementación local, las pruebas ejecutadas y las verificaciones pendientes están en [entrega y piloto](docs/implementation/tours-360-delivery.md). Consultar [diseño y seis láminas](docs/ar-experience-design.md), [canales nativos](docs/implementation/tours-native.md) y [despliegue del procesador](processing/tours/README.md). No se han aplicado migraciones ni desplegado estos servicios en producción; las pruebas físicas de captura y AR siguen pendientes.

Para los recorridos360°, consultar [el piloto Docker + Supabase](docs/implementation/tours-local-pilot-report.md) y [los comandos del procesador local](processing/tours/README.md). Cloud Run espera verificación de facturación; las pruebas físicas de cámara/AR corresponden al propietario del dispositivo.
