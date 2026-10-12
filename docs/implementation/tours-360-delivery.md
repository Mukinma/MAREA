> Estado de infraestructura actualizado: [piloto Docker + Supabase](tours-local-pilot-report.md). Este documento conserva la entrega anterior; el reporte del piloto sustituye sus pendientes de migración/funciones/procesamiento local. Cloud Run y AR físico continúan pendientes.

# Recorridos 360° y AR — entrega local y piloto

6 de octubre de 2026. **Código integrado y verificado localmente. El criterio de entrega física todavía no está acreditado.** No se han desplegado Cloud Run/Edge, activado cron/Vault ni aplicado la migración 015 en un proyecto remoto desde esta implementación.

## Aplicación incorporada

- `lib/features/tours/`: editor de local, zonas y varias posiciones; captura guiada Android/iOS con cámara principal a 1×, calibración JPEG/FOV y orientación nativa. Al retomar comprueba lente y realinea; tomas aceptadas y sesiones permanecen por cuenta.
- Importación de esfera JPEG GPano, carga TUS privada con checkpoint/HEAD, procesamiento y revisión del resultado antes de incorporarlo a la posición. Web administra e importa; debe volver a seleccionar el archivo si cierra la pantalla, pues no conserva bytes en almacenamiento permanente.
- Visor por arrastre, conexiones con indicaciones, puntos angulares o solo en lista, vista previa privada y versión publicada separada del borrador. Reemplazar panorama invalida puntos y conexiones hasta revisarlos.
- ARCore/ARKit mediante PlatformViews: ancho físico, reconocimiento real de imagen, señal ligada a tracking confirmado, ficha que permanece al perderlo, parada siguiente y lista alternativa. Descargas tardías, cambio de cuenta o segundo plano no reactivan una sesión abandonada.
- Progreso privado con outbox local por cuenta/versión, visitadas/saltadas diferenciadas y aviso cuando cambia la versión. Borradores guardados inmediatamente; abrir sin red recupera cambios locales y salir espera la escritura.
- Entradas desde Crear, perfil profesional/público, moderación, solicitudes, mapa y descubrimiento. Los enlaces conservan destino tras autenticación. Las pantallas tienen regreso explícito, incluso al abrirlas directamente. Negocios mantienen Servicios; emprendimientos mantienen Productos.

## Backend y procesamiento preparado

[Migración aditiva 015](../../supabase/migrations/015_tours.sql): espacios/responsabilidad, snapshots editoriales, permisos independientes de espacio y autor, revisiones, progreso, capturas inmutables y cola privada. Publicar cambia la versión activa de manera atómica; editar no sustituye un envío congelado. Revocar responsabilidad impide reanudar sin otro permiso; contenido ajeno se comprueba de nuevo en la lectura pública.

Originales/borradores/evidencias están en buckets privados. Un revisor de un vínculo no obtiene evidencia ni capturas del local. Resultados y confirmaciones de trabajos son exclusivos de backend; respuesta perdida se reconcilia por recibo durable de lease. Ejecuciones canceladas, antiguas o duplicadas no sustituyen capturas posteriores. La eliminación de cuenta cancela, bloquea escrituras y limpia ambos buckets anidados.

[Worker y operación](../../processing/tours/README.md): contenedor Hugin/Enblend, generación de PTO, coincidencias/grafo conectado, optimización, remapeo a 360°×180°, cobertura alpha y mezcla. Salidas GPano 4096×2048, 2048×1024 y 512×256. No se completa una esfera con regiones inventadas.

Cloud Run Jobs `marea-f6a92/us-central1`: 4 vCPU, 8 GiB, 900 s, dos cupos globales en PostgreSQL y hasta dos reintentos transitorios. Dispatcher Edge autenticado con secreto servidor, Google OAuth e IAM de ejecución con overrides. `bootstrap.sh`, `deploy.sh`, `activate.sql` y plantilla de alerta preparan el despliegue explícito; no lo ejecutan automáticamente. La alerta necesita canales reales y comprobación de entrega.

## Verificación ejecutada

| Comprobación | Resultado y alcance |
|---|---|
| `flutter analyze` | Sin observaciones. |
| `flutter test --reporter expanded` | **459 pruebas aprobadas**, incluidas recuperación offline, envío con respuesta perdida, lente al retomar, salida directa, TUS, progreso durable y descargas AR invalidadas. |
| Contratos SQL de recorridos | **85 assertions** con PostgreSQL/PGlite aislado: RLS, privacidad, publicación/snapshots, revocación, leases/cupos, idempotencia, eliminación y recaptura. |
| Migraciones completas | **001–015 aplicadas en aislamiento; 17 flags reales del gate aprobados.** |
| Gate CLI | **12 pruebas** aprobadas. |
| Worker Python | **14 pruebas**: JPEG/GPano, dimensiones, alpha, grafo desconectado, importación/exportación completa y cancelación/respuesta ambigua. Importación usa una imagen sintética; Hugin no se ejecutó. |
| Dispatcher y limpieza | **6 assertions** de autenticación/lease y **3** de limpieza recursiva; Deno check aprobado para ambas Edge Functions. |
| Android nativo | **3 tests JUnit** matemáticos aprobados; APK debug compilado. |
| iOS nativo | **7 checks** de orientación y **8** de estado/orden de tracking aprobados; build debug sin firma compilado. |
| Web | Build release compilado. |
| Interfaz | Revisión real en navegador a 320×740: visor contenido, Entrada→Barra→Entrada, ficha y regreso, editor con etapas envueltas. Widgets verifican texto ampliado y teclado. |
| Diseño | Documento con 24 fichas y seis láminas ImageGen revisadas/corregidas, imágenes y prompts guardados. |

Las builds locales no usaron credenciales administrativas ni distribuyeron la app. iOS requiere firma para instalar. Existen advertencias de plugins/Kotlin e iconos en compilación, sin errores. Los tests nativos ejercitan matemáticas y estado de producción, no callbacks de ARKit/ARCore en un teléfono.

La revisión independiente de fuente detectó y ayudó a corregir exposición a revisores de vínculos, disponibilidad de contenido, confirmación ambigua, puntos solo en lista, recuperación editorial/progreso y lifecycle AR. Los informes y logs locales están en `.superpowers/sdd/tours-360/`; no certifican servicios desplegados.

## Pendientes que condicionan el piloto

1. **Pipeline con fotografías reales.** En este host no hay gcloud, Docker está sin daemon y no se dispone de una captura física. Ejecutar el contenedor con fotografías de celular desde una posición: interiores con techo/piso, ventanas, baja textura y objetos próximos. Medir costura, cierre, fotometría, memoria y tiempo; rechazar huecos, desenfoque y conexiones erróneas. Los fixtures sintéticos no satisfacen esta prueba.
2. **Proyecto y credenciales.** Verificar facturación/IAM de `marea-f6a92`, crear secretos fuera de Git, preparar cuentas separadas con `bootstrap.sh`, desplegar imagen/job y función, aplicar migración 015 y pasar el gate remoto antes de activar `activate.sql`. Configurar canales de alerta y medir coste real en Cloud Billing. Consultar el README del procesador para nombres y comandos.
3. **Supabase real.** Probar Storage/TUS e interrupciones de red, cupos y leases con conexiones concurrentes, respuesta perdida al lanzar/concluir, recaptura durante ejecución y eliminación durante una escritura. PGlite valida lógica/RLS, pero no esas carreras ni los servicios remotos.
4. **Android e iPhone físicos.** Verificar lente/crop ISP/FOV del JPEG frente a sensores, signo yaw/pitch, cenit/nadir y reanudación. Probar AR con permiso rechazado, incompatibilidad, reflejos, pérdida de tracking, cámara limitada, segundo plano y cambios de mobiliario. Validar ancho físico y liberación de cámara; ninguna prueba física está marcada como hecha.
5. **Recorrido de aceptación.** Un local autorizado captura varias posiciones, procesa, revisa, acredita, publica, explora 360° y reconoce una parada física. Interrumpir captura/subida/AR y comprobar recuperación. Registrar duración/calidad/coste y fallos antes de extender el piloto.

## Referencias visuales

[Diseño actualizado y seis láminas](../ar-experience-design.md) · [Imágenes/prompts](../../output/imagegen/ar/README.md) · [Contrato nativo y límites ópticos](tours-native.md).

Las láminas/prompts y evidencias de QA se conservaron localmente en directorios ignorados por la política existente del repositorio; no se han añadido al índice Git. Incluirlos explícitamente al compartir esta entrega.

Captura de **interfaz real con textura sintética de QA**, no foto de un local ni evidencia de procesamiento físico:

![Visita real a 320 px con datos de prueba](../../.superpowers/sdd/tours-360/visit-320.png)
