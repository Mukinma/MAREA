# Recorridos, marcadores y avisos cercanos — 12 de noviembre de 2026

Esta revisión es local y conserva los cambios y fotos anteriores. No ejecuta migraciones, publicaciones ni escrituras en producción. No incorpora la rama `alan`: el usuario indicó que el mapa de su compañero probablemente todavía no está subido. Los pines del mapa y la RA de imágenes se conservan.

## Probar la captura libre

Perfil → Herramientas → Tus recorridos 360° → editar un borrador → Zonas → añadir o retomar un panorama → **Tomar fotos**. La herramienta de recorridos conserva el acceso para perfiles de creador, emprendimiento o negocio.

**Tomar foto** guarda el JPEG sin exigir un ángulo, estabilidad ni completar la guía. **Terminar fotos** cierra la cámara. La guía, la foto inicial de comparación y la autocaptura son opcionales. El plan orientativo sigue teniendo hasta 40 direcciones; el plan medido del OPPO tiene 36. No limita la cantidad de fotos manuales. Se conserva la importación de JPEG 360° originales; una panorámica horizontal normal no aporta techo y piso.

La preparación posterior del panorama necesita entre 6 y 96 fotos con orientación y lente válidas y conserva las comprobaciones reales del procesador. Las fotos sin esos datos quedan guardadas localmente; no se inventan ángulos ni una esfera completa. Detalles y pruebas de conservación: [captura libre](ar-free-capture.md).

En la APK **MAREA Prueba RA**, la preparación/subida de fotos está desactivada mediante `AppSessionController.allowCaptureUploads=false`. La cámara, las fotos locales y los marcadores locales siguen disponibles. La app normal mantiene su flujo de preparación; esta restricción es específica del piloto conectado a producción.

## Probar los marcadores de imagen

1. Perfil → Herramientas → **Tus marcadores RA** → **Añadir marcador**.
2. Elegir una imagen desde la galería, escribir nombre, información y, opcionalmente, enlace al menú. Indicar el ancho real de la imagen que verá la cámara, en centímetros. Guardar.
3. En las opciones del marcador elegir **Probar RA**. Abrir la cámara y apuntar a la misma imagen impresa o mostrada en otra pantalla. Usar una imagen con detalles y contraste; no un rectángulo uniforme.
4. La tarjeta sólo aparece con reconocimiento nativo real y sigue la perspectiva de la imagen. Se oculta con el estado de pérdida o al pasar 600 ms sin seguimiento. Tres segundos continuos acreditan la prueba de esa versión; abrir la cámara o esperar sin reconocer no la acredita.
5. Tocar la tarjeta abre su información y enlace y libera la cámara. Cerrar el panel y abrir la cámara requiere un reconocimiento nuevo.
6. **Editar** conserva el contenido. Cambiar imagen o ancho invalida la prueba anterior. **Eliminar** pide confirmación y borra el marcador y su imagen local, sin borrar la cuenta ni los recorridos.

Por defecto el CRUD es **privado y persistente en este dispositivo**, separado por cuenta. No aparece automáticamente en otros teléfonos ni se publica al guardar. No requiere nuevas tablas remotas. Sus imágenes y metadatos se guardan juntos; el cierre de sesión no permite leer ni editar los de otra cuenta.

Para sincronización entre dispositivos está preparado `SupabaseMarkerRepository` y [041_ar_markers.sql](../../supabase/migrations/041_ar_markers.sql). **La migración no se ha ejecutado ni validado contra PostgreSQL**. Antes de activar `--dart-define=AR_MARKERS_REMOTE=true`, un responsable debe probar y aplicar el esquema en una base de desarrollo aprobada. Incluye RLS, bucket privado, referencias versionadas y RPC de prueba. Guardar o reconocer no aprueba ni publica; la activación pública queda sujeta a revisión. En remoto el cliente no puede activar esa publicación con un interruptor.

La entrada existente **Mapa → Misión → Explorar en RA** conserva sus condiciones: mismo organizador, recorrido público y referencia actual con reconocimiento comprobado. Los marcadores independientes no evitan esas condiciones.

## Probar avisos a 20 metros en Android

1. Para un marcador propio, guardar su ubicación estando físicamente junto a la imagen. Obtener precisión de 20 m o mejor, completar su prueba RA y activar **Notificar cerca** desde su edición.
2. Perfil → Herramientas → **Avisos a 20 metros** → **Activar avisos**. Permitir notificaciones. En los permisos del teléfono permitir ubicación precisa **Todo el tiempo**; regresar y activar de nuevo.
3. Esperar a que indique **Avisos activos** y cuántos lugares se cargaron. Se utilizan Misiones abiertas, vigentes y con ubicación exacta, marcadores propios activados y marcadores remotos publicados cuando esté habilitado el adaptador remoto.
4. Alejarse más de 30 m y acercarse al lugar. El motor pide distancia calculada de 20 m o menos, precisión GPS de hasta 20 m y muestra reciente. Mantener la app en segundo plano o bloquear el teléfono. Tocar el aviso abre la Misión o el reconocimiento del marcador correspondiente.
5. Se mantiene una notificación de seguimiento con **Detener avisos**. También puede detenerse desde la pantalla de ajustes de MAREA. Cambiar de cuenta o cerrar sesión detiene el seguimiento anterior y limpia sus avisos.

El servicio Android es nativo, persiste la lista descargada y no depende de que Flutter permanezca visible. No sube el recorrido GPS ni guarda credenciales. Los lugares se actualizan mientras MAREA está abierta, alrededor de la ubicación consultada; no descubre Misiones nuevas a distancia ilimitada con la app cerrada. Las Misiones almacenadas dejan de avisar al vencer. Los cambios remotos de moderación se actualizan al volver a sincronizar y el destino vuelve a consultar sus permisos al abrirse.

No se repite un aviso mientras se permanece cerca: salida a 30 m y espera mínima de cinco minutos antes de otro aviso. El radio de 20 m es el umbral de cálculo, no una garantía de precisión física del GPS. En Android reciente, [«Todo el tiempo» se concede en Ajustes](https://developer.android.com/develop/sensors-and-location/location/permissions/background). [Detener la app desde el sistema](https://developer.android.com/develop/background-work/services/fgs/handle-user-stopping), forzar su cierre o las restricciones de batería del fabricante pueden detener el servicio; reabrir MAREA permite revisar y reactivar. La ubicación con app cerrada en iOS queda pendiente y la pantalla lo indica.

## Laboratorio sin producción

`test/manual/proximity_probe.dart` usa dos lugares sintéticos sólo en su APK debug independiente **MAREA Avisos QA** (`com.marea.app.proximityqa`). No inicializa Supabase ni usa cuentas reales. La compilación release/profile está bloqueada para este target. No simula reconocimiento AR.

```powershell
flutter build apk --debug -t test/manual/proximity_probe.dart
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 shell pm grant com.marea.app.proximityqa android.permission.ACCESS_COARSE_LOCATION
adb -s emulator-5554 shell pm grant com.marea.app.proximityqa android.permission.ACCESS_FINE_LOCATION
adb -s emulator-5554 shell pm grant com.marea.app.proximityqa android.permission.ACCESS_BACKGROUND_LOCATION
adb -s emulator-5554 shell pm grant com.marea.app.proximityqa android.permission.POST_NOTIFICATIONS
adb -s emulator-5554 emu geo fix 0 0.001 0 8
adb -s emulator-5554 shell am start -n com.marea.app.proximityqa/com.marea.app.MainActivity
```

Pulsar **Iniciar prueba** y esperar el estado `running: true` antes de ir a Inicio/bloquear. Después ejecutar `adb -s emulator-5554 emu geo fix 0.00001 0.00001 0 8` (a unos 1,6 m de los dos lugares de QA). En este emulador la coordenada exacta 0,0 no entregó una muestra nueva; por eso se usa un punto cercano con ambas coordenadas distintas de cero. Comprobar los avisos de Misión QA y Marcador QA. Finalizar con **Detener y borrar prueba**. No aplicar estos comandos de permisos ni las coordenadas simuladas al teléfono personal.

## Evidencia y pendientes

- **275 pruebas dirigidas aprobadas** de recorridos, captura, mapa, rutas, barra móvil, CRUD, seguimiento de imágenes y proximidad. Análisis Flutter sin incidencias. Logs en `build/ar-live-pilot/modules-20261112-*.log` (ignorados por Git).
- Siete pruebas JVM de proximidad y cinco de orientación Android aprobadas. Incluyen el límite de distancia, precisión, muestras antiguas/desordenadas, antirrebote, rutas y vencimiento.
- La APK principal debug del piloto está en `build/ar-live-pilot/marea-modulos-ra-debug.apk`; el laboratorio aislado en `marea-avisos-qa-debug.apk`.
- En el emulador Pixel 7 se verificó servicio foreground nativo con pantalla apagada y MAREA en segundo plano, recepción de ambos avisos, ausencia de repetición con oscilación cercana y detención con eliminación de preferencias/avisos QA. Los dumps quedan en `build/ar-live-pilot/proximity-qa-*`. Esto no acredita precisión GPS real ni reconocimiento óptico.
- En el OPPO ya se verificaron instalación conservando datos, reanudación y captura libre, creación del marcador desde galería, reconocimiento real, seguimiento de la tarjeta, pérdida de reconocimiento y apertura de información liberando cámara. Sigue pendiente la caminata real de entrada/salida para los avisos y su comportamiento con bloqueo/ahorro de batería.
- Pendiente para compartir marcadores públicamente: base de desarrollo, aplicación/validación de la migración y proceso de revisión. No activar el adaptador remoto sobre producción durante estas pruebas.
- iOS requiere compilación y pruebas de cámara/orientación en macOS y desarrollo del servicio de proximidad correspondiente.

## Instalación inalámbrica en OPPO — 13 de noviembre

Se volvió a vincular el OPPO CPH2637 por ADB inalámbrico. Antes de instalar se respaldaron 101 archivos privados (incluidas imágenes, capturas y sesión) bajo `.dart_tool/ar-live-pilot/capture-backups/20261113T055604Z-wireless-update/`, ignorado por Git. Después de `install -r` se verificaron los hashes de los 99 archivos de recorridos: ninguno faltó ni cambió. La captura anterior aparece con 35 fotos.

Se comprobaron el arranque de MAREA, la sesión de organizador, los nuevos accesos en Herramientas y la pantalla vacía del CRUD local. Durante la navegación automatizada se activó accidentalmente **Preparar panorama**. Se detuvo la app para cortar la operación. La revisión local posterior mantiene 35 fotos, sin `capture_id`, `job_id`, rutas subidas ni checkpoints; únicamente se añadió el campo local `mode`. Una consulta remota de sólo lectura confirmó recorrido en borrador, sin revisión pública y cero entradas de ese propietario en `tour-inputs`. La cuenta ordinaria no puede consultar la tabla privada de capturas, por lo que no se puede descartar un registro vacío de inicio. No se ejecutaron limpiezas, cancelaciones globales ni escrituras de reparación en producción.

Se bloqueó la preparación/subida en el piloto tanto en la interfaz como al entrar en `_send`, con una prueba que verifica que todavía permite tomar y conservar JPEG locales sin llamar al repositorio remoto. No continuar automatizando acciones de envío sobre el piloto. La validación óptica del nuevo CRUD y la caminata real de avisos siguen pendientes del usuario.

La APK corregida compiló y se reinstaló por Wi-Fi con `Success`. El análisis quedó sin incidencias y pasaron las 153 pruebas de recorridos. Se abrió directamente la captura existente mediante el enlace interno: 35 fotos guardadas, **Retomar captura** habilitado, **Preparar panorama** deshabilitado y explicación de almacenamiento local. Se pidió al usuario comprobar manualmente una nueva toma antes de dar por validada la captura física.

El usuario confirmó la foto 36 sin bloqueo por ángulo. La revisión posterior encontró **54 fotos**, verificó los 19 JPEG nuevos y los hashes de las 35 fotos originales sin diferencias, sin captura remota ni trabajo de procesamiento localmente registrados.

Se copió la referencia existente de LAB RA 01 a `Pictures/MAREA-QA` y se creó **MAREA LAB RA 01** desde el formulario y el selector real de fotos de Android. El registro permanece privado en el repositorio local. El usuario confirmó tarjeta visible, apertura de la información al tocarla, seguimiento al mover el teléfono y desaparición al sacar la referencia del encuadre. El archivo local acredita la versión actual con **Android / 3 segundos** de tracking real. AppOps no mostraba la cámara en ejecución después de abrir el panel.

La prueba del guardado detectó un salto del formulario: al sustituir la imagen elegida por la guardada, el estado de espera colapsaba su altura. Se reservó el espacio de vista previa y se verificó que la confirmación queda visible sin volver a desplazar la pantalla. También se corrigió el repositorio local para permitir guardar ubicación precisa y una activación explícita del aviso en la misma operación. Cambiar ubicación sin activar expresamente conserva el aviso desactivado; la imagen comprobada y la precisión siguen siendo obligatorias. Pasaron **51 pruebas de marcadores/proximidad**. La APK se reinstaló y se verificaron los 121 archivos locales de recorridos/marcadores sin cambios tras la instalación.

El marcador de prueba recibió una ubicación real del OPPO con precisión de unos **16 m** y se guardó activo, conservando su prueba de imagen. Se verificaron los permisos de notificaciones, ubicación precisa y ubicación todo el tiempo. El servicio nativo quedó en foreground con un lugar cargado. Android registró **MAREA LAB RA 01** en el canal de avisos cercanos. No se simuló la posición ni se cambiaron los umbrales de distancia/precisión.

El usuario bloqueó la pantalla, volvió a encenderla y confirmó que la notificación existente abría **Reconocer marcador** con la referencia correcta. Esto acredita el aviso inicial con ubicación real y su navegación tras bloqueo; **no acredita todavía una nueva entrada de radio con la app cerrada**. Para esa prueba, alejarse más de 30 m, volver a acercarse a 20 m o menos con pantalla bloqueada y dejar transcurrir al menos cinco minutos desde el aviso anterior. La precisión de las nuevas muestras debe ser de 20 m o mejor. Comprobar también una Misión pública con ubicación exacta cuando exista una realmente cercana; en esta prueba física el único lugar cargado era el marcador privado.

Los avisos quedan activados en el OPPO por la solicitud de seguimiento en segundo plano. Se pueden detener desde **Perfil → Herramientas → Avisos a 20 metros → Detener avisos** o desde la notificación de seguimiento. La evidencia sin coordenadas se guarda en `.dart_tool/ar-live-pilot/wireless-20261113-install-summary.json`, ignorada por Git.
