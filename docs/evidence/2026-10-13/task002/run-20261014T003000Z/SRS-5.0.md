---
id: MAREA-SRS-5.0
version: 5.0.0
fecha: 2026-10-12
idioma: es-MX
titulo: MAREA — Especificación maestra de requisitos funcionales y técnicos
estado: BASELINE_DE_DISENO_LISTA_PARA_IMPLEMENTACION
alcance: producto-definitivo-con-entrega-por-fases
plataformas: [web, android, ios]
stack_referencia: [flutter, dart, supabase_auth, postgresql, storage, edge_functions]
modulos: 26
requisitos_funcionales: 313
controles_transversales: 69
reglas_negocio: 25
criterios_aceptacion_heredados: 26
contratos_arquitectura: 38
repositorio_auditado: false
aprobacion_legal: false
aprobacion_operativa: false
aprobacion_tiendas: false
validacion_mercado: false
---

# MAREA — Especificación maestra de requisitos v5.0

**Documento normativo único para producto, ingeniería, diseño, QA y agentes de IA.** Fecha: 12 de octubre de 2026. Reemplaza como guía principal a v4.0, v4.1 y v4.2 sin volver normativas sus secciones históricas.

> **Estado correcto:** el alcance y las reglas de diseño se consideran definidos para iniciar tareas acotadas. NO se afirma que el software esté implementado, sea jurídicamente conforme, esté aprobado por tiendas, tenga moderación operativa ni haya validado el negocio. La autorización de release depende de las puertas y evidencias de la sección 11.

## 0. Cómo leer y ejecutar esta especificación

- **Jerarquía:** la ley/políticas vigentes prevalecen sobre el texto; dentro de esta versión, los contratos normativos de secciones 3, 4 y 8 precisan los requisitos de secciones 5–7. Ante incompatibilidad real, detener la implementación y abrir un registro `DECISION-XXX` en vez de suponer.
- **Lenguaje:** `DEBE` = obligatorio cuando la función esté habilitada; `NO DEBE` = prohibición; `PUEDE` = permitido; `CONDICIONAL` = propuesta deshabilitada hasta aprobación; `PENDIENTE EXTERNO` = falta evidencia no obtenible mediante documentación.
- **Estado de implementación:** `NO_VERIFICADO`, `NO_IMPLEMENTADO`, `PARCIAL`, `IMPLEMENTADO_SIN_PRUEBAS`, `VALIDADO`. Ningún requisito pasa a `VALIDADO` sin ruta de código y evidencia de prueba.
- **Convención de alcance:** `BASE` (MVP y cimientos), `PILOTO` (núcleo de oportunidades), `POST` (expansión posterior a métricas), `CONDICIONAL` (hipótesis sin compromiso). Se implementa sólo lo solicitado en la tarea y sus dependencias obligatorias.
- **IDs estables:** `RF-NN-NNN`, `CT-...`, `RB-NN`, `AC-NN`, `ADR41-NN`, `ADR42-NN`; no renumerar. Los contratos adicionales `CTR5-NN` amplían la semántica; no sustituyen los IDs anteriores.
- **Fuente única:** este archivo. Los documentos previos son historia, no un segundo juego de órdenes. No usar las tablas de riesgos históricas con estado «abierto» como semántica de ejecución actual.
- **Regla de seguridad:** un prototipo visual, una respuesta exitosa del cliente o una prueba aislada NO demuestran autorización del servidor ni habilitan producción.

## 1. Producto, usuarios y límites

**Propuesta única:** conectar necesidades creativas locales con artistas, profesionales, emprendedores y espacios; facilitar postulaciones, acuerdos y coordinación; visibilizar actividades reales y resultados autorizados. Marca: *La ciudad se convierte en escenario*.

**Unidad principal:** la `Mission` declara una necesidad; `Application` propone participación; `AgreementOffer` reserva un cupo y solicita consentimiento; `Agreement` fija obligaciones aceptadas; `PublicActivity` anuncia una experiencia que puede ser futura; `Outcome` registra un resultado posterior y sus niveles de evidencia.

**Usuarios:** visitante (lectura pública), persona registrada, creador (capacidad de persona), miembro o propietario de organización, y personal interno por función (soporte, moderación, operación técnica). Un mismo humano puede tener varias capacidades sin crear identidades de autenticación distintas.

**Prohibiciones de alcance inicial:** no intermediación de pagos, escrow, garantía de contratación o seguridad física, chat abierto sin contexto, reputación convertida en «verificación externa» sin revisión, eventos ficticios, AR obligatoria, explotación de datos personales ni SEO sobre recursos privados.

### 1.1. Distribución por fases

| Fase | Se puede activar | Condición de entrada |
|---|---|---|
| `BASE` | Acceso, perfiles y permisos mínimos, configuración, eliminación, infraestructura y canales de reporte ligados a las funciones realmente expuestas | Autorización RLS y recuperación de cuenta probadas; textos obligatorios y protección de datos revisados para el uso habilitado |
| `PILOTO` | Oportunidades → propuestas → ofertas → acuerdos → actividad/resultado, perfiles, descubrimiento, mapa 2D, coordinación y moderación operativa | Puertas `G0–G4` y `B01–B04/B06/B08/B09` según alcance |
| `POST` | Herramientas premium, publicaciones comunitarias amplias, suscripciones y capacidades comerciales | Uso recurrente, disposición de pago, políticas de compra y compliance aprobados |
| `CONDICIONAL` | AR espacial/avanzada, trueque extensivo, tripulaciones, drops, gamificación, IA y marketplace transaccional | Experimento propio, seguridad, presupuesto y aprobación expresa |

**Nota:** AR exigida académicamente puede ejecutarse en entorno de demostración separado (`academic_ar_demo=true`), pero no autoriza su release comercial.

### 1.2. No-promesas obligatorias

- «Cuenta con 18 años o más» es autodeclaración, NO identidad/edad verificada.
- «Confirmado por ambas partes» NO equivale a certificado independiente, pago recibido ni garantía de satisfacción.
- «Actividad programada» NO equivale a evento realizado; «foto subida» NO equivale a resultado de una misión.
- MAREA documenta compensación entre terceros durante el piloto, pero NO gestiona, valida ni garantiza transferencias de dinero.
- La disponibilidad de funciones está limitada a ciudades, categorías, versiones de app y horarios de soporte aprobados y mostrados con veracidad.

## 2. Modelo de dominio, propiedad y datos

| Entidad | Propiedad, relaciones y semántica obligatorias |
|---|---|
| `Person` | Identidad humana autenticada; autenticación privada y preferencias; eliminación independiente de organizaciones |
| `CreatorProfile` | Proyección pública opcional de Person; portafolios y capacidades, sin credenciales separadas |
| `Organization` | Recurso autónomo; propietarios, miembros y estados de propiedad/operación |
| `Membership` | Vínculo Person–Organization con rol, vigencia, alcances y revocación |
| `Venue` | Sede administrada o autorizada; dirección pública solo con derecho suficiente a publicarla |
| `Mission` / `MissionRevision` | Convocatoria y snapshots inmutables del contenido aceptado por postulantes |
| `Application` | Una candidatura por identidad actuante y misión, con historial y estatus; no es acuerdo |
| `AgreementOffer` / `CapacityReservation` | Oferta temporal con vencimiento y reserva de cupo transaccional |
| `Agreement` / `AgreementRevision` / `Acceptance` | Compromiso bilateral, con versión y aceptación explícita por actor autorizado |
| `PublicActivity` | Publicación de evento/actividad con origen (`MAREA_COLLABORATION` o `EXTERNAL_EDITORIAL`) y vigencia |
| `Outcome` / `OutcomeEvidence` | Afirmación de resultado con evidencia y nivel de comprobación |
| `Conversation` / `Message` | Conversación de misión/acuerdo, acceso autorizado y adjuntos privados |
| `MediaAsset` / `UsagePermission` | Medio con titular, autorización, contexto de uso y retiro por ámbito |
| `Report` / `ModerationCase` | Denuncia, evidencia privada, medida preventiva, resolución y apelación separadas |
| `Notification` / `DomainEvent` / `OutboxEvent` | Avisos, eventos versionados y procesamiento seguro ante reintentos |
| `AuditEvent` / `DeletionRequest` / `SuppressionRecord` | Registro restringido de cambios privilegiados y borrados pendientes/efectuados |

### 2.1. Invariantes no negociables

1. Un recurso tiene `owner_person_id` **o** `owner_organization_id` según su tipo, nunca queda editable por un actor arbitrario a partir de parámetros del cliente.
2. Cada acción servidor deriva `actor_id` de una credencial validada; la membresía vigente y el estado operativo de la organización deben permitir explícitamente la acción.
3. Toda oferta tiene `reservation_id` y `expires_at` definidos por el servidor; para una misión: `acuerdos_confirmados + reservas_pendientes_vigentes ≤ cupos_totales` dentro de una misma transacción.
4. Una `AgreementOffer` aceptada ya no consume reserva temporal: la convierte atómicamente en cupo confirmado; ofertas caducadas/liberadas no pueden activarse.
5. Cada aceptación referencia hash/ID de **versión inmutable** de términos; cambios materiales crean nueva versión que requiere nuevas aceptaciones.
6. La cadena temporal de eventos es de servidor, persistida en UTC; la zona IANA de la sede determina la hora local mostrada. Límites de postulación: `[inicio, cierre)`.
7. Sólo el resultado `CONFIRMADO_BILATERAL` puede indicarse como confirmado por partes; el nivel `REVISADO_INDEPENDIENTEMENTE` exige evidencia/revisión adicionales; no se obtiene automáticamente por número de «me gusta».
8. Una revocación de acceso se hace efectiva en lecturas posteriores aunque un socket siga conectado: el canal no transporta contenido privado después de revocación.
9. El borrado de cuenta no transfiere automáticamente organización, no reactiva archivos tras restauración y no impide ejercer la solicitud de eliminación.
10. El usuario nunca visualiza como «guardado» un cambio de estado crítico hasta recibir confirmación autenticada del backend.
11. Sin personal de moderación responsable y suplente, no se habilitan interacciones públicas de riesgo ni se publicita atención humana continua.
12. Un recurso público retirado no vuelve a publicarse por caché propia, links o backups; las caches de terceros se gestionan por los mecanismos disponibles, sin garantía de purga inmediata.

## 3. Contratos de ejecución: estados, cupos, tiempo y permisos

En esta sección se cierran decisiones que antes quedaban implícitas. Las enumeraciones son **valores de dominio**, no etiquetas UI. La traducción visual nunca modifica el valor persistido.

### 3.1. Máquinas de estado únicas

| Entidad | Estados válidos | Transiciones válidas / terminalidad |
|---|---|---|
| `Mission` | `BORRADOR`, `EN_REVISION`, `PUBLICADA`, `PAUSADA`, `CERRADA`, `EXPIRADA`, `CANCELADA`, `ARCHIVADA` | `BORRADOR→EN_REVISION/PUBLICADA` (según política); `EN_REVISION→PUBLICADA/BORRADOR`; `PUBLICADA→PAUSADA/CERRADA/EXPIRADA/CANCELADA`; `PAUSADA→PUBLICADA/CERRADA/CANCELADA/EXPIRADA`; `CERRADA/EXPIRADA/CANCELADA→ARCHIVADA`. Nunca revivir terminal: duplicar nueva misión. |
| `Application` | `ENVIADA`, `EN_REVISION`, `PRESELECCIONADA`, `OFERTA_DE_ACUERDO`, `NO_SELECCIONADA`, `RETIRADA`, `CADUCADA` | `ENVIADA→EN_REVISION/RETIRADA/CADUCADA/NO_SELECCIONADA`; `EN_REVISION→PRESELECCIONADA/NO_SELECCIONADA/RETIRADA/CADUCADA`; `PRESELECCIONADA→OFERTA_DE_ACUERDO/NO_SELECCIONADA/RETIRADA`; `OFERTA_DE_ACUERDO→NO_SELECCIONADA/RETIRADA` sólo cuando su oferta ya no sea vigente; éxito de contratación se consulta mediante el Agreement enlazado. |
| `AgreementOffer` | `PENDIENTE`, `ACEPTADA`, `RECHAZADA`, `EXPIRADA`, `CANCELADA` | Solo `PENDIENTE` puede avanzar a otro estado. Transición única atómica con liberar/confirmar reserva. |
| `Agreement` | `PROPUESTO`, `PENDIENTE_DE_ACEPTACIONES`, `ACTIVO`, `EJECUCION_DECLARADA`, `CONFIRMADO`, `EN_DISPUTA`, `SIN_RESOLUCION`, `CANCELADO` | `PROPUESTO→PENDIENTE_DE_ACEPTACIONES/CANCELADO`; `PENDIENTE_DE_ACEPTACIONES→ACTIVO/CANCELADO`; `ACTIVO→EJECUCION_DECLARADA/CANCELADO/EN_DISPUTA`; `EJECUCION_DECLARADA→CONFIRMADO/EN_DISPUTA/SIN_RESOLUCION`; `EN_DISPUTA→CONFIRMADO/SIN_RESOLUCION`. `CONFIRMADO` solo cuando Outcome cumple nivel bilateral. Finales no se reabren: expediente de disputa posterior independiente. |
| `PublicActivity` | `PROGRAMADA`, `REPROGRAMADA`, `SUSPENDIDA`, `REALIZADA`, `CANCELADA`, `ARCHIVADA` | `PROGRAMADA→REPROGRAMADA/SUSPENDIDA/REALIZADA/CANCELADA`; `REPROGRAMADA→PROGRAMADA/SUSPENDIDA/CANCELADA`; `SUSPENDIDA→PROGRAMADA/CANCELADA`; `REALIZADA/CANCELADA→ARCHIVADA`. Estado `HELD` está PROHIBIDO. |
| `Outcome` | `AUTODECLARADO`, `ESPERANDO_SEGUNDA_CONFIRMACION`, `CONFIRMADO_BILATERAL`, `DISPUTADO`, `SIN_RESPUESTA` | `AUTODECLARADO→ESPERANDO_SEGUNDA_CONFIRMACION`; esta pasa a `CONFIRMADO_BILATERAL` si hay consentimiento válido de contrapartes no idénticas, a `DISPUTADO` ante objeción, o a `SIN_RESPUESTA` por plazo; no convertir silencio en aceptación. |
| `Organization.ownership_status` | `ACTIVE`, `TRANSFER_PENDING`, `UNOWNED_RESTRICTED`, `CLOSING`, `CLOSED` | `ACTIVE→TRANSFER_PENDING/UNOWNED_RESTRICTED/CLOSING`; `TRANSFER_PENDING→ACTIVE/UNOWNED_RESTRICTED`; `UNOWNED_RESTRICTED→ACTIVE/CLOSING` solo tras procedimiento de reclamación aprobado; `CLOSING→CLOSED`. |
| `Organization.operational_status` | `NORMAL`, `PAUSED`, `SUSPENDED` | Independiente del ownership; `PAUSED/SUSPENDED` bloquean nuevas convocatorias/acuerdos. Solo operación autorizada puede levantar `SUSPENDED`. |

**Proyecciones derivadas (no estados nuevos):** `Application.aceptada` se presenta como «Acuerdo activo» si existe Agreement activo con ella; `Mission.SIN_CUPOS` significa que no queda capacidad disponible, aunque Mission siga PUBLICADA; el estado visible de oportunidad expirada no altera acuerdos vigentes.

### 3.2. Reglas exactas de selección y cupos

- Una oferta activa reserva **un cupo por persona seleccionada**; un grupo requiere tantas ofertas como plazas (no hay aprobación grupal implícita en el piloto).
- `offer_ttl = 72 horas` desde emisión, medido por servidor; el plazo de una misión nunca amplía una oferta vencida. Este valor es parámetro versionado en backend, no editable por cliente.
- Al caducar o rechazarse una oferta, liberar reserva de forma atómica; job de conciliación detecta y repara reservas vencidas sin depender de que el candidato abra la app.
- La creación concurrente de ofertas usa lock/constraint transaccional; crear dos ofertas para el último cupo debe producir exactamente una reserva válida.
- Cuando Mission pasa a `CERRADA`, no recibe postulaciones u ofertas nuevas; ofertas ya emitidas pueden terminar durante su vigencia (salvo cancelación explícita documentada). Si pasa a `CANCELADA`, las ofertas sin aceptar se cancelan y se notifican; acuerdos activos requieren resolución/cancelación separada.
- Ninguna postulación puede desembocar en acuerdo tras un cambio material de la misión sin aceptar expresamente la revisión actualizada.

### 3.3. Qué es un cambio material

Material: compensación, alcance/entregables, fecha u horario relevante, lugar, identidad del organizador responsable, condiciones de seguridad, cupos que afecten a participantes, política de uso de imagen u obligaciones exigibles. Cambios editoriales: ortografía, formato o etiquetas sin alterar expectativas. Si no se puede determinar con seguridad, tratar el cambio como **material**.

### 3.4. Matriz de actuación mínima obligatoria

| Acción | Visitante | Persona elegible | Miembro organizador autorizado | Propietario | Moderación / soporte |
|---|---|---|---|---|---|
| Leer recurso público autorizado | Sí | Sí | Sí | Sí | Sí, sin elevar acceso a datos privados |
| Crear misión personal | No | Sí, bajo políticas | Sí, si actúa como persona | Sí, si actúa como persona | No por defecto |
| Publicar/editar misión de organización | No | No | Sí, permiso `mission.manage` | Sí, si org `NORMAL` | No por defecto; puede suspender con auditoría |
| Postular | No | Sí, elegible y sin conflicto impeditivo | No como organización en PILOTO | Sí, actuando personalmente | No |
| Leer candidaturas | No | Sólo la propia | Sí, `application.review` para esa misión | Sí, dentro de su org | Solo caso asignado, justificado |
| Emitir oferta/crear reserva | No | No | Sí, `agreement.offer` | Sí, dentro de org habilitada | No |
| Aceptar acuerdo | No | Solo por sí misma | Sí, con representación explícita | Sí, como representante autorizado | No en nombre de terceros |
| Revisar/confirmar resultado | No | Solo parte propia | Parte con facultad específica | Parte legítima | Revisar evidencia sin firmar consentimiento ajeno |
| Transferir organización | No | Receptor con aceptación y elegibilidad | No sin propiedad | Propietario verificado y reautenticado | Nunca sin doble revisión y prueba documental |
| Ver denuncias o mensajes privados ajenos | No | Solo reporte/mensaje propio | No | No por ser propietario | Únicamente caso asignado, mínimo acceso y auditoría |
| Gestionar política/flags | No | No | No | No | Operación técnica autorizada, MFA y bitácora |

**Permisos de membresía:** `organization.view`, `venue.manage`, `mission.manage`, `application.review`, `agreement.offer`, `agreement.accept`, `event.manage`, `member.manage`, `billing.manage` (POST). Un rol visible no sustituye checks de permisos concretos. **Denegación por defecto** si el permiso no está presente o la organización está suspendida.

### 3.5. Sesiones, identificadores y tiempo

- Se usa UTC para instantes, IANA TZ de la sede para representación local y moneda `MXN` mientras el mercado sea México. Los días/horas visibles no alteran deadlines en servidor.
- Los UUID/IDs de recursos se tratan como localizadores, jamás autorizaciones. Endpoints y RLS aplican `actor_id`, pertenencia, visibilidad y políticas de borrado.
- `version` entero incrementa en cada cambio material, `updated_at` registra hora servidor, `idempotency_key` preserva unicidad lógica ante reintento y eventos de auditoría enlazan actor/versión/acción.
- Sesión revocada debe perder acceso a peticiones nuevas, canales privados y archivos; la autorización no depende solo de cierre de pantalla.

## 4. Comportamientos transversales ya decididos

### 4.1. Idioma, accesibilidad y preferencias

- Idioma **publicado en BASE y PILOTO**: `es-MX`, con textos de UI, correos, errores, avisos legales, notificaciones push, formularios y accesibilidad cubiertos; `en-US` queda preparado técnicamente pero **oculto/deshabilitado** hasta alcanzar cobertura y QA integral.
- Selector de idioma: `Sistema / Español (México)` mientras sólo es-MX esté aprobado; cuando inglés esté validado: `Sistema / Español (México) / English (United States)`; nunca ofrecer opción que no funcione.
- Preferencia efectiva: selección explícita almacenada en cuenta > selección local sin sesión > locale compatible de OS/navegador > `es-MX`. Preferencia explícita prevalece entre dispositivos autenticados; no traducir automáticamente contenido redactado por usuarios.
- Mensajes localizados por clave (`ARB`/`intl`), formato de zona/fecha/moneda por `intl`; claves faltantes fallan QA de release, no aparecen como identificadores al usuario.
- Soporte de lector de pantalla, escalado de texto, teclado, contraste y movimiento reducido se prueba en flujos habilitados según objetivo WCAG 2.2 AA y equivalentes móviles.

### 4.2. Offline, sincronización y errores

- Pantallas públicas pueden usar caché **con fecha de actualización** y estado «sin conexión»; las lecturas de recursos privados requieren una sesión válida y respeto a revocaciones y expiración.
- Borradores personales pueden editarse offline cifrados o protegidos según plataforma; se sincronizan con comparación de versión y resolución de conflicto **explícita** sin sobrescribir otro dispositivo silenciosamente.
- **Nunca encola offline** operaciones de aceptación contractual, pagos (no disponibles), transferencias, moderación, eliminación de cuenta ni publicación pública sin reconfirmación del servidor.
- La app diferencia `guardado localmente`, `pendiente de sincronizar` y `guardado en servidor`; reintentos con claves idempotentes, sin duplicación lógica.

### 4.3. Medios, ubicaciones y privacidad

- Los medios son privados hasta autorización expresa y pasan por validación de extensión/tipo real, límite de tamaño, metadatos, procesamiento seguro y revisión según categoría.
- Metadatos EXIF GPS se eliminan de versiones públicas; ubicación precisa personal no se expone en búsquedas; sedes y actividades usan localización autorizada y mecanismos de retiro.
- Contenido retirado desaparece de proyecciones públicas propias y URLs propias; no prometer desaparición inmediata de capturas o cachés ajenas.
- Se guarda consentimiento de difusión y créditos por archivo/obra/uso; una colaboración concluida no confiere licencia comercial automática para redes externas.

### 4.4. Moderación, reputación y perfiles vinculados

- Reporte, bloqueo, medida precautoria, revisión, resolución y apelación son registros separados. Los informes nunca son públicamente accesibles.
- El moderador **no hereda acceso total** a todas las conversaciones; recibe acceso temporal por caso, con auditoría y control reforzado en casos sensibles.
- Autoevaluación y colaboraciones bajo control compartido no suman a reputación independiente, aunque puedan registrarse como actividad con divulgación proporcional.
- Confirmación bilateral exige aceptación de partes distintas, no solo dos cuentas. `revisado independientemente` es etiqueta separada y auditable.

### 4.5. Web pública, Android, iOS y AR

- Sitio web público presenta fichas autorizadas accesibles sin login y páginas indexables mediante renderización HTML/SSR adecuada (no se presupone indexación completa de Flutter Web).
- Clientes web/Android/iOS consumen el **mismo contrato backend** de IDs, permisos y estados; el diseño responsive no habilita accesos adicionales.
- Permisos del SO se solicitan de forma contextual; hay alternativa manual para ubicación, alternativa lista/mapa cuando faltan sensores o compatibilidad AR y alternativa accesible para acciones basadas en cámara.
- En iOS el borrado se inicia en la app; en Google Play existe además una ruta externa web claramente accesible. Los datos personales asociados se eliminan con las excepciones legalmente justificadas y explicadas.
- La AR académica `academic_ar_demo` permanece aislada, sin datos de terceros ni afirmaciones de rastreo/precisión superiores al hardware real.

## 5. Catálogo funcional con identificadores estables

**Cobertura:** 26 módulos, exactamente **313 requisitos `RF`**. Cada requisito se interpreta conjuntamente con contratos de secciones 2–4, 8 y controles de sección 6. Las fases `POST/CONDICIONAL` se consideran **no activas**, incluso si el código experimental existe. La trazabilidad con los 52 módulos antiguos es **temática**, no demostración de equivalencia ID por ID.

### M01 — Cuenta, autenticación y elegibilidad

- **Etapa:** `BASE`. **Mapeo temático v3.1:** `F01 F36`.

- **RF-01-001** | `BASE` | Permitir explorar fichas públicas sin iniciar sesión, sin exponer datos privados.
- **RF-01-002** | `BASE` | Registrar una cuenta con correo y contraseña, verificación de dirección y consentimiento documentado.
- **RF-01-003** | `BASE` | Informar y solicitar confirmación de mayoría de edad (18+) antes de activar una cuenta; definir tratamiento de cuentas no elegibles.
- **RF-01-004** | `BASE` | Ofrecer inicio y cierre de sesión, expiración y revocación remota de sesiones activas.
- **RF-01-005** | `BASE` | Permitir recuperación segura mediante OTP o vínculo de uso único con expiración y limitación de intentos.
- **RF-01-006** | `BASE` | Exigir reautenticación para cambiar correo, contraseña, eliminar cuenta o transferir organización.
- **RF-01-007** | `BASE` | Impedir la enumeración de correos en registro, recuperación y cambio de cuenta.
- **RF-01-008** | `BASE` | Permitir MFA a usuarios cuando exista soporte y exigir MFA para administradores.
- **RF-01-009** | `BASE` | Notificar eventos sensibles de seguridad sin revelar secretos ni datos innecesarios.
- **RF-01-010** | `BASE` | Mostrar estados de acceso suspendido, verificación pendiente, sesión expirada y error temporal sin perder navegación.
- **RF-01-011** | `BASE` | Ofrecer eliminación de cuenta dentro de web, Android e iOS, así como el mecanismo web requerido por la tienda correspondiente.
- **RF-01-012** | `BASE` | Distinguir eliminación de cuenta de renuncia a una organización o eliminación de su contenido compartido.
- **RF-01-013** | `BASE` | Registrar versiones aceptadas de términos, aviso de privacidad y políticas relevantes.
- **RF-01-014** | `BASE` | Proteger flujos de invitación y verificación frente a reenvíos, reutilización y vínculos manipulados.

### M02 — Identidad, organizaciones, sedes y permisos

- **Etapa:** `BASE`. **Mapeo temático v3.1:** `F02 F05 F06 F13 F38`.

- **RF-02-001** | `BASE` | Mantener una única identidad personal por cuenta; creador es una capacidad de la persona, no otra cuenta obligatoria.
- **RF-02-002** | `BASE` | Permitir crear y representar organizaciones diferenciadas de la identidad personal del propietario.
- **RF-02-003** | `BASE` | Permitir que la misma persona pertenezca a varias organizaciones sin copiar ni fusionar sus cuentas.
- **RF-02-004** | `BASE` | Registrar membresías y roles: propietario, administrador, editor y miembro con permisos mínimos.
- **RF-02-005** | `BASE` | Resolver permisos por actor, recurso, acción y estado desde el servidor y no desde el rol enviado por el cliente.
- **RF-02-006** | `BASE` | Ofrecer selector explícito de identidad actuante antes de publicar, postular o emitir mensajes.
- **RF-02-007** | `BASE` | Indicar de forma visible en cada acción si se publica como persona o como organización.
- **RF-02-008** | `BASE` | Permitir que una organización mantenga varias sedes y distinga ubicación de sede de domicilio de una persona.
- **RF-02-009** | `BASE` | Permitir invitar, aceptar, rechazar y revocar membresías, registrando emisor, receptor, vigencia y contexto.
- **RF-02-010** | `BASE` | Impedir que la última persona propietaria abandone la organización sin transferencia aprobada o disolución controlada.
- **RF-02-011** | `BASE` | Permitir transferencia de titularidad con reautenticación, consentimiento de receptor y registro auditable.
- **RF-02-012** | `BASE` | Conservar recursos de una organización cuando uno de sus miembros elimina su cuenta, sujeto a privacidad y retención.
- **RF-02-013** | `BASE` | Restringir el acceso de exintegrantes inmediatamente en lecturas, escrituras, archivos y suscripciones en tiempo real.
- **RF-02-014** | `BASE` | Ofrecer proceso de cierre, suspensión o reclamación de organización y sede, con protección frente a suplantación.
- **RF-02-015** | `BASE` | Prevenir acciones cruzadas entre organizaciones mediante pruebas con usuarios titulares de varias entidades.

### M03 — Inicio, onboarding, configuración e idiomas

- **Etapa:** `BASE`. **Mapeo temático v3.1:** `F03 F42 F43 F44`.

- **RF-03-001** | `BASE` | Presentar bienvenida que explique una acción de valor: descubrir o publicar oportunidades, no un recorrido de red social genérica.
- **RF-03-002** | `BASE` | Permitir indicar ciudad o zona piloto manualmente sin exigir geolocalización del dispositivo.
- **RF-03-003** | `BASE` | Mostrar la ciudad activa y permitir cambiarla sólo entre zonas operativas declaradas, con estado honesto fuera de cobertura.
- **RF-03-004** | `BASE` | Solicitar intereses, habilidades y objetivos como datos opcionales, editables y no bloqueantes.
- **RF-03-005** | `BASE` | Permitir saltar tutoriales y retomarlos mediante ayuda contextual posterior.
- **RF-03-006** | `BASE` | Ofrecer idioma automático, español México y sólo idiomas adicionales que tengan traducciones completas.
- **RF-03-007** | `BASE` | Persistir y sincronizar idioma por cuenta, con reglas de precedencia explícitas frente a ajustes locales y del sistema.
- **RF-03-008** | `BASE` | Actualizar interfaz y mensajes al cambiar idioma sin eliminar el borrador activo.
- **RF-03-009** | `BASE` | Localizar errores, estados, correos de autenticación, avisos y notificaciones donde sea técnicamente viable.
- **RF-03-010** | `BASE` | Mostrar fechas, horas, moneda, números y pluralización con el formato regional; almacenar fechas en UTC e IANA donde corresponda.
- **RF-03-011** | `BASE` | No traducir automáticamente mensajes privados ni descripciones escritas por usuarios sin una función y consentimiento específicos.
- **RF-03-012** | `BASE` | Permitir modo claro/oscuro, tamaño dinámico de texto, preferencias de notificación y reducción de movimiento.
- **RF-03-013** | `BASE` | Mostrar los consentimientos separados según finalidad; permitir revocar permisos opcionales sin bloquear funciones independientes.
- **RF-03-014** | `BASE` | Incluir accesos directos a privacidad, sesiones, exportación, eliminación de cuenta, soporte y bloqueo de usuarios.

### M04 — Perfiles profesionales, habilidades y portafolios

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F03 F04 F05 F16 F46`.

- **RF-04-001** | `PILOTO` | Permitir a una persona publicar su nombre visible, biografía, disciplina, habilidades y ciudad sin mostrar domicilio personal.
- **RF-04-002** | `PILOTO` | Permitir a una organización publicar identidad comercial, sector, descripción, enlaces y medios de contacto controlados.
- **RF-04-003** | `PILOTO` | Ofrecer galería de obras/proyectos con descripción, fecha orientativa, fotos y enlaces permitidos.
- **RF-04-004** | `PILOTO` | Permitir indicar servicios o habilidades ofrecidos sin convertirlos automáticamente en productos comprables.
- **RF-04-005** | `PILOTO` | Permitir adjuntar muestras pertinentes a una postulación, con límites de tamaño, tipo y número.
- **RF-04-006** | `PILOTO` | Permitir distinguir contenido propio de colaboraciones y registrar créditos de otros participantes con su consentimiento.
- **RF-04-007** | `PILOTO` | Habilitar controles para ocultar, archivar, actualizar o denunciar portafolios y obras.
- **RF-04-008** | `PILOTO` | Verificar enlaces externos y ofrecer advertencia razonable antes de abrir sitios no administrados por MAREA.
- **RF-04-009** | `PILOTO` | Mostrar badges de verificación separados según el hecho comprobado, nunca como garantía de profesionalismo o seguridad.
- **RF-04-010** | `PILOTO` | Impedir que un perfil bloqueado obtenga información privada mediante enlaces compartidos.
- **RF-04-011** | `PILOTO` | Mostrar el perfil visto como tercero para comprobar qué información pública aparece.
- **RF-04-012** | `PILOTO` | Registrar la fecha de última actualización y pedir revisión de datos profesionales antiguos sin inventar actividad.

### M05 — Sedes, espacios y localización comercial

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F06 F09 F19 F49`.

- **RF-05-001** | `PILOTO` | Registrar una sede con nombre, dirección comercial, zona horaria IANA, mapa y datos de contacto autorizados.
- **RF-05-002** | `PILOTO` | Diferenciar sedes verificadas/reclamadas de lugares aportados por usuarios y de coordenadas aproximadas.
- **RF-05-003** | `PILOTO` | Permitir horarios, excepciones, accesibilidad y servicios relevantes al público.
- **RF-05-004** | `PILOTO` | Permitir que un espacio habilitado se vincule a oportunidades y actividades, con autorización del administrador de la sede.
- **RF-05-005** | `PILOTO` | Exigir consentimiento o autoridad suficiente antes de publicar una dirección de un domicilio o propiedad ajena.
- **RF-05-006** | `PILOTO` | Ofrecer reclamación y corrección de sedes duplicadas, cerradas, incorrectas o suplantadas.
- **RF-05-007** | `PILOTO` | Impedir publicar puntos en ubicaciones sensibles o prohibidas definidas por moderación.
- **RF-05-008** | `PILOTO` | Permitir ocultar o despublicar una sede sin borrar el historial mínimo de acuerdos activos.
- **RF-05-009** | `PILOTO` | No indicar que una sede está abierta, accesible o verificada sin datos vigentes y un significado definido para cada señal.
- **RF-05-010** | `PILOTO` | Ofrecer opciones de contacto seguras cuando la dirección precisa no pueda publicarse.

### M06 — Taxonomías y catálogo de capacidades

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F08 F10 F35 F52`.

- **RF-06-001** | `PILOTO` | Mantener taxonomía versionada de disciplinas, habilidades, tipo de sede y categoría de oportunidad.
- **RF-06-002** | `PILOTO` | Evitar que etiquetas de UI (mascotas, colores o categorías) sean usadas como única autorización o regla de dominio.
- **RF-06-003** | `PILOTO` | Definir dos categorías piloto iniciales configurables sin datos falsos ni categorías inexistentes presentadas como activas.
- **RF-06-004** | `PILOTO` | Permitir etiquetas de habilidad múltiples y un vocabulario libre limitado para cubrir necesidades no previstas.
- **RF-06-005** | `PILOTO` | Proveer mapeo de categorías antiguas en migraciones para no romper búsquedas, enlaces y métricas.
- **RF-06-006** | `PILOTO` | Separar categorías editoriales de la clasificación comercial y de los filtros de seguridad.
- **RF-06-007** | `PILOTO` | Mantener estatus de categoría activa, oculta, archivada o en revisión según ciudad.

### M07 — Exploración, búsqueda y descubrimiento

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F07 F08 F09 F50`.

- **RF-07-001** | `PILOTO` | Mostrar oportunidades reales públicas filtradas por ciudad y estado publicable, con fecha de última actualización.
- **RF-07-002** | `PILOTO` | Permitir búsqueda por texto, disciplina, modalidad de compensación, fecha, distancia aproximada y disponibilidad.
- **RF-07-003** | `PILOTO` | Permitir vista de lista aunque el usuario deniegue permisos de ubicación.
- **RF-07-004** | `PILOTO` | Mostrar resultados pertinentes sin aparentar que hay oferta activa cuando no la hay.
- **RF-07-005** | `PILOTO` | Ofrecer estados de resultados vacíos con opción de cambiar filtros, zona o crear una alerta voluntaria.
- **RF-07-006** | `PILOTO` | Evitar que oportunidades canceladas, expiradas o moderadas aparezcan como disponibles.
- **RF-07-007** | `PILOTO` | Mostrar contexto suficiente para decidir abrir ficha sin compartir datos personales innecesarios.
- **RF-07-008** | `PILOTO` | Establecer reglas documentadas de ordenamiento y separar claramente resultados pagados de los orgánicos cuando exista esa función.
- **RF-07-009** | `PILOTO` | Registrar de forma agregada búsquedas sin resultado para mejorar el arranque local respetando consentimiento.
- **RF-07-010** | `PILOTO` | Permitir guardar oportunidades de manera privada y eliminar guardados sin afectar el recurso original.
- **RF-07-011** | `PILOTO` | Ofrecer enlaces de oportunidad utilizables en web y redireccionamiento seguro a la aplicación instalada.
- **RF-07-012** | `PILOTO` | Restringir scraping abusivo y paginar resultados sin exponer datos ocultos o privados.

### M08 — Misiones: creación y ciclo de oportunidades

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F10 F14 F15 F19 F24`.

- **RF-08-001** | `PILOTO` | Permitir a persona elegible u organización autorizada crear una oportunidad bajo la entidad canónica Mission.
- **RF-08-002** | `PILOTO` | Capturar objetivo concreto, descripción, categoría, habilidades, modalidad de participación, lugar/área, fecha y plazo.
- **RF-08-003** | `PILOTO` | Solicitar cantidad de participantes o cupos y distinguir el cupo de postulaciones recibidas.
- **RF-08-004** | `PILOTO` | Solicitar compensación expresada inequívocamente: pagada, intercambio o no remunerada, con términos explícitos según política.
- **RF-08-005** | `PILOTO` | Advertir de compensaciones ambiguas o convocatorias que puedan inducir trabajo gratuito engañoso.
- **RF-08-006** | `PILOTO` | Indicar quién publica y quién es responsable de la oportunidad, incluyendo modalidad de contacto y alcance geográfico.
- **RF-08-007** | `PILOTO` | Permitir guardar borrador y recuperar cambios tras interrupción sin publicar automáticamente.
- **RF-08-008** | `PILOTO` | Mostrar previsualización y validación de campos obligatorios por modalidad antes de publicar.
- **RF-08-009** | `PILOTO` | Ejecutar validación de seguridad, permisos, límites y políticas antes de cambiar a publicada.
- **RF-08-010** | `PILOTO` | Registrar versión inmutable del contenido visible a cada postulante en el momento de postular.
- **RF-08-011** | `PILOTO` | Permitir corregir errores menores sin invalidar solicitudes; cambios sustanciales requieren nueva aceptación de afectados.
- **RF-08-012** | `PILOTO` | Permitir pausar, cerrar sin seleccionar, cancelar, reabrir bajo reglas explícitas y duplicar como nueva oportunidad sin arrastrar propuestas.
- **RF-08-013** | `PILOTO` | Cerrar automáticamente postulaciones al vencer plazo, agotarse cupos o alcanzar un estado incompatible.
- **RF-08-014** | `PILOTO` | Impedir publicar oportunidades con fechas pasadas incompatibles, ubicación inexistente o actor suspendido.
- **RF-08-015** | `PILOTO` | Limitar publicaciones abusivas, repetidas, fraudulentas o masivas sin castigar indiscriminadamente oportunidades legítimas.
- **RF-08-016** | `PILOTO` | Registrar eventos de estado por actor y marca temporal con razón de cancelación o moderación.
- **RF-08-017** | `PILOTO` | Permitir que una convocatoria cerrada se conserve en historial, sin aparentar que sigue disponible.
- **RF-08-018** | `PILOTO` | Distinguir una misión de un evento público ya programado y de una ficha de catálogo; no usar una misma entidad para los tres.
- **RF-08-019** | `PILOTO` | Definir fusiones como intención/modalidad descriptiva de una misión y trueque como tipo de compensación, no flujos duplicados.

### M09 — Postulaciones, invitaciones y selección

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F11 F14 F15 F18`.

- **RF-09-001** | `PILOTO` | Permitir a una persona elegible postular a una misión abierta si cumple restricciones verificables.
- **RF-09-002** | `PILOTO` | Guardar cada postulación con identidad actuante, texto, referencias de portafolio y disponibilidad.
- **RF-09-003** | `PILOTO` | Evitar postulaciones duplicadas de la misma identidad para la misma misión, salvo regla explícita de nueva versión.
- **RF-09-004** | `PILOTO` | Permitir retirar una postulación antes del acuerdo sin borrar evidencia necesaria de abusos reportados.
- **RF-09-005** | `PILOTO` | Mostrar al postulante estado: enviada, en revisión, preseleccionada, no seleccionada, retirada o aceptada.
- **RF-09-006** | `PILOTO` | Permitir al organizador filtrar candidatos por criterios publicados, sin presentar inferencias discriminatorias como hechos.
- **RF-09-007** | `PILOTO` | Impedir que una organización seleccione más participantes que cupos confirmados mediante transacción atómica.
- **RF-09-008** | `PILOTO` | Permitir al organizador rechazar postulaciones con notificación respetuosa y sin divulgación del resto de candidatos.
- **RF-09-009** | `PILOTO` | Notificar cierre sin selección a personas aún pendientes y conservar información para evitar propuestas eternamente pendientes.
- **RF-09-010** | `PILOTO` | Permitir invitar a un creador concreto mediante enlace/aviso que no eluda permisos, bloqueos ni límites.
- **RF-09-011** | `PILOTO` | Distinguir candidatura y selección provisional de aceptación bilateral del acuerdo.
- **RF-09-012** | `PILOTO` | Restringir la visualización de candidaturas a organizadores autorizados y al postulante correspondiente.
- **RF-09-013** | `PILOTO` | Prevenir autopostulación fraudulenta mediante perfiles u organizaciones relacionadas cuando se use para reputación artificial.
- **RF-09-014** | `PILOTO` | Gestionar estados simultáneos, cambios de plazo y reintentos de red sin duplicar postulaciones.

### M10 — Acuerdos, compromisos y cambios

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F12 F14 F15 F20 F25 F47`.

- **RF-10-001** | `PILOTO` | Crear acuerdo independiente tras la selección y aceptación expresa de cada parte participante.
- **RF-10-002** | `PILOTO` | Registrar alcance, entregables esperados, lugar, fecha, ventana de ejecución, compensación declarada y participantes.
- **RF-10-003** | `PILOTO` | Registrar versión del acuerdo y evidencia de aceptación por actor con fecha y zona horaria.
- **RF-10-004** | `PILOTO` | No presentar como contrato legal revisado por MAREA ni como garantía de cumplimiento económico.
- **RF-10-005** | `PILOTO` | Permitir proponer cambios de fecha, alcance, lugar o compensación y exigir aceptación de todas las partes afectadas.
- **RF-10-006** | `PILOTO` | Conservar versiones anteriores del acuerdo para auditoría y disputas con acceso restringido.
- **RF-10-007** | `PILOTO` | Mostrar compromisos en agenda personal sin publicar información privada a terceros.
- **RF-10-008** | `PILOTO` | Evitar dobles reservas en recursos gestionados por el propio organizador cuando éste habilite disponibilidad.
- **RF-10-009** | `PILOTO` | Permitir cancelación anticipada por causas configuradas y registrar responsable y comunicación a las partes.
- **RF-10-010** | `PILOTO` | Resolver por separado la terminación de un acuerdo, el bloqueo interpersonal y una denuncia de seguridad.
- **RF-10-011** | `PILOTO` | No procesar ni custodiar pagos entre personas en el piloto; sólo documentar compensación declarada.
- **RF-10-012** | `PILOTO` | Advertir que MAREA no verifica el pago externo, salvo integración aprobada en otra fase.
- **RF-10-013** | `PILOTO` | Ofrecer flujo de incidencia si una parte no acude, incumple o reporta una situación insegura.
- **RF-10-014** | `PILOTO` | Hacer idempotentes selección, confirmación, cancelación y cambio de acuerdo en backend.

### M11 — Coordinación y mensajería contextual

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F17 F18 F37 F49`.

- **RF-11-001** | `PILOTO` | Habilitar conversación vinculada a misión o acuerdo, no chat abierto indiscriminado entre desconocidos.
- **RF-11-002** | `PILOTO` | Permitir mensajear sólo a actores autorizados en la etapa correspondiente de la colaboración.
- **RF-11-003** | `PILOTO` | Mostrar identidad y organización representada en la conversación para reducir suplantaciones.
- **RF-11-004** | `PILOTO` | Enviar texto y adjuntos permitidos con validación de tipo, tamaño y contenido peligroso.
- **RF-11-005** | `PILOTO` | Ofrecer estados enviado, recibido y error sin prometer lectura confirmada cuando no esté implementada.
- **RF-11-006** | `PILOTO` | Permitir silenciar notificaciones de una conversación y cerrar alertas no críticas.
- **RF-11-007** | `PILOTO` | No exponer mensajes de otras oportunidades, miembros revocados ni perfiles bloqueados.
- **RF-11-008** | `PILOTO` | Permitir reportar mensaje, compartir evidencia mínima con moderación y bloquear a un usuario.
- **RF-11-009** | `PILOTO` | Cuando existe bloqueo con acuerdo activo, impedir acoso y ofrecer canal administrativo acotado para asuntos pendientes.
- **RF-11-010** | `PILOTO` | Aplicar política documentada de retención, privacidad y acceso excepcional a conversaciones; no prometer cifrado E2EE si no existe.
- **RF-11-011** | `PILOTO` | Evitar publicación accidental de información de contacto y ubicación personal en notificaciones emergentes.
- **RF-11-012** | `PILOTO` | Reintentar envíos fallidos sin duplicar mensajes ni perder orden lógico de la conversación.

### M12 — Agenda, actividades públicas y eventos

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F19 F20 F47 F50`.

- **RF-12-001** | `PILOTO` | Diferenciar ActividadPública programada de ResultadoConfirmado de una misión ya ejecutada.
- **RF-12-002** | `PILOTO` | Permitir crear actividad pública asociada a una misión/acuerdo o actividad editorial autorizada, según permiso vigente.
- **RF-12-003** | `PILOTO` | Capturar título, fecha/hora, sede, condiciones de acceso, capacidad declarada, organizador y nivel de visibilidad.
- **RF-12-004** | `PILOTO` | No publicar automáticamente como evento público una misión privada o un acuerdo sin consentimiento del organizador.
- **RF-12-005** | `PILOTO` | Mostrar actividad como programada, reprogramada, cancelada, realizada o suspendida, según evidencia.
- **RF-12-006** | `PILOTO` | Requerir aceptación de cambios sustanciales cuando afecten compromisos de participantes contratados.
- **RF-12-007** | `PILOTO` | Distinguir capacidad informativa de un sistema de entradas o reservas confirmadas, que quedan fuera del piloto.
- **RF-12-008** | `PILOTO` | Permitir a una persona guardar una actividad en su agenda personal y solicitar añadirla a calendario externo.
- **RF-12-009** | `PILOTO` | Guardar instante UTC y zona IANA local; mostrar la hora de sede y evitar cambios invisibles por zona horaria.
- **RF-12-010** | `PILOTO` | Despublicar inmediatamente actividades con riesgo físico conocido o sede no autorizada, conservando auditoría restringida.
- **RF-12-011** | `PILOTO` | Ofrecer enlace público indexable de actividades autorizadas, con actualización de cancelaciones y datos estructurados válidos.
- **RF-12-012** | `PILOTO` | No afirmar asistencia real, venta de entradas o aforo reservado basándose en vistas, guardados o intención de asistir.

### M13 — Resultados confirmados y reputación

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F12 F21 F29 F30 F33`.

- **RF-13-001** | `PILOTO` | Solicitar confirmación independiente de cada parte del resultado de un acuerdo.
- **RF-13-002** | `PILOTO` | Diferenciar ejecutado autodeclarado, confirmado por ambas partes, disputado, cancelado y sin respuesta.
- **RF-13-003** | `PILOTO` | No convertir la ausencia de respuesta de una parte en confirmación automática.
- **RF-13-004** | `PILOTO` | Permitir registrar evidencia proporcional del resultado sin exigir fotografías de personas que no consintieron.
- **RF-13-005** | `PILOTO` | Mostrar al público sólo resultados autorizados y con la etiqueta exacta de nivel de verificación.
- **RF-13-006** | `PILOTO` | Permitir a cada participante atribuir colaboraciones en su portafolio y gestionar permisos de exhibición.
- **RF-13-007** | `PILOTO` | Registrar desacuerdos de autoría, créditos y publicación; retirar temporalmente materiales controvertidos cuando proceda.
- **RF-13-008** | `PILOTO` | Permitir evaluaciones posteriores vinculadas a compromisos elegibles, evitando reseñas sin colaboración.
- **RF-13-009** | `PILOTO` | Prevenir autoevaluaciones y evaluaciones coordinadas de entidades relacionadas.
- **RF-13-010** | `PILOTO` | Permitir denunciar reseñas fraudulentas, solicitar revisión y ofrecer respuesta limitada a la parte evaluada.
- **RF-13-011** | `PILOTO` | No generar puntuación global de seguridad o fiabilidad a partir de señales insuficientes.
- **RF-13-012** | `PILOTO` | Registrar razones de cancelación, no respuesta y disputa para métricas sin divulgar detalles privados.

### M14 — Mapa, geolocalización y exploración urbana

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F09 F23 F26 F49 F51`.

- **RF-14-001** | `PILOTO` | Permitir vista de mapa opcional para oportunidades, sedes y actividades autorizadas.
- **RF-14-002** | `PILOTO` | Permitir introducir ciudad/barrio manualmente y mostrar resultados sin permiso de GPS.
- **RF-14-003** | `PILOTO` | No mostrar coordenadas exactas de domicilio personal ni historial de movimientos de creadores.
- **RF-14-004** | `PILOTO` | Mostrar marcadores comerciales precisos sólo cuando su publicación esté autorizada.
- **RF-14-005** | `PILOTO` | Ofrecer información de precisión aproximada y no presentar distancias de sensores como exactas.
- **RF-14-006** | `PILOTO` | Agrupar marcadores en zonas de alta densidad y permitir alternar a vista de lista.
- **RF-14-007** | `PILOTO` | No monitorizar ubicación en segundo plano en el piloto.
- **RF-14-008** | `PILOTO` | Asegurar que los filtros de privacidad de mapa también se aplican en búsquedas, API y enlaces profundos.
- **RF-14-009** | `PILOTO` | Permitir reportar marcador equivocado, sede cerrada, punto duplicado o ubicación sensible.
- **RF-14-010** | `PILOTO` | Abrir rutas externas mediante acciones explícitas y avisar cuando se abandona MAREA.
- **RF-14-011** | `PILOTO` | Desactivar categorías o regiones no operativas sin inventar ubicaciones activas.

### M15 — Notificaciones, recordatorios y comunicación

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F18 F42 F44 F47`.

- **RF-15-001** | `PILOTO` | Enviar notificaciones de acciones relevantes: candidatura, selección, aceptación, cambios, cancelación, reporte y cuenta.
- **RF-15-002** | `PILOTO` | Distinguir mensajes transaccionales esenciales de mensajes promocionales opcionales.
- **RF-15-003** | `PILOTO` | Permitir preferencias por canal (dentro de app, push, correo) y por tipo de evento donde sea aplicable.
- **RF-15-004** | `PILOTO` | Respetar permisos de notificaciones; si se rechazan, mantener bandeja de avisos dentro de la aplicación.
- **RF-15-005** | `PILOTO` | Mostrar marcas de leído/no leído y deep links con validación actual de autorización.
- **RF-15-006** | `PILOTO` | Evitar exponer contenido confidencial en pantalla bloqueada y previsualizaciones.
- **RF-15-007** | `PILOTO` | Agrupar avisos repetidos y establecer límites de frecuencia para no saturar.
- **RF-15-008** | `PILOTO` | Registrar envío y resultado cuando sea posible sin afirmar entrega garantizada de terceros.
- **RF-15-009** | `PILOTO` | Enviar recordatorios con hora de la sede y preferencias del usuario, sin acciones críticas automáticas.
- **RF-15-010** | `PILOTO` | Localizar plantillas de push/correo y respetar idioma preferido en el instante del envío.
- **RF-15-011** | `PILOTO` | No activar notificaciones masivas de marketing sin consentimiento apropiado.

### M16 — Contenido de comunidad orientado a resultados

- **Etapa:** `POST`. **Mapeo temático v3.1:** `F07 F16 F17 F21 F22`.

- **RF-16-001** | `POST` | Permitir publicaciones relacionadas con proyectos, resultados, convocatorias o experiencias locales, no un feed social ilimitado por defecto.
- **RF-16-002** | `POST` | Asociar cada publicación a autor y, cuando corresponda, a misión o actividad sin fabricar vínculos.
- **RF-16-003** | `POST` | Permitir comentarios y reacciones únicamente cuando exista capacidad real de moderarlos.
- **RF-16-004** | `POST` | Ofrecer guardados privados y compartir enlaces públicos respetando configuración de visibilidad.
- **RF-16-005** | `POST` | Distinguir publicidad de contenido orgánico y evitar manipular posicionamiento sin señalización.
- **RF-16-006** | `POST` | Permitir archivar publicaciones y solicitar revisión de contenidos reportados.
- **RF-16-007** | `POST` | No asumir que una publicación o reacción equivale a colaboración verificada.
- **RF-16-008** | `POST` | Permitir autorizar o retirar uso de imágenes que identifiquen participantes según política aplicable.

### M17 — Denuncias, bloqueo y seguridad presencial

- **Etapa:** `BASE`. **Mapeo temático v3.1:** `F31 F37 F49 RNF-PRES`.

- **RF-17-001** | `BASE` | Permitir reportar personas, organizaciones, misiones, sedes, mensajes, imágenes y actividades desde su contexto.
- **RF-17-002** | `BASE` | Permitir bloqueo desde un perfil o conversación y aplicar el efecto también en invitaciones y descubrimiento personalizado.
- **RF-17-003** | `BASE` | Ofrecer motivos y nivel de urgencia en reportes, sin obligar a narraciones extensas para riesgos inmediatos.
- **RF-17-004** | `BASE` | Dar número de caso y confirmación al denunciante sin revelar datos del acusado.
- **RF-17-005** | `BASE` | Aplicar cola de moderación por severidad, riesgo físico y vulnerabilidad de los afectados.
- **RF-17-006** | `BASE` | Permitir suspensión preventiva y despublicación cuando se evalúen amenazas creíbles o fraudes.
- **RF-17-007** | `BASE` | Definir horarios reales de atención, responsables, escalado y criterios de suspensión de funciones inseguras.
- **RF-17-008** | `BASE` | Ofrecer información de contacto y guía para acudir a servicios de emergencia cuando exista peligro inmediato.
- **RF-17-009** | `BASE` | Proteger ubicación personal y no permitir eventos en zonas sensibles sin autorización verificable.
- **RF-17-010** | `BASE` | Prevenir hostigamiento mediante invitaciones repetidas, perfiles clonados y evasión de bloqueos.
- **RF-17-011** | `BASE` | Limitar exposición de evidencias y permitir acceso excepcional a personal autorizado con registro de motivo.
- **RF-17-012** | `BASE` | Permitir apelación de sanciones y revisión humana proporcional según gravedad.
- **RF-17-013** | `BASE` | Evitar que una denuncia implique de forma automática una reputación pública negativa sin resolución.
- **RF-17-014** | `BASE` | No ofrecer promesa de seguridad personal garantizada; explicar límites del servicio y mecanismos disponibles.

### M18 — Verificación, antifraude y calidad de oferta

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F29 F30 F31 F33`.

- **RF-18-001** | `PILOTO` | Diferenciar señales de correo verificado, control de organización, sede confirmada y resultado completado.
- **RF-18-002** | `PILOTO` | Mostrar el significado verificable de cada señal y fecha de última revisión cuando aplique.
- **RF-18-003** | `PILOTO` | Permitir verificación proporcional de organizadores piloto sin exigir identificación oficial a todos los usuarios por defecto.
- **RF-18-004** | `PILOTO` | Detectar patrones de misiones duplicadas, identidades vinculadas fraudulentas, spam y postulación automática.
- **RF-18-005** | `PILOTO` | Establecer revisión adicional para ofertas de compensación excepcional, enlaces externos sospechosos o cambios masivos.
- **RF-18-006** | `PILOTO` | Ofrecer mecanismo de reclamación de marcas y sedes para mitigar suplantación comercial.
- **RF-18-007** | `PILOTO` | No utilizar atributos sensibles o protegidos para clasificar confiabilidad de candidatos.
- **RF-18-008** | `PILOTO` | Mantener historial privado de sanciones conforme a política de retención, apelaciones y necesidad operativa.
- **RF-18-009** | `PILOTO` | Establecer límites por actor, dispositivo o comportamiento de modo proporcional y sujeto a revisión de falsos positivos.
- **RF-18-010** | `PILOTO` | Solicitar revisión periódica de oportunidades obsoletas y suspender recursos abandonados según criterios publicados.

### M19 — Administración, soporte y operaciones

- **Etapa:** `BASE`. **Mapeo temático v3.1:** `F37 F38 F40 F52`.

- **RF-19-001** | `BASE` | Ofrecer consola administrativa separada de la aplicación pública con MFA obligatorio.
- **RF-19-002** | `BASE` | Aplicar roles operativos limitados para soporte, moderación, editorial y gestión técnica.
- **RF-19-003** | `BASE` | Registrar toda acción administrativa sensible con actor, motivo, momento y alcance.
- **RF-19-004** | `BASE` | Permitir revisar, escalar, resolver y apelar incidencias con acceso segregado a evidencias.
- **RF-19-005** | `BASE` | Impedir que soporte ordinario consulte conversaciones privadas completas sin autorización excepcional documentada.
- **RF-19-006** | `BASE` | Permitir deshabilitar temporalmente un módulo o ciudad mediante control seguro de funcionalidades.
- **RF-19-007** | `BASE` | Ofrecer revisión editorial de categorías, contenido público destacado y fuentes de publicación auténticas.
- **RF-19-008** | `BASE` | Disponer de procedimiento para atender eliminación de cuenta, exportación de datos y solicitudes de privacidad.
- **RF-19-009** | `BASE` | Permitir corregir publicaciones equivocadas sin alterar unilateralmente acuerdos firmados por otros actores.
- **RF-19-010** | `BASE` | Registrar métricas de trabajo manual en activación, moderación y resolución de disputas para analizar sostenibilidad.
- **RF-19-011** | `BASE` | Ofrecer estados de degradación del sistema y comunicaciones ante incidentes que afecten compromisos importantes.

### M20 — Medición, aprendizaje y experimento de mercado

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F33 F34 F35 F48`.

- **RF-20-001** | `PILOTO` | Medir por ciudad y categoría misiones reales creadas, publicadas y vigentes, sin sumar borradores como oferta.
- **RF-20-002** | `PILOTO` | Medir postulaciones útiles y tiempo a primera postulación, distinguiendo mensajes de propuestas calificadas.
- **RF-20-003** | `PILOTO` | Medir proporción de acuerdos bilaterales y resultados confirmados, con denominadores definidos.
- **RF-20-004** | `PILOTO` | Medir reincidencia de organizadores por cohortes con ventana de observación explícita.
- **RF-20-005** | `PILOTO` | Medir cancelaciones, disputas, abandono, bloqueos e incidentes como contrapeso de métricas de crecimiento.
- **RF-20-006** | `PILOTO` | Separar activación asistida por el equipo de adopción orgánica para no sobredimensionar tracción.
- **RF-20-007** | `PILOTO` | Medir trabajo humano y costo asociado por colaboración confirmada.
- **RF-20-008** | `PILOTO` | Registrar eventos analíticos con esquema versionado, identidad minimizada, respeto al consentimiento y retención definida.
- **RF-20-009** | `PILOTO` | Evitar indicadores manipulables tales como «likes» y visitas como sustitutos de valor entregado.
- **RF-20-010** | `PILOTO` | Permitir exportar un reporte operativo agregado para el equipo piloto sin exponer mensajes ni ubicaciones privadas.
- **RF-20-011** | `PILOTO` | Realizar análisis por categoría y zona antes de justificar una segunda ciudad o segmento.

### M21 — Modelo comercial y herramientas para organizadores

- **Etapa:** `POST`. **Mapeo temático v3.1:** `F25 F32 F34`.

- **RF-21-001** | `POST` | Mantener el núcleo de descubrimiento y oportunidades de creadores accesible sin pago en la etapa de validación.
- **RF-21-002** | `POST` | Probar herramientas de valor para organizadores recurrentes antes de diseñar planes permanentes.
- **RF-21-003** | `POST` | Definir límites gratuitos y capacidades profesionales sobre datos observados, no imponer precios arbitrarios.
- **RF-21-004** | `POST` | Separar las prestaciones digitales de suscripciones propias de los servicios presenciales entre usuarios.
- **RF-21-005** | `POST` | No habilitar pasarela ni checkout de suscripción hasta tener matriz legal, fiscal y de políticas de tiendas por plataforma.
- **RF-21-006** | `POST` | Permitir consultar el plan vigente y derechos de acceso derivados, independientes de la UI del cliente.
- **RF-21-007** | `POST` | Mantener entitlements de pago verificables en servidor y proteger cambios de plan frente a duplicados y reintentos.
- **RF-21-008** | `POST` | Diseñar cancelación y restauración de suscripciones conforme a plataforma y proveedor que se aprueben.
- **RF-21-009** | `POST` | No operar depósito, escrow, reparto ni custodia de pagos entre terceros en la fase piloto.
- **RF-21-010** | `POST` | No presentar anuncios patrocinados sin distinguirlos de los resultados orgánicos cuando se activen.
- **RF-21-011** | `POST` | Medir conversión y disposición real a pagar sin vender datos personales de usuarios.

### M22 — Web pública, enlaces y distribución

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F41 F48 F50`.

- **RF-22-001** | `PILOTO` | Permitir abrir fichas públicas legítimas de oportunidades, sedes, creadores y actividades mediante URL estable.
- **RF-22-002** | `PILOTO` | Ofrecer metadatos de título, descripción e imagen de previsualización en páginas públicas sin filtrar datos privados.
- **RF-22-003** | `PILOTO` | Definir renderizado indexable de contenido público con HTML apto para SEO; no asumir que Flutter Web lo proporciona por defecto.
- **RF-22-004** | `PILOTO` | Permitir redirigir a pantalla equivalente dentro de Android/iOS si la aplicación está instalada.
- **RF-22-005** | `PILOTO` | Recuperar destino al iniciar sesión después de seguir enlace protegido y validar permisos otra vez.
- **RF-22-006** | `PILOTO` | Generar sitemap sólo para contenido público indexable y actualizarlo al archivar o moderar recursos.
- **RF-22-007** | `PILOTO` | Evitar indexación de mensajes, candidaturas, acuerdos, reportes, perfil privado y rutas sensibles.
- **RF-22-008** | `PILOTO` | Mantener enlaces expirados o retirados con respuestas claras sin exponer por qué fueron restringidos.
- **RF-22-009** | `PILOTO` | Soportar teclado, etiquetas semánticas y navegación accesible en web.
- **RF-22-010** | `PILOTO` | Publicar páginas de ayuda, contacto, privacidad, condiciones y eliminación de cuenta.

### M23 — Móviles, medios, estado local y conectividad

- **Etapa:** `BASE`. **Mapeo temático v3.1:** `F39 F40 F41 F45 F46 F51`.

- **RF-23-001** | `BASE` | Soportar Android e iOS con matriz de funciones por plataforma y degradación ante hardware no disponible.
- **RF-23-002** | `BASE` | Solicitar permisos de fotos, cámara y ubicación en el momento de uso, nunca antes como barrera global.
- **RF-23-003** | `BASE` | Permitir seleccionar archivo o imagen sin requerir acceso irrestricto a la fototeca cuando exista selector del sistema.
- **RF-23-004** | `BASE` | Validar tamaño, formato, firmas de archivo y límites de almacenamiento tanto en cliente como en servidor.
- **RF-23-005** | `BASE` | Eliminar metadatos EXIF/GPS de imágenes públicas salvo necesidad justificada y consentimiento explícito.
- **RF-23-006** | `BASE` | Permitir reintentar cargas incompletas y evitar medios huérfanos mediante limpieza controlada.
- **RF-23-007** | `BASE` | Guardar borradores locales de perfil, misión o propuesta con aviso de estado de sincronización.
- **RF-23-008** | `BASE` | Permitir consultar caché reciente sin conexión mostrando antigüedad; no simular nuevas publicaciones sin red.
- **RF-23-009** | `BASE` | Bloquear acciones críticas offline (selección, aceptación, cancelación, verificación) si no hay confirmación de servidor.
- **RF-23-010** | `BASE` | Tratar reintentos con idempotencia y conflictos de versión para evitar duplicar acuerdos.
- **RF-23-011** | `BASE` | Usar almacenamiento protegido adecuado para credenciales en móvil; no almacenar secretos en preferencias comunes.
- **RF-23-012** | `BASE` | Evitar registros de tokens, direcciones precisas, mensajes privados y evidencias sensibles en analítica o crash logs.
- **RF-23-013** | `BASE` | Verificar orientación, áreas seguras, teclado, accesibilidad y tamaño de texto en dispositivos variados.
- **RF-23-014** | `BASE` | Comprobar límites de batería, red y memoria en dispositivos de gama media o baja representativos del piloto.
- **RF-23-015** | `BASE` | Mantener notificaciones esenciales disponibles dentro de la app si no se concede permiso push.

### M24 — Captación local, invitaciones y liquidez

- **Etapa:** `PILOTO`. **Mapeo temático v3.1:** `F43 F48 F52`.

- **RF-24-001** | `PILOTO` | Permitir incorporar organizadores y creadores reales con un flujo asistido sin perfiles ficticios.
- **RF-24-002** | `PILOTO` | Registrar fuente de captación de forma agregada con consentimiento y sin revelar datos personales del promotor.
- **RF-24-003** | `PILOTO` | No mostrar oportunidades editoriales como creadas por negocios si fueron inventadas por el equipo.
- **RF-24-004** | `PILOTO` | Ofrecer invitaciones controladas a colaboradores para una misión con enlaces de caducidad y protección anti-spam.
- **RF-24-005** | `PILOTO` | Permitir lista de espera fuera de ciudades activas sin crear expectativas de cobertura inexistente.
- **RF-24-006** | `PILOTO` | Mostrar ejemplos educativos claramente etiquetados como demostración, nunca en listados de actividad real.
- **RF-24-007** | `PILOTO` | Disponer de procedimiento de limpieza y actualización de ofertas expirada durante el piloto.
- **RF-24-008** | `PILOTO` | Pausar campañas cuando no haya suficiente respuesta o capacidad de moderación operativa.
- **RF-24-009** | `PILOTO` | Entregar al equipo un panel agregado de equilibrio oferta-demanda por categoría para decidir próximas acciones.

### M25 — Fiabilidad, privacidad y ciclo de vida de datos

- **Etapa:** `BASE`. **Mapeo temático v3.1:** `F36 F40 F45 RNF-*`.

- **RF-25-001** | `BASE` | Documentar inventario de datos personales por finalidad, actor, sensibilidad, base legal, ubicación, retención y eliminación.
- **RF-25-002** | `BASE` | Mantener auditoría técnica de autorizaciones y modificaciones críticas con acceso mínimo.
- **RF-25-003** | `BASE` | Permitir descargar datos personales proporcionados por una cuenta cuando corresponda a política y normativa aplicable.
- **RF-25-004** | `BASE` | Ejecutar eliminación según categoría de dato, referencias de organización y excepciones de conservación justificadas.
- **RF-25-005** | `BASE` | Definir plazos concretos de retención antes de producción; no interpretar borrado visual como destrucción total.
- **RF-25-006** | `BASE` | Separar respaldos de PostgreSQL, objetos de Storage y secretos/configuración; ensayar recuperación completa.
- **RF-25-007** | `BASE` | Mantener pruebas de autorización para tablas, funciones, almacenamiento y canales de tiempo real por operación.
- **RF-25-008** | `BASE` | Desplegar migraciones versionadas, entornos separados, secretos fuera de clientes y revisiones de dependencias.
- **RF-25-009** | `BASE` | Definir presupuestos de consumo para mapas, medios, correos, notificaciones y base de datos.
- **RF-25-010** | `BASE` | Registrar incidentes, responsables, mitigaciones y comunicaciones proporcionales.
- **RF-25-011** | `BASE` | Mantener compatibilidad entre versiones móviles admitidas y cambios de esquema backend.
- **RF-25-012** | `BASE` | Establecer SLA/SLO candidatos sólo como objetivos sujetos a pruebas de carga y capacidad operativa.

### M26 — Funciones de evolución sujetas a evidencia

- **Etapa:** `CONDICIONAL`. **Mapeo temático v3.1:** `F13 F15 F17 F20 F21 F22 F23 F24 F25 F26 F27 F28 F35`.

- **RF-26-001** | `CONDICIONAL` | Definir Tripulaciones como equipos creativos persistentes sólo si los acuerdos repetidos requieren administración grupal.
- **RF-26-002** | `CONDICIONAL` | Diseñar Fusiones como plantilla/mode de misión; no crear un segundo motor de postulaciones.
- **RF-26-003** | `CONDICIONAL` | Admitir trueque únicamente como tipo de contraprestación con reglas claras, sin bolsa de créditos intercambiables por defecto.
- **RF-26-004** | `CONDICIONAL` | Posponer marketplace transaccional, carrito, pagos entre usuarios y comisiones hasta prueba jurídica y demanda observada.
- **RF-26-005** | `CONDICIONAL` | Posponer reservas de aforo y ticketing completos hasta que las actividades necesiten ese flujo.
- **RF-26-006** | `CONDICIONAL` | Posponer Drops y promociones limitadas hasta comprobar utilidad para negocio y consumidor y poder moderar inventario.
- **RF-26-007** | `CONDICIONAL` | Posponer Pasaporte, insignias y recompensas hasta demostrar que mejoran participación real sin incentivar fraude.
- **RF-26-008** | `CONDICIONAL` | Posponer rutas urbanas complejas y recomendaciones algorítmicas hasta tener suficientes lugares y actividades reales.
- **RF-26-009** | `CONDICIONAL` | Posponer feeds sociales universales, chats abiertos, seguidores y comentarios masivos hasta disponer de moderación escalable.
- **RF-26-010** | `CONDICIONAL` | Mantener AR Explorer como experimento opcional; asegurar alternativa 2D, manejo de sensores y prohibición de posiciones engañosas.
- **RF-26-011** | `CONDICIONAL` | Posponer editor AR, anclaje visual, modelos 3D, visitas 360° y recursos pesados hasta validar adopción y dispositivos.
- **RF-26-012** | `CONDICIONAL` | Posponer IA generativa y ranking automatizado decisorio hasta contar con datos, evaluación de sesgo, costo y control humano.
- **RF-26-013** | `CONDICIONAL` | No interpretar ningún requisito CONDICIONAL como autorización de desarrollo ni prometerlo comercialmente sin aprobación explícita.

## 6. Controles transversales de seguridad, calidad y plataformas

### SEC-ID — Sesiones, secretos y autenticación

- **CT-SEC-ID-001** | Rechazar reutilización de OTP, aplicar expiración y enfriamiento a recuperación de contraseña.
- **CT-SEC-ID-002** | Implementar medidas contra fuerza bruta y registros automatizados, calibradas con pruebas de falsos positivos.
- **CT-SEC-ID-003** | Reautenticar acciones de transferencia de organización y cambio de medios de recuperación.
- **CT-SEC-ID-004** | Exigir MFA a todas las identidades administrativas de producción.
- **CT-SEC-ID-005** | Tratar claves de servicio de Supabase, credenciales de firma y secretos como material exclusivo de servidores.
- **CT-SEC-ID-006** | Rotar o revocar sesiones y credenciales comprometidas y auditar el procedimiento.
- **CT-SEC-ID-007** | No registrar contraseñas, OTP, JWT, refresh tokens ni PII sensible en trazas.
- **CT-SEC-ID-008** | Separar roles anónimos, autenticados, personal operativo y tareas automáticas de servidor.

### SEC-AUT — Autorización multi-actor y seguridad de APIs

- **CT-SEC-AUT-001** | Habilitar RLS y grants mínimos para tablas expuestas, con pruebas positivas y negativas por operación.
- **CT-SEC-AUT-002** | Rechazar acceso a recursos de otra organización usando ID manipulado, incluso si el solicitante pertenece a una tercera organización.
- **CT-SEC-AUT-003** | Proteger funciones RPC/Edge Functions con verificación del actor, estado y acción de negocio en servidor.
- **CT-SEC-AUT-004** | Aplicar autorización de Storage en lectura, subida, borrado y firma de URL, no solo en la tabla de metadatos.
- **CT-SEC-AUT-005** | Revalidar membresía al abrir canales Realtime y al ejecutar operaciones posteriores a revocación.
- **CT-SEC-AUT-006** | Implementar idempotencia de API en selección, aceptación, cancelación, confirmación y cambio de acuerdo.
- **CT-SEC-AUT-007** | Evitar race conditions mediante transacciones, restricciones únicas y bloqueo lógico al asignar cupos.
- **CT-SEC-AUT-008** | Validar entradas, límites de paginación, tamaño y tipos permitidos a nivel de servidor.
- **CT-SEC-AUT-009** | Impedir uso de un enlace profundo como sustituto de una autorización.
- **CT-SEC-AUT-010** | Proteger panel administrativo con cuentas y permisos diferenciados de la interfaz pública.

### SEC-CONT — Contenido, mensajería, fraudulencia y riesgo

- **CT-SEC-CONT-001** | Habilitar filtros y reportes contra contenido ilegal, ofensivo, amenazas y suplantación antes de abrir UGC público.
- **CT-SEC-CONT-002** | Aplicar bloqueos coherentes en perfiles, invitaciones, mensajería y propuestas.
- **CT-SEC-CONT-003** | Mantener canal de denuncias accesible desde toda superficie donde aparezca UGC.
- **CT-SEC-CONT-004** | Crear política de respuesta por severidad con responsable designado y cobertura operativa realista.
- **CT-SEC-CONT-005** | Evitar que alguien se valore a sí mismo o fabrique resultados usando entidades bajo control compartido.
- **CT-SEC-CONT-006** | Limitar spam de invitaciones, creación de misiones, enlaces y mensajes sin discriminar injustificadamente.
- **CT-SEC-CONT-007** | Conservar evidencia de abuso con control de acceso y periodo formalmente aprobado.
- **CT-SEC-CONT-008** | Impedir localizaciones precisas no autorizadas y marcadores en zonas sensibles.
- **CT-SEC-CONT-009** | Establecer política de enlaces externos y descargas de archivos maliciosos.
- **CT-SEC-CONT-010** | Documentar mecanismos de apelación y revisión de sanciones relevantes.

### PRI-DAT — Privacidad, archivos y protección de datos

- **CT-PRI-DAT-001** | Documentar propósito y conservación de cuenta, ubicación, contratos declarados, medios, comunicaciones y telemetría.
- **CT-PRI-DAT-002** | Separar consentimientos opcionales de los estrictamente necesarios para el servicio.
- **CT-PRI-DAT-003** | Cifrar comunicaciones con TLS y proteger datos en reposo según capacidades de proveedor y clasificación.
- **CT-PRI-DAT-004** | Prohibir identificadores personales privados en URLs, analítica pública, respuestas de error y notificaciones.
- **CT-PRI-DAT-005** | Sanear metadatos EXIF de archivos publicados y eliminar archivos huérfanos con proceso programado.
- **CT-PRI-DAT-006** | Habilitar revocación de consentimiento opcional sin pérdida injustificada de uso principal.
- **CT-PRI-DAT-007** | Definir eliminación física/lógica y su reflejo en backups, cachés, CDN y motores de búsqueda.
- **CT-PRI-DAT-008** | No entregar listados de personas, correos o ubicaciones a terceros mediante consultas masivas.
- **CT-PRI-DAT-009** | Revisar la ley mexicana vigente y avisos por un responsable jurídico antes del lanzamiento comercial.

### QLT-UX — Experiencia, accesibilidad y lenguaje

- **CT-QLT-UX-001** | Cumplir un objetivo de accesibilidad equivalente a WCAG 2.2 AA en superficies aplicables; auditar excepciones.
- **CT-QLT-UX-002** | Garantizar teclado, foco visible y orden lógico de navegación en web.
- **CT-QLT-UX-003** | Comprobar VoiceOver y TalkBack en flujos principales de registro, búsqueda, misión y reporte.
- **CT-QLT-UX-004** | Comprobar zoom y fuente ampliada sin pérdida de controles y sin depender solo del color.
- **CT-QLT-UX-005** | Ofrecer estados carga, vacío, error, reintento, offline y operación exitosa para cada flujo principal.
- **CT-QLT-UX-006** | Ofrecer contraste suficiente y opción de reducir movimiento en animaciones y experiencias de mapa.
- **CT-QLT-UX-007** | Respetar preferencias de idioma por plataforma con fallback documentado.
- **CT-QLT-UX-008** | No marcar una traducción como disponible sin cubrir UI, fallos, correos y notificaciones principales.
- **CT-QLT-UX-009** | Mantener formatos monetarios y de hora coherentes con ubicación de la actividad.

### OPS-REL — Operación, capacidad y resiliencia

- **CT-OPS-REL-001** | Definir umbrales propuestos de latencia y disponibilidad basados en pruebas, sin reportarlos como SLA logrado.
- **CT-OPS-REL-002** | Crear backups verificables de datos y medios con simulacros documentados de restauración.
- **CT-OPS-REL-003** | Medir errores de autenticación, misiones, postulaciones y mensajería sin exportar contenido privado.
- **CT-OPS-REL-004** | Mantener monitoreo de gasto de mapas, almacenamiento, correo y tráfico con alertas y límites.
- **CT-OPS-REL-005** | Contar con feature flags/kill switches por módulo, ciudad y plataforma sin producir estados inconsistentes.
- **CT-OPS-REL-006** | Documentar despliegue, migración compatible, rollback y soporte para versiones móviles anteriores.
- **CT-OPS-REL-007** | Mantener inventario de terceros, costo, titular de datos, cláusulas y alternativa ante caída.
- **CT-OPS-REL-008** | Pruebas automatizadas de unidad, integración, política RLS, concurrencia y flujos E2E prioritarios.
- **CT-OPS-REL-009** | Registrar incidentes, severidad y tiempos de atención según equipo disponible.
- **CT-OPS-REL-010** | Ensayar interrupciones parciales de GPS, mapas, correo, Storage y Realtime.

### PLT-WEB — Web y SEO

- **CT-PLT-WEB-001** | Usar HTTPS; políticas de seguridad CSP, navegación segura y protección de sesión según arquitectura web.
- **CT-PLT-WEB-002** | Revisar XSS, CSRF cuando aplique, inyección de HTML, redirecciones abiertas y caching de contenido personal.
- **CT-PLT-WEB-003** | Servir HTML público realmente indexable para fichas autorizadas sin prometer SEO de Flutter Web por sí solo.
- **CT-PLT-WEB-004** | Impedir indexación/caching público de recursos privados o con acceso revocado.
- **CT-PLT-WEB-005** | Mostrar enlaces compartidos y autenticación de retorno con redirecciones seguras.

### PLT-MOB — Android e iOS

- **CT-PLT-MOB-001** | Revisar targetSdk de Google Play y versiones mínimas al preparar cada lanzamiento; en octubre de 2026 para apps comunes nuevas se exige API 36 salvo excepciones.
- **CT-PLT-MOB-002** | Validar permisos de notificaciones, cámara, fotos y ubicación con solicitud contextual y posibilidad de negación.
- **CT-PLT-MOB-003** | Usar Keychain o Android Keystore/almacenamiento protegido para secretos del cliente cuando corresponda.
- **CT-PLT-MOB-004** | Incluir eliminación de cuenta en apps y ruta web exigida por distribución cuando aplique.
- **CT-PLT-MOB-005** | Auditar UGC, bloqueo y mecanismo de reporte conforme a Apple App Review y Google Play.
- **CT-PLT-MOB-006** | Evaluar reglas de pagos digitales y compras in-app antes de añadir planes o promociones de pago.
- **CT-PLT-MOB-007** | Probar enlaces universales/app links, restauración de sesión y retorno tras permisos del sistema.
- **CT-PLT-MOB-008** | Probar funcionamiento sin AR y sin sensores compatibles; AR no es dependencia del flujo principal.

## 7. Reglas de negocio

- **RB-01** | MAREA facilita oportunidades locales; no garantiza empleo, seguridad física, pago ni calidad de la contraparte.
- **RB-02** | La misión es la unidad de demanda; una publicación, un evento y un acuerdo no son sinónimos de misión.
- **RB-03** | Una cuenta pertenece a persona; una organización puede tener miembros y varias sedes; las facultades dependen de la membresía vigente.
- **RB-04** | La propiedad de una organización no se hereda automáticamente cuando un usuario deja la plataforma.
- **RB-05** | Sólo actores autorizados pueden editar/publicar una misión en nombre de una organización.
- **RB-06** | Se permite postular sólo a una misión publicada que admita candidaturas y en fecha vigente.
- **RB-07** | No existe acuerdo bilateral hasta aceptación explícita de todos los actores afectados.
- **RB-08** | Cualquier cambio material del acuerdo exige nueva aceptación; el original permanece como historial protegido.
- **RB-09** | Una actividad pública programada puede crearse antes de su ejecución; no implica resultado completado.
- **RB-10** | El resultado sólo se etiqueta «confirmado por ambas partes» cuando existen dos confirmaciones independientes válidas.
- **RB-11** | Sin respuesta, disputa, cancelación y ejecución autodeclarada son estados distintos; ninguno se reemplaza por otro.
- **RB-12** | La compensación se describe transparentemente; MAREA no cobra ni distribuye pagos entre terceros en piloto.
- **RB-13** | Toda ubicación de persona es aproximada por defecto; precisión de sedes requiere autoridad para publicar.
- **RB-14** | Toda reseña pública requiere vínculo con una colaboración elegible y protección anti-autoevaluación.
- **RB-15** | Un bloqueo no elimina retroactivamente evidencia necesaria ni habilita contacto abusivo sobre acuerdos activos.
- **RB-16** | Una cuenta puede eliminarse, pero la organización conserva recursos propios según permisos, política legal y retención.
- **RB-17** | No se muestra «verificado» sin etiqueta que indique exactamente qué atributo se comprobó.
- **RB-18** | Sólo se publica contenido de terceros conforme a derechos y autorizaciones; las imágenes identificables requieren base aplicable.
- **RB-19** | Los datos experimentales del equipo y los ejemplos demostrativos nunca se presentan como actividad real.
- **RB-20** | Ningún módulo condicional implica compromiso de lanzamiento; requiere hipótesis de valor, costo y riesgo aprobados.
- **RB-21** | En-US y otros idiomas no se ofrecen hasta completar sus recursos y pruebas; es-MX es idioma base.
- **RB-22** | Toda nueva ciudad requiere oferta, capacidad de soporte y moderación, y métricas de la ciudad inicial.
- **RB-23** | Puntos patrocinados requieren diferenciación clara y no alteran las verificaciones de identidad o reputación.
- **RB-24** | Si falla el servidor, las confirmaciones de acuerdos y estados críticos no se simulan como exitosas.
- **RB-25** | Las decisiones sobre retención, fiscalidad, verificación reforzada y SLA no se inventan en el cliente.

## 8. Contratos de arquitectura y decisiones cerradas

Los **20 `ADR41`** y **18 `ADR42`** siguientes son normativos, no meras recomendaciones. Una prueba de aceptación escrita comprueba **diseño esperado**, pero su ejecución todavía requiere evidencia del repositorio. Si el RF parece menos restrictivo que un ADR, se aplica el ADR.

### 8.1. ADR41 — Decisiones comerciales, de operación y responsabilidad

| ID | Afecta | Contrato obligatorio |
|---|---|---|
| `ADR41-01` | M02, M25 | Separar eliminación de persona del estado `UNOWNED_RESTRICTED` de organización, con recuperación/transferencia auditada. |
| `ADR41-02` | M17, M19 | No habilitar mensajería/encuentros públicos sin moderación humana designada y simulacro. |
| `ADR41-03` | M08, M10, M13 | Compensación externa sólo informativa; no hay garantía ni verificación de pago MAREA. |
| `ADR41-04` | M13, M18 | Evidencia de resultados en niveles; confirmado por partes ≠ revisado independientemente. |
| `ADR41-05` | M20, M21 | No construir ni habilitar cobros digitales antes de prueba de recurrencia y matriz de canales. |
| `ADR41-06` | M07, M24 | Publicación real por zona y categoría; prohibir registros/eventos simulados como reales. |
| `ADR41-07` | M08, M11 | Preguntas limitadas previas a postulación y chat privado posterior sujeto a rol/bloqueo. |
| `ADR41-08` | M12, M24 | `PublicActivity.origin` obligatorio, fuente y vencimiento editorial. |
| `ADR41-09` | M14, M26 | AR detrás de feature flag, sin depender de ella ni usar ubicación AR como prueba. |
| `ADR41-10` | M03, M15 | Idioma base es-MX; mostrar otros sólo tras traducción y QA de todos los canales. |
| `ADR41-11` | M01, M25 | Inventario de datos, retención y excepciones aprobadas antes de datos públicos reales. |
| `ADR41-12` | Todos | Baselines ACADEMICA/PILOTO/POST con puertas independientes; sin activar módulos incompletos. |
| `ADR41-13` | M02, M08–M13 | Transiciones autorizadas en servidor, versionadas, idempotentes y auditables. |
| `ADR41-14` | M07, M18 | Orden explicable sin puntuación secreta comercial; medición de exposición. |
| `ADR41-15` | M07, M12 | Mapa/agenda pública auténtica, sin obligar login ni gamificación para descubrir. |
| `ADR41-16` | M23, M25 | SLO piloto instrumentados y restauración verificada DB+Storage antes de publicarlos. |
| `ADR41-17` | M04, M13, M16 | Permisos por obra, crédito y retiro/revisión; no licencia comercial automática. |
| `ADR41-18` | M21, M22 | Billing digital desactivado hasta revisión SKU×canal×país y validación servidor. |
| `ADR41-19` | Todos | Matriz requisito→código→test→evidencia antes de declarar implementado. |
| `ADR41-20` | M20, M24 | Métricas `n/N`, cohortes, captación asistida separada y ventanas predeterminadas. |

### 8.2. ADR42 — Correcciones de integridad, privacidad y concurrencia

#### ADR42-01 — Estado canónico contradictorio

**Nivel:** ALTO. **Área:** M12 / M13.

- **DEBE:** Normalizar a `PublicActivity.REALIZADA`. Enumeraciones únicas versionadas; nunca comparar con estados de UI/traducciones.
- **Prueba exigida:** Prueba de esquema: todos los estados usados en transiciones, invariantes y eventos están declarados; intento con `HELD` se rechaza.

#### ADR42-02 — Cupo bloqueado por acuerdos inconclusos

**Nivel:** CRÍTICO. **Área:** M08 / M09 / M10.

- **DEBE:** Definir `AgreementOffer` con estados `PENDIENTE`, `ACEPTADA`, `RECHAZADA`, `EXPIRADA`, `CANCELADA`; reserva con TTL y liberación atómica. Cupo confirmado sólo tras firma válida de todas las partes; número de acuerdos activos <= cupos.
- **Prueba exigida:** Dos selecciones simultáneas y oferta vencida: jamás se supera aforo/cupo, nunca quedan reservas huérfanas, y la oferta caducada no puede aceptarse.

#### ADR42-03 — Cambios de misión con postulaciones existentes

**Nivel:** ALTO. **Área:** M08 / M09 / M10.

- **DEBE:** Editar campos materiales crea revisión nueva. Notificar a postulantes afectados; antes de continuar selección, obtener renovación explícita de propuesta/aceptación o permitir retirada sin penalización.
- **Prueba exigida:** Reducir pago/cambiar sede después de candidaturas: ninguna se convierte en acuerdo sin reconocer la versión nueva; historial accesible para disputa.

#### ADR42-04 — Intereses relacionados y autocontratación

**Nivel:** ALTO. **Área:** M02 / M09 / M13 / M18.

- **DEBE:** Calcular relaciones de control al aplicar, seleccionar, confirmar y reseñar; bloquear autoevaluaciones y marcar colaboraciones relacionadas sin atribuirlas a reputación independiente. Evitar exposiciones públicas de vínculos privados.
- **Prueba exigida:** Un usuario controla negocio y colectivo que se contratan entre sí: no se obtiene reputación verificada ni prioridad de ranking por esa relación.

#### ADR42-05 — Fechas e interrupciones horarias

**Nivel:** MEDIO. **Área:** M05 / M08 / M12.

- **DEBE:** Persistir instante UTC, zona IANA de sede y versión local visible. Vencimiento inclusivo/exclusivo documentado; todas las automatizaciones usan tiempo de servidor, nunca reloj de cliente.
- **Prueba exigida:** La postulación enviada al límite, cambio horario y una sede reprogramada producen resultados iguales en web/iOS/Android.

#### ADR42-06 — Permisos Realtime que sobreviven a una revocación

**Nivel:** CRÍTICO. **Área:** M02 / M11 / CT-SEC-AUT-005.

- **DEBE:** No enviar payload sensible por canales persistentes no revocables instantáneamente; invalidar/sustituir canales en revocación y token, minimizar TTL, forzar reconexión, y obtener contenido sensible sólo mediante lectura autorizada vigente.
- **Prueba exigida:** Miembro eliminado con socket activo no recibe nuevos mensajes/archivos privados; probar sin reconectar voluntariamente.

#### ADR42-07 — RLS eludible desde operaciones privilegiadas

**Nivel:** CRÍTICO. **Área:** M02 / M18 / M25.

- **DEBE:** Definir por endpoint actor derivado de credencial validada, organización autorizada, campos editables permitidos, RLS y permisos de DB; el cliente nunca escoge `actor_id`, `ownership_status`, `verified`, `outcome_level`. Para service-role, checks explícitos con principio de mínimo privilegio.
- **Prueba exigida:** Llamada autenticada altera otro `organization_id` o intenta escribir `verified=true`; rechazo verificable pese a Edge Function.

#### ADR42-08 — Archivos riesgosos y URLs privadas persistentes

**Nivel:** ALTO. **Área:** M04 / M23 / M25.

- **DEBE:** Procesar en cuarentena, validar firmas y límites de píxeles/descompresión, transformar formatos permitidos, escanear cuando aplique; no ejecutar contenido subido. URLs firmadas de vigencia corta y rotación/denegación del recurso privado ante revocación.
- **Prueba exigida:** Archivo camuflado/imagen bomba no llega a publicación; acceso a recurso privado revocado no continúa indefinidamente mediante URL previa.

#### ADR42-09 — Restauración que resucita datos eliminados

**Nivel:** CRÍTICO. **Área:** M01 / M25.

- **DEBE:** Llevar registro mínimo protegido de solicitudes de eliminación y supresiones aplicadas, compatible con su obligación de minimización; restaurar en entorno aislado, reaplicar bajas, revocaciones, rotaciones y controles antes de exponer servicio. Probar DB y objetos Storage por separado.
- **Prueba exigida:** Restaurar respaldo anterior al borrado: no se vuelven a publicar perfil ni fotos eliminadas; se audita reconciliación.

#### ADR42-10 — Exposición mediante SEO, caché y enlaces sociales

**Nivel:** ALTO. **Área:** M07 / M22 / M23.

- **DEBE:** Publicar sólo mediante proyección pública minimizada; al moderar/retirar invalidar cachés propias, sitemap, vista previa y URLs en la medida controlable; solicitar desindexación cuando aplique; no prometer purga inmediata de caches de terceros.
- **Prueba exigida:** Publicación denunciada y retirada: URL responde estado neutral, preview nueva no muestra datos y acceso al archivo sigue política; probar bots.

#### ADR42-11 — Mayoría de edad no cubre imágenes de terceros

**Nivel:** ALTO. **Área:** M01 / M04 / M12 / M17.

- **DEBE:** Diferenciar edad autodeclarada de identidad/edad verificada; exigir autorización para difundir personas identificables según política aplicable, reforzar revisión de medios con menores, ocultar ubicaciones privadas y habilitar retirada efectiva.
- **Prueba exigida:** Usuario adulto sube fotos de terceros menores sin autorización suficiente: contenido queda en revisión o se retira y se gestiona petición.

#### ADR42-12 — Denuncias coordinadas y privilegios de moderación

**Nivel:** ALTO. **Área:** M17 / M19.

- **DEBE:** Separar denuncia, medida precautoria, decisión y apelación; revisar señales independientes de volumen, limitar abuso reportante; acceso a evidencias por caso, asignación caducable, auditoría y segundo control para operaciones de alto riesgo.
- **Prueba exigida:** 100 denuncias copiadas no generan prohibición irreversible automática; moderador no asignado no accede a pruebas privadas.

#### ADR42-13 — Autorización de sede frente a actividad y material promocional

**Nivel:** ALTO. **Área:** M05 / M12 / M17.

- **DEBE:** Registrar fuente y vigencia de consentimiento por ubicación, obra y medio; retirar difusión comercial afectada y notificar a participantes, sin alterar unilateralmente acuerdos previos. Un evento con sede retirada vuelve a revisión o se cancela con estado trazable.
- **Prueba exigida:** Propietario de sede revoca la publicación: nueva difusión deshabilitada y asistentes informados sin borrar el expediente del acuerdo.

#### ADR42-14 — Recuperación de cuenta y dispositivos comprometidos

**Nivel:** ALTO. **Área:** M01 / M02.

- **DEBE:** Proceso de recuperación escalonado y documentado, con autenticación reforzada proporcional, demoras de seguridad para operaciones de alto impacto y notificación por canal previo cuando exista; soporte no cambia titularidad por solicitud verbal.
- **Prueba exigida:** Atacante conoce correo y pide recuperar MFA: no puede transferir organización sin pruebas de identidad y segundo control.

#### ADR42-15 — Entrega de notificaciones y jobs sin consistencia transaccional

**Nivel:** MEDIO. **Área:** M10 / M15 / M25.

- **DEBE:** Registrar evento de dominio/outbox en la misma transacción de cambio de estado; procesar al menos una vez con clave estable, reintentos/backoff, cola de errores y conciliación; no equiparar push recibido con lectura.
- **Prueba exigida:** Se acepta acuerdo y cae worker: al recuperar se envía un único aviso lógico, sin duplicar estado ni perder notificación esencial en el inbox.

#### ADR42-16 — Versiones móviles antiguas y reversión de migraciones

**Nivel:** ALTO. **Área:** M23 / M25.

- **DEBE:** Publicar contratos versionados de API/esquemas/eventos, aplicar expand-migrate-contract y tolerancia a clientes soportados, mantener ventana de retirada; flags capaces de desactivar nuevos flujos sin romper datos.
- **Prueba exigida:** Cliente móvil anterior conectado a backend nuevo no corrompe datos ni interpreta estado desconocido como éxito.

#### ADR42-17 — Dependencias externas y transferencia de datos

**Nivel:** ALTO. **Área:** M20 / M25.

- **DEBE:** Matriz proveedor→finalidad→categoría datos→ubicación→contrato→transferencia→retención→mecanismo de baja→alternativa. La aprobación legal/privacidad y presupuesto preceden envío de datos reales.
- **Prueba exigida:** Desactivar proveedor analítico: deja de recibir eventos nuevos y se procesa baja/devolución según contrato y normativa.

#### ADR42-18 — Trazabilidad antigua presentada como cobertura funcional total

**Nivel:** MEDIO. **Área:** Documentación / todos.

- **DEBE:** Declarar trazabilidad temática (no requisito-a-requisito). Generar diff estructurado por ID antiguo→nuevo/decisión de retiro/condicional y obtener aprobación antes de afirmar cero pérdida. Registrar evidencia en backlog.
- **Prueba exigida:** Auditor encuentra antiguo requisito sin correspondencia: se registra decisión de mantener, sustituir o retirar, sin declararlo cubierto por nombre del módulo.

### 8.3. Contratos complementarios de precisión v5.0

- **CTR5-01 — Ofertas:** `offer_ttl=72h`, cada oferta reserva exactamente una plaza, la reserva se libera por rechazo/caducidad/cancelación y toda transición está protegida por transacción e idempotencia. La UI nunca muestra como «seleccionado definitivamente» a quien sólo recibió una oferta.
- **CTR5-02 — Cierre de misión:** cerrar/expirar impide crear nuevas candidaturas u ofertas; no invalida acuerdos ya activos. Cancelar misión exige tratamiento explícito de ofertas pendientes y acuerdos existentes, más notificaciones.
- **CTR5-03 — Aceptaciones:** en cada parte del acuerdo se almacena `actor_id`, contexto de actuación, `revision_id`, timestamp UTC e IP/metadata de auditoría limitada conforme a la política aprobada. Toda parte afectada debe renovar aceptación de cambio material.
- **CTR5-04 — Resultado:** permitir una ventana de respuesta de **7 días naturales** desde declaración/notificación válida del resultado; vencida la ventana pasa a `SIN_RESPUESTA`, sin reputación positiva/negativa automática. Cualquier disputa mantiene evidencia con acceso restringido.
- **CTR5-05 — Dueño único eliminado:** permitir iniciar eliminación personal; organización pasa a `UNOWNED_RESTRICTED`; se bloquean nuevas obligaciones, no se reasigna propietaria sin aceptación documentada; acuerdos activos siguen un proceso de cierre supervisado.
- **CTR5-06 — Recuperación de datos:** registrar supresiones minimizadas y reaplicarlas **antes de publicar** una restauración de DB/Storage. Restaurar en entorno aislado y revalidar permisos, claves y archivos.
- **CTR5-07 — Interfaz de estados:** las etiquetas son traducciones; backend acepta exclusivamente enumeraciones canónicas listadas en 3.1. Las aplicaciones antiguas deben tratar valores desconocidos como «no disponible» y solicitar actualización, no como éxito.
- **CTR5-08 — Eventos/avisos:** mutación de dominio + outbox en la misma transacción; event_id estable, consumo al menos una vez, deduplicación lógica, reintentos limitados y conciliación. Push entregado nunca significa leído.
- **CTR5-09 — Seguridad de perfiles:** una identidad controladora puede operar distintos perfiles; detección de vínculos por control interno no revela la relación privada en público. Reputación independiente no puede surgir de contrataciones relacionadas.
- **CTR5-10 — Release de idiomas:** es-MX completo en funciones habilitadas. en-US y posteriores sólo mediante aprobación de cobertura de UI, accesibilidad, comunicaciones y textos legales; no se habilita por tener únicamente algunas cadenas traducidas.
- **CTR5-11 — Dependencias y fuentes:** integraciones externas sólo si existe inventario de datos/consentimiento/ubicación/costos, acuerdo aplicable y mecanismo de desconexión. No tratar analytics ni mapas como exentos de privacidad.
- **CTR5-12 — Aplicaciones de tienda:** las funciones de cuenta incluyen flujo de eliminación móvil y recurso web de solicitud; las compras digitales permanecen desactivadas hasta matriz por SKU × plataforma × país, revisión fiscal/legal y validación servidor.

## 9. Matriz de pruebas obligatorias y criterios de aceptación

Los 26 escenarios `AC` originales son mínimos y se conservan íntegros. Los casos `AT5` siguientes cubren puntos que antes carecían de decisión exacta. Para aprobar un RF implementado: prueba positiva + negativa + autorización entre dos identidades cuando corresponda + evidencia en Android/iOS/web según superficie. No basta la captura de pantalla.

### 9.1. Criterios originales AC-01…AC-26

### AC-01 — Visitante sin cuenta

- **Dado:** Una persona sin cuenta abre un enlace público válido.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** La ficha muestra datos autorizados y solicita iniciar sesión sólo al intentar postular.

### AC-02 — Organización ajena

- **Dado:** Un usuario autenticado no es miembro de la organización Y.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Toda lectura/escritura sobre borradores, propuestas y mensajes privados de Y se rechaza en API/RLS.

### AC-03 — Revocación miembro

- **Dado:** Un editor tiene un panel abierto y el dueño le revoca acceso.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Su siguiente consulta, RPC, carga o suscripción deja de acceder a recursos internos.

### AC-04 — Propiedad de organización

- **Dado:** El único propietario intenta eliminar cuenta con acuerdos organizacionales activos.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** El sistema exige transferencia o disolución compatible con compromisos y política de retención.

### AC-05 — Borrador interrumpido

- **Dado:** Se corta la conexión durante edición de misión.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** El borrador permanece con fecha de sincronización y no aparece publicado.

### AC-06 — Misiones sin pago

- **Dado:** Organizador publica misión remunerada.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** La ficha muestra monto/forma declarada y aclara que MAREA no procesa ni garantiza cobro de terceros.

### AC-07 — Selección concurrente

- **Dado:** Dos administradores seleccionan simultáneamente el último cupo.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Exactamente una selección adquiere el cupo y la otra obtiene conflicto recuperable.

### AC-08 — Cambio sustancial

- **Dado:** Un acuerdo cambia fecha, sede o compensación.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Las partes deben volver a aceptar y el acuerdo anterior queda consultable con acceso autorizado.

### AC-09 — Actividad no es resultado

- **Dado:** Se programa concierto para el próximo viernes.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Puede aparecer en agenda como programado; no se cuenta como colaboración completada.

### AC-10 — Resultado unilateral

- **Dado:** Una parte marca trabajo realizado, la otra no responde.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** El resultado aparece como autodeclarado, nunca como verificado por dos.

### AC-11 — Resultado disputado

- **Dado:** Las partes discrepan sobre cumplimiento.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Se congela la confirmación pública y se abre incidente proporcional sin borrar pruebas.

### AC-12 — Bloqueo durante acuerdo

- **Dado:** Una persona bloquea al organizador tras denunciar acoso.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Se suprime contacto directo no imprescindible y se preserva canal seguro de gestión de compromiso.

### AC-13 — Sin permiso de ubicación

- **Dado:** Se rechaza GPS en Android, iOS o web.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** La búsqueda por ciudad y lista sigue funcionando sin exigir ubicación.

### AC-14 — Sede falsa

- **Dado:** Tercero reporta una ubicación de domicilio particular.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** El punto se oculta o revisa según gravedad sin revelar denunciante.

### AC-15 — Idioma persistente

- **Dado:** Una persona selecciona es-MX y reinicia la app.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** El idioma permanece; en-US no aparece mientras no esté completamente disponible.

### AC-16 — Sesión caducada

- **Dado:** La persona abre una postulación protegida mediante enlace con sesión expirada.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Se solicita login y se devuelve al recurso sólo si aún tiene permiso.

### AC-17 — Fuera de cobertura

- **Dado:** Una persona elige ciudad sin operación.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Se informa claramente y se ofrecen opciones de espera; no se muestran oportunidades inventadas.

### AC-18 — Reporte UGC

- **Dado:** Se reporta mensaje ofensivo.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Se confirma un caso y pasa a cola con severidad, registro y visibilidad limitada.

### AC-19 — Eliminación vs organización

- **Dado:** Un integrante sin propiedad elimina su cuenta.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Se elimina/desvincula su identidad según política sin destruir recursos comerciales ajenos.

### AC-20 — Medio con GPS

- **Dado:** Creador publica una fotografía que contiene EXIF de ubicación residencial.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** El medio público no revela la geolocalización EXIF.

### AC-21 — Sin conexión

- **Dado:** Una persona intenta aceptar acuerdo sin internet.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** No aparece confirmación falsa; se ofrece reintentar después de restablecer comunicación.

### AC-22 — AR no soportada

- **Dado:** El dispositivo carece de ARKit/ARCore o no obtiene tracking.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** El mapa/lista permanece disponible y la misión sigue siendo usable.

### AC-23 — Actividad retirada

- **Dado:** Evento programado es cancelado o bloqueado por moderación.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** El enlace público deja de promocionarlo como disponible y participantes reciben aviso apropiado.

### AC-24 — Datos públicos y SEO

- **Dado:** Google u otro rastreador accede a ficha pública HTML.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Metadatos corresponden al contenido público y los recursos privados no se indexan.

### AC-25 — Idioma y fechas

- **Dado:** Un creador usa en-US en zona horaria distinta de la sede.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** Se presenta la hora de sede inequívoca y formato local sin alterar el instante almacenado.

### AC-26 — Métrica central

- **Dado:** Una misión obtiene vistas pero ninguna aceptación bilateral.
- **Cuando:** se intenta la operación descrita por el escenario.
- **Entonces:** No se cuenta como colaboración completada en el indicador principal.

### 9.2. Escenarios adversariales AT5

| ID | Dado / Cuando | Resultado verificable esperado |
|---|---|---|
| `AT5-01` | Dos organizadores emiten oferta por el último cupo simultáneamente | Sólo una reserva válida; la otra operación falla con conflicto consistente; no existe sobrecupo |
| `AT5-02` | Oferta vencida hace 1 segundo y candidato intenta aceptar desde móvil offline | Backend rechaza; libera cupo; no aparece acuerdo activo ni confirmación optimista |
| `AT5-03` | Una misión cambia compensación con solicitudes enviadas | Versiones previas permanecen; candidatos deben reconocer nuevos términos antes de selección |
| `AT5-04` | Dos organizaciones pertenecen a la misma persona y se califican | El resultado puede documentarse, pero no generar reputación independiente |
| `AT5-05` | Un miembro removido deja socket Realtime abierto | No recibe nuevos mensajes privados, ni puede recuperar nuevos archivos con URL previamente autorizada sin control efectivo |
| `AT5-06` | Una Edge Function usa service-role y recibe organization_id ajeno | Actor no autorizado; rechazo y evento de auditoría sin elevación de privilegios |
| `AT5-07` | Borran perfil/fotos y se restaura un backup viejo | Supresión reaplicada antes de exponer el servicio; objeto eliminado no resurge |
| `AT5-08` | Usuario cambia a modo oscuro/idioma y se autentica en otro dispositivo | Preferencias de cuenta prevalecen según 4.1; ni cadenas internas ni fechas incoherentes |
| `AT5-09` | Cortan red durante edición de borrador | UI separa «local»/«servidor»; nunca confirma publicación sin servidor; sincronización no pisa cambio remoto |
| `AT5-10` | Usuario entra con enlace público y luego bloquea a otro | Lectura pública autorizada funciona; invitaciones/mensajes del bloqueado se rechazan |
| `AT5-11` | Se denuncia falsamente una cuenta 100 veces | No hay sanción irreversible por mero volumen; decisión auditable y apelación habilitada |
| `AT5-12` | Moderador intenta abrir caso no asignado | Acceso denegado y registrado, incluso con URL directa |
| `AT5-13` | Sede revoca autorización de un evento publicado | El evento no se sigue promocionando, participantes reciben aviso; expediente de acuerdos se conserva según política |
| `AT5-14` | Cliente móvil anterior recibe estado enum desconocido | No ejecuta operación irreversible ni lo interpreta como éxito; flujo invita a actualizar |
| `AT5-15` | Se reinicia worker después de guardar acuerdo antes de avisos | Inbox lógico recibe evento una vez, sin doble contrato ni avisos duplicados |
| `AT5-16` | Usuario solicita eliminación con organización sin sucesor | Persona sigue procedimiento de baja; organización restringida; no propietario heredado |
| `AT5-17` | Usuario de iOS/Android solicita eliminar su cuenta | Ruta accesible en app; además URL externa de borrado en Android/Play; informe preciso de etapas/retención |
| `AT5-18` | Fotos contienen coordenadas GPS y rostro de tercero sin autorización | No se revela EXIF; publicación condicionada o bloqueada; reclamación de imagen disponible |
| `AT5-19` | AR incompatible, GPS denegado o sin conectividad | Descubrimiento en lista/mapa manual funciona; no bloquea misión ni reporte |
| `AT5-20` | Se recogen métricas de participantes captados manualmente | Cohorte «asistida» separada; cálculo n/N y ventanas se pueden reproducir |

## 10. Seguridad, operación, calidad y distribución

### 10.1. Controles de ingeniería del MVP / piloto

1. **Autenticación:** Supabase Auth; no guardar passwords propias; secrets privilegiados sólo en backend; controles de rate limit, OTP y MFA para operaciones privilegiadas.
2. **Autorización:** negar por defecto en DB/RLS, Storage, Edge Functions y Realtime; matriz de 3.4; probar suplantación por `organization_id` ajeno; no confiar en el tipo de perfil del front.
3. **Multitenencia:** recursos organizaciones aislados; logs de cambios de membresía y acceso; revocación efectiva de lectores y emisores incluso con sockets abiertos.
4. **Datos:** TLS, secretos fuera de repo y de `--dart-define` públicos de web (solo claves públicas apropiadas), minimización por nivel de sensibilidad, borrado y restauración con supresiones.
5. **UGC:** reporte/bloqueo/moderación/soporte operativos antes de habilitar chats y encuentros. No describir la plataforma como servicio de seguridad personal o emergencias.
6. **Pagos:** sin checkout ni custodia en PILOTO. Registrar compensación acordada como dato descriptivo con advertencia clara.
7. **Suministro:** dependencias fijadas, revisión de vulnerabilidades, entornos separados dev/staging/prod, CI para lint/tests y migraciones versionadas reversibles por expand/migrate/contract.
8. **Observabilidad:** trazas por `request_id`, contadores de fallos, audit trail de decisiones privilegiadas, alertas de costo y salubridad de colas, sin registrar contraseñas, tokens, conversaciones completas ni datos médicos.
9. **Continuidad:** backup de DB **y** Storage por separado, restauración aislada, prueba de supresiones, verificación funcional y procedimiento documentado de incidentes.
10. **QA multiplataforma:** teclados, zoom, lectores de pantalla, enlaces, fechas, notificaciones, desconexión, permisos rechazados y versiones antiguas; sistemas de pago/AR sólo si bandera habilitada.

### 10.2. Fuentes oficiales de verificación externa

Las políticas y SDK pueden cambiar. Revisar antes de cada publicación, en lugar de codificar afirmaciones regulatorias en la UI:

- Apple — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/es/) y [eliminación de cuentas](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/).
- Google Play — [eliminación de cuentas](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en), [políticas generales](https://support.google.com/googleplay/android-developer/answer/18258653?hl=en).
- Flutter — [Internationalization](https://docs.flutter.dev/ui/internationalization).
- OWASP — [ASVS](https://owasp.org/www-project-application-security-verification-standard/) y [MASVS](https://mas.owasp.org/MASVS/).
- Supabase — [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Realtime Authorization](https://supabase.com/docs/guides/realtime/authorization) y [Backups](https://supabase.com/docs/guides/platform/backups).
- México — revisión jurídica de normativa vigente sobre protección de datos, avisos, derechos de imagen, consumo y fiscalidad del modelo de negocio seleccionado.

## 11. Puertas de liberación y pendientes que NO están resueltos

**Diferenciar:** (a) requisito definido; (b) implementado; (c) probado; (d) aprobado para distribución. Ninguno se infiere de otro.

### 11.1. Puertas G0–G7

| Gate | Se necesita evidencia | Si falta |
|---|---|---|
| `G0` Problema real | Entrevistas y oportunidades auténticas, no ejemplos de clase | No ampliar zona ni adquisición masiva |
| `G1` Seguridad mínima | RLS/roles, protección de datos, reporte/moderación, eliminación probados | No abrir interacciones entre desconocidos |
| `G2` Colaboración E2E | Misión→postulación→oferta→acuerdo→resultado, concurrencia y permisos probados | No anunciar servicio completo |
| `G3` Oferta local | Actividad suficiente por zona y categoría con origen real verificable | Acotar cobertura y reclutar manualmente |
| `G4` Calidad | Resultados no fraudulentos, denuncias atendidas, métricas con cohortes | Ajustar flujo/operación antes de expandir |
| `G5` Negocio | Uso recurrente y disposición de pago con evidencia | No desarrollar/habilitar planes comerciales |
| `G6` Pagos y tiendas | Matriz SKU×canal×país, privacidad, avisos, impuestos y políticas aprobados | Mantener cobros desactivados |
| `G7` AR | Compatibilidad y utilidad verificadas con fallback 2D; rúbrica académica acordada | Mantener AR aislada/desactivada |

### 11.2. Evidencias externas pendientes, con responsable sugerido

| ID | Bloqueo real | Responsable propuesto | Evidencia necesaria |
|---|---|---|---|
| `B01` | Código real no auditado | Ingeniería backend + QA | Inventario de Flutter/Supabase, RLS, Storage, funciones y trazas pruebas |
| `B02` | Moderación no dotada de personal/turnos | Dirección producto/operaciones | Titular, suplente, horario, runbook y simulacro |
| `B03` | Protección de datos no validada jurídicamente | Asesoría jurídica + privacidad | Aviso, retención por categoría, eliminación, derechos y transferencias aprobadas |
| `B04` | Condiciones de colaboraciones y derechos | Jurídico + producto | Términos de compensación, imagen, PI, sede y responsabilidad revisados |
| `B05` | Demanda e ingresos no demostrados | Producto/investigación | Piloto, cohortes y evidencia de recurrencia/disposición a pagar |
| `B06` | Seguridad y recuperación no ensayadas | Infraestructura + seguridad | Restore DB+Storage y supresiones, vulnerabilidades y respuesta a incidente |
| `B07` | Publicación tiendas no revisada | Release manager / móvil | Checklist actual de App Store/Google Play, permisos, declaraciones, cuenta y UGC |
| `B08` | QA multiplataforma no realizado | QA móvil/web | Matriz de dispositivos, navegadores, accesibilidad, offline e idiomas |
| `B09` | Antifraude no validado contra casos reales | Seguridad/moderación | Pruebas de suplantación, contenido falso, autocontratación, abuso de reportes |
| `B10` | Rubrica final AR no confirmada | Equipo académico / docente | Aceptación escrita de alcance, dispositivos y criterios de demostración |

**Release público:** `NO-GO` hasta cerrar los bloqueos que correspondan a las funciones habilitadas. El MVP de clase puede avanzar de forma limitada y aislada, sin exponer interacciones no moderadas ni datos reales innecesarios.

### 11.3. Indicadores de validación del piloto, nunca promesas

- Prueba inicial sugerida de 8–10 semanas en una zona y hasta dos categorías, elegidas mediante entrevistas.
- Hipótesis a evaluar: 12–20 oportunidades auténticas; ≥60 % con 2 propuestas útiles en 7 días; ≥30 % convertidas en colaboración confirmada; ≥25 % de repetición a 60 días entre organizadores elegibles; ≥5 empresas con señal verificable de disposición de pago.
- Cada informe DEBE mostrar numerador, denominador, ventana, tamaño de muestra, captura manual vs orgánica, disputas, incidentes, costo por colaboración y sesgos conocidos.

## 12. Trazabilidad y protocolo de trabajo para IAs

### 12.1. Mapeo histórico temático de la versión v3.1

**Advertencia:** el siguiente mapa sólo indica destino conceptual de 52 módulos anteriores. No garantiza equivalencia de cada uno de los 882 enunciados históricos. Se debe registrar una decisión de mantener, sustituir, condicionar o retirar para cualquier requisito legado que se redescubra y afecte una tarea.

| Módulo legado | Destino v4.0 | Estado de migración |
|---|---|---|
| `F01` | `M01` | reorganizado en dominio central |
| `F02` | `M02` | reorganizado en dominio central |
| `F03` | `M03`, `M04` | reorganizado en dominio central |
| `F04` | `M04` | reorganizado en dominio central |
| `F05` | `M02`, `M04` | reorganizado en dominio central |
| `F06` | `M02`, `M05` | reorganizado en dominio central |
| `F07` | `M07`, `M16` | incorporado o rediseñado; partes diferidas |
| `F08` | `M06`, `M07` | reorganizado en dominio central |
| `F09` | `M14` | reorganizado en dominio central |
| `F10` | `M08` | reorganizado en dominio central |
| `F11` | `M09` | reorganizado en dominio central |
| `F12` | `M10`, `M13` | reorganizado en dominio central |
| `F13` | `M02`, `M26` | incorporado o rediseñado; partes diferidas |
| `F14` | `M08`, `M09`, `M26` | incorporado o rediseñado; partes diferidas |
| `F15` | `M08`, `M10`, `M26` | incorporado o rediseñado; partes diferidas |
| `F16` | `M04`, `M16` | incorporado o rediseñado; partes diferidas |
| `F17` | `M11`, `M16`, `M26` | incorporado o rediseñado; partes diferidas |
| `F18` | `M15` | reorganizado en dominio central |
| `F19` | `M12` | reorganizado en dominio central |
| `F20` | `M10`, `M12`, `M26` | incorporado o rediseñado; partes diferidas |
| `F21` | `M13`, `M26` | incorporado o rediseñado; partes diferidas |
| `F22` | `M16`, `M26` | incorporado o rediseñado; partes diferidas |
| `F23` | `M14`, `M26` | incorporado o rediseñado; partes diferidas |
| `F24` | `M04`, `M26` | incorporado o rediseñado; partes diferidas |
| `F25` | `M10`, `M21`, `M26` | incorporado o rediseñado; partes diferidas |
| `F26` | `M14`, `M26` | incorporado o rediseñado; partes diferidas |
| `F27` | `M26` | incorporado o rediseñado; partes diferidas |
| `F28` | `M26` | incorporado o rediseñado; partes diferidas |
| `F29` | `M13`, `M18` | reorganizado en dominio central |
| `F30` | `M13`, `M18` | reorganizado en dominio central |
| `F31` | `M17`, `M18` | reorganizado en dominio central |
| `F32` | `M19`, `M21` | incorporado o rediseñado; partes diferidas |
| `F33` | `M20` | reorganizado en dominio central |
| `F34` | `M20`, `M21` | incorporado o rediseñado; partes diferidas |
| `F35` | `M06`, `M20`, `M26` | incorporado o rediseñado; partes diferidas |
| `F36` | `M01`, `M03`, `M25` | reorganizado en dominio central |
| `F37` | `M11`, `M17`, `M19` | reorganizado en dominio central |
| `F38` | `M02`, `M19` | reorganizado en dominio central |
| `F39` | `M03`, `M23` | reorganizado en dominio central |
| `F40` | `M19`, `M23`, `M25` | reorganizado en dominio central |
| `F41` | `M22`, `M23` | reorganizado en dominio central |
| `F42` | `M03`, `M15` | reorganizado en dominio central |
| `F43` | `M03`, `M24` | reorganizado en dominio central |
| `F44` | `M03`, `M15` | reorganizado en dominio central |
| `F45` | `M23`, `M25` | reorganizado en dominio central |
| `F46` | `M04`, `M11`, `M23` | reorganizado en dominio central |
| `F47` | `M10`, `M12`, `M15` | reorganizado en dominio central |
| `F48` | `M20`, `M22`, `M24` | reorganizado en dominio central |
| `F49` | `M05`, `M14`, `M17` | reorganizado en dominio central |
| `F50` | `M07`, `M12`, `M22` | reorganizado en dominio central |
| `F51` | `M14`, `M23`, `M26` | incorporado o rediseñado; partes diferidas |
| `F52` | `M06`, `M19`, `M24` | reorganizado en dominio central |

### 12.2. Protocolo obligatorio de implementación con agentes

1. Leer este documento antes de diseñar tabla, pantalla o API. Identificar `RF`, `CT`, `RB`, `ADR41`, `ADR42`, `CTR5` y `AC/AT5` aplicables.
2. Inspeccionar el repositorio y migraciones; **no asumir implementado** lo que aparece en el catálogo. Guardar resultado en matriz `ID | fase | componente/ruta | estado | prueba | evidencia | riesgo`.
3. Diseñar primero permiso, estado, transacción y manejo de fallas; después UI. Cualquier endpoint que requiera privilegios se prueba con identidad sin permisos.
4. Usar migraciones PostgreSQL versionadas y revisar compatibilidad con clientes iOS/Android existentes. No desplegar cambios destructivos sobre producción sin plan de rollback.
5. Implementar solamente la tarea/fase pedida y dependencias obligatorias. `POST`/`CONDICIONAL` se mantienen desactivadas salvo autorización explícita.
6. Pruebas mínimas por caso: permitido + denegado + simultáneo/reintento + expiración + restauración cuando aplique + regresión multiplataforma.
7. Cuando una obligación exige persona, revisión jurídica, contrato, proveedor, dato real o política de tienda, marcar `PENDIENTE EXTERNO` y el ID `Bxx`. No fabricar validaciones.
8. Cada PR debe indicar IDs atendidos, evidencias, migraciones, banderas, compatibilidad y criterio de rollback.
9. Evitar datos inventados en producción. Los registros de demostración deben estar aislados y rotulados explícitamente como demo.

### 12.3. Definición de terminado de cada requisito

`VALIDADO` si, y sólo si: su implementación está localizada, todas las pruebas aplicables pasan, permisos se comprueban en el servidor, estados/casos límite están tratados, textos/idiomas/accesibilidad se verifican, no se rompe compatibilidad y el responsable añade evidencia. El SRS describe comportamiento deseado; no es certificado de calidad o cumplimiento.

## 13. Registro editorial

- **v5.0 (2026-10-12):** edición normativa limpia sin historial duplicado; se conservan los IDs de 313 RF, 69 CT, 25 RB, 26 AC, 20 ADR41 y 18 ADR42. Contratos `CTR5-01…12` concretan cupos, aceptación, tiempos, precedencia, sesiones, privacidad e idiomas. Separación de diez bloqueos externos.
- **v4.2:** fuente conceptual, ingeniería adversarial y controles ADR42.
- **v4.1:** ADR41 y cierres de las veinte decisiones de arquitectura/operación.
- **v4.0:** 26 módulos funcionales y catálogo base de RF/CT/RB/AC.
- **v3.1:** 52 áreas históricas; sin correspondencia verificada uno-a-uno con v5.0.

**FIN DE LA ESPECIFICACIÓN CANÓNICA.**
