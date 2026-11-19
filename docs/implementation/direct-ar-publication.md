# Publicación directa de recorridos y marcadores

Cambio solicitado el 18 de noviembre de 2026: el autor publica sin revisión
administrativa. Sustituye la aprobación previa descrita en documentos anteriores.

## Recorrido virtual

1. En «Tus recorridos», crea o abre un recorrido y escribe su título y nombre.
2. En «Panoramas», pulsa «Añadir panorama». Se crea la zona/posición necesaria;
   puedes importar el JPEG 360° o capturar fotos con la guía existente.
3. Cuando el panorama esté listo y adjunto, entra a
   «Publicar» y pulsa «Subir recorrido». Queda visible para otros usuarios.

No se pide acreditar responsabilidad, aportar evidencia privada ni esperar a un
administrador. Guardar el borrador sigue siendo privado; salir conserva los cambios
locales. Puntos de RA, conexiones, orden y vista previa están en el menú de opciones.
Las fechas son opcionales. Se conserva el acceso actual de perfiles profesionales.

`tours_publish` valida autor, medios procesados, referencias y vigencia, congela
una revisión y la publica en la misma transacción. No crea solicitudes de revisión.
Los reintentos conservan la revisión pública y no quitan pausas. Una solicitud
anterior pendiente puede publicarse con el mismo botón: conserva su instantánea y
sustituye las solicitudes pendientes. `tours_submit` conserva compatibilidad con
clientes anteriores y delega a publicación directa.

Los vínculos con contenido de otra persona y la asociación a su espacio conservan
su consentimiento; publicar tu propio recorrido no concede derechos sobre ellos.
Las referencias de RA sin reconocimiento vigente permanecen fuera de la revisión
pública. La captura del cubo, el ensamblado y la clasificación horizontal/360° no cambian.

## Marcadores

En el repositorio remoto se sube la imagen con sus datos. Al guardar una prueba
real de reconocimiento de al menos tres segundos en Android/iOS, se publica
directamente. Editar el texto mantiene esa publicación; cambiar la imagen o el
ancho físico exige reconocer la nueva referencia antes de volver a publicarla.
Si el marcador ya tenía una prueba guardada, «Publicar marcador» aprovecha esa
prueba vigente; no se vuelve a exigir reconocimiento para el mismo archivo y ancho.

`published` controla la visibilidad, separado de `active`, que habilita los avisos
de proximidad. Publicar no exige GPS. «Notificar cerca» sigue siendo opcional y
requiere una ubicación exacta con precisión de hasta 20 m. Los permisos de cámara,
ubicación y notificaciones del sistema siguen siendo necesarios para esas funciones.
Las columnas de prueba y publicación solo se escriben mediante RPC con comprobación
de autor y versión; no se amplían los permisos de escritura directa del cliente.

## Activación del servidor

Las migraciones de publicación directa tienen estas dependencias:

- `20261118100001_direct_tour_publication.sql` requiere `015_tours.sql` y `042_tour_horizontal_panoramas.sql`.
- `20261118100002_direct_marker_publication.sql` requiere `041_ar_markers.sql`.

Verifica las dependencias y el historial antes de aplicar las migraciones en un
proyecto. En producción, `041`, `042` y las dos migraciones de publicación
directa se aplicaron y verificaron el 18/11/2026. Si el RPC de publicación falta,
la app conserva el borrador.

El repositorio remoto de marcadores se activa con
`--dart-define=AR_MARKERS_REMOTE=true`. Si se cambia del repositorio local al
remoto, los archivos del teléfono se conservan. Los marcadores locales no se
copian automáticamente a Supabase.

## Verificación local

`tool/check_direct_publication_database.mjs` carga las migraciones reales en
PostgreSQL aislado mediante PGlite. Comprueba la visibilidad de los borradores,
la publicación y el acceso de visitantes, el consentimiento de otros autores,
los permisos de marcadores y los reintentos de importación. Para usar una
instalación externa de PGlite, define `MAREA_PGLITE_MODULE` con la ruta de su
módulo. Las pruebas de Flutter viven en `test/features/tours` y
`test/features/ar_markers`. Las del JPEG están en
`supabase/functions/tour-import/panorama_test.ts`.

## Importación directa de un JPEG 360°

La ruta nueva de «Subir panorámica» puede usar una sola foto 360° esférica
completa. El original se sube al bucket privado `tour-inputs`. La función
`tour-import` comprueba el JPEG y sus metadatos GPano, quita los metadatos
de la copia para el visor y registra en la base de datos un resultado listo.
El visor usa esa copia sin que se reasignen o recompriman los píxeles. El autor
todavía revisa el panorama, lo adjunta y decide cuándo publicar el recorrido.

El límite es 32 MiB y 8192 × 4096 píxeles. La revisión en el visor sigue siendo
necesaria para comprobar la costura y la cobertura. Las tomas con guía y las
importaciones horizontales siguen usando el flujo de procesamiento existente.
Una importación esférica que siga en cola y no haya comenzado se puede completar
desde el teléfono con «Terminar subida de la foto 360°».

Para habilitarla en un proyecto hay que aplicar
`20261119062601_direct_sphere_import.sql`, desplegar `tour-import` con la
configuración de `supabase/config.toml` y actualizar la app. Las pruebas
locales no publican imágenes ni modifican producción.

El 19/11/2026 se aplicó esa migración en `alxdipzfunbpaywmpndi` y se desplegó
`tour-import` v1. Se confirmó que sus dos RPC solo permiten ejecución al rol
del servidor y que la función rechaza solicitudes sin sesión. El OPPO recibió
`build/production-local/marea-direct-sphere-import-debug.apk` con `adb install -r`.
Antes de abrir Marea se compararon 37 archivos persistentes y todos conservaron
su contenido. Queda pendiente una subida real desde la galería del autor.
