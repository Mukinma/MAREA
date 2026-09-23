# Comunidad y funciones por perfil

MAREA utiliza cuentas reales de Supabase. Inicio, Explorar, Crear y Misiones consultan y guardan contenido en PostgreSQL. No se incorporó ninguna función, dependencia ni permiso de realidad aumentada.

## Qué diferencia a cada perfil

| Perfil | Publicaciones disponibles | Presentación del perfil |
| --- | --- | --- |
| Usuario general | Comunidad | Comunidad: descubrir, compartir y guardar |
| Artista / creador | Comunidad y proyectos | Portafolio |
| Emprendedor | Comunidad, productos y servicios; precio opcional en MXN | Catálogo |
| Negocio | Comunidad, espacios y eventos; ubicación obligatoria | Espacio y eventos |
| Administrador | Las opciones de su tipo de perfil, más gestión de reportes | Acceso adicional a Moderación |

El tipo de perfil se modifica en Editar perfil. Los contenidos existentes se conservan al cambiar de tipo; se pueden editar sin convertir su tipo de publicación. El rol administrativo es independiente y no se asigna desde el registro ni desde Editar perfil.

## Flujos disponibles

- Publicar título, descripción y categoría, con fotografía opcional desde la galería; editar y eliminar publicaciones propias. Las publicaciones pueden incluir una ubicación seleccionada en el mapa, buscada por dirección, elegida manualmente o tomada de la ubicación actual tras una acción explícita.
- Explorar publicaciones mediante búsqueda y categorías, guardar y quitar guardados, visitar perfiles con sus publicaciones y misiones.
- Crear misiones con ubicación escrita, fecha y hora, cupo y tipo de participante buscado. Todos los perfiles pueden crear oportunidades.
- Postularse con un mensaje, consultar el estado y retirar la postulación. No es posible postularse a una misión propia, fuera de fecha, cerrada o incompatible con el tipo solicitado.
- Revisar postulaciones propias como organizador, consultar perfiles, aceptar o rechazar y cerrar/reabrir una convocatoria antes de su fecha. La base de datos serializa la selección para respetar el cupo.
- Reportar publicaciones o misiones. El administrador revisa el contenido, lo oculta y puede restaurarlo desde el historial de reportes.

## Datos y permisos

Las migraciones `003_community.sql` y `004_post_locations.sql` agregan `posts`, `post_saves`, `missions`, `mission_applications` y `content_reports`, índices, permisos por columna y RLS. Las coordenadas de una publicación son opcionales y se guardan con precisión `exact` o `approximate`; las publicaciones antiguas que solo tienen texto siguen siendo válidas. Los RPCs verifican la identidad y el rol en el servidor. Un cliente no puede decidir autor, visibilidad ni rol administrativo.

La tabla de perfiles conserva su lectura privada. El directorio autenticado devuelve solamente nombre, usuario, bio, tipo de perfil y enlace voluntario. No expone correo, intereses privados, aceptación legal ni archivos privados del perfil. Por ello, los perfiles de otras personas muestran iniciales en esta versión.

Las fotografías de posts usan el bucket privado `post-images`: PNG de hasta 4 MiB, ruta por propietario y lectura ligada a publicaciones visibles. Los enlaces firmados vencen a los 10 minutos; ocultar una publicación restringe nuevas lecturas, pero no revoca enlaces ya emitidos antes de su vencimiento. Eliminar la cuenta también limpia este bucket. Las subidas se coordinan con la marca de eliminación de cuenta.

## Verificación

```sh
flutter analyze
flutter test
flutter build web --dart-define-from-file=config/supabase.local.json
MAREA_PGLITE_MODULE=/ruta/a/pglite/dist/index.js node tool/check_community_database.mjs
```

La migración 003 y la actualización de `delete-account` ya están desplegadas en el proyecto conectado. El [estado de despliegue](deployment-status.md) distingue pruebas locales y comprobaciones remotas.

Las pruebas PostgreSQL se ejecutan en una base aislada con roles `anon` y `authenticated`, sin crear cuentas reales ni contenido de prueba en el proyecto conectado. Los repositorios de prueba viven únicamente en `test/`.

## Alcance de esta entrega

Los posts admiten una fotografía y una ubicación opcional. Las misiones se cierran o reabren; sus detalles no se editan después de publicar. El contacto disponible es el enlace voluntario del perfil y el mensaje de postulación; esta entrega no incorpora chat privado, comentarios, pagos ni AR. La ubicación de publicaciones usa mapas de OpenStreetMap y búsqueda de Nominatim. Android declara permisos de ubicación y Web solicita permiso al navegador solo cuando la persona pulsa `Usar mi ubicación actual`; no se obtiene ubicación al abrir el formulario ni se guarda automáticamente. La opción aproximada redondea las coordenadas antes de persistirlas. Las misiones mantienen ubicación textual.

## Regresión de fotografías Web

El procesamiento de fotos evita consultar `ImageDescriptor.width/height` para imágenes codificadas en Web: Flutter no implementa esos getters en navegador. En Web se obtiene el tamaño desde la imagen decodificada con `instantiateImageCodec`; en Android/iOS se conserva la comprobación previa al decodificado. Ambos caminos generan PNG y mantienen los límites de dimensiones y peso.

Prueba específica en navegador real:

```sh
flutter test --platform chrome test/features/profile/data/profile_image_picker_test.dart
```

El arnés opcional `test/browser/image_picker_probe.dart` permite comprobar el selector y la vista previa sin una cuenta ni peticiones a Supabase. No forma parte de las rutas de la app.

Si una compilación anterior no incluyó el registro del plugin de fotos, regenerar los archivos de Flutter y publicar el resultado nuevo:

```sh
flutter clean
flutter pub get
flutter build web --dart-define-from-file=config/supabase.local.json
```

No editar manualmente los registradores generados. La compilación corregida incluye `ImagePickerPlugin.registerWith`.
