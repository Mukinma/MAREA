import fs from 'node:fs';
const old=JSON.parse(fs.readFileSync(new URL('../../avance-marea-2026-10-06/.support/inventory.json',import.meta.url)));
export const blocks=old.metadata.blocks||[
 ['SEP-1','Septiembre','S1','01–07 sep','2026-09-01','2026-09-07'],['SEP-2','Septiembre','S2','08–14 sep','2026-09-08','2026-09-14'],['SEP-3','Septiembre','S3','15–21 sep','2026-09-15','2026-09-21'],['SEP-4','Septiembre','S4','22–30 sep','2026-09-22','2026-09-30'],
 ['OCT-1','Octubre','S1','01–07 oct','2026-10-01','2026-10-07'],['OCT-2','Octubre','S2','08–14 oct','2026-10-08','2026-10-14'],['OCT-3','Octubre','S3','15–21 oct','2026-10-15','2026-10-21'],['OCT-4','Octubre','S4','22–31 oct','2026-10-22','2026-10-31'],
 ['NOV-1','Noviembre','S1','01–07 nov','2026-11-01','2026-11-07'],['NOV-2','Noviembre','S2','08–14 nov','2026-11-08','2026-11-14'],['NOV-3','Noviembre','S3','15–18 nov','2026-11-15','2026-11-18'],['NOV-4','Noviembre','S4','Deshabilitada',null,null]];
export const modules={BASE:'Transversal',AUT:'Autenticación y Acceso',PER:'Perfil y Cuenta',SOC:'Comunidad y Publicaciones',MIS:'Misiones',FIC:'Fichas Profesionales',MAP:'Mapa y Ubicación',PUS:'Notificaciones Push',AR:'Recorridos y Realidad Aumentada',MOD:'Moderación y Administración'};
export const shortModules={BASE:'Transversal',AUT:'Autenticación',PER:'Perfil y cuenta',SOC:'Comunidad',MIS:'Misiones',FIC:'Fichas profesionales',MAP:'Mapa',PUS:'Push',AR:'Recorridos y AR',MOD:'Moderación'};
export const stages=[];export const tasks=[];
function add(id,name,role,text){
 const stage={id,name,role};stages.push(stage);
 text.trim().split('\n').forEach((line,i)=>{
  const [module,title,result,groupId,a,b,state='Completado']=line.split('¦');
  const g=old.groups.find(g=>g.id===groupId);if(!g)throw Error(groupId);
  tasks.push({id:`${id}-${String(i+1).padStart(2,'0')}`,stage:id,stageName:name,module,moduleName:modules[module],title,result,state,start:+a,end:+b,estimated:+b-(+a)+1,real:state==='Completado'?+b-(+a)+1:null,role,assigned:'',performed:'',date:state==='Completado'||state==='WIP'?g.date:null,sources:g.sources,origin:groupId,deps:'',note:state==='Completado'?'R se coloca en los mismos bloques que E por criterio del cronograma; no representa una duración de trabajo medida.':state==='WIP'?'Código integrado; falta aceptación física. R permanece vacía mientras la tarea está abierta.':'Solo estimación; ejecución pendiente.',close:state==='Completado'?'Completado':state==='WIP'?'Validar físicamente reconocimiento, estabilidad y recuperación AR.':result});
 });
}
add('INV','Investigación y Requisitos','Investigación',`
BASE¦Delimitar el problema de conexión local¦Describir la necesidad de conectar personas, proyectos y oportunidades cercanas.¦INV01¦1¦1
BASE¦Identificar necesidades por tipo de usuario¦Diferenciar necesidades de usuario general, creador, emprendimiento y negocio.¦INV01¦1¦1
BASE¦Redactar requisitos y límites del producto¦Priorizar acceso, comunidad, descubrimiento y colaboración local.¦INV01¦1¦1
BASE¦Estudiar Flutter y arquitectura del cliente¦Fundamentar una aplicación compartida para Android, iOS y Web.¦INV02¦1¦1
BASE¦Estudiar servicios de Supabase¦Relacionar Auth, PostgreSQL, Storage y funciones de servidor.¦INV02¦1¦1
BASE¦Definir criterios de privacidad y RLS¦Distinguir datos públicos, privados y permisos por propietario.¦INV02¦1¦1
AUT¦Investigar OTP y consentimiento explícito¦Fundamentar recuperación, términos y declaración de mayoría de edad.¦INV02¦1¦1
PER¦Estudiar almacenamiento privado de imágenes¦Definir propiedad, normalización y acceso mediante URLs firmadas.¦INV02¦1¦1
SOC¦Analizar feed e interacciones sociales¦Determinar categorías, comentarios, reacciones y guardados privados.¦INV01¦1¦1
MIS¦Definir reglas de convocatorias y candidaturas¦Distinguir estados, fechas, cupos, participantes y selección de finalistas.¦INV01¦1¦1
FIC¦Diferenciar portafolio, catálogo y servicios¦Definir obras, productos, precios MXN y disponibilidad.¦INV01¦1¦1
MAP¦Estudiar OpenStreetMap y coordenadas¦Definir precisión aproximada, posición exacta y consulta geográfica.¦INV03¦1¦1
PUS¦Analizar colas de alertas y entrega FCM¦Definir eventos, preferencias y separación entre cola y transporte.¦INV02¦1¦1
AR¦Estudiar panoramas 360° y metadatos GPano¦Definir proyección equirectangular y cobertura de esfera completa.¦INV03¦1¦1
AR¦Investigar cosido Hugin y mezcla Enblend¦Comprender coincidencias, optimización, remapeo y mezcla de tomas.¦INV03¦1¦1
AR¦Estudiar ARCore y ARKit¦Definir soporte nativo y reconocimiento de referencias físicas.¦INV03¦1¦1
AR¦Estudiar orientación, FOV y solapamiento¦Definir yaw, pitch, roll, anillos y cobertura óptica de captura.¦INV03¦1¦1
MOD¦Definir reglas de reportes y moderación¦Separar ocultamiento, restauración y acceso a la cola privada.¦INV01¦1¦1
`);
add('DIS','Planificación y Diseño','Diseño',`
BASE¦Definir el alcance del MVP¦Priorizar cuenta, sesión, perfil y navegación inicial.¦MVP02¦2¦2
BASE¦Definir la paleta oficial MAREA¦Aplicar navy, azul, aqua, mint y superficies claras.¦DIS02¦4¦4
BASE¦Integrar tipografía Nunito Sans¦Unificar pesos, jerarquía de texto y legibilidad.¦MVP02¦2¦2
BASE¦Diseñar componentes y estados de carga¦Definir botones, paneles, campos y MareaSkeleton.¦INT02¦5¦5
BASE¦Diseñar navegación responsiva¦Distribuir Inicio, Explorar, Crear, Misiones y Perfil.¦MVP02¦2¦2
AUT¦Diseñar registro por pasos y recuperación¦Separar identidad, acceso, consentimiento y verificación OTP.¦ACC03¦4¦4
PER¦Diseñar los cuatro tipos de perfil¦Mostrar herramientas específicas y datos opcionales por tipo.¦PRO04¦4¦4
PER¦Diseñar edición de identidad y configuración¦Organizar avatar, portada, seguridad y eliminación de cuenta.¦PRO03¦4¦4
SOC¦Diseñar feed, tarjetas y compositor¦Definir lectura de publicaciones y creación con fotos y categorías.¦SOC01¦4¦4
SOC¦Revisar propuestas visuales v3 a v6¦Comparar alternativas antes de consolidar la interfaz vigente.¦DIS01¦4¦4
SOC¦Consolidar interfaz social v7¦Aplicar diseño final de feed, comentarios y acciones sociales.¦DIS02¦4¦4
MIS¦Diseñar creación y administración de misiones¦Organizar fechas, cupos, borradores y control del organizador.¦MIS02¦4¦4
MIS¦Diseñar candidatura y selección de finalistas¦Definir formulario estructurado y seguimiento del participante.¦MIS03¦4¦4
FIC¦Diseñar fichas de obra, producto y servicio¦Organizar galería, precio, disponibilidad y contacto.¦PRO02¦4¦4
MAP¦Diseñar mapa, filtros y selección de ubicación¦Permitir elegir área, radio y precisión de coordenadas.¦MAP01¦5¦5
PUS¦Diseñar bandeja y preferencias de alertas¦Distinguir lectura, navegación al destino y configuración push.¦PUS01¦5¦5
AR¦Diseñar captura, visor y experiencia presencial¦Definir zonas, puntos, progreso y recuperación de la experiencia AR.¦TOU01¦5¦5
MOD¦Diseñar reportes y cola de moderación¦Definir acceso privado, revisión, ocultamiento y restauración.¦COM03¦3¦3
`);
add('BD','Desarrollo Base de Datos y Back-end','Backend',`
AUT¦Crear perfiles iniciales y trigger de Auth¦Generar perfil de cada nueva cuenta desde el servidor.¦MVP04¦2¦2
AUT¦Implementar políticas de registro y consentimientos¦Persistir términos vigentes y mayoría de edad sin escritura directa.¦ACC01¦2¦2
AUT¦Proteger cambios sensibles de la cuenta¦Restringir rol, identidad interna y operaciones autenticadas.¦ACC01¦2¦2
PER¦Ampliar modelo para cuatro tipos de perfil¦Guardar datos profesionales y campos permitidos por tipo.¦PRO01¦4¦4
PER¦Implementar almacenamiento privado de avatar y portada¦Validar imágenes y generar URLs firmadas de presentación.¦ACC02¦2¦2
PER¦Implementar eliminación de cuenta y limpieza¦Borrar datos y recursos asociados con validación de identidad.¦COM03¦3¦3
SOC¦Crear publicaciones y políticas de visibilidad¦Persistir contenido, categorías y propiedad de cada publicación.¦COM01¦3¦3
SOC¦Crear procesamiento privado de fotografías¦Normalizar imágenes y restringir cargas al propietario.¦COM01¦3¦3
SOC¦Implementar comentarios y reacciones¦Persistir interacciones con permisos y operaciones coordinadas.¦SOC02¦4¦4
SOC¦Implementar guardados privados¦Separar publicaciones guardadas del contenido público.¦SOC03¦4¦4
SOC¦Implementar intereses, enlaces y eventos en tiempo real¦Sincronizar avisos y datos sociales con aislamiento de privacidad.¦SOC04¦4¦4
MIS¦Crear modelo y ciclo de vida de misiones¦Definir borrador, publicación, cierre y estados de convocatoria.¦MIS01¦3¦3
MIS¦Implementar fechas, cupos y operaciones atómicas¦Validar ventanas de participación y prevenir ocupación duplicada.¦MIS02¦4¦4
MIS¦Guardar candidaturas estructuradas¦Persistir respuestas y permitir consulta privada autorizada.¦MIS03¦4¦4
MIS¦Implementar evaluación de finalistas y avisos¦Registrar decisiones del organizador y notificar cambios de estado.¦MIS04¦4¦4
FIC¦Crear modelo de portafolio, catálogo y servicios¦Diferenciar fichas independientes del feed social.¦PRO02¦4¦4
FIC¦Guardar galerías, precio MXN y disponibilidad¦Validar contenido profesional y permisos de edición.¦PRO02¦4¦4
MAP¦Crear consultas de mapa y filtros por radio¦Consultar coordenadas y misiones dentro del área solicitada.¦MAP01¦5¦5
PUS¦Crear cola de entrega y preferencias push¦Persistir tokens, eventos y configuración por usuario.¦PUS02¦5¦5
PUS¦Implementar envío FCM y reintentos¦Procesar la cola sin duplicar avisos y limpiar tokens inválidos.¦PUS02¦5¦5
AR¦Crear migración de recorridos, zonas y versiones¦Persistir estructura de captura y resultados por versión.¦TOU06¦5¦5
AR¦Implementar bucket privado y carga reanudable¦Aislar recursos y permitir retomar transferencias TUS.¦TOU05¦5¦5
AR¦Implementar cola, leases y limpieza de recorridos¦Coordinar ejecución, cancelación y eliminación recursiva.¦TOU06¦5¦5
AR¦Implementar procesador Hugin y Enblend¦Generar panorama, vista previa y metadatos GPano.¦TOU07¦5¦5
MOD¦Crear reportes y cola privada de moderación¦Permitir revisión autorizada de publicaciones y misiones.¦COM03¦3¦3
MOD¦Implementar ocultamiento, restauración y limpieza¦Controlar visibilidad y eliminación segura de imágenes.¦COM03¦3¦3
`);
add('FE','Desarrollo Front-end (Cliente)','Frontend',`
BASE¦Crear proyecto Flutter y configuración del cliente¦Preparar Android, iOS y Web con dependencias y parámetros públicos.¦MVP01¦2¦2
BASE¦Configurar rutas y continuidad de sesión¦Implementar go_router, guards y restauración del destino.¦MVP01¦2¦2
AUT¦Implementar registro en pasos y validadores¦Capturar datos y bloquear entradas incompletas o inválidas.¦ACC03¦4¦4
AUT¦Implementar inicio, cierre y persistencia de sesión¦Sincronizar autenticación y perfil durante aperturas y cambios de cuenta.¦MVP03¦2¦2
AUT¦Implementar recuperación mediante OTP¦Solicitar, verificar y reenviar códigos con control de espera.¦ACC01¦2¦2
AUT¦Implementar cambios de contraseña y correo¦Solicitar reautenticación y confirmar operaciones sensibles.¦ACC01¦2¦2
AUT¦Implementar aceptación de términos y mayoría de edad¦Mostrar consentimientos explícitos y conservar la ruta pendiente.¦ACC01¦2¦2
PER¦Implementar selección de los cuatro perfiles¦Presentar configuración y herramientas por tipo de cuenta.¦PRO04¦4¦4
PER¦Implementar edición de identidad y datos profesionales¦Guardar nombre, usuario, biografía y campos del perfil.¦PRO03¦4¦4
PER¦Implementar selección de avatar y portada¦Mostrar vista previa, normalizar imágenes y sincronizar cambios.¦ACC02¦2¦2
PER¦Implementar configuración y eliminación de cuenta¦Mostrar controles de seguridad y confirmación de borrado.¦PRO03¦4¦4
SOC¦Implementar feed de inicio y exploración¦Cargar publicaciones, búsqueda y estados vacíos.¦SOC01¦4¦4
SOC¦Implementar creación de posts con categorías y fotos¦Permitir redactar, adjuntar y publicar contenido validado.¦COM01¦3¦3
SOC¦Implementar reacciones optimistas y gestos¦Actualizar acciones visibles y recuperar el estado tras errores.¦INT01¦5¦5
SOC¦Implementar bandeja de comentarios¦Permitir consultar, redactar y responder interacciones del post.¦SOC02¦4¦4
SOC¦Implementar enlaces sociales y guardados¦Abrir enlaces y gestionar colecciones privadas del usuario.¦SOC03¦4¦4
SOC¦Implementar sincronización y paneles compartidos¦Actualizar datos en tiempo real y unificar cargas y acciones.¦INT02¦5¦5
MIS¦Implementar compositor y borradores de misión¦Capturar descripción, fechas, cupos y publicación de convocatoria.¦MIS02¦4¦4
MIS¦Implementar formulario de candidatura¦Enviar respuestas estructuradas y mostrar el estado de participación.¦MIS03¦4¦4
MIS¦Implementar gestión de finalistas por organizador¦Revisar postulantes y guardar decisiones privadas.¦MIS04¦4¦4
MIS¦Implementar listado y avisos del ciclo de misión¦Mostrar fechas, estado, cupos y seguimiento del participante.¦MIS04¦4¦4
FIC¦Implementar creación de fichas profesionales¦Publicar obras, productos y servicios según el tipo de perfil.¦PRO02¦4¦4
FIC¦Implementar galería, precio y disponibilidad¦Editar imágenes y datos comerciales con validación MXN.¦PRO02¦4¦4
FIC¦Implementar detalle y herramientas de fichas¦Mostrar contenido y permitir edición o eliminación autorizada.¦PRO02¦4¦4
MAP¦Integrar mapa OpenStreetMap y selección de ubicación¦Mostrar teselas, atribución y posición aproximada o exacta.¦MAP01¦5¦5
MAP¦Implementar búsqueda por área y radios de 1 a 10 km¦Actualizar resultados al explorar y filtrar el mapa.¦MAP01¦5¦5
MAP¦Implementar clusters y navegación a misiones¦Agrupar marcadores y abrir detalles desde la posición seleccionada.¦MAP01¦5¦5
PUS¦Integrar cliente FCM y permisos Android¦Registrar tokens y recibir avisos en los estados de la aplicación.¦PUS01¦5¦5
PUS¦Implementar preferencias y apertura de notificaciones¦Gestionar opt-in, lectura y navegación al destino correcto.¦PUS01¦5¦5
AR¦Implementar editor de recorridos, zonas y puntos¦Administrar estructura y versiones de captura del local.¦TOU02¦5¦5
AR¦Implementar captura guiada y orientación nativa¦Guardar tomas y mostrar cobertura usando sensores móviles.¦TOU03¦5¦5
AR¦Implementar importación GPano y subida reanudable¦Validar panoramas y recuperar transferencias interrumpidas.¦TOU05¦5¦5
AR¦Implementar visor 360° y progreso del recorrido¦Navegar panoramas y mostrar estado de procesamiento.¦TOU08¦5¦5
AR¦Integrar reconocimiento y recuperación AR nativos¦Completar aceptación física del código Android e iOS integrado.¦AR01¦5¦7¦WIP
MOD¦Implementar reporte de publicación y misión¦Capturar motivo y enviar el reporte para revisión privada.¦COM03¦3¦3
MOD¦Implementar bandeja privada de moderación¦Mostrar contenidos reportados únicamente al rol autorizado.¦COM03¦3¦3
MOD¦Implementar acciones de ocultar y restaurar¦Actualizar contenido revisado y confirmar acciones sensibles.¦COM03¦3¦3
BASE¦Unificar diseño responsivo, skeletons y refresco¦Aplicar estados de carga y controles coherentes en todos los módulos.¦INT02¦5¦5
`);
add('QA','Pruebas y Verificación (QA)','QA',`
AUT¦Verificar validadores, sesión y guards de acceso¦Cubrir entradas inválidas, recuperación de sesión y redirecciones.¦QA01¦3¦3
AUT¦Verificar contrato SQL de consentimientos y privacidad¦Comprobar permisos y protección de campos sensibles.¦QA01¦3¦3
PER¦Verificar widgets y tipos de perfil¦Validar estados y herramientas de los cuatro perfiles.¦PRO03¦4¦4
SOC¦Verificar comentarios, reacciones y guardados¦Comprobar permisos y contratos de las interacciones sociales.¦SOC05¦4¦4
SOC¦Verificar regresión de la interfaz v7¦Comprobar feed, formularios, paneles y adaptación de pantallas.¦SOC05¦4¦4
MIS¦Ejecutar comprobaciones SQL de misiones¦Comprobar cupos, candidaturas, finalistas y aislamiento de organizador.¦MIS05¦4¦4
MIS¦Verificar widgets y regresión de candidaturas¦Comprobar compositor, seguimiento y decisiones del organizador.¦MIS05¦4¦4
FIC¦Verificar edición y visibilidad de fichas¦Comprobar galería, disponibilidad y acceso por tipo de cuenta.¦PRO02¦4¦4
PUS¦Verificar envío y apertura push en Samsung¦Comprobar avisos con app visible, en segundo plano y proceso cerrado.¦PUS04¦5¦5
AR¦Ejecutar pruebas automáticas de recorridos¦Comprobar cliente, procesador, contratos SQL y código nativo.¦TOU10¦5¦5
AR¦Procesar panoramas con fixtures sintéticos¦Verificar Hugin, Enblend, formatos de salida y metadatos GPano.¦PIL01¦5¦5
AR¦Corregir fallos encontrados en el piloto local¦Resolver mezcla, respuestas vacías, reintentos y renovación de leases.¦PIL01¦5¦5
AUT¦Verificar entrega real de OTP y recuperación¦Completar flujo de correo desde una cuenta nueva en dispositivo.¦QA02¦6¦6¦Pendiente
PER¦Verificar privacidad al cambiar de sesión¦Comprobar aislamiento de medios y datos entre dos cuentas físicas.¦QA02¦6¦6¦Pendiente
SOC¦Verificar fotografías y gestos en dispositivos reales¦Probar cámara, galería, teclado y errores de conectividad.¦QA02¦6¦6¦Pendiente
MAP¦Verificar permisos GPS y búsqueda geográfica real¦Probar ubicación denegada, precisión y filtros en movimiento.¦QA02¦6¦6¦Pendiente
PUS¦Probar permisos, cambio de cuenta y renovación de token¦Completar matriz física adicional de notificaciones Android.¦QA03¦6¦7¦Pendiente
MOD¦Verificar reportes y restauración con cuentas reales¦Comprobar acceso restringido y cambios visibles tras moderación.¦QA03¦7¦7¦Pendiente
AR¦Calibrar captura óptica y FOV en teléfonos¦Medir cobertura real y ajustar orientación y encuadre.¦FIS01¦6¦7¦Pendiente
AR¦Validar panoramas de un local físico¦Revisar costuras, zonas próximas, baja textura y cobertura completa.¦FIS01¦7¦8¦Pendiente
AR¦Validar reconocimiento AR en Android e iPhone¦Comprobar referencia física, estabilidad y seguimiento nativo.¦FIS02¦7¦8¦Pendiente
AR¦Validar recuperación, permisos y equipos sin soporte¦Comprobar fallbacks y recuperación después de perder tracking.¦FIS02¦8¦8¦Pendiente
AR¦Corregir incidencias de captura y reconocimiento¦Resolver hallazgos de la aceptación física y repetir casos afectados.¦COR01¦8¦9¦Pendiente
BASE¦Ejecutar regresión integrada después de los ajustes¦Comprobar módulos, privacidad y recorridos antes del piloto final.¦QA03¦9¦10¦Pendiente
`);
add('DEP','Despliegue y Pilotos','DevOps',`
BASE¦Publicar repositorio y conservar historial del MVP¦Integrar la entrega pública y los antecedentes del desarrollo.¦GIT01¦4¦4
AUT¦Aplicar migraciones iniciales de acceso y cuenta¦Configurar Auth, políticas y funciones del MVP remoto.¦ACC01¦2¦2
SOC¦Aplicar migraciones sociales y almacenamiento¦Habilitar feed, fotografías y permisos del entorno remoto.¦COM01¦3¦3
BASE¦Integrar perfiles, fichas y diseño social v7¦Publicar migraciones y versión visual consolidada.¦SOC05¦4¦4
MIS¦Desplegar rediseño de misiones y verificar contrato¦Aplicar migración y comprobar consultas del organizador y participante.¦MIS05¦4¦4
MAP¦Aplicar consultas de mapa al backend remoto¦Habilitar filtros geográficos usados por el cliente.¦MAP01¦5¦5
PUS¦Configurar Firebase y secretos de entrega en Vault¦Preparar credenciales y transporte FCM para Android.¦PUS03¦5¦5
PUS¦Desplegar función push y programar la cola¦Activar send-push, pg_net y ejecución periódica.¦PUS03¦5¦5
BASE¦Publicar compilación Web y preparar APK¦Distribuir la versión actual con configuración del entorno.¦PUS03¦5¦5
AR¦Aplicar migración de recorridos y limpieza remota¦Habilitar bucket privado, tour-dispatch y borrado recursivo.¦PIL01¦5¦5
AR¦Ejecutar piloto Docker con Supabase real¦Procesar fixtures y verificar contratos de cola y almacenamiento.¦PIL01¦5¦5
AR¦Habilitar facturación e identidad de Google Cloud¦Resolver requisitos externos para ejecutar el worker en la nube.¦CLO01¦6¦7¦Pendiente
AR¦Configurar IAM, secretos y registro de imágenes¦Preparar accesos del servicio y artefactos del procesador.¦CLO01¦7¦8¦Pendiente
AR¦Desplegar worker en Cloud Run y activar monitoreo¦Publicar servicio y comprobar dispatch, colas y alertas operativas.¦CLO01¦8¦9¦Pendiente
BASE¦Preparar distribución Android e instalación iOS de piloto¦Generar APK y resolver firma autorizada para iPhone.¦ENT01¦9¦9¦Pendiente
BASE¦Ejecutar piloto de aceptación en un local real¦Recorrer cuenta, comunidad, misiones, catálogo, push y AR.¦PIL02¦9¦10¦Pendiente
BASE¦Estabilizar la versión tras el piloto¦Resolver incidencias y comprobar nuevamente los flujos afectados.¦ENT01¦10¦11¦Pendiente
BASE¦Entregar la versión técnica final el 18 de noviembre¦Consolidar configuración, compilaciones y estado de aceptación.¦ENT01¦11¦11¦Pendiente
`);
for(const t of tasks){
 if(t.stage==='INV'){t.note='Investigación realizada según confirmación general del usuario. Distribución semanal retrospectiva; no hay duración individual medida.';t.date=null;}
 // Dependencias por módulo y etapa; no obligan a que se ejecute toda una etapa antes de iniciar otra.
 const previous=tasks.filter(p=>p.module===t.module&&p.stage!==t.stage&&p.state==='Completado'&&p.end<=t.start&&stages.findIndex(s=>s.id===p.stage)<stages.findIndex(s=>s.id===t.stage));
 t.deps=previous.length?previous.at(-1).id:'';
}
export const team={Santiago:'Líder AR',Cristopher:'Back-end AR',Alan:'Base de datos',Ximena:'AR',Josefina:'Documentación y planeación',Fatima:'UI/UX'};
for(const t of tasks){
 t.assigned=t.stage==='INV'?'Josefina':t.stage==='DIS'?(t.module==='AR'?'Santiago':t.id==='DIS-01'?'Josefina':'Fatima'):t.stage==='BD'?(t.module==='AR'&&t.id==='BD-24'?'Cristopher':t.module==='PUS'&&t.id==='BD-20'?'Cristopher':['BD-05','BD-06','BD-08'].includes(t.id)?'Cristopher':'Alan'):t.stage==='FE'?(t.module==='AR'?(t.id==='FE-34'?'Santiago':'Ximena'):t.module==='PUS'||t.module==='AUT'?'Cristopher':'Fatima'):t.stage==='QA'?(t.module==='AR'?(t.id==='QA-21'||t.id==='QA-22'?'Santiago':t.id==='QA-19'||t.id==='QA-20'?'Ximena':'Cristopher'):['QA-02','QA-04','QA-06','QA-14','QA-18'].includes(t.id)?'Alan':t.module==='PUS'||t.id==='QA-13'||t.id==='QA-24'?'Cristopher':'Fatima'):t.id==='DEP-18'?'Josefina':t.id==='DEP-16'||t.id==='DEP-17'?'Santiago':['DEP-02','DEP-03','DEP-04','DEP-05','DEP-06','DEP-10'].includes(t.id)?'Alan':'Cristopher';
 t.role=team[t.assigned];
}
export const metadata={cutoff:'2026-10-06',period:'01 septiembre–18 noviembre 2026',research:'Confirmación general del usuario',realRule:'Completado: R en los mismos bloques que E. WIP y Pendiente: solo E. Alineación semanal solicitada, sin duración de esfuerzo medida.',planning:'E es una propuesta retrospectiva para lo terminado y futura para los pendientes.',roster:'Reparto propuesto con los nombres y especialidades indicados por el usuario. Realizado por queda editable: no se atribuye autoría histórica.'};
