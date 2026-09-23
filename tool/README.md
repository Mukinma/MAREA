# Herramientas y ejecución local

La entrada de demostración `ui_preview.dart` fue retirada. La aplicación se ejecuta exclusivamente desde `lib/main.dart`. Los fakes de cuentas solo viven en las pruebas automatizadas.

```sh
flutter run -d chrome -t lib/main.dart --web-port 7357 --dart-define-from-file=config/supabase.local.json
```

El archivo local debe contener únicamente la URL y la clave publicable de tu proyecto. Nunca agregar claves `service_role`, `sb_secret` ni contraseñas. No se deben versionar archivos locales de configuración.

`check_database.mjs` valida migraciones en un PostgreSQL aislado para pruebas, sin modificar Supabase. Las pruebas de layout están en `test/features/presentation/responsive_test.dart`.
