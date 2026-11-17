# Continuar MAREA en otra laptop

## Estado actual: 16 de noviembre de 2026

Repositorio: `https://github.com/Mukinma/MAREA.git`; rama de este trabajo: **santiago**. El usuario confirmó el visor 360° en el OPPO y autorizó descargar, subir e integrar esta revisión en `main`. Tras descargar el remoto, `main` y `santiago` seguían en `3f51d78` (PR #12), sin divergencia. El PR #11 de Alan tiene conflictos propios y se mantiene separado, sin modificar su rama. No se despliega ni se aplican migraciones.

En VS Code, **MAREA · app principal** ejecuta `lib/main.dart`, sin datos ficticios ni etiquetas del laboratorio. **MAREA · capturas locales · cuentas del piloto** conserva el paquete `com.marea.app.pilot`, las fotos y las restricciones del piloto, pero ahora usa el nombre visible **MAREA**, sin la banda **PRUEBA RA**. El laboratorio sin backend y su imagen **LAB RA 01** permanecen exclusivamente en `test/` y `tool/`: cambiar esa imagen invalidaría las pruebas ópticas anteriores. No se renombran ni eliminan registros remotos para limpiar la presentación.

- **Captura:** se conserva el cubo y se corrige la animación para no volver al centro entre cuadros de una misma cara. Giro e inclinación vuelven a mostrarse por defecto y un aro verde indica alineación con una lectura reciente. El frente se referencia a la primera foto, sin reescribir poses. El disparador manual sigue libre, incluso sin sensor o fuera de la guía. Las sesiones anteriores se conservan. Véanse [captura libre](ar-free-capture.md) y [guía del cubo](ar-cube-guide.md).
- **Fotos actuales:** una captura nueva de 36 fotos; las sesiones anteriores de 91, 36 y 3 fotos se conservan en el historial. Una escena distinta contiene la panorámica del restaurante importada por el usuario (4096 × 2048, GPano). El último respaldo indicado por `.dart_tool/ar-live-pilot/latest-local-panorama-update.txt` verifica 242 archivos originales sin cambios ni pérdidas. Conservar también los respaldos indicados por `latest-image-test.txt` y `latest-cube-angles-update.txt`. No usar el antiguo ZIP del 9 de noviembre como único respaldo.
- **Unión de las 36 fotos: SIN RESOLVER.** Hugin encontró grupos de 20, 7 y 6 fotos, más tres aisladas. Se renderizaron sectores parciales de la cocina (OpenCV), sala y entrada (Hugin). El grupo de 20 falló en Enblend; no hay un panorama completo listo ni publicado. Estos resultados privados están bajo la carpeta indicada por `.dart_tool/ar-live-pilot/latest-image-test.txt`. El mosaico antiguo rechazado sigue retirado y se conservan las validaciones de lente y cobertura.
- **Marcadores:** CRUD privado local y reconocimiento nativo real probados en el OPPO. El usuario confirmó que la tarjeta sigue la imagen, desaparece al perderla y abre información liberando la cámara. El adaptador remoto sigue desactivado por defecto.
- **Avisos Android:** ubicación real, aviso inicial del marcador y apertura tras bloqueo comprobados. Falta validar una nueva entrada desde fuera del radio con la app en segundo plano y probar una Misión pública realmente cercana. [Estado y procedimiento](ar-three-modules.md).
- **Panorámicas de galería:** admiten esfera GPano o imagen horizontal con aviso y visor lateral. Una esfera importada se explora localmente tocando la imagen o **Ver en 360°**. Se comprobó en el OPPO con la panorámica del restaurante y gestos en ambos ejes; el usuario confirmó que funciona y le gustó el resultado. No se subió al servidor. Esto valida el visor, no la unión de las 36 fotos. [Contrato y evidencia](ar-horizontal-import.md).
- **Servidor:** migraciones 041 y 042 preparadas, sin aplicar. La APK piloto mantiene desactivadas las subidas. No activar el adaptador remoto, colas, workers o cambios de esquema sobre producción para continuar estas pruebas. iOS requiere compilación y validación en macOS.

Comprobaciones del 16 de noviembre: `flutter analyze --no-pub` sin incidencias y 227 pruebas Flutter de recorridos, marcadores y proximidad aprobadas, incluidas las pruebas nuevas de animación, guía sin restricciones, visor local y ausencia de subidas. La APK piloto `marea-panorama-local-debug.apk` compiló, se instaló en el OPPO y pasó la comprobación de conservación de los 242 archivos. El visor esférico respondió a gestos horizontales y verticales y recibió confirmación del usuario. La compilación no acredita la unión pendiente de las 36 fotos ni una publicación en el backend. Las comprobaciones del 14 de noviembre incluyeron además 310 pruebas Flutter, 32 Python y 14 nativas Android.

Para retomar en otra laptop con un clon **sin cambios pendientes**:

```powershell
git fetch origin
git switch santiago
git pull --ff-only origin santiago
flutter pub get
```

Si hay trabajo local, conservarlo antes de actualizar; no usar reset, clean ni push forzado. Las fotos, sesiones, configuración privada y firma debug deben transferirse por separado. Además de los archivos indicados abajo, conservar los respaldos actuales de `.dart_tool/ar-live-pilot/capture-backups/` y, para investigar la unión, `.dart_tool/ar-live-pilot/processing/`. Permanecen fuera de Git. El teléfono conserva sus fotos: actualizar con la misma firma y `install -r`, sin desinstalar.

Prompt actual para continuar:

> Continúa desde el estado del 16 de noviembre de docs/implementation/continue-on-another-laptop.md. Conserva los cambios de todos los colaboradores, la captura nueva de 36 fotos, sus sesiones anteriores y la panorámica del restaurante importada en otra escena. El visor local 360° de esa panorámica fue confirmado por el usuario; no se subió ni publicó. La unión de las 36 fotos sigue sin resolver: sólo hay sectores parciales y el mosaico antiguo rechazado permanece retirado. La guía del cubo ahora muestra giro/inclinación y una señal visual de alineación sin bloquear el disparador. Conserva poses reales, reglas de publicación y reconocimiento nativo. Los respaldos privados y evidencias están indicados por latest-local-panorama-update.txt, latest-cube-angles-update.txt y latest-image-test.txt bajo .dart_tool/ar-live-pilot/. No escribas en producción ni actives migraciones/colas/workers. Comprueba Git, Flutter, configuración privada, firma debug y respaldos antes de instalar. No hagas nuevos commits o push sin autorización en la nueva sesión.

## Instalación y antecedentes del 9 de noviembre

La integración de la navegación reciente de `main` con RA y los pasos para que cada colaborador continúe en su rama están en [Integración con main](ar-main-integration.md). Usar siempre una copia actualizada de la rama al retomar.

Las instrucciones de herramientas y firma que siguen continúan siendo útiles. Los registros de **35 de 36** tomas al final son antecedentes del 9 de noviembre, no el estado actual. Consultar el apartado anterior y [Simplificación de captura y RA](ar-simplification.md) para la revisión nueva.

## Instalar las herramientas

1. Instalar Git y **Visual Studio Code**. Para Android no se necesita el IDE Visual Studio completo. La [guía oficial de Flutter con VS Code](https://docs.flutter.dev/install/with-vs-code) reúne la instalación de Git, VS Code, la extensión Flutter y el SDK. La extensión Flutter también instala Dart.
2. Instalar la extensión **Codex de OpenAI** siguiendo el enlace de instalación de la [documentación oficial de Codex](https://learn.chatgpt.com/docs/codex/ide). Abrir su panel e iniciar sesión. Si no aparece, ejecutar **Codex: Open Codex Sidebar** desde la paleta de comandos.
3. Instalar Flutter y agregar su carpeta `bin` al PATH. Este trabajo se verificó con **Flutter 3.47.9 / Dart 3.13.7**. Para reproducirlo, usar esa versión del [archivo oficial de SDK](https://docs.flutter.dev/install/archive) o comprobar cuidadosamente las pruebas con otra compatible con `pubspec.yaml`.
4. Para el teléfono Android, preparar Android Studio y su SDK siguiendo la [configuración oficial de Android para Flutter](https://docs.flutter.dev/platform-integration/android/setup). Instalar las herramientas y licencias indicadas por `flutter doctor`.
5. Instalar Node.js para los scripts de diagnóstico y sus pruebas. En esta computadora se verificaron con Node **24.16.0**. Python 3.12 y las dependencias de `processing/tours/requirements.txt` son adicionales para validar/procesar medios; no hacen falta para abrir el laboratorio de RA.

Cerrar y volver a abrir VS Code después de modificar el PATH. En una terminal nueva:

```powershell
git --version
flutter --version
flutter doctor
node --version
```

Si Git sigue sin aparecer y se instaló en su ubicación habitual de Windows, agregar `C:\Program Files\Git\cmd` al PATH. Las rutas del SDK, Android Studio y `android/local.properties` corresponden a cada equipo; no copiar `local.properties` de la laptop anterior.

## Descargar el proyecto

Cuando los cambios estén confirmados en GitHub, desde una carpeta donde quieras guardar el proyecto:

```powershell
git clone --branch santiago https://github.com/Mukinma/MAREA.git
cd MAREA
git status
flutter pub get
code .
```

Si MAREA ya está clonado en la otra laptop, revisar primero sus cambios locales con `git status`. Con una copia limpia:

```powershell
git switch santiago
git pull --ff-only origin santiago
flutter pub get
```

Si hay cambios propios o Git indica divergencia, conservarlos y resolver esa situación antes de actualizar; no usar reset, clean ni push forzado para continuar esta guía. La integración con `main` debe conservar los cambios de ambas ramas; no reemplazar archivos completos para eliminar conflictos.

## Transferir los archivos privados por separado

Estos archivos **no se suben a GitHub**. Copiarlos directamente entre tus equipos por un medio privado, conservando sus rutas relativas dentro del proyecto:

Para este traslado se preparó también un paquete local en `.dart_tool/git-transfer-20261109-012622/private-transfer.zip`, fuera de Git. Contiene los archivos de la tabla, los respaldos de captura y la firma debug. Al descomprimirlo, copiar el contenido de `project/` dentro del clon y trasladar `user-profile/.android/debug.keystore` a la carpeta `.android` del usuario de la otra laptop, conservando primero su firma existente si la tiene. El paquete incluye `LEEME-TRASLADO.txt` y un manifiesto de integridad. Las copias de fotos no se restauran automáticamente en la app: conservarla instalada en el OPPO.

| Archivo o carpeta | Para qué se necesita |
| --- | --- |
| `config/supabase.production.json` | Configuración del backend actual para **MAREA Prueba RA**. Usar sólo las cuentas y borradores del piloto autorizado. |
| `.dart_tool/ar-live-pilot/accounts.json` | Credenciales y sesiones de las dos cuentas ya creadas; es información privada. Necesario sólo para recuperar esos accesos o usar los helpers del mismo lote. |
| `.dart_tool/ar-live-pilot/resources.json` | Registro de los recursos nuevos ya creados. |
| `.dart_tool/ar-live-pilot/capture-backups/` | Respaldos privados de las capturas del teléfono. Incluir el respaldo **`20261107T232004764143Z/`**, que contiene el JSON y las **35 fotos seleccionadas**, con sus bytes verificados. Conservarlo completo y separado de Git. |
| `outputs/ar-live-pilot/` | Plan y verificaciones locales del lote. No editar los IDs propuestos del plan ni volver a crear el lote. |

No copiar todo `.dart_tool`, `build`, `.venv-tours` o el SDK: las dependencias y compilaciones se recrean en el nuevo equipo. `config/supabase.development.json` todavía contiene una plantilla incompleta; el proyecto de desarrollo independiente sigue pendiente. La configuración de ejemplo no conecta al backend actual.

### Conservar la app y sus fotos en el OPPO

Antes de compilar una actualización para el mismo teléfono, es **crítico transferir la clave de depuración de esta computadora** por separado:

```text
Origen Windows:  %USERPROFILE%\.android\debug.keystore
Destino Windows: %USERPROFILE%\.android\debug.keystore
Destino macOS/Linux: ~/.android/debug.keystore
```

La ruta usa el usuario propio de cada equipo. Si la otra laptop ya tiene una clave, conservar una copia de ella antes de sustituirla. Mantener este archivo fuera del repositorio. Android exige una firma compatible para actualizar una aplicación instalada; la ubicación predeterminada de la clave debug está documentada en [firma de aplicaciones Android](https://developer.android.com/studio/publish/app-signing).

Conservar **MAREA Prueba RA** instalada en el teléfono. Sus fotos de captura permanecen en el almacenamiento privado del teléfono; los respaldos anteriores son una copia privada adicional y **no viajan con el clon de GitHub**. Si aparece `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, resolver la firma antes de instalar; desinstalar o borrar los datos de la app eliminaría las tomas locales y su sesión. Tener un respaldo no significa que su restauración en la app ya esté implementada o probada.

La depuración inalámbrica debe vincularse con la nueva laptop usando el flujo de Android. Usar su dirección y puerto actuales; no reutilizar códigos de vinculación anteriores. Las pruebas ya confirmadas de la referencia están en el backend; las fotografías de esta captura aún no se han subido. Antes de retomar, comprobar en el teléfono que mantiene el contador **35 de 36** y su foto guía, sin empezar una captura nueva.

## Recuperar la lámina y ejecutar

Desde la raíz, después de `flutter pub get`:

```powershell
dart run tool/ar_reference.dart
# Vuelve a crear outputs/ar-local/reference.png y print.html.

flutter devices
```

En VS Code seleccionar el teléfono y una de estas configuraciones de ejecución:

- **MAREA Prueba RA · base actual · cuentas del piloto**: aplicación real, paquete `com.marea.app.pilot`, requiere la configuración privada transferida. Conservar las cuentas existentes y su contenido privado de prueba.
- **MAREA RA local · sin backend**: laboratorio con datos de prueba y reconocimiento nativo real, paquete `com.marea.app.arqa`, no necesita configuración Supabase.
- **MAREA Desarrollo · piloto con backend**: requiere un proyecto Supabase independiente configurado; la plantilla actual se rechaza deliberadamente.

Para compilar el piloto real desde terminal:

```powershell
flutter build apk --debug -t test/manual/business_ar_live_probe.dart --dart-define-from-file=config/supabase.production.json
```

La salida es `build/app/outputs/flutter-apk/app-debug.apk`. Para ejecutarlo en un teléfono conectado, usar `flutter run --debug -d ID_DEL_TELEFONO -t test/manual/business_ar_live_probe.dart --dart-define-from-file=config/supabase.production.json`.

No ejecutar otra vez `accounts.mjs --create-new-accounts` ni `drafts.mjs --create-new-drafts`: el lote ya existe. Las condiciones de publicación, permisos y reconocimiento siguen aplicándose.

## Registro histórico del 9 de noviembre (no usar como estado actual)

Abrir esta guía y `docs/implementation/ar-development-pilot.md` en VS Code. Se puede iniciar el nuevo chat con:

> Continúa MAREA desde docs/implementation/continue-on-another-laptop.md, ar-simplification.md y ar-development-pilot.md. Conserva mis cambios locales y los de los demás colaboradores. No hagas nuevos commits, push, despliegues ni cambios de esquema sin que te lo pida. El piloto de producción sólo permite operar sobre las cuentas y recursos nuevos del lote ra-20261102-8e2d4e; conserva los datos existentes. La referencia LAB RA 01 ya tiene reconocimiento observado y prueba persistida en el OPPO. La captura calibrada conserva 35 de 36 fotos y sólo falta el techo. La nueva guía superpone la primera foto a la cámara en vivo y ya está instalada; falta que el usuario confirme físicamente esta alineación y complete la última foto. El parpadeo anterior sí quedó corregido y confirmado en el teléfono. No reinicies la captura ni des por terminados el panorama, su importación real, su procesamiento o el flujo público. Revisa primero Git, Flutter, la configuración privada, la firma debug y el respaldo .dart_tool/ar-live-pilot/capture-backups/20261107T232004764143Z/ para conservar sesión y fotos. No inicies workers, colas o limpieza globales. No imprimas credenciales ni vuelvas a crear las cuentas o los borradores del lote.

Estado físico verificado: **35 de 36 tomas guardadas** en el OPPO; falta el techo. Las selecciones coinciden con el respaldo privado `20261107T232004764143Z/`. La captura automática ya funcionó en el teléfono. Tras guardar una foto, la app solicita una vibración del sistema; su percepción depende del dispositivo. La corrección del parpadeo al retomar fue confirmada por el usuario: la foto guía permanece fija entre actualizaciones de sensores.

La APK con la **foto guía superpuesta a la cámara en vivo** compiló y se instaló como actualización en el OPPO. Se comprobó la superposición, el contador **35 de 36** y el botón visible **Continuar con este encuadre**. Para retomar, volver al mismo punto y comparar los elementos de la foto con la cámara; no hace falta una coincidencia perfecta de cada píxel. Ese botón confirma el encuadre para reanudar la guía; no guarda por sí mismo la foto del techo. **Sigue pendiente que el usuario confirme la nueva alineación y capture el techo real.**

La última revisión pasó `flutter analyze --no-pub`, **126 pruebas de recorridos** y compilación/instalación Android; las nueve pruebas de la foto guía incluyen superposición, lectura estable y controles alcanzables con texto ampliado. El laboratorio tuvo una prueba manual de RA reportada satisfactoria; la referencia propia del piloto tuvo reconocimiento observado y reporte comprobado en el backend. Las pruebas de widgets no sustituyen la siguiente comprobación física de alineación.

Aún faltan completar la captura, comprobar la unión óptica y el procesamiento legítimo del panorama, y revisar/publicar el recorrido y la Misión para probar todo el flujo público real. La importación desde galería también necesita una prueba con un panorama auténtico: la lámina de RA o una imagen plana 2:1 no acreditan una esfera 360°. **No se ha ejecutado un worker ni se han subido estas 35 fotos para procesarlas.** No pulsar **Subir y procesar panorama** hasta comprobar el procesador legítimo y el alcance autorizado del lote.

Para repetir las comprobaciones:

```powershell
flutter analyze --no-pub
flutter test test/features/tours
node --test test/tool/ar_live_pilot_*_test.mjs test/tool/ar_pilot_*_test.mjs
```

Estos comandos de pruebas no aprovisionan las cuentas del piloto ni procesan una cola remota.

La integración del 9 de noviembre con `main` (`c9b56d7`) conserva el diseño reciente del equipo. El análisis quedó limpio y pasaron las 199 pruebas de recorridos/mapa/rutas/barra y 79 de Node. La suite completa aprobó 699 y omitió dos; los 17 fallos restantes se reprodujeron exactamente en el `main` de referencia. El detalle está en [Integración con main](ar-main-integration.md). Esta integración de Git no añade una prueba física de la última foto del techo.
