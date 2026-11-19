# Avisos remotos en Android, iOS y Web

MAREA registra los tokens FCM por instalación después de autenticar la cuenta y obtener permiso. El worker de Supabase usa las preferencias, la cola y las mismas comprobaciones de vigencia para los tres destinos. Al tocar el aviso, la aplicación consulta la fila de la bandeja bajo la sesión actual antes de abrir su destino. El despliegue histórico de Android figura en [la bitácora Android](android-push.md).

## Configurar un entorno de prueba

1. Registrar cada aplicación en un proyecto Firebase de pruebas. Usar el identificador de paquete de la compilación Android o el bundle ID de iOS. Añadir una app Web en ese mismo proyecto. Habilitar Firebase Cloud Messaging HTTP v1. La cuenta de servicio del worker debe pertenecer a este proyecto.
2. Copiar [el ejemplo de defines públicos](../config/firebase.push.example.json) a un archivo local por plataforma y sustituir los marcadores. Usar el app ID que Firebase asignó a esa plataforma. Web necesita además la clave pública del par VAPID generado en **Cloud Messaging → Web Push certificates**. Android e iOS pueden omitir esa entrada.
3. Para una aplicación de desarrollo, usar el backend Supabase de pruebas y sus defines de desarrollo habituales. Añadir al archivo de Firebase de pruebas `MAREA_TEST_FIREBASE_PROJECT_ID` con el ID del proyecto aislado y `MAREA_PRODUCTION_FIREBASE_PROJECT_ID` con el ID público de producción para comprobar la separación. El piloto de producción mantiene la bandeja como único canal.
4. En Apple Developer habilitar Push Notifications para el App ID, renovar el perfil de aprovisionamiento y firmar el build con ese perfil. Registrar en Firebase la clave de autenticación APNs del entorno apropiado, junto con el Key ID y el Team ID. El proyecto configura `aps-environment` en desarrollo para Debug y producción para Profile y Release. MAREA conserva el proxy de delegado de Firebase y permite el modo de fondo `remote-notification`.
5. Publicar el build Web en HTTPS o probar en localhost. Servir el archivo real `push/firebase-messaging-sw.js` como JavaScript con su query original, junto con `push_bridge.js` y los iconos. El worker se configura con los mismos cuatro valores públicos que Flutter y usa un ámbito propio bajo `push/`. Permitir el SDK Firebase Web de gstatic en la política de scripts. En navegadores compatibles, abrir **Configuración → Notificaciones → Permitir notificaciones**. En iPhone o iPad con Web Push, usar la aplicación web instalada en la pantalla de inicio.
6. Guardar el JSON de la cuenta de servicio en el secreto de la Edge Function `FCM_SERVICE_ACCOUNT_JSON`, y el secreto del worker en `PUSH_WORKER_SECRET` y su entrada correspondiente de Vault. En el proyecto Supabase de prueba aplicar las migraciones, desplegar `send-push` y configurar [la invocación de la cola](../supabase/push/activate.sql). La clave APNs, el secreto VAPID, el token de dispositivo y las credenciales de envío permanecen fuera de los archivos públicos de Flutter.

Ejemplo para la Web de desarrollo, con archivos locales preparados para el mismo entorno.

```sh
flutter run -d chrome --dart-define-from-file=config/supabase.development.json --dart-define-from-file=config/firebase.web.local.json
```

## Prueba con entrega real

Usar dos cuentas de prueba, crear un comentario o mensaje permitido desde la segunda y verificar el aviso con la primera. Repetir con la app visible, en segundo plano y cerrada, comprobando una sola presentación y su destino. Silenciar la categoría y repetir. Denegar o retirar permiso, cerrar sesión y cambiar de cuenta para comprobar que la bandeja se conserva y los taps antiguos se descartan. Tras renovar el token o la suscripción Web, reabrir la app y repetir el envío. En Web la app vuelve a consultar el token al reanudar la sesión, además de al iniciar. Las pruebas locales con claves de ejemplo comprueban el contrato y la navegación. La entrega de extremo a extremo necesita credenciales del proveedor y permisos del dispositivo.

Véanse [la configuración Flutter de FCM](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [la recepción Web](https://firebase.google.com/docs/cloud-messaging/web/receive-messages) y [la referencia de mensajes HTTP v1](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages).
