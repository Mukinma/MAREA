# Continuar MAREA en otra laptop

Guía preparada el 2 de noviembre de 2026. Repositorio: `https://github.com/Mukinma/MAREA.git`; rama de este trabajo: **santiago**. Los comandos de clonación deben usarse después de confirmar que se subió el trabajo pendiente a esa rama.

La integración de la navegación reciente de `main` con RA y los pasos para que cada colaborador continúe en su rama están en [Integración con main](ar-main-integration.md). Usar siempre una copia actualizada de la rama al retomar.

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

Si MAREA ya está clonado en la otra laptop, revisar primero sus cambios locales con `git status`. Con una copia limpia, seleccionar `santiago` y actualizar con `git pull --ff-only origin santiago`. Si hay cambios propios o Git indica divergencia, conservarlos y resolver esa situación antes de actualizar; no usar reset, clean ni push forzado para continuar esta guía.

## Transferir los archivos privados por separado

Estos archivos **no se suben a GitHub**. Copiarlos directamente entre tus equipos por un medio privado, conservando sus rutas relativas dentro del proyecto:

| Archivo o carpeta | Para qué se necesita |
| --- | --- |
| `config/supabase.production.json` | Configuración del backend actual para **MAREA Prueba RA**. Usar sólo las cuentas y borradores del piloto autorizado. |
| `.dart_tool/ar-live-pilot/accounts.json` | Credenciales y sesiones de las dos cuentas ya creadas; es información privada. Necesario sólo para recuperar esos accesos o usar los helpers del mismo lote. |
| `.dart_tool/ar-live-pilot/resources.json` | Registro de los recursos nuevos ya creados. |
| `outputs/ar-live-pilot/` | Plan y verificaciones locales del lote. No editar los IDs propuestos del plan ni volver a crear el lote. |

No copiar todo `.dart_tool`, `build`, `.venv-tours` o el SDK: las dependencias y compilaciones se recrean en el nuevo equipo. `config/supabase.development.json` todavía contiene una plantilla incompleta; el proyecto de desarrollo independiente sigue pendiente. La configuración de ejemplo no conecta al backend actual.

### Conservar la app y sus fotos en el OPPO

Antes de compilar una actualización para el mismo teléfono, transferir también **la clave de depuración de esta computadora**:

```text
Origen Windows:  %USERPROFILE%\.android\debug.keystore
Destino Windows: %USERPROFILE%\.android\debug.keystore
Destino macOS/Linux: ~/.android/debug.keystore
```

La ruta usa el usuario propio de cada equipo. Si la otra laptop ya tiene una clave, conservar una copia de ella antes de sustituirla. Mantener este archivo fuera del repositorio. Android exige una firma compatible para actualizar una aplicación instalada; la ubicación predeterminada de la clave debug está documentada en [firma de aplicaciones Android](https://developer.android.com/studio/publish/app-signing).

Conservar **MAREA Prueba RA** instalada en el teléfono. Sus fotos de captura permanecen en el almacenamiento privado del teléfono, no en GitHub. Si aparece `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, resolver la firma antes de instalar; desinstalar o borrar los datos de la app eliminaría las tomas locales y su sesión.

La depuración inalámbrica debe vincularse con la nueva laptop usando el flujo de Android. Usar su dirección y puerto actuales; no reutilizar códigos de vinculación anteriores. Las pruebas ya confirmadas de la referencia están en el backend, pero las fotografías aún no subidas siguen sólo en el teléfono.

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

## Punto exacto para retomar con Codex

Abrir esta guía y `docs/implementation/ar-development-pilot.md` en VS Code. Se puede iniciar el nuevo chat con:

> Continúa MAREA desde docs/implementation/continue-on-another-laptop.md y ar-development-pilot.md. Conserva mis cambios locales. No hagas commits, push, despliegues ni cambios de esquema sin que te lo pida. El piloto de producción sólo permite operar sobre las cuentas y recursos nuevos del lote ra-20261102-8e2d4e; conserva los datos existentes. La referencia LAB RA 01 ya tiene reconocimiento observado y prueba persistida en el OPPO. Falta comprobar la primera toma del panorama con la guía actualizada y preparar su procesamiento legítimo, sin iniciar colas o limpieza globales. Revisa primero Git, Flutter, configuración y firma debug para conservar la sesión y las fotos del teléfono. No imprimas credenciales ni vuelvas a crear las cuentas o los borradores del lote.

Estado de la captura: el OPPO generó un plan de 67 tomas. Se corrigieron la guía de dirección, visibilidad del botón y continuidad de sensores; la última lectura mostraba `0 de 67`, con inclinación −86° ante un objetivo 0°/0°. Se pidió sostener el teléfono vertical, apuntar al frente y confirmar la primera toma. No darla por guardada sin comprobar el contador.

El último cambio pasó `flutter analyze --no-pub`, 64 pruebas de recorridos y compilación/instalación Android. El laboratorio tuvo una prueba manual de RA reportada satisfactoria; la referencia propia del piloto tuvo reconocimiento observado y reporte comprobado en el backend. Aún faltan captura completa, procesamiento de panorama, revisión y publicación del recorrido/Misión para probar todo el flujo público real.

Para repetir las comprobaciones:

```powershell
flutter analyze --no-pub
flutter test test/features/tours
node --test test/tool/ar_live_pilot_*_test.mjs test/tool/ar_pilot_*_test.mjs
```

Estos comandos de pruebas no aprovisionan las cuentas del piloto ni procesan una cola remota.
