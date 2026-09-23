# Acceso y perfil — ampliación del MVP

Actualización de la etapa escolar: ya están publicados los términos y el aviso `escolar-1.0`, y el bloqueo legal del registro fue retirado por instrucción del responsable. Consulta `docs/legal/README.md`. Se pospuso SMTP y no se cambió la confirmación de correo; los requisitos de lanzamiento público descritos abajo siguen siendo una guía futura.

## Implementado

- Bienvenida pública con Crear cuenta e Iniciar sesión; términos, aviso y ayuda para eliminación accesibles sin sesión.
- México, comunidad de 18 años o más. Declaración separada de mayoría de edad y aceptación contractual sin preselección. No se recopilan identificación, cumpleaños, domicilio ni geolocalización.
- Registro bloqueado en cliente y trigger de Auth hasta publicar documentos y activar la política. Las versiones se contrastan en servidor, la fecha se genera allí y el cliente no puede insertar, modificar ni borrar el historial de aceptación.
- Las cuentas existentes no reciben aceptaciones inventadas: se solicita aceptar los documentos vigentes al iniciar sesión. Pueden gestionar/eliminar la cuenta sin aceptar condiciones nuevas.
- Confirmación y recuperación mediante código de correo, reenvío con espera de 60 segundos y mensajes que no revelan si existe una cuenta. El servidor Supabase mantiene sus propios límites.
- Cambios de correo con contraseña actual y confirmación en ambos correos; cambio de contraseña con contraseña actual y código de reautenticación si Supabase lo requiere.
- Guía de tres pasos: intereses, objetivos privados y presentación. Se puede omitir sin perder acceso, retomar y modificar después.
- Perfil: nombre, username, bio, tipo, intereses, un enlace HTTPS, avatar y portada. Objetivos y correo no se muestran en el perfil. No se publican perfiles a otros usuarios: RLS sigue siendo solo del propietario.
- Imágenes: selección de galería, vista previa, ajuste centrado, reemplazo, eliminación y cuatro portadas MAREA. No hay recorte manual. Entrada hasta 10 MB / 24 MP; conversión local a PNG sin EXIF, máximo 640 px avatar / 1600 px portada y salida hasta 4 MB. La Edge Function vuelve a decodificar/normalizar PNG y valida tamaño, dimensiones y propiedad.
- Guardado con bloqueo de envíos duplicados, aviso de cambios sin guardar, conservación de la imagen anterior hasta confirmar el perfil. Archivos de edición abandonados se limpian al siguiente upload tras 24 horas o al eliminar la cuenta.
- Bucket privado y URLs firmadas de 10 minutos. Sin permisos de upload/delete directos para clientes: las escrituras pasan por la función validada.
- Eliminación reintentable: marcador duradero, bloqueo de nuevas escrituras, espera de subidas en curso, limpieza de Storage y finalmente Auth/cascade. Storage y PostgreSQL **no son una transacción conjunta**. Una interrupción puede haber eliminado imágenes; reintentar completa el proceso.

## Configuración remota obligatoria

Estado actualizado: se verificó el proyecto real autorizado por el usuario; las migraciones 001/002 y ambas funciones ya estaban desplegadas y no se reaplicaron. Storage se probó con subida/descarga y limpieza de un archivo temporal. Ver `docs/deployment-status.md`. Los pasos siguientes siguen siendo la guía para preparar otro entorno; usa staging y un respaldo verificado antes de cambiar datos existentes.

1. `supabase login` y `supabase link --project-ref TU_PROJECT_REF`.
2. Revisar `supabase db push --linked --dry-run` y después aplicar `supabase db push --linked`. Debe aplicar 002 después de 001. 002 conserva perfiles y cierra nuevos registros por defecto.
3. Desplegar **ambas** funciones:

```sh
supabase functions deploy profile-media --use-api
supabase functions deploy delete-account --use-api
```

No usar `--no-verify-jwt`. Ambas funciones comprueban además el usuario con `auth.getUser()` y nunca aceptan un user ID del cuerpo. Las claves administrativas permanecen en los secretos automáticos del entorno Supabase.

4. Auth → Email: activar Confirm Email y Secure Email Change. Configurar longitud de contraseña mínima de al menos 8, límites de envío/verificación y las protecciones contra contraseñas filtradas disponibles en el plan. Probar el flujo de reautenticación si se activa Secure Password Change.
5. Configurar SMTP propio y dominio remitente verificado; el SMTP de prueba no es una solución de envío público. Copiar `supabase/email-templates/confirmation.html` a Confirm signup y `recovery.html` a Reset password. Los códigos usan `{{ .Token }}`; no dependen de deep links móviles. Mantener las plantillas de cambio de correo y reautenticación de Supabase y personalizar solo la marca.
6. Configurar Site URL / URLs permitidas con el dominio HTTPS real y localhost para desarrollo. Este MVP usa código manual para recuperación; no publicar una plantilla de recuperación que solo tenga un enlace. Cambiar contraseña por un enlace heredado requiere comprobar el evento `passwordRecovery`; ante una recarga que pierde ese estado, solicitar/verificar otro código.
7. Publicar documentos aprobados y configurar la política siguiendo la sección siguiente.
8. Compilar `lib/main.dart` usando un archivo local basado en `config/supabase.example.json`. Se eliminó la entrada `tool/ui_preview.dart` para evitar ejecuciones con datos simulados. El hosting debe redirigir rutas de Flutter a `index.html`, incluidas `/privacy`, `/terms` y `/delete-account`.

## Documentos legales y activación

Faltan datos del responsable: nombre o razón social, domicilio aplicable al aviso, correo de privacidad/soporte, procedimiento ARCO y decisiones de conservación/transferencias. No se generaron textos con nombres, domicilios o garantías inventados.

Un profesional debe revisar los términos y el aviso para México: finalidades necesarias y opcionales, datos tratados, proveedores/transferencias, derechos ARCO y revocación, cambios del aviso, conservación/borrado y reglas de uso. No hay consentimiento para publicidad ni analítica porque esta implementación no añade esos tratamientos. La base de referencia es la [LFPDPPP publicada por la Cámara de Diputados](https://www.diputados.gob.mx/LeyesBiblio/pdf/LFPDPPP.pdf); esto no es una certificación de cumplimiento.

Con los textos aprobados, un administrador carga dos filas en `public.legal_documents` (kind `terms`/`privacy`, versión única, título, cuerpo completo y `published_at`). No pegar documentos legales en metadatos del usuario. Las versiones publicadas son inmutables: cualquier cambio requiere una nueva versión.

En `public.registration_settings` configura `terms_version`, `privacy_version`, un `support_email` operativo y `signup_enabled=true`. El RPC `registration_policy()` solo habilita el registro si ambas versiones están publicadas y existe contacto. Verificar estas tres rutas en una ventana sin sesión:

- `/terms`: texto contractual completo, no borrador.
- `/privacy`: aviso completo y accesible.
- `/delete-account`: instrucciones, recuperación y contacto real para solicitar ayuda sin reinstalar Android.

Una casilla de 18+ registra una declaración, **no acredita documentalmente la edad**. No prometer verificación de identidad. Revisar con asesoría si el riesgo del servicio exige controles adicionales.

## Comprobaciones antes de usuarios reales

- Dos cuentas reales en staging: registro con código, reenvío, código vencido/incorrecto, recuperación en Android/Web, cambio de correo confirmado en ambos buzones y contraseña nueva.
- Intento directo a Auth sin consentimiento, con edad falsa/ausente y versiones obsoletas: rechazado. Aceptaciones con fecha de servidor y protegidas contra edición.
- Guardar, quitar y reemplazar avatar/portada desde Android y Web; abrir la otra plataforma y comprobar persistencia.
- RLS: otro usuario no lee ni actualiza el perfil, historial o fotos; RPCs administrativos no son ejecutables por clientes; endpoints rechazan JWT ausente/falso.
- Simular corte durante subida y eliminación: la cuenta conserva un estado reintentable y no aparecen archivos después del borrado. Un proceso de imágenes interrumpido puede mantener una reserva hasta 10 minutos; volver a intentar la eliminación después.
- Confirmar que Auth, perfil, preferencias, imágenes y aceptación desaparecen. Revisar backups/retenciones del proveedor: borrar de tablas activas no equivale a borrar inmediatamente todos sus respaldos. Los JWT ya emitidos pueden seguir criptográficamente válidos hasta expirar; las funciones verifican que el usuario aún existe.
- Probar cerrar sesión con error de conexión, volver atrás con cambios sin guardar, teclado móvil, lector de pantalla y aumento de texto. No hay recuperación de borradores después de cerrar/recargar la pestaña.
- Para Play Store: política pública, enlace externo de eliminación y formulario Data safety coherente. Ver [política oficial de datos de Google Play](https://support.google.com/googleplay/android-developer/answer/10144311).
- Valorar CAPTCHA / límites adicionales antes de un registro abierto de gran escala. El cooldown visual no sustituye los límites del servidor; no se integró un proveedor CAPTCHA ni se crearon cuentas externas.

## Verificación local reproducible

```sh
dart format lib test
flutter analyze
flutter test
flutter build web --dart-define-from-file=config/supabase.local.json
flutter build apk --debug --dart-define-from-file=config/supabase.local.json
npx --yes deno check supabase/functions/profile-media/index.ts supabase/functions/delete-account/index.ts
npx --yes deno test --allow-env --allow-read supabase/functions/profile-media/image_test.ts
```

`tool/check_database.mjs` ejecuta las migraciones en PostgreSQL aislado mediante PGlite, con esquemas Auth/Storage de prueba, y comprueba grants, RLS, consentimientos, preferencias, reservas y cascadas. Instala `@electric-sql/pglite` en un directorio temporal y pasa la ruta absoluta de `dist/index.js` en `MAREA_PGLITE_MODULE`. No sustituye el API de Auth ni Storage remotos.

Resultado local del 14 de septiembre de 2026: analyzer sin incidencias, 62 pruebas Flutter, 33 comprobaciones PostgreSQL y 3 pruebas de imágenes aprobadas; Deno check, Web y APK debug completados. Sin prueba interactiva en dispositivo Android ni compilación iOS. El build Web avisa sobre la fuente opcional CupertinoIcons y Gradle sobre acceso nativo de Java; no impidieron compilar. En el servidor de demostración apareció además un error del cliente de depuración inyectado DWDS; la navegación y guardado de la demo siguieron funcionando. No es evidencia de validación remota ni de una consola de desarrollo libre de avisos.

Fuentes técnicas: [Auth por contraseña/códigos](https://supabase.com/docs/guides/auth/passwords), [plantillas de correo](https://supabase.com/docs/guides/auth/auth-email-templates), [eliminación de usuarios y objetos](https://supabase.com/docs/guides/auth/managing-user-data), [autenticación de Edge Functions](https://supabase.com/docs/guides/functions/auth).
