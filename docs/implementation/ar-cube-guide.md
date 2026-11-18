# Guía visual de captura con cubo 3 × 3

## Revisión del 16 de noviembre de 2026

- Se conserva el cubo y el plan de hasta 40 sugerencias. La animación continúa desde el indicador anterior al pasar a otro cuadro de la misma cara; el siguiente cuadro se ilumina desde el inicio, sin volver a parpadear en el centro. El cubo también se inclina para distinguir las zonas altas y bajas. Se respeta la preferencia de reducir animaciones.
- La orientación vuelve a estar visible por defecto: giro e inclinación actuales y sugeridos. En captura manual, la primera foto guardada define el frente; girar el teléfono después de abrir la cámara ya no desplaza toda la guía. Esto sólo transforma la presentación, sin reescribir las poses de las fotos.
- La cámara muestra un aro, una línea de nivel y un punto que señala el movimiento hacia el objetivo. El aro se pone verde con una lectura reciente a menos de 6° del objetivo. No muestra un texto «aquí puedes tomar foto». La falta de sensor, la pérdida de seguimiento o un encuadre diferente dejan la guía neutra y mantienen disponible el disparador manual.
- El contenido de ayuda puede desplazarse con texto ampliado; el botón de captura permanece fuera de ese desplazamiento. Se conserva una única acción principal y el menú para ocultar los grados si se desea.
- La guía sigue siendo orientativa. Una foto libre avanza la sugerencia sólo después de guardarse; ni el contador ni el aro verde acreditan la cobertura del panorama. La captura automática opcional conserva sus condiciones anteriores. Las fotos de las sesiones existentes y las reglas de procesamiento/publicación no se alteran.
- Verificación de esta revisión: 225 pruebas de recorridos, marcadores y proximidad aprobadas; análisis sin incidencias y APK debug del piloto compilada. Las pruebas incluyen el cambio inmediato de cuadro del cubo, el frente elegido en la primera foto, la vuelta del sensor tras una foto sin orientación, la retirada de la señal verde al caducar una lectura y el disparador libre con texto ampliado. Las vistas de `build/ar-live-pilot/cube-angles-*.png` usan una cámara de prueba y no acreditan una captura física.
- La APK `marea-cubo-angulos-debug.apk` se instaló en el OPPO por Wi-Fi, conservando la captura activa de 36 fotos. Se compararon los 239 archivos originales de recorridos y marcadores antes y después: ninguno cambió ni desapareció. El respaldo y resultado privados están indicados por `.dart_tool/ar-live-pilot/latest-cube-angles-update.txt`. Falta la confirmación física del usuario sobre la guía nueva; para recorrerla desde el principio se puede usar **Más opciones → Empezar otra captura**, que archiva las 36 fotos actuales.

Los apartados siguientes registran la primera versión de la guía y sus pruebas anteriores.

Revisión local del 13 de noviembre de 2026. Complementa la [captura libre](ar-free-capture.md); no vuelve a bloquear el disparador por orientación, estabilidad o falta de sensores.

## Uso

1. Abrir una posición del recorrido y pulsar **Tomar fotos** o **Retomar captura**.
2. Comenzar mirando al frente, a la altura de los ojos. El cuadro central del cubo es la referencia.
3. Fotografiar el sector iluminado. Un indicador se desplaza desde el centro hacia el cuadro sugerido. El cubo gira al cambiar de lado.
4. Recorrer frente, lado derecho, detrás y lado izquierdo. Cada lado empieza por su parte central, después muestra las zonas altas y bajas. Techo y piso tienen indicaciones propias al final.
5. El paso avanza cuando se guarda un JPEG. Se puede tomar una foto fuera de la sugerencia; el botón permanece disponible. Al recorrer la guía se pueden guardar fotos adicionales.

La pantalla mantiene un único disparador principal y coloca el cubo y su explicación junto a él. No hace falta abrir Más opciones para conocer el siguiente sector. La captura automática opcional conserva sus condiciones anteriores.

## Datos y reanudación

La guía conserva las direcciones del plan de lente existente y cambia su orden visual. El plan medido del OPPO tiene 36 pasos. Si faltan datos de lente se ofrece una guía visual de 38 pasos; no se atribuyen esos ángulos a las fotos reales ni se afirma cobertura suficiente.

La primera cara y cada lado toman su centro como referencia. Una animación indica el siguiente movimiento sugerido; el cubo no certifica que el teléfono haya llegado a ese ángulo.

La secuencia se guarda en `cube_guide` dentro de la sesión local. Cada JPEG nuevo puede registrar `cube_guide_version` y `cube_guide_step`, separados de la pose real y de `target_id`. Esos campos se omiten del manifiesto de procesamiento. El contador de pasos corresponde a sugerencias recorridas, no a cobertura esférica validada.

Las fotos anteriores no completan automáticamente la guía nueva. Se conservan sus bytes, poses y asignaciones anteriores. Al salir y retomar se recupera la sugerencia pendiente; repetir la última toma devuelve ese paso. Un fallo al fotografiar o guardar no avanza la guía. No se ejecutan migraciones ni operaciones de publicación para introducirla.

El procesamiento conserva sus comprobaciones de pose, lente y cobertura real. En **MAREA Prueba RA** siguen desactivadas la preparación y la subida a producción.

## Comprobaciones

- 160 pruebas de recorridos aprobadas tras integrar la guía: orden desde el centro, techo/piso, conservación de objetivos de lente, restauración, rechazo de sesiones malformadas, animación, texto ampliado y disparador libre sin sensores.
- Prueba de pantalla: una foto guardada avanza la sugerencia; salir y volver conserva el paso; un error de cámara no avanza ni modifica las fotos anteriores.
- Vistas previas renderizadas con la fuente de MAREA en `build/ar-live-pilot/cube-guide-front.png`, `cube-guide-right.png` y `cube-guide-ceiling.png`. La vista de cámara de esas imágenes es un fondo de prueba, no una captura del teléfono.
- Análisis Flutter sin incidencias y APK Android debug compilada. Una prueba adicional verifica que las etiquetas de guía se conservan localmente y no entran en el manifiesto de procesamiento.
- Se instaló `build/ar-live-pilot/marea-cubo-guia-debug.apk` en el OPPO por Wi-Fi con `Success`. Se verificaron los hashes de 121 archivos de recorridos/marcadores: ninguno cambió ni desapareció durante la instalación.
- Al abrir la captura, el teléfono estaba bloqueado. Después de desbloquear y retomar, el usuario confirmó: **«Sí, veo el cubo y avanza»**. Quedan comprobados físicamente la presencia de la guía y el avance de la animación al guardar una foto en el OPPO. La evidencia local está en `.dart_tool/ar-live-pilot/cube-guide-install-summary.json` y el respaldo privado en la carpeta indicada por `latest-cube-backup.txt`.
