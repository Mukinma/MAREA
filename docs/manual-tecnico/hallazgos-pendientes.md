# Hallazgos pendientes · MAREA v1.1

Revisión: 11 de noviembre de 2026. Los IDs H01–H08 se conservan. **Estado de evidencia** expresa qué se sabe; **estado de resolución** expresa si el problema está cerrado. Alto identifica impacto relevante en promoción, semántica de producto o datos; Medio identifica pérdida de confianza de QA o una dependencia operativa no verificada. Estas prioridades no son puntuaciones de vulnerabilidad.

## H01 · Historial de migraciones ambiguo

- **Evidencia: VERIFICADO en archivos; historial remoto PENDIENTE. Resolución: abierto. Severidad: Alta.** Hay dos archivos 034 y dos 035. La reconstrucción local exige considerar dependencias y redefiniciones; no demuestra qué se aplicó en un entorno.
- **Impacto:** reproducibilidad de instalación y riesgo de promover un contrato distinto al que consume el cliente.
- **Fuente:** [migraciones](../../supabase/migrations/), especialmente los cuatro nombres duplicados, 036–040 y [gates](../../tool/README.md).
- **Acción:** un operador debe reconciliar historial, nombres, firmas, columnas y permisos del destino; preparar un cambio aditivo revisado cuando sea necesario. No renumerar archivos aplicados a ciegas.
- **Cierre:** historial explicado, esquema aislado reproducible y comparación de catálogo/contratos aprobada. Requiere acceso a infraestructura; cualquier corrección SQL queda fuera de esta tarea.

## H02 · Selección unilateral y contrato normativo

- **Evidencia: VERIFICADO. Resolución: abierto. Severidad: Alta.** `confirm_mission_selection` acepta candidaturas mediante `review_application(...,'accepted')` por acción del organizador, con misión `open` o `closed` futura y cupo válido.
- **Impacto:** no corresponde a la oferta firmada y aceptación de contraparte exigidas por RF-09-005/RF-09-011. También debe revisarse la eliminación de cuentas frente a compromisos personales normativos; las cascadas actuales no prueban conservación de obligaciones.
- **Fuente:** [013](../../supabase/migrations/013_missions_redesign.sql), [SRS §3 y M09](../MAREA_SRS.md), [baja](../../supabase/functions/delete-account/index.ts).
- **Acción:** resolver la compatibilidad de producto y diseñar, en trabajo separado, la transición de candidaturas históricas. Mantener el manual fiel a la selección existente.
- **Cierre:** decisión registrada y contratos/pruebas que distingan candidatura, oferta y aceptación sin que una parte firme por la otra. Requiere decisión de producto, código, SQL y pruebas; no se resuelve editorialmente.

## H03 · Cartografía y experiencia física

- **Evidencia: PENDIENTE DE VALIDACIÓN actual. Resolución: abierto. Severidad: Alta para aceptación móvil.** Código y adaptadores simulados existen, pero esta edición no ejecutó mapa con token ni cámara/RA físicos.
- **Impacto:** no se acreditan carga real de estilos, estabilidad de sensores, reconocimiento ni captura utilizable.
- **Fuente:** [historial Mapbox](../mapbox-validation.md), [mapa](../../lib/core/maps/), [captura](../../lib/features/tours/capture/), [Android RA](../../android/app/src/main/kotlin/com/marea/app/TourAR.kt), [iOS](../../ios/Runner/AppDelegate.swift).
- **Acción:** matriz Android/iOS/Web con token autorizado; captura, denegación de permisos, interrupción/reanudación y RA en dispositivos compatibles. Registrar versión, dispositivo, condiciones y evidencia sanitizada.
- **Cierre:** criterios por plataforma satisfechos y limitaciones documentadas. Requiere credenciales públicas autorizadas, dispositivos y servicios. No se presume necesidad de cambios de código hasta observar fallos.

## H04 · Firma Android de distribución

- **Evidencia: VERIFICADO en configuración. Resolución: abierto. Severidad: Alta para distribución.** `buildTypes.release` usa la configuración `debug`.
- **Impacto:** el build configurado no constituye una cadena de firma de distribución acreditada. No se afirma que un APK histórico fuese publicado ni que una tienda lo aceptara.
- **Fuente:** [Gradle](../../android/app/build.gradle.kts).
- **Acción:** preparar firma y custodia de claves en trabajo autorizado; verificar identidad de aplicación y certificado del artefacto final.
- **Cierre:** artefacto firmado mediante la cadena aprobada, certificado verificado y procedimiento reproducible. Requiere configuración y secretos de distribución; no se cambia aquí.

## H05 · Diecisiete pruebas Flutter fallidas

- **Evidencia: VERIFICADO por nuevas corridas. Resolución: abierto. Severidad: Media.** Suite completa 653 aprobadas, 2 omitidas, 17 fallidas. Juntas e individualmente se reproducen 7/3/7.
- **Impacto:** las rutas de bienvenida, interacción con historias y escaparates no tienen esas comprobaciones en verde; no se atribuye un fallo de backend a un finder vacío.
- **Fuente:** [diagnóstico F01–F03](auditoria-tecnica.md#investigación-de-los-17-fallos), [casos exactos](evidencias/fallos-flutter.json), [corridas](evidencias/README.md).
- **Acción:** contrastar la fila de bienvenida con métricas de fuentes reales; alinear las acciones de historias con el visor/compositor actual; revisar herramientas y navegación de perfil. Preservar la intención de cada prueba.
- **Cierre:** cada caso pasa por una corrección justificada de producto o test, y la suite completa se repite sin regresiones. Requiere código o pruebas; esta entrega solo diagnostica.

## H06 · Sesión local y revocación efectiva

- **Evidencia: VERIFICADO el uso explícito de SharedPreferences en desarrollo/piloto; protección y revocación PENDIENTES. Resolución: abierto. Severidad: Alta por sensibilidad de sesión.** La v1.0 agrupaba este punto como inferido; v1.1 separa mecanismo y riesgo.
- **Impacto potencial, INFERIDO:** exposición o supervivencia no deseada de una sesión si las protecciones del dispositivo o la revocación no satisfacen el contrato. No hay explotación ni vulnerabilidad demostrada en esta inspección.
- **Fuente:** [arranque](../../lib/main.dart), [sesión](../../lib/core/session/app_session_controller.dart), [baja](../../supabase/functions/delete-account/index.ts).
- **Acción:** verificar almacenamiento efectivo por plataforma/variante, backups, cierre local, tokens previos a baja y recuperación. No extrapolar el almacenamiento explícito del piloto a todas las variantes.
- **Cierre:** evidencia del dispositivo y Auth que satisfaga los requisitos acordados de protección y revocación. Requiere infraestructura y dispositivos; cambios posteriores dependerán de resultados.

## H07 · Dependencias operativas externas

- **Evidencia: VERIFICADO el código y configuración; servicio actual PENDIENTE. Resolución: abierto. Severidad: Media.** Proveedor geográfico, caché/lease y Cloud Run tienen contratos locales, pero no se verificaron credenciales, cuotas, facturación ni ejecución integral.
- **Impacto:** una UI y un worker unitario aprobados pueden coexistir con un servicio sin activar.
- **Fuente:** [021](../../supabase/migrations/021_content_cities.sql), [geocoding](../../supabase/functions/geocoding/index.ts), [deploy](../../processing/tours/deploy.sh), [activación](../../processing/tours/activate.sql), [alerta](../../processing/tours/monitoring-alert.json).
- **Acción:** comprobar búsqueda/reverse y ciudad de contenido; luego reclamo, despacho, salida, adjunto y limpieza 360°. Verificar alerta y canal de entrega por separado.
- **Cierre:** recorridos integrales autorizados y evidencia de cuotas, operación y alertas. Requiere infraestructura y credenciales; no se ejecutó despliegue.

## H08 · Publicación Realtime de chat

- **Evidencia: VERIFICADO el consumidor; publicación remota PENDIENTE. Resolución: abierto. Severidad: Media.** `changes()` observa `chat_messages`; la búsqueda local de publicación explícita encontró `notifications`, sin demostrar habilitación del chat en destino.
- **Impacto potencial:** mensajes recuperables por lectura podrían no llegar como eventos en tiempo real. No se declara un fallo remoto confirmado.
- **Fuente:** [repositorio](../../lib/features/chat/data/chat_repository.dart) · `changes()`, [009](../../supabase/migrations/009_post_reactions.sql).
- **Acción:** inspeccionar catálogo del entorno y observar dos sesiones participantes y una ajena. Evitar cambios SQL hasta conocer el estado efectivo.
- **Cierre:** publicación y suscripción verificadas, evento recibido y acceso de terceros rechazado. Requiere infraestructura; podría requerir configuración.

## Pendientes transversales

La instalación limpia de dependencias, aplicación íntegra de migraciones en motor aislado, SMTP/OAuth, entrega FCM, firmas iOS/Android, alojamiento con rutas limpias, respaldo/restauración y responsables operativos no se verificaron en esta edición. Son pendientes explícitos; no se convierten en capacidades ausentes ni en vulnerabilidades confirmadas.

## Hallazgos del documento

- **HD01 · Fragmentación de identificadores:** la v1.0 partía `supabase_flutter` dejando una letra aislada. Se corrige el tratamiento tipográfico y la distribución de columnas; cierre sujeto a control final del PDF.
- **HD02 · Profundidad insuficiente:** se amplían contratos, invariantes, errores y procedimientos, conservando el contenido válido. La evidencia y límites se revisan en la matriz.
- **HD03 · Trazabilidad incompleta:** se agrega requisito, diseño, prueba, resultado y estado, sin convertir una relación temática en cumplimiento normativo.
- **HD04 · Reproducción y navegación:** se incorporan verificación automatizada, archivo recuperable, subsecciones navegables y evidencia durable. La aceptación consta en [control de calidad](evidencias/control-calidad.md).

Estos cambios documentales no cierran H01–H08.
