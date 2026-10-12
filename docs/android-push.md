# Notificaciones Android de MAREA

La integración está activa en el proyecto Supabase vinculado: migración 014, worker `send-push`, credenciales FCM, Vault y proceso por minuto configurados. Supabase conserva cuentas, publicaciones, bandeja, preferencias y cola; Firebase sólo transporta avisos a Android. La Web compatible se publicó el 5 de octubre de 2026 en https://marea-azul.netlify.app/ (deploy `6ac4886c87af0e3de91ce2fb`); su `main.dart.js` servido coincide byte por byte con la compilación verificada. iOS quedó fuera de la distribución solicitada por el usuario.

## Configuración externa

Proyecto creado: `MAREA` (`marea-f6a92`), plan Spark sin Analytics. Android registrado como `com.marea.app`, app ID `1:985129121820:android:386304edd4f802c06147d9`, sender ID `985129121820`. La configuración pública se guardó en `config/firebase.android.json` (ignorado por Git) y el APK debug ya fue compilado con esos valores e instalado en el Samsung físico conectado. API FCM v1 comprobada como habilitada. La cuenta dedicada `marea-push` y su rol `roles/firebasecloudmessaging.admin` se crearon con autorización del usuario. La descarga del navegador falló: se generó una nueva clave mediante Cloud Shell, se transfirió a `FCM_SERVICE_ACCOUNT_JSON` en Supabase y se desactivó la clave que quedó sin archivo. Las copias temporales de Cloud Shell y del equipo se eliminaron después de validar la integración. El Samsung registra sesión, dispositivo y permiso concedido. Se verificó un único aviso con la app abierta (confirmado por el usuario), en segundo plano y con el proceso cerrado (observados en la bandeja del celular). Al tocar los avisos de segundo plano y arranque en frío, se abrió Inicio y la bandeja marcó el evento leído. La primera prueba de segundo plano no llegó; se corrigió la inicialización nativa de Firebase mediante recursos Android y la repetición sí llegó. Los cinco eventos de diagnóstico se eliminaron de la cuenta probada y la actividad/zona horaria se restauraron antes de activar el proceso. Permiso denegado, cambio de cuenta y renovación de token siguen requiriendo una matriz física más amplia; los casos de sesión, recuperación de permiso y coordinación de registro tienen pruebas automatizadas.

1. En Firebase Console, crear o seleccionar el proyecto de MAREA y registrar la aplicación Android `com.marea.app`. Habilitar Firebase Cloud Messaging API v1. No hace falta activar Analytics.
2. Copiar los cuatro valores públicos de la app Android a un archivo local ignorado de defines, junto con los de Supabase: `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` y `FIREBASE_PROJECT_ID`. Gradle genera los recursos públicos de Firebase a partir de esos mismos valores para inicializar el SDK nativo cuando Android despierta la app cerrada; Flutter también inicializa Firebase con ellos. Los cuatro se proporcionan juntos o se omiten todos. No se requiere añadir el plugin Google Services ni incluir una clave privada en Flutter. Compilar con `flutter build apk --dart-define-from-file=config/supabase.production.json --dart-define-from-file=config/firebase.android.json`.
3. Crear una cuenta de servicio con el permiso de envío FCM del proyecto (`roles/firebasecloudmessaging.admin`). Descargar su JSON y guardarlo fuera del repositorio. Su `project_id` debe coincidir con el del cliente Android.
4. Aplicar las migraciones con el flujo habitual del proyecto y ejecutar `node tool/check_backend_contract.mjs`. La 014 amplía el contrato de notificaciones; publicar primero clientes compatibles con `marea_message` en todas las plataformas que se distribuyen, antes de activar el scheduler.
5. Guardar en los secretos de Edge Functions `FCM_SERVICE_ACCOUNT_JSON` (JSON completo) y `PUSH_WORKER_SECRET` (valor aleatorio de al menos 32 caracteres). Supabase proporciona `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY`; nunca poner estas claves en defines de Flutter. Puede usarse `supabase secrets set --env-file /ruta/privada/marea-push.env`. Desplegar `supabase functions deploy send-push`; el endpoint verifica su secreto propio aunque JWT esté desactivado en `config.toml`.
6. En Supabase Vault crear `marea_push_url`, con `https://<project-ref>.supabase.co/functions/v1/send-push`, y `marea_push_worker_secret`, con el mismo valor privado del worker. Usar Vault en el Dashboard evita guardar el secreto en un archivo SQL versionado.

## Validar y activar

Comprobar primero la aplicación Android real: acceso inicial completo, solicitud de permiso, cambios desde Configuración, registro del celular y preferencias. Sin Firebase configurado se conserva la bandeja y se muestra que los avisos del celular aún no están disponibles.

Invocar el worker con POST y cabecera `x-marea-worker-secret` mientras `private.push_settings.enabled=false`: debe responder sin reclamar trabajos. No imprimir la cabecera, tokens ni credenciales en logs compartidos. Para probar envíos, habilitar temporalmente esa bandera en un entorno de pruebas configurado; crear una notificación mediante una reacción/comentario real de otra cuenta. Validar primer plano (presentación local), segundo plano y app cerrada (FCM), apertura del destino y un único aviso por evento. Verificar permiso denegado, cierre/cambio de cuenta, renovación del token y contenido eliminado.

Después de validar las credenciales, clientes compatibles y entrega real, ejecutar `supabase/push/activate.sql` como postgres. Instala una invocación por minuto, idempotente por nombre, y habilita los envíos. Los triggers despiertan al worker inmediatamente; el cron continúa los reintentos y programa mensajes sin que Flutter esté abierto. La pausa figura al final del mismo archivo.

Los mensajes de MAREA sólo se programan tras 72 horas sin actividad, entre las 10:00 y las 19:00 de la zona registrada, como máximo dos en siete días y separados por 72 horas. Android, Web e iOS actualizan actividad al entrar/reanudar y durante sesiones activas. Desactivar mensajes o volver cancela la cola pendiente. La bandeja conserva el mensaje ya creado.

## Nota de compilación iOS

iOS no se distribuyó ni se incluyó en las pruebas físicas por indicación del usuario. El transporte sólo se inicializa en Android; Web e iOS mantienen la bandeja y preferencias. Los plugins Flutter de Firebase se enlazan también al compilar iOS y su SDK requiere iOS 15. El target de Runner se actualizó a 15.0 para mantener la compilación compatible con estas dependencias.

## Verificación local y operación

Última suite completa: 439 pruebas Flutter aprobadas; 28 pruebas de comunidad posteriores al ajuste de texto ampliado aprobadas. Análisis sin incidencias, Web y APK debug compilados e instalados. Nueve pruebas de funciones/PostgreSQL y once del gate aprobadas; contrato remoto aprobado. La prueba en el celular cubrió los tres estados de ejecución y la apertura de avisos hacia Inicio; no sustituye toda la matriz manual indicada arriba.

```sh
flutter analyze
flutter test
npx --yes deno test --allow-read supabase/functions/send-push
npx --yes deno check supabase/functions/send-push/index.ts
node --test test/tool/backend_contract_test.mjs
flutter build web --dart-define-from-file=config/supabase.production.json
flutter build apk --dart-define-from-file=config/supabase.production.json --dart-define-from-file=config/firebase.android.json
```

Las pruebas PostgreSQL/PGlite ejecutan la migración real con un fixture mínimo y reloj controlado para los límites de mensajes. No sustituyen la prueba en un Android físico ni la configuración real de Firebase, Vault, pg_net y pg_cron. Revisar `private.push_queue` (estado, intentos y `last_error`), el historial del cron y los logs del worker desde herramientas privadas de administración. No exponer la cola o dispositivos al cliente. Un token inválido sólo desactiva la versión reclamada; los trabajos con cinco intentos fallidos quedan terminales y no giran indefinidamente.

Referencia: [FCM para Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [recursos Android de Firebase](https://firebase.google.com/docs/android/google-services-plugin-and-file), [envío HTTP v1](https://firebase.google.com/docs/cloud-messaging/migrate-v1), [Supabase Cron](https://supabase.com/docs/guides/cron).
