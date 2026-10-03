# Misiones: flujos y contrato

El rediseño conserva repositorios, categorías, cuatro perfiles, mapa, moderación y ciclo de vida. Usa Nunito, celeste, navy, aqua y tarjetas blancas.

## Recorridos

Explorar conserva búsqueda en servidor, filtros y paginación. Guardadas pertenece a Explorar; los borradores privados están en Mis misiones. Mis candidaturas conserva historial, retirada y repostulación. Volver del detalle mantiene filtros y desplazamiento.

Crear y editar comparten cuatro pasos: idea; colaboración y compensación; lugar y fecha; revisión. La edición explica los campos bloqueados desde la primera candidatura. Los borradores admiten datos incompletos y texto temporalmente inválido; no aparecen en descubrimiento ni mapa. Salir ofrece guardar, descartar o continuar. Publicar utiliza UUID estable y journal para crear una sola misión; la recuperación explica qué versión se publicó.

El detalle muestra portada real opcional, organizador con perfil, fecha, lugar, cupo, compensación, descripción, requisitos y condiciones. Reutiliza el visor de ubicación. La acción inferior refleja elegibilidad, candidatura o gestión.

La candidatura tiene tres pasos: revisar misión; motivación, disponibilidad y muestras; revisar y enviar. Admite hasta tres muestras opcionales: fichas propias publicadas o enlaces HTTPS con título. Una ficha retirada u oculta muestra «Muestra no disponible». La confirmación usa la misión real sin prometer tiempos. Los fallos conservan el formulario, refrescan elegibilidad y recuperan envíos persistidos.

Gestión es privada del organizador, con contadores reales, filtros y candidaturas estructuradas. Finalistas es una lista interna sin avisos ni cambio de estado público. La selección es provisional hasta revisar y confirmar el grupo; SQL la ejecuta atómicamente respetando cupo, sin cierre ni rechazo automático. Conserva edición, cierre/reapertura, cancelación con motivo y finalización.

El «+» abre un panel inferior móvil o anclado en escritorio, fondo atenuado y transición a cerrar. Incluye misión para todos y opciones profesionales; /create reutiliza las opciones.

## Persistencia y privacidad

La migración aditiva 013 añade compensación por participante: sin pago, por acordar o importe fijo en céntimos MXN. Se bloquea tras la primera candidatura. Los datos antiguos muestran «Compensación no indicada».

mission_drafts separa datos privados y journal published_at/published_mission_id: una misión eliminada no vuelve como borrador. Guardados y finalistas tienen RLS por propietario. Solo participante y organizador acceden a candidaturas/muestras; el servidor valida propiedad y visibilidad de fichas. Las portadas de borrador son privadas y se limpian imágenes sin referencias tras borrar.

RPC nuevos: save_mission_draft, publish_mission_draft, delete_mission_draft, list_saved_missions, set_mission_saved, submit_mission_application, set_mission_finalist y confirm_mission_selection. Las operaciones anteriores siguen compatibles. El envío devuelve el ID de candidatura; su UUID evita duplicados y detecta conflictos de payload.

La campana recibe candidatura, aceptación/rechazo, retirada y cierre/reapertura/cancelación/finalización para participantes activos. Reintentos sin avisos duplicados. Finalistas no notifican; fallar al marcar leído no bloquea navegación. Las rutas específicas verifican sesión, propiedad y estado y sus destinos internos sobreviven autenticación.

No se agregan pagos, chat, push, correos, afinidad, insignias ni plazos ficticios. La fecha de inicio sigue siendo el límite de candidatura.

## Verificación reproducible

Ejecutar Flutter secuencialmente, con config/supabase.production.json para builds.

- flutter analyze y MAREA_SCREENSHOTS=1 flutter test.
- MAREA_PGLITE_MODULE=/ruta/a/pglite/dist/index.js node tool/check_missions_redesign_database.mjs.
- node --test test/tool/backend_contract_test.mjs.
- supabase migration list --linked y supabase db push --linked --dry-run; aplicar antes de distribuir cliente.
- node tool/check_backend_contract.mjs y node tool/check_live_missions_flow.mjs --run.
- flutter build web, flutter build apk --debug y flutter build ios --no-codesign, con --dart-define-from-file=config/supabase.production.json.

SQL aislado no contacta Supabase. El runner live crea exclusivamente cuentas temporales .invalid confirmadas, mantiene credenciales en memoria y limpia sus datos; no envía correo ni usa cuentas existentes. Estado de entrega en [ledger](implementation/missions-redesign-progress.md).

Interfaz probada en 360/390 px, tablet y escritorio con texto ampliado y teclado simulado. Capturas reproducibles en /tmp/marea-validation. Teclado y permisos en teléfonos físicos requieren QA manual previo a distribución.
