# RA del organizador desde el mapa

Implementación inicial sobre `santiago` a9b6712d7acbc0374034b2d7e2b912d720bd1ecd.

## Comportamiento

Seleccionar una Misión en el mapa consulta las experiencias públicas de su organizador. Aparece **Explorar en RA** únicamente si hay al menos una referencia con ruta, ancho físico positivo y `tested_version` igual a una `reference_version` no vacía. Con varias referencias se elige una antes de abrir la cámara.

La pantalla muestra el perfil y la imagen que hay que buscar. La cámara carga solamente esa referencia. ARCore exige cámara e imagen en TRACKING y método FULL_TRACKING; ARKit exige imagen rastreada y cámara normal. Las cuatro esquinas de una tarjeta física se proyectan en cada plataforma y Flutter transforma la tarjeta mediante una homografía. El toque utiliza la misma transformación. La tarjeta contiene el nombre, tipo de perfil e imagen de perfil del organizador; sin avatar se conservan las iniciales habituales de MAREA.

Al perder el seguimiento se oculta. Si el flujo nativo deja de enviar proyecciones durante 600 ms también se oculta. Android e iOS sólo renuevan la proyección cuando llega un fotograma de cámara con timestamp nuevo: renderizar repetidamente el último fotograma no mantiene visible la tarjeta. Cada sesión lleva un identificador para descartar eventos de cámaras anteriores. Un reconocimiento nuevo vuelve a mostrarla.

Tocar la tarjeta detiene y libera la vista de cámara, y abre información pública del perfil y Misiones abiertas, no ocultas y con fecha futura. Las Misiones se consultan por organizador y admiten paginación y reintento. Se utilizan las rutas existentes `/people/:id` y `/missions/:id`. Al cerrar la información o volver de esas rutas se abre una nueva sesión que necesita reconocer de nuevo la imagen. El botón Atrás conserva la selección y posición del mapa.

Salir de la pantalla, cubrirla con otra ruta, cambiar de cuenta o pasar la app a segundo plano cancela la preparación/cámara. Al regresar del segundo plano se ofrece abrir la cámara expresamente.

## Datos necesarios para la prueba

- La migración existente `015_tours.sql` y las RPC de recorridos deben estar instaladas en el entorno. Este cambio no modifica SQL, permisos ni datos de Supabase.
- Una Misión visible en el mapa, con su organizador accesible.
- Un recorrido público de ese mismo organizador, con una parada que tenga imagen de referencia y ancho físico en centímetros.
- Referencia probada y publicada mediante los flujos existentes. Una referencia privada, sin prueba o con versión de prueba anterior no habilita el botón. El autor también consulta la revisión pública, aunque tenga un borrador más reciente.
- La imagen física debe ser la misma que se cargó como referencia. Las imágenes con detalles distintivos y buen contraste suelen reconocerse mejor que logotipos simples. El ancho configurado debe corresponder al real.
- Un teléfono compatible con ARCore/ARKit y permiso de cámara. Web permite consultar la introducción y el perfil; la cámara RA no se habilita allí.

No se crean cuentas, Misiones ni referencias de demostración en producción. La cámara usa un único objetivo seleccionado; no coloca objetos con GPS ni incluye navegación o modelos 3D.

## Laboratorio local sin producción

La entrada normal necesita datos publicados. Un listado vacío no confirma un fallo de RA: el mapa exige Misión abierta, no oculta, fecha futura y coordenadas dentro de la zona y filtros consultados. El panel de información consulta las Misiones de ese organizador y excluye las cerradas, ocultas y vencidas.

En esta versión **Perfil → Herramientas → Tus recorridos 360°** se muestra para creador, emprendimiento y negocio, cuando existe repositorio de recorridos. Usuario general no tiene esa herramienta y tampoco puede abrir el editor mediante un enlace directo. Puede explorar RA y crear Misiones. No se cambia el tipo de ninguna cuenta para probar.

`test/manual/business_ar_probe.dart` permite probar las pantallas y rutas reales con datos ficticios: visitante Usuario general, organizador negocio, Misión futura en el centro de CDMX y recorrido público de ese mismo organizador. La referencia y los mosaicos del mapa se sirven dentro del teléfono por `127.0.0.1:38765`; no necesita conexión con la PC ni un backend. Las peticiones HTTP externas y las escrituras de los repositorios del laboratorio se rechazan. No inicia Supabase ni Firebase y rechaza defines de Supabase.

La publicación y `tested_version` del fixture representan únicamente datos de prueba del contrato público. **No acreditan una prueba física, no llaman `reportAR` y no publican nada.** No hay `cameraBuilder` falso ni eventos de reconocimiento simulados en este laboratorio: la tarjeta sólo aparece con seguimiento nativo real. Los eventos simulados están limitados a pruebas automatizadas.

Android instala el laboratorio como **MAREA RA local**, paquete `com.marea.app.arqa`, independiente de MAREA y sus datos de sesión. Sólo admite debug. El target normal conserva `com.marea.app`; no se modifican sus reglas de publicación, permisos o configuración de red.

Desde PowerShell en la raíz:

```powershell
# Generar la lámina para imprimir (mismos píxeles que usa la cámara).
powershell -ExecutionPolicy Bypass -File .\tool\ar-local.ps1 -Action Reference

# Identificar el teléfono/emulador conectado.
$env:Path = 'C:\Program Files\Git\cmd;' + $env:Path
flutter devices

# Sustituir el ID por el devuelto por flutter devices.
powershell -ExecutionPolicy Bypass -File .\tool\ar-local.ps1 -Action Run -Device emulator-5554
```

El script encuentra Git en las ubicaciones habituales y ajusta el PATH únicamente de su proceso. En este equipo Git está instalado en `C:\Program Files\Git\cmd` pero no venía en PATH. Flutter está en `C:\dev\flutter\bin`. Para que `git` funcione también en nuevas terminales de VS Code, agregar su carpeta `cmd` al PATH de Windows y reiniciar VS Code. También se añadió la configuración **MAREA RA local · sin backend** a `.vscode/launch.json`.

Para compilar sin arrancar:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\ar-local.ps1 -Action Build
# APK: build/ar-local/marea-ar-local-debug.apk
```

La lámina está en `outputs/ar-local/reference.png`; abrir `outputs/ar-local/print.html` e imprimir al 100%, sin ajustar a página. Medir **20 × 15 cm**, mantenerla plana y sin reflejos. El arte es reproducible y tiene detalles asimétricos; su calidad óptica y facilidad de reconocimiento aún deben medirse con un teléfono. La recomendación oficial es usar referencias con suficientes rasgos únicos ([Augmented Images](https://developers.google.com/ar/develop/augmented-images)).

1. Abrir el laboratorio y tocar el marcador del centro del mapa. No usar el botón de ubicación: la Misión ficticia está en CDMX.
2. Pulsar **Explorar en RA**; comprobar organizador y referencia.
3. Pulsar **Abrir cámara**, conceder permiso y apuntar a la lámina. Una referencia incorrecta no debe mostrar tarjeta.
4. Mover/rotar el teléfono y comprobar perspectiva y toque de la tarjeta.
5. Tocar la tarjeta: comprobar información pública, Misión activa y navegación al perfil y al detalle. La cámara debe quedar liberada mientras está abierto el panel.
6. Regresar: no debe aparecer tarjeta hasta reconocer otra vez. Tapar/retirar la lámina, interrumpir cámara o pasar a segundo plano debe ocultarla. Probar permiso denegado y volver al Mapa.

El laboratorio permite probar la lectura del flujo; el editor, revisión independiente, procesamiento de panoramas y publicación con RLS requieren un backend de desarrollo propio y sus recursos. No hay configuración de desarrollo disponible aquí; la de producción no se utiliza para esta prueba.

## Validación local — 30 de octubre de 2026

Git 2.51.0, Flutter 3.47.9 y Dart 3.13.7 accesibles después de corregir el PATH del proceso. `flutter analyze --no-pub`: **No issues found**. Suite de recorridos, mapa, herramientas de perfil y router: **90 pruebas aprobadas**, incluidas las siete de `business_ar_test.dart`, las catorce de entrada RA/permisos y tres del fixture/aislamiento. Kotlin: cinco pruebas aprobadas, incluidas dos de timestamps repetidos y sesiones independientes. APK debug del laboratorio y del target normal compiladas; identificadores y nombres comprobados con `aapt`. El intento de configurar una compilación release del laboratorio se rechazó como estaba previsto.

En `emulator-5554` se instaló la APK independiente y se comprobó Mapa → Misión → introducción de RA con referencia local visible y perfil del organizador. El emulador devolvió compatibilidad RA negativa y dejó **Abrir cámara** deshabilitado, por lo que no se validaron reconocimiento, perspectiva, toque sobre imagen ni liberación física de cámara allí. No se conectó ningún teléfono. Esos casos siguen pendientes en hardware compatible; los tests automatizados verifican su lógica con eventos de prueba, sin acreditar el comportamiento óptico.

Las pruebas añadidas detectaron y cubren dos correcciones Dart: el reintento de consulta ya no devuelve un `Future` dentro de `setState`; reintentar la imagen cancela la preparación pendiente y permite abrir cámara de nuevo. Si no hay Misiones activas, el panel lo indica expresamente.

Para repetir las comprobaciones Flutter:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\ar-local.ps1 -Action Test

# Pruebas nativas Android (desde android/).
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
.\gradlew.bat :app:testDebugUnitTest '-Ptarget=test/manual/business_ar_probe.dart' --console=plain
```

Los cambios nativos necesitan detener y volver a ejecutar la aplicación; hot reload no basta. iOS necesita compilación con Xcode en macOS. No se atribuye el fallo histórico del lector de logs al AR: el registro citado era de Bluetooth y no prueba esa relación.

Probar: referencia correcta/incorrecta; alejar y volver a encuadrar; mover y rotar el teléfono; tocar la tarjeta desde distintas perspectivas; Misiones vigentes/vencidas/ocultas; cerrar y volver del perfil; denegar cámara; desconectar red durante descarga; salir mientras descarga; segundo plano; cambio de cuenta; volver al mapa; referencia pausada o sustituida antes de abrir cámara. Conservar la revisión pública y las restricciones RLS existentes.

Referencia técnica: https://developers.google.com/ar/develop/java/augmented-images/guide
