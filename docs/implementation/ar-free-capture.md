# Captura libre — 12 de noviembre de 2026

El modo inicial es manual. La guía orienta, pero **Tomar foto** no espera un ángulo, estabilidad, sensores ni una dirección pendiente. El botón sólo espera a que termine la operación de cámara/guardado en curso. La cámara sigue disponible cuando no se puede calcular el plan o iniciar la orientación.

La [guía visual de cubo 3 × 3](ar-cube-guide.md) indica ahora una secuencia concreta desde el centro de cada lado, seguida por las partes altas/bajas, el techo y el piso. Su animación avanza al guardar fotos y conserva el disparador libre.

## Uso

1. En una posición del recorrido, elegir **Añadir panorama → Tomar fotos**.
2. Girar sobre el mismo punto y tomar fotos a tu ritmo. La guía es opcional; se puede incluir techo y piso sin esperar una señal de autorización.
3. Pulsar el icono **Terminar fotos** y después **Preparar panorama**.

La pantalla muestra fotos guardadas, en lugar de exigir completar un contador de objetivos. El plan de hasta 40 direcciones queda como ayuda opcional; no limita el número de fotos manuales. La captura automática permanece en Más opciones y conserva su propia comprobación de estabilidad.

## Reanudar y conservar datos

Abrir una captura existente no fuerza la comparación de la foto inicial. El disparador manual está disponible de inmediato al terminar de abrir la cámara. **Más opciones → Usar foto inicial como referencia** abre la superposición cuando el usuario quiera recuperar la dirección para procesar las nuevas fotos.

Esa comparación no reinicia los sensores. Recalcula el origen de giro y puede recuperar las fotos con muestras reales de la sesión de cámara actual. Cada sesión tiene su identificador; los datos de las fotos anteriores permanecen intactos. Volver desde la comparación permite seguir con la captura manual.

Se guardan todos los JPEG reales. Una foto con orientación reciente y referencia recuperada conserva sus ángulos medidos aunque esté fuera de la guía. Sólo se asigna un objetivo cuando está realmente cerca de esa dirección; no se completa el siguiente objetivo por pulsar el botón. Si faltan sensores, datos de lente o referencia, la foto sigue guardada localmente y no se inventan ángulos.

Al iniciar mirando exactamente al techo/piso, Android e iOS informan `headingReady=false` hasta establecer un origen de giro. Esto sólo determina la disponibilidad de la orientación; nunca bloquea el disparador manual.

## Preparación del panorama

La acción indica cuántas fotos con datos disponibles preparará y explica cuáles permanecen locales. El contrato existente del procesador admite entre 6 y 96 fotos con pose y lente válidas, sin requerir los objetivos de la guía. No se cambiaron el backend ni ese contrato. Los checkpoints de subida se conservan en las fotos originales y el manifiesto omite datos exclusivamente locales.

El procesador mantiene las comprobaciones reales de coincidencias, conexión, costura y cobertura. Pulsar Tomar foto no acredita una esfera completa. Se conservan la revisión antes de usar un panorama, las reglas de publicación y el reconocimiento nativo real de imágenes.

## Verificación

- 150 pruebas de recorridos aprobadas, incluidas captura manual libre, cámara sin sensores, conservación de fotos, importación y manifiesto con fotos fuera de la guía.
- Cinco pruebas nativas Android de orientación aprobadas. Las comprobaciones equivalentes de iOS requieren macOS.
- No se modificaron datos del piloto ni se instalaron cambios en el teléfono durante estas comprobaciones. La validación física de este modo queda pendiente.

El usuario aclaró que se conservan los marcadores de imagen y los pines del mapa. El CRUD independiente y los avisos de Misiones/marcadores a 20 m, incluso en segundo plano Android, se documentan en [los tres módulos](ar-three-modules.md). No se integró la rama `alan`.
