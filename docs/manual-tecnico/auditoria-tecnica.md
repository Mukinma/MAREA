# Auditoría técnica de MAREA

11 de noviembre de 2026 · Revisión base `e27f6ae4e3fb2a63f7287bbd486e989745bab216` · Árbol de trabajo con cambios locales de Mapbox

Esta auditoría acompaña al [manual](manual-tecnico.md). La [matriz](matriz-trazabilidad.md) localiza la implementación y las pruebas. **VERIFICADO** se refiere a evidencia de código o a una corrida indicada expresamente. **INFERIDO** se reserva para consecuencias del diseño. **PENDIENTE DE VALIDACIÓN** indica evidencia que requiere otro entorno, dispositivo o responsable.

## Inventario comprobado

| Capa | Elementos encontrados | Evidencia primaria |
|---|---|---|
| Aplicación | Flutter/Dart, Material, `go_router`, repositorios Supabase, controladores y vistas Android/iOS/Web. Versión de paquete `1.1.0+1`. | `pubspec.yaml`, `pubspec.lock`, `.metadata`, `lib/main.dart`, `lib/app.dart` |
| Datos | PostgreSQL, Auth, Storage, PostgREST, RPC y streams. 42 archivos SQL numerados `001`–`040`. | `supabase/migrations/`, `supabase/config.toml`, repositorios Dart |
| Integraciones | Google OAuth y correo desde Auth, Mapbox Flutter/Web `3.34.2`, geocodificación configurable con Nominatim por defecto, FCM Android y Cloud Run Jobs. | `auth_repository.dart`, `pubspec.lock`, `021_content_cities.sql`, Edge Functions y `deploy.sh` |
| Edge Functions | `delete-account`, `profile-media`, `geocoding`, `send-push`, `story-cleanup`, `tour-dispatch`. | `supabase/functions/*/index.ts`, `supabase/config.toml` |
| Worker | Imagen Python 3.12, Hugin/Enblend y dependencias fijadas Pillow, NumPy y Requests. Runner local separado. | `processing/tours/Dockerfile`, `requirements.txt`, `worker.py`, `local_runner.py` |
| Entrega y pruebas | Gradle 9.1.1, AGP 9.0.1, Kotlin 2.3.20, objetivo JVM 17, iOS 15 con SwiftPM. Gates Node, pruebas Flutter y laboratorios SQL/PGlite. | `android/`, `ios/`, `test/`, `tool/`, `processing/tours/tests/` |

La inspección cubrió entradas y configuración, dependencias, repositorios y flujos principales, contratos SQL y sus redefiniciones, almacenamiento, funciones Edge, worker y guías de operación. `docs/evidence/`, `docs/task002/` y sus laboratorios se tomaron como contexto de validaciones puntuales. Su contenido y la adopción normativa del SRS requieren revisiones propias. El inventario estático no acredita la paridad del esquema alojado con los 42 archivos.

## Comportamiento verificado e inferencias

- **VERIFICADO.** `startMarea()` construye el cliente y el router desde un controlador de sesión con repositorios inyectados. Los roles de perfil y los permisos de recurso se aplican en dominios distintos. Los guards del cliente dirigen la UI y el backend autoriza operaciones y visibilidad.
- **VERIFICADO.** Las operaciones asíncronas de tours usan reclamación, lease, guardas de escritura y recuperación. La baja consulta una marca de eliminación, espera operaciones protegidas y limpia Storage antes de eliminar el usuario.
- **VERIFICADO.** Las funciones de perfil y baja validan al usuario. Los tres workers aplican sus credenciales de servidor. `geocoding` separa lectura de lugares y resolución de contenido. El RPC `community_profiles` proyecta el directorio de perfiles y el username anónimo se consulta por booleano.
- **INFERIDO.** Los repositorios y la fachada de mapa permiten cambiar implementaciones de I/O en pruebas sin replicar la interfaz visual. Los límites reales de performance, cuotas y dispositivo necesitan pruebas con los proveedores configurados.
- **INFERIDO.** Una baja coordinada reduce residuos y escrituras posteriores. Su completitud ante restauración, trabajos interrumpidos y vigencia de credenciales necesita verificación operacional.

## Discrepancias con guías y resultados previos

| ID | Referencia anterior | Evidencia en el árbol inspeccionado |
|---|---|---|
| D01 | El `README.md` enlaza `docs/instalacion-local.md`. | La ruta está ausente. Los capítulos 09 y 10 reconstruyen los pasos con los ejemplos, código y guías disponibles. |
| D02 | El árbol del README enumera `005_mission_management.sql` y termina en `008`. | La migración se llama `005_mission_lifecycle.sql`. El inventario incluye `009`–`040` y los prefijos repetidos `034` y `035`. |
| D03 | El README describe `lib/main.dart` como única entrada ejecutable. | Es la entrada ordinaria. Gradle también identifica dos entradas de QA, `test/manual/business_ar_probe.dart` y `test/manual/business_ar_live_probe.dart`, restringidas a debug. |
| D04 | El gate inicial se presenta como verificación antes de distribuir. | `tool/backend_contract.sql` exige `001`–`015`. Hay gates separados para `016`–`019` y `020`–`021`. Las migraciones posteriores requieren sus comprobaciones de destino. |
| D05 | `docs/deployment-status.md` incluye una observación histórica de SMTP desactivado. El README y `docs/email-setup.md` reportan activación posterior y plantillas de confirmación. | El repositorio contiene plantillas y flujos de Auth. El estado de SMTP y la entrega efectiva se mantienen pendientes en esta edición. |
| D06 | El mensaje de error de `stories_repository.dart` cita `016`, `018`, `019` y `034`. | La firma actual del cliente envía cinco parámetros. La secuencia de reparación incluye `036`–`040`. Para diagnosticar el entorno revisar firmas, columnas y caché. |

## Hallazgos revisados

La reevaluación conserva H01–H08 y separa evidencia, severidad, estado de resolución y acción. Todos siguen abiertos total o parcialmente. El [informe de pendientes](hallazgos-pendientes.md) contiene las condiciones de cierre; una mejora del texto no resuelve un defecto del software.

## Comprobaciones realizadas en v1.1

Fecha: 11 de noviembre de 2026. Revisión base `e27f6ae4e3fb2a63f7287bbd486e989745bab216`, con cambios locales. SDK Flutter 3.44.1/Dart 3.12.1, Node 24.14.0, worker Python 3.12.14. Se copió el cliente, assets, tests y manifiestos a un directorio temporal. Se reutilizó la resolución de paquetes y se ejecutó el snapshot de Flutter; el runner necesitó loopback. La carpeta de capturas se preparó solo en esa copia. No se modificaron tests ni código funcional.

| ID de corrida | Aprobadas | Omitidas | Fallidas | Código de salida |
|---|---:|---:|---:|---:|
| [Análisis](evidencias/analyze.log) | Sin incidencias | No aplica | 0 | 0 |
| [Flutter completo](evidencias/flutter-full.log) | 653 | 2 | 17 | 1 |
| [Tres suites juntas](evidencias/flutter-grupo.log) | 23 | 0 | 17 | 1 |
| [Introducción aislada](evidencias/flutter-intro.log) | 2 | 0 | 7 | 1 |
| [Historias aislada](evidencias/flutter-historias.log) | 14 | 0 | 3 | 1 |
| [Escaparates aislada](evidencias/flutter-escaparates.log) | 7 | 0 | 7 | 1 |
| [Node](evidencias/node.log) | 55 | 0 | 0 | 0 |
| [Python](evidencias/python.log) | 16 | 0 | 0 | 0 |

Los resultados se solapan; no sumarlos como pruebas únicas. Node usa CLI y proveedor simulados. Python simula I/O externo. Los comandos, tiempos disponibles y procedencia están en los JSON de cada corrida y en [la guía de evidencia](evidencias/README.md). No se midió cobertura. No se ejecutaron nuevos builds, pruebas SQL aisladas, pruebas E2E remotas ni pruebas físicas. No se verificó instalación limpia desde Internet.

### Investigación de los 17 fallos

**VERIFICADO.** Los 17 casos se repiten en la suite completa, en las tres suites juntas y en cada archivo aislado. Esta reproducción reduce la hipótesis de interferencia exclusiva entre suites; no demuestra ausencia de otros factores del entorno.

#### F01 · Introducción: siete variantes

**Síntoma verificado:** `RenderFlex overflowed by 54 pixels on the right`. El harness fija 390×844, incluso en las variantes desktop. Los siete casos alcanzan la bienvenida; las dos pruebas de la primera pantalla introductoria pasan. `WelcomeScreen._actions()` construye el botón Google con una `Row`, icono, separación y texto sin `Flexible` para ese texto.

**Causa probable, inferida:** el ancho intrínseco de esa fila excede el disponible bajo las métricas del harness. El test no carga fuentes explícitas, mientras `test/_visual/mobile_intro_capture_test.dart` sí usa `FontLoader` para Nunito Sans e iconos. No se ejecutó una comparación controlada de fuentes ni se atribuye el desbordamiento a dispositivos reales.

**Impacto y cierre:** la suite no valida limpiamente la transición a bienvenida. Un trabajo posterior debe contrastar métricas de test y fuentes reales, conservar el test representativo y verificar la fila a 390 px y con texto ampliado. Requiere decidir y corregir código o harness fuera del alcance documental.

**Fuentes:** [test](../../test/features/auth/mobile_intro_test.dart), [bienvenida](../../lib/features/auth/presentation/welcome_screen.dart) · `_actions()`, [capturas](../../test/_visual/mobile_intro_capture_test.dart), [log aislado](evidencias/flutter-intro.log).

#### F02 · Historias: tres interacciones

**Síntoma y divergencia verificados:** dos casos buscan `Pausar historia`; esa etiqueta no está en el visor actual, que usa `GestureDetector` y pausa al mantener pulsado. El caso de reintento intenta escribir en un `TextField` que aún no existe: el compositor lo crea en el diálogo de `_addTextOverlay()`. El resultado es finder vacío o `Bad state: No element` antes de probar el contrato pretendido.

**Límite:** se ha demostrado desalineación entre las acciones del test y la UI actual, no que la pausa, publicación o idempotencia estén correctas en un servicio real. Se debe acordar la interacción vigente y volver a cubrir pausa, navegación y conservación de ID/payload tras error.

**Fuentes:** [test](../../test/features/home_feed/home_feed_experience_test.dart), [visor](../../lib/features/home_feed/presentation/story_viewer.dart), [compositor](../../lib/features/home_feed/presentation/story_composer.dart) · `_addTextOverlay()`, [log](evidencias/flutter-historias.log).

#### F03 · Escaparates: siete recorridos

**Síntoma verificado:** tres pruebas esperan `Agregar obra`, `Agregar producto` o `Agregar servicio` directamente tras abrir `/profile`; no encuentran el texto. Cuatro pruebas de visitante fallan al intentar volver a la sección de escaparate después de pulsar `Misiones`.

**Evidencia de diseño:** las herramientas del perfil y las hojas de contenido son componentes distintos del resumen. `profile_tools_sheet.dart` genera acciones por `showcaseKinds`; `profile_content_sections.dart` proporciona resumen, acceso «Ver todo» y hoja de escaparate. El test conserva una expectativa de herramientas visibles y navegación que esa secuencia ya no satisface.

**Causa probable y límite:** desalineación con la composición actual; para los cuatro casos de visitante falta una captura de la ruta exacta al fallar. No se concluye que permisos o persistencia estén rotos. El cierre exige comprobar acceso del dueño, ausencia de controles de dueño en terceros y navegación de ida/vuelta con los widgets vigentes.

**Fuentes:** [test](../../test/features/showcase/showcase_flow_test.dart), [herramientas](../../lib/features/profile/presentation/profile_tools_sheet.dart), [secciones](../../lib/features/profile/presentation/profile_content_sections.dart), [log](evidencias/flutter-escaparates.log).

### Catálogo de casos reproducidos

| Grupo | Caso exacto | Resultado |
|---|---|---|
| F01 | four pages finish at welcome and persist across app restarts (variant: TargetPlatform.android) | Fallo reproducido individualmente |
| F01 | four pages finish at welcome and persist across app restarts (variant: TargetPlatform.iOS) | Fallo reproducido individualmente |
| F01 | skip on a middle page records completion (variant: TargetPlatform.android) | Fallo reproducido individualmente |
| F01 | skip on a middle page records completion (variant: TargetPlatform.iOS) | Fallo reproducido individualmente |
| F01 | desktop retains the original welcome (variant: TargetPlatform.macOS) | Fallo reproducido individualmente |
| F01 | desktop retains the original welcome (variant: TargetPlatform.linux) | Fallo reproducido individualmente |
| F01 | desktop retains the original welcome (variant: TargetPlatform.windows) | Fallo reproducido individualmente |
| F02 | opening a story covers the shell navigation | Fallo reproducido individualmente |
| F02 | a failed publish retains text and retries the same operation | Fallo reproducido individualmente |
| F02 | story viewer marks shown content seen and supports pause and next | Fallo reproducido individualmente |
| F03 | creator completes initial choices and gets the right tools | Fallo reproducido individualmente |
| F03 | entrepreneur completes initial choices and gets the right tools | Fallo reproducido individualmente |
| F03 | business completes initial choices and gets the right tools | Fallo reproducido individualmente |
| F03 | general visitor sees its public section without owner tools | Fallo reproducido individualmente |
| F03 | creator visitor sees its public section without owner tools | Fallo reproducido individualmente |
| F03 | entrepreneur visitor sees its public section without owner tools | Fallo reproducido individualmente |
| F03 | business visitor sees its public section without owner tools | Fallo reproducido individualmente |

## Evidencia histórica y discrepancias adicionales

`docs/mapbox-validation.md` registra el 7 de noviembre 649 aprobadas, 2 omitidas, 17 fallidas y builds Web, APK e iOS. v1.0 registró el 11 de noviembre 653/2/17. v1.1 obtuvo de nuevo 653/2/17: son tres registros distintos, no una sola corrida. Las compilaciones históricas no se vuelven a certificar.

La SRS 5.1.1 contiene organizaciones, representación y aceptación bilateral, mientras el código inspeccionado usa perfiles, autoría y aceptación por organizador. Los IDs de requisito en la matriz no acreditan cumplimiento integral. RF-26-009 y RF-26-011 condicionan funciones sociales y RA/360°: su presencia en el árbol no acredita activación aprobada.

**DESACTUALIZADO como lectura del esquema actual:** describir `chat_bans` o la firma de tres argumentos de historias como interfaces vigentes omite las migraciones 027 y 039. El inventario textual conserva su aparición histórica e indica que no es un catálogo efectivo.

## Control de la edición

La v1.0 se preservó antes de editar, con manifiesto SHA-256 y una copia ZIP que también conserva el archivo auxiliar `.DS_Store` encontrado. La línea base contiene 1420 archivos ajenos al directorio documental. El control final, la navegación y la revisión de páginas se registran en [control de calidad](evidencias/control-calidad.md). Los resultados se incorporan después de verificar el artefacto final.
