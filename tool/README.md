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

El gate consulta el historial 001–008, la columna/grants de `setup_step`, las
preferencias editables y los contratos de registro y confirmación. Si falla, no
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
