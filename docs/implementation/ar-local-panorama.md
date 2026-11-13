# Prueba local de unión de fotos

Estado: 13 de noviembre de 2026. La APK **MAREA Prueba RA** conserva desactivado el envío al backend. Esta prueba procesa una copia privada de los JPEG en la computadora; no crea trabajos remotos ni publica recorridos.

## Capturar desde el mismo punto

1. Abrir una posición del recorrido y empezar mirando al frente, a la altura de los ojos.
2. Seguir las caras del cubo sin caminar: frente, derecha, detrás e izquierda. En cada cara fotografiar el centro y después sus zonas altas y bajas. Incluir en cada foto parte de lo que aparecía en la anterior para que puedan unirse.
3. Terminar apuntando directamente al techo y al piso. El contador indica sugerencias recorridas; no certifica cobertura real. El disparador sigue disponible para fotos adicionales.
4. Para hacer una serie nueva, usar **Más opciones → Empezar otra captura**. La sesión actual se conserva en **Capturas anteriores**, con sus JPEG originales. Desde ese apartado se puede retomar otra sesión; la que estaba activa también se archiva antes del cambio. Si falla el guardado, no se descarta la sesión activa.

La guía no sustituye los ángulos medidos del teléfono ni rellena partes que no fueron fotografiadas. Un reinicio del sensor puede cambiar su origen de orientación; la herramienta local busca correspondencias reales entre las imágenes para recuperar la alineación.

## Procesar una copia

El procedimiento y los parámetros están en [processing/tours/README.md](../../processing/tours/README.md), en el apartado de procesamiento local sin backend. `process_local_capture.py` recibe el JSON de la sesión y una carpeta con sus JPEG; necesita Pillow, NumPy y las herramientas de Hugin. Rechaza sobrescribir una salida existente o escribir dentro de los originales.

Para Windows se extrajeron las herramientas de Hugin 2025.0.1 bajo `.dart_tool/tour-tools/`, sin instalar servicios. El instalador se contrastó con el SHA-256 del manifiesto de Microsoft winget. Las fotos, respaldos y resultados permanecen bajo `.dart_tool/ar-live-pilot/`, ignorado por Git.

El informe `result.json` indica `ready`, `uploaded: false` y `published: false`. Sólo se considera preparada una salida que supera las comprobaciones de correspondencias entre imágenes, cobertura, transparencia y GPano del procesador. Un error de correspondencias incluye grupos y números de fotos en `connections`; no se declara completo un panorama con imágenes desconectadas.

## Evidencia de esta sesión

- Las 91 fotos anteriores se respaldaron antes de instalar la actualización. El usuario confirmó que se habían tomado para probar la guía y el botón. La unión de sus 36 fotos etiquetadas por la guía se ejecutó realmente y fue rechazada por imágenes desconectadas; no produjo un panorama preparado.
- Se encontraron después 35 fotos en una serie nueva. La búsqueda real de correspondencias relacionó 32; las fotos 6, 27 y 35 quedaron aisladas. El intento se rechazó con `disconnected_control_points`, sin generar un panorama preparado. Los números corresponden al orden de esa copia de 35 fotos, no al historial anterior.
- Se recuperó la conexión inalámbrica y se verificaron los hashes de los 91 JPEG originales. La sesión antigua se incorporó a **Capturas anteriores**, conservando intacta la captura activa de 35 fotos. La cámara quedó abierta en **Piso · Centro**, paso 36 de 36, para completar la toma pendiente.
- El usuario confirmó la foto 36. Se copiaron nuevamente los originales y se verificó que los primeros 35 JPEG y sus registros no cambiaron. La toma nueva muestra el piso; al provenir de otra sesión del sensor conserva `needs_reference` y su `sensor_yaw` real. La prueba local busca alinearla visualmente, sin inventar una orientación común ni habilitar su envío remoto.
- Se ejecutó la unión de las 36 fotos, primero con detección normal y después con `--fullscale`. La segunda relacionó 32 fotos; las tomas 6, 27, 35 y 36 quedaron sin coincidencias. Ambos intentos se rechazaron antes de generar una esfera. El modo local ahora conserva todo el detalle al detectar características; el modo habitual del backend no cambia. Se preparó `--selection all` para incluir fotos intermedias adicionales, que no reciben etiquetas de pasos del cubo.
- La APK con historial se compiló e instaló en el OPPO. Pasaron 163 pruebas de recorridos y `flutter analyze` terminó sin incidencias. Pasaron seis pruebas del procesador local y 16 del worker existente.
- La unión completa sigue pendiente de obtener una geometría coherente con las fotos reales. El usuario prefirió conservar y visualizar sus tomas existentes en vez de añadir fotografías de objetos concretos. No se resolverá asignando ángulos de la guía como si fueran poses medidas.

## Experimento de vista privada — retirado

**Retirado tras la revisión del usuario.** Las capturas del OPPO mostraron cortes grandes, duplicaciones y zonas sin imagen. Esta composición no ofrece un recorrido utilizable. Se eliminó su pantalla y el acceso «Ver mi recorrido», conservando todos los JPEG, sesiones y respaldos. La APK sin ese mosaico se compiló e instaló en el teléfono. No se volverá a presentar esa composición como resultado del procesamiento. Los párrafos siguientes registran el experimento, no una función disponible.

El usuario pidió ver su recorrido con las 36 tomas guardadas y dejó la prueba de importación para después. Se preparó una **vista preliminar**, separada de los resultados listos y de la publicación:

- El diagnóstico de 32 imágenes conectadas mostró una mala solución visual: `autooptimiser -a` cambió campos de visión entre 8,95° y 180°, con deformaciones. Mantener la lente fija durante la optimización tampoco recuperó una unión coherente. Enblend 4.3 en Windows además terminó con acceso inválido (3221225477) al intentar mezclar ese diagnóstico.
- La vista preliminar utiliza los ángulos y la lente originales registrados, sin promover indicaciones del cubo a mediciones. Remapea las 32 fotos de esa sesión con posiciones disponibles y muestra la toma más próxima al centro de cada región cubierta; no afirma una costura resuelta. Las zonas sin datos se dibujan con cuadros grises. No tiene XMP GPano ni se registra como trabajo listo.
- Se conserva la captura de 36 fotos y su historial. La vista lleva los 36 IDs de origen en orden; si cambia la captura, la app rechaza reutilizarla silenciosamente.
- **Más opciones → Ver mi recorrido** sólo se ofrece en el piloto privado, con subidas desactivadas. Abre un visor local centrado, rotulando fotos usadas, costuras y zonas pendientes. No añade medios al borrador remoto, reportes RA, revisiones ni publicaciones.
- Pasaron 169 pruebas de recorridos, incluidas apertura sin trabajo remoto, conservación de la sesión, rechazo de una vista de otra captura y ausencia del acceso en la app normal. El análisis de las dos pantallas modificadas terminó sin incidencias. Se compiló `build/ar-live-pilot/marea-mi-recorrido-debug.apk`.

Los remapeos y la imagen de revisión son privados y permanecen bajo `.dart_tool/ar-live-pilot/processing/`. La unión final sigue pendiente; la vista permite revisar las fotos reales desde el centro mientras se corrige el procesamiento.

La APK se instaló en el OPPO por Wi-Fi con `Success`. Se verificaron los 196 archivos anteriores sin cambios ni pérdidas; sólo se añadieron la imagen de revisión y su índice privado. Se abrió **Tu recorrido · vista previa** en el teléfono, se comprobó visualmente que muestra las fotos del usuario y se verificó mediante un gesto horizontal que cambia la dirección de la vista. Las capturas de pantalla y el resumen de evidencia permanecen privados bajo `.dart_tool/ar-live-pilot/`.

### Corrección tras el rechazo visual

- Se retiraron el visor del mosaico, su opción del menú y sus tres pruebas. Pasaron las 166 pruebas de recorridos restantes y se compiló e instaló `marea-captura-segura-debug.apk` sin borrar datos.
- El procesador local sustituye `-a` por inicialización por pares y optimización de orientación con lente fija. Una nueva validación rechaza campos de visión alterados, referencias de lente cíclicas y cantidades de imágenes incoherentes antes de remapear. El diagnóstico real con la lente original pasa esa validación; el diagnóstico deformado queda rechazado.
- Se ejecutó una alternativa local con OpenCV 4.12.0, instalado sólo en `.venv-tours`, sin cambiar dependencias del worker desplegado. El ensamblador general falló al ajustar cámaras. SIFT con lente fija logró una composición coherente de ocho fotos de una esquina; no reconstruyó las 36 ni una esfera completa. El fallo final de ese script fue la ventana gráfica no disponible en la variante headless; la imagen de diagnóstico sí se guardó, pero no se publicó ni se instaló como otro recorrido.
- La medición de las correspondencias de Hugin frente a las orientaciones registradas arrojó un error angular mediano de unos 15,6°. Este dato indica una inconsistencia a investigar entre poses y correspondencias; no identifica por sí solo su causa ni demuestra que las fotos estén mal tomadas.
- Resultado: la unión completa continúa **sin resolver** con estas tomas. Se conservan las fotos para seguir investigando; no se marca el recorrido como listo ni se inventa el techo, piso o continuidad.
- También se probaron copias de las 91 fotos anteriores junto a las 36 actuales. Los dos intentos de 127 imágenes con SIFT agotaron el límite local de tres minutos sin producir un candidato. No se modificó la selección activa ni se enviaron imágenes al servidor. Una prueba adicional selecciona las fotos antiguas con orientación disponible para reducir redundancias; su estado queda en los diagnósticos privados.
