# Simplificación de captura y RA — 7 de noviembre de 2026

**Actualización local del 12 de noviembre:** la captura manual libre sustituye el modo automático inicial y la comparación obligatoria al retomar. Ver [Captura libre](ar-free-capture.md). Lo que sigue conserva las decisiones y pruebas de la revisión anterior.

Cambios locales sobre `main` actualizado (`a1e2d81`), conservando los cambios del equipo en historias, perfil y navegación.

## Captura 360°

- Nuevas capturas: máximo **40 fotos**, con un plan calculado según la lente. El caso 40°×60°, que antes pedía 67, ahora pide **35**; 38°×60° pide 36. Otras lentes compatibles pueden necesitar menos.
- No se truncan objetivos: el plan incluye techo/piso y comprueba cobertura nominal mediante frustums rectangulares, una malla de 1° y margen angular. Se mantiene solapamiento horizontal mínimo del 30 % y vertical del 25 %. Una lente que no permita cubrir la esfera dentro del límite muestra una explicación y permite importar un panorama.
- El plan matemático no acredita el resultado óptico. El worker mantiene sus comprobaciones de coincidencias, cobertura real sin huecos y calidad. El OPPO ya tomó automáticamente 35 de 36 fotos del plan nuevo; falta la del techo y comprobar la unión real.
- Captura automática: tras alinear y mantener estable el teléfono, se toma un JPEG real. Se conserva una acción fija **Pausar captura / Continuar captura**. Modo manual, orientación detallada, repetir, importar y empezar otra captura quedan en **Más opciones**.
- El coordinador impide fotos simultáneas y la captura requiere cámara activa y muestras recientes/estables. Los errores pausan el modo automático. Si falla guardar una toma, no se avanza el contador.
- Un plan antiguo sin fotos ni subida iniciada se recalcula. Si ya hay fotos aceptadas, se mantienen el plan y sus identificadores; para usar el plan nuevo se puede empezar otra captura con confirmación. No se mezclan objetivos antiguos y nuevos.

## Editor y reconocimiento por imagen

El editor usa un selector de etapa y **Guardar y continuar**. Cada punto presenta una acción RA principal; editar texto, ubicar en 360°, vincular contenido y cambiar referencia quedan en un menú.

**Añadir imagen RA** ofrece dos opciones: usar una imagen instalada en el lugar o crear una marca para imprimir. Ambas usan reconocimiento nativo real de imagen. El ancho físico debe ser finito y estar entre 1 y 1000 cm. La referencia se guarda antes de abrir el diálogo del sistema para compartir la marca. Cambiar la referencia conserva la exigencia de una prueba nueva.

Durante la visita se muestra una acción principal según el estado. La lista de paradas se despliega cuando hace falta; opciones de lectura, detener cámara o saltar quedan agrupadas. Abrir el menú o el detalle libera la cámara. Los eventos incluyen sesión para descartar reconocimientos anteriores.

La pantalla de RA del organizador conserva la imagen que hay que buscar y **Abrir cámara**. Perfil y comprobación de compatibilidad se agrupan en Más opciones. El panel de la tarjeta mantiene perfil y Misiones activas, y volver a la cámara exige reconocimiento nuevo.

## Importar un panorama

En una posición vacía, **Añadir panorama** ofrece **Capturar con guía** o **Importar desde galería**. En web o importación exclusiva abre directamente la galería. Si hay tomas guardadas, la importación está en Más opciones; sólo se pide reemplazarlas después de elegir y validar un archivo. Cancelar el selector, rechazar el reemplazo o fallar la validación conserva la captura. Si falla guardar la nueva sesión, se restaura la selección anterior.

Antes de guardar/subir se comprueban tamaño (32 MiB), contenedor JPEG, dimensiones acotadas y orientación EXIF. Una esfera completa se reconoce por sus metadatos XMP GPano con namespace real y dimensiones coincidentes. Un JPEG horizontal sin esa evidencia se importa como panorámica horizontal, con un aviso y desplazamiento lateral. Se conservan los bytes originales. El worker mantiene la decodificación y validación final; las salidas horizontales conservan su proporción y no reciben metadatos esféricos.

Una panorámica horizontal del modo Panorama se puede usar para mirar de izquierda a derecha; el aviso indica que no incluye techo y piso. Una imagen 2:1 sin los metadatos originales tampoco se declara esférica. La vista previa local no equivale a aprobación ni permite omitir procesamiento, revisión o publicación. Véase [importación horizontal](ar-horizontal-import.md): el servidor necesita el worker actualizado y la migración 042, preparados localmente y todavía sin aplicar.

## Experiencias cercanas

El usuario aclaró que la geolocalización corresponde a encontrar experiencias en el mapa. Se solicita GPS al pulsar la acción de búsqueda, se ordenan resultados por distancia aproximada y los reintentos conservan la ubicación. Se puede seguir explorando sin permiso y volver a todos los resultados.

**Más opciones → Ver mapa** abre `/map?experiences=1`, que activa las experiencias públicas en el mapa directamente. Los botones normales del mapa y las condiciones de publicación/RA de una Misión se conservan. Este flujo no crea anclajes geoespaciales dentro de la cámara.

## Comprobación

- Análisis Flutter sin incidencias.
- **161 pruebas dirigidas aprobadas** de recorridos, captura, mapa, rutas y barra móvil.
- La suite general ejecutada aprobó 667 pruebas, omitió dos y encontró diez fallos en historias/fichas. Se repitieron esos módulos en un worktree limpio de `a1e2d81`: los diez fallos son los mismos y preceden a estos cambios. Evidencia local en `build/ar-live-pilot/simplify-baseline-summary.json` y sus logs. No se modificaron esas partes del equipo para ocultar los fallos.
- APK Android debug del piloto compilada; la APK actualizada se guarda en `build/ar-live-pilot/marea-production-pilot-debug.apk`.
- La prueba inalámbrica posterior verificó autocaptura en el teléfono y conservación de 30 de 36 tomas; la unión física de la esfera sigue pendiente. iOS requiere compilación y prueba en macOS/dispositivo compatible.

Para probar: abrir el editor, entrar a una posición nueva o vacía, pulsar **Añadir panorama → Capturar con guía** y seguir la guía, o elegir **Importar desde galería** si se dispone de un JPEG 360° original. Comprobar pausa/continuación, repetir desde Más opciones y conservación al salir. Validar después el panorama con el procesador legítimo. Para RA, añadir foto o marca, imprimir/medir si corresponde, probar con cámara y guardar su reconocimiento. Las reglas de revisión y publicación siguen vigentes; no se ejecutaron migraciones ni escrituras de prueba en producción durante estos cambios.

## Repetición por depuración inalámbrica — 7 de noviembre

Se reconectó el OPPO CPH2637 y la actualización devolvió `Success`, conservando la sesión y una captura antigua con **1 de 67** fotos. Se respaldaron su JSON y la foto referenciada en `.dart_tool/ar-live-pilot/capture-backups/`, verificando los bytes copiados. La lente medida (`hfov 39.2791466920366`, `vfov 64.78388988521341`) produce **36 objetivos** con el plan nuevo. Se añadió ese caso a las pruebas. No se sustituyó la captura con fotos existentes mientras se esperaba la elección del usuario.

La búsqueda cercana completó el GPS y mostró «Cerca de ti». No había recorridos públicos disponibles en sus resultados. **Ver mapa** abrió el mapa con **Locales 360° seleccionado** y el marcador de ubicación. La prueba de la referencia del recorrido abrió la pantalla simplificada con una sola acción principal; la repetición óptica y la primera autocaptura nueva se registrarán cuando se completen.

Se abrió además la cámara nativa de RA: la pantalla indicó encuadrar la imagen y Android registró el uso de cámara activo. Al abrir Más opciones, la cámara dejó de figurar como activa y quedó registrada su duración; el menú mostró las acciones secundarias. No se guardó un reporte nuevo ni se simuló reconocimiento. El resumen está en `outputs/ar-live-pilot/wireless-check-20261107.json`, ignorado por Git y sin claves ni coordenadas personales.

Durante la revisión de esta prueba se cerró una carrera al abrir cámara: después de persistir la sesión se vuelven a verificar generación, cámara y estado foreground antes de suscribir/arrancar sensores. El análisis quedó limpio y pasaron **30 pruebas dirigidas** de planes, estabilidad y autocaptura, incluido el caso medido del OPPO. La APK corregida compiló y se reinstaló.

### Foto guía al retomar

El usuario confirmó que la captura automática funciona y llegó a **30 de 36**, pero informó parpadeo de la foto de referencia al retomar. El `FutureBuilder` anterior creaba una lectura del archivo en cada actualización de orientación y ocultaba su espacio mientras esperaba. `CaptureResumePhoto` conserva una sola lectura por archivo/almacén y un espacio fijo de 160 píxeles lógicos. Mantiene la imagen montada entre actualizaciones; un archivo nuevo descarta el anterior y un fallo de lectura permite reintentar.

Seis pruebas de regresión verifican reconstrucciones repetidas sin otra lectura ni desaparición de la imagen, reserva de espacio, cambio de archivo/almacén, descarte de lecturas tardías y reintento. Otras seis pruebas de pantalla cubren importación y conservación de las tomas; trece cubren metadatos del panorama y reintento del visor. Los fixtures sintéticos permanecen limitados a `test/`.

Se respaldaron el JSON y las 30 fotos seleccionadas, con verificación SHA-256, en `.dart_tool/ar-live-pilot/capture-backups/20261107T213647349777Z/` (ignorado). La APK corregida compiló y se instaló con actualización, conservando sesión y contador. Se volvió a abrir la cámara: la interfaz mostró **30 de 36** y la imagen guía en un espacio de 160 píxeles lógicos. El usuario confirmó en el teléfono físico: «Sí, ya se queda fija». Queda comprobada visualmente la corrección del parpadeo al retomar; no se marcó alineación ni se subieron las fotos desde la depuración.

Comprobación final de esta corrección e importación: `flutter analyze --no-pub` sin incidencias y **145 pruebas aprobadas** en `test/features/tours` y `test/features/map`. Dos lecturas posteriores de la interfaz del OPPO conservaron la misma posición/tamaño de la foto guía sin aviso de error; las 30 selecciones del JSON coinciden con el respaldo. Estas comprobaciones acompañan la confirmación visual del usuario. Siguen pendientes las seis tomas restantes, el procesamiento y revisión de la esfera completa, y la importación de un JPEG 360° real en el teléfono.

### Últimas tres tomas: guía física y señal al guardar

El usuario avanzó a **33 de 36**, pero no logró localizar las últimas direcciones y reportó cansancio del brazo. Se leyó únicamente la captura local del piloto: faltan el objetivo del anillo superior (`yaw -36°, pitch +45°`), el piso (`pitch -90°`) y el techo (`pitch +90°`). Las 33 fotos y su JSON se respaldaron con verificación SHA-256 en `.dart_tool/ar-live-pilot/capture-backups/20261107T220912697364Z/`, ignorado por Git.

La guía predeterminada muestra una flecha y un movimiento por vez, sin exigir cifras angulares. Para techo/piso explica hacia dónde apunta la cámara trasera y dónde queda la pantalla. Si el teléfono apunta casi vertical y la siguiente toma pertenece a un anillo, primero indica volver al frente; así evita pedir giros basados en un azimut inestable cerca del polo. Los valores numéricos siguen disponibles en Más opciones. Se conserva un solo botón de pausa/continuación o toma manual.

Después de guardar correctamente un JPEG y la sesión se solicita una vibración del sistema, útil cuando la pantalla queda hacia abajo al apuntar al techo. Un dispositivo sin respuesta háptica no invalida una foto guardada. No se exige un ángulo exactamente polar: el criterio es la distancia esférica existente de menos de 6°, con muestras recientes y estables durante 500 ms. Las pruebas comprueban aceptación a 86° hacia un polo de 90° para distintos azimuts, rechazo a 83° y estabilidad frente a cambios grandes de azimut cerca del polo. No se ampliaron tolerancias ni se omitieron objetivos o fotos.

La finalización óptica de las tres tomas y la percepción de la vibración en el OPPO requieren la siguiente prueba del usuario, después de descansar. No se ha procesado ni subido la captura.

Verificación de esta mejora: análisis Flutter sin incidencias y **123 pruebas de recorridos aprobadas**, incluidas las de guía polar y estabilidad. La prueba anterior del parpadeo permanece confirmada por el usuario; la mejora de las últimas tres tomas debe confirmarse con fotos nuevas reales, sin dar por completados los objetivos pendientes.

La APK con la guía y señal háptica nuevas compiló y la actualización inalámbrica devolvió `Success`. Se comprobó que el JSON mantiene las **33 tomas seleccionadas**, idénticas a las del respaldo, sin trabajo remoto creado. La cámara queda a disposición del usuario para retomar cuando haya descansado; no se confirmó alineación desde la depuración.

### Comparar la foto y la cámara al retomar

En la siguiente asistencia el teléfono ya conservaba **35 de 36 fotos**: se habían guardado la última dirección del anillo superior y el piso; sólo falta el techo. El usuario indicó que no logra alinear la foto al retomar. Se respaldaron el JSON y las 35 fotos, con verificación SHA-256, en `.dart_tool/ar-live-pilot/capture-backups/20261107T232004764143Z/` (ignorado).

La pantalla de reanudación ahora superpone la primera foto semitransparente sobre la cámara en vivo. Usa la proporción real de esa foto (en el OPPO, 720×1280) y ajusta el conjunto al espacio disponible. La foto y la cámara se ven a la vez; **Continuar con este encuadre** queda fijo abajo y se habilita con la referencia cargada y la cámara disponible. Se conserva la lectura única por archivo/almacén, el reintento ante errores y la confirmación manual antes de recuperar la dirección.

Aunque sólo falte el techo, no se omite automáticamente esa confirmación: la gravedad permite comprobar la dirección óptica, pero no restituye por sí sola la rotación del JPEG respecto a las fotos anteriores. El procesador usa las orientaciones guardadas y no tiene un modo probado de azimut desconocido. Las 35 fotos y los objetivos restantes se conservan; no se marca alineación ni una foto como completada desde la depuración.

El usuario confirmó que la dificultad era comparar la foto con la cámara. Pasaron **nueve pruebas del componente**, incluidas las regresiones del parpadeo, y **126 pruebas de recorridos**. El análisis global y el análisis dirigido de los archivos finales quedaron sin incidencias; la APK final compiló y la actualización inalámbrica devolvió `Success`. En el OPPO se abrió la cámara y se comprobó la foto superpuesta (rectángulo de 810×1438 píxeles físicos), el contador **35 de 36** y el botón visible y habilitado. Las 35 selecciones coinciden con su respaldo. Está pendiente que el usuario confirme la alineación con esta vista y complete la foto real del techo.
