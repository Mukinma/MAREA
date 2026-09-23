# MAREA

Configuración pendiente para recibir códigos reales: [guía breve de correo SMTP](docs/email-setup.md). Las plantillas locales aún no están publicadas; los cambios de UI no sustituyen este paso.

MAREA para Android, Web e iOS, con publicaciones y funciones diferenciadas por perfil. Consulta [Comunidad y misiones](docs/community.md) para los flujos y permisos de esta entrega. La app incluye registro e inicio de sesión con persistencia, perfil social editable, cierre de sesión y eliminación completa de cuenta. La interfaz parte del mockup oficial: azul marino, aqua, superficies claras, pasteles, formas suaves y navegación social responsive.

## Stack

La ampliación de bienvenida, consentimiento legal (México, 18+), recuperación, guía opcional y personalización está documentada en [Acceso y perfil](docs/account-completion.md). Las migraciones y funciones de Supabase están incluidas como código fuente; cada instalación debe usar su propio proyecto y sus propias políticas operativas.

- Flutter 3.44.1 y Dart 3.12.1
- Material 3 personalizado y Nunito Sans local (OFL)
- `go_router` para rutas y guards
- `supabase_flutter` para Auth, PostgreSQL y Edge Functions
- Android Kotlin, application ID `com.marea.app`, `minSdk 24`

No hay backend adicional, Docker, librería externa de estado ni AR. La aplicación usa Supabase Storage privado para avatar y portada. Se retiró la entrada de demostración: `lib/main.dart` es la única aplicación ejecutable y los repositorios falsos se limitan a pruebas automatizadas.

## Estructura importante

```text
lib/
  core/          configuración, errores, sesión, tema, rutas y validación
  features/
    auth/        repositorio y pantallas de autenticación
    profile/     modelo, repositorio y experiencia de perfil
    community/   publicaciones, descubrimiento, misiones y moderación
    shell/       navegación adaptativa
  shared/        componentes visuales de MAREA
supabase/
  migrations/001_initial_schema.sql
  migrations/002_account_completion.sql
  migrations/003_community.sql
  functions/delete-account/index.ts
test/            unitarias, controlador, guards y widgets
```

Los tokens visuales están documentados en [`docs/design-system.md`](docs/design-system.md). Los assets provisionales de mascota permanecen desacoplados hasta su aprobación; logo y estados actuales usan recursos vectoriales propios del código.

## Crear y configurar Supabase

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

Para Android, selecciona el dispositivo real que aparece en `flutter devices` y usa `-d ID_DEL_DISPOSITIVO` con el mismo archivo. VS Code incluye configuraciones que apuntan a la plantilla de ejemplo; cámbialas a tu archivo local para probar un backend propio.

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
- `id`, `role` y timestamps no pueden modificarse desde Flutter;
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

Inicio, Explorar, Crear y Misiones utilizan datos persistentes de Supabase. Incluye publicaciones por tipo de perfil, fotografías, guardados, búsqueda, perfiles de la comunidad, postulaciones y moderación. Las limitaciones concretas se documentan en [Comunidad y misiones](docs/community.md). No incluye AR.
