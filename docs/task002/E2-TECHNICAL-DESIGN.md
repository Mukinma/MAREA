# E2 — Separar autoría, titularidad y perfil sin pérdida de recursos

**19 octubre 2026. PROPUESTA TÉCNICA, NO AUTORIZADA PARA IMPLEMENTACIÓN O EJECUCIÓN.** Fuente de diseño: SRS v5.1.1; baseline efectiva histórica v5.0, sin cambio de adopción. E1 está implementado únicamente en sus dos copias sintéticas. Este expediente no acredita compatibilidad con datos reales ni habilita Flutter, RPC o remoto.

Lecturas necesarias: [expediente de autorización](E2-AUTHORIZATION-DOSSIER.md), [secuencia de implementación](E2-IMPLEMENTATION-PLAN.md), [matriz de aceptación](E2-TEST-MATRIX.md), [inventario vinculado](E2-DEPENDENCY-INVENTORY.json). Las recomendaciones siguientes son decisiones del diseño propuestas para revisión; ninguna se presenta como aprobada por el usuario.

## 1. Base comprobada y alcance de esta revisión

E1 creó `collaboration.persons(id, auth_user_id, created_at)`, con PK estable, Auth UNIQUE anulable/SET NULL, RLS y denegación a clientes. A/B contienen seis principales cada uno. No sincroniza altas futuras, no define retención ni protege misiones al eliminar perfiles. Su propuesta original con barrera/ROLLBACK, ejecutables y evidencias permanecen intactos.

El análisis deriva de snapshots congelados de E1, sus recibos y fuentes del repositorio; **no se inició Docker, ejecutó SQL ni consultó una base en esta revisión**. El inventario contiene 85 archivos con SHA-256, 116 anclas y 56 rutinas relevantes, incluidas dependencias indirectas. Hay 102 FK después de E1; 36 referencias entrantes a perfiles y diez a misiones. No se confunden estos conteos con un nuevo inventario operativo o remoto. Las dos fuentes son fixtures limitados: seis misiones, un autor distinto, ocho candidaturas (tres accepted legados) y ninguna organización o perfil Negocio por fuente.

Dependencias que impiden un simple cambio de FK:

| Hallazgo efectivo | Riesgo concreto | Tratamiento propuesto |
|---|---|---|
| `missions.author_id → profiles ON DELETE CASCADE` | Auth→perfil borra seis misiones y ocho candidaturas en los fixtures históricos | Referencia aditiva validada a Person; retirar la FK anterior únicamente en el corte aprobado |
| `mission_applications.applicant_id → profiles CASCADE` | Borrar a una candidata sigue borrando su candidatura aunque sobreviva la misión | Conservar ID e identidad estable de candidatura; corte de esta dependencia en hito específico |
| `mission_application_operations.applicant_id → profiles CASCADE` | Se pierde deduplicación/historial al eliminar perfil | Conservar recibos mínimos que tengan finalidad vigente; política y nueva referencia explícitas |
| `missions` concede DELETE a authenticated con policy de autor | Borrado directo elude el flujo de cierre | Denegar DELETE físico ordinario; retirada/cancelación por contrato autorizado, sin cascada silenciosa |
| Lecturas/RLS/gestión equiparan `author_id = auth.uid()` a dueño | Exrepresentante conserva facultad o nuevo representante carece de ella | Resolver «organizador autorizado» con titularidad actual; autoría histórica nunca concede representación |
| `list_missions`, mapa, guardados y feed hacen JOIN a profiles | Desaparece el recurso al eliminar el perfil del creador | Resolver parte organizadora independiente; perfil opcional con proyección segura, sin INNER JOIN obligatorio |
| `notify_mission_*`, comentarios y notificaciones dependen de perfiles | Aviso falla, desaparece o revela autor eliminado; accepted sugiere contratación | Destinatarios vigentes, actor público opcional/minimizado y eventos versionados; revisión de avisos históricos |
| Edge `delete-account` borra cinco buckets por prefijo y luego Auth | Borra medios usados por terceros/organización antes de retirar la FK | Sustituir limpieza ciega por plan por recurso, reservas de operación y API Storage |
| `guard_mission_image_operation` sólo impide borrar en uso si auth.uid no es NULL | Un contexto privilegiado sin uid no tiene esa protección de uso | Guarda de referencias/plan también para workers y service_role; no asumir protección por RLS |
| `account_deletion_requests.user_id → auth.users CASCADE` | El marcador desaparece con Auth y no sirve como ledger durable | Control/solicitud privados independientes de Auth y supresión reconciliable |
| Flutter consulta candidaturas directamente y trata todo 2xx de borrado como final | UPDATE_REQUIRED sólo en RPC o responder 202 puede dejar estados falsos | Puerta por superficie completa; protocolo de borrado v2 y compatibilidad explícita |

La prueba histórica de cascada y los cinco FAIL de TASK-001 no se repiten ni cambian a PASS aquí. Los documentos E anteriores contienen estados fechados superados por E1: se preservan como historia; no se debe ejecutar `E-PROPOSED-REFERENCE.sql`, que intenta crear objetos ya existentes y sólo comprueba existencia de un hook.

## 2. Alternativas y recomendación

| Alternativa | Ventajas | Costes/riesgos | Decisión propuesta |
|---|---|---|---|
| A. Cambiar sólo la FK de author_id a Person | Menor DDL; conserva UUID | No modela titularidad, candidatos, medios, borrado ni clientes; permisos siguen ligados al creador | Insuficiente como E2 completo; es sólo una operación final de un plan mayor |
| B. Añadir owner_person_id/owner_organization_id directamente a missions | XOR local a fila; consultas simples | SELECT/to_jsonb del legado expone campos internos nuevos; ampliar fila pública y políticas afecta clientes | Viable si se cierran todas las superficies; mayor impacto inmediato |
| C. Tabla privada de titularidad uno a uno con missions; conservar ancla y autoría | No cambia DTO público por expansión; separa atribución de autoridad; permite clasificación gradual | Exige guardas transaccionales contra falta de titular, más joins y comprobación cruzada | **Recomendada**, con FK y guardas verificadas, sin confiar sólo en código cliente |
| D. Mover misiones a tabla nueva y dejar una vista legada | Separación limpia del nuevo dominio | Mucho mayor riesgo en diez FK entrantes, PostgREST/Realtime, `%ROWTYPE`, triggers y wrappers | Descartada para este incremento |

Se mantiene `public.missions.id` como ancla; no se duplica ni renumera una misión. `author_id` conserva la atribución técnica original, futura FK RESTRICT a Person; no es el titular contractual. Se propone una tabla privada `collaboration.mission_ownership` con `mission_id` PK/FK RESTRICT a missions, exactamente uno de `owner_person_id` o `owner_organization_id`, FK RESTRICT a sus entidades, versión entera, evidencia de clasificación y timestamps servidor. Autor y propietario pueden coincidir, pero no son conceptos intercambiables.

**Dependencia explícita ORG-0:** `collaboration.organizations` y membresías/roles vigentes todavía no existen. La variante completa de mission_ownership no puede compilarse con una FK a una tabla inexistente. No se admite UUID organizacional sin FK, tabla ficticia ni organización fabricada. ORG-0 es otro incremento de TASK-002, con autorización y pruebas propias. E2-A (sincronización/control del principal) puede implementarse independientemente; el hito de titularidad C requiere ORG-0 aprobado o un rediseño personal acotado aprobado expresamente. No se considera que la validación personal certifique la variante organizacional.

Los casos aún no clasificados viven en `collaboration.mission_migration_cases` como inventario interno, sin fila operativa de titularidad. `REVIEW_REQUIRED` es una marca de migración, **no un estado nuevo de Mission**. La operación de alta/clasificación crea ancla y titularidad en una misma transacción; una guarda diferida valida al commit la existencia de titular XOR para cada misión nueva o promovida. Borrar o editar la titularidad directamente queda denegado. La FK RESTRICT desde titularidad impide borrar accidentalmente el ancla; mientras exista la cascada vieja también impediría su borrado en cadena, por lo que no se habilita purga de cuentas durante esa convivencia.

## 3. Invariantes de E2

| ID | Invariante exigido antes de aceptar el hito dueño |
|---|---|
| E2-I01 | E1 histórico intacto. Ningún id de misión/candidatura/autor ni dato legado cambia durante expansión/clasificación/corte salvo cambios explícitos en manifiesto aprobado. |
| E2-I02 | A lo sumo un principal por Auth, PK Person inmutable para rutas de aplicación; desvinculación no crea ni reasigna identidad. Un Person no concede elegibilidad. |
| E2-I03 | Cada misión nueva/promovida tiene exactamente un titular comprobado; casos ambiguos no operan ni reciben dueño por inferencia. |
| E2-I04 | Permiso actual = sujeto autenticado válido + contexto + recurso + acción + estado; denegación por defecto. Ni creador, etiqueta Negocio, metadata ni UUID enviado confieren representación. |
| E2-I05 | Borrar perfil/credenciales no borra automáticamente misiones, candidaturas protegidas, versiones o medios de terceros. Recursos compartidos se preservan o restringen por derecho acreditado, no por prefijo. |
| E2-I06 | Un comienzo de eliminación bloquea obligaciones nuevas en la misma transacción que registra la solicitud; jobs retrasados no permiten nuevas aceptaciones. |
| E2-I07 | Ninguna selección/candidatura accepted histórica se transforma en firma, oferta o acuerdo. Ningún consumidor soportado recibe confirmación contractual falsa. |
| E2-I08 | Migración y operaciones idempotentes: misma clave/cuerpo repite resultado; clave con otro cuerpo rechaza. Reintento no religa principales desvinculados. |
| E2-I09 | No se cambia de contraparte contractual por editar titularidad; se exige proceso material/nuevo acuerdo según SRS. |
| E2-I10 | Rollback/restore nunca restaura selección unilateral, expone datos suprimidos ni elimina el principal E1 para forzar una FK antigua. |
| E2-I11 | Conservation de migración y supresión autorizada son escenarios distintos: el primero exige igualdad total; el segundo un delta mínimo exacto, con conservación del resto. |
| E2-I12 | Sin control de sesión/revocación/Storage y recuperación exigidos de TASK-003 no hay aceptación integral ni habilitación operativa dependiente. |

## 4. Altas futuras, sincronización y reparación

Alternativas: creación asíncrona por worker (riesgo de hueco), creación perezosa en cada operación (riesgo de fabricar/religar identidad desde rutas expuestas), o trigger transaccional Auth + reconciliador privado. Se recomienda **trigger AFTER INSERT en auth.users y reconciliador sólo administrativo**. El error del trigger revierte el alta; es un coste de disponibilidad deliberado, que debe probarse y aprobarse. No se reemplaza `handle_new_user` ni se relajan sus validaciones legales/registro actuales.

Contrato propuesto, interno y no RPC cliente: `collaboration.ensure_person_for_auth(auth_user_id uuid, source text) → person_id uuid`. Sólo admite un Auth efectivamente existente y no suprimido; sin nombre, correo, role o user_type del cliente como autoridad. El trigger toma NEW.id de la fila Auth, no un parámetro HTTP. Cada proveedor enlazado en auth.identities de un mismo auth.users no crea otro Person.

Se propone continuar el esquema de E1 `Person.id = Auth.id` **únicamente al crear una identidad técnica nueva**. El PK persiste al desvincular Auth; ningún permiso depende de esa igualdad y el resolver usa `persons.auth_user_id`, control de ciclo de vida y Auth vigente. Alternativa: UUID aleatorio para altas futuras, con proyecciones adaptadas; rompe más supuestos del binario actual y necesita aprobación diferente. La opción elegida es D01 pendiente. No se permite recrear automáticamente una relación auth_user_id NULL ni reusar un UUID suprimido: una colisión genera `PRINCIPAL_MAPPING_CONFLICT` y revisión; no un ON CONFLICT que oculte el problema.

El reconciliador `collaboration.reconcile_persons(batch_id uuid, manifest_hash text, dry_run boolean) → summary` requiere manifiesto privado inmutable, límites de lote y permisos de operador. Dry-run detecta: Auth sin Person; duplicidad/conflicto; principal desvinculado; perfil/autor sin Auth; importación incompleta; cuentas con eliminación/supresión. Sólo el primer caso inequívoco y autorizado admite INSERT técnico. No crea perfiles ni organizaciones ni cambia roles, autorías o titularidades; no recupera eliminados desde backups. Casos ambiguos se exportan minimizados para resolución.

Se añaden controles privados por Person, sin FK destructiva a Auth: bloqueo de obligaciones, versión de control, solicitud de eliminación y motivo/timestamps mínimos. Su tabla no expone un nuevo estado canónico del dominio: describe etapas internas del procedimiento. Un estado inconsistente o ausente donde sea obligatorio produce denegación hasta reparación, nunca alta silenciosa desde un RPC de negocio.

Privilegios propuestos: funciones internas con search_path vacío, nombres cualificados, sin SQL dinámico; rol NOLOGIN dedicado sin membresía de anon/authenticated, sólo permisos y policies internas indispensables para insertar/consultar el principal. Ni USAGE de collaboration ni acceso directo a persons para clientes. Evitar dar BYPASSRLS, grants globales o ownership general al worker; si una limitación del Auth instalado obliga otro owner, se eleva el cambio concreto para revisión, no se recurre automáticamente a supabase_admin. Auditar orden real de triggers junto con on_auth_user_created, alta fallida y paths de importación administrativa.

## 5. Eliminación, minimización y protección de asociados

### 5.1. Frontera entre solicitud y purga

`delete-account` actual llama request_account_deletion, borra medios por prefijo y después auth.admin.deleteUser; Flutter interpreta cualquier 2xx como cuenta eliminada. No se puede convertir ese endpoint en 202 asíncrono sin resolver su consumidor. Se propone un **contrato v2 de solicitud y consulta de progreso**, con operation_id y etapas verificables; el endpoint legado sólo puede responder 204 cuando efectivamente terminó su contrato compatible. Para casos incompatibles debe fallar con actualización requerida **sin limpiar medios ni falsear un éxito** y mantener una vía soportada para solicitar eliminación. No se bloquea el derecho a presentar solicitud por existir compromisos; sus etapas/retenciones se explican de manera precisa.

La reautenticación reciente y la validación de sesión son contratos de TASK-003. El actual getUser no demuestra por sí solo ese requisito. En laboratorio se podrán ensayar estados de borrado sintéticos; ninguna ruta operativa sensible se habilita sin integración real de esa dependencia y cliente soportado. No se introduce aquí un arreglo global de revocación.

### 5.2. Puerta S0 previa y protocolo propuesto

**Antes de activar parcialmente las guardas/referencias E2 debe cerrarse la ventana destructiva legada.** Pausar/redirigir ingreso a delete-account y limpieza, mantener una vía que reciba solicitudes sin prometer purga, y drenar o invalidar ejecuciones/reintentos ya iniciados. El endpoint actual borra archivos antes de Auth: una guarda BEFORE DELETE Auth puede llegar demasiado tarde. La versión Storage instalada debe demostrar el orden real de sus operaciones; un trigger sobre metadatos no se presupone capaz de cancelar borrado físico ya iniciado. S0 exige conservación de bytes/referencias ante una ejecución anterior a la barrera (T49), quiescencia comprobada y backup revalidado. Si no puede demostrarse, no continuar a B/C/D/M ni al corte. A, que sólo sincroniza principales, no habilita esa transición.

1. Registrar idempotentemente una solicitud durable asociada a Person, sin cascada Auth. Bloquear nuevas obligaciones/publicación/edición sensible del titular en la misma transacción. Capturar manifest de recursos/versión, sin copiar PII indiscriminada. La eliminación de un miembro no bloquea por sí misma a toda organización: revoca su representación; si queda sin propietario se aplica UNOWNED_RESTRICTED.
2. Ocultar de descubrimiento misiones personales afectadas, bloquear nuevas candidaturas y contratos; preservar historial/contrapartes según SRS 3.10. Respetar estados terminales; no reabrir ni transformar completed en cancelled para facilitar limpieza. Emisión/aceptación deberán consultar el bloqueo aunque la conciliación aún no haya terminado.
3. Cancelar ofertas personales PENDIENTE y liberar reservas/preliminares atómicamente por unidad transaccional. Mientras falte el motor contractual o falten reglas de un recurso, el plan no puede declarar completa esa etapa ni autorizar una purga destructiva. Los accepted legados se conservan como evidencia histórica restringida/revisión, no como contratos válidos inferidos ni borrado automático de compromisos posibles.
4. Para acuerdos activos/en ejecución/disputa: expediente mínimo restringido, cierre supervisado, acceso sólo de contraparte/caso autorizado. No exige mantener perfil público ni credenciales del solicitante; la purga de Auth puede ocurrir tras asegurar el expediente y los controles, sin esperar el cierre final del acuerdo. Nadie firma por la persona eliminada.
5. Resolver membresías, autoría, candidaturas, medios y notificaciones mediante manifiesto por recurso. Borrar/anular proyecciones personales donde corresponda; conservar recursos de organización independientemente del perfil del creador. No transferirlos automáticamente a otro humano ni a una organización ficticia.
6. Persistir plan y supresiones minimizadas; worker de Storage aplica sólo operaciones permitidas y verifica resultados reales. Fallos/reintentos dejan solicitud en curso, sin 204 ni promesa de eliminación remota no confirmada. No mantener transacciones/locks DB abiertos durante llamadas HTTP.
7. Guarda BEFORE DELETE Auth/perfil verifica **postcondiciones y versión del plan**, no sólo que exista una función o un marcador. El borrado directo por API administrativa también debe pasar la protección DB. Si no está listo, deniega la purga física y conserva la solicitud recibida. Reautenticación, supresión de secretos y cierre de sesiones requieren TASK-003. Usuarios cliente nunca pueden alterar el plan para habilitar borrados.
8. Al desligar Auth queda el Person mínimo sólo mientras exista finalidad/retención aprobada; retirar atributos no necesarios, restringir accesos, auditar expiración y eventual purga. El operador necesita poder explicar etapa/bloqueo al solicitante sin exponer datos de terceros.

No hay una transacción distribuida DB–Auth–Storage. Se usa una saga con estados durables, outbox y reintentos idempotentes, comprobando primero condiciones DB y después cada operación externa. El punto de no retorno incluye pérdida física de un objeto, supresión de PII o eliminación Auth; desde él no se promete rollback SQL integral.

### 5.3. Matriz mínima de datos, sin plazos inventados

| Categoría | Tratamiento propuesto | Decisión/condición previa |
|---|---|---|
| Credenciales, correo, tokens, perfil público, vínculos externos | Eliminar o desvincular por procedimiento; despublicación temprana | Reautenticación/revocación TASK-003; matriz de datos/operador |
| Person.id y enlaces de autoría necesarios | Expediente privado mínimo mientras haya finalidad justificada; auth_user_id NULL | D02: fundamento, plazo, expiración, accesos y responsable; no retención perpetua implícita |
| Candidaturas, condiciones conocidas y recibos | Conservar ID/relación y evidencia mínima requerida; restringir mensaje/adjuntos personales | D03: protección de contraparte/caso frente a minimización; delta permitido por categoría |
| Identidad/medios del solicitante en recurso organizacional | Desvincular proyección personal; continuar sólo usos con derecho acreditado | D04: autoría/consentimiento/uso y qué se despublica si faltan derechos |
| Comentarios/reacciones/guardados/avisos | Clasificar como personales/transitorios o evidencia relevante; nunca retener todo por defecto | D02/D03, inventario de 36 FK, reglas de notificación |
| Auditoría, supresiones y manifiestos | Identificadores minimizados, cifrado/acceso restringido, retención propia | TASK-003 recuperación/supresión durable; política aprobada |
| Backups y caches | Destrucción/expiración controlada y supresión antes de reexposición; cliente nuevo invalida caches | No prometer purgar dispositivos offline o copias de terceros inalcanzables |

El UUID E1 coincide con el antiguo UUID Auth. Conservarlo, su hash simple, timestamps y relaciones puede permitir correlación: es **seudonimización**, no anonimización irreversible. Anonimizar exige evaluar textos, imágenes, documentos y vínculos indirectos; un nombre «Cuenta eliminada» o auth_user_id NULL no basta. No se afirma cumplimiento jurídico ni se fija aquí un número de días no aprobado. Esta política no autoriza mantener PII hasta que «termine TASK-002» sin causa/plazo.

### 5.4. Candidaturas y otros hijos

Para las candidaturas se recomienda conservar id y applicant_id técnico, añadir/validar una FK a Person RESTRICT y retirar la FK al perfil sólo en su corte explícito, adaptando antes RLS, notificaciones, recibos y joins. `mission_application_operations` tiene dependencia equivalente y conserva sólo el recibo mínimo autorizado. Es una ampliación respecto al mero author_id y necesita autorización separada D03/E2-D; no se ejecuta de manera implícita.

Comentarios, reacciones, guardados, borradores y avisos no cambian todos a RESTRICT por comodidad. El manifiesto de disposición debe resolver cada FK: conservar vínculo mínimo, pasar actor opcional a NULL cuando el contrato lo permita o borrar dato estrictamente personal según política. Casos asignados/reportes no se pierden por borrar al reportante; retención de evidencia exige fundamento. APIs que escriben notifications con UUID de una persona sin perfil deben resolver un destinatario Auth vigente y un actor público admisible, o registrar sólo evento mínimo; no fallar ni inventar perfil sustitutivo. Ninguna de estas modificaciones se implementó aquí.

## 6. Medios: pertenencia y uso por recurso

Se recomienda conservar inicialmente cada bucket/key y digest existente, con un registro privado de assets y vínculos a recurso, independiente del uploader. Alternativa: copiar a prefijos de organización/recurso; exige verificación adicional y no es atómica con DB. El prefijo actual identifica procedencia técnica, **no propietario ni derecho de eliminación**. Ownership de storage.objects tampoco prueba autorización de uso.

Registro propuesto: asset_id, bucket/key únicos, object_id/versión disponible, hash, uploader_person_id restringido/minimizado y control de operación; bindings con FK real a misión/borrador/expediente (tablas de vínculo por tipo o columnas FK con XOR, nunca un resource_id polimórfico sin integridad). Derechos/UsagePermission separados: propósito, titular/consentimiento acreditados y alcance de retiro. Compartir asset entre dos recursos exige comprobar ambos vínculos; borrar una cuenta no elimina el asset usado por el otro. Si el uso organizacional no está acreditado se restringe/despublica hasta decisión; no se adquieren derechos por clasificar la misión.

Las guardas para subida, asociación, copia y borrado incluyen todos los roles, especialmente service_role sin auth.uid. Una eliminación se habilita sólo para objeto/versión/manifiesto esperado sin bindings protegidos y con trabajo vigente. Un GUC/job_id enviado por cliente no acredita autorización: además se exige identidad de worker y claim privado no accesible a roles de app. Bloquear reutilización de keys retiradas y upsert incompatible; una carrera que reasigne o cambie el objeto invalida el plan. La guarda de uso evita que el borrado por prefijo siga activo durante la transición.

Las operaciones físicas se hacen por **Storage API**, no DELETE SQL de storage.objects (que sólo eliminaría metadatos). La API puede fallar a mitad: leases cortas persistidas, reintento por objeto, verificación de ausencia/conservación y reconciliación de DB/archivos. Un medio ya borrado requiere recuperación controlada; nunca se restaurará uno suprimido a su URL pública. URL firmada y caché pueden sobrevivir a cambios de RLS: invalidación/TTL y pruebas posteriores a revocación pertenecen a TASK-003; no se certifica esa protección por esta propuesta.

**Puerta adicional antes de purgar Auth:** la documentación Supabase indica que un usuario propietario de objetos Storage puede impedir su eliminación. El catálogo congelado contiene `storage.objects.owner` UUID y `owner_id` text anulables, sin FK Auth en objects; la ausencia de FK no demuestra que la API Auth permita eliminarlo. Hay que inventariar ambos campos y buckets/propietarios y probar el comportamiento de las versiones fijadas. El registry nuevo no cambia esa propiedad técnica. Si un objeto conservado bloquea Auth, se requiere un procedimiento de reasignación soportado y verificado, o una copia por API bajo custodia técnica aprobada, con hash/derechos/bindings y compatibilidad comprobados antes de retirar el original. No se inventa una API de cambio de owner ni se modifica metadata a mano para saltar la restricción. La copia puede cambiar keys/object_id/URLs y requiere D04 y delta explícito; no se promete conservar simultáneamente todas las rutas y purgar Auth sin comprobarlo. No transferir a otra persona arbitraria, fabricar una cuenta organizacional ni borrar el medio protegido para desbloquear la baja. Si no se ha aprobado/verificado la salida, se conserva la solicitud, se despublica lo exigido y se declara la purga pendiente; esa limitación debe resolverse antes de operación real, sin retención indefinida implícita.

## 7. Migración y corte de referencias

### 7.1. Expansión, clasificación y verificación

1. Generar una nueva copia aislada desde respaldo E1 verificado (o restaurar origen y reproducir E1 autorizado en copia nueva). Los volúmenes/evidencias E1 conservados no son el destino. Validar hashes, catálogo exacto, Auth/mapping, Storage, roles/grants y ausencia de conexiones remotas; ante drift/ambigüedad abortar, no desactivar controles.
2. Añadir controles del principal y sincronización. Añadir titularidad privada sólo después de ORG-0. Denegar acceso directo cliente; auditar owner/default ACL/RLS/funciones/triggers efectivos. Insertar casos de migración, no propietarios inferidos.
3. Clasificar con manifiesto por misión: id, hash/versión de origen, tipo de titular, evidencia, aprobador, derechos de medios y condición de migración. La relación Auth/perfil de E1 acredita principal, **no** propiedad personal inequívoca. Incluso los seis fixtures necesitan ground truth explícito para ensayar clasificación; no se generaliza a producción. Casos Negocio/organizacionales/disputados quedan REVIEW_REQUIRED sin organización automática.
4. Crear titularidad con comparación de versión bajo lock; reejecución idéntica no duplica y decisión distinta exige revisión. Nuevas misiones no admiten ausencia de titular. La guarda diferida comprueba el conjunto operativo al commit, incluidas altas directas privilegiadas ordinarias y borrado del sidecar.
5. Instalar rutas y políticas seguras en el laboratorio autorizado: autorización actual, proyecciones/compatibilidad, planes de borrado y medios; cerrar grants y wrappers de bypass. Verificar candidatos y todos los hijos antes de permitir borrar perfiles. Las rutas nuevas siguen deshabilitadas para uso real hasta completar dependencias.

### 7.2. Corte final, todavía no autorizable como script

La operación futura `missions_author_person_fkey` añade FK author_id→persons(id) RESTRICT **NOT VALID**, valida datos y sólo después retira `missions_author_id_fkey`. El cambio final se hará en una transacción corta, con preflight revalidado, lock_timeout/statement_timeout aprobados, bloqueos medidos y abortos seguros. No se alteran valores/default ni se cambian arbitrariamente nombres que rompan relaciones PostgREST. La referencia de candidatura tiene su propia operación equivalente y puerta. Sin el manifiesto de disposición de los restantes hijos, no se permite eliminación Auth/perfil aunque la FK de misión ya apunte a Person.

NOT VALID se usa en FK/CHECK compatibles, no en UNIQUE/PK; no evita locks ni deja de comprobar escrituras nuevas. Validar antes de retirar la referencia vieja. Para índices grandes, CREATE INDEX CONCURRENTLY sería una operación separada, fuera de la transacción de corte, con inspección de índice inválido tras fallo; no se promete «sin bloqueo» por usar esas cláusulas. En los fixtures pequeños se prefiere el camino transaccional sencillo; el volumen real requerirá otra evaluación.

No se propone ejecutar el SQL E anterior, recrear persons, usar DROP CASCADE, session_replication_role, deshabilitar triggers/RLS ni aceptar una función vacía prepare_principal_deletion como precondición. El script final deberá bindear esquema, firmas/cuerpos/ACL, triggers registrados y pruebas del plan real. **No se ha escrito ni compilado un ejecutable E2 en este expediente.**

### 7.3. Rollback y recuperación

| Momento | Recuperación permitida | Condición |
|---|---|---|
| Fallo dentro de un incremento DDL/DML transaccional | ROLLBACK del incremento, digest/catálogo/ACL comparados | Sin efectos externos en esa transacción; secuencias y artefactos fuera de transacción comprobados aparte |
| Expansión confirmada, aún sin escrituras nuevas | Deshabilitar capacidad; retirar sólo objetos nuevos si no tienen dependencias/datos válidos | Preservar E1, historial y manifiestos; revisión de rollback concreto |
| Corte confirmado, todos los autores/candidatos conservan perfiles y aún no se purgó nada | Posible reintroducir/validar FK antigua por script aprobado | Demostrar compatibilidad de todas las referencias, no sólo count=0 de huérfanos; nunca reabrir DELETE/selección unilateral |
| Ya hay perfiles eliminados, nuevos titulares/recibos o datos suprimidos | Mantener FK nueva y aplicar corrección hacia adelante; bloquear escrituras afectadas | No fabricar perfiles, reasignar autores ni borrar principals para hacer encajar el legado |
| Fallo de Storage/Auth o restore completo | Reanudar saga o restaurar a copia nueva aislada y reconciliar | Ledger de supresión posterior al backup, derechos, hashes, permisos y evidencia del punto recuperado |

Ledger de supresión no puede depender sólo del backup DB que se está restaurando ni de una fila Auth con cascada. El diseño durable, claves, acceso y retención son interfaz de TASK-003: fuente independiente/actualizada y verificación de integridad, sin prescribir aquí proveedor remoto. Si no está disponible o no coincide su checkpoint, la restauración permanece aislada y no se publica. Restaurar no equivale a deshacer supresiones legítimas.

## 8. Compatibilidad: servidor, Flutter, clientes antiguos y eventos

Contratos propuestos `list_missions_v2`, `mission_detail_v2`, `list_mission_applications_v2`, `request_account_deletion_v2` y consulta de progreso son **nombres de diseño**, no RPC implementados. Los DTO llevan contract_version y capacidades servidor por recurso/acción; no incluyen catálogo privado Person, listas de miembros o PII de bajas. Las mutaciones revalidan permisos; una capacidad cacheada no es autorización.

| Superficie actual | Compatibilidad que se conserva | Cambio futuro necesario / condición |
|---|---|---|
| create/update/list_missions y wrappers legacy→compensation→city | UUID, campos maduros, ciudad, compensación, validaciones y borradores | Puente personal sólo si puede derivar contexto personal inequívoco; cambios materiales/contexto no representable → UPDATE_REQUIRED |
| Mission.authorId y guard de pantalla de gestión | Autoría histórica y links existentes | Usar can_manage/contexto de servidor para facultad; no inferirlo del creador. Identidad visual y cinco destinos AppShell intactos |
| SELECT directo mission_applications/finalists/drafts | Recursos seguros representables y permisos actuales | DTO/fachada v2; cerrar acceso bruto incompatible. Cabecera de versión no es frontera de seguridad |
| review_application y confirm_mission_selection | Firma de entrada puede mantenerse para error compatible | Selección/confirmación unilateral → UPDATE_REQUIRED sin mutación; jamás convertir llamada antigua en oferta o firma |
| accepted_count, etiquetas Aceptada, avisos mission_accepted | Historial se conserva sin alterar filas | No exponer confirmación sin Agreement ACTIVO y firmas. accepted histórico va a revisión restringida v2; no inventar accepted_count=0 como si no existiera compromiso |
| Feed/mapa/guardados/social/notificaciones/push | IDs, orden/paginación y deep links seguros | Resolver titular sin perfil fundador; auditar fanout, textos y snapshot de feed, no sólo listado de misiones |
| Storage firmado y Realtime | Canales/URLs sólo con autorización suficiente | Revocación efectiva depende TASK-003; payloads sin PII ajena, sin confiar en conexión previa |
| Borrado de cuenta actual: cualquier 2xx implica final | 204 sólo para eliminación compatible realmente completada | Cliente v2 distingue solicitud/en curso/completada; 202 nunca al consumidor legado que lo interpreta como purga |

RLS no oculta columnas nuevas por sí sola ni agrega un error estructurado de actualización a una tabla. Una policy PERMISSIVE adicional puede abrir acceso por OR; no se deja la policy de autor y otra de titular esperando que la segunda restrinja a la primera. Se revisa el conjunto efectivo de grants, policies, views y SECURITY DEFINER. Las fachadas booleanas/DTO que requieren leer el esquema privado usan un owner mínimo y autorización de sujeto; no conceden USAGE/SELECT de collaboration a anon/authenticated. Soporte sólo accede por caso asignado, no por un rol admin genérico enviado por cliente.

Para las tablas contractuales directas y avisos incompatibles, la propuesta es retirar su acceso bruto cuando esté disponible la fachada y el cliente soportado. Un cliente antiguo obtiene denegación segura/actualización requerida por la superficie que pueda emitirla; no se le entrega un estado falso, ni se asegura que su binario antiguo ya muestre un mensaje nuevo. Mantener funciones firma antigua como rechazo seguro evita bypass. PostgREST puede revelar relaciones por nombre de FK: añadir una segunda referencia durante expansión exige pruebas de embeds, overloads, cache de esquema y peticiones grabadas; no se certifica sólo por mantener nombres JSON.

La ambigüedad ya documentada sobre postulación de personas vinculadas a organizaciones permanece D10: una membresía o control compartido no se convierte por inferencia en permiso ni en prohibición general nueva. El caso no se habilita hasta regla aprobada y validación servidor; se conserva U0 sin modificar el SRS.

No existe aún motor Agreement, por lo que E2 no puede producir una proyección contractual confirmada. Las rutas de contrato nuevo permanecen cerradas hasta los hitos de ofertas/reservas/acuerdos y su cliente. El corte operativo no puede ejecutarse mientras el único cliente disponible dibuje accepted como compromiso y no tenga ruta de actualización/solicitud de baja soportada. Las pruebas con binario real, cache local antigua, deep link, sesión recuperada y offline son puertas explícitas; no se reemplazan por capturas U0 ni JSON sintético.

## 9. Concurrencia y fallos

Orden propuesto para los caminos que bloquean Auth: fila Auth (KEY SHARE/DELETE) → locks personales ordenados → control Person → organizaciones ordenadas → misiones por UUID → candidaturas/ofertas/reservas → assets/recibos. Un camino que empieza por locks Person no debe después adquirir un row-lock Auth: validar existencia mediante lectura sin lock y estado de control, o reorganizar el entrypoint. El DELETE Auth obtiene su row-lock antes de su trigger; ignorar ese detalle crea un deadlock contra reparación.

Los locks advisory existentes usan hashtextextended(UUID Auth,0); las rutas nuevas deben interoperar con ese espacio mientras subsistan, no introducir un lock paralelo que no proteja a los workers legados. Para acciones multipartes se toman todos los locks necesarios en orden antes de llamar helpers legacy que ya bloquean al actor. No se toma un segundo lock personal fuera de orden. Una solicitud de eliminación puede cerrar por lotes de misión ordenados mientras el bloqueo personal impide acuerdos nuevos. Estos órdenes son propuestas a comprobar con pg_locks y fault injection, no una demostración ejecutada.

La reparación y el borrado compiten bajo referencia Auth y control durable: o se crea exactamente un principal de cuenta vigente o se observa borrado/supresión y no se religa. La asignación concurrente de titular se resuelve por PK mission_id, versión esperada y decisión/hash idénticos; dos clasificaciones distintas rechazan. Asociar medio/eliminarlo comparten claim y binding transaccional, sin mantener locks durante red. Reintentos de serialization_failure/deadlock_detected tienen límite y jitter servidor; respuesta incierta exige consultar operación persistida, nunca confirmación UI por timeout.

## 10. Dependencias TASK-002 / TASK-003 y aceptación

| Responsabilidad TASK-002/E2 | Dependencia TASK-003 que no se implementa aquí |
|---|---|
| Principal, autoría/titularidad, bloqueo por recurso/solicitud, disposición de datos, control de medios, idempotencia | Identidad/sesión actual, reautenticación reciente y revocación de credenciales |
| RLS/RPC comprueban titular/contexto/estado actual; borrado no concede nuevas facultades | JWT previo al logout y socket ya conectado dejan de leer; URLs privadas posteriores a revocación |
| Plan minimizado de supresión y requisitos de restauración/reconciliación | Ledger durable, reaplicación antes de exposición y controles de sesiones/secretos al recuperar |
| Cancelación/liberación por eliminación y preservación de evidencia | No se corrigen los dos FAIL históricos HTTP/Realtime de TASK-001 dentro de E2 |

La interfaz de integración debe aportar evidencia verificable, no un booleano mock como aceptación final. Puede haber PASS estructural local con fixtures explícitamente sintéticos; no PASS integral de seguridad o de TASK-002 mientras falten dependencias, organizaciones, bilateralidad, clientes y QA. No se marca RF/TC completamente validado con este documento.

## Referencias técnicas contrastadas

- [PostgreSQL 17: ALTER TABLE](https://www.postgresql.org/docs/17/sql-altertable.html): NOT VALID/VALIDATE y locks; el corte y los índices concurrentes necesitan límites transaccionales distintos.
- [Supabase: datos de usuario](https://supabase.com/docs/guides/auth/managing-user-data): un trigger de alta puede impedir el registro al fallar; la eliminación Auth y objetos Storage requiere tratamiento explícito.
- [Supabase: propiedad Storage](https://supabase.com/docs/guides/storage/security/ownership): la propiedad técnica no concede por sí sola acceso.
- [Supabase: esquema Storage](https://supabase.com/docs/guides/storage/schema/design): tratarlo como metadatos y operar archivos mediante la API.
- [Supabase: seguridad de API](https://supabase.com/docs/guides/api/securing-your-api): grants y RLS son capas distintas. El SRS del repositorio sigue siendo la fuente normativa; estas referencias describen mecanismos, no autorizaciones.
