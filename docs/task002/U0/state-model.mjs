// Artefacto de diseño U0. No es autorización ni implementación Flutter/backend.
export const actors = {
 organizer:{label:'Organizador autorizado · Alex',name:'Alex Rivera'},
 candidate:{label:'Lucía · candidata C / invitada I',name:'Lucía Torres'},
 member:{label:'Lucía · editora vigente M (sin candidatura)',name:'Lucía Torres'},
 editor:{label:'Editora · Sofía (sin firma)',name:'Sofía Marín'},
 related:{label:'Lucía vinculada · escenario separado',name:'Lucía Torres'},
 outsider:{label:'Tercero sin permiso privado',name:'Persona visitante'}
};
export const transports={ready:'Disponible',loading:'Carga / autorización pendiente',sending:'Operación contractual en curso',error:'Resultado incierto / error',conflict:'Conflicto de versión',offline:'Sin conexión',denied:'Permiso perdido',retry_ready:'Servidor: operación no aplicada; reintento permitido'};
const A=(id,label,target,kind='consult',states=null,roles=null,consent=false)=>({id,label,target,kind,states,roles,consent});
const all=['organizer','candidate','editor','related','member'];
const org=['organizer','editor','member'];
const signer=['organizer'];
const candidate=['candidate','related'];
const S=(resource,states,roles,actions,{publicRead=false,empty=false,...rest}={})=>({resource,states,roles,actions,publicRead,empty,...rest});
export const screens={
 U01:S('mission_list',{available:'Misiones disponibles',empty:'Sin misiones'},[...all,'outsider'],[A('detail','Ver misión','U09','consult',['available']),A('create','Crear misión','U02'),A('notices','Ver avisos','U22')],{publicRead:true,empty:true}),
 U02:S('acting_context',{available:'Contextos vigentes',org_unavailable:'Organización sin facultad vigente'},all,[A('personal','Continuar como persona','U08','context'),A('organization','Continuar por Colectivo Río','U08','context',['available'],org),A('organizations','Gestionar organizaciones','U03')]),
 U03:S('organization_list',{available:'Organizaciones vigentes',empty:'Sin organizaciones'},all,[A('create_org','Crear organización','U04'),A('organization','Ver organización','U05','consult',['available'],org),A('invitation','Consultar invitación separada','U07','consult',null,candidate)],{empty:true}),
 U04:S('organization_draft',{draft:'Nueva organización'},all,[A('create_org','Crear organización','U05','accept',null,null,true)]),
 U05:S('organization',{normal:'NORMAL',suspended:'SUSPENDIDA',no_owner:'SIN_PROPIETARIO'},org.concat('related'),[A('members','Consultar miembros','U06','consult',null,signer),A('manage','Gestionar misión','U12','consult',['normal'],signer),A('create','Crear por la organización','U02','context',['normal'],org)]),
 U06:S('memberships',{active:'Membresías vigentes',no_owner:'Última propiedad: procedimiento controlado'},signer,[A('invite','Preparar invitación','U07','consult',['active']),A('organization','Consultar organización','U05')]),
 U07:S('invitation',{pending:'Invitación pendiente (13 oct)',member_active:'Invitación aceptada y membresía vigente (14 oct)',expired:'Invitación vencida',rejected:'Invitación rechazada'},candidate.concat('member'),[A('accept_invite','Aceptar invitación','U05','accept',['pending'],null,true),A('reject_invite','Rechazar invitación','U03','reject',['pending']),A('membership','Consultar membresía vigente','U05','consult',['member_active'],['member']),A('organizations','Volver a organizaciones','U03')]),
 U08:S('mission_draft',{draft:'Borrador editable',material:'Edición material de misión publicada'},org.concat('candidate','related'),[A('publish','Publicar misión','U09','accept',['draft']),A('save','Guardar borrador en servidor','U28','write'),A('mission_revision','Revisar edición de misión','U09','consult',['material']),A('draft','Consultar borrador','U28')],{localDraft:true}),
 U09:S('mission',{open:'PUBLICADA · admite candidaturas',closed:'CERRADA',cancelled:'CANCELADA',full:'PUBLICADA · sin plazas disponibles',eligibility_pending:'Vínculo de control: elegibilidad sin resolver'},[...all,'outsider'],[A('apply','Postular personalmente','U10','context',['open'],candidate),A('manage','Gestionar como organizador','U12','consult',null,signer),A('edit','Administrar contenido de misión','U08','consult',null,['editor','member']),A('eligibility','Consultar elegibilidad de persona vinculada','U09','query',null,['organizer','editor','related','member']),A('legacy','Consultar histórico legado','U23')],{publicRead:true}),
 U10:S('application_draft',{eligible:'Elegibilidad vigente · misión abierta',unavailable:'Postulación no disponible'},candidate,[A('apply','Enviar candidatura','U11','accept',['eligible'],null,true),A('revision','Consultar revisión de misión','U26')]),
 U11:S('application',{sent:'ENVIADA',shortlisted:'PRESELECCIONADA',offer_pending:'Oferta PENDIENTE',revision_known:'ENVIADA · revisión v2 reconocida',expired:'CADUCADA',resolved:'Candidatura resuelta'},candidate,[A('offer','Consultar oferta','U15','consult',['offer_pending']),A('mission','Volver a misión','U09')]),
 U12:S('applications',{available:'Candidaturas preseleccionadas',empty:'Sin candidaturas',closed:'Misión CERRADA · sólo consulta',cancelled:'Misión CANCELADA · sólo consulta'},signer,[A('prepare','Revisar oferta para Lucía','U13','consult',['available']),A('status','Cerrar o cancelar misión','U27','consult',['available']),A('mission','Volver a misión','U09')],{empty:true}),
 U13:S('offer_preparation',{available:'Candidatura disponible · plaza disponible',pending:'Oferta previa PENDIENTE',expired:'Oferta previa EXPIRADA · elegibilidad aún sin verificar',resolved:'Oferta previa resuelta · sólo consulta',unavailable:'Sin plaza / candidatura incompatible'},signer,[A('issue','Enviar oferta y aceptar estas condiciones','U14','accept',['available'],null,true),A('existing_offer','Consultar oferta previa','U14','consult',['pending','expired','resolved']),A('eligibility','Consultar candidatura y cupo actuales','U12','query',['expired','unavailable']),A('applications','Volver a candidaturas','U12')]),
 U14:S('offer',{pending:'PENDIENTE · reserva vigente',expired:'EXPIRADA · reserva liberada',accepted:'ACEPTADA · aceptación histórica',rejected:'RECHAZADA · reserva liberada',cancelled:'CANCELADA · reserva liberada'},signer,[A('withdraw','Retirar oferta pendiente','U14','cancel',['pending'],null,true),A('agreement','Consultar acuerdo vinculado','U16','consult',['accepted']),A('applications','Volver a candidaturas','U12')]),
 U15:S('offer',{pending:'PENDIENTE · antes de expires_at',expired:'EXPIRADA · no admite respuesta',accepted:'ACEPTADA · aceptación histórica',rejected:'RECHAZADA',cancelled:'CANCELADA'},candidate,[A('accept_offer','Aceptar oferta','U16','accept',['pending'],null,true),A('reject_offer','Rechazar oferta','U11','reject',['pending']),A('agreement','Consultar acuerdo vinculado','U16','consult',['accepted']),A('application','Volver a candidatura','U11')]),
 U16:S('agreement',{active:'ACTIVO',revision_pending:'ACTIVO · propuesta de revisión pendiente',terminated:'TERMINADO',cancelled:'CANCELADO'},['organizer',...candidate],[A('propose','Proponer cambios de acuerdo','U17','context',['active']),A('revision','Consultar propuesta pendiente','U17','consult',['revision_pending']),A('history','Ver historial','U18'),A('cancel_request','Solicitar cancelación','U19','context',['active','revision_pending']),A('safety','Participación y seguridad','U20','protection')]),
 U17:S('agreement_revision',{pending:'Propuesta v2 vigente',signed:'Aceptación propia registrada · falta contraparte',expired:'Propuesta EXPIRADA',rejected:'Propuesta RECHAZADA',activated:'v2 activada bilateralmente',agreement_terminal:'Acuerdo TERMINADO · propuesta sin operación vigente'},['organizer',...candidate],[A('accept_revision','Aceptar cambios por mi parte','U16','accept',['pending'],null,true),A('reject_revision','Rechazar propuesta y conservar v1','U16','reject',['pending']),A('history','Ver versiones','U18'),A('agreement','Consultar acuerdo','U16')]),
 U18:S('agreement_history',{active:'Acuerdo ACTIVO · v1 vigente',revision_pending:'ACTIVO · v2 propuesta',terminated:'Acuerdo TERMINADO · historial',revised:'ACTIVO · v2 vigente'},['organizer',...candidate],[A('agreement','Volver al acuerdo','U16')]),
 U19:S('cancellation_preparation',{available:'Acuerdo activo · sin solicitud pendiente',pending:'Solicitud ya pendiente',resolved:'Acuerdo terminal · sólo consulta'},['organizer',...candidate],[A('request_cancel','Enviar solicitud de cancelación','U25','cancel',['available'],null,true),A('request','Consultar solicitud existente','U25','consult',['pending']),A('agreement','Consultar acuerdo','U16'),A('safety','Acciones de seguridad','U20','protection')]),
 U20:S('personal_safety',{available:'Protección personal disponible',contract_sending:'Otra operación contractual en curso',safety_sending:'Aviso de seguridad en curso',recorded:'Aviso confirmado por servidor (muestra)'},['organizer',...candidate],[A('stop','Detener participación y solicitar registro','U21','safety',['available','contract_sending']),A('report','Bloquear contacto y solicitar reporte','U21','safety',['available','contract_sending']),A('case','Consultar seguimiento','U21','consult',['recorded']),A('agreement','Consultar acuerdo','U16')],{publicRead:true}),
 U21:S('case',{unconfirmed:'Sin respuesta de registro',received:'Reporte recibido (respuesta de muestra)',resolved:'Caso resuelto (respuesta de muestra)'},['organizer',...candidate],[A('case_status','Consultar estado del caso','U21','query'),A('agreement','Consultar acuerdo','U16'),A('safety','Protección personal','U20','protection')]),
 U22:S('notification_list',{available:'Notificaciones disponibles',empty:'Sin notificaciones'},all,[A('offer','Consultar oferta','U15','consult',['available'],candidate),A('revision','Consultar cambios','U17','consult',['available'],['organizer',...candidate]),A('cancellation','Consultar cancelación','U25','consult',['available'],['organizer',...candidate])],{empty:true}),
 U23:S('legacy_record',{review:'Histórico pendiente de revisión'},all,[A('mission','Volver a ficha segura','U09'),A('update','Consultar actualización requerida','U24')]),
 U24:S('client_capability',{incompatible:'Cliente incompatible'},[...all,'outsider'],[A('missions','Volver a misiones','U01'),A('safety','Protección personal','U20','protection')],{publicRead:true}),
 U25:S('cancellation_request',{requested:'Solicitud pendiente · acuerdo ACTIVO',rejected:'Solicitud RECHAZADA · acuerdo ACTIVO',completed:'Cancelación bilateral completada · acuerdo CANCELADO',withdrawn:'Solicitud RETIRADA · acuerdo ACTIVO',requester:'Persona solicitante · no es contraparte receptora'},['organizer',...candidate],[A('accept_cancel','Aceptar cancelación por mi parte','U16','cancel',['requested'],null,true),A('reject_cancel','Rechazar solicitud y conservar acuerdo','U16','reject',['requested']),A('agreement','Consultar acuerdo','U16'),A('safety','Participación y seguridad','U20','protection')]),
 U26:S('mission_revision_ack',{pending:'Revisión v2 vigente · reconocimiento pendiente',conflict:'Revisión v2 superada por v3',expired:'Candidatura CADUCADA · sin transición admisible',acknowledged:'Reconocimiento v2 registrado',current:'Revisión ya conocida · sin cambio material'},candidate,[A('acknowledge','Reconocer revisión de misión','U11','acknowledge',['pending'],null,true),A('current_revision','Consultar revisión vigente en servidor','U26','query',['conflict']),A('application','Volver a candidatura','U11')]),
 U27:S('mission_transition',{open:'PUBLICADA',closed:'CERRADA',cancelled:'CANCELADA'},signer,[A('close','Cerrar convocatoria','U09','write',['open']),A('cancel','Cancelar misión y ofertas pendientes','U09','cancel',['open','closed'],null,true),A('agreements','Consultar acuerdos existentes','U16')]),
 U28:S('mission_draft',{local:'Borrador local',server:'Borrador servidor',conflict:'Versiones en conflicto'},all,[A('edit','Editar borrador','U08'),A('missions','Volver a misiones','U01')],{localDraft:true})
};
export function validTransports(id){const s=screens[id]; return Object.keys(transports).filter(t=>!['sending','conflict','retry_ready'].includes(t)||s.actions.some(a=>isMutation(a)||a.kind==='context'));}
export function isMutation(a){return ['accept','reject','cancel','write','acknowledge','safety'].includes(a.kind);}
export function resolve({screen,actor='organizer',context='personal',resourceState,transport='ready',consented=false,originalOperation=false}){
 const s=screens[screen]; if(!s)throw Error('Pantalla desconocida');
 const r=resourceState||Object.keys(s.states)[0];
 if(!Object.hasOwn(s.states,r))throw Error(`Estado ${r} no aplicable a ${screen}/${s.resource}`);
 if(!validTransports(screen).includes(transport))throw Error(`Transporte ${transport} no aplicable a ${screen}`);
 const authorized=s.roles.includes(actor)&&(!(screen==='U07')||(actor==='member'?r==='member_active':r!=='member_active'))&&(!(s.localDraft&&context==='organization')||['organizer','editor','member'].includes(actor)), privateVisible=Boolean(authorized&&transport!=='denied'&&(transport!=='offline'||s.publicRead||(s.localDraft&&context==='personal')));
 const actions=s.actions.map(a=>{
 let visible=authorized&&(!a.roles||a.roles.includes(actor))&&(!a.states||a.states.includes(r));
 if(screen==='U02'&&a.id==='organization'&&context!=='organization')visible=false;
 if(screen==='U09'&&a.id==='apply'&&context==='personal'&&actor==='organizer')visible=false;
 if(a.kind==='protection')visible=true; // Acceso seguro; el destino valida identidad propia.
 if(!privateVisible&&!['protection'].includes(a.kind)&&!s.publicRead)visible=false;
 let reason='',enabled=visible;
 if(visible){
  if(['context','query'].includes(a.kind)&&['loading','offline','denied'].includes(transport)){enabled=false;reason='Requiere autorización / consulta de servidor.';}
  if(isMutation(a)){
   if(transport!=='ready'&&transport!=='retry_ready'){enabled=false;reason='No mutar hasta conciliación y autorización del servidor.';}
   if(a.consent&&!consented&&transport==='ready'){enabled=false;reason='Requiere consentimiento expreso sobre la versión actual.';}
   if(transport==='retry_ready'){enabled=false;reason='Reintento únicamente de la operación original; no una operación nueva.';}
   if(a.kind==='safety'&&r!=='safety_sending'&&['ready','sending'].includes(transport)){enabled=true;reason='Clave de seguridad independiente del envío contractual.';}
  }
  if(a.kind==='consult'&&['loading','offline','denied'].includes(transport)&&!a.target?.startsWith('U01')){enabled=false;reason='Destino requiere autorización o conexión actual.';}
  if(a.kind==='protection'){enabled=true;reason='Acceso a protección no depende del envío contractual.';}
 }
 return {...a,visible,enabled,reason};
 });
 const uncertain=['sending','error','conflict','retry_ready'].includes(transport)&&authorized;
 if(uncertain)actions.push({id:'reconcile',label:'Consultar resultado en servidor',kind:'query',visible:true,enabled:true,reason:'Sin backend: sólo explica la consulta necesaria.',target:null,consent:false});
 if(transport==='retry_ready'&&authorized)actions.push({id:'retry_same',label:'Reintentar la misma operación y clave',kind:'retry',visible:true,enabled:originalOperation,reason:originalOperation?'Muestra NO_APLICADA; preserva clave, cuerpo y versión.':'No hay operación original en esta sesión; no se habilita reintento.',target:null,consent:false});
 return {screen,actor,context,resource:s.resource,resourceState:r,resourceLabel:s.states[r],transport,authorized,privateVisible,actions};
}

// Proyecciones de una respuesta de muestra conocida al navegar; nunca resultado de pulsar mutación.
export function destinationState(from,state,to){
 const map={U16:{terminated:{U18:'terminated'},cancelled:{U18:'terminated'},revision_pending:{U18:'revision_pending',U17:'pending'}},U18:{terminated:{U16:'terminated'},revision_pending:{U16:'revision_pending'}},U25:{completed:{U16:'cancelled'},rejected:{U16:'active'},withdrawn:{U16:'active'}},U17:{agreement_terminal:{U16:'terminated'},activated:{U18:'revised'}},U26:{expired:{U11:'expired'},acknowledged:{U11:'revision_known'}},U09:{closed:{U12:'closed'},cancelled:{U12:'cancelled'}}};return map[from]?.[state]?.[to]||null;
}
