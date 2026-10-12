# MAREA — interacciones y push Android

Plan: solicitud aprobada en el chat, 5 de octubre de 2026.

- Interacciones: toque para reaccionar, mantener/deslizar/soltar, estado optimista y accesibilidad.
- Paneles: rutas raíz y visibilidad coordinada del dock, sin mover el feed.
- Cargas: esqueletos, botones con texto de progreso y actualización lineal.
- Android: FCM con Supabase, preferencias, dispositivos, cola, destinos compartidos y mensajes ocasionales.
- Verificación: widgets, backend, análisis, pruebas completas, Web y APK.

Ruling: trabajar en la rama `Chris/modern-interactions-push` del checkout seleccionado, que estaba limpio; no crear otro worktree ni mover el resultado fuera del proyecto del usuario.
Ruling: mantener el push desactivado cuando no exista configuración Firebase; las mejoras visuales y la bandeja siguen disponibles. Las credenciales externas son necesarias para verificar entrega real.

## Progreso

- Exploración completa. No hay configuración Firebase ni herramientas firebase/gcloud instaladas.
- Baseline de reacciones, paneles y navegación: 27 pruebas aprobadas; advertencia de hit testing en el selector anterior.
- Suite completa de baseline: 387 pruebas aprobadas.

- Reacciones optimistas, selector accesible y paneles raíz implementados. Esqueletos en todas las cargas que antes usaban ruedas; refresco lineal.
- FCM, preferencias y sesión Android implementados; migración 014 y worker con autenticación privada.
- Backend: 4 pruebas PostgreSQL/PGlite y 3 de entrega FCM aprobadas. Gate local: 10 aprobadas.
Ruling: usar ondas Material `InkRipple` coherentes con MAREA. El shader InkSparkle de este SDK se genera para Vulkan mientras el runner de widgets usa SkSL; se reproducía incluso después de limpiar los artefactos. Las animaciones de escala funcionan sin ese shader.

- Revisión independiente: corregidos logout offline/colgado, reset tardío entre cuentas, token renovado y actividad Web/iOS. Sin hallazgos pendientes en la última pasada.
- Regresiones: selección con teclado, cancelación, reacción tardía al cambiar de usuario, paneles anidados y eliminación del navegador, esqueletos pequeños y movimiento reducido.
- Suite completa: 433 aprobadas antes de añadir la prueba de conservación de contenido; prueba enfocada de cargas/showcase/reacciones: 60 aprobadas.
- Supabase remoto: migración 014 aplicada, send-push desplegado y gate completo aprobado. Bandera de envío comprobada en false. Firebase requiere acceso/verificación de Google para continuar.
- Web y APK debug compilados. Secreto del worker y Vault configurados; smoke remoto401 sin autorización/503 autenticado sin credenciales FCM. No hay Android físico conectado para validar FCM real.

- Verificación final: 434 pruebas Flutter completas aprobadas; 9 Edge/PostgreSQL y 11 gate. Web, APK debug e iOS sin firma compilados. Firebase Flutter requiere iOS15: target actualizado y compilación iOS comprobada.
- Revisión visual en390×844: selector con los tres iconos, actualización inmediata, comentarios con esqueletos y dock oculto; restauración al cerrar. Se ajustó accesibilidad para evitar botones de reacción duplicados.
- Firebase creado en la cuenta indicada: MAREA (`marea-f6a92`), Spark, sin Analytics ni Gemini; Android `com.marea.app` registrado. Google Cloud requiere verificación adicional para obtener configuración y preparar credenciales de envío.
- Verificación final posterior a los ajustes de accesibilidad: 436 pruebas Flutter aprobadas y análisis sin incidencias.
- Web y APK debug recompilados con los últimos ajustes. El APK aún necesita la configuración pública Firebase para recibir push; no se habilitó el cron ni la bandera de envío. La verificación adicional de Google Cloud quedó solicitada al usuario.
- Google Cloud verificado por el usuario. Configuración pública Android obtenida y guardada en el archivo ignorado `config/firebase.android.json`; APK debug compilado con Firebase. Cuenta dedicada `marea-push` preparada antes de crearla; autorización de credencial/rol/almacenamiento en Supabase solicitada por el requisito de la herramienta del navegador.
- Autorización recibida. Cuenta `marea-push@marea-f6a92.iam.gserviceaccount.com` creada con el rol FCM autorizado; Google Cloud confirmó la generación del JSON. Descarga no expuesta por la herramienta ni localizada en carpetas de usuario o temporales: se pidió al usuario guardar el archivo desde el navegador e indicar su ruta. No se generaron claves duplicadas. API FCM v1 comprobada como habilitada.
- Usuario confirmó que la descarga falló. Alternativa oficial Cloud Shell: nueva clave transferida a `FCM_SERVICE_ACCOUNT_JSON` en Supabase y la anterior desactivada. OAuth FCM200; HTTP v1 validate_only400 INVALID_ARGUMENT para el token de diagnóstico deliberadamente inválido. Worker remoto200, processed0/sent0 con bandera false. Copias temporales remota/local eliminadas. Gate remoto nuevamente aprobado.
- Android físico conectado con autorización: APK Firebase instalado correctamente en Samsung SM-A556E. Pendiente abrir la app y conceder permiso para validar registro/entrega real; solicitud de confirmación de Inicio enviada al usuario.
- El usuario no vio el aviso de permiso y lo habilitó manualmente en Android. Los registros detectaron `refresh_token_not_found`; se corrigió su clasificación como sesión inválida para recuperar el acceso. Prueba de regresión y 29 pruebas enfocadas aprobadas, análisis limpio. APK actualizado instalado en el Samsung; pendiente confirmar sesión/estado del permiso y registro del dispositivo. Se añadió diagnóstico de inicialización solo en debug, sin datos de credenciales ni tokens.
- Samsung registrado en Supabase y permiso confirmado. Revisados y corregidos dos casos de recuperación del diálogo: refresh usa promptOnce y el indicador persistente sólo se guarda cuando termina la solicitud. Dos regresiones fallaron antes y pasaron después. 439 pruebas completas aprobadas, más 28 de comunidad tras abreviar «Acciones» a «Más» para texto ampliado.
- `pg_net` instalado antes de las pruebas físicas; el cron aún no está instalado. Primer aviso con app abierta: cola sent, un intento, activación inmediata desde el trigger y usuario confirma un único aviso del sistema. Segundo plano: cola sent con un intento; pendiente confirmación del celular. Las pruebas usan eventos claramente identificados, inactividad/horario controlados sólo para la única cuenta del dispositivo, y restauran actividad/zona/bandera false al finalizar.
- Se generan los cuatro recursos públicos Android de Firebase desde los mismos dart-defines, para iniciar el SDK nativo cuando despierta el proceso sin Dart. FCM auto-init sigue desactivado hasta permiso. Compilación nativa y prueba de app cerrada en curso.
- APK con recursos nativos compilado y reinstalado correctamente. Los cuatro recursos generados coinciden con los defines públicos (valores omitidos); Web actual también compilado. Revisión de sesión/permiso y Gradle sin hallazgos pendientes. Falta confirmación de segundo plano y prueba de app cerrada; bandera general false, sin cron.
- El usuario no vio el primer aviso de segundo plano. Repetición solicitada con el APK nativo actual: abrir una vez y dejar en segundo plano. Aceptación de FCM no se toma como prueba de recepción. Análisis actual limpio.

- Pruebas físicas posteriores a la corrección: un aviso visible en segundo plano y otro con el proceso realmente cerrado; al tocar ambos se abrió Inicio y `read_at` quedó registrado. La primera prueba de segundo plano fallida se corrigió mediante recursos Firebase nativos. No se afirma que estén probadas físicamente todas las variantes de permiso, cuenta y renovación.
- Cinco eventos de diagnóstico propios eliminados; actividad y zona restauradas, cola vacía antes de activar. El usuario excluyó iOS y confirmó la Web existente en `https://marea-azul.netlify.app/`.
- Netlify autenticado por el usuario: Web actual publicada mediante Netlify Drop en el proyecto existente, deploy `6ac4886c87af0e3de91ce2fb`. URL pública responde200 y SHA256 de `main.dart.js` coincide con la compilación actual. Pantalla Welcome comprobada visualmente y evidencia guardada en `output/modern-interactions/web-live.png` y `netlify-published.png`.
- `supabase/push/activate.sql` ejecutado correctamente tras comprobar Android y Web compatibles. Cron por minuto y bandera de envíos activados; primeras llamadas backend al worker devuelven200 sin timeout. Verificación operativa final: bandera true, exactamente un cron activo por minuto, última ejecución succeeded, cola vacía y un dispositivo habilitado. Gate remoto aprobado y git diff --check limpio.
