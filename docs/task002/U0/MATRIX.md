# U0 — Matriz de recursos, actores, estados y acciones

Propuesta funcional; no valida Flutter/RPC. Generada por `node docs/task002/U0/build-matrix.mjs`. La matriz JSON contiene 7944 combinaciones, incluidas negativas. Las filas siguientes usan comunicación disponible y consentimiento expreso; el transporte y la falta de consentimiento restringen, nunca conceden facultades.

## Aplicabilidad por interfaz

| Pantalla | Recurso | Estados aplicables (muestras) | No aplicables | Actores del recurso |
|---|---|---|---|---|
| U01 | mission_list | available = Misiones disponibles; empty = Sin misiones | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member, outsider |
| U02 | acting_context | available = Contextos vigentes; org_unavailable = Organización sin facultad vigente | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member |
| U03 | organization_list | available = Organizaciones vigentes; empty = Sin organizaciones | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member |
| U04 | organization_draft | draft = Nueva organización | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member |
| U05 | organization | normal = NORMAL; suspended = SUSPENDIDA; no_owner = SIN_PROPIETARIO | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, editor, member, related |
| U06 | memberships | active = Membresías vigentes; no_owner = Última propiedad: procedimiento controlado | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer |
| U07 | invitation | pending = Invitación pendiente (13 oct); member_active = Invitación aceptada y membresía vigente (14 oct); expired = Invitación vencida; rejected = Invitación rechazada | Todo estado fuera de esta lista, incluidos terminales de otros recursos | candidate, related, member |
| U08 | mission_draft | draft = Borrador editable; material = Edición material de misión publicada | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, editor, member, candidate, related |
| U09 | mission | open = PUBLICADA · admite candidaturas; closed = CERRADA; cancelled = CANCELADA; full = PUBLICADA · sin plazas disponibles; eligibility_pending = Vínculo de control: elegibilidad sin resolver | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member, outsider |
| U10 | application_draft | eligible = Elegibilidad vigente · misión abierta; unavailable = Postulación no disponible | Todo estado fuera de esta lista, incluidos terminales de otros recursos | candidate, related |
| U11 | application | sent = ENVIADA; shortlisted = PRESELECCIONADA; offer_pending = Oferta PENDIENTE; revision_known = ENVIADA · revisión v2 reconocida; expired = CADUCADA; resolved = Candidatura resuelta | Todo estado fuera de esta lista, incluidos terminales de otros recursos | candidate, related |
| U12 | applications | available = Candidaturas preseleccionadas; empty = Sin candidaturas; closed = Misión CERRADA · sólo consulta; cancelled = Misión CANCELADA · sólo consulta | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer |
| U13 | offer_preparation | available = Candidatura disponible · plaza disponible; pending = Oferta previa PENDIENTE; expired = Oferta previa EXPIRADA · elegibilidad aún sin verificar; resolved = Oferta previa resuelta · sólo consulta; unavailable = Sin plaza / candidatura incompatible | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer |
| U14 | offer | pending = PENDIENTE · reserva vigente; expired = EXPIRADA · reserva liberada; accepted = ACEPTADA · aceptación histórica; rejected = RECHAZADA · reserva liberada; cancelled = CANCELADA · reserva liberada | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer |
| U15 | offer | pending = PENDIENTE · antes de expires_at; expired = EXPIRADA · no admite respuesta; accepted = ACEPTADA · aceptación histórica; rejected = RECHAZADA; cancelled = CANCELADA | Todo estado fuera de esta lista, incluidos terminales de otros recursos | candidate, related |
| U16 | agreement | active = ACTIVO; revision_pending = ACTIVO · propuesta de revisión pendiente; terminated = TERMINADO; cancelled = CANCELADO | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, related |
| U17 | agreement_revision | pending = Propuesta v2 vigente; signed = Aceptación propia registrada · falta contraparte; expired = Propuesta EXPIRADA; rejected = Propuesta RECHAZADA; activated = v2 activada bilateralmente; agreement_terminal = Acuerdo TERMINADO · propuesta sin operación vigente | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, related |
| U18 | agreement_history | active = Acuerdo ACTIVO · v1 vigente; revision_pending = ACTIVO · v2 propuesta; terminated = Acuerdo TERMINADO · historial; revised = ACTIVO · v2 vigente | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, related |
| U19 | cancellation_preparation | available = Acuerdo activo · sin solicitud pendiente; pending = Solicitud ya pendiente; resolved = Acuerdo terminal · sólo consulta | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, related |
| U20 | personal_safety | available = Protección personal disponible; contract_sending = Otra operación contractual en curso; safety_sending = Aviso de seguridad en curso; recorded = Aviso confirmado por servidor (muestra) | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, related |
| U21 | case | unconfirmed = Sin respuesta de registro; received = Reporte recibido (respuesta de muestra); resolved = Caso resuelto (respuesta de muestra) | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, related |
| U22 | notification_list | available = Notificaciones disponibles; empty = Sin notificaciones | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member |
| U23 | legacy_record | review = Histórico pendiente de revisión | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member |
| U24 | client_capability | incompatible = Cliente incompatible | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member, outsider |
| U25 | cancellation_request | requested = Solicitud pendiente · acuerdo ACTIVO; rejected = Solicitud RECHAZADA · acuerdo ACTIVO; completed = Cancelación bilateral completada · acuerdo CANCELADO; withdrawn = Solicitud RETIRADA · acuerdo ACTIVO; requester = Persona solicitante · no es contraparte receptora | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, related |
| U26 | mission_revision_ack | pending = Revisión v2 vigente · reconocimiento pendiente; conflict = Revisión v2 superada por v3; expired = Candidatura CADUCADA · sin transición admisible; acknowledged = Reconocimiento v2 registrado; current = Revisión ya conocida · sin cambio material | Todo estado fuera de esta lista, incluidos terminales de otros recursos | candidate, related |
| U27 | mission_transition | open = PUBLICADA; closed = CERRADA; cancelled = CANCELADA | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer |
| U28 | mission_draft | local = Borrador local; server = Borrador servidor; conflict = Versiones en conflicto | Todo estado fuera de esta lista, incluidos terminales de otros recursos | organizer, candidate, editor, related, member |

## Comunicación, incertidumbre y acciones

| Condición | Representación / habilitación |
|---|---|
| ready | Recurso y permisos actuales; consentimiento requerido para firmar/reconocer. Pulsar mutación sólo muestra envío sin respuesta. |
| loading | Esqueleto sin términos previos; acciones dependientes deshabilitadas. Entrada protección y vuelta segura disponibles. |
| sending | Nuevas mutaciones contractuales deshabilitadas; consultar clave original. Acceso protección y aviso independiente de seguridad disponibles con conexión/permisos; el propio aviso en curso no se duplica. |
| error | Resultado incierto, no fallo definitivo. Consultar servidor y clave original, sin nueva mutación ni clave. |
| conflict | Consultar operación y versión; renovar lectura/consentimiento. No volver a firmar términos superados. |
| retry_ready | Muestra de respuesta servidor NO_APLICADA: sólo reintentar operación original con clave/cuerpo/versión iguales. Si no hay operación original o cambió la versión, denegar. |
| offline | Sin nuevas operaciones ni cola; privados ocultos. Público/borrador personal protegido e instrucciones de seguridad disponibles. No registro remoto. |
| denied | Retirar contenido privado y facultades; conservar entrada a protección propia que valida destino. TASK-003 sigue sin validar revocación JWT/Realtime real. |

## Matriz por actor y estado (ready)

Organizador autorizado = Alex, titular personal o representante con permisos actuales; candidate = Lucía externa C; editor = Sofía sin firma; member = Lucía editora M sin candidatura; related = Lucía vinculada V (muestra separada con admisibilidad servidor sólo en estado open); outsider = tercero. No son roles globales de producto. Cada acción lista abajo conserva su comprobación servidor.

| Pantalla | Actor | Titular | Estado | Acciones visibles | Habilitadas con consentimiento |
|---|---|---|---|---|---|
| U01 | organizer | personal | available | detail, create, notices | detail, create, notices |
| U01 | organizer | personal | empty | create, notices | create, notices |
| U01 | organizer | organization | available | detail, create, notices | detail, create, notices |
| U01 | organizer | organization | empty | create, notices | create, notices |
| U01 | candidate | personal | available | detail, create, notices | detail, create, notices |
| U01 | candidate | personal | empty | create, notices | create, notices |
| U01 | candidate | organization | available | detail, create, notices | detail, create, notices |
| U01 | candidate | organization | empty | create, notices | create, notices |
| U01 | member | personal | available | detail, create, notices | detail, create, notices |
| U01 | member | personal | empty | create, notices | create, notices |
| U01 | member | organization | available | detail, create, notices | detail, create, notices |
| U01 | member | organization | empty | create, notices | create, notices |
| U01 | editor | personal | available | detail, create, notices | detail, create, notices |
| U01 | editor | personal | empty | create, notices | create, notices |
| U01 | editor | organization | available | detail, create, notices | detail, create, notices |
| U01 | editor | organization | empty | create, notices | create, notices |
| U01 | related | personal | available | detail, create, notices | detail, create, notices |
| U01 | related | personal | empty | create, notices | create, notices |
| U01 | related | organization | available | detail, create, notices | detail, create, notices |
| U01 | related | organization | empty | create, notices | create, notices |
| U01 | outsider | personal | available | detail, create, notices | detail, create, notices |
| U01 | outsider | personal | empty | create, notices | create, notices |
| U01 | outsider | organization | available | detail, create, notices | detail, create, notices |
| U01 | outsider | organization | empty | create, notices | create, notices |
| U02 | organizer | personal | available | personal, organizations | personal, organizations |
| U02 | organizer | personal | org_unavailable | personal, organizations | personal, organizations |
| U02 | organizer | organization | available | personal, organization, organizations | personal, organization, organizations |
| U02 | organizer | organization | org_unavailable | personal, organizations | personal, organizations |
| U02 | candidate | personal | available | personal, organizations | personal, organizations |
| U02 | candidate | personal | org_unavailable | personal, organizations | personal, organizations |
| U02 | candidate | organization | available | personal, organizations | personal, organizations |
| U02 | candidate | organization | org_unavailable | personal, organizations | personal, organizations |
| U02 | member | personal | available | personal, organizations | personal, organizations |
| U02 | member | personal | org_unavailable | personal, organizations | personal, organizations |
| U02 | member | organization | available | personal, organization, organizations | personal, organization, organizations |
| U02 | member | organization | org_unavailable | personal, organizations | personal, organizations |
| U02 | editor | personal | available | personal, organizations | personal, organizations |
| U02 | editor | personal | org_unavailable | personal, organizations | personal, organizations |
| U02 | editor | organization | available | personal, organization, organizations | personal, organization, organizations |
| U02 | editor | organization | org_unavailable | personal, organizations | personal, organizations |
| U02 | related | personal | available | personal, organizations | personal, organizations |
| U02 | related | personal | org_unavailable | personal, organizations | personal, organizations |
| U02 | related | organization | available | personal, organizations | personal, organizations |
| U02 | related | organization | org_unavailable | personal, organizations | personal, organizations |
| U02 | outsider | personal | available | Ninguna | Ninguna |
| U02 | outsider | personal | org_unavailable | Ninguna | Ninguna |
| U02 | outsider | organization | available | Ninguna | Ninguna |
| U02 | outsider | organization | org_unavailable | Ninguna | Ninguna |
| U03 | organizer | personal | available | create_org, organization | create_org, organization |
| U03 | organizer | personal | empty | create_org | create_org |
| U03 | organizer | organization | available | create_org, organization | create_org, organization |
| U03 | organizer | organization | empty | create_org | create_org |
| U03 | candidate | personal | available | create_org, invitation | create_org, invitation |
| U03 | candidate | personal | empty | create_org, invitation | create_org, invitation |
| U03 | candidate | organization | available | create_org, invitation | create_org, invitation |
| U03 | candidate | organization | empty | create_org, invitation | create_org, invitation |
| U03 | member | personal | available | create_org, organization | create_org, organization |
| U03 | member | personal | empty | create_org | create_org |
| U03 | member | organization | available | create_org, organization | create_org, organization |
| U03 | member | organization | empty | create_org | create_org |
| U03 | editor | personal | available | create_org, organization | create_org, organization |
| U03 | editor | personal | empty | create_org | create_org |
| U03 | editor | organization | available | create_org, organization | create_org, organization |
| U03 | editor | organization | empty | create_org | create_org |
| U03 | related | personal | available | create_org, invitation | create_org, invitation |
| U03 | related | personal | empty | create_org, invitation | create_org, invitation |
| U03 | related | organization | available | create_org, invitation | create_org, invitation |
| U03 | related | organization | empty | create_org, invitation | create_org, invitation |
| U03 | outsider | personal | available | Ninguna | Ninguna |
| U03 | outsider | personal | empty | Ninguna | Ninguna |
| U03 | outsider | organization | available | Ninguna | Ninguna |
| U03 | outsider | organization | empty | Ninguna | Ninguna |
| U04 | organizer | personal | draft | create_org | create_org |
| U04 | organizer | organization | draft | create_org | create_org |
| U04 | candidate | personal | draft | create_org | create_org |
| U04 | candidate | organization | draft | create_org | create_org |
| U04 | member | personal | draft | create_org | create_org |
| U04 | member | organization | draft | create_org | create_org |
| U04 | editor | personal | draft | create_org | create_org |
| U04 | editor | organization | draft | create_org | create_org |
| U04 | related | personal | draft | create_org | create_org |
| U04 | related | organization | draft | create_org | create_org |
| U04 | outsider | personal | draft | Ninguna | Ninguna |
| U04 | outsider | organization | draft | Ninguna | Ninguna |
| U05 | organizer | personal | normal | members, manage, create | members, manage, create |
| U05 | organizer | personal | suspended | members | members |
| U05 | organizer | personal | no_owner | members | members |
| U05 | organizer | organization | normal | members, manage, create | members, manage, create |
| U05 | organizer | organization | suspended | members | members |
| U05 | organizer | organization | no_owner | members | members |
| U05 | candidate | personal | normal | Ninguna | Ninguna |
| U05 | candidate | personal | suspended | Ninguna | Ninguna |
| U05 | candidate | personal | no_owner | Ninguna | Ninguna |
| U05 | candidate | organization | normal | Ninguna | Ninguna |
| U05 | candidate | organization | suspended | Ninguna | Ninguna |
| U05 | candidate | organization | no_owner | Ninguna | Ninguna |
| U05 | member | personal | normal | create | create |
| U05 | member | personal | suspended | Ninguna | Ninguna |
| U05 | member | personal | no_owner | Ninguna | Ninguna |
| U05 | member | organization | normal | create | create |
| U05 | member | organization | suspended | Ninguna | Ninguna |
| U05 | member | organization | no_owner | Ninguna | Ninguna |
| U05 | editor | personal | normal | create | create |
| U05 | editor | personal | suspended | Ninguna | Ninguna |
| U05 | editor | personal | no_owner | Ninguna | Ninguna |
| U05 | editor | organization | normal | create | create |
| U05 | editor | organization | suspended | Ninguna | Ninguna |
| U05 | editor | organization | no_owner | Ninguna | Ninguna |
| U05 | related | personal | normal | Ninguna | Ninguna |
| U05 | related | personal | suspended | Ninguna | Ninguna |
| U05 | related | personal | no_owner | Ninguna | Ninguna |
| U05 | related | organization | normal | Ninguna | Ninguna |
| U05 | related | organization | suspended | Ninguna | Ninguna |
| U05 | related | organization | no_owner | Ninguna | Ninguna |
| U05 | outsider | personal | normal | Ninguna | Ninguna |
| U05 | outsider | personal | suspended | Ninguna | Ninguna |
| U05 | outsider | personal | no_owner | Ninguna | Ninguna |
| U05 | outsider | organization | normal | Ninguna | Ninguna |
| U05 | outsider | organization | suspended | Ninguna | Ninguna |
| U05 | outsider | organization | no_owner | Ninguna | Ninguna |
| U06 | organizer | personal | active | invite, organization | invite, organization |
| U06 | organizer | personal | no_owner | organization | organization |
| U06 | organizer | organization | active | invite, organization | invite, organization |
| U06 | organizer | organization | no_owner | organization | organization |
| U06 | candidate | personal | active | Ninguna | Ninguna |
| U06 | candidate | personal | no_owner | Ninguna | Ninguna |
| U06 | candidate | organization | active | Ninguna | Ninguna |
| U06 | candidate | organization | no_owner | Ninguna | Ninguna |
| U06 | member | personal | active | Ninguna | Ninguna |
| U06 | member | personal | no_owner | Ninguna | Ninguna |
| U06 | member | organization | active | Ninguna | Ninguna |
| U06 | member | organization | no_owner | Ninguna | Ninguna |
| U06 | editor | personal | active | Ninguna | Ninguna |
| U06 | editor | personal | no_owner | Ninguna | Ninguna |
| U06 | editor | organization | active | Ninguna | Ninguna |
| U06 | editor | organization | no_owner | Ninguna | Ninguna |
| U06 | related | personal | active | Ninguna | Ninguna |
| U06 | related | personal | no_owner | Ninguna | Ninguna |
| U06 | related | organization | active | Ninguna | Ninguna |
| U06 | related | organization | no_owner | Ninguna | Ninguna |
| U06 | outsider | personal | active | Ninguna | Ninguna |
| U06 | outsider | personal | no_owner | Ninguna | Ninguna |
| U06 | outsider | organization | active | Ninguna | Ninguna |
| U06 | outsider | organization | no_owner | Ninguna | Ninguna |
| U07 | organizer | personal | pending | Ninguna | Ninguna |
| U07 | organizer | personal | member_active | Ninguna | Ninguna |
| U07 | organizer | personal | expired | Ninguna | Ninguna |
| U07 | organizer | personal | rejected | Ninguna | Ninguna |
| U07 | organizer | organization | pending | Ninguna | Ninguna |
| U07 | organizer | organization | member_active | Ninguna | Ninguna |
| U07 | organizer | organization | expired | Ninguna | Ninguna |
| U07 | organizer | organization | rejected | Ninguna | Ninguna |
| U07 | candidate | personal | pending | accept_invite, reject_invite, organizations | accept_invite, reject_invite, organizations |
| U07 | candidate | personal | member_active | Ninguna | Ninguna |
| U07 | candidate | personal | expired | organizations | organizations |
| U07 | candidate | personal | rejected | organizations | organizations |
| U07 | candidate | organization | pending | accept_invite, reject_invite, organizations | accept_invite, reject_invite, organizations |
| U07 | candidate | organization | member_active | Ninguna | Ninguna |
| U07 | candidate | organization | expired | organizations | organizations |
| U07 | candidate | organization | rejected | organizations | organizations |
| U07 | member | personal | pending | Ninguna | Ninguna |
| U07 | member | personal | member_active | membership, organizations | membership, organizations |
| U07 | member | personal | expired | Ninguna | Ninguna |
| U07 | member | personal | rejected | Ninguna | Ninguna |
| U07 | member | organization | pending | Ninguna | Ninguna |
| U07 | member | organization | member_active | membership, organizations | membership, organizations |
| U07 | member | organization | expired | Ninguna | Ninguna |
| U07 | member | organization | rejected | Ninguna | Ninguna |
| U07 | editor | personal | pending | Ninguna | Ninguna |
| U07 | editor | personal | member_active | Ninguna | Ninguna |
| U07 | editor | personal | expired | Ninguna | Ninguna |
| U07 | editor | personal | rejected | Ninguna | Ninguna |
| U07 | editor | organization | pending | Ninguna | Ninguna |
| U07 | editor | organization | member_active | Ninguna | Ninguna |
| U07 | editor | organization | expired | Ninguna | Ninguna |
| U07 | editor | organization | rejected | Ninguna | Ninguna |
| U07 | related | personal | pending | accept_invite, reject_invite, organizations | accept_invite, reject_invite, organizations |
| U07 | related | personal | member_active | Ninguna | Ninguna |
| U07 | related | personal | expired | organizations | organizations |
| U07 | related | personal | rejected | organizations | organizations |
| U07 | related | organization | pending | accept_invite, reject_invite, organizations | accept_invite, reject_invite, organizations |
| U07 | related | organization | member_active | Ninguna | Ninguna |
| U07 | related | organization | expired | organizations | organizations |
| U07 | related | organization | rejected | organizations | organizations |
| U07 | outsider | personal | pending | Ninguna | Ninguna |
| U07 | outsider | personal | member_active | Ninguna | Ninguna |
| U07 | outsider | personal | expired | Ninguna | Ninguna |
| U07 | outsider | personal | rejected | Ninguna | Ninguna |
| U07 | outsider | organization | pending | Ninguna | Ninguna |
| U07 | outsider | organization | member_active | Ninguna | Ninguna |
| U07 | outsider | organization | expired | Ninguna | Ninguna |
| U07 | outsider | organization | rejected | Ninguna | Ninguna |
| U08 | organizer | personal | draft | publish, save, draft | publish, save, draft |
| U08 | organizer | personal | material | save, mission_revision, draft | save, mission_revision, draft |
| U08 | organizer | organization | draft | publish, save, draft | publish, save, draft |
| U08 | organizer | organization | material | save, mission_revision, draft | save, mission_revision, draft |
| U08 | candidate | personal | draft | publish, save, draft | publish, save, draft |
| U08 | candidate | personal | material | save, mission_revision, draft | save, mission_revision, draft |
| U08 | candidate | organization | draft | Ninguna | Ninguna |
| U08 | candidate | organization | material | Ninguna | Ninguna |
| U08 | member | personal | draft | publish, save, draft | publish, save, draft |
| U08 | member | personal | material | save, mission_revision, draft | save, mission_revision, draft |
| U08 | member | organization | draft | publish, save, draft | publish, save, draft |
| U08 | member | organization | material | save, mission_revision, draft | save, mission_revision, draft |
| U08 | editor | personal | draft | publish, save, draft | publish, save, draft |
| U08 | editor | personal | material | save, mission_revision, draft | save, mission_revision, draft |
| U08 | editor | organization | draft | publish, save, draft | publish, save, draft |
| U08 | editor | organization | material | save, mission_revision, draft | save, mission_revision, draft |
| U08 | related | personal | draft | publish, save, draft | publish, save, draft |
| U08 | related | personal | material | save, mission_revision, draft | save, mission_revision, draft |
| U08 | related | organization | draft | Ninguna | Ninguna |
| U08 | related | organization | material | Ninguna | Ninguna |
| U08 | outsider | personal | draft | Ninguna | Ninguna |
| U08 | outsider | personal | material | Ninguna | Ninguna |
| U08 | outsider | organization | draft | Ninguna | Ninguna |
| U08 | outsider | organization | material | Ninguna | Ninguna |
| U09 | organizer | personal | open | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | personal | closed | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | personal | cancelled | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | personal | full | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | personal | eligibility_pending | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | organization | open | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | organization | closed | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | organization | cancelled | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | organization | full | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | organizer | organization | eligibility_pending | manage, eligibility, legacy | manage, eligibility, legacy |
| U09 | candidate | personal | open | apply, legacy | apply, legacy |
| U09 | candidate | personal | closed | legacy | legacy |
| U09 | candidate | personal | cancelled | legacy | legacy |
| U09 | candidate | personal | full | legacy | legacy |
| U09 | candidate | personal | eligibility_pending | legacy | legacy |
| U09 | candidate | organization | open | apply, legacy | apply, legacy |
| U09 | candidate | organization | closed | legacy | legacy |
| U09 | candidate | organization | cancelled | legacy | legacy |
| U09 | candidate | organization | full | legacy | legacy |
| U09 | candidate | organization | eligibility_pending | legacy | legacy |
| U09 | member | personal | open | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | personal | closed | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | personal | cancelled | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | personal | full | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | personal | eligibility_pending | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | organization | open | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | organization | closed | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | organization | cancelled | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | organization | full | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | member | organization | eligibility_pending | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | personal | open | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | personal | closed | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | personal | cancelled | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | personal | full | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | personal | eligibility_pending | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | organization | open | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | organization | closed | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | organization | cancelled | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | organization | full | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | editor | organization | eligibility_pending | edit, eligibility, legacy | edit, eligibility, legacy |
| U09 | related | personal | open | apply, eligibility, legacy | apply, eligibility, legacy |
| U09 | related | personal | closed | eligibility, legacy | eligibility, legacy |
| U09 | related | personal | cancelled | eligibility, legacy | eligibility, legacy |
| U09 | related | personal | full | eligibility, legacy | eligibility, legacy |
| U09 | related | personal | eligibility_pending | eligibility, legacy | eligibility, legacy |
| U09 | related | organization | open | apply, eligibility, legacy | apply, eligibility, legacy |
| U09 | related | organization | closed | eligibility, legacy | eligibility, legacy |
| U09 | related | organization | cancelled | eligibility, legacy | eligibility, legacy |
| U09 | related | organization | full | eligibility, legacy | eligibility, legacy |
| U09 | related | organization | eligibility_pending | eligibility, legacy | eligibility, legacy |
| U09 | outsider | personal | open | legacy | legacy |
| U09 | outsider | personal | closed | legacy | legacy |
| U09 | outsider | personal | cancelled | legacy | legacy |
| U09 | outsider | personal | full | legacy | legacy |
| U09 | outsider | personal | eligibility_pending | legacy | legacy |
| U09 | outsider | organization | open | legacy | legacy |
| U09 | outsider | organization | closed | legacy | legacy |
| U09 | outsider | organization | cancelled | legacy | legacy |
| U09 | outsider | organization | full | legacy | legacy |
| U09 | outsider | organization | eligibility_pending | legacy | legacy |
| U10 | organizer | personal | eligible | Ninguna | Ninguna |
| U10 | organizer | personal | unavailable | Ninguna | Ninguna |
| U10 | organizer | organization | eligible | Ninguna | Ninguna |
| U10 | organizer | organization | unavailable | Ninguna | Ninguna |
| U10 | candidate | personal | eligible | apply, revision | apply, revision |
| U10 | candidate | personal | unavailable | revision | revision |
| U10 | candidate | organization | eligible | apply, revision | apply, revision |
| U10 | candidate | organization | unavailable | revision | revision |
| U10 | member | personal | eligible | Ninguna | Ninguna |
| U10 | member | personal | unavailable | Ninguna | Ninguna |
| U10 | member | organization | eligible | Ninguna | Ninguna |
| U10 | member | organization | unavailable | Ninguna | Ninguna |
| U10 | editor | personal | eligible | Ninguna | Ninguna |
| U10 | editor | personal | unavailable | Ninguna | Ninguna |
| U10 | editor | organization | eligible | Ninguna | Ninguna |
| U10 | editor | organization | unavailable | Ninguna | Ninguna |
| U10 | related | personal | eligible | apply, revision | apply, revision |
| U10 | related | personal | unavailable | revision | revision |
| U10 | related | organization | eligible | apply, revision | apply, revision |
| U10 | related | organization | unavailable | revision | revision |
| U10 | outsider | personal | eligible | Ninguna | Ninguna |
| U10 | outsider | personal | unavailable | Ninguna | Ninguna |
| U10 | outsider | organization | eligible | Ninguna | Ninguna |
| U10 | outsider | organization | unavailable | Ninguna | Ninguna |
| U11 | organizer | personal | sent | Ninguna | Ninguna |
| U11 | organizer | personal | shortlisted | Ninguna | Ninguna |
| U11 | organizer | personal | offer_pending | Ninguna | Ninguna |
| U11 | organizer | personal | revision_known | Ninguna | Ninguna |
| U11 | organizer | personal | expired | Ninguna | Ninguna |
| U11 | organizer | personal | resolved | Ninguna | Ninguna |
| U11 | organizer | organization | sent | Ninguna | Ninguna |
| U11 | organizer | organization | shortlisted | Ninguna | Ninguna |
| U11 | organizer | organization | offer_pending | Ninguna | Ninguna |
| U11 | organizer | organization | revision_known | Ninguna | Ninguna |
| U11 | organizer | organization | expired | Ninguna | Ninguna |
| U11 | organizer | organization | resolved | Ninguna | Ninguna |
| U11 | candidate | personal | sent | mission | mission |
| U11 | candidate | personal | shortlisted | mission | mission |
| U11 | candidate | personal | offer_pending | offer, mission | offer, mission |
| U11 | candidate | personal | revision_known | mission | mission |
| U11 | candidate | personal | expired | mission | mission |
| U11 | candidate | personal | resolved | mission | mission |
| U11 | candidate | organization | sent | mission | mission |
| U11 | candidate | organization | shortlisted | mission | mission |
| U11 | candidate | organization | offer_pending | offer, mission | offer, mission |
| U11 | candidate | organization | revision_known | mission | mission |
| U11 | candidate | organization | expired | mission | mission |
| U11 | candidate | organization | resolved | mission | mission |
| U11 | member | personal | sent | Ninguna | Ninguna |
| U11 | member | personal | shortlisted | Ninguna | Ninguna |
| U11 | member | personal | offer_pending | Ninguna | Ninguna |
| U11 | member | personal | revision_known | Ninguna | Ninguna |
| U11 | member | personal | expired | Ninguna | Ninguna |
| U11 | member | personal | resolved | Ninguna | Ninguna |
| U11 | member | organization | sent | Ninguna | Ninguna |
| U11 | member | organization | shortlisted | Ninguna | Ninguna |
| U11 | member | organization | offer_pending | Ninguna | Ninguna |
| U11 | member | organization | revision_known | Ninguna | Ninguna |
| U11 | member | organization | expired | Ninguna | Ninguna |
| U11 | member | organization | resolved | Ninguna | Ninguna |
| U11 | editor | personal | sent | Ninguna | Ninguna |
| U11 | editor | personal | shortlisted | Ninguna | Ninguna |
| U11 | editor | personal | offer_pending | Ninguna | Ninguna |
| U11 | editor | personal | revision_known | Ninguna | Ninguna |
| U11 | editor | personal | expired | Ninguna | Ninguna |
| U11 | editor | personal | resolved | Ninguna | Ninguna |
| U11 | editor | organization | sent | Ninguna | Ninguna |
| U11 | editor | organization | shortlisted | Ninguna | Ninguna |
| U11 | editor | organization | offer_pending | Ninguna | Ninguna |
| U11 | editor | organization | revision_known | Ninguna | Ninguna |
| U11 | editor | organization | expired | Ninguna | Ninguna |
| U11 | editor | organization | resolved | Ninguna | Ninguna |
| U11 | related | personal | sent | mission | mission |
| U11 | related | personal | shortlisted | mission | mission |
| U11 | related | personal | offer_pending | offer, mission | offer, mission |
| U11 | related | personal | revision_known | mission | mission |
| U11 | related | personal | expired | mission | mission |
| U11 | related | personal | resolved | mission | mission |
| U11 | related | organization | sent | mission | mission |
| U11 | related | organization | shortlisted | mission | mission |
| U11 | related | organization | offer_pending | offer, mission | offer, mission |
| U11 | related | organization | revision_known | mission | mission |
| U11 | related | organization | expired | mission | mission |
| U11 | related | organization | resolved | mission | mission |
| U11 | outsider | personal | sent | Ninguna | Ninguna |
| U11 | outsider | personal | shortlisted | Ninguna | Ninguna |
| U11 | outsider | personal | offer_pending | Ninguna | Ninguna |
| U11 | outsider | personal | revision_known | Ninguna | Ninguna |
| U11 | outsider | personal | expired | Ninguna | Ninguna |
| U11 | outsider | personal | resolved | Ninguna | Ninguna |
| U11 | outsider | organization | sent | Ninguna | Ninguna |
| U11 | outsider | organization | shortlisted | Ninguna | Ninguna |
| U11 | outsider | organization | offer_pending | Ninguna | Ninguna |
| U11 | outsider | organization | revision_known | Ninguna | Ninguna |
| U11 | outsider | organization | expired | Ninguna | Ninguna |
| U11 | outsider | organization | resolved | Ninguna | Ninguna |
| U12 | organizer | personal | available | prepare, status, mission | prepare, status, mission |
| U12 | organizer | personal | empty | mission | mission |
| U12 | organizer | personal | closed | mission | mission |
| U12 | organizer | personal | cancelled | mission | mission |
| U12 | organizer | organization | available | prepare, status, mission | prepare, status, mission |
| U12 | organizer | organization | empty | mission | mission |
| U12 | organizer | organization | closed | mission | mission |
| U12 | organizer | organization | cancelled | mission | mission |
| U12 | candidate | personal | available | Ninguna | Ninguna |
| U12 | candidate | personal | empty | Ninguna | Ninguna |
| U12 | candidate | personal | closed | Ninguna | Ninguna |
| U12 | candidate | personal | cancelled | Ninguna | Ninguna |
| U12 | candidate | organization | available | Ninguna | Ninguna |
| U12 | candidate | organization | empty | Ninguna | Ninguna |
| U12 | candidate | organization | closed | Ninguna | Ninguna |
| U12 | candidate | organization | cancelled | Ninguna | Ninguna |
| U12 | member | personal | available | Ninguna | Ninguna |
| U12 | member | personal | empty | Ninguna | Ninguna |
| U12 | member | personal | closed | Ninguna | Ninguna |
| U12 | member | personal | cancelled | Ninguna | Ninguna |
| U12 | member | organization | available | Ninguna | Ninguna |
| U12 | member | organization | empty | Ninguna | Ninguna |
| U12 | member | organization | closed | Ninguna | Ninguna |
| U12 | member | organization | cancelled | Ninguna | Ninguna |
| U12 | editor | personal | available | Ninguna | Ninguna |
| U12 | editor | personal | empty | Ninguna | Ninguna |
| U12 | editor | personal | closed | Ninguna | Ninguna |
| U12 | editor | personal | cancelled | Ninguna | Ninguna |
| U12 | editor | organization | available | Ninguna | Ninguna |
| U12 | editor | organization | empty | Ninguna | Ninguna |
| U12 | editor | organization | closed | Ninguna | Ninguna |
| U12 | editor | organization | cancelled | Ninguna | Ninguna |
| U12 | related | personal | available | Ninguna | Ninguna |
| U12 | related | personal | empty | Ninguna | Ninguna |
| U12 | related | personal | closed | Ninguna | Ninguna |
| U12 | related | personal | cancelled | Ninguna | Ninguna |
| U12 | related | organization | available | Ninguna | Ninguna |
| U12 | related | organization | empty | Ninguna | Ninguna |
| U12 | related | organization | closed | Ninguna | Ninguna |
| U12 | related | organization | cancelled | Ninguna | Ninguna |
| U12 | outsider | personal | available | Ninguna | Ninguna |
| U12 | outsider | personal | empty | Ninguna | Ninguna |
| U12 | outsider | personal | closed | Ninguna | Ninguna |
| U12 | outsider | personal | cancelled | Ninguna | Ninguna |
| U12 | outsider | organization | available | Ninguna | Ninguna |
| U12 | outsider | organization | empty | Ninguna | Ninguna |
| U12 | outsider | organization | closed | Ninguna | Ninguna |
| U12 | outsider | organization | cancelled | Ninguna | Ninguna |
| U13 | organizer | personal | available | issue, applications | issue, applications |
| U13 | organizer | personal | pending | existing_offer, applications | existing_offer, applications |
| U13 | organizer | personal | expired | existing_offer, eligibility, applications | existing_offer, eligibility, applications |
| U13 | organizer | personal | resolved | existing_offer, applications | existing_offer, applications |
| U13 | organizer | personal | unavailable | eligibility, applications | eligibility, applications |
| U13 | organizer | organization | available | issue, applications | issue, applications |
| U13 | organizer | organization | pending | existing_offer, applications | existing_offer, applications |
| U13 | organizer | organization | expired | existing_offer, eligibility, applications | existing_offer, eligibility, applications |
| U13 | organizer | organization | resolved | existing_offer, applications | existing_offer, applications |
| U13 | organizer | organization | unavailable | eligibility, applications | eligibility, applications |
| U13 | candidate | personal | available | Ninguna | Ninguna |
| U13 | candidate | personal | pending | Ninguna | Ninguna |
| U13 | candidate | personal | expired | Ninguna | Ninguna |
| U13 | candidate | personal | resolved | Ninguna | Ninguna |
| U13 | candidate | personal | unavailable | Ninguna | Ninguna |
| U13 | candidate | organization | available | Ninguna | Ninguna |
| U13 | candidate | organization | pending | Ninguna | Ninguna |
| U13 | candidate | organization | expired | Ninguna | Ninguna |
| U13 | candidate | organization | resolved | Ninguna | Ninguna |
| U13 | candidate | organization | unavailable | Ninguna | Ninguna |
| U13 | member | personal | available | Ninguna | Ninguna |
| U13 | member | personal | pending | Ninguna | Ninguna |
| U13 | member | personal | expired | Ninguna | Ninguna |
| U13 | member | personal | resolved | Ninguna | Ninguna |
| U13 | member | personal | unavailable | Ninguna | Ninguna |
| U13 | member | organization | available | Ninguna | Ninguna |
| U13 | member | organization | pending | Ninguna | Ninguna |
| U13 | member | organization | expired | Ninguna | Ninguna |
| U13 | member | organization | resolved | Ninguna | Ninguna |
| U13 | member | organization | unavailable | Ninguna | Ninguna |
| U13 | editor | personal | available | Ninguna | Ninguna |
| U13 | editor | personal | pending | Ninguna | Ninguna |
| U13 | editor | personal | expired | Ninguna | Ninguna |
| U13 | editor | personal | resolved | Ninguna | Ninguna |
| U13 | editor | personal | unavailable | Ninguna | Ninguna |
| U13 | editor | organization | available | Ninguna | Ninguna |
| U13 | editor | organization | pending | Ninguna | Ninguna |
| U13 | editor | organization | expired | Ninguna | Ninguna |
| U13 | editor | organization | resolved | Ninguna | Ninguna |
| U13 | editor | organization | unavailable | Ninguna | Ninguna |
| U13 | related | personal | available | Ninguna | Ninguna |
| U13 | related | personal | pending | Ninguna | Ninguna |
| U13 | related | personal | expired | Ninguna | Ninguna |
| U13 | related | personal | resolved | Ninguna | Ninguna |
| U13 | related | personal | unavailable | Ninguna | Ninguna |
| U13 | related | organization | available | Ninguna | Ninguna |
| U13 | related | organization | pending | Ninguna | Ninguna |
| U13 | related | organization | expired | Ninguna | Ninguna |
| U13 | related | organization | resolved | Ninguna | Ninguna |
| U13 | related | organization | unavailable | Ninguna | Ninguna |
| U13 | outsider | personal | available | Ninguna | Ninguna |
| U13 | outsider | personal | pending | Ninguna | Ninguna |
| U13 | outsider | personal | expired | Ninguna | Ninguna |
| U13 | outsider | personal | resolved | Ninguna | Ninguna |
| U13 | outsider | personal | unavailable | Ninguna | Ninguna |
| U13 | outsider | organization | available | Ninguna | Ninguna |
| U13 | outsider | organization | pending | Ninguna | Ninguna |
| U13 | outsider | organization | expired | Ninguna | Ninguna |
| U13 | outsider | organization | resolved | Ninguna | Ninguna |
| U13 | outsider | organization | unavailable | Ninguna | Ninguna |
| U14 | organizer | personal | pending | withdraw, applications | withdraw, applications |
| U14 | organizer | personal | expired | applications | applications |
| U14 | organizer | personal | accepted | agreement, applications | agreement, applications |
| U14 | organizer | personal | rejected | applications | applications |
| U14 | organizer | personal | cancelled | applications | applications |
| U14 | organizer | organization | pending | withdraw, applications | withdraw, applications |
| U14 | organizer | organization | expired | applications | applications |
| U14 | organizer | organization | accepted | agreement, applications | agreement, applications |
| U14 | organizer | organization | rejected | applications | applications |
| U14 | organizer | organization | cancelled | applications | applications |
| U14 | candidate | personal | pending | Ninguna | Ninguna |
| U14 | candidate | personal | expired | Ninguna | Ninguna |
| U14 | candidate | personal | accepted | Ninguna | Ninguna |
| U14 | candidate | personal | rejected | Ninguna | Ninguna |
| U14 | candidate | personal | cancelled | Ninguna | Ninguna |
| U14 | candidate | organization | pending | Ninguna | Ninguna |
| U14 | candidate | organization | expired | Ninguna | Ninguna |
| U14 | candidate | organization | accepted | Ninguna | Ninguna |
| U14 | candidate | organization | rejected | Ninguna | Ninguna |
| U14 | candidate | organization | cancelled | Ninguna | Ninguna |
| U14 | member | personal | pending | Ninguna | Ninguna |
| U14 | member | personal | expired | Ninguna | Ninguna |
| U14 | member | personal | accepted | Ninguna | Ninguna |
| U14 | member | personal | rejected | Ninguna | Ninguna |
| U14 | member | personal | cancelled | Ninguna | Ninguna |
| U14 | member | organization | pending | Ninguna | Ninguna |
| U14 | member | organization | expired | Ninguna | Ninguna |
| U14 | member | organization | accepted | Ninguna | Ninguna |
| U14 | member | organization | rejected | Ninguna | Ninguna |
| U14 | member | organization | cancelled | Ninguna | Ninguna |
| U14 | editor | personal | pending | Ninguna | Ninguna |
| U14 | editor | personal | expired | Ninguna | Ninguna |
| U14 | editor | personal | accepted | Ninguna | Ninguna |
| U14 | editor | personal | rejected | Ninguna | Ninguna |
| U14 | editor | personal | cancelled | Ninguna | Ninguna |
| U14 | editor | organization | pending | Ninguna | Ninguna |
| U14 | editor | organization | expired | Ninguna | Ninguna |
| U14 | editor | organization | accepted | Ninguna | Ninguna |
| U14 | editor | organization | rejected | Ninguna | Ninguna |
| U14 | editor | organization | cancelled | Ninguna | Ninguna |
| U14 | related | personal | pending | Ninguna | Ninguna |
| U14 | related | personal | expired | Ninguna | Ninguna |
| U14 | related | personal | accepted | Ninguna | Ninguna |
| U14 | related | personal | rejected | Ninguna | Ninguna |
| U14 | related | personal | cancelled | Ninguna | Ninguna |
| U14 | related | organization | pending | Ninguna | Ninguna |
| U14 | related | organization | expired | Ninguna | Ninguna |
| U14 | related | organization | accepted | Ninguna | Ninguna |
| U14 | related | organization | rejected | Ninguna | Ninguna |
| U14 | related | organization | cancelled | Ninguna | Ninguna |
| U14 | outsider | personal | pending | Ninguna | Ninguna |
| U14 | outsider | personal | expired | Ninguna | Ninguna |
| U14 | outsider | personal | accepted | Ninguna | Ninguna |
| U14 | outsider | personal | rejected | Ninguna | Ninguna |
| U14 | outsider | personal | cancelled | Ninguna | Ninguna |
| U14 | outsider | organization | pending | Ninguna | Ninguna |
| U14 | outsider | organization | expired | Ninguna | Ninguna |
| U14 | outsider | organization | accepted | Ninguna | Ninguna |
| U14 | outsider | organization | rejected | Ninguna | Ninguna |
| U14 | outsider | organization | cancelled | Ninguna | Ninguna |
| U15 | organizer | personal | pending | Ninguna | Ninguna |
| U15 | organizer | personal | expired | Ninguna | Ninguna |
| U15 | organizer | personal | accepted | Ninguna | Ninguna |
| U15 | organizer | personal | rejected | Ninguna | Ninguna |
| U15 | organizer | personal | cancelled | Ninguna | Ninguna |
| U15 | organizer | organization | pending | Ninguna | Ninguna |
| U15 | organizer | organization | expired | Ninguna | Ninguna |
| U15 | organizer | organization | accepted | Ninguna | Ninguna |
| U15 | organizer | organization | rejected | Ninguna | Ninguna |
| U15 | organizer | organization | cancelled | Ninguna | Ninguna |
| U15 | candidate | personal | pending | accept_offer, reject_offer, application | accept_offer, reject_offer, application |
| U15 | candidate | personal | expired | application | application |
| U15 | candidate | personal | accepted | agreement, application | agreement, application |
| U15 | candidate | personal | rejected | application | application |
| U15 | candidate | personal | cancelled | application | application |
| U15 | candidate | organization | pending | accept_offer, reject_offer, application | accept_offer, reject_offer, application |
| U15 | candidate | organization | expired | application | application |
| U15 | candidate | organization | accepted | agreement, application | agreement, application |
| U15 | candidate | organization | rejected | application | application |
| U15 | candidate | organization | cancelled | application | application |
| U15 | member | personal | pending | Ninguna | Ninguna |
| U15 | member | personal | expired | Ninguna | Ninguna |
| U15 | member | personal | accepted | Ninguna | Ninguna |
| U15 | member | personal | rejected | Ninguna | Ninguna |
| U15 | member | personal | cancelled | Ninguna | Ninguna |
| U15 | member | organization | pending | Ninguna | Ninguna |
| U15 | member | organization | expired | Ninguna | Ninguna |
| U15 | member | organization | accepted | Ninguna | Ninguna |
| U15 | member | organization | rejected | Ninguna | Ninguna |
| U15 | member | organization | cancelled | Ninguna | Ninguna |
| U15 | editor | personal | pending | Ninguna | Ninguna |
| U15 | editor | personal | expired | Ninguna | Ninguna |
| U15 | editor | personal | accepted | Ninguna | Ninguna |
| U15 | editor | personal | rejected | Ninguna | Ninguna |
| U15 | editor | personal | cancelled | Ninguna | Ninguna |
| U15 | editor | organization | pending | Ninguna | Ninguna |
| U15 | editor | organization | expired | Ninguna | Ninguna |
| U15 | editor | organization | accepted | Ninguna | Ninguna |
| U15 | editor | organization | rejected | Ninguna | Ninguna |
| U15 | editor | organization | cancelled | Ninguna | Ninguna |
| U15 | related | personal | pending | accept_offer, reject_offer, application | accept_offer, reject_offer, application |
| U15 | related | personal | expired | application | application |
| U15 | related | personal | accepted | agreement, application | agreement, application |
| U15 | related | personal | rejected | application | application |
| U15 | related | personal | cancelled | application | application |
| U15 | related | organization | pending | accept_offer, reject_offer, application | accept_offer, reject_offer, application |
| U15 | related | organization | expired | application | application |
| U15 | related | organization | accepted | agreement, application | agreement, application |
| U15 | related | organization | rejected | application | application |
| U15 | related | organization | cancelled | application | application |
| U15 | outsider | personal | pending | Ninguna | Ninguna |
| U15 | outsider | personal | expired | Ninguna | Ninguna |
| U15 | outsider | personal | accepted | Ninguna | Ninguna |
| U15 | outsider | personal | rejected | Ninguna | Ninguna |
| U15 | outsider | personal | cancelled | Ninguna | Ninguna |
| U15 | outsider | organization | pending | Ninguna | Ninguna |
| U15 | outsider | organization | expired | Ninguna | Ninguna |
| U15 | outsider | organization | accepted | Ninguna | Ninguna |
| U15 | outsider | organization | rejected | Ninguna | Ninguna |
| U15 | outsider | organization | cancelled | Ninguna | Ninguna |
| U16 | organizer | personal | active | propose, history, cancel_request, safety | propose, history, cancel_request, safety |
| U16 | organizer | personal | revision_pending | revision, history, cancel_request, safety | revision, history, cancel_request, safety |
| U16 | organizer | personal | terminated | history, safety | history, safety |
| U16 | organizer | personal | cancelled | history, safety | history, safety |
| U16 | organizer | organization | active | propose, history, cancel_request, safety | propose, history, cancel_request, safety |
| U16 | organizer | organization | revision_pending | revision, history, cancel_request, safety | revision, history, cancel_request, safety |
| U16 | organizer | organization | terminated | history, safety | history, safety |
| U16 | organizer | organization | cancelled | history, safety | history, safety |
| U16 | candidate | personal | active | propose, history, cancel_request, safety | propose, history, cancel_request, safety |
| U16 | candidate | personal | revision_pending | revision, history, cancel_request, safety | revision, history, cancel_request, safety |
| U16 | candidate | personal | terminated | history, safety | history, safety |
| U16 | candidate | personal | cancelled | history, safety | history, safety |
| U16 | candidate | organization | active | propose, history, cancel_request, safety | propose, history, cancel_request, safety |
| U16 | candidate | organization | revision_pending | revision, history, cancel_request, safety | revision, history, cancel_request, safety |
| U16 | candidate | organization | terminated | history, safety | history, safety |
| U16 | candidate | organization | cancelled | history, safety | history, safety |
| U16 | member | personal | active | safety | safety |
| U16 | member | personal | revision_pending | safety | safety |
| U16 | member | personal | terminated | safety | safety |
| U16 | member | personal | cancelled | safety | safety |
| U16 | member | organization | active | safety | safety |
| U16 | member | organization | revision_pending | safety | safety |
| U16 | member | organization | terminated | safety | safety |
| U16 | member | organization | cancelled | safety | safety |
| U16 | editor | personal | active | safety | safety |
| U16 | editor | personal | revision_pending | safety | safety |
| U16 | editor | personal | terminated | safety | safety |
| U16 | editor | personal | cancelled | safety | safety |
| U16 | editor | organization | active | safety | safety |
| U16 | editor | organization | revision_pending | safety | safety |
| U16 | editor | organization | terminated | safety | safety |
| U16 | editor | organization | cancelled | safety | safety |
| U16 | related | personal | active | propose, history, cancel_request, safety | propose, history, cancel_request, safety |
| U16 | related | personal | revision_pending | revision, history, cancel_request, safety | revision, history, cancel_request, safety |
| U16 | related | personal | terminated | history, safety | history, safety |
| U16 | related | personal | cancelled | history, safety | history, safety |
| U16 | related | organization | active | propose, history, cancel_request, safety | propose, history, cancel_request, safety |
| U16 | related | organization | revision_pending | revision, history, cancel_request, safety | revision, history, cancel_request, safety |
| U16 | related | organization | terminated | history, safety | history, safety |
| U16 | related | organization | cancelled | history, safety | history, safety |
| U16 | outsider | personal | active | safety | safety |
| U16 | outsider | personal | revision_pending | safety | safety |
| U16 | outsider | personal | terminated | safety | safety |
| U16 | outsider | personal | cancelled | safety | safety |
| U16 | outsider | organization | active | safety | safety |
| U16 | outsider | organization | revision_pending | safety | safety |
| U16 | outsider | organization | terminated | safety | safety |
| U16 | outsider | organization | cancelled | safety | safety |
| U17 | organizer | personal | pending | accept_revision, reject_revision, history, agreement | accept_revision, reject_revision, history, agreement |
| U17 | organizer | personal | signed | history, agreement | history, agreement |
| U17 | organizer | personal | expired | history, agreement | history, agreement |
| U17 | organizer | personal | rejected | history, agreement | history, agreement |
| U17 | organizer | personal | activated | history, agreement | history, agreement |
| U17 | organizer | personal | agreement_terminal | history, agreement | history, agreement |
| U17 | organizer | organization | pending | accept_revision, reject_revision, history, agreement | accept_revision, reject_revision, history, agreement |
| U17 | organizer | organization | signed | history, agreement | history, agreement |
| U17 | organizer | organization | expired | history, agreement | history, agreement |
| U17 | organizer | organization | rejected | history, agreement | history, agreement |
| U17 | organizer | organization | activated | history, agreement | history, agreement |
| U17 | organizer | organization | agreement_terminal | history, agreement | history, agreement |
| U17 | candidate | personal | pending | accept_revision, reject_revision, history, agreement | accept_revision, reject_revision, history, agreement |
| U17 | candidate | personal | signed | history, agreement | history, agreement |
| U17 | candidate | personal | expired | history, agreement | history, agreement |
| U17 | candidate | personal | rejected | history, agreement | history, agreement |
| U17 | candidate | personal | activated | history, agreement | history, agreement |
| U17 | candidate | personal | agreement_terminal | history, agreement | history, agreement |
| U17 | candidate | organization | pending | accept_revision, reject_revision, history, agreement | accept_revision, reject_revision, history, agreement |
| U17 | candidate | organization | signed | history, agreement | history, agreement |
| U17 | candidate | organization | expired | history, agreement | history, agreement |
| U17 | candidate | organization | rejected | history, agreement | history, agreement |
| U17 | candidate | organization | activated | history, agreement | history, agreement |
| U17 | candidate | organization | agreement_terminal | history, agreement | history, agreement |
| U17 | member | personal | pending | Ninguna | Ninguna |
| U17 | member | personal | signed | Ninguna | Ninguna |
| U17 | member | personal | expired | Ninguna | Ninguna |
| U17 | member | personal | rejected | Ninguna | Ninguna |
| U17 | member | personal | activated | Ninguna | Ninguna |
| U17 | member | personal | agreement_terminal | Ninguna | Ninguna |
| U17 | member | organization | pending | Ninguna | Ninguna |
| U17 | member | organization | signed | Ninguna | Ninguna |
| U17 | member | organization | expired | Ninguna | Ninguna |
| U17 | member | organization | rejected | Ninguna | Ninguna |
| U17 | member | organization | activated | Ninguna | Ninguna |
| U17 | member | organization | agreement_terminal | Ninguna | Ninguna |
| U17 | editor | personal | pending | Ninguna | Ninguna |
| U17 | editor | personal | signed | Ninguna | Ninguna |
| U17 | editor | personal | expired | Ninguna | Ninguna |
| U17 | editor | personal | rejected | Ninguna | Ninguna |
| U17 | editor | personal | activated | Ninguna | Ninguna |
| U17 | editor | personal | agreement_terminal | Ninguna | Ninguna |
| U17 | editor | organization | pending | Ninguna | Ninguna |
| U17 | editor | organization | signed | Ninguna | Ninguna |
| U17 | editor | organization | expired | Ninguna | Ninguna |
| U17 | editor | organization | rejected | Ninguna | Ninguna |
| U17 | editor | organization | activated | Ninguna | Ninguna |
| U17 | editor | organization | agreement_terminal | Ninguna | Ninguna |
| U17 | related | personal | pending | accept_revision, reject_revision, history, agreement | accept_revision, reject_revision, history, agreement |
| U17 | related | personal | signed | history, agreement | history, agreement |
| U17 | related | personal | expired | history, agreement | history, agreement |
| U17 | related | personal | rejected | history, agreement | history, agreement |
| U17 | related | personal | activated | history, agreement | history, agreement |
| U17 | related | personal | agreement_terminal | history, agreement | history, agreement |
| U17 | related | organization | pending | accept_revision, reject_revision, history, agreement | accept_revision, reject_revision, history, agreement |
| U17 | related | organization | signed | history, agreement | history, agreement |
| U17 | related | organization | expired | history, agreement | history, agreement |
| U17 | related | organization | rejected | history, agreement | history, agreement |
| U17 | related | organization | activated | history, agreement | history, agreement |
| U17 | related | organization | agreement_terminal | history, agreement | history, agreement |
| U17 | outsider | personal | pending | Ninguna | Ninguna |
| U17 | outsider | personal | signed | Ninguna | Ninguna |
| U17 | outsider | personal | expired | Ninguna | Ninguna |
| U17 | outsider | personal | rejected | Ninguna | Ninguna |
| U17 | outsider | personal | activated | Ninguna | Ninguna |
| U17 | outsider | personal | agreement_terminal | Ninguna | Ninguna |
| U17 | outsider | organization | pending | Ninguna | Ninguna |
| U17 | outsider | organization | signed | Ninguna | Ninguna |
| U17 | outsider | organization | expired | Ninguna | Ninguna |
| U17 | outsider | organization | rejected | Ninguna | Ninguna |
| U17 | outsider | organization | activated | Ninguna | Ninguna |
| U17 | outsider | organization | agreement_terminal | Ninguna | Ninguna |
| U18 | organizer | personal | active | agreement | agreement |
| U18 | organizer | personal | revision_pending | agreement | agreement |
| U18 | organizer | personal | terminated | agreement | agreement |
| U18 | organizer | personal | revised | agreement | agreement |
| U18 | organizer | organization | active | agreement | agreement |
| U18 | organizer | organization | revision_pending | agreement | agreement |
| U18 | organizer | organization | terminated | agreement | agreement |
| U18 | organizer | organization | revised | agreement | agreement |
| U18 | candidate | personal | active | agreement | agreement |
| U18 | candidate | personal | revision_pending | agreement | agreement |
| U18 | candidate | personal | terminated | agreement | agreement |
| U18 | candidate | personal | revised | agreement | agreement |
| U18 | candidate | organization | active | agreement | agreement |
| U18 | candidate | organization | revision_pending | agreement | agreement |
| U18 | candidate | organization | terminated | agreement | agreement |
| U18 | candidate | organization | revised | agreement | agreement |
| U18 | member | personal | active | Ninguna | Ninguna |
| U18 | member | personal | revision_pending | Ninguna | Ninguna |
| U18 | member | personal | terminated | Ninguna | Ninguna |
| U18 | member | personal | revised | Ninguna | Ninguna |
| U18 | member | organization | active | Ninguna | Ninguna |
| U18 | member | organization | revision_pending | Ninguna | Ninguna |
| U18 | member | organization | terminated | Ninguna | Ninguna |
| U18 | member | organization | revised | Ninguna | Ninguna |
| U18 | editor | personal | active | Ninguna | Ninguna |
| U18 | editor | personal | revision_pending | Ninguna | Ninguna |
| U18 | editor | personal | terminated | Ninguna | Ninguna |
| U18 | editor | personal | revised | Ninguna | Ninguna |
| U18 | editor | organization | active | Ninguna | Ninguna |
| U18 | editor | organization | revision_pending | Ninguna | Ninguna |
| U18 | editor | organization | terminated | Ninguna | Ninguna |
| U18 | editor | organization | revised | Ninguna | Ninguna |
| U18 | related | personal | active | agreement | agreement |
| U18 | related | personal | revision_pending | agreement | agreement |
| U18 | related | personal | terminated | agreement | agreement |
| U18 | related | personal | revised | agreement | agreement |
| U18 | related | organization | active | agreement | agreement |
| U18 | related | organization | revision_pending | agreement | agreement |
| U18 | related | organization | terminated | agreement | agreement |
| U18 | related | organization | revised | agreement | agreement |
| U18 | outsider | personal | active | Ninguna | Ninguna |
| U18 | outsider | personal | revision_pending | Ninguna | Ninguna |
| U18 | outsider | personal | terminated | Ninguna | Ninguna |
| U18 | outsider | personal | revised | Ninguna | Ninguna |
| U18 | outsider | organization | active | Ninguna | Ninguna |
| U18 | outsider | organization | revision_pending | Ninguna | Ninguna |
| U18 | outsider | organization | terminated | Ninguna | Ninguna |
| U18 | outsider | organization | revised | Ninguna | Ninguna |
| U19 | organizer | personal | available | request_cancel, agreement, safety | request_cancel, agreement, safety |
| U19 | organizer | personal | pending | request, agreement, safety | request, agreement, safety |
| U19 | organizer | personal | resolved | agreement, safety | agreement, safety |
| U19 | organizer | organization | available | request_cancel, agreement, safety | request_cancel, agreement, safety |
| U19 | organizer | organization | pending | request, agreement, safety | request, agreement, safety |
| U19 | organizer | organization | resolved | agreement, safety | agreement, safety |
| U19 | candidate | personal | available | request_cancel, agreement, safety | request_cancel, agreement, safety |
| U19 | candidate | personal | pending | request, agreement, safety | request, agreement, safety |
| U19 | candidate | personal | resolved | agreement, safety | agreement, safety |
| U19 | candidate | organization | available | request_cancel, agreement, safety | request_cancel, agreement, safety |
| U19 | candidate | organization | pending | request, agreement, safety | request, agreement, safety |
| U19 | candidate | organization | resolved | agreement, safety | agreement, safety |
| U19 | member | personal | available | safety | safety |
| U19 | member | personal | pending | safety | safety |
| U19 | member | personal | resolved | safety | safety |
| U19 | member | organization | available | safety | safety |
| U19 | member | organization | pending | safety | safety |
| U19 | member | organization | resolved | safety | safety |
| U19 | editor | personal | available | safety | safety |
| U19 | editor | personal | pending | safety | safety |
| U19 | editor | personal | resolved | safety | safety |
| U19 | editor | organization | available | safety | safety |
| U19 | editor | organization | pending | safety | safety |
| U19 | editor | organization | resolved | safety | safety |
| U19 | related | personal | available | request_cancel, agreement, safety | request_cancel, agreement, safety |
| U19 | related | personal | pending | request, agreement, safety | request, agreement, safety |
| U19 | related | personal | resolved | agreement, safety | agreement, safety |
| U19 | related | organization | available | request_cancel, agreement, safety | request_cancel, agreement, safety |
| U19 | related | organization | pending | request, agreement, safety | request, agreement, safety |
| U19 | related | organization | resolved | agreement, safety | agreement, safety |
| U19 | outsider | personal | available | safety | safety |
| U19 | outsider | personal | pending | safety | safety |
| U19 | outsider | personal | resolved | safety | safety |
| U19 | outsider | organization | available | safety | safety |
| U19 | outsider | organization | pending | safety | safety |
| U19 | outsider | organization | resolved | safety | safety |
| U20 | organizer | personal | available | stop, report, agreement | stop, report, agreement |
| U20 | organizer | personal | contract_sending | stop, report, agreement | stop, report, agreement |
| U20 | organizer | personal | safety_sending | agreement | agreement |
| U20 | organizer | personal | recorded | case, agreement | case, agreement |
| U20 | organizer | organization | available | stop, report, agreement | stop, report, agreement |
| U20 | organizer | organization | contract_sending | stop, report, agreement | stop, report, agreement |
| U20 | organizer | organization | safety_sending | agreement | agreement |
| U20 | organizer | organization | recorded | case, agreement | case, agreement |
| U20 | candidate | personal | available | stop, report, agreement | stop, report, agreement |
| U20 | candidate | personal | contract_sending | stop, report, agreement | stop, report, agreement |
| U20 | candidate | personal | safety_sending | agreement | agreement |
| U20 | candidate | personal | recorded | case, agreement | case, agreement |
| U20 | candidate | organization | available | stop, report, agreement | stop, report, agreement |
| U20 | candidate | organization | contract_sending | stop, report, agreement | stop, report, agreement |
| U20 | candidate | organization | safety_sending | agreement | agreement |
| U20 | candidate | organization | recorded | case, agreement | case, agreement |
| U20 | member | personal | available | Ninguna | Ninguna |
| U20 | member | personal | contract_sending | Ninguna | Ninguna |
| U20 | member | personal | safety_sending | Ninguna | Ninguna |
| U20 | member | personal | recorded | Ninguna | Ninguna |
| U20 | member | organization | available | Ninguna | Ninguna |
| U20 | member | organization | contract_sending | Ninguna | Ninguna |
| U20 | member | organization | safety_sending | Ninguna | Ninguna |
| U20 | member | organization | recorded | Ninguna | Ninguna |
| U20 | editor | personal | available | Ninguna | Ninguna |
| U20 | editor | personal | contract_sending | Ninguna | Ninguna |
| U20 | editor | personal | safety_sending | Ninguna | Ninguna |
| U20 | editor | personal | recorded | Ninguna | Ninguna |
| U20 | editor | organization | available | Ninguna | Ninguna |
| U20 | editor | organization | contract_sending | Ninguna | Ninguna |
| U20 | editor | organization | safety_sending | Ninguna | Ninguna |
| U20 | editor | organization | recorded | Ninguna | Ninguna |
| U20 | related | personal | available | stop, report, agreement | stop, report, agreement |
| U20 | related | personal | contract_sending | stop, report, agreement | stop, report, agreement |
| U20 | related | personal | safety_sending | agreement | agreement |
| U20 | related | personal | recorded | case, agreement | case, agreement |
| U20 | related | organization | available | stop, report, agreement | stop, report, agreement |
| U20 | related | organization | contract_sending | stop, report, agreement | stop, report, agreement |
| U20 | related | organization | safety_sending | agreement | agreement |
| U20 | related | organization | recorded | case, agreement | case, agreement |
| U20 | outsider | personal | available | Ninguna | Ninguna |
| U20 | outsider | personal | contract_sending | Ninguna | Ninguna |
| U20 | outsider | personal | safety_sending | Ninguna | Ninguna |
| U20 | outsider | personal | recorded | Ninguna | Ninguna |
| U20 | outsider | organization | available | Ninguna | Ninguna |
| U20 | outsider | organization | contract_sending | Ninguna | Ninguna |
| U20 | outsider | organization | safety_sending | Ninguna | Ninguna |
| U20 | outsider | organization | recorded | Ninguna | Ninguna |
| U21 | organizer | personal | unconfirmed | case_status, agreement, safety | case_status, agreement, safety |
| U21 | organizer | personal | received | case_status, agreement, safety | case_status, agreement, safety |
| U21 | organizer | personal | resolved | case_status, agreement, safety | case_status, agreement, safety |
| U21 | organizer | organization | unconfirmed | case_status, agreement, safety | case_status, agreement, safety |
| U21 | organizer | organization | received | case_status, agreement, safety | case_status, agreement, safety |
| U21 | organizer | organization | resolved | case_status, agreement, safety | case_status, agreement, safety |
| U21 | candidate | personal | unconfirmed | case_status, agreement, safety | case_status, agreement, safety |
| U21 | candidate | personal | received | case_status, agreement, safety | case_status, agreement, safety |
| U21 | candidate | personal | resolved | case_status, agreement, safety | case_status, agreement, safety |
| U21 | candidate | organization | unconfirmed | case_status, agreement, safety | case_status, agreement, safety |
| U21 | candidate | organization | received | case_status, agreement, safety | case_status, agreement, safety |
| U21 | candidate | organization | resolved | case_status, agreement, safety | case_status, agreement, safety |
| U21 | member | personal | unconfirmed | safety | safety |
| U21 | member | personal | received | safety | safety |
| U21 | member | personal | resolved | safety | safety |
| U21 | member | organization | unconfirmed | safety | safety |
| U21 | member | organization | received | safety | safety |
| U21 | member | organization | resolved | safety | safety |
| U21 | editor | personal | unconfirmed | safety | safety |
| U21 | editor | personal | received | safety | safety |
| U21 | editor | personal | resolved | safety | safety |
| U21 | editor | organization | unconfirmed | safety | safety |
| U21 | editor | organization | received | safety | safety |
| U21 | editor | organization | resolved | safety | safety |
| U21 | related | personal | unconfirmed | case_status, agreement, safety | case_status, agreement, safety |
| U21 | related | personal | received | case_status, agreement, safety | case_status, agreement, safety |
| U21 | related | personal | resolved | case_status, agreement, safety | case_status, agreement, safety |
| U21 | related | organization | unconfirmed | case_status, agreement, safety | case_status, agreement, safety |
| U21 | related | organization | received | case_status, agreement, safety | case_status, agreement, safety |
| U21 | related | organization | resolved | case_status, agreement, safety | case_status, agreement, safety |
| U21 | outsider | personal | unconfirmed | safety | safety |
| U21 | outsider | personal | received | safety | safety |
| U21 | outsider | personal | resolved | safety | safety |
| U21 | outsider | organization | unconfirmed | safety | safety |
| U21 | outsider | organization | received | safety | safety |
| U21 | outsider | organization | resolved | safety | safety |
| U22 | organizer | personal | available | revision, cancellation | revision, cancellation |
| U22 | organizer | personal | empty | Ninguna | Ninguna |
| U22 | organizer | organization | available | revision, cancellation | revision, cancellation |
| U22 | organizer | organization | empty | Ninguna | Ninguna |
| U22 | candidate | personal | available | offer, revision, cancellation | offer, revision, cancellation |
| U22 | candidate | personal | empty | Ninguna | Ninguna |
| U22 | candidate | organization | available | offer, revision, cancellation | offer, revision, cancellation |
| U22 | candidate | organization | empty | Ninguna | Ninguna |
| U22 | member | personal | available | Ninguna | Ninguna |
| U22 | member | personal | empty | Ninguna | Ninguna |
| U22 | member | organization | available | Ninguna | Ninguna |
| U22 | member | organization | empty | Ninguna | Ninguna |
| U22 | editor | personal | available | Ninguna | Ninguna |
| U22 | editor | personal | empty | Ninguna | Ninguna |
| U22 | editor | organization | available | Ninguna | Ninguna |
| U22 | editor | organization | empty | Ninguna | Ninguna |
| U22 | related | personal | available | offer, revision, cancellation | offer, revision, cancellation |
| U22 | related | personal | empty | Ninguna | Ninguna |
| U22 | related | organization | available | offer, revision, cancellation | offer, revision, cancellation |
| U22 | related | organization | empty | Ninguna | Ninguna |
| U22 | outsider | personal | available | Ninguna | Ninguna |
| U22 | outsider | personal | empty | Ninguna | Ninguna |
| U22 | outsider | organization | available | Ninguna | Ninguna |
| U22 | outsider | organization | empty | Ninguna | Ninguna |
| U23 | organizer | personal | review | mission, update | mission, update |
| U23 | organizer | organization | review | mission, update | mission, update |
| U23 | candidate | personal | review | mission, update | mission, update |
| U23 | candidate | organization | review | mission, update | mission, update |
| U23 | member | personal | review | mission, update | mission, update |
| U23 | member | organization | review | mission, update | mission, update |
| U23 | editor | personal | review | mission, update | mission, update |
| U23 | editor | organization | review | mission, update | mission, update |
| U23 | related | personal | review | mission, update | mission, update |
| U23 | related | organization | review | mission, update | mission, update |
| U23 | outsider | personal | review | Ninguna | Ninguna |
| U23 | outsider | organization | review | Ninguna | Ninguna |
| U24 | organizer | personal | incompatible | missions, safety | missions, safety |
| U24 | organizer | organization | incompatible | missions, safety | missions, safety |
| U24 | candidate | personal | incompatible | missions, safety | missions, safety |
| U24 | candidate | organization | incompatible | missions, safety | missions, safety |
| U24 | member | personal | incompatible | missions, safety | missions, safety |
| U24 | member | organization | incompatible | missions, safety | missions, safety |
| U24 | editor | personal | incompatible | missions, safety | missions, safety |
| U24 | editor | organization | incompatible | missions, safety | missions, safety |
| U24 | related | personal | incompatible | missions, safety | missions, safety |
| U24 | related | organization | incompatible | missions, safety | missions, safety |
| U24 | outsider | personal | incompatible | missions, safety | missions, safety |
| U24 | outsider | organization | incompatible | missions, safety | missions, safety |
| U25 | organizer | personal | requested | accept_cancel, reject_cancel, agreement, safety | accept_cancel, reject_cancel, agreement, safety |
| U25 | organizer | personal | rejected | agreement, safety | agreement, safety |
| U25 | organizer | personal | completed | agreement, safety | agreement, safety |
| U25 | organizer | personal | withdrawn | agreement, safety | agreement, safety |
| U25 | organizer | personal | requester | agreement, safety | agreement, safety |
| U25 | organizer | organization | requested | accept_cancel, reject_cancel, agreement, safety | accept_cancel, reject_cancel, agreement, safety |
| U25 | organizer | organization | rejected | agreement, safety | agreement, safety |
| U25 | organizer | organization | completed | agreement, safety | agreement, safety |
| U25 | organizer | organization | withdrawn | agreement, safety | agreement, safety |
| U25 | organizer | organization | requester | agreement, safety | agreement, safety |
| U25 | candidate | personal | requested | accept_cancel, reject_cancel, agreement, safety | accept_cancel, reject_cancel, agreement, safety |
| U25 | candidate | personal | rejected | agreement, safety | agreement, safety |
| U25 | candidate | personal | completed | agreement, safety | agreement, safety |
| U25 | candidate | personal | withdrawn | agreement, safety | agreement, safety |
| U25 | candidate | personal | requester | agreement, safety | agreement, safety |
| U25 | candidate | organization | requested | accept_cancel, reject_cancel, agreement, safety | accept_cancel, reject_cancel, agreement, safety |
| U25 | candidate | organization | rejected | agreement, safety | agreement, safety |
| U25 | candidate | organization | completed | agreement, safety | agreement, safety |
| U25 | candidate | organization | withdrawn | agreement, safety | agreement, safety |
| U25 | candidate | organization | requester | agreement, safety | agreement, safety |
| U25 | member | personal | requested | safety | safety |
| U25 | member | personal | rejected | safety | safety |
| U25 | member | personal | completed | safety | safety |
| U25 | member | personal | withdrawn | safety | safety |
| U25 | member | personal | requester | safety | safety |
| U25 | member | organization | requested | safety | safety |
| U25 | member | organization | rejected | safety | safety |
| U25 | member | organization | completed | safety | safety |
| U25 | member | organization | withdrawn | safety | safety |
| U25 | member | organization | requester | safety | safety |
| U25 | editor | personal | requested | safety | safety |
| U25 | editor | personal | rejected | safety | safety |
| U25 | editor | personal | completed | safety | safety |
| U25 | editor | personal | withdrawn | safety | safety |
| U25 | editor | personal | requester | safety | safety |
| U25 | editor | organization | requested | safety | safety |
| U25 | editor | organization | rejected | safety | safety |
| U25 | editor | organization | completed | safety | safety |
| U25 | editor | organization | withdrawn | safety | safety |
| U25 | editor | organization | requester | safety | safety |
| U25 | related | personal | requested | accept_cancel, reject_cancel, agreement, safety | accept_cancel, reject_cancel, agreement, safety |
| U25 | related | personal | rejected | agreement, safety | agreement, safety |
| U25 | related | personal | completed | agreement, safety | agreement, safety |
| U25 | related | personal | withdrawn | agreement, safety | agreement, safety |
| U25 | related | personal | requester | agreement, safety | agreement, safety |
| U25 | related | organization | requested | accept_cancel, reject_cancel, agreement, safety | accept_cancel, reject_cancel, agreement, safety |
| U25 | related | organization | rejected | agreement, safety | agreement, safety |
| U25 | related | organization | completed | agreement, safety | agreement, safety |
| U25 | related | organization | withdrawn | agreement, safety | agreement, safety |
| U25 | related | organization | requester | agreement, safety | agreement, safety |
| U25 | outsider | personal | requested | safety | safety |
| U25 | outsider | personal | rejected | safety | safety |
| U25 | outsider | personal | completed | safety | safety |
| U25 | outsider | personal | withdrawn | safety | safety |
| U25 | outsider | personal | requester | safety | safety |
| U25 | outsider | organization | requested | safety | safety |
| U25 | outsider | organization | rejected | safety | safety |
| U25 | outsider | organization | completed | safety | safety |
| U25 | outsider | organization | withdrawn | safety | safety |
| U25 | outsider | organization | requester | safety | safety |
| U26 | organizer | personal | pending | Ninguna | Ninguna |
| U26 | organizer | personal | conflict | Ninguna | Ninguna |
| U26 | organizer | personal | expired | Ninguna | Ninguna |
| U26 | organizer | personal | acknowledged | Ninguna | Ninguna |
| U26 | organizer | personal | current | Ninguna | Ninguna |
| U26 | organizer | organization | pending | Ninguna | Ninguna |
| U26 | organizer | organization | conflict | Ninguna | Ninguna |
| U26 | organizer | organization | expired | Ninguna | Ninguna |
| U26 | organizer | organization | acknowledged | Ninguna | Ninguna |
| U26 | organizer | organization | current | Ninguna | Ninguna |
| U26 | candidate | personal | pending | acknowledge, application | acknowledge, application |
| U26 | candidate | personal | conflict | current_revision, application | current_revision, application |
| U26 | candidate | personal | expired | application | application |
| U26 | candidate | personal | acknowledged | application | application |
| U26 | candidate | personal | current | application | application |
| U26 | candidate | organization | pending | acknowledge, application | acknowledge, application |
| U26 | candidate | organization | conflict | current_revision, application | current_revision, application |
| U26 | candidate | organization | expired | application | application |
| U26 | candidate | organization | acknowledged | application | application |
| U26 | candidate | organization | current | application | application |
| U26 | member | personal | pending | Ninguna | Ninguna |
| U26 | member | personal | conflict | Ninguna | Ninguna |
| U26 | member | personal | expired | Ninguna | Ninguna |
| U26 | member | personal | acknowledged | Ninguna | Ninguna |
| U26 | member | personal | current | Ninguna | Ninguna |
| U26 | member | organization | pending | Ninguna | Ninguna |
| U26 | member | organization | conflict | Ninguna | Ninguna |
| U26 | member | organization | expired | Ninguna | Ninguna |
| U26 | member | organization | acknowledged | Ninguna | Ninguna |
| U26 | member | organization | current | Ninguna | Ninguna |
| U26 | editor | personal | pending | Ninguna | Ninguna |
| U26 | editor | personal | conflict | Ninguna | Ninguna |
| U26 | editor | personal | expired | Ninguna | Ninguna |
| U26 | editor | personal | acknowledged | Ninguna | Ninguna |
| U26 | editor | personal | current | Ninguna | Ninguna |
| U26 | editor | organization | pending | Ninguna | Ninguna |
| U26 | editor | organization | conflict | Ninguna | Ninguna |
| U26 | editor | organization | expired | Ninguna | Ninguna |
| U26 | editor | organization | acknowledged | Ninguna | Ninguna |
| U26 | editor | organization | current | Ninguna | Ninguna |
| U26 | related | personal | pending | acknowledge, application | acknowledge, application |
| U26 | related | personal | conflict | current_revision, application | current_revision, application |
| U26 | related | personal | expired | application | application |
| U26 | related | personal | acknowledged | application | application |
| U26 | related | personal | current | application | application |
| U26 | related | organization | pending | acknowledge, application | acknowledge, application |
| U26 | related | organization | conflict | current_revision, application | current_revision, application |
| U26 | related | organization | expired | application | application |
| U26 | related | organization | acknowledged | application | application |
| U26 | related | organization | current | application | application |
| U26 | outsider | personal | pending | Ninguna | Ninguna |
| U26 | outsider | personal | conflict | Ninguna | Ninguna |
| U26 | outsider | personal | expired | Ninguna | Ninguna |
| U26 | outsider | personal | acknowledged | Ninguna | Ninguna |
| U26 | outsider | personal | current | Ninguna | Ninguna |
| U26 | outsider | organization | pending | Ninguna | Ninguna |
| U26 | outsider | organization | conflict | Ninguna | Ninguna |
| U26 | outsider | organization | expired | Ninguna | Ninguna |
| U26 | outsider | organization | acknowledged | Ninguna | Ninguna |
| U26 | outsider | organization | current | Ninguna | Ninguna |
| U27 | organizer | personal | open | close, cancel, agreements | close, cancel, agreements |
| U27 | organizer | personal | closed | cancel, agreements | cancel, agreements |
| U27 | organizer | personal | cancelled | agreements | agreements |
| U27 | organizer | organization | open | close, cancel, agreements | close, cancel, agreements |
| U27 | organizer | organization | closed | cancel, agreements | cancel, agreements |
| U27 | organizer | organization | cancelled | agreements | agreements |
| U27 | candidate | personal | open | Ninguna | Ninguna |
| U27 | candidate | personal | closed | Ninguna | Ninguna |
| U27 | candidate | personal | cancelled | Ninguna | Ninguna |
| U27 | candidate | organization | open | Ninguna | Ninguna |
| U27 | candidate | organization | closed | Ninguna | Ninguna |
| U27 | candidate | organization | cancelled | Ninguna | Ninguna |
| U27 | member | personal | open | Ninguna | Ninguna |
| U27 | member | personal | closed | Ninguna | Ninguna |
| U27 | member | personal | cancelled | Ninguna | Ninguna |
| U27 | member | organization | open | Ninguna | Ninguna |
| U27 | member | organization | closed | Ninguna | Ninguna |
| U27 | member | organization | cancelled | Ninguna | Ninguna |
| U27 | editor | personal | open | Ninguna | Ninguna |
| U27 | editor | personal | closed | Ninguna | Ninguna |
| U27 | editor | personal | cancelled | Ninguna | Ninguna |
| U27 | editor | organization | open | Ninguna | Ninguna |
| U27 | editor | organization | closed | Ninguna | Ninguna |
| U27 | editor | organization | cancelled | Ninguna | Ninguna |
| U27 | related | personal | open | Ninguna | Ninguna |
| U27 | related | personal | closed | Ninguna | Ninguna |
| U27 | related | personal | cancelled | Ninguna | Ninguna |
| U27 | related | organization | open | Ninguna | Ninguna |
| U27 | related | organization | closed | Ninguna | Ninguna |
| U27 | related | organization | cancelled | Ninguna | Ninguna |
| U27 | outsider | personal | open | Ninguna | Ninguna |
| U27 | outsider | personal | closed | Ninguna | Ninguna |
| U27 | outsider | personal | cancelled | Ninguna | Ninguna |
| U27 | outsider | organization | open | Ninguna | Ninguna |
| U27 | outsider | organization | closed | Ninguna | Ninguna |
| U27 | outsider | organization | cancelled | Ninguna | Ninguna |
| U28 | organizer | personal | local | edit, missions | edit, missions |
| U28 | organizer | personal | server | edit, missions | edit, missions |
| U28 | organizer | personal | conflict | edit, missions | edit, missions |
| U28 | organizer | organization | local | edit, missions | edit, missions |
| U28 | organizer | organization | server | edit, missions | edit, missions |
| U28 | organizer | organization | conflict | edit, missions | edit, missions |
| U28 | candidate | personal | local | edit, missions | edit, missions |
| U28 | candidate | personal | server | edit, missions | edit, missions |
| U28 | candidate | personal | conflict | edit, missions | edit, missions |
| U28 | candidate | organization | local | Ninguna | Ninguna |
| U28 | candidate | organization | server | Ninguna | Ninguna |
| U28 | candidate | organization | conflict | Ninguna | Ninguna |
| U28 | member | personal | local | edit, missions | edit, missions |
| U28 | member | personal | server | edit, missions | edit, missions |
| U28 | member | personal | conflict | edit, missions | edit, missions |
| U28 | member | organization | local | edit, missions | edit, missions |
| U28 | member | organization | server | edit, missions | edit, missions |
| U28 | member | organization | conflict | edit, missions | edit, missions |
| U28 | editor | personal | local | edit, missions | edit, missions |
| U28 | editor | personal | server | edit, missions | edit, missions |
| U28 | editor | personal | conflict | edit, missions | edit, missions |
| U28 | editor | organization | local | edit, missions | edit, missions |
| U28 | editor | organization | server | edit, missions | edit, missions |
| U28 | editor | organization | conflict | edit, missions | edit, missions |
| U28 | related | personal | local | edit, missions | edit, missions |
| U28 | related | personal | server | edit, missions | edit, missions |
| U28 | related | personal | conflict | edit, missions | edit, missions |
| U28 | related | organization | local | Ninguna | Ninguna |
| U28 | related | organization | server | Ninguna | Ninguna |
| U28 | related | organization | conflict | Ninguna | Ninguna |
| U28 | outsider | personal | local | Ninguna | Ninguna |
| U28 | outsider | personal | server | Ninguna | Ninguna |
| U28 | outsider | personal | conflict | Ninguna | Ninguna |
| U28 | outsider | organization | local | Ninguna | Ninguna |
| U28 | outsider | organization | server | Ninguna | Ninguna |
| U28 | outsider | organization | conflict | Ninguna | Ninguna |

## Etiquetas, intención y destino

| Pantalla | Acción | Texto | Intención | Destino tras resultado autorizado | Consentimiento |
|---|---|---|---|---|---|
| U01 | detail | Ver misión | consult | U09 | No es aceptación contractual |
| U01 | create | Crear misión | consult | U02 | No es aceptación contractual |
| U01 | notices | Ver avisos | consult | U22 | No es aceptación contractual |
| U02 | personal | Continuar como persona | context | U08 | No es aceptación contractual |
| U02 | organization | Continuar por Colectivo Río | context | U08 | No es aceptación contractual |
| U02 | organizations | Gestionar organizaciones | consult | U03 | No es aceptación contractual |
| U03 | create_org | Crear organización | consult | U04 | No es aceptación contractual |
| U03 | organization | Ver organización | consult | U05 | No es aceptación contractual |
| U03 | invitation | Consultar invitación separada | consult | U07 | No es aceptación contractual |
| U04 | create_org | Crear organización | accept | U05 | Expreso, versión actual |
| U05 | members | Consultar miembros | consult | U06 | No es aceptación contractual |
| U05 | manage | Gestionar misión | consult | U12 | No es aceptación contractual |
| U05 | create | Crear por la organización | context | U02 | No es aceptación contractual |
| U06 | invite | Preparar invitación | consult | U07 | No es aceptación contractual |
| U06 | organization | Consultar organización | consult | U05 | No es aceptación contractual |
| U07 | accept_invite | Aceptar invitación | accept | U05 | Expreso, versión actual |
| U07 | reject_invite | Rechazar invitación | reject | U03 | No es aceptación contractual |
| U07 | membership | Consultar membresía vigente | consult | U05 | No es aceptación contractual |
| U07 | organizations | Volver a organizaciones | consult | U03 | No es aceptación contractual |
| U08 | publish | Publicar misión | accept | U09 | No es aceptación contractual |
| U08 | save | Guardar borrador en servidor | write | U28 | No es aceptación contractual |
| U08 | mission_revision | Revisar edición de misión | consult | U09 | No es aceptación contractual |
| U08 | draft | Consultar borrador | consult | U28 | No es aceptación contractual |
| U09 | apply | Postular personalmente | context | U10 | No es aceptación contractual |
| U09 | manage | Gestionar como organizador | consult | U12 | No es aceptación contractual |
| U09 | edit | Administrar contenido de misión | consult | U08 | No es aceptación contractual |
| U09 | eligibility | Consultar elegibilidad de persona vinculada | query | U09 | No es aceptación contractual |
| U09 | legacy | Consultar histórico legado | consult | U23 | No es aceptación contractual |
| U10 | apply | Enviar candidatura | accept | U11 | Expreso, versión actual |
| U10 | revision | Consultar revisión de misión | consult | U26 | No es aceptación contractual |
| U11 | offer | Consultar oferta | consult | U15 | No es aceptación contractual |
| U11 | mission | Volver a misión | consult | U09 | No es aceptación contractual |
| U12 | prepare | Revisar oferta para Lucía | consult | U13 | No es aceptación contractual |
| U12 | status | Cerrar o cancelar misión | consult | U27 | No es aceptación contractual |
| U12 | mission | Volver a misión | consult | U09 | No es aceptación contractual |
| U13 | issue | Enviar oferta y aceptar estas condiciones | accept | U14 | Expreso, versión actual |
| U13 | existing_offer | Consultar oferta previa | consult | U14 | No es aceptación contractual |
| U13 | eligibility | Consultar candidatura y cupo actuales | query | U12 | No es aceptación contractual |
| U13 | applications | Volver a candidaturas | consult | U12 | No es aceptación contractual |
| U14 | withdraw | Retirar oferta pendiente | cancel | U14 | Expreso, versión actual |
| U14 | agreement | Consultar acuerdo vinculado | consult | U16 | No es aceptación contractual |
| U14 | applications | Volver a candidaturas | consult | U12 | No es aceptación contractual |
| U15 | accept_offer | Aceptar oferta | accept | U16 | Expreso, versión actual |
| U15 | reject_offer | Rechazar oferta | reject | U11 | No es aceptación contractual |
| U15 | agreement | Consultar acuerdo vinculado | consult | U16 | No es aceptación contractual |
| U15 | application | Volver a candidatura | consult | U11 | No es aceptación contractual |
| U16 | propose | Proponer cambios de acuerdo | context | U17 | No es aceptación contractual |
| U16 | revision | Consultar propuesta pendiente | consult | U17 | No es aceptación contractual |
| U16 | history | Ver historial | consult | U18 | No es aceptación contractual |
| U16 | cancel_request | Solicitar cancelación | context | U19 | No es aceptación contractual |
| U16 | safety | Participación y seguridad | protection | U20 | No es aceptación contractual |
| U17 | accept_revision | Aceptar cambios por mi parte | accept | U16 | Expreso, versión actual |
| U17 | reject_revision | Rechazar propuesta y conservar v1 | reject | U16 | No es aceptación contractual |
| U17 | history | Ver versiones | consult | U18 | No es aceptación contractual |
| U17 | agreement | Consultar acuerdo | consult | U16 | No es aceptación contractual |
| U18 | agreement | Volver al acuerdo | consult | U16 | No es aceptación contractual |
| U19 | request_cancel | Enviar solicitud de cancelación | cancel | U25 | Expreso, versión actual |
| U19 | request | Consultar solicitud existente | consult | U25 | No es aceptación contractual |
| U19 | agreement | Consultar acuerdo | consult | U16 | No es aceptación contractual |
| U19 | safety | Acciones de seguridad | protection | U20 | No es aceptación contractual |
| U20 | stop | Detener participación y solicitar registro | safety | U21 | No es aceptación contractual |
| U20 | report | Bloquear contacto y solicitar reporte | safety | U21 | No es aceptación contractual |
| U20 | case | Consultar seguimiento | consult | U21 | No es aceptación contractual |
| U20 | agreement | Consultar acuerdo | consult | U16 | No es aceptación contractual |
| U21 | case_status | Consultar estado del caso | query | U21 | No es aceptación contractual |
| U21 | agreement | Consultar acuerdo | consult | U16 | No es aceptación contractual |
| U21 | safety | Protección personal | protection | U20 | No es aceptación contractual |
| U22 | offer | Consultar oferta | consult | U15 | No es aceptación contractual |
| U22 | revision | Consultar cambios | consult | U17 | No es aceptación contractual |
| U22 | cancellation | Consultar cancelación | consult | U25 | No es aceptación contractual |
| U23 | mission | Volver a ficha segura | consult | U09 | No es aceptación contractual |
| U23 | update | Consultar actualización requerida | consult | U24 | No es aceptación contractual |
| U24 | missions | Volver a misiones | consult | U01 | No es aceptación contractual |
| U24 | safety | Protección personal | protection | U20 | No es aceptación contractual |
| U25 | accept_cancel | Aceptar cancelación por mi parte | cancel | U16 | Expreso, versión actual |
| U25 | reject_cancel | Rechazar solicitud y conservar acuerdo | reject | U16 | No es aceptación contractual |
| U25 | agreement | Consultar acuerdo | consult | U16 | No es aceptación contractual |
| U25 | safety | Participación y seguridad | protection | U20 | No es aceptación contractual |
| U26 | acknowledge | Reconocer revisión de misión | acknowledge | U11 | Expreso, versión actual |
| U26 | current_revision | Consultar revisión vigente en servidor | query | U26 | No es aceptación contractual |
| U26 | application | Volver a candidatura | consult | U11 | No es aceptación contractual |
| U27 | close | Cerrar convocatoria | write | U09 | No es aceptación contractual |
| U27 | cancel | Cancelar misión y ofertas pendientes | cancel | U09 | Expreso, versión actual |
| U27 | agreements | Consultar acuerdos existentes | consult | U16 | No es aceptación contractual |
| U28 | edit | Editar borrador | consult | U08 | No es aceptación contractual |
| U28 | missions | Volver a misiones | consult | U01 | No es aceptación contractual |
