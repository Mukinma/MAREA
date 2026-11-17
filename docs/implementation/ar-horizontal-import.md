# Importación de panorámicas horizontales

## Vista local 360°: 16 de noviembre de 2026

Las esferas importadas y validadas pueden explorarse antes de subirlas: tocar la foto o el icono **Ver en 360°** abre una vista a pantalla completa. El usuario puede arrastrar para mirar alrededor, al techo y al piso. El visor usa los bytes del almacenamiento local, sin URL remota, cámara ni sensores de orientación; volver conserva el archivo y la sesión. Si cambia la cuenta, la vista deja de mostrar el archivo anterior. Las panorámicas horizontales mantienen su desplazamiento lateral y no reciben un visor esférico.

El piloto conserva desactivada la subida. La prueba automática verifica movimiento real del visor en ambos ejes y apertura/regreso sin guardados ni llamadas de subida. Pasaron 227 pruebas de recorridos, marcadores y proximidad, el análisis terminó sin incidencias y la APK debug del piloto compiló.

Se instaló `marea-panorama-local-debug.apk` en el OPPO y se abrió la imagen del restaurante importada por el usuario (4096 × 2048, con GPano). Se comprobó la representación esférica real y el cambio de vista mediante gestos ADB horizontales y verticales, con capturas de pantalla antes/después. La comparación de los 242 archivos locales antes y después de instalar no encontró cambios ni pérdidas. La vista quedó abierta para la revisión del usuario, sin habilitar subidas ni modificar producción. El respaldo y la evidencia privados están indicados por `.dart_tool/ar-live-pilot/latest-local-panorama-update.txt`. Esto comprueba el visor de una imagen ya panorámica, no la unión pendiente de las 36 fotos.

El usuario confirmó después: **«Sí quedó todo ya, me gustó cómo quedó»**, y autorizó subir e integrar los cambios. Esta confirmación corresponde al visor local de la panorámica importada; no acredita una publicación remota ni que las 36 fotos sueltas ya estén unidas.

Cambio local del 13 de noviembre de 2026. Se conserva la captura guiada para recorridos completos con techo y piso; se amplía la entrada existente de galería.

## Uso

1. En una posición vacía: **Añadir panorama → Importar desde galería**. Si hay fotos: **Más opciones → Importar desde galería**.
2. Elegir el JPEG panorámico original. Si se sustituye una captura, confirmar el cambio; la sesión anterior y sus JPEG se conservan en **Capturas anteriores**.
3. Una esfera completa con GPano conserva el visor 360°. Las imágenes horizontales muestran **«Panorámica horizontal: desliza de izquierda a derecha. Esta imagen no incluye techo y piso.»** y abren centradas, con desplazamiento hasta los extremos reales de la foto. No hay otro selector de tipo ni se inventa una vuelta completa.
4. **Subir panorámica** requiere una acción expresa y un servidor compatible. El piloto **MAREA Prueba RA** conserva desactivadas todas las subidas; permite guardar y revisar la imagen localmente.

Una imagen 2:1 sin evidencia GPano se trata como imagen horizontal. Los archivos corruptos, dimensiones fuera de límites, orientación EXIF sin normalizar y archivos mayores de 32 MiB siguen rechazándose. Los bytes elegidos se conservan; la vista previa no declara que un recorrido esté publicado o aprobado.

## Contrato y servidor

- Se mantiene `mode: import`; una importación horizontal añade `panorama_kind: horizontal`. Su único frame contiene ID, ruta y dimensiones, sin ángulos ni campo de visión inventados. Las capturas `photos` mantienen sus comprobaciones de esfera completa.
- El worker verifica y decodifica el JPEG, genera tres tamaños conservando su proporción y elimina metadatos de proyección de las salidas horizontales. Devuelve `panorama_kind`, `panorama_width` y `panorama_height` junto a las rutas existentes. Los leases, escritura protegida y recuperación conservan sus reglas.
- La migración aditiva [042_tour_horizontal_panoramas.sql](../../supabase/migrations/042_tour_horizontal_panoramas.sql) acepta ese contrato y conserva el tipo desde el resultado del trabajo validado. No confía en el tipo declarado por un documento editorial. Mantiene propietario, rutas privadas, prueba de imagen RA, revisión, permisos y reglas de publicación.
- Las conexiones de una posición horizontal se recorren desde la lista; no tienen coordenadas esféricas. Sus puntos también permanecen en la lista. El editor omite «Ubicar en 360°» para estas posiciones.
- Antes de crear una captura o subir bytes, el cliente consulta `tours_media_capabilities`. Un servidor antiguo devuelve una explicación de indisponibilidad y conserva el archivo local, sin empezar la subida. No falla silenciosamente después de enviar la imagen.

**No se aplicó la migración ni se desplegó el worker.** Hace falta validar ambos contra una base de desarrollo antes de habilitar la subida remota. Este equipo no dispone de PostgreSQL/Docker para comprobar aquí la migración contra una instancia local. Para una futura puesta en servicio: validar esquema y RPC en desarrollo, actualizar el worker, aplicar la migración y probar una subida/revisión/publicación con cuentas de desarrollo. No ejecutar estas operaciones contra producción como parte de la prueba del teléfono.

## Comprobaciones

Las pruebas de importación verifican clasificación sin falsa esfera, bytes originales, aviso, guardado en historial, cancelación, recuperación tras error y ausencia de subida a servidores antiguos. El visor tiene una prueba de centrado inicial, desplazamiento y límites reales. Las pruebas Python procesan JPEG reales de fixture, conservan la proporción horizontal y verifican que las salidas no pasan por una esfera GPano. Los fixtures son sólo pruebas; no representan el lugar del usuario.

Resultado local: `flutter analyze --no-pub` sin incidencias; **166 pruebas de recorridos** aprobadas; **18 pruebas del worker y siete del procesador local** aprobadas. APK debug compilada en `build/ar-live-pilot/marea-panoramicas-debug.apk`. El respaldo previo a la instalación contiene 196 archivos de recorridos/marcadores, incluida la captura activa de 36 fotos.

La APK se instaló por Wi-Fi en el OPPO CPH2637 con `Success`. Después de instalar se verificaron los 196 hashes: cero archivos cambiados y cero faltantes. Se abrió la galería real de Android desde **Importar desde galería**; queda pendiente la selección y confirmación del usuario para acreditar el visor con su panorámica. La evidencia técnica sin fotos está en `.dart_tool/ar-live-pilot/horizontal-import-install-summary.json`.

La prueba física requiere elegir la panorámica del usuario en el OPPO y confirmar aviso y desplazamiento. Las 36 fotos de la captura anterior y la sesión de 91 fotos siguen conservadas. La unión de esas 36 fotos continúa sin acreditar una esfera completa; importar una panorámica horizontal no la declara reparada.
