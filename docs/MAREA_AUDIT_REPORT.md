

<!-- MAREA:GENERATED:BEGIN -->
# Auditoría de MAREA

Línea base histórica **AUDIT-2026-10-13**, revisión 2026-10-13T06:52:08.029Z, commit 989e5b5845deff0afd13703a067a7d7a3775d3bc, SRS v5.0. [Fuente histórica](evidence/2026-10-13/task002/run-20261014T003000Z/SRS-5.0.md). Fuente de diseño autorizada: [SRS v5.1.1](MAREA_SRS.md), SHA256 4a1c28594e68d26180390b9aea3affce18a619039ad25ad1c8c528dc3d2f4388. Adopción efectiva: **PENDIENTE_COMPATIBILIDAD_LOCAL**. Registro canónico: [YAML](MAREA_REQUIREMENTS_STATUS.yaml). Integración documental no acredita migración, datos reales, release ni autorización remota. Estados/criterios preexistentes conservan su evaluación histórica; 144 registros requieren reauditoría y 21 casos TC permanecen pendientes.

## Método

Lectura completa del SRS, revisión estática por ID, auditoría inversa y metadatos remotos de sólo lectura. No se consultaron filas de personas ni se ejecutaron funciones de negocio remotas. Se distinguen fuente, configuración, pruebas y funcionamiento por plataforma.

MAREA contiene una aplicación Flutter amplia y un backend legado desplegado en desarrollo. Su implementación no coincide todavía con varios contratos v5 del flujo central: organización/membresía, ofertas con reserva y TTL, acuerdos bilaterales, versiones aceptadas y resultados verificables. Las suites locales aprobadas no acreditan esos contratos ni un release multiplataforma. No se declara ningún módulo terminado. Las características sociales y AR requieren decisión de alcance/aislamiento; no se elimina código. TASK-002 consolida SRS v5.1.1 y trazabilidad documental con autorización acotada. Sus contratos aplican al organizador autorizado personal u organizacional. E/U0 son propuestas: no se ejecutaron migraciones ni código funcional. La baseline efectiva histórica v5.0 y TASK-001 se conservan; adopción v5.1.1 pendiente de compatibilidad. Datos sintéticos no prueban todos los datos reales ni autorizan remoto.

## Hallazgos, inconsistencias y seguridad

### FND-001 · CRITICA · Selección unilateral consume cupo y se anuncia participante confirmado

confirm_mission_selection llama review_application(..., accepted), admite misión open o closed y cuenta accepted como capacidad. No existen oferta 72h/reserva/acuerdo/aceptación candidata. UI afirma Participantes confirmados. El lock evita sobrecupo unilateral, pero contradice ADR42-02/CTR5-01 y cerrar no impide nuevas selecciones.

Requisitos: RF-08-003, RF-09-007, RF-09-011, RF-10-001. Archivos: [lib/features/community/presentation/mission_management_screen.dart](../lib/features/community/presentation/mission_management_screen.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql). Evidencias: E-SRC-001, E-SRC-002, E-SRC-003, E-TASK001-CONT-SUITES, E-TASK001-CONT-REPRO.

Acción: Implementar oferta/reserva 72h/aceptación revisionada y conversión transaccional, separar preselección de acuerdo; probar último cupo concurrente, expiración y cierre.

### FND-002 · ALTA · Cambios materiales no tienen revisión ni renovación de consentimiento

conditions_locked_at bloquea fecha/lugar/target y bajar capacidad, compensation lock bloquea pago, pero body/requirements/conditions siguen editables. No hay MissionRevision ni revision_id de candidatura y la UI autoriza corregir textos. Alcance/obligaciones pueden cambiar tras postulación sin registro anterior ni nueva aceptación.

Requisitos: RF-08-010, RF-08-011, RF-09-014, RF-10-005, RF-10-006. Archivos: [lib/features/community/presentation/mission_composer_screen.dart](../lib/features/community/presentation/mission_composer_screen.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql). Evidencias: E-SRC-004, E-SRC-002, E-SRC-003, E-TASK001-CONT-SUITES, E-TASK001-CONT-REPRO.

Acción: Clasificar campos materiales, snapshots inmutables, renovación obligatoria antes de oferta y evidencia AT5-03.

### FND-003 · ALTA · Cuenta Negocio sustituye a organización autónoma y baja hace cascade

Organization/Membership/Venue no aparecen en inventario acumulado. profiles.user_type Negocio usa mismo auth.users ID, con contenido autor/owner_profile y cascadas. No puede separar eliminación persona, conservación recursos entidad, scopes, revocación ni UNOWNED_RESTRICTED.

Requisitos: RF-01-012, RF-02-002, RF-02-004, RF-02-012, RF-02-013. Archivos: [supabase/functions/delete-account/index.ts](../supabase/functions/delete-account/index.ts), [supabase/migrations/001_initial_schema.sql](../supabase/migrations/001_initial_schema.sql), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql). Evidencias: E-SRC-005, E-SRC-006, E-SRC-007, E-SRC-008.

Acción: Introducir propiedad/representación/membresía organizacional y proceso de baja compatible antes de compromisos de organización.

### FND-004 · ALTA · Eliminación permite credencial existente sin reautenticación

Settings sólo confirma ELIMINAR; Auth delete invokes Edge y Edge getUser valida token pero no contraseña/nonce ni antigüedad reautenticación. Una sesión abierta puede iniciar destrucción permanente.

Requisitos: RF-01-006, RF-01-011. Archivos: [lib/features/auth/data/auth_repository.dart](../lib/features/auth/data/auth_repository.dart), [lib/features/profile/presentation/settings_screen.dart](../lib/features/profile/presentation/settings_screen.dart), [supabase/functions/delete-account/index.ts](../supabase/functions/delete-account/index.ts). Evidencias: E-SRC-009, E-SRC-010, E-SRC-005.

Acción: Exigir reautenticación reciente comprobable servidor y probar token viejo/dispositivo comprometido.

### FND-005 · ALTA · Registro revela cuenta existente por identities vacías

Código convierte usuario fake identities vacío en emailAlreadyUsed y mensaje diferenciado mientras registro nuevo muestra confirmación requerida. Prueba fake signup preserva la distinción, por lo que la respuesta facilita enumeración.

Requisitos: RF-01-007. Archivos: [lib/core/errors/app_failure.dart](../lib/core/errors/app_failure.dart), [lib/features/auth/data/auth_repository.dart](../lib/features/auth/data/auth_repository.dart), [test/features/auth/registration_email_test.dart](../test/features/auth/registration_email_test.dart). Evidencias: E-SRC-011, E-SRC-009, E-SRC-012.

Acción: Respuesta observable homogénea en registro, recuperación/cambio y pruebas temporización/errores sin revelar existencia.

### FND-006 · ALTA · Fichas públicas requieren login en router y backend

Sólo /terms /privacy /delete-account son públicos. Misiones/personas/mapa/fichas redirigen visitante a /login y sus RPC requieren auth; no hay HTML/SSR público indexable.

Requisitos: RF-01-001, RF-07-011, RF-12-011. Archivos: [lib/core/router/app_router.dart](../lib/core/router/app_router.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql), [supabase/migrations/012_mission_map.sql](../supabase/migrations/012_mission_map.sql). Evidencias: E-SRC-013, E-SRC-002, E-SRC-008, E-SRC-014.

Acción: Proyección pública minimizada y rutas/indexación autorizadas manteniendo postulaciones/acuerdos/reportes privados.

### FND-007 · ALTA · Dirección exacta publicada sin autoridad o consentimiento comprobable

Picker default exact, entradas RPC y perfil validan rangos pero no titularidad/sede/UsagePermission/sensibilidad. Approximate redondea cliente, API no impone precisión personal ni fuente vigente. Mapa entrega punto de Mission tal cual.

Requisitos: RF-05-005, RF-05-007, RF-14-003, RF-14-004, RF-14-008. Archivos: [lib/features/community/presentation/post_location_picker.dart](../lib/features/community/presentation/post_location_picker.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql), [supabase/migrations/012_mission_map.sql](../supabase/migrations/012_mission_map.sql). Evidencias: E-SRC-015, E-SRC-002, E-SRC-008, E-SRC-014.

Acción: Separar ubicación personal/comercial, precisión server y autorización/revocación de sede, impedir sensibles y probar bypass API.

### FND-008 · ALTA · Discusión de misión visible a cualquier usuario autenticado

mission_social_visible exige auth y misión no hidden, sin participación/etapa/bloqueo. Texto del panel Conversación son comentarios sociales públicos entre autenticados, no canal privado de coordinación; no report target mensaje ni user_blocks.

Requisitos: RF-11-002, RF-11-007, RF-11-008. Archivos: [lib/features/community/data/mission_social_repository.dart](../lib/features/community/data/mission_social_repository.dart), [lib/features/community/presentation/mission_social_panels.dart](../lib/features/community/presentation/mission_social_panels.dart), [supabase/migrations/020_mission_social.sql](../supabase/migrations/020_mission_social.sql). Evidencias: E-SRC-016, E-SRC-017, E-SRC-018.

Acción: Distinguir preguntas públicas limitadas de conversación privada posterior, autorización por parte/etapa y bloqueo/reporte servidor.

### FND-009 · ALTA · Notificaciones promocionales quedan activadas por defecto

marea_enabled y mareaMessages default true. Worker tras 72h manda mensajes de reactivación a dispositivo enabled sin aceptación de marketing por finalidad; permiso SO no constituye ese registro.

Requisitos: RF-03-013, RF-15-002, RF-15-011. Archivos: [lib/features/notifications/models/notification_preferences.dart](../lib/features/notifications/models/notification_preferences.dart), [lib/features/notifications/presentation/notification_settings.dart](../lib/features/notifications/presentation/notification_settings.dart), [supabase/migrations/014_android_push.sql](../supabase/migrations/014_android_push.sql). Evidencias: E-SRC-019, E-SRC-020, E-SRC-021.

Acción: Opt-in separado/versionado por finalidad, default false y filtrado outbox; preservar transaccionales esenciales.

### FND-010 · ALTA · Payload de push contiene nombre y título sin modo privado

claim_push_jobs construye body con nombre completo actor y post_title y FCM lo envía como notification; título redactado puede contener ubicación/contacto. No hay redacción por nivel de privacidad ni configuración de preview protegida identificada.

Requisitos: RF-11-011, RF-15-006. Archivos: [lib/features/notifications/data/android_push_gateway.dart](../lib/features/notifications/data/android_push_gateway.dart), [supabase/functions/send-push/delivery.ts](../supabase/functions/send-push/delivery.ts), [supabase/migrations/014_android_push.sql](../supabase/migrations/014_android_push.sql). Evidencias: E-SRC-022, E-SRC-023, E-SRC-021.

Acción: Plantilla neutra para lockscreen, obtener contenido tras lectura autorizada y probar privacidad/denegación por plataforma.

### FND-011 · ALTA · Misión cerrada conserva candidaturas pendientes y permite selección

review_application/confirm_mission_selection permiten closed; notify_mission_status sólo avisa sin terminalizar pendientes. La UI afirma posibilidad de reabrir y revisar tras cierre, incompatible con Mission.CERRADA canónica y prohibición nuevas ofertas.

Requisitos: RF-08-012, RF-09-009, RF-09-011. Archivos: [lib/features/community/presentation/mission_management_screen.dart](../lib/features/community/presentation/mission_management_screen.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql). Evidencias: E-SRC-001, E-SRC-002, E-SRC-003, E-TASK001-CONT-SUITES, E-TASK001-CONT-REPRO.

Acción: Implementar máquina canónica y política explícita para pendientes y ofertas vigentes al cierre sin invalidar acuerdos activos.

### FND-012 · MEDIA · Hora actividad depende de dispositivo y no sede

starts_at UTC existe, pero no venue timezone IANA y missionDate usa local dispositivo. Recordatorios actuales son reactivación por zona usuario, no compromisos por hora sede.

Requisitos: RF-03-010, RF-05-001, RF-12-009, RF-15-009. Archivos: [lib/features/community/models/community_models.dart](../lib/features/community/models/community_models.dart), [lib/features/community/presentation/mission_widgets.dart](../lib/features/community/presentation/mission_widgets.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/014_android_push.sql](../supabase/migrations/014_android_push.sql). Evidencias: E-SRC-024, E-SRC-025, E-SRC-002, E-SRC-021.

Acción: Guardar timezone IANA/versión local y mostrar hora sede; probar entre zonas/límites de candidatura.

### FND-013 · MEDIA · Lista de descubrimiento mantiene misiones sin cupo

list_missions discover filtra open/futuro/hidden pero no accepted_count<capacity; mapa sí. Puede aparecer convocatoria que rechaza postulación mission_full.

Requisitos: RF-07-004, RF-07-002. Archivos: [lib/features/community/presentation/missions_screen.dart](../lib/features/community/presentation/missions_screen.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/012_mission_map.sql](../supabase/migrations/012_mission_map.sql). Evidencias: E-SRC-026, E-SRC-002, E-SRC-014.

Acción: Unificar disponibilidad derivada en proyección lista/mapa/feed y probar última plaza.

### FND-014 · MEDIA · Razón de cancelación visible públicamente en payload de misión

Cancellation reason se solicita con etiqueta visible para comunidad y list_missions/list_saved usan to_jsonb(m); no separa razón privada de señal pública/analítica. Motivos pueden narrar incidente sensible.

Requisitos: RF-07-007, RF-13-012. Archivos: [lib/features/community/presentation/mission_management_screen.dart](../lib/features/community/presentation/mission_management_screen.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/012_mission_map.sql](../supabase/migrations/012_mission_map.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql). Evidencias: E-SRC-001, E-SRC-002, E-SRC-014, E-SRC-003.

Acción: Separar motivo privado/auditoría de etiqueta pública y proyectar campos minimizados explícitos.

### FND-015 · MEDIA · Prueba de repositorio acepta filtro que backend rechaza

Test mission listing sends filters and parses server aggregates envía scope=available y MockClient devuelve 200. list_missions servidor sólo acepta all/discover/active/history. La prueba acredita serialización/parsing del mock, no contrato SQL ni filtrado real.

Requisitos: RF-07-001, RF-07-002, RF-07-006, RF-07-012. Archivos: [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [test/features/community/mission_repository_test.dart](../test/features/community/mission_repository_test.dart). Evidencias: E-SRC-002, E-SRC-027.

Acción: Alinear enum/test al contrato y verificar filtros en backend aislado autorizado, incluyendo ocultos/expirados/llenos y permisos.

### FND-016 · ALTA · Expansión social accesible sin gate de fase/capacidad operativa

main instancia feed/stories; HomeScreen usa HomeFeedScreen; CreationChoices expone historia/publicación. FollowButton activo en perfil ajeno, comentarios posts/misiones habilitados. El código no contiene gate POST/conditional/capacidad humana identificado. Presencia de moderación básica no prueba B02 ni moderación escalable.

Requisitos: RF-16-001, RF-16-003, RF-19-006, RF-26-008, RF-26-009, RF-26-013. Archivos: [lib/core/config/app_config.dart](../lib/core/config/app_config.dart), [lib/core/router/app_router.dart](../lib/core/router/app_router.dart), [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart), [lib/features/community/data/social_repository.dart](../lib/features/community/data/social_repository.dart), [lib/features/community/presentation/moderation_screen.dart](../lib/features/community/presentation/moderation_screen.dart), [lib/features/community/presentation/social_panels.dart](../lib/features/community/presentation/social_panels.dart), [lib/features/home_feed/data/home_feed_repository.dart](../lib/features/home_feed/data/home_feed_repository.dart), [lib/features/home_feed/data/stories_repository.dart](../lib/features/home_feed/data/stories_repository.dart), [lib/features/home_feed/presentation/follow_button.dart](../lib/features/home_feed/presentation/follow_button.dart), [lib/features/home_feed/presentation/home_feed_screen.dart](../lib/features/home_feed/presentation/home_feed_screen.dart), [lib/features/home_feed/presentation/stories_rail.dart](../lib/features/home_feed/presentation/stories_rail.dart), [lib/features/home_feed/presentation/story_composer.dart](../lib/features/home_feed/presentation/story_composer.dart), [lib/features/home_feed/presentation/story_viewer.dart](../lib/features/home_feed/presentation/story_viewer.dart), [lib/features/shell/presentation/app_shell.dart](../lib/features/shell/presentation/app_shell.dart), [lib/main.dart](../lib/main.dart), [supabase/functions/story-cleanup/cleanup.ts](../supabase/functions/story-cleanup/cleanup.ts), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql), [supabase/migrations/009_post_reactions.sql](../supabase/migrations/009_post_reactions.sql), [supabase/migrations/010_post_comments.sql](../supabase/migrations/010_post_comments.sql), [supabase/migrations/011_post_collaboration.sql](../supabase/migrations/011_post_collaboration.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql), [supabase/migrations/020_mission_social.sql](../supabase/migrations/020_mission_social.sql). Evidencias: E-SRC-028, E-SRC-013, E-SRC-029, E-SRC-030, E-SRC-031, E-SRC-032, E-SRC-033, E-SRC-034, E-SRC-035, E-SRC-036, E-SRC-037, E-SRC-038, E-SRC-039, E-SRC-040, E-SRC-041, E-SRC-042, E-SRC-007, E-SRC-008, E-SRC-043, E-SRC-044, E-SRC-045, E-SRC-046, E-SRC-018.

Acción: Solicitar decisión humana de alcance; preparar control seguro de fase/módulo y mantener funciones experimentales aisladas hasta evidencia requerida. No retirar automáticamente.

### FND-017 · ALTA · Tours360 y AR avanzados expuestos en flujo normal

Crear, Tus herramientas y Mapa enlazan tours; rutas editor/captura/AR y worker pesado existen sin academic_ar_demo ni gate G7 localizado. Fallback/tracking son piezas útiles pero no aprobación de adopción ni QA físico.

Requisitos: RF-26-010, RF-26-011, RF-26-013. Archivos: [android/app/src/main/kotlin/com/marea/app/TourAR.kt](../android/app/src/main/kotlin/com/marea/app/TourAR.kt), [ios/Runner/AppDelegate.swift](../ios/Runner/AppDelegate.swift), [lib/core/config/app_config.dart](../lib/core/config/app_config.dart), [lib/core/location/device_location_service.dart](../lib/core/location/device_location_service.dart), [lib/core/router/app_router.dart](../lib/core/router/app_router.dart), [lib/features/community/presentation/post_location_picker.dart](../lib/features/community/presentation/post_location_picker.dart), [lib/features/map/data/mission_map_repository.dart](../lib/features/map/data/mission_map_repository.dart), [lib/features/map/presentation/mission_map_screen.dart](../lib/features/map/presentation/mission_map_screen.dart), [lib/features/profile/presentation/profile_tools_sheet.dart](../lib/features/profile/presentation/profile_tools_sheet.dart), [lib/features/shell/presentation/app_shell.dart](../lib/features/shell/presentation/app_shell.dart), [lib/features/showcase/presentation/create_screen.dart](../lib/features/showcase/presentation/create_screen.dart), [lib/features/tours/capture/tour_capture_screen.dart](../lib/features/tours/capture/tour_capture_screen.dart), [lib/features/tours/data/tour_repository.dart](../lib/features/tours/data/tour_repository.dart), [lib/features/tours/presentation/tour_ar_screen.dart](../lib/features/tours/presentation/tour_ar_screen.dart), [lib/features/tours/presentation/tour_editor_screen.dart](../lib/features/tours/presentation/tour_editor_screen.dart), [lib/features/tours/presentation/tour_panorama.dart](../lib/features/tours/presentation/tour_panorama.dart), [lib/features/tours/presentation/tour_visit_screen.dart](../lib/features/tours/presentation/tour_visit_screen.dart), [lib/main.dart](../lib/main.dart), [processing/tours/README.md](../processing/tours/README.md), [processing/tours/worker.py](../processing/tours/worker.py), [supabase/migrations/012_mission_map.sql](../supabase/migrations/012_mission_map.sql), [supabase/migrations/015_tours.sql](../supabase/migrations/015_tours.sql), [supabase/migrations/021_content_cities.sql](../supabase/migrations/021_content_cities.sql). Evidencias: E-SRC-047, E-SRC-048, E-SRC-028, E-SRC-049, E-SRC-013, E-SRC-015, E-SRC-050, E-SRC-051, E-SRC-052, E-SRC-040, E-SRC-053, E-SRC-054, E-SRC-055, E-SRC-056, E-SRC-057, E-SRC-058, E-SRC-059, E-SRC-041, E-SRC-060, E-SRC-061, E-SRC-014, E-SRC-062, E-SRC-063.

Acción: Reconciliar aprobación histórica con SRS v5; proponer aislamiento/gates y recopilar B08/B10/G7 sin reemplazar ni retirar alcance unilateralmente.

### FND-018 · ALTA · Reporte básico carece expediente, bloqueo y apelación

content_reports target posts/missions/showcase y story_reports; motivo texto, open/resolved, sorting cronológico. No caso retornado, severidad/asignación/caducidad, bloqueos ni apelación. No reporte específico de comentarios o tour.

Requisitos: RF-17-001, RF-17-002, RF-17-003, RF-17-004, RF-17-005, RF-17-010, RF-17-011, RF-17-012, RF-19-004. Archivos: [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart), [lib/features/community/data/social_repository.dart](../lib/features/community/data/social_repository.dart), [lib/features/community/presentation/moderation_screen.dart](../lib/features/community/presentation/moderation_screen.dart), [lib/features/community/presentation/social_panels.dart](../lib/features/community/presentation/social_panels.dart), [lib/features/profile/models/profile.dart](../lib/features/profile/models/profile.dart), [lib/features/profile/presentation/edit_profile_screen.dart](../lib/features/profile/presentation/edit_profile_screen.dart), [lib/features/profile/presentation/profile_experience.dart](../lib/features/profile/presentation/profile_experience.dart), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql), [supabase/migrations/009_post_reactions.sql](../supabase/migrations/009_post_reactions.sql), [supabase/migrations/010_post_comments.sql](../supabase/migrations/010_post_comments.sql), [supabase/migrations/011_post_collaboration.sql](../supabase/migrations/011_post_collaboration.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql). Evidencias: E-SRC-029, E-SRC-030, E-SRC-031, E-SRC-032, E-SRC-064, E-SRC-065, E-SRC-066, E-SRC-007, E-SRC-008, E-SRC-043, E-SRC-044, E-SRC-045, E-SRC-046.

Acción: Completar contrato de reporte/medida/decisión/apelación y bloqueo con servidor y capacidad humana antes de UGC público.

### FND-019 · ALTA · Administración integrada y privilegio admin general

/moderation pertenece al router público, community_is_admin usa profiles.role=admin; no MFA obligatorio/cuentas operativas diferenciadas ni auditoría actor/motivo por toda medida.

Requisitos: RF-19-001, RF-19-002, RF-19-003, RF-19-006, RF-25-002. Archivos: [lib/core/config/app_config.dart](../lib/core/config/app_config.dart), [lib/core/router/app_router.dart](../lib/core/router/app_router.dart), [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart), [lib/features/community/presentation/moderation_screen.dart](../lib/features/community/presentation/moderation_screen.dart), [lib/features/shell/presentation/app_shell.dart](../lib/features/shell/presentation/app_shell.dart), [lib/main.dart](../lib/main.dart), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql). Evidencias: E-SRC-028, E-SRC-013, E-SRC-029, E-SRC-031, E-SRC-040, E-SRC-041, E-SRC-007, E-SRC-008, E-SRC-046.

Acción: Preparar consola y roles acotados con MFA, auditoría y flags; validar permisos negativos antes de exposición.

### FND-020 · ALTA · Fichas públicas y SEO pendientes pese a URL compartible

Router sólo deja legales sin login; backend comunitario authenticated. index.html genérico/Flutter bootstrap, no SSR/OG/sitemap. Android sólo launcher y iOS sin associated domains localizados. Retorno allowlist no cubre people/showcase.

Requisitos: RF-22-001, RF-22-002, RF-22-003, RF-22-004, RF-22-005, RF-22-006, RF-22-007. Archivos: [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml), [android/app/src/main/kotlin/com/marea/app/MainActivity.kt](../android/app/src/main/kotlin/com/marea/app/MainActivity.kt), [ios/Runner/AppDelegate.swift](../ios/Runner/AppDelegate.swift), [ios/Runner/Info.plist](../ios/Runner/Info.plist), [lib/core/config/app_config.dart](../lib/core/config/app_config.dart), [lib/core/router/app_router.dart](../lib/core/router/app_router.dart), [pubspec.yaml](../pubspec.yaml), [web/_redirects](../web/_redirects), [web/index.html](../web/index.html). Evidencias: E-SRC-067, E-SRC-068, E-SRC-048, E-SRC-069, E-SRC-028, E-SRC-013, E-SRC-070, E-SRC-071, E-SRC-072.

Acción: Crear contrato/proyección pública minimizada con HTML y links equivalentes después de decisión de implementación; probar bots, retirada, retorno y permisos.

### FND-021 · ALTA · Inventario/retención/backup y supresión no cerrados

Avisos genéricos y textos locales difieren de SQL escolar; no inventario completo de datos nuevos, exportación, política concreta retención ni restore DB+Storage con supresiones. DeleteAccount elimina auth y datos por cascada sin Organization independiente.

Requisitos: RF-19-008, RF-25-001, RF-25-003, RF-25-004, RF-25-005, RF-25-006. Archivos: [.gitignore](../.gitignore), [README.md](../README.md), [docs/legal/README.md](legal/README.md), [docs/legal/aviso-privacidad-escolar-v1.txt](legal/aviso-privacidad-escolar-v1.txt), [docs/legal/terminos-escolar-v1.txt](legal/terminos-escolar-v1.txt), [lib/features/legal/legal_screens.dart](../lib/features/legal/legal_screens.dart), [lib/features/profile/presentation/settings_screen.dart](../lib/features/profile/presentation/settings_screen.dart), [processing/tours/README.md](../processing/tours/README.md), [processing/tours/monitoring-alert.json](../processing/tours/monitoring-alert.json), [pubspec.lock](../pubspec.lock), [pubspec.yaml](../pubspec.yaml), [supabase/config.toml](../supabase/config.toml), [supabase/functions/delete-account/index.ts](../supabase/functions/delete-account/index.ts), [supabase/functions/delete-account/tour-storage.ts](../supabase/functions/delete-account/tour-storage.ts), [supabase/legal/publish-school-v1.sql](../supabase/legal/publish-school-v1.sql), [supabase/migrations/002_account_completion.sql](../supabase/migrations/002_account_completion.sql), [supabase/migrations/015_tours.sql](../supabase/migrations/015_tours.sql). Evidencias: E-SRC-073, E-SRC-074, E-SRC-075, E-SRC-076, E-SRC-077, E-SRC-078, E-SRC-010, E-SRC-060, E-SRC-079, E-SRC-080, E-SRC-070, E-SRC-081, E-SRC-005, E-SRC-082, E-SRC-083, E-SRC-084, E-SRC-062.

Acción: Reconciliar texto realmente servido (root revisa metadata) con documentos aprobados y cerrar B03/B06; definir categorías/excepciones/supresiones y ensayar restore aislado.

### FND-022 · ALTA · Medición de piloto y captación carecen modelo reproducible

Conteos accepted/social y logs técnicos no son n/N de acuerdos/outcomes, propuestas útiles, cohortes/asistido-orgánico/costo humano; no panel/export agregado ni gate de segunda ciudad.

Requisitos: RF-20-001, RF-20-002, RF-20-003, RF-20-004, RF-20-005, RF-20-006, RF-20-007, RF-20-008, RF-20-010, RF-20-011, RF-24-002, RF-24-009. Archivos: [.gitignore](../.gitignore), [README.md](../README.md), [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart), [lib/features/community/models/mission_experience.dart](../lib/features/community/models/mission_experience.dart), [lib/features/community/presentation/mission_management_screen.dart](../lib/features/community/presentation/mission_management_screen.dart), [lib/features/home_feed/data/home_feed_repository.dart](../lib/features/home_feed/data/home_feed_repository.dart), [lib/features/home_feed/presentation/follow_button.dart](../lib/features/home_feed/presentation/follow_button.dart), [lib/features/home_feed/presentation/home_feed_screen.dart](../lib/features/home_feed/presentation/home_feed_screen.dart), [lib/main.dart](../lib/main.dart), [processing/tours/README.md](../processing/tours/README.md), [processing/tours/monitoring-alert.json](../processing/tours/monitoring-alert.json), [pubspec.lock](../pubspec.lock), [pubspec.yaml](../pubspec.yaml), [supabase/config.toml](../supabase/config.toml), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql), [supabase/migrations/020_mission_social.sql](../supabase/migrations/020_mission_social.sql), [supabase/migrations/021_content_cities.sql](../supabase/migrations/021_content_cities.sql). Evidencias: E-SRC-073, E-SRC-074, E-SRC-029, E-SRC-085, E-SRC-001, E-SRC-033, E-SRC-035, E-SRC-036, E-SRC-041, E-SRC-060, E-SRC-079, E-SRC-080, E-SRC-070, E-SRC-081, E-SRC-002, E-SRC-003, E-SRC-046, E-SRC-018, E-SRC-063.

Acción: Definir eventos minimizados/versionados y denominadores/cohortes/ventanas con consentimientos y operación, sin usar likes como valor entregado.

### FND-023 · ALTA · Conectividad y persistencia segura incompletas

Draft misión es servidor; perfil/propuesta sólo memoria, tours local sí persiste. Sin caché contenido con antigüedad ni conflicto cross-device. Supabase.initialize no inyecta almacenamiento protegido explícito; depende del default SDK. SDK local confirmado: supabase_flutter 2.17.2 usa SharedPreferencesLocalStorage por defecto; se conserva sin override en main.

Requisitos: RF-23-007, RF-23-008, RF-23-009, RF-23-010, RF-23-011. Archivos: [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml), [android/app/src/main/kotlin/com/marea/app/MainActivity.kt](../android/app/src/main/kotlin/com/marea/app/MainActivity.kt), [ios/Runner/AppDelegate.swift](../ios/Runner/AppDelegate.swift), [ios/Runner/Info.plist](../ios/Runner/Info.plist), [lib/core/config/app_config.dart](../lib/core/config/app_config.dart), [lib/core/router/app_router.dart](../lib/core/router/app_router.dart), [lib/features/community/presentation/mission_application_screen.dart](../lib/features/community/presentation/mission_application_screen.dart), [lib/features/community/presentation/mission_composer_screen.dart](../lib/features/community/presentation/mission_composer_screen.dart), [lib/features/shell/presentation/app_shell.dart](../lib/features/shell/presentation/app_shell.dart), [lib/features/tours/data/tour_local_store_io.dart](../lib/features/tours/data/tour_local_store_io.dart), [lib/features/tours/data/tour_local_store_web.dart](../lib/features/tours/data/tour_local_store_web.dart), [lib/features/tours/data/tour_progress_store.dart](../lib/features/tours/data/tour_progress_store.dart), [lib/main.dart](../lib/main.dart), [pubspec.yaml](../pubspec.yaml). Evidencias: E-SRC-067, E-SRC-068, E-SRC-048, E-SRC-069, E-SRC-028, E-SRC-013, E-SRC-086, E-SRC-004, E-SRC-040, E-SRC-087, E-SRC-088, E-SRC-089, E-SRC-041, E-SRC-070.

Acción: Confirmar persistencia Auth de versión local y preparar almacenamiento protegido; completar borradores/sync/caché con estados honestos y pruebas offline.

### FND-024 · ALTA · Sanitización backend no uniforme para medios

Perfil normaliza PNG en Edge y tours worker procesa JPEG; posts/showcase/stories suben directo a Storage con MIME/tamaño. Cliente oficial limpia por PNG, pero no sanitizer backend común para todo ingreso ni permisos por imagen identificable.

Requisitos: RF-16-008, RF-23-004, RF-23-005, RF-23-006. Archivos: [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart), [lib/features/community/models/community_models.dart](../lib/features/community/models/community_models.dart), [lib/features/community/presentation/post_composer_screen.dart](../lib/features/community/presentation/post_composer_screen.dart), [lib/features/community/presentation/posts_feed.dart](../lib/features/community/presentation/posts_feed.dart), [lib/features/home_feed/data/stories_repository.dart](../lib/features/home_feed/data/stories_repository.dart), [lib/features/home_feed/presentation/stories_rail.dart](../lib/features/home_feed/presentation/stories_rail.dart), [lib/features/home_feed/presentation/story_composer.dart](../lib/features/home_feed/presentation/story_composer.dart), [lib/features/home_feed/presentation/story_viewer.dart](../lib/features/home_feed/presentation/story_viewer.dart), [lib/features/profile/data/profile_media_repository.dart](../lib/features/profile/data/profile_media_repository.dart), [lib/features/showcase/data/showcase_repository.dart](../lib/features/showcase/data/showcase_repository.dart), [lib/features/showcase/models/showcase.dart](../lib/features/showcase/models/showcase.dart), [lib/features/showcase/presentation/showcase_composer_screen.dart](../lib/features/showcase/presentation/showcase_composer_screen.dart), [lib/features/showcase/presentation/showcase_detail_screen.dart](../lib/features/showcase/presentation/showcase_detail_screen.dart), [supabase/functions/profile-media/image.ts](../supabase/functions/profile-media/image.ts), [supabase/functions/profile-media/index.ts](../supabase/functions/profile-media/index.ts), [supabase/functions/story-cleanup/cleanup.ts](../supabase/functions/story-cleanup/cleanup.ts), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql). Evidencias: E-SRC-029, E-SRC-024, E-SRC-090, E-SRC-091, E-SRC-034, E-SRC-037, E-SRC-038, E-SRC-039, E-SRC-092, E-SRC-093, E-SRC-094, E-SRC-095, E-SRC-096, E-SRC-097, E-SRC-098, E-SRC-042, E-SRC-007, E-SRC-008, E-SRC-046.

Acción: Unificar validación/cuarentena/EXIF backend y consentimiento/retirada por uso; verificar clientes manipulados y medios huérfanos.

### FND-025 · MEDIA · Enum desconocido no siempre degrada con seguridad

ShowcaseKind/Status.values.byName y PostKind.firstWhere lanzan; HomeFeedEntry trata cualquier kind distinto de post como mission. Sin contrato versionado y ventana de clientes soportados.

Requisitos: RF-25-011. Archivos: [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart), [lib/features/community/models/mission_experience.dart](../lib/features/community/models/mission_experience.dart), [lib/features/community/presentation/mission_management_screen.dart](../lib/features/community/presentation/mission_management_screen.dart), [lib/features/home_feed/data/home_feed_repository.dart](../lib/features/home_feed/data/home_feed_repository.dart), [lib/features/home_feed/presentation/follow_button.dart](../lib/features/home_feed/presentation/follow_button.dart), [lib/features/home_feed/presentation/home_feed_screen.dart](../lib/features/home_feed/presentation/home_feed_screen.dart), [lib/features/showcase/data/showcase_repository.dart](../lib/features/showcase/data/showcase_repository.dart), [lib/features/showcase/models/showcase.dart](../lib/features/showcase/models/showcase.dart), [lib/features/showcase/presentation/showcase_composer_screen.dart](../lib/features/showcase/presentation/showcase_composer_screen.dart), [lib/features/showcase/presentation/showcase_detail_screen.dart](../lib/features/showcase/presentation/showcase_detail_screen.dart), [lib/main.dart](../lib/main.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql), [supabase/migrations/020_mission_social.sql](../supabase/migrations/020_mission_social.sql), [supabase/migrations/021_content_cities.sql](../supabase/migrations/021_content_cities.sql). Evidencias: E-SRC-029, E-SRC-085, E-SRC-001, E-SRC-033, E-SRC-035, E-SRC-036, E-SRC-093, E-SRC-094, E-SRC-095, E-SRC-096, E-SRC-041, E-SRC-002, E-SRC-008, E-SRC-003, E-SRC-046, E-SRC-018, E-SRC-063.

Acción: Añadir estrategia de enum desconocido no disponible y contrato expand-migrate-contract con pruebas de cliente anterior.

### FND-026 · MEDIA · Alertas/costos técnicos no equivalen operación piloto

monitoring-alert.json tiene notificationChannels vacío; límites worker/técnicos no son presupuesto monetario, SLO/capacidad operativa ni canal incidentes compromisos.

Requisitos: RF-19-010, RF-19-011, RF-25-009, RF-25-010, RF-25-012. Archivos: [.gitignore](../.gitignore), [README.md](../README.md), [lib/features/profile/presentation/profile_tools_sheet.dart](../lib/features/profile/presentation/profile_tools_sheet.dart), [lib/features/showcase/presentation/create_screen.dart](../lib/features/showcase/presentation/create_screen.dart), [lib/features/tours/capture/tour_capture_screen.dart](../lib/features/tours/capture/tour_capture_screen.dart), [lib/features/tours/data/tour_repository.dart](../lib/features/tours/data/tour_repository.dart), [lib/features/tours/presentation/tour_editor_screen.dart](../lib/features/tours/presentation/tour_editor_screen.dart), [lib/features/tours/presentation/tour_panorama.dart](../lib/features/tours/presentation/tour_panorama.dart), [processing/tours/README.md](../processing/tours/README.md), [processing/tours/monitoring-alert.json](../processing/tours/monitoring-alert.json), [processing/tours/worker.py](../processing/tours/worker.py), [pubspec.lock](../pubspec.lock), [pubspec.yaml](../pubspec.yaml), [supabase/config.toml](../supabase/config.toml), [supabase/migrations/015_tours.sql](../supabase/migrations/015_tours.sql). Evidencias: E-SRC-073, E-SRC-074, E-SRC-052, E-SRC-053, E-SRC-054, E-SRC-055, E-SRC-057, E-SRC-058, E-SRC-060, E-SRC-079, E-SRC-061, E-SRC-080, E-SRC-070, E-SRC-081, E-SRC-062.

Acción: Confirmar estado remoto por metadata con root; definir alertas efectivas/presupuestos y evidencias operativas antes de declarar cumplimiento.

### FND-027 · CRITICO · Selección unilateral sustituye oferta y consentimiento bilateral

review_application cambia status accepted por owner; confirm_mission_selection delega en ella. Lock limita cupo legacy pero no existe AgreementOffer72h, reservation ni aceptación candidata/Agreement. No se etiqueta como explotación confirmada; es incumplimiento de integridad contractual v5.

Requisitos: RB-07, ADR42-02, CTR5-01, CTR5-03, G2. Archivos: [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql). Evidencias: E-SRC-002, E-SRC-003.

Acción: Modelar oferta/reserva/acuerdo/aceptaciones y sustituir selección final; pruebas último cupo, TTL y consentimiento bilateral.

### FND-028 · ALTO · Cierre todavía permite nuevas selecciones

review_application y confirm_mission_selection permiten misión closed. Test exige closed review accepts, contrario a prohibición v5 de nuevas ofertas/candidaturas tras cierre. No hay oferta previa identificable que justifique completar aceptación.

Requisitos: CTR5-02, ADR42-02. Archivos: [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql), [tool/check_mission_database.mjs](../tool/check_mission_database.mjs). Evidencias: E-SRC-002, E-SRC-003, E-SRC-099.

Acción: Al migrar ofertas distinguir emisión prohibida en closed de aceptación de ofertas vigentes anteriores; actualizar tests legacy.

### FND-029 · ALTO · Modelo personal no conserva organización al eliminar cuenta

Negocio es user_type del perfil y recursos author_id ON DELETE CASCADE. Baja elimina auth.users/perfil y recursos, no Organization autónoma ni Membership/UNOWNED_RESTRICTED.

Requisitos: RB-03, RB-04, RB-16, ADR41-01, CTR5-05. Archivos: [supabase/functions/delete-account/index.ts](../supabase/functions/delete-account/index.ts), [supabase/migrations/001_initial_schema.sql](../supabase/migrations/001_initial_schema.sql), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql). Evidencias: E-SRC-005, E-SRC-006, E-SRC-007.

Acción: Separar persona/organización/sede/propiedad, aplicar baja sin herencia y cierre supervisado de compromisos.

### FND-030 · ALTO · Credenciales móviles persisten mediante SharedPreferences por defecto

main usa Supabase.initialize sin authOptions localStorage. Fuente instalada SDK2.17.2 selecciona SharedPreferencesLocalStorage y persiste JSON completo de sesión mediante setString; no adaptador Keychain/Keystore configurado. No se inspeccionaron tokens reales ni se afirma extracción/explotación. Plugins instalados corroboran UserDefaults (iOS) y getSharedPreferences(MODE_PRIVATE) (Android), sin capa enclave indirecta.

Requisitos: CT-PLT-MOB-003, RF-23-011. Archivos: [lib/main.dart](../lib/main.dart), [pubspec.lock](../pubspec.lock). Evidencias: E-SRC-041, E-SRC-080.

Acción: Configurar almacenamiento protegido nativo y migrar/borrar sesión heredada; probar persistencia/logout/reauth por plataforma.

### FND-031 · ALTO · Medios públicos admiten ruta directa sin saneamiento PNG servidor

profile-media sí normaliza PNG con límites/CRC. Policies Upload own para post-images/mission-images/showcase-media/story-images permiten carga directa con MIME/ruta/tamaño y publicación basada en existencia; cliente normaliza pero una llamada Storage propia puede omitir ese cliente. No normalización/quarantine backend equivalente localizada; no se ejecutó upload adversarial.

Requisitos: CT-PRI-DAT-005, ADR42-08, AT5-18. Archivos: [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart), [supabase/functions/profile-media/image.ts](../supabase/functions/profile-media/image.ts), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql). Evidencias: E-SRC-029, E-SRC-097, E-SRC-007, E-SRC-002, E-SRC-008, E-SRC-046.

Acción: Hacer pasar todos medios publicables por validación/normalización servidor antes de proyección pública y ensayar GPS/archivo camuflado/píxeles.

### FND-032 · ALTO · Moderación carece segregación por caso y MFA backend

community_is_admin deriva profiles.role; reports policies conceden acceso global admin. No asignación temporal de caso, audit motivo, apelación/segundo control ni requisito aal2 en funciones privilegiadas. Existencia personal/runbook externa no se evaluó.

Requisitos: CT-SEC-ID-004, CT-SEC-AUT-010, ADR42-12, AT5-12. Archivos: [lib/features/community/presentation/moderation_screen.dart](../lib/features/community/presentation/moderation_screen.dart), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql). Evidencias: E-SRC-031, E-SRC-007, E-SRC-046.

Acción: Implantar permisos operativos, MFA servidor, acceso caducable por caso/auditoría y apelación; probar admin sin MFA/moderador no asignado.

### FND-033 · CRITICO · Baja carece supresión durable para restauración

account_deletion_requests referencia auth.users ON DELETE CASCADE: desaparece al completar baja. No registro durable de supresión ni procedimiento ejecutable restore DB+Storage antes exposición localizado. Esto es riesgo de resurrección sin prueba restore realizada.

Requisitos: CT-PRI-DAT-007, ADR42-09, CTR5-06, AT5-07, B06. Archivos: [supabase/functions/delete-account/index.ts](../supabase/functions/delete-account/index.ts), [supabase/migrations/002_account_completion.sql](../supabase/migrations/002_account_completion.sql). Evidencias: E-SRC-005, E-SRC-084.

Acción: Registro protegido/minimizado de supresiones y procedimiento restore aislado que reaplica bajas/revocaciones antes publicación.

### FND-034 · ALTO · Estados/revisiones legacy contradicen contratos canónicos

Estados open/closed/accepted difieren enumeraciones3.1; lock de condiciones impide parte de cambios en vez de revisión inmutable/consentimiento. statusLabel muestra valor desconocido crudo; no ruta update segura integral.

Requisitos: ADR42-01, ADR42-03, CTR5-07, AT5-14. Archivos: [lib/features/community/models/community_models.dart](../lib/features/community/models/community_models.dart), [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql). Evidencias: E-SRC-024, E-SRC-002, E-SRC-003.

Acción: Migrar contratos enumerados/versionados y revisiones con compatibilidad controlada; test unknown enum y cambios materiales.

### FND-035 · MEDIO · Fichas públicas e indexación HTML no implementadas

Router solicita login para fichas; RPC lectura exige auth.uid. web/index.html sólo bootstrap/meta genérica, no HTML por ficha/sitemap. Seguridad login actual no cumple descubrimiento público/SEO v5.

Requisitos: ADR41-15, CT-PLT-WEB-003, AC-01, AC-24. Archivos: [lib/core/router/app_router.dart](../lib/core/router/app_router.dart), [web/index.html](../web/index.html). Evidencias: E-SRC-013, E-SRC-072.

Acción: Proyección pública minimizada con HTML/metadatos y reglas retiro/caching; mantener privado denegado y probar invitado/bot.

### FND-036 · ALTO · Funciones condicionales sin baseline o gate central

Feed con follows/stories y tours360/AR tienen rutas habilitadas en app; no academic_ar_demo o flag baseline central encontrado. Documentación histórica de autorización de desarrollo no constituye aprobación comercial de release v5.

Requisitos: RB-20, ADR41-09, ADR41-12, G7. Archivos: [lib/core/router/app_router.dart](../lib/core/router/app_router.dart), [supabase/migrations/015_tours.sql](../supabase/migrations/015_tours.sql), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql). Evidencias: E-SRC-013, E-SRC-062, E-SRC-046.

Acción: Registrar autorización vigente/entorno académico y flags seguros por módulo/plataforma; mantener gates externos sin cierre inferido.

### FND-037 · ALTO · Revocación JWT/membresía no se demuestra con auth.uid

RPC de usuario comprueba auth.uid/perfil/baja, no session_id/auth.sessions de sesión revocada. Membership no existe; Realtime stream carga notificaciones privadas antes de map(void). No se afirma fallo explotado de JWT/Reatime sin ensayo, falta enforcement/escenario requerido.

Requisitos: CT-SEC-ID-006, CT-SEC-AUT-005, ADR42-06. Archivos: [docs/account-completion.md](account-completion.md), [lib/features/community/data/social_repository.dart](../lib/features/community/data/social_repository.dart), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql). Evidencias: E-SRC-100, E-SRC-030, E-SRC-007, E-TASK001-CONT-SUITES, E-TASK001-CONT-REPRO.

Acción: Definir revocación efectiva de sesiones/membresías en nuevas lecturas/canales/archivos y probar con socket/JWT anterior en entorno aislado.

### FND-038 · ALTO · Evidencias externas no obtenidas para puertas de release

Moderación dotada, aprobación jurídica, mercado, restore, tiendas, antifraude real y rúbrica académica necesitan evidencias externas no recibidas. NO_AUDITADO expresa esta limitación, no inexistencia.

Requisitos: B02, B03, B04, B05, B06, B07, B09, B10. Archivos: [docs/MAREA_SRS.md](MAREA_SRS.md). Evidencias: E-SRC-101.

Acción: Solicitar y registrar evidencias concretas por bloqueo, sin declarar GO por inspección estática.

### FND-039 · MEDIO · Advisors requieren contextualización y pruebas, no conteo como vulnerabilidades

Avisos previos INFO22 RLS sin policies, WARN3 anonymous definer, WARN70 authenticated definer, WARN1 leaked password fueron contexto proporcionado por raíz, no evidencia nueva de esta subauditoría. Tablas internas sin grants cliente usan denegación por defecto; boolean username/policy y helpers auth.uid son APIs justificables; workers verify_jwt=false validan secreto y geocoding escritura valida getUser/RLS. Grants remotos y auth settings requieren revisión contextual antes de conclusión.

Requisitos: CT-SEC-AUT-001, CT-SEC-AUT-003, B01. Archivos: [supabase/config.toml](../supabase/config.toml), [supabase/migrations/001_initial_schema.sql](../supabase/migrations/001_initial_schema.sql), [supabase/migrations/002_account_completion.sql](../supabase/migrations/002_account_completion.sql), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/014_android_push.sql](../supabase/migrations/014_android_push.sql), [supabase/migrations/021_content_cities.sql](../supabase/migrations/021_content_cities.sql). Evidencias: E-SRC-081, E-SRC-006, E-SRC-084, E-SRC-007, E-SRC-021, E-SRC-063.

Acción: Cruzar cada aviso con grants/policies/cuerpo/rol/config actual de desarrollo y priorizar casos con bypass demostrable; habilitar protección passwords si procede con evaluación de configuración.

### FND-040 · MEDIA · Configuración remota observada y límites de equivalencia

Supabase confirma 21 migraciones, 46 tablas public/private con RLS habilitado, 55 políticas, 140 firmas de función, 7 buckets privados y 6 Edge Functions activas. El nombre/versión de migración no prueba que su cuerpo coincida; se conservan hashes MD5 de definiciones remotas sin comparar a dumps equivalentes. verify_jwt=false en workers requiere autenticación manual contextual. No se ejecutaron funciones ni consultaron filas personales.

Requisitos: CT-SEC-AUT-001, CT-SEC-AUT-003, CT-SEC-AUT-004, CT-SEC-ID-008, RF-25-007. Archivos: . Evidencias: E-REMOTE-METADATA, E-REMOTE-MIGRATIONS, E-REMOTE-EDGE-FUNCTIONS.

Acción: Preparar comparación de contratos y pruebas negativas en staging; no promover autorización segura por RLS habilitado.

### FND-041 · ALTA · Avisos de seguridad Supabase requieren revisión contextual

Proveedor reporta protección contra contraseñas filtradas desactivada, 22 avisos INFO de RLS sin políticas, 3 WARN de funciones security definer disponibles para anon y 70 para authenticated. Algunas tablas se usan exclusivamente vía RPC y los workers verifican secretos manualmente; estos avisos no equivalen a exploits comprobados.

Requisitos: CT-SEC-ID-002, CT-SEC-AUT-001, CT-SEC-AUT-003. Archivos: . Evidencias: E-REMOTE-SECURITY-ADVISORS.

Acción: Evaluar acceso/actor/search_path/privilegios de cada firma; resolver configuración Auth con aprobación y pruebas aisladas, sin cambiar remoto durante auditoría.

## Implementaciones potencialmente innecesarias

### ORF-001 · POR_VALIDAR · Historias24h y seguidores: expansión sin RF directo habilitado

Historias/seguidores operan como producto social; SRS no exige stories y pospone seguidores/feed universal.

Ubicación: [lib/features/home_feed/data/home_feed_repository.dart](../lib/features/home_feed/data/home_feed_repository.dart), [lib/features/home_feed/data/stories_repository.dart](../lib/features/home_feed/data/stories_repository.dart), [lib/features/home_feed/presentation/follow_button.dart](../lib/features/home_feed/presentation/follow_button.dart), [lib/features/home_feed/presentation/home_feed_screen.dart](../lib/features/home_feed/presentation/home_feed_screen.dart), [lib/features/home_feed/presentation/stories_rail.dart](../lib/features/home_feed/presentation/stories_rail.dart), [lib/features/home_feed/presentation/story_composer.dart](../lib/features/home_feed/presentation/story_composer.dart), [lib/features/home_feed/presentation/story_viewer.dart](../lib/features/home_feed/presentation/story_viewer.dart), [lib/main.dart](../lib/main.dart), [supabase/functions/story-cleanup/cleanup.ts](../supabase/functions/story-cleanup/cleanup.ts), [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql), [supabase/migrations/020_mission_social.sql](../supabase/migrations/020_mission_social.sql). Requisitos relacionados: RF-16-001, RF-16-003, RF-26-009, RF-26-013.

Motivo: La capacidad implementada rebasa núcleo piloto y requiere aprobación/capacidad escalable; no se afirma falta de uso.

Dependencias activas: main→SupabaseStoriesRepository/SupabaseHomeFeedRepository, HomeFeedScreen→StoriesRail, CreationChoices→/stories/new, ProfileExperience→FollowButton, AppRouter→StoryComposer, publish_story/list_stories/set_profile_follow/home_feed. Costo/riesgo: UGC efímero, privacidad, retención y costo de operación/moderación adicionales..

Recomendación: Proponer decisión mantener condicional/aislar/retrabajar tras evidencia de valor; no retirar automáticamente.

Evidencia adicional: Aprobación humana de release v5, métricas adopción, costo Storage/cleanup y dotación moderación.. Decisión pendiente de aprobación; no autoriza eliminación.

### ORF-002 · POR_VALIDAR · Tours360/editor AR/worker pesado

Recorridos interiores con panoramas, enlaces, capturas esfera y tracking imagen nativo.

Ubicación: [android/app/src/main/kotlin/com/marea/app/TourAR.kt](../android/app/src/main/kotlin/com/marea/app/TourAR.kt), [ios/Runner/AppDelegate.swift](../ios/Runner/AppDelegate.swift), [lib/features/profile/presentation/profile_tools_sheet.dart](../lib/features/profile/presentation/profile_tools_sheet.dart), [lib/features/showcase/presentation/create_screen.dart](../lib/features/showcase/presentation/create_screen.dart), [lib/features/tours/capture/tour_capture_screen.dart](../lib/features/tours/capture/tour_capture_screen.dart), [lib/features/tours/data/tour_repository.dart](../lib/features/tours/data/tour_repository.dart), [lib/features/tours/presentation/tour_ar_screen.dart](../lib/features/tours/presentation/tour_ar_screen.dart), [lib/features/tours/presentation/tour_editor_screen.dart](../lib/features/tours/presentation/tour_editor_screen.dart), [lib/features/tours/presentation/tour_panorama.dart](../lib/features/tours/presentation/tour_panorama.dart), [lib/features/tours/presentation/tour_visit_screen.dart](../lib/features/tours/presentation/tour_visit_screen.dart), [processing/tours/README.md](../processing/tours/README.md), [processing/tours/worker.py](../processing/tours/worker.py), [supabase/migrations/015_tours.sql](../supabase/migrations/015_tours.sql). Requisitos relacionados: RF-26-008, RF-26-010, RF-26-011, RF-26-013.

Motivo: RF26-011 pide posponer hasta adopción/dispositivos; la implementación sí tiene callers reales.

Dependencias activas: CreationChoices→/tours/new, ProfileTools→/tours, MissionMapScreen→/tours/nearby, AppRouter→TourEditor/Capture/Visit/AR, SupabaseTourRepository→tours_* RPC, tour-dispatch→processing/tours/worker.py. Costo/riesgo: Dependencias Hugin/CloudRun, memoria/red móvil, permisos cámara/sensores y derechos sedes/obras..

Recomendación: Proponer gate/aislamiento académico y decisión de alcance basada en G7/B10, preservando trabajo existente.

Evidencia adicional: Revisión de aprobación previa, dispositivos físicos, fotos reales, adopción y costos GPU/CPU/Storage.. Decisión pendiente de aprobación; no autoriza eliminación.

### ORF-003 · POR_VALIDAR · Posts product/service/project/space/event frente a Showcase y PublicActivity

Posts admite formatos comerciales/obra/sede/evento; Showcase tiene ficha separada project/product/service con status/galería/precio.

Ubicación: [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart), [lib/features/community/models/community_models.dart](../lib/features/community/models/community_models.dart), [lib/features/community/presentation/post_composer_screen.dart](../lib/features/community/presentation/post_composer_screen.dart), [lib/features/community/presentation/posts_feed.dart](../lib/features/community/presentation/posts_feed.dart), [lib/features/showcase/data/showcase_repository.dart](../lib/features/showcase/data/showcase_repository.dart), [lib/features/showcase/models/showcase.dart](../lib/features/showcase/models/showcase.dart), [lib/features/showcase/presentation/showcase_composer_screen.dart](../lib/features/showcase/presentation/showcase_composer_screen.dart), [lib/features/showcase/presentation/showcase_detail_screen.dart](../lib/features/showcase/presentation/showcase_detail_screen.dart), [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql), [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql). Requisitos relacionados: RF-16-001, RF-16-002, RF-22-001, RF-26-004.

Motivo: Dos representaciones de obra/producto/servicio y post event sin PublicActivity canónica pueden dispersar búsqueda/privacidad/ciclo. No es redundancia probada: catálogo y post pueden ser proyecciones distintas.

Dependencias activas: CreateScreen→/posts/new y /showcase/new, ExploreScreen→PostsFeed/ShowcaseFeed, ProfileExperience→PostsFeed y ShowcaseFeed, PostComposer→savePost, ShowcaseComposer→save. Costo/riesgo: Duplicación de contenido, reglas divergentes, eventos sin estado/consentimiento y mantenimiento extra..

Recomendación: Revisar contrato relación/proyección y decisión conservar/sustituir sin eliminar datos ni alcance por cuenta propia.

Evidencia adicional: Uso real de ambos formatos, modelo editorial/origen y mapa por RF; verificar links/callers y migración compatible.. Decisión pendiente de aprobación; no autoriza eliminación.

### ORF-004 · SIN_USO · PlaceholderScreen sin referencias activas localizadas

Widget genérico Próximamente no importado ni construido en lib/test según búsqueda de nombre/path.

Ubicación: [lib/features/shell/presentation/placeholder_screen.dart](../lib/features/shell/presentation/placeholder_screen.dart). Requisitos relacionados: RF-26-013.

Motivo: Candidato SIN_USO en fuentes actuales; no se infiere por falta de navegación sino búsqueda de imports/usos/callers. No prueba ausencia en ramas/publicaciones anteriores.

Dependencias activas: Ningún import/caller en lib o tests encontrado. Costo/riesgo: Código muerto pequeño puede confundir promesas/alcance; costo bajo hasta decisión..

Recomendación: Proponer revisión de retiro en decisión humana; no tocar automáticamente y comprobar referencias externas antes.

Evidencia adicional: Búsqueda global de PlaceholderScreen y placeholder_screen.dart; historial/ramas no auditados.. Decisión pendiente de aprobación; no autoriza eliminación.

### ORF-005 · POR_VALIDAR · RPC wrappers legacy siguen en cadena activa

create_mission_legacy/update_mission_legacy renombrados y revocados al cliente, pero usados por wrappers before_city.

Ubicación: [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql), [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql), [supabase/migrations/021_content_cities.sql](../supabase/migrations/021_content_cities.sql). Requisitos relacionados: RF-25-008, RF-25-011.

Motivo: Nombre legacy no prueba obsoleto: forman parte de creación/edición actual. Su semántica de estados/condiciones es legado frente v5.

Dependencias activas: CommunityRepository→create_mission/update_mission, 021→create_mission_before_city/update_mission_before_city, 013→create_mission_legacy/update_mission_legacy, publish_mission_draft→create_mission. Costo/riesgo: Cambios precipitados rompen creación/draft/publicación; wrappers complican trazabilidad..

Recomendación: Mantener mientras sean dependencia activa; planear evolución compatible con contratos v5, sin eliminar por nombre.

Evidencia adicional: Tests/contrato de permisos y versión soportada; historia de migración y runtime remoto root.. Decisión pendiente de aprobación; no autoriza eliminación.

### ORF-006 · POR_VALIDAR · PostsFeed conservado tras HomeFeedScreen

HomeScreen delega HomeFeedScreen, pero PostsFeed lista perfiles/búsqueda/guardados y fallback de feed.

Ubicación: [lib/features/community/presentation/explore_screen.dart](../lib/features/community/presentation/explore_screen.dart), [lib/features/community/presentation/posts_feed.dart](../lib/features/community/presentation/posts_feed.dart), [lib/features/home_feed/presentation/home_feed_screen.dart](../lib/features/home_feed/presentation/home_feed_screen.dart), [lib/features/profile/presentation/profile_experience.dart](../lib/features/profile/presentation/profile_experience.dart). Requisitos relacionados: RF-16-001, RF-16-004, RF-26-009.

Motivo: No es huérfano muerto ni redundancia demostrada; comparte PostCard y mantiene consumers. Candidato sólo para consolidación arquitectónica basada en contrato.

Dependencias activas: ExploreScreen→PostsFeed, ProfileExperience→PostsFeed, HomeFeedScreen→PostsFeed, HomeFeedScreen→PostCard. Costo/riesgo: Retiro sin revisar callers rompe explorar/perfiles/guardados; listas con reglas distintas pueden divergir..

Recomendación: Documentar consumers y evaluar consolidación sin eliminar componente usado.

Evidencia adicional: Pruebas de explore/profile/guardados y fallback; métricas de mantenimiento.. Decisión pendiente de aprobación; no autoriza eliminación.

### ORF-007 · POR_VALIDAR · Documentos legales locales divergen de script de publicación

README afirma textos breves publicados con contacto existente; txt actuales usan otra denominación/contactos y más contenido; SQL conserva versión escolar inicial.

Ubicación: [docs/legal/README.md](legal/README.md), [docs/legal/aviso-privacidad-escolar-v1.txt](legal/aviso-privacidad-escolar-v1.txt), [docs/legal/terminos-escolar-v1.txt](legal/terminos-escolar-v1.txt), [supabase/legal/publish-school-v1.sql](../supabase/legal/publish-school-v1.sql). Requisitos relacionados: RF-19-008, RF-25-001, RF-25-005.

Motivo: No deben tratarse archivos locales como versión vigente servida ni aprobación legal. Modificar texto local no actualiza backend.

Dependencias activas: LegalRepository→registration_policy, LegalScreens→LegalDocument.body, publish-school-v1.sql→legal_documents/registration_settings. Costo/riesgo: Mensajes de privacidad/visibilidad/contacto incompatibles y falsa evidencia de cumplimiento..

Recomendación: Proponer nueva versión aprobada coherente con producto actual, sólo después reconciliar metadata y decisión jurídica; no republicar script antiguo.

Evidencia adicional: Hash/contenido real de documentos servidos, aprobación humana y B03; root audita metadata readonly.. Decisión pendiente de aprobación; no autoriza eliminación.

## Decisiones y conflictos normativos

### DEC-001 · PENDIENTE_APROBACION · Interpretación normativa: AC-04, CTR5-05, ADR41-01, RB-16

AC04 exige transferencia/disolución cuando dueño único elimina con compromisos; CTR5-05 garantiza iniciar baja personal y restringir organización sin sucesor. Una lectura de AC04 como bloqueo absoluto de baja contradice precisión v5.

Propuesta/decisión: Registrar DECISION sin editar SRS: permitir solicitud personal inmediatamente, UNOWNED_RESTRICTED y cierre supervisado; transferencia/disolución se exige para resolver compromisos, no como impedimento indefinido de derecho de baja.

### DEC-002 · PENDIENTE_APROBACION · Interpretación normativa: AC-10, CTR5-04, RB-11

AC10 describe resultado sin respuesta como autodeclarado sin distinguir waiting vs SIN_RESPUESTA tras7 días; CTR5-04 y máquina3.1 precisan ventana/estado.

Propuesta/decisión: Registrar precisión de prueba: preservar no bilateral siempre, mostrar ESPERANDO_SEGUNDA_CONFIRMACION durante ventana y SIN_RESPUESTA tras7 días, sin reputación automática.

### DEC-003 · PENDIENTE_APROBACION · Interpretación normativa: AC-25, CTR5-10, RB-21

AC25 usa en-US aunque base/piloto sólo es-MX. No contradicción si AC25 se ejecuta cuando inglés haya sido aprobado; falta precondición explícita en escenario heredado.

Propuesta/decisión: Conservar AC25 y registrar precondición de release en-US aprobado, no habilitar idioma sólo para poder ejecutar el escenario.

### DEC-004 · REGISTRADA · Protección y separación de fuentes

SRS byte a byte protegido. YAML estados canónicos y cuatro documentos generados con delimitadores. Estados no se recalculan desde archivos.

Propuesta/decisión: Aprobación humana en esta conversación; sin modificación normativa ni commit.

### DEC-005 · PENDIENTE_APROBACION · Fases de controles, escenarios y cláusulas sin ID original

No tienen fase individual inequívoca; se mantienen null y visibles. PRODUCTO_COMPLETO es agregado, no fase.

Propuesta/decisión: Resolver interpretación por ID con respaldo normativo y aprobación explícita; no heredar fase del módulo ni de RF relacionado.

### DEC-006 · REGISTRADA · Conservar evidencia histórica sin validación vigente automática

SHA256 por archivo y commit; cambios señalan potencial obsolescencia, sin modificar estados. Corresponde a precisión aprobada por el usuario.

Propuesta/decisión: Reconfirmar aplicabilidad con persona, fecha, motivo y huellas actuales, conservando snapshot previo.

### DEC-007 · REGISTRADA · Correcciones de revisión independiente del seguimiento

Se corrigieron metadatos/historial obligatorios, identidad de catálogo, cifras narrativas derivadas, aplicabilidad de fallos históricos y correspondencias de tareas/cláusulas. Son cambios del seguimiento durante auditoría inicial, sin cambiar lógica de negocio.

Propuesta/decisión: Regresiones ejecutadas y revisión independiente; evidencia histórica conservada, SRS intacto.

### DEC-008 · REGISTRADA · Huellas de tests también obligatorias en validación vigente

Una corrida completa sólo acredita vigencia si referencia tanto archivos de implementación como tests asociados. Cambiar un test invalida aplicabilidad de su resultado previo sin alterar estados.

Propuesta/decisión: Regresión con fallo observado y 21 casos aprobados; corridas anteriores conservadas.

### DECISION-51-01 · APROBADA_CONDICIONADA · Corrección normativa v5.1

Oferta aceptada terminal sin segunda firma | Organizador acepta al emitir; destinatario completa bilateralidad dentro de TTL, todo atómico

Propuesta/decisión: Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.

### DECISION-51-02 · APROBADA_CONDICIONADA · Corrección normativa v5.1

Revisión material sobre acuerdo activo | Revisión vigente persiste; propuesta separada con aceptación bilateral y plazo explícito

Propuesta/decisión: Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.

### DECISION-51-03 · APROBADA_CONDICIONADA · Corrección normativa v5.1

Titularidad de misiones legadas ambigua | Clasificar con evidencia o aislar histórico solo lectura; sin dueños inventados

Propuesta/decisión: Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.

### DECISION-51-04 · APROBADA_CONDICIONADA · Corrección normativa v5.1

Cliente antiguo muestra `accepted` engañosamente | Proyección segura o `UPDATE_REQUIRED`; probar binario real y cache

Propuesta/decisión: Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.

### DECISION-51-05 · APROBADA_CONDICIONADA · Corrección normativa v5.1

Representante revocado o entidad suspendida | Diferenciar pérdida de permiso individual de suspensión de entidad; fail-closed para nuevas obligaciones

Propuesta/decisión: Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.

### DECISION-51-06 · APROBADA_CONDICIONADA · Corrección normativa v5.1

Borrado de organizador personal | Transiciones por recurso, retención mínima justificada y supresión en restauración

Propuesta/decisión: Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.

### DECISION-51-07 · APROBADA_CONDICIONADA · Corrección normativa v5.1

Pruebas sin IDs individuales | `TC-51-001…021` independientes de RF y evidencias antiguas

Propuesta/decisión: Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.

### DECISION-51-08 · APROBADA_CONDICIONADA · Corrección normativa v5.1

Estado documental anticipa aprobación | Documento marcado como propuesta pendiente y baseline anterior vigente hasta reconciliación

Propuesta/decisión: Aprobación conceptual para diseño/N/T; no autoriza migración, Flutter, remoto ni adopción efectiva anticipada.

### DECISION-T002-REVISION-TTL · APROBADA_PROVISIONAL · Plazo provisional del piloto

Siete días naturales calculados por servidor en UTC, acortados por ejecución; aceptación retroactiva prohibida.

Propuesta/decisión: Revisar cercanía a ejecución, límite exacto, expiración y rechazo antes de habilitar.

### D-TASK002-U0-ELIGIBILITY-CONTROL · PENDIENTE_PRECISION_NORMATIVA · undefined

RF-09-001 personal-own prohibition, RB-06 own mission, AT5-04 controlled organizations and section 4.4 admissible related collaborations need exact control/admissibility boundary; no SRS change or blanket membership prohibition.

Propuesta/decisión: pendiente

## Pruebas ejecutadas

| Corrida | Comando | Resultado | Casos | Límite |
| --- | --- | --- | --- | --- |
| RUN-FLUTTER | flutter test --no-pub --reporter expanded | PASS | 555 aprobadas; 2 omitidas | Flutter VM/mocks; sin runtime web/Android/iOS ni backend real |
| RUN-ANALYZE | flutter analyze --no-pub | PASS | Sin incidencias | Análisis estático; no prueba comportamiento |
| RUN-NODE | node --test test/tool/backend_contract_test.mjs supabase/functions/geocoding/geocoding_test.mjs supabase/functions/geocoding/lease_test.mjs | PASS | 21 aprobadas | Contratos locales/fakes; no DB remota |
| RUN-WORKER-INITIAL | .venv-tours/bin/python -m unittest discover -s processing/tours/tests -v | INVOCATION_ERROR | 3 casos; 2 errores de importación | PYTHONPATH faltante; no defecto de negocio confirmado |
| RUN-WORKER | PYTHONPATH=processing/tours PYTHONDONTWRITEBYTECODE=1 .venv-tours/bin/python -m unittest discover -s processing/tours/tests -v | PASS | 25 aprobadas | Mocks; no Hugin real ni worker remoto |
| RUN-TRACKING | node --test tool/traceability/traceability.test.mjs | PASS | 20 aprobadas | Integridad de seguimiento, no funcionalidad MAREA |
| RUN-NATIVE | swiftc TourOrientation.swift + NativeTests como main.swift; ejecutar binarios temporales | PASS | 7 orientación + 8 tracking | Swift en host macOS; no dispositivo iOS ni ARKit |
| RUN-BUILD-WEB | flutter build web --no-pub; defines ficticios; copia temporal | PASS | bundle web | Sólo compilación; no ejecución de flujos, conectividad ni distribución. |
| RUN-BUILD-ANDROID | flutter build apk --debug --no-pub; defines ficticios; copia temporal | PASS | APK debug | Sólo compilación; no ejecución de flujos, conectividad ni distribución. |
| RUN-BUILD-IOS | flutter build ios --simulator --debug --no-pub; defines ficticios; copia temporal | PASS | Runner.app simulador, sin firma | Sólo compilación; no ejecución de flujos, conectividad ni distribución. |
| RUN-ANDROID-NATIVE | ./gradlew app:testDebugUnitTest (copia temporal) | PASS | 3 pruebas JVM; 0 omitidas/fallidas | Orientación matemática; no Android real/cámara/ARCore |
| RUN-TRACKING-FINAL | node --test tool/traceability/traceability.test.mjs | PASS | 20 aprobadas; 0 fallidas/omitidas | Integridad del seguimiento; no acredita funcionalidad MAREA |
| RUN-TRACKING-SOURCE-BINDING | node --test tool/traceability/traceability.test.mjs | PASS | 21 aprobadas;0 fallidas/omitidas | Seguimiento, sin pruebas funcionales nuevas de MAREA. |
| RUN-TASK001-SUPABASE-20261013T164530Z | node tool/staging/cli.mjs start <runtime privado propio> | BLOQUEADO | Arranque real fallido: ECONNREFUSED 127.0.0.1:61002; CLI detuvo contenedores. | No stack saludable ni prueba de egreso; ninguna migración/función MAREA ejecutada. |
| RUN-TASK001-GUARDS-20261013T164530Z | node --test tool/staging/guard.test.mjs; seed/test/start guardados | PASS | 4 unitarias + 3 rechazos CLI comprobados. | Host/fixtures de filesystem; no autorización HTTP, PostgreSQL, Storage ni dispositivo. |
| RUN-TASK001-SUITES-20261013T164530Z | No ejecutado: H5 dependiente de H3/H4 bloqueados. | BLOQUEADO | 129 escenarios especificados: 117 bloqueados, 6 sin contrato y 6 pendientes de dispositivo; 0 ejecutados. | Node HTTP/pgTAP/Dart repositorio no implementados aún; no mocks nuevos. |
| RUN-TASK001-INTEGRITY-20261013T164530Z | npm test --prefix tool/traceability | PASS | 21 aprobadas, 0 fallidas/omitidas. | Integridad del seguimiento exclusivamente. |
| RUN-TASK001-CONT-SUITES | node tool/staging/cli.mjs test <fresh-private-runtime>; node tool/staging/storage-expiration.mjs <runtime>; node tool/staging/ingress-test.mjs <runtime> | FAIL | Por runtime: 129 definidos,119 cubiertos;734 subcasos:726 PASS,5 FAIL,3 NO_IMPLEMENTADO,0 PENDIENTE,0 BLOQUEADO. Escenarios:113 PASS parciales,5 FAIL,5 NO_IMPLEMENTADO (incluye límites de sesión),6 PENDIENTE dispositivo. | 621 subcasos reales,113 inspección,0 mock. Autorización de filas y semántica de RPC por estado/actor/acción parciales. No validación integral de RF ni QA Android/iOS. |
| RUN-TASK001-CONT-REPRO | prepare/start/seed/test en runtime nuevo, conservar anteriores | PASS | 21 migraciones originales y seis bundles idénticos; mismos 734 resultados en dos runtimes independientes. | Imagen de red reproducible mediante artefacto local inmutable; no se presume reconstrucción APK mutable ni equivalencia remota. |
| RUN-TASK001-CONT-CHECKS | npm test --prefix tool/traceability; validate; render; check; render sin cambios | PASS | 21 tests de trazabilidad y10 guards PASS; SRS original; segunda generación sin escrituras. | Integridad del seguimiento; ninguna certificación funcional integral. |
| RUN-TASK002-NT-TOOLS | node --test tool/traceability/traceability.test.mjs | PASS | 34/34 herramientas; 21 regresiones preexistentes y 13 nuevas. | No prueba contratos de producto, migraciones, datos reales, Flutter o dispositivos. Complete requirement validation false. |

## Límites

- **LIM-001:** Sin pruebas E2E contra backend ni matriz permitido/denegado con identidades reales o temporales: remoto sólo metadata. Evidencia pendiente: Staging aislado autorizado y fixtures controlados para RLS/Storage/Realtime/RPC.
- **LIM-002:** Compilaciones web, APK debug y app iOS simulador aprobaron en copia temporal con configuración ficticia. No se ejecutaron flujos completos en esas plataformas ni distribución. Xcode/simuladores disponibles, sin ejecución iOS de app/ARKit; tests Swift sólo host macOS. Evidencia pendiente: Corridas por plataforma con dispositivo/navegador, versión, permisos y recibos; publicación separada del backend.
- **LIM-003:** Sin equivalencia completa del cuerpo de migraciones/funciones locales y remotas; Deno no disponible y pruebas DB con escritura excluidas. Evidencia pendiente: Dump normalizado de metadatos/definiciones no personales y pruebas aisladas; no ejecutar tool/check_* sin revisar sus efectos.
- **LIM-004:** Controles externos y cláusulas transversales sin evidencia suficiente se conservan NO_AUDITADO individualmente. No existe porcentaje global definitivo ni esfuerzo realizado inferible. Evidencia pendiente: Responsables, documentos humanos, pruebas de obligación completa y aprobaciones por ID.
- **LIM-005:** No se consultaron conteos/filas de auth.users ni datos de personas; no se buscó demostrar ausencia de usuarios reales. Evidencia pendiente: Confirmación humana de entorno (ya recibida) y revisión agregada mínima sólo si necesaria.
- **LIM-006:** Subcriterios /Cxx son descomposición de auditoría, no IDs normativos nuevos ni ponderación aprobada. IDs TR-S* sólo identifican cláusulas antes sin ID. Evidencia pendiente: Congelar correspondencia de fragmento/hash; cambios normativos sólo con aprobación/versionado; no renumerar historial.
- **LIM-TASK001-20261013T164530Z:** Limitación histórica conservada de run-20261013T164530Z. TASK-001 incompleta: H1/H2 PASS; H3 falla conexión al PostgreSQL local con red interna. H4/H5 detenidos. No se acreditan autorizado/denegado/concurrencia/expiración reales. DDL destructivo histórico y job automático también impiden replay bajo las restricciones vigentes. Bloqueo superado en la continuación local; consultar E-TASK001-CONT-CAUSE/SCHEMA/SUITES/REPRO/CHECKS. Evidencia pendiente: Resolver arranque con aislamiento efectivo, revisar ruta no destructiva del esquema, ejecutar fixtures .invalid y Node HTTP/pgTAP/Dart; QA Android/iOS separado. Evidencias E-TASK001-SUPABASE-20261013T164530Z y E-TASK001-SUITES-20261013T164530Z.
- **LIM-TASK001-CONT:** El bloqueo histórico de run-20261013T164530Z queda superado por evidencia local H3/H4/H5; se conserva el evento anterior. Persisten cinco regresiones fallidas, cuatro contratos ausentes, tres restricciones de sesión sin configurar y seis escenarios de dispositivo pendientes. Cobertura parcial de filas/RPC. Ningún requisito VALIDADO por esta corrida. Evidencia pendiente: TASK-002/TASK-003 y QA posterior con pruebas de criterios completos, datos sintéticos y dispositivos reales.

## Evidencias y vigencia

| ID | Tipo | Resultado | Vigencia de archivos | Referencia / norma |
| --- | --- | --- | --- | --- |
| E-NORM-001 | NORMATIVE_SOURCE | OBSERVADO | POTENCIALMENTE_OBSOLETA | [docs/MAREA_SRS.md](MAREA_SRS.md) · SRS-5.0 |
| E-BASELINE-001 | REPOSITORY_MANIFEST | OBSERVADO | ACTUAL | [docs/evidence/2026-10-13/repository-baseline.json](evidence/2026-10-13/repository-baseline.json) · SRS-5.0 |
| E-ENV-001 | USER_CONFIRMATION | OBSERVADO | ACTUAL | El usuario confirma backend Supabase Marea de desarrollo; operativo pendiente de piloto pequeño y lanzamiento. No implica distribución de clientes. · SRS-5.0 |
| E-REMOTE-MIGRATIONS | REMOTE_CONFIGURATION | OBSERVADO | ACTUAL | [docs/evidence/2026-10-13/supabase-migrations.json](evidence/2026-10-13/supabase-migrations.json) · SRS-5.0 |
| E-REMOTE-EDGE-FUNCTIONS | REMOTE_CONFIGURATION | OBSERVADO | ACTUAL | [docs/evidence/2026-10-13/supabase-edge_functions.json](evidence/2026-10-13/supabase-edge_functions.json) · SRS-5.0 |
| E-REMOTE-SECURITY-ADVISORS | REMOTE_CONFIGURATION | OBSERVADO | ACTUAL | [docs/evidence/2026-10-13/supabase-security_advisors.json](evidence/2026-10-13/supabase-security_advisors.json) · SRS-5.0 |
| E-REMOTE-METADATA | REMOTE_CONFIGURATION | OBSERVADO | ACTUAL | [docs/evidence/2026-10-13/supabase-metadata.json](evidence/2026-10-13/supabase-metadata.json) · SRS-5.0 |
| E-RUN-FLUTTER | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/flutter-test.log](evidence/2026-10-13/flutter-test.log) · SRS-5.0 |
| E-RUN-ANALYZE | STATIC_ANALYSIS | PASS | ACTUAL | [docs/evidence/2026-10-13/flutter-analyze.log](evidence/2026-10-13/flutter-analyze.log) · SRS-5.0 |
| E-RUN-NODE | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/node-existing.log](evidence/2026-10-13/node-existing.log) · SRS-5.0 |
| E-RUN-WORKER-INITIAL | TEST_EXECUTION | ERROR | ACTUAL | [docs/evidence/2026-10-13/worker-test.log](evidence/2026-10-13/worker-test.log) · SRS-5.0 |
| E-RUN-WORKER | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/worker-test-corrected.log](evidence/2026-10-13/worker-test-corrected.log) · SRS-5.0 |
| E-RUN-TRACKING | TEST_EXECUTION | PASS | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/tool-green.log](evidence/2026-10-13/tool-green.log) · SRS-5.0 |
| E-RUN-NATIVE | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/native-tests.log](evidence/2026-10-13/native-tests.log) · SRS-5.0 |
| E-SRC-001 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/mission_management_screen.dart](../lib/features/community/presentation/mission_management_screen.dart) · SRS-5.0 |
| E-SRC-002 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/005_mission_lifecycle.sql](../supabase/migrations/005_mission_lifecycle.sql) · SRS-5.0 |
| E-SRC-003 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/013_missions_redesign.sql](../supabase/migrations/013_missions_redesign.sql) · SRS-5.0 |
| E-SRC-004 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/mission_composer_screen.dart](../lib/features/community/presentation/mission_composer_screen.dart) · SRS-5.0 |
| E-SRC-005 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/delete-account/index.ts](../supabase/functions/delete-account/index.ts) · SRS-5.0 |
| E-SRC-006 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/001_initial_schema.sql](../supabase/migrations/001_initial_schema.sql) · SRS-5.0 |
| E-SRC-007 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/003_community.sql](../supabase/migrations/003_community.sql) · SRS-5.0 |
| E-SRC-008 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/006_profile_experience.sql](../supabase/migrations/006_profile_experience.sql) · SRS-5.0 |
| E-SRC-009 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/auth/data/auth_repository.dart](../lib/features/auth/data/auth_repository.dart) · SRS-5.0 |
| E-SRC-010 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/presentation/settings_screen.dart](../lib/features/profile/presentation/settings_screen.dart) · SRS-5.0 |
| E-SRC-011 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/core/errors/app_failure.dart](../lib/core/errors/app_failure.dart) · SRS-5.0 |
| E-SRC-012 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/auth/registration_email_test.dart](../test/features/auth/registration_email_test.dart) · SRS-5.0 |
| E-SRC-013 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/core/router/app_router.dart](../lib/core/router/app_router.dart) · SRS-5.0 |
| E-SRC-014 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/012_mission_map.sql](../supabase/migrations/012_mission_map.sql) · SRS-5.0 |
| E-SRC-015 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/post_location_picker.dart](../lib/features/community/presentation/post_location_picker.dart) · SRS-5.0 |
| E-SRC-016 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/data/mission_social_repository.dart](../lib/features/community/data/mission_social_repository.dart) · SRS-5.0 |
| E-SRC-017 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/mission_social_panels.dart](../lib/features/community/presentation/mission_social_panels.dart) · SRS-5.0 |
| E-SRC-018 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/020_mission_social.sql](../supabase/migrations/020_mission_social.sql) · SRS-5.0 |
| E-SRC-019 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/notifications/models/notification_preferences.dart](../lib/features/notifications/models/notification_preferences.dart) · SRS-5.0 |
| E-SRC-020 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/notifications/presentation/notification_settings.dart](../lib/features/notifications/presentation/notification_settings.dart) · SRS-5.0 |
| E-SRC-021 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/014_android_push.sql](../supabase/migrations/014_android_push.sql) · SRS-5.0 |
| E-SRC-022 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/notifications/data/android_push_gateway.dart](../lib/features/notifications/data/android_push_gateway.dart) · SRS-5.0 |
| E-SRC-023 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/send-push/delivery.ts](../supabase/functions/send-push/delivery.ts) · SRS-5.0 |
| E-SRC-024 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/models/community_models.dart](../lib/features/community/models/community_models.dart) · SRS-5.0 |
| E-SRC-025 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/mission_widgets.dart](../lib/features/community/presentation/mission_widgets.dart) · SRS-5.0 |
| E-SRC-026 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/missions_screen.dart](../lib/features/community/presentation/missions_screen.dart) · SRS-5.0 |
| E-SRC-027 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_repository_test.dart](../test/features/community/mission_repository_test.dart) · SRS-5.0 |
| E-SRC-028 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/core/config/app_config.dart](../lib/core/config/app_config.dart) · SRS-5.0 |
| E-SRC-029 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/data/community_repository.dart](../lib/features/community/data/community_repository.dart) · SRS-5.0 |
| E-SRC-030 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/data/social_repository.dart](../lib/features/community/data/social_repository.dart) · SRS-5.0 |
| E-SRC-031 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/moderation_screen.dart](../lib/features/community/presentation/moderation_screen.dart) · SRS-5.0 |
| E-SRC-032 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/social_panels.dart](../lib/features/community/presentation/social_panels.dart) · SRS-5.0 |
| E-SRC-033 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/home_feed/data/home_feed_repository.dart](../lib/features/home_feed/data/home_feed_repository.dart) · SRS-5.0 |
| E-SRC-034 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/home_feed/data/stories_repository.dart](../lib/features/home_feed/data/stories_repository.dart) · SRS-5.0 |
| E-SRC-035 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/home_feed/presentation/follow_button.dart](../lib/features/home_feed/presentation/follow_button.dart) · SRS-5.0 |
| E-SRC-036 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/home_feed/presentation/home_feed_screen.dart](../lib/features/home_feed/presentation/home_feed_screen.dart) · SRS-5.0 |
| E-SRC-037 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/home_feed/presentation/stories_rail.dart](../lib/features/home_feed/presentation/stories_rail.dart) · SRS-5.0 |
| E-SRC-038 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/home_feed/presentation/story_composer.dart](../lib/features/home_feed/presentation/story_composer.dart) · SRS-5.0 |
| E-SRC-039 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/home_feed/presentation/story_viewer.dart](../lib/features/home_feed/presentation/story_viewer.dart) · SRS-5.0 |
| E-SRC-040 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/shell/presentation/app_shell.dart](../lib/features/shell/presentation/app_shell.dart) · SRS-5.0 |
| E-SRC-041 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/main.dart](../lib/main.dart) · SRS-5.0 |
| E-SRC-042 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/story-cleanup/cleanup.ts](../supabase/functions/story-cleanup/cleanup.ts) · SRS-5.0 |
| E-SRC-043 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/009_post_reactions.sql](../supabase/migrations/009_post_reactions.sql) · SRS-5.0 |
| E-SRC-044 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/010_post_comments.sql](../supabase/migrations/010_post_comments.sql) · SRS-5.0 |
| E-SRC-045 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/011_post_collaboration.sql](../supabase/migrations/011_post_collaboration.sql) · SRS-5.0 |
| E-SRC-046 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/016_home_feed.sql](../supabase/migrations/016_home_feed.sql) · SRS-5.0 |
| E-SRC-047 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [android/app/src/main/kotlin/com/marea/app/TourAR.kt](../android/app/src/main/kotlin/com/marea/app/TourAR.kt) · SRS-5.0 |
| E-SRC-048 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [ios/Runner/AppDelegate.swift](../ios/Runner/AppDelegate.swift) · SRS-5.0 |
| E-SRC-049 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/core/location/device_location_service.dart](../lib/core/location/device_location_service.dart) · SRS-5.0 |
| E-SRC-050 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/map/data/mission_map_repository.dart](../lib/features/map/data/mission_map_repository.dart) · SRS-5.0 |
| E-SRC-051 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/map/presentation/mission_map_screen.dart](../lib/features/map/presentation/mission_map_screen.dart) · SRS-5.0 |
| E-SRC-052 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/presentation/profile_tools_sheet.dart](../lib/features/profile/presentation/profile_tools_sheet.dart) · SRS-5.0 |
| E-SRC-053 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/showcase/presentation/create_screen.dart](../lib/features/showcase/presentation/create_screen.dart) · SRS-5.0 |
| E-SRC-054 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/capture/tour_capture_screen.dart](../lib/features/tours/capture/tour_capture_screen.dart) · SRS-5.0 |
| E-SRC-055 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/data/tour_repository.dart](../lib/features/tours/data/tour_repository.dart) · SRS-5.0 |
| E-SRC-056 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/presentation/tour_ar_screen.dart](../lib/features/tours/presentation/tour_ar_screen.dart) · SRS-5.0 |
| E-SRC-057 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/presentation/tour_editor_screen.dart](../lib/features/tours/presentation/tour_editor_screen.dart) · SRS-5.0 |
| E-SRC-058 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/presentation/tour_panorama.dart](../lib/features/tours/presentation/tour_panorama.dart) · SRS-5.0 |
| E-SRC-059 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/presentation/tour_visit_screen.dart](../lib/features/tours/presentation/tour_visit_screen.dart) · SRS-5.0 |
| E-SRC-060 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [processing/tours/README.md](../processing/tours/README.md) · SRS-5.0 |
| E-SRC-061 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [processing/tours/worker.py](../processing/tours/worker.py) · SRS-5.0 |
| E-SRC-062 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/015_tours.sql](../supabase/migrations/015_tours.sql) · SRS-5.0 |
| E-SRC-063 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/021_content_cities.sql](../supabase/migrations/021_content_cities.sql) · SRS-5.0 |
| E-SRC-064 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/models/profile.dart](../lib/features/profile/models/profile.dart) · SRS-5.0 |
| E-SRC-065 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/presentation/edit_profile_screen.dart](../lib/features/profile/presentation/edit_profile_screen.dart) · SRS-5.0 |
| E-SRC-066 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/presentation/profile_experience.dart](../lib/features/profile/presentation/profile_experience.dart) · SRS-5.0 |
| E-SRC-067 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) · SRS-5.0 |
| E-SRC-068 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [android/app/src/main/kotlin/com/marea/app/MainActivity.kt](../android/app/src/main/kotlin/com/marea/app/MainActivity.kt) · SRS-5.0 |
| E-SRC-069 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [ios/Runner/Info.plist](../ios/Runner/Info.plist) · SRS-5.0 |
| E-SRC-070 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [pubspec.yaml](../pubspec.yaml) · SRS-5.0 |
| E-SRC-071 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [web/_redirects](../web/_redirects) · SRS-5.0 |
| E-SRC-072 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [web/index.html](../web/index.html) · SRS-5.0 |
| E-SRC-073 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [.gitignore](../.gitignore) · SRS-5.0 |
| E-SRC-074 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [README.md](../README.md) · SRS-5.0 |
| E-SRC-075 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/legal/README.md](legal/README.md) · SRS-5.0 |
| E-SRC-076 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/legal/aviso-privacidad-escolar-v1.txt](legal/aviso-privacidad-escolar-v1.txt) · SRS-5.0 |
| E-SRC-077 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/legal/terminos-escolar-v1.txt](legal/terminos-escolar-v1.txt) · SRS-5.0 |
| E-SRC-078 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/legal/legal_screens.dart](../lib/features/legal/legal_screens.dart) · SRS-5.0 |
| E-SRC-079 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [processing/tours/monitoring-alert.json](../processing/tours/monitoring-alert.json) · SRS-5.0 |
| E-SRC-080 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [pubspec.lock](../pubspec.lock) · SRS-5.0 |
| E-SRC-081 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/config.toml](../supabase/config.toml) · SRS-5.0 |
| E-SRC-082 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/delete-account/tour-storage.ts](../supabase/functions/delete-account/tour-storage.ts) · SRS-5.0 |
| E-SRC-083 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/legal/publish-school-v1.sql](../supabase/legal/publish-school-v1.sql) · SRS-5.0 |
| E-SRC-084 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/002_account_completion.sql](../supabase/migrations/002_account_completion.sql) · SRS-5.0 |
| E-SRC-085 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/models/mission_experience.dart](../lib/features/community/models/mission_experience.dart) · SRS-5.0 |
| E-SRC-086 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/mission_application_screen.dart](../lib/features/community/presentation/mission_application_screen.dart) · SRS-5.0 |
| E-SRC-087 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/data/tour_local_store_io.dart](../lib/features/tours/data/tour_local_store_io.dart) · SRS-5.0 |
| E-SRC-088 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/data/tour_local_store_web.dart](../lib/features/tours/data/tour_local_store_web.dart) · SRS-5.0 |
| E-SRC-089 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/tours/data/tour_progress_store.dart](../lib/features/tours/data/tour_progress_store.dart) · SRS-5.0 |
| E-SRC-090 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/post_composer_screen.dart](../lib/features/community/presentation/post_composer_screen.dart) · SRS-5.0 |
| E-SRC-091 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/posts_feed.dart](../lib/features/community/presentation/posts_feed.dart) · SRS-5.0 |
| E-SRC-092 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/data/profile_media_repository.dart](../lib/features/profile/data/profile_media_repository.dart) · SRS-5.0 |
| E-SRC-093 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/showcase/data/showcase_repository.dart](../lib/features/showcase/data/showcase_repository.dart) · SRS-5.0 |
| E-SRC-094 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/showcase/models/showcase.dart](../lib/features/showcase/models/showcase.dart) · SRS-5.0 |
| E-SRC-095 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/showcase/presentation/showcase_composer_screen.dart](../lib/features/showcase/presentation/showcase_composer_screen.dart) · SRS-5.0 |
| E-SRC-096 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/showcase/presentation/showcase_detail_screen.dart](../lib/features/showcase/presentation/showcase_detail_screen.dart) · SRS-5.0 |
| E-SRC-097 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/profile-media/image.ts](../supabase/functions/profile-media/image.ts) · SRS-5.0 |
| E-SRC-098 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/profile-media/index.ts](../supabase/functions/profile-media/index.ts) · SRS-5.0 |
| E-SRC-099 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_mission_database.mjs](../tool/check_mission_database.mjs) · SRS-5.0 |
| E-SRC-100 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/account-completion.md](account-completion.md) · SRS-5.0 |
| E-SRC-101 | REPOSITORY_SOURCE | OBSERVADO | POTENCIALMENTE_OBSOLETA | [docs/MAREA_SRS.md](MAREA_SRS.md) · SRS-5.0 |
| E-SRC-102 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/shell/presentation/placeholder_screen.dart](../lib/features/shell/presentation/placeholder_screen.dart) · SRS-5.0 |
| E-SRC-103 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/explore_screen.dart](../lib/features/community/presentation/explore_screen.dart) · SRS-5.0 |
| E-SRC-104 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/core/session/app_session_controller.dart](../lib/core/session/app_session_controller.dart) · SRS-5.0 |
| E-SRC-105 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/007_minimal_registration.sql](../supabase/migrations/007_minimal_registration.sql) · SRS-5.0 |
| E-SRC-106 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/app.dart](../lib/app.dart) · SRS-5.0 |
| E-SRC-107 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/auth/presentation/mobile_intro_screen.dart](../lib/features/auth/presentation/mobile_intro_screen.dart) · SRS-5.0 |
| E-SRC-108 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/auth/presentation/welcome_screen.dart](../lib/features/auth/presentation/welcome_screen.dart) · SRS-5.0 |
| E-SRC-109 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/models/profile_preferences.dart](../lib/features/profile/models/profile_preferences.dart) · SRS-5.0 |
| E-SRC-110 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/presentation/profile_setup_screen.dart](../lib/features/profile/presentation/profile_setup_screen.dart) · SRS-5.0 |
| E-SRC-111 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/notifications_panel.dart](../lib/features/community/presentation/notifications_panel.dart) · SRS-5.0 |
| E-SRC-112 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/notifications/data/inbox_only_gateway.dart](../lib/features/notifications/data/inbox_only_gateway.dart) · SRS-5.0 |
| E-SRC-113 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/notifications/data/push_controller.dart](../lib/features/notifications/data/push_controller.dart) · SRS-5.0 |
| E-SRC-114 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/core/router/account_routes_test.dart](../test/core/router/account_routes_test.dart) · SRS-5.0 |
| E-SRC-115 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/core/session/registration_safety_test.dart](../test/core/session/registration_safety_test.dart) · SRS-5.0 |
| E-SRC-116 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/core/session/app_session_controller_test.dart](../test/core/session/app_session_controller_test.dart) · SRS-5.0 |
| E-SRC-117 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/presentation/email_flow_test.dart](../test/features/presentation/email_flow_test.dart) · SRS-5.0 |
| E-SRC-118 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/presentation/account_flow_test.dart](../test/features/presentation/account_flow_test.dart) · SRS-5.0 |
| E-SRC-119 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/core/errors/app_failure_test.dart](../test/core/errors/app_failure_test.dart) · SRS-5.0 |
| E-SRC-120 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/core/router/app_router_test.dart](../test/core/router/app_router_test.dart) · SRS-5.0 |
| E-SRC-121 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/delete-account/tour-storage_test.ts](../supabase/functions/delete-account/tour-storage_test.ts) · SRS-5.0 |
| E-SRC-122 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/core/config/legal_policy_test.dart](../test/core/config/legal_policy_test.dart) · SRS-5.0 |
| E-SRC-123 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/core/session/account_completion_test.dart](../test/core/session/account_completion_test.dart) · SRS-5.0 |
| E-SRC-124 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/profile/initial_profile_contract_test.dart](../test/features/profile/initial_profile_contract_test.dart) · SRS-5.0 |
| E-SRC-125 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_permissions_ui_test.dart](../test/features/community/mission_permissions_ui_test.dart) · SRS-5.0 |
| E-SRC-126 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/auth/welcome_reference_test.dart](../test/features/auth/welcome_reference_test.dart) · SRS-5.0 |
| E-SRC-127 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/location_picker_test.dart](../test/features/community/location_picker_test.dart) · SRS-5.0 |
| E-SRC-128 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/profile/models/personalization_test.dart](../test/features/profile/models/personalization_test.dart) · SRS-5.0 |
| E-SRC-129 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/profile/profile_setup_test.dart](../test/features/profile/profile_setup_test.dart) · SRS-5.0 |
| E-SRC-130 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/auth/mobile_intro_experience_test.dart](../test/features/auth/mobile_intro_experience_test.dart) · SRS-5.0 |
| E-SRC-131 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/profile/profile_tools_test.dart](../test/features/profile/profile_tools_test.dart) · SRS-5.0 |
| E-SRC-132 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/models_test.dart](../test/features/community/models_test.dart) · SRS-5.0 |
| E-SRC-133 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/notifications/push_controller_test.dart](../test/features/notifications/push_controller_test.dart) · SRS-5.0 |
| E-SRC-134 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/presentation/responsive_test.dart](../test/features/presentation/responsive_test.dart) · SRS-5.0 |
| E-SRC-135 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/presentation/professional_details.dart](../lib/features/profile/presentation/professional_details.dart) · SRS-5.0 |
| E-SRC-136 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/profile/presentation/profile_identity.dart](../lib/features/profile/presentation/profile_identity.dart) · SRS-5.0 |
| E-SRC-137 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/profile/profile_redesign_test.dart](../test/features/profile/profile_redesign_test.dart) · SRS-5.0 |
| E-SRC-138 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/profile/profile_experience_ui_test.dart](../test/features/profile/profile_experience_ui_test.dart) · SRS-5.0 |
| E-SRC-139 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/showcase/showcase_flow_test.dart](../test/features/showcase/showcase_flow_test.dart) · SRS-5.0 |
| E-SRC-140 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/showcase/showcase_models_test.dart](../test/features/showcase/showcase_models_test.dart) · SRS-5.0 |
| E-SRC-141 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_experience_models_test.dart](../test/features/community/mission_experience_models_test.dart) · SRS-5.0 |
| E-SRC-142 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_participation_test.dart](../test/features/community/mission_participation_test.dart) · SRS-5.0 |
| E-SRC-143 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/showcase/showcase_repository_test.dart](../test/features/showcase/showcase_repository_test.dart) · SRS-5.0 |
| E-SRC-144 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/core/theme/category_visuals.dart](../lib/core/theme/category_visuals.dart) · SRS-5.0 |
| E-SRC-145 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/home_feed/feed_correction_test.dart](../test/features/home_feed/feed_correction_test.dart) · SRS-5.0 |
| E-SRC-146 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/map/mission_map_repository_test.dart](../test/features/map/mission_map_repository_test.dart) · SRS-5.0 |
| E-SRC-147 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/map/device_location_service_test.dart](../test/features/map/device_location_service_test.dart) · SRS-5.0 |
| E-SRC-148 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/map/mission_map_ui_test.dart](../test/features/map/mission_map_ui_test.dart) · SRS-5.0 |
| E-SRC-149 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/missions_screen_test.dart](../test/features/community/missions_screen_test.dart) · SRS-5.0 |
| E-SRC-150 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/home_feed/mission_card_layout_test.dart](../test/features/home_feed/mission_card_layout_test.dart) · SRS-5.0 |
| E-SRC-151 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/implementation/home-feed-redesign-progress.md](implementation/home-feed-redesign-progress.md) · SRS-5.0 |
| E-SRC-152 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/map.md](map.md) · SRS-5.0 |
| E-SRC-153 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/home_feed/home_feed_models_test.dart](../test/features/home_feed/home_feed_models_test.dart) · SRS-5.0 |
| E-SRC-154 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_experience_repository_test.dart](../test/features/community/mission_experience_repository_test.dart) · SRS-5.0 |
| E-SRC-155 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_navigation_test.dart](../test/features/community/mission_navigation_test.dart) · SRS-5.0 |
| E-SRC-156 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/community/presentation/mission_social_actions.dart](../lib/features/community/presentation/mission_social_actions.dart) · SRS-5.0 |
| E-SRC-157 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_social_test.dart](../test/features/community/mission_social_test.dart) · SRS-5.0 |
| E-SRC-158 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/home_feed/home_feed_experience_test.dart](../test/features/home_feed/home_feed_experience_test.dart) · SRS-5.0 |
| E-SRC-159 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_composer_steps_test.dart](../test/features/community/mission_composer_steps_test.dart) · SRS-5.0 |
| E-SRC-160 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_models_test.dart](../test/features/community/mission_models_test.dart) · SRS-5.0 |
| E-SRC-161 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/mission_social_panels_test.dart](../test/features/community/mission_social_panels_test.dart) · SRS-5.0 |
| E-SRC-162 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/map/presentation/mission_map_canvas.dart](../lib/features/map/presentation/mission_map_canvas.dart) · SRS-5.0 |
| E-SRC-163 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/map/presentation/mission_map_preview.dart](../lib/features/map/presentation/mission_map_preview.dart) · SRS-5.0 |
| E-SRC-164 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/notification_destination_test.dart](../test/features/community/notification_destination_test.dart) · SRS-5.0 |
| E-SRC-165 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/social_models_test.dart](../test/features/community/social_models_test.dart) · SRS-5.0 |
| E-SRC-166 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/send-push/delivery_test.ts](../supabase/functions/send-push/delivery_test.ts) · SRS-5.0 |
| E-SRC-167 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/send-push/database_test.ts](../supabase/functions/send-push/database_test.ts) · SRS-5.0 |
| E-SRC-168 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/community_flow_test.dart](../test/features/community/community_flow_test.dart) · SRS-5.0 |
| E-SRC-169 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/post_composer_test.dart](../test/features/community/post_composer_test.dart) · SRS-5.0 |
| E-SRC-170 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/home_feed/home_feed_ui_test.dart](../test/features/home_feed/home_feed_ui_test.dart) · SRS-5.0 |
| E-SRC-171 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/presentation/navigation_test.dart](../test/features/presentation/navigation_test.dart) · SRS-5.0 |
| E-SRC-172 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_community_database.mjs](../tool/check_community_database.mjs) · SRS-5.0 |
| E-SRC-173 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_feed_correction_contract.mjs](../tool/check_feed_correction_contract.mjs) · SRS-5.0 |
| E-SRC-174 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_home_feed_database.mjs](../tool/check_home_feed_database.mjs) · SRS-5.0 |
| E-SRC-175 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/community/social_panels_test.dart](../test/features/community/social_panels_test.dart) · SRS-5.0 |
| E-SRC-176 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_profile_experience_database.mjs](../tool/check_profile_experience_database.mjs) · SRS-5.0 |
| E-SRC-177 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_social_database.mjs](../tool/check_social_database.mjs) · SRS-5.0 |
| E-SRC-178 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/core/config/app_config_test.dart](../test/core/config/app_config_test.dart) · SRS-5.0 |
| E-SRC-179 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/story-cleanup/cleanup_test.ts](../supabase/functions/story-cleanup/cleanup_test.ts) · SRS-5.0 |
| E-SRC-180 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [processing/tours/tests/test_worker.py](../processing/tours/tests/test_worker.py) · SRS-5.0 |
| E-SRC-181 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/tours/tour_models_test.dart](../test/features/tours/tour_models_test.dart) · SRS-5.0 |
| E-SRC-182 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/tours/tus_upload_test.dart](../test/features/tours/tus_upload_test.dart) · SRS-5.0 |
| E-SRC-183 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_map_database.mjs](../tool/check_map_database.mjs) · SRS-5.0 |
| E-SRC-184 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_tours_database.mjs](../tool/check_tours_database.mjs) · SRS-5.0 |
| E-SRC-185 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_missions_redesign_database.mjs](../tool/check_missions_redesign_database.mjs) · SRS-5.0 |
| E-SRC-186 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_database.mjs](../tool/check_database.mjs) · SRS-5.0 |
| E-SRC-187 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [android/app/src/test/kotlin/com/marea/app/TourOrientationTest.kt](../android/app/src/test/kotlin/com/marea/app/TourOrientationTest.kt) · SRS-5.0 |
| E-SRC-188 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [ios/NativeTests/orientation.swift](../ios/NativeTests/orientation.swift) · SRS-5.0 |
| E-SRC-189 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [ios/NativeTests/tracking.swift](../ios/NativeTests/tracking.swift) · SRS-5.0 |
| E-SRC-190 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/tours/tour_ar_recovery_test.dart](../test/features/tours/tour_ar_recovery_test.dart) · SRS-5.0 |
| E-SRC-191 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/tours/tour_ui_test.dart](../test/features/tours/tour_ui_test.dart) · SRS-5.0 |
| E-SRC-192 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/profile-media/image_test.ts](../supabase/functions/profile-media/image_test.ts) · SRS-5.0 |
| E-SRC-193 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/browser/image_picker_probe.dart](../test/browser/image_picker_probe.dart) · SRS-5.0 |
| E-SRC-194 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/profile/data/profile_image_picker_test.dart](../test/features/profile/data/profile_image_picker_test.dart) · SRS-5.0 |
| E-SRC-195 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/tours/tour_editor_recovery_test.dart](../test/features/tours/tour_editor_recovery_test.dart) · SRS-5.0 |
| E-SRC-196 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/tours/tour_progress_store_test.dart](../test/features/tours/tour_progress_store_test.dart) · SRS-5.0 |
| E-SRC-197 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/tool/backend_contract_test.mjs](../test/tool/backend_contract_test.mjs) · SRS-5.0 |
| E-SRC-198 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_backend_contract.mjs](../tool/check_backend_contract.mjs) · SRS-5.0 |
| E-SRC-199 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/auth/presentation/email_code_screen.dart](../lib/features/auth/presentation/email_code_screen.dart) · SRS-5.0 |
| E-SRC-200 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/geocoding/index.ts](../supabase/functions/geocoding/index.ts) · SRS-5.0 |
| E-SRC-201 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/send-push/index.ts](../supabase/functions/send-push/index.ts) · SRS-5.0 |
| E-SRC-202 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/tour-dispatch/index.ts](../supabase/functions/tour-dispatch/index.ts) · SRS-5.0 |
| E-SRC-203 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_access_database.mjs](../tool/check_access_database.mjs) · SRS-5.0 |
| E-SRC-204 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/tour-dispatch/dispatch.ts](../supabase/functions/tour-dispatch/dispatch.ts) · SRS-5.0 |
| E-SRC-205 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/core/config/map_tile_configuration.dart](../lib/core/config/map_tile_configuration.dart) · SRS-5.0 |
| E-SRC-206 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/notifications/models/notification_destination.dart](../lib/features/notifications/models/notification_destination.dart) · SRS-5.0 |
| E-SRC-207 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/migrations/017_story_cleanup_schedule.sql](../supabase/migrations/017_story_cleanup_schedule.sql) · SRS-5.0 |
| E-SRC-208 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/shared/widgets/marea_surface.dart](../lib/shared/widgets/marea_surface.dart) · SRS-5.0 |
| E-SRC-209 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/shared/widgets/marea_text_field.dart](../lib/shared/widgets/marea_text_field.dart) · SRS-5.0 |
| E-SRC-210 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/auth/presentation/intro_decorations.dart](../lib/features/auth/presentation/intro_decorations.dart) · SRS-5.0 |
| E-SRC-211 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/map/application/mission_map_controller.dart](../lib/features/map/application/mission_map_controller.dart) · SRS-5.0 |
| E-SRC-212 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/map/mission_map_test.dart](../test/features/map/mission_map_test.dart) · SRS-5.0 |
| E-SRC-213 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/shared/widgets/marea_skeleton.dart](../lib/shared/widgets/marea_skeleton.dart) · SRS-5.0 |
| E-SRC-214 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/shared/widgets/marea_loading_test.dart](../test/shared/widgets/marea_loading_test.dart) · SRS-5.0 |
| E-SRC-215 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/email-templates/confirmation.html](../supabase/email-templates/confirmation.html) · SRS-5.0 |
| E-SRC-216 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/email-templates/recovery.html](../supabase/email-templates/recovery.html) · SRS-5.0 |
| E-SRC-217 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/implementation/tours-local-pilot-report.md](implementation/tours-local-pilot-report.md) · SRS-5.0 |
| E-SRC-218 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/android-push.md](android-push.md) · SRS-5.0 |
| E-SRC-219 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/ar-experience-design.md](ar-experience-design.md) · SRS-5.0 |
| E-SRC-220 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [android/app/build.gradle.kts](../android/app/build.gradle.kts) · SRS-5.0 |
| E-SRC-221 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [ios/Runner.xcodeproj/project.pbxproj](../ios/Runner.xcodeproj/project.pbxproj) · SRS-5.0 |
| E-SRC-222 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/support/fakes.dart](../test/support/fakes.dart) · SRS-5.0 |
| E-SRC-223 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/check_mission_social_database.mjs](../tool/check_mission_social_database.mjs) · SRS-5.0 |
| E-SRC-224 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [docs/implementation/missions-redesign-progress.md](implementation/missions-redesign-progress.md) · SRS-5.0 |
| E-SRC-225 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [tool/backend_contract.sql](../tool/backend_contract.sql) · SRS-5.0 |
| E-SRC-226 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [lib/features/auth/presentation/security_screen.dart](../lib/features/auth/presentation/security_screen.dart) · SRS-5.0 |
| E-SRC-227 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [test/features/location/content_city_test.dart](../test/features/location/content_city_test.dart) · SRS-5.0 |
| E-SRC-228 | REPOSITORY_SOURCE | OBSERVADO | ACTUAL | [supabase/functions/geocoding/edge_test.mjs](../supabase/functions/geocoding/edge_test.mjs) · SRS-5.0 |
| E-BUILD-WEB | COMPILATION | PASS | ACTUAL | [docs/evidence/2026-10-13/build-web.log](evidence/2026-10-13/build-web.log) · SRS-5.0 |
| E-BUILD-ANDROID | COMPILATION | PASS | ACTUAL | [docs/evidence/2026-10-13/build-android.log](evidence/2026-10-13/build-android.log) · SRS-5.0 |
| E-BUILD-IOS | COMPILATION | PASS | ACTUAL | [docs/evidence/2026-10-13/build-ios.log](evidence/2026-10-13/build-ios.log) · SRS-5.0 |
| E-RUN-ANDROID-NATIVE | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/android-native-test.log](evidence/2026-10-13/android-native-test.log) · SRS-5.0 |
| E-REMOTE-QUERY | AUDIT_QUERY_RECEIPT | OBSERVADO | ACTUAL | [docs/evidence/2026-10-13/supabase-metadata-query.sql](evidence/2026-10-13/supabase-metadata-query.sql) · SRS-5.0 |
| E-DEPENDENCIES-001 | DEPENDENCY_INVENTORY | OBSERVADO | ACTUAL | [docs/evidence/2026-10-13/dependency-inventory.json](evidence/2026-10-13/dependency-inventory.json) · SRS-5.0 |
| E-RUN-TRACKING-FINAL | TEST_EXECUTION | PASS | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/tool-final.log](evidence/2026-10-13/tool-final.log) · SRS-5.0 |
| E-RUN-TRACKING-SOURCE-BINDING | TEST_EXECUTION | PASS | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/tool-source-binding.log](evidence/2026-10-13/tool-source-binding.log) · SRS-5.0 |
| E-TASK001-BACKUP-20261013T164530Z | BACKUP_VERIFICATION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T164530Z/01-backup.json](evidence/2026-10-13/task001/run-20261013T164530Z/01-backup.json) · SRS-5.0 |
| E-TASK001-DOCKER-20261013T164530Z | LOCAL_INFRASTRUCTURE | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T164530Z/02-docker.json](evidence/2026-10-13/task001/run-20261013T164530Z/02-docker.json) · SRS-5.0 |
| E-TASK001-SUPABASE-20261013T164530Z | LOCAL_INFRASTRUCTURE_EXECUTION | BLOQUEADO | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/task001/run-20261013T164530Z/03-supabase.json](evidence/2026-10-13/task001/run-20261013T164530Z/03-supabase.json) · SRS-5.0 |
| E-TASK001-SCHEMA-20261013T164530Z | SOURCE_INSPECTION | BLOQUEADO | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/task001/run-20261013T164530Z/04-schema.json](evidence/2026-10-13/task001/run-20261013T164530Z/04-schema.json) · SRS-5.0 |
| E-TASK001-SUITES-20261013T164530Z | TEST_PLAN | BLOQUEADO | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/task001/run-20261013T164530Z/05-suites.json](evidence/2026-10-13/task001/run-20261013T164530Z/05-suites.json) · SRS-5.0 |
| E-TASK001-GUARDS-20261013T164530Z | TEST_EXECUTION | PASS | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/task001/run-20261013T164530Z/06-guards.json](evidence/2026-10-13/task001/run-20261013T164530Z/06-guards.json) · SRS-5.0 |
| E-TASK001-INTEGRITY-20261013T164530Z | TEST_EXECUTION | PASS | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/task001/run-20261013T164530Z/07-integrity-tests.json](evidence/2026-10-13/task001/run-20261013T164530Z/07-integrity-tests.json) · SRS-5.0 |
| E-TASK001-PRESERVATION-20261013T1704Z | REPOSITORY_PRESERVATION | PASS_CON_LIMITACION | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T164530Z/preservation-resolution.json](evidence/2026-10-13/task001/run-20261013T164530Z/preservation-resolution.json) · SRS-5.0 |
| E-TASK001-CONT-BACKUP | LOCAL_BACKUP | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/01-backup.json](evidence/2026-10-13/task001/run-20261013T174515Z/01-backup.json) · SRS-5.0 |
| E-TASK001-CONT-CAUSE | LOCAL_INFRASTRUCTURE | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/02-network-resolution.json](evidence/2026-10-13/task001/run-20261013T174515Z/02-network-resolution.json) · SRS-5.0 |
| E-TASK001-CONT-STACK | LOCAL_INFRASTRUCTURE | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/stack-fd0edb3330b2.json](evidence/2026-10-13/task001/run-20261013T174515Z/stack-fd0edb3330b2.json) · SRS-5.0 |
| E-TASK001-CONT-ISOLATION | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/isolation-fd0edb3330b2.json](evidence/2026-10-13/task001/run-20261013T174515Z/isolation-fd0edb3330b2.json) · SRS-5.0 |
| E-TASK001-CONT-DNS | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/dns-fd0edb3330b2.json](evidence/2026-10-13/task001/run-20261013T174515Z/dns-fd0edb3330b2.json) · SRS-5.0 |
| E-TASK001-CONT-INGRESS | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/ingress-fd0edb3330b2.json](evidence/2026-10-13/task001/run-20261013T174515Z/ingress-fd0edb3330b2.json) · SRS-5.0 |
| E-TASK001-CONT-SCHEMA | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/schema-fd0edb3330b2.json](evidence/2026-10-13/task001/run-20261013T174515Z/schema-fd0edb3330b2.json) · SRS-5.0 |
| E-TASK001-CONT-CATALOG | LOCAL_DATABASE_INVENTORY | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/inventory-fd0edb3330b2.json](evidence/2026-10-13/task001/run-20261013T174515Z/inventory-fd0edb3330b2.json) · SRS-5.0 |
| E-TASK001-CONT-SUITES | TEST_EXECUTION | FAIL | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/suites-marea-task001-fd0edb3330b2-1791920209734.json](evidence/2026-10-13/task001/run-20261013T174515Z/suites-marea-task001-fd0edb3330b2-1791920209734.json) · SRS-5.0 |
| E-TASK001-CONT-REPRO | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/11-reproducibility.json](evidence/2026-10-13/task001/run-20261013T174515Z/11-reproducibility.json) · SRS-5.0 |
| E-TASK001-CONT-ATTEMPTS | TEST_ATTEMPT_HISTORY | PASS_CON_LIMITACION | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/12-attempt-history-additional.json](evidence/2026-10-13/task001/run-20261013T174515Z/12-attempt-history-additional.json) · SRS-5.0 |
| E-TASK001-CONT-SOURCE | IMPLEMENTATION_MANIFEST | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/13-source-binding.json](evidence/2026-10-13/task001/run-20261013T174515Z/13-source-binding.json) · SRS-5.0 |
| E-TASK001-CONT-INTEGRITY | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/14-integrity-tests.json](evidence/2026-10-13/task001/run-20261013T174515Z/14-integrity-tests.json) · SRS-5.0 |
| E-TASK001-CONT-PRESERVATION | REPOSITORY_PRESERVATION | PASS_CON_LIMITACION | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/08-preservation.json](evidence/2026-10-13/task001/run-20261013T174515Z/08-preservation.json) · SRS-5.0 |
| E-TASK001-CONT-CHECKS | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/17-closure-checks.json](evidence/2026-10-13/task001/run-20261013T174515Z/17-closure-checks.json) · SRS-5.0 |
| E-TASK001-CONT-PRESERVATION-FINAL | REPOSITORY_PRESERVATION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/15-preservation-final.json](evidence/2026-10-13/task001/run-20261013T174515Z/15-preservation-final.json) · SRS-5.0 |
| E-TASK001-CONT-STOP | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task001/run-20261013T174515Z/16-stop.json](evidence/2026-10-13/task001/run-20261013T174515Z/16-stop.json) · SRS-5.0 |
| E-TASK002-AUTH | USER_CONFIRMATION | AUTORIZACION_ACOTADA | ACTUAL | [docs/evidence/2026-10-13/task002/run-20261014T003000Z/AUTHORIZATION.md](evidence/2026-10-13/task002/run-20261014T003000Z/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-N | NORMATIVE_REVIEW | DOCUMENTADO | ACTUAL | [docs/evidence/2026-10-13/task002/run-20261014T003000Z/01-N-verification.json](evidence/2026-10-13/task002/run-20261014T003000Z/01-N-verification.json) · SRS-5.1.1 |
| E-TASK002-T-DESIGN | DOCUMENT_REVIEW | DOCUMENTADO | ACTUAL | [docs/evidence/2026-10-13/task002/run-20261014T003000Z/T-TOOLING-DESIGN.md](evidence/2026-10-13/task002/run-20261014T003000Z/T-TOOLING-DESIGN.md) · SRS-5.1.1 |
| E-TASK002-T-TESTS | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-13/task002/run-20261014T003000Z/14-T-verification.json](evidence/2026-10-13/task002/run-20261014T003000Z/14-T-verification.json) · SRS-5.1.1 |
| E-TASK002-PRESERVATION | INTEGRITY_CHECK | PASS | ACTUAL | [docs/evidence/2026-10-13/task002/run-20261014T003000Z/13-preservation-check.json](evidence/2026-10-13/task002/run-20261014T003000Z/13-preservation-check.json) · SRS-5.1.1 |
| E-TASK002-E | STATIC_ANALYSIS | PROPUESTA_PENDIENTE | POTENCIALMENTE_OBSOLETA | [docs/task002/E-STRUCTURAL-REVIEW.md](task002/E-STRUCTURAL-REVIEW.md) · SRS-5.1.1 |
| E-TASK002-U0 | DESIGN_PROPOSAL | ENTREGADO_PARA_REVISION | POTENCIALMENTE_OBSOLETA | [docs/task002/U0-FUNCTIONAL-DESIGN.md](task002/U0-FUNCTIONAL-DESIGN.md) · SRS-5.1.1 |
| E-TASK002-U0-CORRECTION-AUTH | USER_CONFIRMATION | CONFIRMED_SCOPED | ACTUAL | [docs/evidence/2026-10-13/task002/run-20261014T044500Z/AUTHORIZATION.md](evidence/2026-10-13/task002/run-20261014T044500Z/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-U0-CONSISTENCY | DESIGN_PROPOSAL | CORREGIDO_PARA_APROBACION_FORMAL | POTENCIALMENTE_OBSOLETA | [docs/task002/U0-FUNCTIONAL-DESIGN.md](task002/U0-FUNCTIONAL-DESIGN.md) · SRS-5.1.1 |
| E-TASK002-U0-CONSISTENCY-TESTS | PROTOTYPE_VERIFICATION | PASS | ACTUAL | [docs/evidence/2026-10-13/task002/run-20261014T044500Z/U0-browser-release.json](evidence/2026-10-13/task002/run-20261014T044500Z/U0-browser-release.json) · SRS-5.1.1 |
| E-TASK002-E-DIAGNOSIS | LOCAL_ENVIRONMENT_DIAGNOSIS | BLOCKED | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-13/task002/run-20261014T044500Z/E-local-diagnosis.json](evidence/2026-10-13/task002/run-20261014T044500Z/E-local-diagnosis.json) · SRS-5.1.1 |
| E-TASK002-U0-FILE-CONSERVATION | INTEGRITY_CHECK | PASS | ACTUAL | [docs/evidence/2026-10-13/task002/run-20261014T044500Z/08-file-conservation.json](evidence/2026-10-13/task002/run-20261014T044500Z/08-file-conservation.json) · SRS-5.1.1 |
| E-TASK002-U0-FORMAL-APPROVAL | USER_CONFIRMATION | APROBADO_DISEÑO_FUNCIONAL | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T051800Z/AUTHORIZATION.md](evidence/2026-10-18/task002/run-20261019T051800Z/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-E-ENV-20261018 | LOCAL_ENVIRONMENT_DIAGNOSIS | PASS | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T051800Z/01-offline-preservation.json](evidence/2026-10-18/task002/run-20261019T051800Z/01-offline-preservation.json) · SRS-5.1.1 |
| E-TASK002-E-INVENTORY-20261018 | EFFECTIVE_DATABASE_INVENTORY | PASS | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T051800Z/08-effective-inventory-canonical.json](evidence/2026-10-18/task002/run-20261019T051800Z/08-effective-inventory-canonical.json) · SRS-5.1.1 |
| E-TASK002-E-RECOVERY-20261018 | LOCAL_RECOVERY_VERIFICATION | PASS | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T051800Z/09-logical-backup-restore.json](evidence/2026-10-18/task002/run-20261019T051800Z/09-logical-backup-restore.json) · SRS-5.1.1 |
| E-TASK002-E-REPORT-20261018 | TECHNICAL_DIAGNOSTIC_REPORT | DIAGNOSTICO_COMPLETADO_LOCAL_CORTE_NO_AUTORIZADO | ACTUAL | [docs/task002/E-DIAGNOSTIC-REPORT.md](task002/E-DIAGNOSTIC-REPORT.md) · SRS-5.1.1 |
| E-TASK002-E1-AUTH-20261018 | USER_CONFIRMATION | AUTORIZADO_SOLO_E1_LOCAL | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1/AUTHORIZATION.md](evidence/2026-10-18/task002/run-20261019T055200Z-e1/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-E1-PREFLIGHT-20261018 | LOCAL_E1_PREFLIGHT | PASS | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1/01-preflight.json](evidence/2026-10-18/task002/run-20261019T055200Z-e1/01-preflight.json) · SRS-5.1.1 |
| E-TASK002-E1-IMPLEMENTATION-20261018 | LOCAL_E1_SCHEMA_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1/04-transactional-execution.json](evidence/2026-10-18/task002/run-20261019T055200Z-e1/04-transactional-execution.json) · SRS-5.1.1 |
| E-TASK002-E1-ACCESS-TESTS-20261018 | LOCAL_E1_NEGATIVE_SQL_TESTS | PASS | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1/05-permissions-constraints-tests.json](evidence/2026-10-18/task002/run-20261019T055200Z-e1/05-permissions-constraints-tests.json) · SRS-5.1.1 |
| E-TASK002-E1-CONSERVATION-20261018 | LOCAL_E1_LEGACY_CONSERVATION | PASS | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1/06-legacy-and-storage-conservation.json](evidence/2026-10-18/task002/run-20261019T055200Z-e1/06-legacy-and-storage-conservation.json) · SRS-5.1.1 |
| E-TASK002-E1-VERIFIER-HISTORY-20261018 | LOCAL_E1_VERIFIER_INCIDENTS | FAILURES_PRESERVED_VERIFIER_CORRECTED | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1/10-readonly-failure-diagnosis.json](evidence/2026-10-18/task002/run-20261019T055200Z-e1/10-readonly-failure-diagnosis.json) · SRS-5.1.1 |
| E-TASK002-E1-REPORT-20261018 | LOCAL_E1_TECHNICAL_REPORT | PASS | ACTUAL | [docs/evidence/2026-10-18/task002/run-20261019T055200Z-e1/REPORT.md](evidence/2026-10-18/task002/run-20261019T055200Z-e1/REPORT.md) · SRS-5.1.1 |
| E-TASK002-E2-AUTH-20261019 | USER_INSTRUCTION | DOCUMENTADO_NO_IMPLEMENTADO_NO_EJECUTADO | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T061500Z-e2-design/AUTHORIZATION.md](evidence/2026-10-19/task002/run-20261019T061500Z-e2-design/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-E2-INVENTORY-20261019 | DESK_DEPENDENCY_ANALYSIS | DOCUMENTADO_NO_IMPLEMENTADO_NO_EJECUTADO | ACTUAL | [docs/task002/E2-DEPENDENCY-INVENTORY.json](task002/E2-DEPENDENCY-INVENTORY.json) · SRS-5.1.1 |
| E-TASK002-E2-DESIGN-20261019 | TECHNICAL_DESIGN_PROPOSAL | DOCUMENTADO_NO_IMPLEMENTADO_NO_EJECUTADO | ACTUAL | [docs/task002/E2-TECHNICAL-DESIGN.md](task002/E2-TECHNICAL-DESIGN.md) · SRS-5.1.1 |
| E-TASK002-E2-REPORT-20261019 | DOCUMENTARY_PLANNING_REPORT | DOCUMENTADO_NO_IMPLEMENTADO_NO_EJECUTADO | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T061500Z-e2-design/REPORT.md](evidence/2026-10-19/task002/run-20261019T061500Z-e2-design/REPORT.md) · SRS-5.1.1 |
| E-TASK002-E2A-AUTH-20261019 | USER_CONFIRMATION | APROBADO_D01_AUTORIZADO_SOLO_E2A_LOCAL | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T132000Z-e2a/AUTHORIZATION.md](evidence/2026-10-19/task002/run-20261019T132000Z-e2a/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-E2A-PREPARATION-20261019 | LOCAL_LAB_PREPARATION | PREPARACION_PARCIAL_NO_ACEPTADA | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T132000Z-e2a/02-partial-preparation.json](evidence/2026-10-19/task002/run-20261019T132000Z-e2a/02-partial-preparation.json) · SRS-5.1.1 |
| E-TASK002-E2A-ISOLATION-20261019 | LOCAL_ISOLATION_PRECONDITION | BLOQUEADO_PRECONDICION_AISLAMIENTO | POTENCIALMENTE_OBSOLETA | [docs/evidence/2026-10-19/task002/run-20261019T132000Z-e2a/FAILURE-1792416399489362000.json](evidence/2026-10-19/task002/run-20261019T132000Z-e2a/FAILURE-1792416399489362000.json) · SRS-5.1.1 |
| E-TASK002-E2A-REPORT-20261019 | BLOCKED_INCREMENT_REPORT | E2A_NO_IMPLEMENTADO_NO_ACEPTADO | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T132000Z-e2a/REPORT.md](evidence/2026-10-19/task002/run-20261019T132000Z-e2a/REPORT.md) · SRS-5.1.1 |
| E-TASK002-ISOLATION-AUTH-20261019 | USER_CONFIRMATION | AUTORIZADO_SOLO_DIAGNOSTICO_AISLAMIENTO | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation/AUTHORIZATION.md](evidence/2026-10-19/task002/run-20261019T133800Z-isolation/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-ISOLATION-DIAG-20261019 | LOCAL_ISOLATION_DIAGNOSTIC | FALSO_POSITIVO_REPRODUCIDO | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation/03-reproduction.json](evidence/2026-10-19/task002/run-20261019T133800Z-isolation/03-reproduction.json) · SRS-5.1.1 |
| E-TASK002-ISOLATION-VERIFIER-20261019 | LOCAL_EMPTY_LAB_ISOLATION_VERIFICATION | PASS_SOLO_CONTENEDORES_VACIOS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation/10-live-verification.json](evidence/2026-10-19/task002/run-20261019T133800Z-isolation/10-live-verification.json) · SRS-5.1.1 |
| E-TASK002-ISOLATION-TESTS-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation/12-isolation-tests.json](evidence/2026-10-19/task002/run-20261019T133800Z-isolation/12-isolation-tests.json) · SRS-5.1.1 |
| E-TASK002-ISOLATION-REPORT-20261019 | SCOPED_DIAGNOSTIC_REPORT | E2A_BLOQUEADO_NO_IMPLEMENTADO | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation/REPORT.md](evidence/2026-10-19/task002/run-20261019T133800Z-isolation/REPORT.md) · SRS-5.1.1 |
| E-TASK002-E2A-R2-AUTH-20261019 | USER_CONFIRMATION | AUTORIZADO_SOLO_REINTENTO_E2A_LOCAL | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/AUTHORIZATION.md](evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-E2A-R2-PREFLIGHT-20261019 | LOCAL_LAB_PREFLIGHT | PASS_PRECONDICIONES_INICIALES_NO_ACEPTACION_A | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/02-full-preflight.json](evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/02-full-preflight.json) · SRS-5.1.1 |
| E-TASK002-E2A-R2-PREPARATION-20261019 | LOCAL_LAB_PREPARATION | PREPARACION_PARCIAL_NO_ACEPTADA | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/03-partial-preparation.json](evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/03-partial-preparation.json) · SRS-5.1.1 |
| E-TASK002-E2A-R2-FAILURE-20261019 | LOCAL_RECOVERY_INTEGRITY_FAILURE | FAIL_STOPPED | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/FAILURE-1792418995136753000.json](evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/FAILURE-1792418995136753000.json) · SRS-5.1.1 |
| E-TASK002-E2A-R2-TESTS-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/08-final-verifier-tests.log](evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/08-final-verifier-tests.log) · SRS-5.1.1 |
| E-TASK002-E2A-R2-REPORT-20261019 | BLOCKED_INCREMENT_REPORT | E2A_BLOQUEADO_NO_IMPLEMENTADO | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/REPORT.md](evidence/2026-10-19/task002/run-20261019T140102Z-e2a-r2/REPORT.md) · SRS-5.1.1 |
| E-TASK002-PAX-AUTH-20261019 | LOCAL_SCOPED_AUTHORIZATION | TWO_STAGE_AUTHORIZATION | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/AUTHORIZATION.md](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-PAX-TRANSPORT-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T143903Z-e2a-r3/pax/05-PAX-cycle.json](evidence/2026-10-19/task002/run-20261019T143903Z-e2a-r3/pax/05-PAX-cycle.json) · SRS-5.1.1 |
| E-TASK002-PAX-HISTORY-20261019 | LOCAL_LAB_DIAGNOSTIC | PRESERVED_FAILED_ATTEMPTS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/ATTEMPT-HISTORY.json](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/ATTEMPT-HISTORY.json) · SRS-5.1.1 |
| E-TASK002-R8-PREFLIGHT-20261019 | LOCAL_LAB_PREFLIGHT | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/02-full-preflight.json](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/02-full-preflight.json) · SRS-5.1.1 |
| E-TASK002-R8-IMPLEMENTATION-20261019 | LOCAL_LAB_IMPLEMENTATION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/05-A-transactional-installation.json](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/05-A-transactional-installation.json) · SRS-5.1.1 |
| E-TASK002-R8-FUNCTIONAL-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/06-functional-GREEN.json](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/06-functional-GREEN.json) · SRS-5.1.1 |
| E-TASK002-R8-CONSERVATION-20261019 | LOCAL_LAB_CONSERVATION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/07-integrity-conservation.json](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/07-integrity-conservation.json) · SRS-5.1.1 |
| E-TASK002-R8-RECOVERY-20261019 | LOCAL_LAB_RECOVERY | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/08-final-cold-recovery.json](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/08-final-cold-recovery.json) · SRS-5.1.1 |
| E-TASK002-R8-HARNESS-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/09-unit-tests.log](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/09-unit-tests.log) · SRS-5.1.1 |
| E-TASK002-R8-REPORT-20261019 | LOCAL_INCREMENT_ACCEPTANCE_REPORT | E2A_VALIDATED_LOCAL_ONLY | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/REPORT.md](evidence/2026-10-19/task002/run-20261019T152005Z-e2a-r8/REPORT.md) · SRS-5.1.1 |
| E-TASK002-S0-AUTH-20261019 | LOCAL_SCOPED_AUTHORIZATION | LOCAL_S0_ONLY | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/AUTHORIZATION.md](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-S0-PREFLIGHT-20261019 | LOCAL_LAB_PREFLIGHT | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/02-full-preflight.json](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/02-full-preflight.json) · SRS-5.1.1 |
| E-TASK002-S0-IMPLEMENTATION-20261019 | LOCAL_LAB_IMPLEMENTATION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/23-space-reference-GREEN.json](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/23-space-reference-GREEN.json) · SRS-5.1.1 |
| E-TASK002-S0-T49-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/10-T49-GREEN.json](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/10-T49-GREEN.json) · SRS-5.1.1 |
| E-TASK002-S0-NEGATIVE-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/15-additional-tests.json](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/15-additional-tests.json) · SRS-5.1.1 |
| E-TASK002-S0-REVIEW-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/23-space-reference-GREEN.json](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/23-space-reference-GREEN.json) · SRS-5.1.1 |
| E-TASK002-S0-CONSERVATION-20261019 | LOCAL_LAB_CONSERVATION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/25-data-conservation-v3.json](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/25-data-conservation-v3.json) · SRS-5.1.1 |
| E-TASK002-S0-RECOVERY-20261019 | LOCAL_LAB_RECOVERY | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/26-final-recovery-v3.json](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/26-final-recovery-v3.json) · SRS-5.1.1 |
| E-TASK002-S0-HARNESS-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/24-unit-tests-v3.log](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/24-unit-tests-v3.log) · SRS-5.1.1 |
| E-TASK002-S0-REPORT-20261019 | LOCAL_INCREMENT_ACCEPTANCE_REPORT | S0_VALIDATED_LOCAL_ONLY | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/REPORT.md](evidence/2026-10-19/task002/run-20261019T185927Z-e2s0/REPORT.md) · SRS-5.1.1 |
| E-TASK002-B-AUTH-20261019 | LOCAL_SCOPED_AUTHORIZATION | LOCAL_B_STRUCTURAL_ONLY | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/AUTHORIZATION.md](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/AUTHORIZATION.md) · SRS-5.1.1 |
| E-TASK002-B-PREFLIGHT-20261019 | LOCAL_LAB_PREFLIGHT | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/02-full-preflight.json](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/02-full-preflight.json) · SRS-5.1.1 |
| E-TASK002-B-IMPLEMENTATION-20261019 | LOCAL_LAB_IMPLEMENTATION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/05-B-installation.json](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/05-B-installation.json) · SRS-5.1.1 |
| E-TASK002-B-T09_T10-20261019 | TEST_EXECUTION | PASS_STRUCTURAL_ONLY | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/09-core-GREEN.json](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/09-core-GREEN.json) · SRS-5.1.1 |
| E-TASK002-B-T46-20261019 | TEST_EXECUTION | PASS_STRUCTURAL_ONLY | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/13-cases-manifests-GREEN.json](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/13-cases-manifests-GREEN.json) · SRS-5.1.1 |
| E-TASK002-B-CONCURRENCY-20261019 | TEST_EXECUTION | PASS_STRUCTURAL_PARTIAL_T11 | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/12-concurrency.json](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/12-concurrency.json) · SRS-5.1.1 |
| E-TASK002-B-REVIEW-20261019 | TEST_EXECUTION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/18c-review-GREEN.json](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/18c-review-GREEN.json) · SRS-5.1.1 |
| E-TASK002-B-CONSERVATION-20261019 | LOCAL_LAB_CONSERVATION | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/15-conservation-v2.json](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/15-conservation-v2.json) · SRS-5.1.1 |
| E-TASK002-B-RECOVERY-20261019 | LOCAL_LAB_RECOVERY | PASS | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/16-final-recovery.json](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/16-final-recovery.json) · SRS-5.1.1 |
| E-TASK002-B-REPORT-20261019 | LOCAL_INCREMENT_ACCEPTANCE_REPORT | B_STRUCTURAL_VALIDATED_LOCAL_ONLY | ACTUAL | [docs/evidence/2026-10-19/task002/run-20261019T212928Z-e2b/REPORT.md](evidence/2026-10-19/task002/run-20261019T212928Z-e2b/REPORT.md) · SRS-5.1.1 |

Las huellas cambiadas señalan evidencia potencialmente obsoleta: se conserva históricamente y no acredita validación vigente. No se alteran estados automáticamente. Los avisos del proveedor requieren evaluación contextual.

## Integridad

Los comandos y resultados se describen en [mantenimiento](../tool/traceability/README.md) y sus recibos anexos. Las pruebas del seguimiento no acreditan funcionalidad de MAREA.

## Casos normativos TC-51 — pendientes de implementación y ejecución

| ID | Requisitos | Estado | Escenario / expectativa | Dependencias |
| --- | --- | --- | --- | --- |
| TC-51-001 | RF-08-001, RF-02-005, RB-05 | PENDIENTE | `RF-08-001, RF-02-005, RB-05` \| Persona elegible publica/edita misión propia; tercero intenta hacerlo \| Solo titular autorizado, sin organización forzada | TASK-002 |
| TC-51-002 | RF-02-006, RF-02-007, RF-09-012 | PENDIENTE | `RF-02-006, RF-02-007, RF-09-012` \| Mismo humano alterna misión personal y representación organizacional \| Contexto explícito; sin acceso ni escritura cruzada | TASK-002 |
| TC-51-003 | RF-09-006, RF-09-012, CT-SEC-AUT-001 | PENDIENTE | `RF-09-006, RF-09-012, CT-SEC-AUT-001` \| Candidaturas leídas por dueño personal y por tercero \| Propietario permitido; tercero denegado en HTTP/RLS/Storage | TASK-002 |
| TC-51-004 | RF-09-007, CTR5-01, AT5-01 | PENDIENTE | `RF-09-007, CTR5-01, AT5-01` \| Dos emisores compiten por el último cupo personal y organizacional \| Solo una oferta y reserva válidas; sin sobrecupo | TASK-002 |
| TC-51-005 | RF-09-011, RF-10-001, CTR5-03 | PENDIENTE | `RF-09-011, RF-10-001, CTR5-03` \| Emitir oferta sin aceptación expresa de organizador \| Denegado sin oferta, firma, reserva ni outbox parcial | TASK-002 |
| TC-51-006 | RF-10-001, ADR42-02, CTR5-01 | PENDIENTE | `RF-10-001, ADR42-02, CTR5-01` \| Organizador firma al emitir; destinatario acepta dentro de TTL \| Activación inicial: oferta ACEPTADA + Agreement ACTIVO + cupo confirmado en transacción única; una terminación posterior cambia únicamente Agreement y conserva oferta/firma históricas | TASK-002 |
| TC-51-007 | CTR5-01, CT-SEC-AUT-007, AT5-02 | PENDIENTE | `CTR5-01, CT-SEC-AUT-007, AT5-02` \| Aceptar a expires_at exacto; job tarda; reintento/concurrencia expiración \| Rechazo por límite [inicio, fin), reserva liberada, sin acuerdo huérfano | TASK-002 |
| TC-51-008 | RF-09-013, ADR42-04, AT5-04 | PENDIENTE | `RF-09-013, ADR42-04, AT5-04` \| Titular se autopostula o firma por candidato; control compartido \| Rechazo, sin reputación fraudulenta | TASK-002 |
| TC-51-009 | RF-08-011, RF-10-005, AC-08 | PENDIENTE | `RF-08-011, RF-10-005, AC-08` \| Propuesta material con una sola aceptación; posterior rechazo o expiración \| Agreement anterior sigue ACTIVO con revisión anterior; propuesta terminal | TASK-002 |
| TC-51-010 | RF-10-003, RF-10-005, CTR5-03 | PENDIENTE | `RF-10-003, RF-10-005, CTR5-03` \| Dos partes aceptan revisión material vigente antes del límite \| Nueva revisión activada atómicamente; anterior SUPERADA y auditada | TASK-002 |
| TC-51-011 | RF-10-005, ADR42-03 | PENDIENTE | `RF-10-005, ADR42-03` \| Cambiar identidad de contraparte en acuerdo activo \| Rechazo como revisión ordinaria; requiere cierre/nuevo acuerdo | TASK-002 |
| TC-51-012 | RF-23-009, AT5-02, CTR5-01 | PENDIENTE | `RF-23-009, AT5-02, CTR5-01` \| Oferta/aceptación sin conexión o con JWT revocado \| Sin éxito optimista; permisos y TTL verificados en backend | TASK-002, TASK-003 |
| TC-51-013 | RF-25-011, ADR42-16, AT5-14 | PENDIENTE | `RF-25-011, ADR42-16, AT5-14` \| Binario móvil legado renderiza accepted sin acuerdo bilateral \| No presenta confirmado: lectura bloqueada/forzar actualización segura | TASK-002 |
| TC-51-014 | RF-02-005, RF-09-012, CT-SEC-AUT-003 | PENDIENTE | `RF-02-005, RF-09-012, CT-SEC-AUT-003` \| ID ajeno de misión persona/org en RPC o Edge \| Rechazo, sin fuga de datos ni mutación | TASK-002 |
| TC-51-015 | RF-02-004, CTR5-03, CT-SEC-AUT-005 | PENDIENTE | `RF-02-004, CTR5-03, CT-SEC-AUT-005` \| Representante emisor pierde membresía y org continúa NORMAL \| Firma histórica auditada; el exmiembro pierde acceso; oferta puede persistir | TASK-002, TASK-003 |
| TC-51-016 | RF-02-004, CTR5-01, ADR42-02 | PENDIENTE | `RF-02-004, CTR5-01, ADR42-02` \| Organización suspende o pierde propiedad con oferta pendiente \| Aceptación bloqueada, cancelación de oferta y liberación; activos aparte | TASK-002 |
| TC-51-017 | RF-01-012, RF-25-004, CTR5-05 | PENDIENTE | `RF-01-012, RF-25-004, CTR5-05` \| Eliminar cuenta con borradores, misión pública, oferta, reserva, acuerdo \| Nueva obligación bloqueada, pendientes cancelados, activos supervisados, supresión aplicada | TASK-002, TASK-003 |
| TC-51-018 | RF-02-005, RF-25-011, ADR42-16 | PENDIENTE | `RF-02-005, RF-25-011, ADR42-16` \| Clasificar misión legada personal u org con evidencia o caso ambiguo \| XOR en modelo nuevo; ambiguo histórico sólo lectura sin dueño inventado | TASK-002 |
| TC-51-019 | RF-09-007, CT-SEC-AUT-006, CT-SEC-AUT-007 | PENDIENTE | `RF-09-007, CT-SEC-AUT-006, CT-SEC-AUT-007` \| Repetir idempotency_key con payload cambiado y carreras aceptar/cancelar \| Rechazo consistente, no dobles eventos ni reserva huérfana | TASK-002 |
| TC-51-020 | RF-08-011, RF-10-001, CTR5-01 | PENDIENTE | `RF-08-011, RF-10-001, CTR5-01` \| Cerrar/expirar misión con oferta previa, cancelar misión con acuerdo activo \| Sin nuevas ofertas; previas siguen vigentes salvo cancelación; acuerdo activo no se borra | TASK-002 |
| TC-51-021 | RF-25-011, CTR5-07, ADR42-16 | PENDIENTE | `RF-25-011, CTR5-07, ADR42-16` \| Cache legada offline y deep link tras actualizar \| Nueva app corrige cache; no prometer reparar offline inalcanzable | TASK-002 |
<!-- MAREA:GENERATED:END -->
