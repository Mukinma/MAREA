# Comunidad y funciones por perfil

MAREA utiliza cuentas reales de Supabase. Inicio, Explorar, Crear y Misiones consultan y guardan contenido en PostgreSQL. No se incorporó ninguna función, dependencia ni permiso de realidad aumentada.

## Qué diferencia a cada perfil

| Perfil | Publicaciones sociales nuevas | Apartado propio y herramientas |
| --- | --- | --- |
| Usuario general | Comunidad | Publicaciones, explorar, guardar y misiones |
| Artista / creador | Comunidad y proyectos | Portafolio: obras/proyectos, fotografías, enlaces y disponibilidad para colaborar |
| Emprendedor | Comunidad, productos y servicios | Catálogo: productos y servicios, precio opcional en MXN, disponibilidad y contacto |
| Negocio | Comunidad, servicios, espacios y eventos | Servicios: precio opcional, contacto, ubicación y horarios semanales |
| Administrador | Las opciones de su tipo de perfil | Acceso privado adicional a Moderación |

El tipo se elige y confirma una sola vez, junto con intereses y objetivos privados. Las publicaciones anteriores permanecen editables por su propietario aunque el tipo confirmado sea distinto; las nuevas respetan sus capacidades. El rol administrativo es independiente y no se asigna desde registro o edición.

## Permisos de misiones por tipo de perfil

Los cuatro tipos tienen los mismos permisos para organizar misiones. El tipo solicitado define quién puede postularse, sin jerarquía entre los perfiles.

| Acción | Quién puede realizarla |
| --- | --- |
| Crear misión | Persona, artista/creador, emprendedor y negocio |
| Postularse | Otro usuario cuyo tipo coincide con el solicitado; todos si no se especifica tipo |
| Editar, cerrar, reabrir, cancelar o finalizar | Propietario de la misión, respetando fecha, estado y bloqueo de condiciones |
| Revisar y seleccionar postulaciones | Propietario; solo antes de la fecha y respetando el cupo, incluso con convocatoria cerrada |
| Retirar una postulación pendiente o aceptada | Su participante, antes de la fecha y mientras la misión no sea terminal |
| Ocultar o restaurar contenido reportado | Administrador; este rol no concede gestión de misiones ajenas |

Desde Herramientas del perfil se puede crear contenido y encontrar colaboraciones compatibles. “Para mi perfil” consulta en servidor convocatorias dirigidas al tipo actual y convocatorias para todos. Esto indica compatibilidad de tipo; la postulación también depende de cupo, fecha, estado y ausencia de una solicitud activa o rechazada. Mis postulaciones permite filtrar pendientes, aceptadas, no seleccionadas y retiradas. Una retirada conserva el historial y permite volver a postularse si la convocatoria sigue disponible.

La revisión de permisos se ejecuta con roles autenticados en PostgreSQL aislado: 20 combinaciones de organizador y perfil solicitado, los cuatro tipos de participante, propiedad, acceso anónimo y ciclo de convocatoria. No modifica cuentas ni contenido del proyecto remoto.

Inicio, Explorar, Crear, Misiones y Perfil mantienen la navegación principal. Crear ofrece publicaciones a todos y las fichas correspondientes a perfiles profesionales. Perfil separa publicaciones del apartado profesional y abre Guardados, Mis misiones y Mis postulaciones directamente. Los visitantes ven presentación, fichas disponibles, publicaciones y misiones; los controles de administración son exclusivos del propietario.

## Fichas profesionales independientes

- `project`, `product` y `service` viven fuera de Inicio. Las fichas nuevas comienzan vacías; los posts existentes no se migran ni se duplican.
- Título, descripción, categoría y hasta seis fotografías ordenadas. Obras y productos publicados requieren al menos una fotografía; servicios pueden publicarse sin imagen.
- Guardar borrador, publicar, editar, archivar, volver a borrador y eliminar con confirmación. Borradores y archivados permanecen privados. El público solo ve contenido publicado, disponible y sin ocultamiento por moderación.
- Productos y servicios admiten precio opcional en MXN; sin precio muestran “Consultar precio”. Contactar aparece únicamente si el perfil tiene enlace HTTPS configurado.
- Guardados privados y reportes integrados en Moderación. Explorar busca por título y filtra por categoría y tipo, además de buscar publicaciones/personas.
- Carga, reintento, estados vacíos, aviso de cambios sin guardar y conservación del formulario tras fallar. Guardar ficha permanece accesible al pie del formulario móvil.
- Negocios pueden usar el selector existente de ubicación y configurar un intervalo por día o cerrado. Horarios y ubicación son opcionales; las horas se presentan en la hora local del negocio.

## Flujos disponibles

- Publicar título, descripción y categoría, con fotografía opcional desde la galería; editar y eliminar publicaciones propias. Las publicaciones pueden incluir una ubicación seleccionada en el mapa, buscada por dirección, elegida manualmente o tomada de la ubicación actual tras una acción explícita.
- Explorar publicaciones mediante búsqueda y categorías, guardar y quitar guardados, visitar perfiles con sus publicaciones y misiones.
- Crear misiones con ubicación escrita, fecha y hora, cupo y tipo de participante buscado. Todos los perfiles pueden crear oportunidades.
- Postularse con un mensaje, consultar el estado y retirar la postulación. No es posible postularse a una misión propia, fuera de fecha, cerrada o incompatible con el tipo solicitado.
- Revisar postulaciones propias como organizador, consultar perfiles, aceptar o rechazar y cerrar/reabrir una convocatoria antes de su fecha. La base de datos serializa la selección para respetar el cupo.
- Reportar publicaciones, fichas o misiones. El administrador revisa el contenido, lo oculta y puede restaurarlo desde el historial de reportes.

## Datos y permisos

Las migraciones `003_community.sql` y `004_post_locations.sql` agregan `posts`, `post_saves`, `missions`, `mission_applications` y `content_reports`, índices, permisos por columna y RLS. Las coordenadas de una publicación son opcionales y se guardan con precisión `exact` o `approximate`; las publicaciones antiguas que solo tienen texto siguen siendo válidas. Los RPCs verifican la identidad y el rol en el servidor. Un cliente no puede decidir autor, visibilidad ni rol administrativo.

La tabla de perfiles conserva su lectura privada. `community_profiles` devuelve solo presentación pública: nombre, usuario, bio, tipo, enlaces, avatar/portada y campos profesionales. No expone correo de acceso, intereses, objetivos, aceptación legal ni rol. Fotos públicas de presentación se leen únicamente mientras estén referenciadas por un perfil visible; los visitantes ven el avatar y la portada reales.

Las fotografías de posts usan el bucket privado `post-images`: PNG de hasta 4 MiB, ruta por propietario y lectura ligada a publicaciones visibles. Los enlaces firmados vencen a los 10 minutos; ocultar una publicación restringe nuevas lecturas, pero no revoca enlaces ya emitidos antes de su vencimiento. Eliminar la cuenta también limpia este bucket. Las subidas se coordinan con la marca de eliminación de cuenta.

La migración `006_profile_experience.sql` agrega marca de confirmación, `complete_initial_profile`, fichas, fotografías ordenadas y guardados. Las elecciones iniciales no aceptan escritura directa. La confirmación y el guardado de cada ficha son atómicos en PostgreSQL; identidad, capacidades, categorías, disponibilidad y propiedad se validan en servidor, además de Flutter. El bucket privado `showcase-media` admite PNG de hasta 4 MiB, lectura ligada a fichas visibles y borrado solo de imágenes propias sin referencias. Tras un guardado exitoso se limpian imágenes reemplazadas; un fallo conserva las anteriores. `delete-account` limpia también las fotografías de fichas antes del cascade. Las URLs firmadas duran diez minutos; ocultar contenido no revoca las ya emitidas hasta su vencimiento.

## Verificación

```sh
flutter analyze
flutter test
flutter build web --dart-define-from-file=config/supabase.local.json
MAREA_PGLITE_MODULE=/ruta/a/pglite/dist/index.js node tool/check_community_database.mjs
MAREA_PGLITE_MODULE=/ruta/a/pglite/dist/index.js node tool/check_mission_database.mjs
MAREA_PGLITE_MODULE=/ruta/a/pglite/dist/index.js node tool/check_profile_experience_database.mjs
```

Las migraciones hasta 006 y la actualización de `delete-account` están desplegadas en el proyecto conectado. El [estado de despliegue](deployment-status.md) distingue pruebas locales y comprobaciones remotas.

Las pruebas PostgreSQL se ejecutan en una base aislada con roles `anon` y `authenticated`, sin crear cuentas reales ni contenido de prueba en el proyecto conectado. Los repositorios de prueba viven únicamente en `test/`.

## Alcance de esta entrega

Los posts admiten una fotografía y una ubicación opcional. Las misiones se cierran o reabren; sus detalles no se editan después de publicar. El contacto disponible es el enlace voluntario del perfil y el mensaje de postulación; esta entrega no incorpora pedidos, reservas, pagos, chat privado, comentarios, algoritmo de recomendaciones ni AR. La ubicación de publicaciones usa mapas de OpenStreetMap y búsqueda de Nominatim. Android declara permisos de ubicación y Web solicita permiso al navegador solo cuando la persona pulsa `Usar mi ubicación actual`; no se obtiene ubicación al abrir el formulario ni se guarda automáticamente. La opción aproximada redondea las coordenadas antes de persistirlas. Las misiones mantienen ubicación textual.

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

## Validación de perfiles — 27 de septiembre de 2026

Analyzer sin incidencias, 194 pruebas Flutter, cuatro pruebas de imágenes en Chrome y 277 comprobaciones PostgreSQL aisladas aprobadas. Web y APK debug compilan con la configuración del proyecto real. La migración 006 y `delete-account` v4 están desplegadas; la base remota está al día y su lint no encontró errores. Las peticiones anónimas de fichas/confirmación/borrado son rechazadas.

Los recorridos automatizados cubren los cuatro tipos, confirmación/reingreso bloqueado, herramientas propias y visita pública, búsqueda/guardados, fallo de guardado, archivo/borrado y protección de cambios. La revisión visual verificó móvil y escritorio, incluido selector/vista previa de fotografía. No se inició sesión en cuentas de producción; la prueba manual entre dos sesiones reales y en Android físico sigue pendiente. El frontend remoto no se publicó por esta entrega.
