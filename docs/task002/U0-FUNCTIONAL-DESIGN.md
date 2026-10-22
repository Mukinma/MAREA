# U0 — Navegación y diseño funcional para revisión

Estado vigente: **APROBADO_DISEÑO_FUNCIONAL**, por instrucción directa del usuario el 18 de octubre de 2026 (America/Mexico_City). **Flutter y cambios funcionales NO AUTORIZADOS**. El prototipo `U0/index.html` sólo representa pantallas con datos sintéticos; no autentica, firma, reserva, publica, reporta ni llama al backend. No es evidencia de implementación validada.

## Identidad visual y superficies

Se reutilizan logo MAREA y NunitoSans del repositorio. Tokens leídos de AppColors/AppTheme/AppSpacing/AppRadius: navy #0B255E, acción #0D4397, aqua #22C5C1, fondo paper #FAF9F6, texto #102149, borde suave #E9E8E4; tarjetas de 24 px, inputs/botones de 16 px y altura mínima 52 px, espaciado 4/8/12/16/24/32. Sin nueva marca ni reorganización de la navegación principal. AppShell conserva Inicio, Explorar, Misiones, Mapa y Perfil, con Crear y las utilidades actuales de guardados/notificaciones. Las rutas de detalle fuera de Shell conservan Volver; el prototipo no añade dock a esos flujos. El prototipo permite inspección móvil y escritorio, contexto personal/organizacional y estados; la equivalencia Flutter aún debe verificarse en U1.

## Mapa de navegación propuesto

```mermaid
flowchart TD
  Perfil[Perfil actual] --> Orgs[Organizaciones]
  Orgs --> CrearOrg[Crear organización]
  Orgs --> Org[Organización y miembros]
  Org --> Invitacion[Invitación / permisos]
  Misiones[Lista / mapa / inicio / guardados] --> Detalle[Detalle de misión]
  Misiones --> Contexto[Selector de contexto]
  Contexto --> Crear[Crear / editar / borrador]
  Crear --> Detalle
  Detalle --> Postular[Postular y reconocer revisión]
  Postular --> Candidatura[Mi candidatura]
  Detalle --> Gestion[Gestionar candidaturas]
  Gestion --> Preparar[Preselección / revisar oferta]
  Preparar --> Emitida[Oferta enviada y firmada por organizador]
  Avisos[Notificaciones / enlace] --> Oferta[Oferta recibida]
  Avisos --> Acuerdo[Acuerdo]
  Candidatura --> Oferta
  Oferta --> Respuesta[Aceptar / rechazar]
  Respuesta --> Acuerdo
  Acuerdo --> Historia[Versiones y firmas]
  Acuerdo --> Propuesta[Proponer / revisar cambios]
  Propuesta --> Acuerdo
  Acuerdo --> Cancelacion[Solicitar / responder cancelación]
  Acuerdo --> Seguridad[Detener participación / bloquear / reportar]
  Detalle --> Historico[Histórico sólo lectura / actualización requerida]
```

Los destinos antiguos /missions/:id, /apply, /sent, /manage y /edit se conservan, con resolución autorizada del recurso. Rutas propuestas adicionales: /organizations, /organizations/new, /organizations/:id, /organizations/:id/members, /invitations/:id, /offers/:id, /agreements/:id y sus revisiones/cancelaciones/historial. Reportes usan entrada contextual con identificadores validados, nunca una URL arbitraria del push.

Volver conserva filtros y borrador, no reproduce una mutación. Enlace/notificación resuelve sesión → capacidad del cliente → permiso actual → recurso; si falta sesión, retorno tras login al mismo destino, sujeto a nueva autorización. Si falta permiso, no renderizar términos cacheados. Compartir una misión sólo comparte su proyección pública, jamás aceptación, candidaturas o contrato.

## Inventario revisable

| ID | Interfaz | Cambio y salida |
|---|---|---|
| U01 | Lista de misiones / tarjetas / mapa | Existente: titular, reservas y acuerdos diferenciados; detalle o crear |
| U02 | Selector de contexto | Nueva hoja: persona siempre disponible; sólo organizaciones con facultad actual; vuelve a acción pendiente |
| U03 | Organizaciones | Nueva lista desde perfil; crear/detalle/invitación |
| U04 | Crear organización | Nombre y responsable; no fusiona identidad personal |
| U05 | Organización | Estado de operación/propiedad; misiones y miembros autorizados |
| U06 | Miembros y permisos | Roles mínimos, facultades de firma separadas, invitar/revocar; última propiedad con flujo controlado |
| U07 | Invitación | Parte invitante, rol, permisos y vigencia; aceptar/rechazar, sin incorporación silenciosa |
| U08 | Crear / editar misión y borrador | Existente: contexto fijo, titular, plazo, contenido y revisión; borrador local versus servidor |
| U09 | Detalle de misión | Existente: titular, condiciones públicas y cupos; postular o gestionar según permiso |
| U10 | Postulación | Existente: disponibilidad/evidencia, revisión conocida, reconocimiento material antes de continuar |
| U11 | Mi candidatura / envío | Existente: enviada/preseleccionada/oferta separadas; ninguna equivale a contrato |
| U12 | Gestión de candidaturas | Existente: revisar → preseleccionar → oferta individual; no confirmar lote ni firmar por candidata |
| U13 | Revisar y emitir oferta | Nueva: destinatario, condiciones exactas, plaza, 72h y aceptación organizadora expresa |
| U14 | Oferta enviada | Nueva: pendiente de destinataria, firma organizadora y vencimiento; retirar autorizado |
| U15 | Oferta recibida | Nueva: términos exactos, parte responsable, límite; aceptación/rechazo personal |
| U16 | Acuerdo | Nueva: estado actual, oferta histórica, revisión vigente, partes y acciones por permiso |
| U17 | Propuesta material / revisión | Nueva: antes/después, plazo, firmas parciales; anterior continúa vigente |
| U18 | Historial | Nueva: revisiones y firmas históricas, sin acceso privado de terceros |
| U19 | Solicitud de cancelación | Nueva: motivo y aviso; no termina automáticamente; contraparte acepta/rechaza |
| U20 | Seguridad | Nueva: detener participación, bloquear y reportar sin consentimiento abusivo; no declarar culpabilidad |
| U21 | Caso/incidencia | Propuesta de entrada contextual y número de caso; resolución administrativa no habilitada sin política |
| U22 | Notificaciones | Existente: oferta/cambio/cancelación diferenciados, destinos autorizados sin payload contractual |
| U23 | Histórico legado | Nuevo estado de detalle: selección legada no es acuerdo; revisión pendiente, sin acciones contractuales |
| U24 | Actualización requerida | Nuevo estado transversal: no continuar con estados incompatibles; volver a superficie segura |
| U25 | Responder cancelación | Nueva: contraparte acepta expresamente o rechaza conservando acuerdo |
| U26 | Reconocer revisión de misión | Nueva: comparación de términos, reconocimiento separado de firma contractual |
| U27 | Cierre/cancelación de misión | Modificada: efectos separados en ofertas pendientes y acuerdos activos |
| U28 | Borrador | Modificada: estado local/servidor y conflicto antes de publicar |

En el prototipo, Inicio/Explorar/Mapa reutilizan la muestra de tarjeta/listado U01 y Perfil abre el acceso propuesto a Organizaciones: son atajos de revisión, no una sustitución de sus pantallas reales. No se propone rediseñar esas superficies.

Perfil sólo añade acceso a Organizaciones; no se rediseñan onboarding ni otros módulos. Guardados, mapa y feed conservan su estructura con DTO/proyecciones correctos. Reacciones/comentarios existentes se preservan y no se convierten en chat contractual privado.

## Flujos completos

### Organizador autorizado personal u organizacional

Entrada lista/perfil → escoger contexto → crear/guardar borrador → publicar con confirmación servidor → recibir candidaturas → revisar → preseleccionar → revisar términos y destinataria → consentir «Enviar oferta y aceptar estas condiciones» → envío pendiente de respuesta → consultar aceptación/rechazo/vencimiento → acuerdo/historial.

El selector muestra la persona humana actuante y, cuando corresponda, la organización representada. Cambiar contexto requiere nueva verificación y no transforma titularidad ni borra un borrador. En una misión existente manda su titular, no una preferencia global. Nunca exigir organización a la persona que gestiona su propia misión.

### Candidata

Descubrimiento/enlace → detalle → postular personalmente → confirmar disponibilidad/revisión/evidencia → envío real → candidatura → notificación/oferta → leer términos completos y vencimiento → aceptar/rechazar → resultado autenticado → acuerdo activo o candidatura con oferta terminada. No hay confirmación optimista ni firma del organizador por la candidata.

### Cambio material

Misión: edición material → advertencia de efectos → revisión nueva y ofertas afectadas terminadas → candidata ve diferencias y reconoce revisión → organizador puede emitir nueva oferta cuando estado lo permita.

Acuerdo: detalle → proponer condiciones → revisar diff y aceptar expresamente por parte propia → propuesta pendiente → contraparte revisa → aceptación dentro de plazo promueve revisión; rechazo/retiro/expiración conservan revisión previa. Mostrar ambas revisiones mientras negocian. Cambiar contraparte no se ofrece como edición ordinaria.

### Cancelación y seguridad

Acuerdo → solicitar cancelación con motivo → aviso → contraparte responde → cancelación bilateral sólo con consentimiento exigido. Rechazar la solicitud conserva acuerdo; mostrar estado independiente de solicitud.

Seguridad: acuerdo/perfil contextual → detener participación o bloquear/reportar inmediatamente → confirmación de la acción realizada y estado del caso. Detener participación no declara acuerdo cancelado, incumplimiento probado ni indemnización. Bloqueo no borra firmas/evidencias y no exige retirar denuncia. Sin promesa de atención continua; horarios y contactos reales pendientes de política operativa. El diseño no inventa servicios de emergencia ni resoluciones administrativas.

### Organización y privacidad

Crear → organización → miembros → invitación → aceptación del receptor → facultades vigentes. Revocar conserva firma histórica; la persona pierde acciones futuras. Organización sin propiedad/representación válida o suspendida muestra restricción y no admite obligaciones nuevas. Transferencia requiere consentimiento y reautenticación: interfaz/proceso completo queda ligado a sus dependencias de seguridad, no se presume implementado en TASK-002.

La solicitud de eliminación siempre puede presentarse. Estado/seguimiento de privacidad explica recursos pendientes sin exigir mantener perfil público. Expedientes activos se conservan sólo bajo causa y plazo aprobado, no como retención indefinida. No se reutiliza author_id como dueño organizacional al eliminar un representante.

## Estados y acciones

| Estado | Lectura | Acción crítica y salida |
|---|---|---|
| Carga | Esqueleto, sin términos anteriores de otro contexto | Deshabilitada hasta permiso/recurso actual |
| Vacío | Explicación contextual y siguiente paso autorizado | Crear/postular sólo cuando corresponde |
| Error de red | Mensaje localizado y reintento | No simular éxito ni nueva clave al reintentar misma operación |
| Offline | Sólo contenido público cacheado con fecha; borrador local protegido | Oferta, firma, publicación, cancelación, membresía y reporte no se encolan; puede detener físicamente participación, pero la app no afirma registro servidor sin respuesta |
| Permiso perdido | Retirar contenido privado y acciones | Volver; volver a resolver contexto válido |
| Conflicto / revisión cambiada | Informar nueva revisión y conservar aportación | Revisión/consentimiento renovado, no sobrescritura silenciosa |
| Envío en curso | Evitar doble clic y mostrar progreso | Reintentar con misma clave; conciliar resultado servidor antes de declarar fallo definitivo |
| Vencimiento | Fecha de servidor y resultado terminal | Aceptación denegada; no extender TTL por UI |
| Éxito | Sólo postconfirmación backend real en futura implementación | Oferta enviada no dice «contratado»; cancelación solicitada no dice «cancelado» |
| Cliente incompatible | Pantalla de actualización localizada | Lectura contractual bloqueada; regreso seguro |

El contador es informativo; siempre mostrar fecha/hora y zona, y volver a consultar al recuperar foco/red. La cuenta atrás no demuestra elegibilidad para aceptar.

## Textos, permisos y accesibilidad

- Etiquetas: «Como persona», «En representación de…», «Oferta pendiente de tu respuesta», «Acuerdo activo», «Oferta aceptada el…», «Solicitud de cancelación», «Participación detenida por seguridad».
- Permisos mínimos: mission.manage, application.review, agreement.offer y facultad de aceptación organizadora para emitir; agreement.accept para firma organizacional; candidata firma exclusivamente por sí misma. La ausencia de acciones UI no sustituye controles servidor.
- Explicar compensación como declarada; MAREA no gestiona/verifica pagos ni garantiza cumplimiento externo.
- Teclado/foco visible, labels, contraste, objetivos >=48px, texto ampliable, fechas inequívocas y anuncios accesibles de resultado. El prototipo no acredita WCAG integral ni lectores móviles.
- Cachés: separar contextos; no recuperar privados tras perder permiso; app nueva corrige estado legado al actualizar/reconectar. No prometer reparar una pantalla offline inalcanzable de un binario antiguo.

## Entregable y puerta de aprobación

Revisar prototipo, navegación U01–U28, decisiones sobre permisos/acciones y estados. U0 queda **ENTREGADO_PARA_REVISION**, no aprobado. La futura equivalencia Flutter y QA en dispositivos se verificarán en U1; la preparación de U0 no bloquea diseño backend, pero no autoriza implementarlo. Ninguna pantalla del producto se ha modificado.

## Corrección acotada de consistencia — 13 octubre, segunda revisión

Estado actual: **CORREGIDO_PARA_APROBACIÓN_FORMAL_U0; FLUTTER NO AUTORIZADO**. Esta sección y la matriz sustituyen la aplicabilidad del antiguo selector global. El diseño conceptual, identidad MAREA, componentes y cinco destinos actuales se conservan. Las tarjetas/formularios del prototipo son una referencia de flujo; la futura adaptación deberá conservar las pantallas maduras, no sustituirlas por estas muestras abreviadas.

Historial previo inmutable: `docs/evidence/2026-10-13/task002/run-20261014T044500Z/prior-U0/` y `prior-U0-FUNCTIONAL-DESIGN.md`. Los recibos y evidencias de TASK-001 y del checkpoint N/T anterior siguen intactos. No cambian SRS, Flutter, SQL de E, migraciones, RPC ni servicios.

### Contrato reutilizable de presentación

Entrada de resolución: **pantalla + identidad humana + facultad por recurso + tipo de titular + estado del recurso + comunicación/operación + consentimiento/versionado**. Salida: contenido visible, acciones visibles, acciones habilitadas y motivo de bloqueo. Un rol de muestra no concede permisos reales. En producto, las facultades y la elegibilidad deben venir de comprobaciones servidor; este modelo sólo permite revisar la propuesta.

`U0/state-model.mjs` declara las reglas por recurso; `screens.json` contiene el inventario y aplicabilidad. `U0/MATRIX.md` presenta los estados aplicables/no aplicables y la matriz por actor/titular/estado, con etiquetas y destinos. `U0/matrix.json` contiene todas las combinaciones con transporte, contenido, acciones visibles, habilitadas y consentimiento requerido. Se regeneran con `node docs/task002/U0/build-matrix.mjs`. Son verificaciones del diseño, no de los contratos del producto.

La selección de estado sólo admite la lista del recurso actual. Al navegar se resuelve la pantalla destino; no se transporta un estado de oferta a organización/borrador. Los estados de comunicación también se localizan: una operación pendiente no añade un banner de envío a otro recurso. Se conserva la proyección de un resultado conocido al consultar: cancelación completada → acuerdo CANCELADO; acuerdo terminado → historial terminado; candidatura caducada → candidatura CADUCADA; misión cancelada → gestión sólo lectura. Oferta ACEPTADA nunca obliga a proyectar permanentemente un acuerdo ACTIVO.

La carga muestra esqueleto y bloqueos explícitos, sin términos previos. Permiso perdido y offline retiran privados; offline conserva público/borrador personal protegido e instrucciones de protección. Error o conflicto exige consultar recurso, permiso, versión y resultado de la clave original; no ofrece una nueva operación como reintento. Envío bloquea nuevos clics/mutaciones del recurso, conserva clave/cuerpo/versión y no navega a un éxito. Reintento sólo después de respuesta NO_APLICADA, con clave original; se deniega si no hay operación original o cambió su versión. Las respuestas de ejemplo se seleccionan expresamente en el panel y nunca son confirmaciones de la acción pulsada.

El acceso a seguridad funciona durante un envío contractual. El aviso de seguridad usa una clave independiente; su propio envío tampoco se duplica. Se necesita conectividad y autorización para registrar/bloquear/reportar remotamente. Detener físicamente participación y acceder a orientación no dependen de que ese registro sea confirmado. El diseño no sustituye los controles pendientes de revocación TASK-003.

Aceptar usa acción principal azul; rechazar usa contorno rojo; cancelar usa acción de peligro roja y texto explícito; consultar usa acción neutra; reconocer una revisión de misión usa contorno aqua y texto que excluye firma contractual. Consentimiento deshabilitado durante carga/envío/error/conflicto. El botón de aceptación permanece deshabilitado hasta consentimiento expreso sobre la versión vigente y permiso/estado compatibles. Ocultar un botón no sustituye el control servidor.

### Identidades, tiempos y elegibilidad

Se distinguen seis perfiles de revisión, derivados de escenarios distintos, no seis roles universales:

| Escenario | Identidad / situación | Relación con el flujo |
|---|---|---|
| C | Alex organizador autorizado personal u organizacional; Sofía editora sin firma; Lucía candidata externa | Contrato ejemplo con humanos distintos. No hay invitación ni membresía de Lucía. |
| I | Lucía invitada el 13 oct, 09:00; aún no miembro | Invitación pendiente. No candidatura en la misma muestra. |
| M | Lucía editora vigente el 14 oct, 09:00, tras aceptar invitación | Invitación resuelta; consultar membresía, sin aceptar/rechazar otra vez. Perfil M puede consultar organización y administrar contenido por su permiso; no firma ni revisa candidaturas privadas. Sin candidatura C simultánea. |
| V | Lucía con vínculo divulgado, en escenario alternativo | `open` presupone admisibilidad comprobada por servidor y firma organizadora por otro humano. `eligibility_pending` no permite postular. No genera reputación independiente. |
| Tercero | Persona sin permiso privado | Sólo superficies públicas y acceso a protección propia; no consulta términos privados ni firmas. |

U09 personal propia: Alex administra y no postula (RF-09-001, §3 y §4.4). U09 organizacional: la representación y el control se revisan por recurso; ser miembro por sí solo no equivale a controlar la misión. La muestra del organizador Alex ofrece administración y consulta de elegibilidad, sin habilitar postulación por cambiar contexto. La candidata externa sólo postula a misión abierta y elegible. Sofía/Lucía M pueden administrar contenido por `mission.manage`, sin `application.review` ni facultad de firma.

**Ambigüedad acotada que requiere decisión normativa futura:** RF-09-001 y la definición de Application especifican autopostulación personal propia; RB-06 habla de misión «propia» y AT5-04 incluye organizaciones controladas, mientras §4.4 admite colaboraciones vinculadas bajo controles. Debe precisarse qué relación de propiedad/administración/representación constituye control impeditivo para la postulación, y cuáles colaboraciones vinculadas pueden admitirse con divulgación y representante independiente. No se modifica el SRS ni se presume esa autorización. Hasta resolver elegibilidad actual en servidor, la UI mantiene la postulación del organizador/controlador sin habilitar; tampoco impone una prohibición a todos los miembros. Una misma persona nunca firma ambos lados (§3.2, invariante 6).

Las fechas contractuales pertenecen al escenario C: emisión 13 oct, 18:00; oferta vence 16 oct, 18:00 (72h servidor); aceptación inicial 14 oct; ejecución original 20 oct, 10:00. Propuesta de revisión de acuerdo creada 14 oct, 10:00; límite 20 oct, 10:00 por ejecución, antes del máximo de siete días naturales. Las variantes terminales son momentos posteriores o respuestas alternativas de la muestra, no estados simultáneos. MissionRevision no recibe un TTL de oferta/revisión contractual: U26 vencimiento significa candidatura CADUCADA sin transición admisible; conflicto significa revisión v2 superada por v3; reconocimiento significa lectura registrada, nunca aceptación contractual.

### Verificación solicitada y decisiones independientes

| Interfaces | Criterio corregido |
|---|---|
| U02 | Personal habilitada con elegibilidad; organización sólo con facultad vigente; organización no disponible no bloquea contexto personal. |
| U07 | Pendiente I admite consentimiento/respuesta; membresía vigente M sólo consulta; receptor y facultades separados de candidata C. |
| U09 | Autopostulación personal propia ausente; administración según permiso; vínculos organizacionales sujetos a comprobación, sin prohibición general por membresía. |
| U13–U15 | Una oferta previa impide duplicar emisión; vencida/resuelta sin respuesta/retiro; reemisión necesita candidatura, revisión y cupo actuales. |
| U16–U18 | ACTIVO y propuesta separadas; última versión bilateral vigente; terminal sólo lectura/historial/seguridad, sin proponer/cancelar ni presentar historial terminado como obligación vigente. |
| U25 | Pendiente responde la contraparte distinta; rechazada conserva ACTIVO; bilateral completada muestra CANCELADO y sólo consulta/seguridad, incluida navegación posterior. |
| U26 | Vigente permite reconocimiento expreso; conflicto consulta versión actual; candidatura caducada sólo lectura; reconocimiento registrado no se repite ni firma acuerdo. |

Recibos actuales: corrida `run-20261014T044500Z`, pruebas del modelo, verificación de navegador y láminas `U0-terminal-release.png` / `U0-uncertainty-release.png` / `U0-actions-release.png`. Las láminas agrupan nueve casos críticos usando la interfaz real del prototipo; no requieren capturas manuales de cada combinación trivial. El inventario/matriz cubre U01–U28 y las variantes restantes.

**Decisión U0 solicitada:** aprobación formal del diseño funcional corregido como referencia para una futura adaptación acotada de Flutter, conservando pantallas maduras. La ambigüedad de elegibilidad queda localizada y requiere comprobación normativa/servidor antes de habilitar ese caso; no bloquea el resto del diseño. Esta entrega no autoriza ni implementa Flutter.

**Decisión E independiente:** no se combina con U0. El diagnóstico y los límites actuales se encuentran en `E-STRUCTURAL-REVIEW.md`. E no está listo para aprobar ejecución estructural; no se han aplicado migraciones TASK-002. TASK-002 sigue incompleta.


## Aprobación formal — 18 octubre 2026

El usuario aprueba U0 como APROBADO_DISEÑO_FUNCIONAL: las 28 interfaces, estados por recurso, presentación y permisos, consentimiento, separación contractual/protección personal y conservación de identidad/componentes actuales. La matriz y las evidencias verificadas quedan congeladas sin modificación. Las pantallas maduras se conservan. Las secciones previas y sus solicitudes de aprobación corresponden al historial de revisión, no al estado vigente.

La postulación vinculada ambigua no obtiene elegibilidad por inferencia: necesita regla aprobada y validación servidor. Esta aprobación no autoriza Flutter, migraciones, RPC ni remoto. E continúa NO AUTORIZADO para su cambio estructural; sólo se autoriza desbloquear y completar diagnóstico y ensayos locales de respaldo/restauración, sin aplicar la propuesta. Recibo: docs/evidence/2026-10-18/task002/run-20261019T051800Z/AUTHORIZATION.md.
