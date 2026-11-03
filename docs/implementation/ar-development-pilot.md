# Piloto de RA con backend de desarrollo

## Qué se está preparando

Un proyecto de desarrollo es una segunda base de datos de MAREA, con cuentas, Misiones, fotografías y recorridos propios. Permite probar creación y publicación sin utilizar los datos de la aplicación real.

El laboratorio `MAREA RA local` ya permitió la prueba manual de reconocimiento reportada por el usuario. Este piloto usa la aplicación real, `lib/main.dart`, sus repositorios Supabase y las reglas existentes. No contiene cuentas ficticias en memoria ni simula reconocimiento o publicación.

## Implementado localmente — 2 de noviembre de 2026

- Android **MAREA Desarrollo**, paquete `com.marea.app.dev`, independiente de MAREA y del laboratorio. Banner DESARROLLO, almacenamiento de sesión por entorno/backend y callback `com.marea.app.dev://login-callback`.
- Arranque bloqueado antes de inicializar Supabase si el entorno de desarrollo apunta al host de producción, carece de referencia de comparación, contiene una clave administrativa o conserva enlaces de producción. Los comandos del piloto aplican además la validación estricta de configuración antes de compilar o ejecutar.
- Notificaciones de desarrollo en la bandeja del backend; no se inicializa el gateway FCM de Android. Gradle rechaza defines Firebase en esta variante y bloquea builds release/profile del piloto.
- Validación offline de configuración, preparación de defines ignorados por Git y comprobación complementaria del backend mediante seis GET. No hay login automático, creación de cuentas ni escrituras en ese diagnóstico.
- Validación local de JPEG GPano con el mismo parser del worker. Se preparó `.venv-tours` con las dependencias fijadas de Python; no se instaló Docker, Hugin, Enblend ni Supabase CLI.

Esta preparación inicial no hizo escrituras en producción. Posteriormente, el usuario autorizó un piloto limitado con registros nuevos en la base actual; se documenta abajo. No se hicieron despliegues, commits, push ni cambios de esquema.

## Configuración necesaria

Se creó `config/supabase.development.json` desde la plantilla versionada `config/supabase.development.example.json`. El archivo local está ignorado por Git y conserva marcadores, por lo que los comandos lo rechazan hasta configurarlo.

Se necesitan dos valores de **un proyecto Supabase de desarrollo distinto**:

```json
{
  "SUPABASE_URL": "https://REFERENCIA_DEL_PROYECTO_DE_DESARROLLO.supabase.co",
  "SUPABASE_ANON_KEY": "CLAVE_PUBLICABLE_DEL_PROYECTO_DE_DESARROLLO"
}
```

Usar la URL canónica del proyecto y una clave `sb_publishable_…` o una clave heredada `anon`. Las claves administrativas `service_role` y `sb_secret_…` no pertenecen a Flutter. [Tipos de claves y su ubicación en Supabase](https://supabase.com/docs/guides/getting-started/api-keys).

El guard compara la identidad del proyecto con `config/supabase.production.json` leyendo ese archivo local en memoria; no consulta producción ni imprime sus valores. Si falta esa referencia, se detiene. No copia claves de producción al piloto. Se admiten también endpoints locales literales, incluidos IPv4 de red privada para acceder desde el teléfono; no se aceptan alias arbitrarios ni dominios personalizados.

Antes de usar cuentas reales de prueba, el proyecto independiente necesita:

1. El esquema y las funciones requeridas por esta versión de la app, incluidos recorridos 015, Misiones, mapa y las migraciones posteriores aplicables.
2. Buckets privados, permisos y servicios de backend correspondientes. El preflight HTTP no sustituye la comprobación de migraciones/RLS ni demuestra aislamiento entre usuarios.
3. Términos y privacidad publicados en ese entorno, versiones activas, contacto de soporte y registro habilitado. Una base recién creada empieza con el registro cerrado; aplicar migraciones no proporciona esos textos.
4. Confirmación de correo accesible para las cuentas del piloto. Si se prueba Google, permitir `com.marea.app.dev://login-callback` y `http://localhost:7358` únicamente en la configuración Auth de desarrollo.
5. Un procesador 360° conectado exclusivamente a la cola de desarrollo. Su configuración de servidor debe mantenerse separada de los defines Flutter.

Esta entrega prepara el cliente y los diagnósticos. Todavía no se creó ni aprovisionó ese proyecto remoto. La preparación o aplicación del esquema deberá dirigirse explícitamente al proyecto de desarrollo y respetar la autorización de despliegue del usuario.

**No ejecutar `processing/tours/configure_local.py` para este piloto:** ese script histórico lee explícitamente la configuración de producción y modifica secretos Edge. Tampoco usar comandos `--linked` como sustituto de seleccionar el entorno de desarrollo.

## Comandos del piloto

Desde PowerShell, en la raíz:

```powershell
# Sólo diagnóstico local; no hace conexiones de backend.
powershell -ExecutionPolicy Bypass -File .\tool\ar-pilot.ps1 -Action Doctor

# Validar y generar .dart_tool/ar-pilot/defines.json después de configurar.
powershell -ExecutionPolicy Bypass -File .\tool\ar-pilot.ps1 -Action Prepare

# Comprobación de lectura del proyecto de desarrollo validado.
powershell -ExecutionPolicy Bypass -File .\tool\ar-pilot.ps1 -Action CheckBackend

# Aplicación real con datos del backend de desarrollo.
powershell -ExecutionPolicy Bypass -File .\tool\ar-pilot.ps1 -Action Run -Device ID_DEL_TELEFONO

# Web usa el puerto 7358 para mantener coherente el retorno de autenticación.
powershell -ExecutionPolicy Bypass -File .\tool\ar-pilot.ps1 -Action Run -Device chrome

# Compilar la variante configurada: build/ar-pilot/marea-development-debug.apk.
powershell -ExecutionPolicy Bypass -File .\tool\ar-pilot.ps1 -Action Build
```

VS Code incluye **MAREA Desarrollo · piloto con backend**, con una tarea previa de validación. Los comandos Run y Build se detienen si la configuración no es válida; no tienen fallback a producción. Prepare retira los defines generados anteriores cuando se invalida el archivo local.

El preflight usa metadatos OpenAPI y RPC lectoras. Sin sesión, varias RPC deben rechazar el acceso: el resultado será parcial, no una certificación de que estén ausentes. Opcionalmente admite un token ya existente del usuario de desarrollo en `MAREA_AR_PILOT_USER_TOKEN`, sólo en el entorno del proceso; no realiza login ni guarda el token. Un HTTP 200 no acredita RLS, publicación ni reconocimiento. Los GET de PostgREST ejecutan transacciones de lectura; el diagnóstico no reintenta una operación con POST. [PostgREST: modo de acceso de funciones](https://docs.postgrest.org/en/stable/references/transactions.html#access-mode-on-functions).

## Contenido y aceptación del piloto

Crear las cuentas mediante el registro normal de desarrollo: organizador de tipo creador, emprendimiento o negocio y visitante Usuario general. La cuenta revisora debe tener el rol administrativo establecido legítimamente en ese entorno y ser distinta del autor. No se otorgan permisos desde el cliente ni se sustituye la revisión independiente.

1. Organizador: **Perfil → Herramientas → Tus recorridos 360°**. Crear el recorrido con datos del espacio y una posición válida.
2. Importar un panorama GPano auténtico o capturar/procesar una esfera real; revisar y adjuntar el resultado. Una imagen 2:1 o la lámina plana de RA no constituyen un panorama 360°.
3. Añadir la referencia AR y su ancho físico. Probarla mediante el editor en el teléfono para registrar la versión correspondiente por el flujo existente.
4. Enviar a revisión y publicar mediante las reglas actuales. No insertar `tested_version`, permisos de espacio ni publicaciones con un seeder.
5. Crear una Misión abierta, futura y con coordenadas, del mismo organizador.
6. Visitante: entrar al Mapa en la app de desarrollo, seleccionar esa Misión y abrir RA. Comprobar seguimiento, perspectiva, pérdida de reconocimiento, panel, perfil y Misiones activas.
7. Comprobar nueva sesión tras cerrar el panel, segundo plano, referencia sustituida y recorrido pausado. Registrar actor, versión de referencia, resultado y fallo concreto; no guardar fotos personales, claves ni códigos de vinculación en la evidencia compartible.

## Validar el panorama antes de subirlo

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\ar-pilot.ps1 -Action CheckMedia
powershell -ExecutionPolicy Bypass -File .\tool\ar-pilot.ps1 -Action CheckMedia -File 'C:\ruta\panorama.jpg'
```

El validador sólo lee el archivo local. Rechaza JPEGs sin XMP GPano válido, recortes, dimensiones incoherentes, orientación no normalizada y entradas corruptas. No fabrica metadatos ni acredita calidad óptica.

La importación GPano del worker puede validar/exportar con Python sin Hugin; el ejecutor de cola existente `local_runner.py` sigue requiriendo Docker y credenciales de servidor. No se preparó un nuevo consumidor que reclame trabajos de fotos sin disponer de sus herramientas. Para procesamiento de fotografías faltan Hugin/Enblend o el contenedor existente. En este Windows tampoco está preparado el stack local de Supabase, que necesita CLI y runtime de contenedores. [Desarrollo local de Supabase](https://supabase.com/docs/guides/local-development).

## Verificación de esta preparación

- Flutter: análisis sin incidencias; **148 pruebas aprobadas**, con dos omisiones existentes de la suite, cubriendo configuración, rutas, acceso, recorridos, mapa y herramientas de perfil.
- Node: **33 pruebas aprobadas** de bloqueo de producción, claves, archivos de configuración, redirecciones, tiempo de espera, consultas de lectura, preparación y retirada de defines anteriores.
- Python: **27 pruebas pertinentes aprobadas** del worker y del nuevo validador. La ejecución de las 36 pruebas históricas encontró dos fallos previos de portabilidad en Windows: expectativa de ruta POSIX y ausencia de `bash` en una prueba del publicador de imagen. No se modificaron esas pruebas para ocultar los fallos.
- Compilaron las variantes debug Android normal y de desarrollo. El manifest de desarrollo contiene `com.marea.app.dev`, etiqueta propia y esquema OAuth separado. La compilación de diagnóstico se hizo sin credenciales y no intenta iniciar Supabase.
- Prepare y CheckBackend rechazaron la plantilla incompleta antes de realizar conexiones. No se comprobaron un backend real de desarrollo, cuentas persistidas, panorama real ni publicación completa.

El archivo `build/ar-pilot/marea-development-configuration-debug.apk` es únicamente la compilación de comprobación de la variante: muestra configuración pendiente. La APK funcional del piloto se genera con Build después de conectar el proyecto de desarrollo.

## Piloto autorizado en la base actual — 2 de noviembre de 2026

Después de explicar que la base actual es producción, el usuario autorizó con «hazlo» crear únicamente cuentas y contenido nuevos de prueba. Se usaron el registro y las API normales con sesiones de usuarios ordinarios. Esta autorización no incluye modificar contenido existente, otorgar roles, cambiar el esquema, desplegar ni ejecutar mantenimiento global.

Se creó el lote `ra-20261102-8e2d4e`:

- Dos cuentas nuevas confirmadas por correo: organizador de tipo Negocio y visitante Usuario general, ambas con rol ordinario.
- Recorrido privado `c93d0e50-aa67-4ad6-b8ea-33b5fa1f9bb3`, con la imagen LAB RA 01 subida como referencia nueva y ancho configurado de 20 cm.
- Misión en borrador privado `a9630e65-66db-4dc5-b68d-7b2a739772af`, identificada como prueba técnica sin convocatoria real. No aparece en Misiones abiertas.

La comprobación de lectura de estos recursos confirmó que el organizador puede consultar sus borradores y el visitante no puede leerlos. El recorrido sigue privado y no hay recorrido público del lote. En el OPPO se observó «Imagen reconocida» y posteriormente se verificó en el backend que `tested_version` coincide con la versión actual `fdeda395-6dab-4e11-b88a-1b0d6f091b35`, con `test_kind = user_reported_tracking`. Esta prueba se guardó mediante el flujo nativo de la app; no se copió evidencia del laboratorio. Estos resultados no certifican todo el backend ni la experiencia pública todavía pendiente.

### Aplicación del piloto

**MAREA Prueba RA**, paquete `com.marea.app.pilot`, ejecuta la aplicación y los repositorios reales contra la configuración actual. Usa el target `test/manual/business_ar_live_probe.dart`, banner PRUEBA RA, instalación y sesión independientes, acceso por correo y bandeja de notificaciones. Sólo admite debug; no incorpora contraseñas ni sesiones en la APK. La separación de paquete y sesión no aísla los datos de producción: utilizar exclusivamente las cuentas y borradores de este lote.

VS Code incluye **MAREA Prueba RA · base actual · cuentas del piloto**. Para compilar desde PowerShell:

```powershell
$env:Path = 'C:\Program Files\Git\cmd;' + $env:Path
flutter build apk --debug --no-pub -t test/manual/business_ar_live_probe.dart --dart-define-from-file=config/supabase.production.json
```

La APK compilada se conservó en `build/ar-live-pilot/marea-production-pilot-debug.apk`. Se instaló por Wi-Fi en el OPPO CPH2637; se inició sesión con el organizador y se comprobó el borrador en **Perfil → Herramientas → Tus recorridos 360°**. Al volver del editor se detectó y corrigió una recarga que devolvía un `Future` dentro de `setState`, también presente en reintentos de listas y solicitudes. Tres pruebas cubren estos casos. La APK corregida volvió a instalarse con `Success`; se comprobó el editor, **Puntos y AR**, la referencia remota y el arranque de cámara. Con la APK final se volvió del editor a **Tus recorridos**, donde el borrador siguió visible, sin la excepción anterior en los logs del proceso.

### Continuar este lote

1. Con la cuenta organizadora, abrir **Tus recorridos 360° → Editar borrador → Puntos y AR**. Seleccionar la parada de referencia y pulsar **Probar AR en el local**. Esta prueba puede hacerse antes de disponer del panorama.
2. Para repetir la prueba ya guardada, mostrar en la computadora `outputs/ar-local/print.html` o imprimir la imagen; medir su ancho real y hacerlo coincidir con los 20 cm configurados. Apuntar con el teléfono a la imagen, mantener el reconocimiento al menos tres segundos y guardar la prueba desde la app. No registrar un reporte por script. La medición física del ancho no quedó documentada en esta sesión.
3. Incorporar un panorama 360° auténtico y procesarlo mediante un servicio legítimo. Después seguir las solicitudes y la revisión independiente existentes para publicar el recorrido. La lámina plana de RA no sustituye al panorama.
4. Cuando el recorrido sea público con su referencia probada, preparar la Misión del mismo organizador según el flujo normal y comprobar desde el visitante **Mapa → Misión → Explorar en RA**, seguimiento, panel, perfil y Misiones activas. El borrador privado actual no habilita esa entrada.

Faltan el panorama real, su procesamiento y la revisión legítima. Los ejecutores existentes `local_runner.py`, `tour-dispatch` y las RPC de reclamación gestionan colas o limpieza globales; no iniciarlos bajo la autorización limitada de este lote. No fabricar resultados de procesamiento, `tested_version`, aprobaciones ni permisos. No se cambió ninguna regla de publicación para habilitar el botón.

### Archivos del lote y verificaciones

`tool/ar-live-pilot/plan.mjs` prepara un plan offline; `accounts.mjs` registra sólo cuentas nuevas; `sessions.mjs` confirma mediante códigos recibidos por stdin; `drafts.mjs` crea únicamente nuevos recursos privados. No publican ni cambian roles. **No volver a ejecutar los comandos de creación para continuar este lote**: los journals existentes evitan repetir escrituras.

Los archivos de `.dart_tool/ar-live-pilot/` y `outputs/ar-live-pilot/` están ignorados por Git. El journal de cuentas contiene credenciales y sesiones privadas: no compartirlo ni copiarlo a documentación. El plan conserva IDs propuestos; los helpers emplean los IDs reales del journal y no debe editarse para sustituirlos. `outputs/ar-live-pilot/verification.json` contiene el resultado de lectura de los nuevos recursos, sin contraseñas ni tokens.

La verificación al continuar aprobó **199 pruebas Flutter**, con dos omisiones existentes, de configuración, rutas, autenticación, recorridos, mapa y perfil. Las **79 pruebas Node** de ambos pilotos pasaron. Después se añadió la validación de confirmación del reporte: sus **12 pruebas dirigidas** pasaron, cubriendo respuesta correcta, siete respuestas incongruentes y reintento. `flutter analyze --no-pub` volvió a terminar con **No issues found**. La APK final compiló, se comprobó que contiene la nueva validación, se verificaron paquete/etiqueta y se reinstaló por Wi-Fi con `Success`, conservando la sesión del organizador. El guardado físico confirmado precedió a esta última validación de respuesta; los casos de respuesta incongruente se verificaron mediante pruebas automatizadas.

Las primeras lecturas del recorrido todavía devolvían `tested_version = null`. Tras repetir el reconocimiento, se observó «Imagen reconocida» y el editor pasó a ofrecer «Volver a probar AR». La lectura posterior confirmó la versión probada y se actualizó `outputs/ar-live-pilot/native-reference-verification.json`. No se atribuyó esa diferencia temporal a un fallo del servidor.

Se reforzó `TourARScreen._report`: antes de mostrar éxito debe recibir del servidor el mismo recorrido, propietario, punto, versión, ruta y ancho, con `tested_version` coincidente. Una respuesta incongruente conserva la cámara, muestra un error y permite reintentar. La confirmación comprobada libera la cámara. No se cambiaron SQL ni reglas de publicación.

## Captura guiada en el OPPO — 2 de noviembre de 2026

El usuario abrió **Editar borrador → Zonas → Capturar / retomar → Abrir cámara guiada**. La cámara y la calibración inicial generaron un plan de **67 tomas** en ese dispositivo; el número depende de la lente medida. El usuario encontró **Aceptar toma** deshabilitado. La lectura de accesibilidad mostró `0 de 67 tomas aceptadas`, el objetivo `0° · inclinación 0°` y el botón gris, sin un error de cámara. La pantalla anterior no mostraba orientación actual ni dirección para alcanzar el objetivo; esta evidencia por sí sola no acredita un fallo del sensor.

Se añadió una guía con giro e inclinación actuales, dirección para corregir el encuadre y estado de espera/estabilidad. El botón **Aceptar toma** queda fijo en la parte inferior, accesible aunque se desplace la vista. Las condiciones siguen siendo orientación a menos de 6° del objetivo, al menos 500 ms de estabilidad y una muestra de sensor de hace menos de 300 ms. No se habilita una toma por pulsar un control de diagnóstico.

El nuevo `CaptureMotionGate` reinicia la estabilidad ante una separación de muestras de 300 ms o más, pausa, cambio de objetivo, cambio de cámara y datos no finitos. Un temporizador actualiza la habilitación cuando caduca una lectura, aunque no lleguen nuevos eventos. La alineación al retomar también comprueba que siga activa la misma sesión de cámara antes y después de reiniciar los sensores.

Pasaron **64 pruebas de recorridos**, incluidas las 12 del gate y cuatro del panel de captura; se comprobó el botón con viewport de teléfono y texto ampliado. `flutter analyze --no-pub` terminó sin incidencias y la APK debug compiló. Se verificó que contiene la guía nueva y se reinstaló en el OPPO con `Success`, conservando sesión y captura local (`0 de 67`). La aceptación de la primera toma en el dispositivo está pendiente de la repetición física.

La nueva guía permitió observar orientación actual `giro 56° · inclinación −86°` frente al primer objetivo `0° · 0°`: había muestras de sensor recientes, pero la cámara apuntaba casi al piso. En ese estado el botón debe permanecer desactivado. Se indicó levantar el teléfono vertical y apuntar al frente, seguir la corrección de giro y esperar la estabilidad antes de aceptar. Se distingue así una falta de alineación de un error de cámara o de almacenamiento.

Las fotos aceptadas y el plan se guardan primero en el teléfono. **Capturar / retomar** sincroniza el borrador propio al entrar; abrir la cámara y aceptar fotos no crea un trabajo remoto. Sólo **Subir y procesar panorama** crea la captura remota, sube los JPEG privados y envía el trabajo. Para esta sesión se detendrá la prueba antes de ese botón hasta preparar o comprobar el procesador legítimo. La cámara guiada, el reconocimiento AR y el procesamiento de panoramas son verificaciones distintas.
