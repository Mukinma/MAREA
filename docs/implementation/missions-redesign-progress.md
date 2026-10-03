# Misiones: implementación del plan aprobado — 2026-09-30

Plan: rediseño integral aprobado en esta conversación.

Ruling: trabajar en el checkout actual Chris/mission-map para conservar los cambios locales de mapa y navegación; no crear un checkout que los pierda.

## Contrato compartido

Modelos en community_models.dart (exportarán mission_experience.dart):
- Mission/MissionInput añaden String? compensationType (`unpaid`, `negotiable`, `paid`), int? compensationAmountCents. Mission.compensationLabel.
- MissionApplication añade bool? availabilityConfirmed, List<MissionEvidence> evidence (default []).
- MissionEvidence({required String title, String? showcaseId, String? url}); fromJson/toJson/validate. Exactamente uno de showcaseId/url; hasta tres muestras.
- MissionApplicationInput({required String message, required bool availabilityConfirmed, List<MissionEvidence> evidence = const [], required String operationId}); validate/toJson.
- MissionDraft({required String id, required Map<String,dynamic> data, required DateTime updatedAt, String? publishedMissionId, DateTime? publishedAt}); data contiene los campos de MissionInput, permite campos incompletos.

CommunityRepository conserva sus métodos y añade:
- Future<List<MissionDraft>> missionDrafts(); Future<MissionDraft?> missionDraft(String id);
- Future<String> saveMissionDraft(Map<String,dynamic> data, {required String id});
- Future<String> publishMissionDraft(String id, MissionInput input);
- Future<void> deleteMissionDraft(String id);
- Future<Set<String>> savedMissionIds(); Future<void> setMissionSaved(String id,bool saved);
- Future<String> submitApplication(String missionId,MissionApplicationInput input);
- Future<Set<String>> missionFinalists(String missionId); Future<void> setMissionFinalist(String missionId,String applicationId,bool finalist);
- Future<void> confirmMissionSelection(String missionId,List<String> applicationIds);

RPCs: save_mission_draft(draft_id uuid,draft_input jsonb), publish_mission_draft(draft_id uuid,mission_input jsonb), delete_mission_draft(draft_id uuid), submit_mission_application(mission_id uuid,application_input jsonb), set_mission_finalist(mission_id uuid,application_id uuid,is_finalist boolean), confirm_mission_selection(mission_id uuid,application_ids uuid[]), set_mission_saved(mission_id uuid,is_saved boolean).
Lecturas privadas de mission_drafts, mission_saves, mission_finalists vía RLS.

Rutas nuevas: /missions/drafts/:id/edit (composer draftId), /missions/:id/apply (MissionApplicationScreen), /missions/:id/sent?application=ID (MissionApplicationSentScreen), /missions/:id/manage (MissionManagementScreen).
Widgets de pantallas nuevas reciben required AppSessionController controller, required String missionId. Sent recibe String? applicationId.
MissionComposerScreen añade String? draftId.

Notificaciones: post_id pasa a nullable, mission_id uuid opcional, post_title conserva el título de destino. Tipos: mission_application, mission_accepted, mission_rejected, mission_withdrawn, mission_closed, mission_reopened, mission_cancelled, mission_completed. Mantener tipos anteriores. source_id = candidatura cuando corresponda.

## Tareas
- [x] Datos Dart y repositorios / tests (modelos y contratos con pruebas de recuperación y limpieza).
- [x] Migración SQL, privacidad, idempotencia, notificaciones y pruebas aisladas. `013_missions_redesign.sql`: 146 aserciones PGlite y 10 pruebas del gate; migración 013 aplicada y contrato remoto aprobado.
- [x] Composer de cuatro pasos, borradores, edición (14 pruebas, capturas móviles/tablet/escritorio).
- [x] Candidatura, confirmación y gestión independiente (19 pruebas, evidencias opcionales/paginadas, recuperación).
- [x] Listado, detalle, guardados, menú +, rutas y campana (13 pruebas nuevas de integración, destinos autenticados y notificaciones).
- [x] Suite integrada, capturas, builds, backend y documentación.

Verificación integrada final: flutter test → 387 aprobadas; flutter analyze sin incidencias. Revisión independiente final sin regresiones materiales. Web, APK debug e iOS release sin firma compilan con la configuración real, secuencialmente.

### Candidatura y gestión — validación

Pantallas dedicadas terminadas con flujo de tres pasos, muestras propias/enlaces HTTPS opcionales, recuperación de respuesta perdida y UUID estable para reintentos. Si hubo persistencia y el usuario editó tras perder la respuesta, muestra la candidatura original guardada y explica que los cambios posteriores no se enviaron. Gestión privada con finalistas y selección provisional confirmada en lote; sin cierre/rechazo automático. 19 pruebas de participación pasan, incluido paginado de muestras, cuatro perfiles y anchos 360/390/768/1440 con texto a 1.4. Análisis de las dos pantallas y pruebas sin incidencias. Capturas reproducibles con `MAREA_SCREENSHOTS=1 flutter test test/features/community/mission_participation_test.dart`.

### Cierre — 30 de septiembre de 2026

- Corregidos con regresiones: cambios tras publicación/envío con respuesta perdida, descarte de borrador cuya respuesta de guardado se perdió, journal de publicación cuya misión fue eliminada, limpieza de portadas, campana con fallo al marcar leído, destino conservado por autenticación y actualización de elegibilidad tras fallar candidatura.
- SQL aislado: 720 comprobaciones en misiones, rediseño, permisos, comunidad, fichas, mapa y social; más 10 pruebas del gate. El payload exacto del compositor guarda hora/minuto numéricos; los borradores admiten entrada incompleta, con tipos y tamaños seguros.
- Backend: aplicada únicamente 013. Migraciones 001–013 coinciden local/remoto; dry-run final sin pendientes. Gate y presencia de validación estricta de evidencias confirmados en remoto. Lint SQL remoto sin errores.
- Integración real: 54 checks de misiones y 21 de experiencia social aprobados. Tres cuentas temporales por runner, JWT de usuario, publicación/envío/selección concurrentes, privacidad, avisos y persistencia. Limpieza verificada: cero cuentas temporales restantes.
- Capturas: 43 vistas reproducibles en /tmp/marea-validation, revisadas en móvil, tablet y escritorio; texto ampliado y teclado simulado cubiertos por pruebas.
- Builds locales: build/web, build/app/outputs/flutter-apk/app-debug.apk, build/ios/iphoneos/Runner.app. Cliente no distribuido ni Web publicado por este trabajo.
- Se preservaron los cambios locales previos de mapa, marca y configuración. QA de teclado/permisos en teléfonos físicos continúa como verificación manual antes de distribución.
- Flujos y contrato documentados en docs/missions-redesign.md.
