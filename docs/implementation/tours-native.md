# Canales nativos de recorridos

Android registra los canales desde `MainActivity` sin reemplazar el canal de notificaciones. iOS usa el registro del motor implícito de Flutter. AR es opcional, con permiso de cámara solicitado al iniciar una vista; permiso denegado, referencia ilegible o soporte ausente emiten un error que deja disponible la lista de paradas.

`marea/tour_motion`: `start`, `stop`, `cameraInfo`. Eventos `yaw,pitch,roll,timestamp` en grados y milisegundos Unix. El eje óptico posterior es −Z del dispositivo. Android usa RotationVector, cámara en ENU y yaw `atan2(-R[2],-R[5])`, pitch `asin(-R[8])`. iOS invierte el quaternion de CoreMotion (referencia→dispositivo) antes de transformar el eje óptico. Se resta solamente yaw inicial; el pitch conserva horizonte 0, cenit +90 y nadir −90. En un inicio exactamente polar se difiere el origen azimutal hasta que resulte definido. La captura Flutter bloquea portraitUp; el eje óptico no cambia al rotar la pantalla. Roll se expresa en los ejes físicos de esa captura en retrato.

`cameraInfo` recibe `{cameraName,imageWidth,imageHeight}`. Las dimensiones corresponden a un JPEG de calibración con EXIF ya aplicado, tomado con la misma cámara posterior principal a zoom 1× y preset que las fotografías finales. La foto de calibración no cuenta como toma aceptada. Se devuelve `{hfov,vfov,aspectRatio,width,height,cameraName}` para la imagen final en retrato, no el preview. Android obtiene apertura física, focal, área activa y píxeles de CameraCharacteristics, y aplica el recorte a la proporción real del JPEG. Rechaza orientación de sensor no convencional y cámaras de focal múltiple ambiguas. iOS usa la cámara builtInWideAngle identificada por uniqueID, su activeFormat.videoFieldOfView, zoom 1× y la proporción del JPEG. Falta de datos produce camera_info_unavailable; nunca se usa un FOV constante de respaldo. El FOV requiere verificar en dispositivos posibles recortes/correcciones del ISP de fotografía frente a vídeo.

`marea/tour_ar` devuelve `supported`. La vista `marea/tour_ar_view` recibe `{references:[{id,path,widthMeters}]}` con JPEG local y ancho físico positivo. Android usa ARCore 1.56 AugmentedImageDatabase; renderiza la cámara con textura OES y coordenadas de ARCore, y una señal verde situada en un anchor real. Solo TRACKING + FULL_TRACKING + cámara TRACKING emite `tracking`; LAST_KNOWN_POSE, PAUSED o STOPPED emiten `lost`. iOS usa ARImageTrackingConfiguration y ARReferenceImage de ancho conocido, ARSCNView y plano verde sobre ARImageAnchor; `isTracked` y pérdida de tracking de cámara gobiernan la confirmación.

El EventChannel `marea/tour_ar/events` emite `{id,state:'tracking'|'lost'|'error',message?}`. Los eventos solo provienen del reconocimiento de las referencias. No hay simulación, botones de reconocimiento ni alineación GPS. Una sola vista AR está activa. Pausa, cancelación de stream y destrucción detienen sensores/cámara; Android destruye el contexto EGL y cierra Session/anchors, iOS pausa la sesión y libera su escena/delegado. Captura Flutter debe liberar su CameraController antes de abrir AR.

Verificación reproducible:

```sh
cd android && ./gradlew :app:testDebugUnitTest
# Desde raíz:
cp ios/NativeTests/orientation.swift /tmp/main.swift
swiftc ios/Runner/TourOrientation.swift /tmp/main.swift -o /tmp/marea-orientation-test
/tmp/marea-orientation-test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

La orientación y AR requieren una prueba física antes de acreditar `tested_version`: horizonte/cenit/nadir, costura ±180°, volver a abrir captura, JPEG real frente a FOV, referencias con medidas reales, retirar imagen del encuadre, apagar/reanudar pantalla y negar permiso. Las compilaciones y tests matemáticos no acreditan reconocimiento físico ni la calibración óptica del dispositivo.
