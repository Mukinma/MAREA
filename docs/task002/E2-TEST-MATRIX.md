# E2 — Matriz de pruebas y aceptación propuesta

**19 octubre 2026. TODOS LOS CASOS SIGUIENTES: DISEÑADOS / NO EJECUTADOS.** No sustituyen las pruebas reales de E1 ni los cinco FAIL de TASK-001. No hay nueva validación de producto en esta entrega. Diseño e invariantes en [E2-TECHNICAL-DESIGN.md](E2-TECHNICAL-DESIGN.md); autorizaciones por [E2-AUTHORIZATION-DOSSIER.md](E2-AUTHORIZATION-DOSSIER.md).

## Preparación y oráculo

En un hito futuro expresamente autorizado: dos clones nuevos derivados de E1, DB/Storage independientes, red aislada y pruebas separadas positivas y negativas mediante roles reales y clientes HTTP. No reutilizar/modificar los volúmenes E1 ni mezclar con el runtime bloqueado de TASK-001. Bindear imagen, origen, herramientas, SQL y corpus. Fixtures adicionales: dos titulares personales, dos organizaciones, roles distintos/revocados, candidata ajena, casos ambiguos y recursos compartidos. Declarar su ground truth, sin clasificar por user_type ni fabricar consentimiento histórico.

El oráculo compara **todas** las tablas/filas/digests, secuencias, FK, índices, triggers, policies, ACL efectivas, funciones/cuerpos y objetos Storage. Una migración sin disposición exige igualdad del legado; una prueba de eliminación usa un manifiesto explícito de cambios permitidos y exige igualdad de todo lo demás. Timestamps/UUID nuevos no se borran de la comparación para ocultar diferencias; se documentan como adiciones autorizadas.

Cada caso conservará inputs minimizados, actor/contexto, operación/versión, resultado/error, postcondiciones SQL/Storage, catálogos y logs privados. Exit code cero o UI sin error no basta. Pruebas de capacidades deshabilitadas se registran BLOQUEADO/NO_IMPLEMENTADO, nunca PASS. Seguridad dependiente de TASK-003 exige prueba real integrada, no mocks, claims administrativos o expiración temporal como sustituto de revocación.

## Casos planificados

| ID / nombre futuro | Actor, entrada o carrera | Oráculo exigido | Hito / dependencia |
|---|---|---|---|
| E2-T01 `source_drift_aborts` | Backup equivocado, schema/ACL/cuerpo distinto o destino no aislado | Aborto antes del DDL, ninguna ruta alternativa ni cambio de origen | A / todas las puertas |
| E2-T02 `signup_creates_one_person` | Alta válida estándar/minimal-v1, varios proveedores del mismo Auth | Un Person, id/mapping correcto, validaciones legales/perfil actuales intactas | A |
| E2-T03 `signup_failure_is_atomic` | Falla de trigger Person/perfil/legal en cada punto | No quedan Auth/perfil/aceptación legal/Person parciales; error no simula alta exitosa | A |
| E2-T04 `forged_metadata_confers_no_authority` | user_metadata role/admin/org/Person ajeno | Sin privilegio, pertenencia ni titularidad nuevos | A/C |
| E2-T05 `parallel_repair_is_idempotent` | Dos reconciliadores + trigger sobre misma identidad | Un principal; mismo resultado o conflicto explícito, sin duplicidad/roles | A |
| E2-T06 `repair_never_relinks_detached` | Auth inexistente, id colisionado, principal NULL o supresión vigente | No religa, no crea perfil/organización, reporte minimizado de conflicto | A / D01 |
| E2-T07 `repair_vs_auth_delete_serializes` | Reparación concurrente con DELETE Auth controlado | O vínculo válido antes del borrado o ausencia/desvinculación; nunca huérfano ni resurrección | B/integración tras D/M; **excluido de A** |
| E2-T08 `principal_stays_private` | anon/authenticated CRUD, introspección RPC y acceso por IDs manipulados | 42501/denegación uniforme sin filas, mappings ni PII; RLS/grants efectivos también probados | A, regresión E1 |
| E2-T09 `auth_and_profile_delete_cannot_bypass_plan` | Admin API Auth, SQL DELETE ordinario perfil/Auth, endpoint legado | Guarda registrada deniega purga no preparada; solicitud recibida no desaparece | B/D/M |
| E2-T10 `deletion_request_retry_is_consistent` | Dos solicitudes, timeout tras commit, misma/diferente operation_id/cuerpo | Una solicitud durable/plan; consulta del resultado; no doble limpieza ni falsa finalización | B |
| E2-T11 `deletion_blocks_new_obligations_immediately` | Worker detenido tras registrar solicitud | Publicación/candidatura/oferta/aceptación personal nuevas denegadas antes del job | B / motores T2 posteriores |
| E2-T12 `active_case_survives_credential_purge` | Baja con compromiso activo/disputa y expediente autorizado | Perfil/credenciales no necesarios para conservar expediente mínimo; firma/contraparte no suplantada | B/D / contratos, política, TASK-003 |
| E2-T13 `member_exit_preserves_org_resources` | Miembro/editor/fundador elimina cuenta | Misiones/candidaturas/medios org intactos, exmiembro sin facultad, sin JOIN obligatorio a fundador | C integrada tras B/D/M / ORG-0 y TASK-003 |
| E2-T14 `last_owner_exit_is_restricted` | Único propietario sin sucesor | UNOWNED_RESTRICTED, no sucesión automática ni nuevas obligaciones, recursos conservados | C integrada tras B/D/M / ORG-0 |
| E2-T15 `personal_owner_is_not_inferred` | Misión ligada a perfil/Auth pero evidencia de propiedad insuficiente | REVIEW_REQUIRED interno, sin fila operativa de dueño ni ofertas/publicación | C / D05 |
| E2-T16 `business_is_not_organization` | user_type Negocio, reclamo org, perfil sin Auth | Ninguna organización/membresía/transferencia inventada; historial minimizado | C |
| E2-T17 `ownership_xor_is_enforced_at_commit` | Alta sin dueño, ambos dueños, borrado sidecar o actualización privilegiada ordinaria | Transacción falla por constraints/guardas; no ancla operativa sin titular | C / ORG-0 |
| E2-T18 `classifiers_conflict_safely` | Dos manifests/versiones/titulares para una misión | Un único resultado; misma decisión idempotente, distinta decisión rechazada | C |
| E2-T19 `creator_is_not_current_representative` | Creador desvinculado vs representante vigente, IDs de otra organización | Creador no administra por author_id; representante habilitado sí; acceso cruzado denegado | C/K / ORG-0, TASK-003 |
| E2-T20 `related_candidate_remains_gated` | Persona vinculada/controlante de organización intenta postular | No se concede elegibilidad por inferencia; caso pendiente de regla normativa/servidor validada | C/K / D10 |
| E2-T21 `mission_author_cut_preserves_legacy` | Corte de FK en A/B y dataset multi-autor | Mismos IDs/valores/filas, diez FK entrantes intactas; nueva FK validada RESTRICT; vieja retirada sólo al final | X |
| E2-T22 `applicant_profile_delete_keeps_required_application` | Se elimina perfil de candidata con candidatura protegida | Candidatura y recibo mínimo conservados por ID; PII sólo según manifiesto; sin notificación inválida | D/B / D03 |
| E2-T23 `mission_delete_cannot_cascade_children` | authenticated, service worker sin plan y autor antiguo intentan DELETE | Ninguna cascada de misiones/candidaturas/reportes; retiro legítimo usa procedimiento | C/D/X |
| E2-T24 `all_profile_children_have_disposition` | Borrado con comentarios, reacciones, guardados, reportes y avisos | Cada una de 36 FK inventariadas tiene decisión, delta y prueba; nunca retención universal implícita | D / D02/D03 |
| E2-T25 `profileless_projection_keeps_org_visible` | Perfil creador eliminado; lista/mapa/feed/guardados/deep link | Recurso permitido sigue accesible por titular; ningún dato del eliminado se vuelve público | K/M / ORG-0 |
| E2-T26 `wrappers_cannot_bypass_authorization` | Invocar legacy/before_city/sobrecargas con parámetros válidos y forjados | Sin EXECUTE ordinario o mismo gate; ciudad/compensación/validadores conservados | K |
| E2-T27 `raw_rest_and_realtime_do_not_leak` | SELECT/embeds de tablas, funciones, Storage y suscripción anterior | Mismo alcance por actor/recurso; principal privado; superficie contractual incompatible cerrada | K / TASK-003 para socket |
| E2-T28 `unilateral_selection_is_rejected` | review_application accepted y confirm_mission_selection en open/closed | UPDATE_REQUIRED/denegación, cero mutación/firma/reserva/avisos engañosos | K / regresiones TASK-001 |
| E2-T29 `legacy_acceptance_never_looks_signed` | Tres accepted históricos, oferta pendiente o acuerdo terminal | No accepted/contador/aviso contractual falso en v1; v2 distingue evidencia heredada y acuerdo real | K / futuro motor contractual |
| E2-T30 `all_notifications_and_feed_snapshots_are_checked` | Aviso mission_accepted antiguo, push pendiente, snapshot feed y deep link | No se filtra confirmación falsa por vía alterna; no borrar historia para ocultar el problema | K |
| E2-T31 `real_legacy_binary_has_safe_outcome` | Binario anterior Android/iOS/web aplicable, cache, deep link y sesión recuperada | Dibujo seguro o bloqueo verificable; cliente nuevo corrige cache al reconectar; límites offline declarados | F / autorización Flutter y artefactos reales |
| E2-T32 `deletion_202_is_not_reported_complete` | Endpoint v2 en curso, error Storage, cliente antiguo frente a endpoint legado | Nuevo cliente muestra etapa real; antiguo no recibe un 2xx que simule purga | F/B / D08 |
| E2-T33 `asset_prefix_is_not_ownership` | Imagen bajo UUID de miembro usada por misión org; objeto/bucket con owner/owner_id del Auth a eliminar | No borra asset en uso. Si Auth rechaza baja por propiedad Storage, custodia/reasignación soportada o copia API aprobada conserva bytes/derechos/bindings/compatibilidad; no saltar restricción con metadata SQL o cuenta ficticia | M / D04, integración T12 |
| E2-T34 `shared_asset_is_not_deleted` | Misma imagen usada por dos recursos; baja de uno | El otro binding/archivo/digest permanece; retiro de permiso de uso se tramita separado | M / D04 |
| E2-T35 `service_role_cannot_skip_asset_plan` | Worker sin uid intenta limpieza por prefijo/objeto | Guarda de uso/claim bloquea igual; no basta GUC manipulable | M |
| E2-T36 `asset_bind_vs_delete_serializes` | Asociar recurso mientras worker prepara borra; objeto/key reemplazados | Binding válido conserva archivo o delete justificado completa; no referencia a fichero perdido ni borrado de versión distinta | M |
| E2-T37 `storage_failures_are_resumable` | Error antes/después de cada API remove/copy, TTL lease, worker duplicado | Reintento por objeto, sin afirmar exact-once remoto ni 204 prematuro; metadata y físico reconciliados | M |
| E2-T38 `deleted_profile_does_not_break_events` | Cambio de candidatura/misión con actor/recipient sin perfil | Evento durable mínimo o destinatario válido; no FK failure ni perfil/consentimiento inventado | D/K |
| E2-T39 `cut_validation_failure_keeps_old_fk` | Huérfano, lock_timeout, FK no validable, fallo antes/después de DROP | Rollback transaccional deja FK/catálogo/filas/ACL iniciales; sin constraints deshabilitados | X |
| E2-T40 `index_and_schema_cache_failure_is_detected` | Índice concurrente inválido, cache PostgREST antigua, embed ambiguo | Corrida se detiene y registra; no continuar con schema engañoso ni DROP CASCADE | X/K |
| E2-T41 `down_migration_is_refused_when_unsafe` | Perfil ya eliminado o fila nueva incompatible con FK vieja | Reversión rechazada, datos conservados y escrituras afectadas cerradas; forward fix explícito | X/R |
| E2-T42 `restore_includes_db_storage_roles_and_e1` | Respaldo completo restaurado en copia nueva | Filas/DDL/ACL/roles/objetos verificados; E1 correcto y SQL E anterior no reejecutado | R |
| E2-T43 `restore_reapplies_later_suppression` | Backup anterior a baja + ledger posterior | Ninguna PII/foto/alta suprimida se expone; checkpoint ausente mantiene copia aislada | R / TASK-003 |
| E2-T44 `locks_have_bounded_retries` | Reparación, baja, alta/edición, clasificación y workers con barreras concurrentes | Sin deadlock no gestionado ni espera infinita; reintento limitado conserva idempotencia y permisos | A/B/C/M/X |
| E2-T45 `task003_failures_remain_a_release_gate` | JWT previo a logout, socket abierto, URL firmada tras revocación | Evidencia real de TASK-003 requerida; E2 no convierte expiración/mocks en PASS integral | integración TASK-003 |
| E2-T46 `protected_access_is_case_scoped` | Soporte sin caso, caso ajeno o expirado intenta datos retenidos | Denegación; caso asignado con finalidad permite sólo campos mínimos y deja auditoría | B/D / política |
| E2-T47 `retention_is_not_false_anonymization` | Person UUID igual a Auth previo, hash simple, texto/foto identificable | Clasifica seudonimización, no certifica anonimato; expiración/purga sólo bajo decisión aprobada | B/R / D02/D04 |
| E2-T48 `counterparty_never_changes_by_owner_edit` | Transferencia personal→org o entre entidades con acuerdo existente | No cambia parte/firma ni términos por update; exige nuevo acuerdo/proceso documentado | C / contratos |
| E2-T49 `inflight_legacy_cleanup_is_fenced` | delete-account/worker legado inició antes del corte y reintenta borrar medio en uso tras barrera | Bytes/hash y vínculos conservados; ejecución drenada/invalidada y ruta de solicitud disponible; no basta denegar DELETE Auth | S0, previo a B/C/D/M/X |

## Recibos y aceptación por hito

Cada incremento futuro tendrá AUTHORIZATION, preflight/hashes, SQL/fuentes exactas, pruebas positivas/negativas, fallos conservados, comparación antes/después, recuperación y REPORT. Una reanudación sólo por fallo del harness exige causa demostrada y precondiciones de datos intactas; nunca esquivar drift o un control de seguridad con alternativas más amplias.

- **A:** T01–06/T08 y sólo reparación de T44; alta/repair privados, sin DELETE Auth/perfil, sin modificar author_id, FK, medios o producto Flutter. T06 usa fixtures nuevos de control/desvinculación. T07 y baja de T44 diferidas. Regresión de privacidad E1 y casos de alta legal obligatorios.
- **S0:** T49 y bypass correspondientes T09/T35; sin esta prueba no se activa transición parcial de eliminación o referencias. No presuponer atomicidad física del Storage instalado.
- **B estructural:** registro/bloqueo/guardas negativas T09/T10/T46; integraciones T07/T11/T12/T32/T47 y baja de T44 sólo cuando estén disponibles sus motores/dependencias y autorización. No acredita purga integral ni éxito final.
- **C estructural:** T15–20/T23 aplicables, ORG-0 real y representaciones personal/organizacional; XOR y clasificación deben rechazarse por SQL, no sólo por Flutter. T13/T14 de baja completa y T48 contractual quedan diferidos a integración tras B/D/M/contratos/TASK-003 aplicables; M puede consumir C estructural sin afirmar esos PASS.
- **D/M:** T22–24/T33–38, manifiesto por cada FK y asset; derechos/política aprobados y protección de todo entrypoint destructivo.
- **K/F:** T25–32/T38/T40; todas las superficies y binarios efectivamente soportados. U0 no es prueba de implementación.
- **X/R:** T21/T39–44 y regresiones anteriores; rollback antes del punto irreversible, forward-only después, restore íntegro aislado y supresiones verificadas.

**Aceptar un hito local no autoriza el siguiente ni un entorno remoto.** Requisitos y TC-51 permanecen con su evaluación histórica hasta evidencia integral suficiente. Los 49 casos son una especificación de pruebas, no 49 PASS.
