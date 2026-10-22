export const groups = [];
export const tasks = [];
export const blocks = [
  ['SEP-1','Septiembre','S1','01–07 sep','2026-09-01','2026-09-07'],
  ['SEP-2','Septiembre','S2','08–14 sep','2026-09-08','2026-09-14'],
  ['SEP-3','Septiembre','S3','15–21 sep','2026-09-15','2026-09-21'],
  ['SEP-4','Septiembre','S4','22–30 sep','2026-09-22','2026-09-30'],
  ['OCT-1','Octubre','S1','01–07 oct','2026-10-01','2026-10-07'],
  ['OCT-2','Octubre','S2','08–14 oct','2026-10-08','2026-10-14'],
  ['OCT-3','Octubre','S3','15–21 oct','2026-10-15','2026-10-21'],
  ['OCT-4','Octubre','S4','22–31 oct','2026-10-22','2026-10-31'],
  ['NOV-1','Noviembre','S1','01–07 nov','2026-11-01','2026-11-07'],
  ['NOV-2','Noviembre','S2','08–14 nov','2026-11-08','2026-11-14'],
  ['NOV-3','Noviembre','S3','15–18 nov','2026-11-15','2026-11-18'],
  ['NOV-4','Noviembre','S4','Fuera de plazo',null,null],
];
function add(id,name,start,end,date,state,sources,deps,text,note='') {
  const group = {id,name,start,end,date,state,sources,deps,note};
  groups.push(group);
  text.trim().split('\n').filter(Boolean).forEach((line,i)=>{
    const [title,result,override,extraDeps] = line.trim().split('¦');
    tasks.push({id:`${id}.${String(i+1).padStart(3,'0')}`,parent:id,group:name,title,result,
      start,end,date,state:override||state,sources,deps:extraDeps||deps,note,
      estimated:end-start+1,realStart:null,realEnd:null,real:null,assigned:'',performed:'',
      pending:(override||state)==='WIP'?'Validación física/aceptación del módulo pendiente.':
        (override||state)==='Bloqueado'?'Resolver credenciales, permisos o firma indicados en el resultado.':
        (override||state)==='Pendiente'?'Ejecutar la actividad y registrar resultado, responsables y duración real.':
        state==='Sustituido'?'Propuesta conservada como antecedente; no representa la interfaz vigente.':
        id.startsWith('INV')?'Confirmar el detalle del tema estudiado y capturar su duración real.':''});
  });
}

const research='Realización de investigación confirmada por el usuario en este chat; desglose temático reconstruido desde los requisitos y la arquitectura del repositorio. No acredita fechas ni el estudio individual de cada tema.';
add('INV01','Investigación del problema y requisitos',1,1,null,'Completado',
 ['README.md','docs/design-experiments/mobile-social-ui-product.md','docs/design-experiments/social-mobile-redesign-product.md'],'',`
Delimitar el problema de conexión comunitaria¦Definir la necesidad de descubrir personas, proyectos y oportunidades locales.
Identificar al usuario general¦Describir su participación mediante publicaciones, búsqueda, guardados y misiones.
Identificar necesidades de artistas y creadores¦Separar exposición de obras, portafolio y colaboración.
Identificar necesidades de emprendimientos¦Distinguir catálogo, productos, servicios y contacto.
Identificar necesidades de negocios¦Distinguir servicios, espacios, horarios, ubicación y recorridos.
Definir funciones de administración¦Separar moderación y acreditación del tipo de perfil.
Inventariar requisitos funcionales¦Organizar acceso, identidad, contenido, participación y recorridos.
Inventariar requisitos no funcionales¦Considerar privacidad, persistencia, compatibilidad y accesibilidad.
Delimitar el primer MVP¦Priorizar cuenta, sesión y perfil antes de la comunidad completa.
Definir límites de alcance¦Separar la aplicación de pagos, chat y reconstrucción 3D no implementados.
Definir criterios de aceptación por módulo¦Vincular cada capacidad con un resultado comprobable.
Estudiar navegación social móvil y web¦Revisar jerarquía de Inicio, Explorar, Crear, Misiones y Perfil.
`,research);
add('INV02','Fundamentos de arquitectura, datos y seguridad',1,1,null,'Completado',
 ['README.md','docs/design-system.md','docs/account-completion.md','supabase/migrations/001_initial_schema.sql'],'INV01',`
Estudiar Flutter y Dart para el cliente¦Fundamentar la aplicación compartida para Android, web e iOS.
Estudiar integración nativa móvil¦Separar responsabilidades Flutter, Kotlin y Swift.
Estudiar Supabase como backend¦Relacionar Auth, PostgreSQL, Storage y Edge Functions.
Estudiar arquitectura por funcionalidades¦Separar presentación, modelos, repositorios y servicios compartidos.
Estudiar navegación y guards¦Fundamentar protección de rutas y continuidad del destino interno.
Estudiar ciclo de sesión¦Considerar persistencia, renovación, cierre y cambio de cuenta.
Estudiar modelado relacional¦Relacionar perfiles, contenido, misiones y participación.
Estudiar RLS y permisos por columna¦Fundamentar aislamiento de filas y protección de campos internos.
Estudiar operaciones atómicas¦Considerar cupos, publicación, confirmaciones y cambios coordinados.
Estudiar idempotencia de operaciones¦Prevenir duplicados por reintentos y respuestas perdidas.
Estudiar almacenamiento privado¦Diferenciar originales privados, recursos visibles y URLs firmadas.
Estudiar privacidad de identidad y preferencias¦Separar datos de acceso de la presentación pública.
Estudiar diseño accesible¦Considerar contraste, controles de 48 px, teclado y texto ampliado.
Estudiar pruebas por capas¦Distinguir unidades, widgets, SQL aislado y servicios reales.
`,research);
add('INV03','Fundamentos de mapas, panoramas y AR',1,1,null,'Completado',
 ['docs/map.md','docs/ar-experience-design.md','docs/implementation/tours-native.md','processing/tours/README.md'],'INV01, INV02',`
Estudiar coordenadas y precisión de ubicación¦Diferenciar posición exacta, aproximada y ubicación textual.
Estudiar cartografía OpenStreetMap¦Considerar teselas, atribución y consulta por área visible.
Estudiar permisos de geolocalización¦Distinguir solicitud explícita y exploración sin GPS.
Estudiar panoramas equirectangulares¦Distinguir una esfera 360°×180° de una imagen horizontal común.
Estudiar metadatos GPano¦Relacionar proyección, dimensiones y cobertura de esfera completa.
Estudiar campo de visión y solapamiento¦Fundamentar anillos, techo, piso y tomas desde una posición fija.
Estudiar cosido Hugin y mezcla Enblend¦Separar coincidencias, optimización, remapeo y mezcla.
Estudiar reconocimiento de imágenes AR¦Diferenciar reconocimiento físico de un QR o coordenada GPS.
Estudiar ARCore y ARKit¦Considerar soporte nativo, ancho físico de referencia y tracking.
Estudiar orientación yaw, pitch y roll¦Considerar ejes ópticos, horizonte, polos y costura angular.
Estudiar cargas reanudables TUS¦Fundamentar checkpoints, offsets y recuperación por HEAD.
Estudiar colas y leases de procesamiento¦Considerar concurrencia, cancelación, reintentos y limpieza.
`,research);

add('MVP01','Base técnica y arquitectura inicial',2,2,'2026-09-11','Completado',
 ['git:b92a237:README.md','git:b92a237:pubspec.yaml','git:b92a237:lib/main.dart','git:b92a237:lib/core/config/app_config.dart'],'INV02',`
Crear el proyecto Flutter¦Preparar la estructura ejecutable inicial de MAREA.
Configurar dependencias del MVP¦Integrar go_router y supabase_flutter en el manifiesto.
Crear la entrada main.dart¦Inicializar Flutter y la configuración del cliente.
Leer configuración pública de Supabase¦Obtener URL y clave publicable mediante defines.
Mostrar error de configuración faltante¦Evitar inicializar Supabase sin valores necesarios.
Crear AppSessionController¦Centralizar estado de sesión y carga del perfil.
Crear el enrutador de la aplicación¦Definir destinos y redirecciones por sesión.
Crear estados de error comunes¦Traducir fallos técnicos a mensajes de la aplicación.
Definir validadores de formularios¦Validar nombre, usuario, correo y contraseña.
Configurar Android com.marea.app¦Preparar identificador y minSdk 24 del MVP.
Preparar el proyecto iOS¦Conservar Runner, configuración Flutter y esquema de ejecución.
Preparar el cliente web¦Crear index, manifiesto e iconos iniciales.
Configurar exclusiones de archivos locales¦Separar configuración y artefactos del código compartido.
Configurar análisis estático¦Definir reglas Dart y análisis del proyecto.
Documentar configuración y ejecución¦Explicar cómo conectar y ejecutar el primer MVP.
`,'La fecha corresponde al primer commit conservado; no identifica inicio ni duración de cada subtarea.');
add('MVP02','Diseño y navegación del primer MVP',2,2,'2026-09-11','Completado',
 ['git:b92a237:docs/design-system.md','git:b92a237:lib/core/theme/app_theme.dart','git:b92a237:lib/features/shell/presentation/app_shell.dart'],'MVP01',`
Definir la paleta inicial MAREA¦Crear tokens navy, azul, aqua y superficies claras.
Instalar Nunito Sans local¦Incorporar pesos y licencia de la tipografía.
Definir espaciados y radios¦Uniformar formularios, tarjetas y controles.
Personalizar Material 3¦Aplicar tema compartido a pantallas del MVP.
Crear el logotipo provisional en código¦Mostrar identidad inicial antes de integrar archivos oficiales.
Crear el campo de texto compartido¦Reutilizar etiquetas, errores y entrada de datos.
Crear el botón primario¦Unificar acción principal y estado de envío.
Crear layout de autenticación¦Adaptar formularios a móvil y escritorio.
Crear shell de navegación¦Presentar Inicio, Explorar, Crear, Misiones y Perfil.
Adaptar navegación al ancho de pantalla¦Separar presentación móvil y escritorio.
Mostrar secciones próximas del MVP¦Explicar módulos aún no implementados sin datos falsos.
Crear indicador inicial de avatar¦Mostrar iniciales o presentación disponible del perfil.
`);
add('MVP03','Autenticación del primer MVP',2,2,'2026-09-11','Completado',
 ['git:b92a237:lib/features/auth/data/auth_repository.dart','git:b92a237:lib/features/auth/presentation/register_screen.dart','git:b92a237:lib/core/session/app_session_controller.dart'],'MVP01',`
Crear pantalla de carga inicial¦Resolver sesión antes de mostrar el destino.
Crear formulario inicial de registro¦Capturar identidad y credenciales del MVP.
Validar campos obligatorios de registro¦Impedir envío de datos incompletos.
Validar formato de correo¦Mostrar errores antes de enviar el formulario.
Validar contraseña mínima¦Aplicar el requisito de acceso establecido.
Consultar disponibilidad del username¦Detectar colisiones sin exponer perfiles.
Registrar usuario en Supabase Auth¦Crear cuenta usando el repositorio de autenticación.
Mostrar instrucción de confirmación de correo¦Presentar el siguiente paso tras registrar.
Crear formulario de inicio de sesión¦Permitir acceso con correo y contraseña.
Mostrar fallos de autenticación¦Presentar error y permitir reintento.
Persistir sesión entre aperturas¦Restaurar estado de acceso desde Supabase.
Cargar perfil después de autenticar¦Sincronizar identidad con la sesión.
Proteger destinos privados¦Redirigir a acceso cuando no existe sesión.
Cerrar sesión desde configuración¦Limpiar estado y regresar al acceso.
Bloquear envíos repetidos¦Evitar solicitudes paralelas desde los botones.
`);
add('MVP04','Base de datos y cuenta del primer MVP',2,2,'2026-09-11','Completado',
 ['git:b92a237:supabase/migrations/001_initial_schema.sql','git:b92a237:supabase/functions/delete-account/index.ts','git:b92a237:lib/features/profile/data/profile_repository.dart'],'MVP01',`
Crear migración 001 de perfiles¦Definir perfil relacionado con auth.users.
Crear perfil mediante trigger de Auth¦Asignar identidad y rol desde servidor.
Habilitar RLS en perfiles¦Restringir lectura y actualización a la cuenta autorizada.
Proteger rol y timestamps¦Impedir escritura cliente de campos internos.
Crear consulta segura de username¦Devolver disponibilidad sin publicar datos privados.
Crear modelo Profile inicial¦Representar nombre, usuario y presentación.
Crear repositorio de perfil¦Leer y actualizar los campos autorizados.
Crear pantalla de perfil inicial¦Mostrar la identidad persistida.
Crear editor de identidad inicial¦Editar nombre, username y bio.
Crear pantalla de configuración¦Reunir sesión y acciones de cuenta.
Implementar eliminación autenticada de cuenta¦Obtener identidad del JWT antes del borrado.
Eliminar perfil mediante cascade¦Coordinar borrado de Auth y datos asociados del MVP.
Confirmar borrado desde el cliente¦Solicitar confirmación antes de ejecutar la acción.
`);
add('MVP05','Verificación del MVP',2,2,'2026-09-11','Completado',
 ['git:b92a237:README.md','git:b92a237:test/core/session/app_session_controller_test.dart','git:b92a237:test/features/presentation/screens_test.dart'],'MVP02, MVP03, MVP04',`
Probar configuración de la aplicación¦Cubrir valores disponibles y configuración faltante.
Probar validadores iniciales¦Cubrir entradas válidas y mensajes de error.
Probar estados de sesión¦Cubrir acceso, carga de perfil y cierre.
Probar redirecciones de rutas¦Verificar guards para destinos privados.
Probar modelo inicial de perfil¦Verificar lectura de los campos del backend.
Probar pantallas y formularios¦Cubrir acciones visibles y errores del MVP.
Documentar comprobaciones remotas del MVP¦Separar instrucciones de pruebas de evidencia de ejecución.
`,'Los archivos de pruebas acreditan su implementación; los comandos de README no se toman como prueba de ejecución.');

add('ACC01','Ampliación de acceso, seguridad y consentimientos',2,2,'2026-09-14','Completado',
 ['docs/account-completion.md','docs/deployment-status.md','docs/superpowers/plans/2026-09-14-account-completion.md','supabase/migrations/002_account_completion.sql'],'MVP03, MVP04',`
Crear bienvenida pública¦Ofrecer Crear cuenta e Iniciar sesión sin autenticar.
Publicar rutas de términos y privacidad¦Permitir lectura de documentos sin sesión.
Publicar ayuda de eliminación de cuenta¦Ofrecer instrucciones sin reinstalar la aplicación.
Crear política de registro del servidor¦Consultar documentos vigentes y apertura de registros.
Bloquear registro con documentos faltantes¦Validar la política en cliente y trigger de Auth.
Agregar declaración separada de mayoría de edad¦Exigir selección explícita sin recopilar cumpleaños.
Agregar aceptación contractual explícita¦Evitar casillas preseleccionadas.
Persistir versiones de consentimiento¦Registrar versiones y fecha generada por servidor.
Proteger historial de aceptaciones¦Impedir inserción, modificación y borrado directos.
Solicitar aceptación a cuentas existentes¦No fabricar consentimientos para perfiles previos.
Permitir gestionar cuenta sin aceptar cambios¦Mantener acceso a eliminación y administración básica.
Crear pantalla de código de correo¦Capturar OTP y mostrar destino de verificación.
Implementar reenvío con espera¦Aplicar cooldown de 60 segundos tras solicitud aceptada.
Separar solicitud de recuperación¦Capturar correo sin revelar si existe una cuenta.
Verificar código de recuperación¦Validar OTP antes de cambiar contraseña.
Guardar nueva contraseña recuperada¦Completar el flujo tras verificación.
Crear cambio de correo seguro¦Solicitar contraseña actual y confirmación requerida.
Crear cambio de contraseña autenticado¦Solicitar contraseña actual y reautenticación cuando corresponda.
Clasificar sesión inválida y errores de red¦Dar mensajes y acciones adecuados en acceso.
Conservar destino durante pasos de cuenta¦Retomar la ruta interna tras completar autenticación.
`,'Fecha de evidencia del reporte de cuenta; las actualizaciones posteriores se desglosan en sus propias etapas.');
add('ACC02','Fotografías de perfil y almacenamiento privado',2,2,'2026-09-14','Completado',
 ['docs/account-completion.md','lib/features/profile/data/profile_media_repository.dart','supabase/functions/profile-media/index.ts','supabase/functions/profile-media/image.ts'],'ACC01',`
Seleccionar avatar desde galería¦Abrir selector de imágenes de la plataforma.
Mostrar vista previa del avatar¦Revisar la imagen antes de guardar.
Seleccionar portada desde galería¦Preparar imagen de cabecera del perfil.
Ofrecer portadas prediseñadas MAREA¦Permitir elegir entre cuatro portadas.
Validar peso de imagen de entrada¦Rechazar archivos que excedan el límite de entrada.
Validar resolución de entrada¦Rechazar imágenes que excedan 24 megapíxeles.
Normalizar avatar localmente¦Generar PNG de hasta 640 px sin EXIF.
Normalizar portada localmente¦Generar PNG de hasta 1600 px sin EXIF.
Aplicar ajuste centrado de imagen¦Preparar salida sin introducir recorte manual.
Crear bucket privado profile-media¦Guardar recursos bajo propiedad de la cuenta.
Validar JWT en profile-media¦Verificar identidad antes de aceptar escritura.
Volver a decodificar imagen en Edge¦Normalizar PNG y validar tamaño y dimensiones.
Restringir escritura directa de medios¦Exigir función validada para upload y eliminación.
Generar URLs firmadas de presentación¦Entregar acceso temporal de diez minutos.
Conservar imagen anterior durante guardado¦Reemplazar referencia solo tras confirmar perfil.
Quitar avatar o portada¦Eliminar referencia de forma controlada.
Avisar sobre edición sin guardar¦Ofrecer continuar o descartar cambios.
Limpiar imágenes de edición abandonada¦Retirar archivos sin referencias tras el plazo definido.
Coordinar subidas con eliminación de cuenta¦Bloquear nuevas escrituras cuando comienza el borrado.
`);
add('COM01','Comunidad y publicaciones iniciales',3,3,'2026-09-16','Completado',
 ['docs/community.md','docs/deployment-status.md','supabase/migrations/003_community.sql','lib/features/community/data/community_repository.dart'],'ACC01, ACC02',`
Crear tablas de publicaciones¦Persistir autor, tipo, categoría y contenido.
Crear catálogo de categorías¦Compartir opciones entre búsqueda y formularios.
Definir tipos de publicaciones por perfil¦Limitar nuevas opciones según capacidades.
Crear modelo de publicación¦Representar datos persistidos del feed.
Crear repositorio de comunidad¦Conectar lectura y operaciones de contenido con Supabase.
Crear feed de Inicio¦Mostrar publicaciones reales de la comunidad.
Crear pantalla Explorar¦Reunir búsqueda y filtrado de publicaciones.
Buscar publicaciones en servidor¦Consultar texto sin simular resultados.
Filtrar publicaciones por categoría¦Aplicar categoría seleccionada a la consulta.
Crear formulario de publicación¦Capturar título, descripción y categoría.
Añadir fotografía opcional al post¦Procesar imagen seleccionada desde galería.
Crear almacenamiento privado post-images¦Vincular lectura de fotos a publicaciones visibles.
Publicar contenido propio¦Guardar la publicación con identidad verificada.
Editar publicaciones propias¦Conservar autorización del propietario.
Eliminar publicación con confirmación¦Retirar contenido y relaciones asociadas.
Crear guardados privados de posts¦Persistir relación por usuario.
Guardar y quitar publicaciones¦Actualizar colección personal desde la interfaz.
Crear directorio público autenticado¦Exponer presentación sin correo ni preferencias privadas.
Abrir perfil de otra persona¦Consultar sus publicaciones y misiones visibles.
Mantener edición de contenido histórico¦Permitir al dueño editar posts previos a cambios de capacidades.
`);
add('COM02','Ubicación de publicaciones',3,3,'2026-09-17','Completado',
 ['supabase/migrations/004_post_locations.sql','lib/features/community/presentation/post_location_picker.dart','docs/community.md','git:b321100:README.md'],'COM01, INV03',`
Agregar coordenadas opcionales a posts¦Conservar compatibilidad con ubicaciones solo textuales.
Registrar precisión exacta o aproximada¦Persistir elección junto a coordenadas.
Crear selector visual de ubicación¦Elegir un punto sobre OpenStreetMap.
Buscar dirección con Nominatim¦Permitir localizar el punto mediante texto.
Mover punto manualmente¦Ajustar ubicación antes de confirmarla.
Solicitar ubicación mediante acción explícita¦No obtener GPS al abrir el formulario.
Manejar permiso de ubicación rechazado¦Mantener disponibles búsqueda y selección manual.
Redondear posición aproximada¦Reducir precisión antes de persistir.
Confirmar ubicación seleccionada¦Devolver texto, punto y precisión al compositor.
Retirar ubicación opcional¦Permitir publicación sin punto en mapa.
Mostrar ubicación guardada¦Abrir el contexto de posición desde contenido visible.
Configurar permisos Android y web¦Declarar acceso y dejar solicitud bajo control de la persona.
`,'El commit del 17 acredita presencia del cambio; no fija el día exacto de implementación.');
add('MIS01','Primer flujo y ciclo de vida de misiones',3,3,'2026-09-17','Completado',
 ['git:b321100:README.md','supabase/migrations/005_mission_lifecycle.sql','docs/community.md','test/features/community/mission_repository_test.dart'],'COM01, COM02',`
Crear entidades de misión y candidatura¦Relacionar organizador, convocatoria y participante.
Crear formulario inicial de misión¦Capturar descripción, fecha, cupo y ubicación.
Crear listado inicial de misiones¦Mostrar convocatorias desde Supabase.
Crear detalle inicial de misión¦Mostrar condiciones y acción de participación.
Filtrar elegibilidad por tipo solicitado¦Aceptar perfiles coincidentes o convocatoria abierta.
Bloquear candidatura del organizador¦Impedir postularse a una misión propia.
Validar fecha límite de candidatura¦Impedir solicitud fuera del periodo permitido.
Validar disponibilidad de cupo¦No aceptar participantes fuera de capacidad.
Enviar candidatura inicial¦Persistir mensaje y participante autorizado.
Consultar candidaturas propias¦Mostrar el estado de participación.
Retirar candidatura propia¦Conservar historial y aplicar restricciones temporales.
Aceptar candidatura desde organizador¦Respetar propiedad y cupo.
Rechazar candidatura individual¦Actualizar estado autorizado por el organizador.
Cerrar convocatoria¦Detener nuevas solicitudes sin borrar historial.
Reabrir convocatoria válida¦Permitir nuevas solicitudes antes de la fecha.
Cancelar misión con motivo¦Registrar estado terminal y razón.
Finalizar misión¦Conservar historial de la colaboración.
Bloquear condiciones tras primera candidatura¦Evitar modificaciones incompatibles con solicitudes recibidas.
`,'b321100 se guardó como WIP. Estas capacidades se conservan en etapas posteriores; la aceptación del rediseño se registra en MIS05.');
add('COM03','Moderación y eliminación ampliada de cuenta',3,3,'2026-09-17','Completado',
 ['docs/community.md','docs/account-completion.md','supabase/functions/delete-account/index.ts','lib/features/community/presentation/moderation_screen.dart'],'COM01, MIS01',`
Reportar publicaciones¦Guardar razón de reporte vinculada a contenido.
Reportar misiones¦Permitir revisión de convocatorias.
Crear cola privada de moderación¦Mostrar reportes solo a administradores.
Ocultar contenido reportado¦Retirar disponibilidad sin dar control a usuarios comunes.
Restaurar contenido desde historial¦Recuperar visibilidad mediante acción administrativa.
Separar rol administrador del tipo de perfil¦No asignar moderación mediante registro.
Crear marcador durable de eliminación¦Permitir reintentar borrado interrumpido.
Bloquear escrituras de cuenta en eliminación¦Evitar crear recursos durante el proceso.
Esperar operaciones de imagen en curso¦Coordinar limpieza con las subidas pendientes.
Limpiar imágenes de publicaciones al borrar cuenta¦Incluir post-images en la eliminación.
Eliminar Auth tras limpieza¦Completar cascadas de datos de la cuenta.
`);
add('QA01','Verificaciones de cuenta y comunidad tempranas',3,3,'2026-09-16','Completado',
 ['docs/deployment-status.md','test/features/profile/data/profile_image_picker_test.dart','tool/check_database.mjs','tool/check_community_database.mjs'],'ACC01, ACC02, COM01',`
Verificar migraciones 001 y 002 desplegadas¦Confirmar proyecto y contrato sin reaplicar versiones idénticas.
Verificar funciones de medios y borrado¦Comparar código remoto y rechazo sin sesión.
Probar almacenamiento administrativo temporal¦Comprobar subida, descarga idéntica y limpieza.
Publicar documentos escolares y abrir registro¦Registrar política escolar-1.0 sin consentimientos inventados.
Aplicar migración 003 de comunidad¦Extender el proyecto sin reset de tablas existentes.
Desplegar limpieza de fotos de posts¦Actualizar delete-account conservando autenticación.
Validar SQL aislado de comunidad¦Reporte acredita 100 comprobaciones de comunidad y 33 previas.
Validar pantallas de comunidad¦Reporte acredita 133 pruebas Flutter antes de la corrección Web.
Corregir dimensiones de imágenes en navegador¦Usar imagen decodificada en lugar de getters no implementados.
Regenerar registro del plugin de fotos Web¦Incluir ImagePickerPlugin en la compilación corregida.
Probar selector y vista previa en Chrome¦Comprobar entrega de fotografía en perfil y publicación.
Validar regresión de fotos Web¦Reporte acredita 137 pruebas locales y cuatro Chrome.
Compilar Web y APK de comunidad¦Registrar builds locales con configuración del proyecto.
`,'El reporte incluye hechos del 14 y 16; las fechas puntuales de cada ejecución no equivalen a duración real.');
add('GIT01','Publicación del repositorio e integración del historial',4,4,'2026-09-22','Completado',
 ['git:1c7a5d0:README.md','.gitignore','README.md'],'MVP01, COM01, MIS01',`
Preparar archivos públicos del proyecto¦Publicar el snapshot de Flutter, backend, pruebas y documentación.
Conservar ejemplos de configuración¦Compartir plantillas sin secretos administrativos.
Excluir configuración privada del snapshot público¦Separar valores locales de archivos distribuibles.
Conservar etapa previa del MVP¦Identificar b92a237 y b321100 fuera de la nueva raíz principal.
Registrar nueva raíz de publicación¦Identificar 1c7a5d0 sin atribuirle todo el trabajo desde cero.
Conservar checkpoint previo de trabajo¦Usar stash como evidencia auxiliar sin contarlo como implementación nueva.
`,'La publicación del 22 reinició la raíz principal. Merges, stashes y checkpoints no se suman como nuevas capacidades.');

add('PRO01','Experiencia profesional y confirmación de perfil',4,4,'2026-09-27','Completado',
 ['docs/account-completion.md','docs/community.md','docs/deployment-status.md','supabase/migrations/006_profile_experience.sql'],'ACC01, COM01',`
Agregar marca de confirmación inicial¦Persistir confirmación de tipo desde servidor.
Crear complete_initial_profile¦Confirmar elección una sola vez con validaciones atómicas.
Proteger tipo confirmado contra edición¦Mantener capacidades consistentes tras completar perfil.
Persistir intereses privados¦Guardar preferencias sin exponerlas en directorio.
Persistir objetivos privados¦Separar metas personales de presentación pública.
Agregar enlace HTTPS de contacto¦Mostrar acción únicamente con enlace configurado.
Agregar disponibilidad para colaborar¦Permitir declaración profesional de creadores.
Agregar datos de negocio¦Persistir ubicación y contexto profesional opcionales.
Agregar horarios semanales¦Permitir intervalo por día o día cerrado.
Crear herramientas por tipo de perfil¦Distinguir Portafolio, Catálogo y Servicios.
Separar perfil propio y público¦Exponer controles privados solo al propietario.
Separar publicaciones y fichas profesionales¦No duplicar contenido de Inicio.
Integrar lectura pública de avatar y portada¦Mostrar fotografías reales de perfiles visibles.
Desplegar migración 006¦Reporte del 27 acredita contrato remoto actualizado.
Actualizar limpieza de showcase-media¦Incluir fotografías de fichas en delete-account.
Verificar perfiles y fichas¦Reporte acredita 194 pruebas Flutter y 277 checks SQL aislados.
`);
add('PRO02','Fichas de portafolio, catálogo y servicios',4,4,'2026-09-27','Completado',
 ['docs/community.md','lib/features/showcase/data/showcase_repository.dart','lib/features/showcase/presentation/showcase_composer_screen.dart','supabase/migrations/006_profile_experience.sql'],'PRO01, ACC02',`
Crear modelo de ficha profesional¦Representar project, product y service independientemente de posts.
Crear repositorio de showcase¦Conectar lectura, escritura y cambios de estado.
Crear compositor de obra o proyecto¦Ofrecer ficha de portafolio para creador.
Crear compositor de producto¦Ofrecer ficha de catálogo para emprendimiento.
Crear compositor de servicio¦Ofrecer ficha autorizada por tipo de perfil.
Capturar título y descripción de ficha¦Validar información de presentación.
Seleccionar categoría de ficha¦Aplicar catálogo compatible con el contenido.
Agregar hasta seis fotos ordenadas¦Conservar secuencia de la galería.
Crear bucket privado showcase-media¦Relacionar fotos con fichas visibles y propietario.
Exigir foto para obra y producto publicados¦Permitir servicio publicado sin imagen.
Capturar precio opcional en MXN¦Mostrar Consultar precio cuando no existe importe.
Capturar disponibilidad de ficha¦Controlar disponibilidad del contenido publicado.
Guardar borrador privado¦Permitir preparación sin exposición pública.
Publicar ficha válida¦Cambiar estado con validación atómica del servidor.
Editar ficha propia¦Conservar contenido y permisos del propietario.
Archivar ficha¦Retirar disponibilidad conservando datos.
Volver ficha a borrador¦Permitir edición privada de contenido publicado.
Eliminar ficha con confirmación¦Limpiar relaciones y recursos sin referencias.
Mostrar detalle y galería de ficha¦Permitir navegación de fotografías.
Mostrar contacto del perfil en ficha¦Abrir únicamente el enlace HTTPS disponible.
Buscar fichas en Explorar¦Filtrar por título, categoría y tipo.
Guardar y quitar fichas¦Mantener colección personal privada.
Reportar ficha profesional¦Integrar reporte con moderación existente.
Conservar formulario ante fallo¦Permitir reintento sin perder imágenes o texto.
Limpiar fotos reemplazadas tras éxito¦No borrar imágenes anteriores cuando falla el guardado.
`);
add('PRO03','Rediseño de perfil, edición y configuración',4,4,'2026-09-29','Completado',
 ['output/profile-redesign-progress.md','output/ux-permissions-progress.md','git:84f3151:lib/features/profile/presentation/profile_experience.dart'],'PRO01, PRO02',`
Crear cabecera compacta de perfil¦Mostrar portada, avatar e identidad en primer viewport.
Adaptar perfil a dos columnas¦Usar distribución de escritorio desde 1024 px.
Conservar estado de pestañas¦Mantener carga y desplazamiento al cambiar secciones.
Redirigir enlace público al perfil propio¦Evitar controles contradictorios para la misma cuenta.
Separar editor de identidad y profesional¦Organizar campos sin perder valores al cambiar sección.
Validar campos entre secciones¦Detectar errores aunque el campo no esté visible.
Corregir foco de campos ocultos¦Retirar foco al cambiar pestaña manteniendo estado.
Actualizar identidad tras cambiar enlaces¦Refrescar presentación profesional después de guardar.
Crear configuración compacta¦Agrupar herramientas y seguridad con acabado MAREA.
Rediseñar formularios de seguridad¦Simplificar etiquetas y distribución de correo y contraseña.
Mantener guardar visible sobre teclado¦Evitar que la acción quede fuera del formulario móvil.
Crear controles de galería accesibles¦Operar fotos con botones además de gestos.
Corregir selectores con texto ampliado¦Permitir ancho adaptable y alturas variables.
Agregar regreso en enlaces directos¦Dar salida explícita a pantallas derivadas.
Verificar rediseño de perfil¦Reporte acredita 216 pruebas, análisis y build Web correctos.
Inspeccionar diez vistas de perfil en navegador¦Revisar móvil, escritorio, seguridad, perfil público y fichas.
`,'El reporte del rediseño no tiene fecha propia; el commit del 29 acredita integración.');
add('ACC03','Rediseño de registro mínimo y guías opcionales',4,4,'2026-09-28','Completado',
 ['docs/access-redesign.md','output/access-redesign-progress.md','supabase/migrations/007_minimal_registration.sql'],'PRO01, ACC01',`
Crear referencias visuales de acceso¦Preparar cuatro láminas móviles/escritorio y sus prompts.
Rediseñar bienvenida con marca MAREA¦Presentar acciones de acceso y superficies compactas.
Crear selector de cuatro tipos de perfil¦Ofrecer elección explícita durante registro.
Dividir registro mínimo en tres pasos¦Separar tipo, identidad y credenciales/verificación.
Retirar preferencias obligatorias del registro¦Permitir llegar a Inicio con información mínima.
Confirmar tipo en nuevo registro¦Persistir la elección autorizada desde el trigger.
Crear confirmación mínima heredada¦Solicitar solo el tipo a cuentas pendientes compatibles.
Crear guía de usuario general¦Ofrecer orientación opcional específica del tipo.
Crear guía de artista o creador¦Ofrecer pasos opcionales del portafolio y colaboración.
Crear guía de emprendimiento¦Ofrecer orientación de catálogo y contacto.
Crear guía de negocio¦Ofrecer orientación de servicios y datos del local.
Permitir omitir guía¦No impedir el acceso a Inicio por orientación pendiente.
Retomar guía desde perfil¦Recuperar paso guardado al volver.
Persistir avance privado de guía¦Guardar paso confirmado en lugar de pregunta abierta.
Editar preferencias después del registro¦Actualizar intereses y objetivos sin cambiar el tipo.
Proteger borradores al cambiar cuenta¦Evitar aplicar datos de una sesión anterior.
Corregir disposición al cerrar sesión¦Inicializar controladores antes de la limpieza de estado.
Validar registro a 320 px y texto 200%¦Cubrir teclado y cuatro tipos de perfil.
Verificar acceso rediseñado¦Reporte acredita 239 pruebas Flutter y 35 checks SQL aislados.
`);
add('ACC04','Reparación de registro, cámara y contrato remoto',4,4,'2026-09-28','Completado',
 ['output/account-repair-progress.md','docs/email-setup.md','docs/deployment-status.md','supabase/migrations/008_recover_minimal_registration.sql'],'ACC03, ACC02',`
Detectar desfase cliente-servidor de registro¦Identificar preferencias exigidas y setup_step faltante.
Crear migración 008 de recuperación¦Recuperar elecciones válidas sin alterar perfiles confirmados.
Conservar cuentas con datos incompatibles¦Dejar confirmación explícita sin perder contenido profesional.
Aplicar migraciones 007 y 008¦Actualizar únicamente el contrato necesario del proyecto.
Crear mensaje de esquema desactualizado¦Mostrar acción útil ante backend incompatible.
Corregir área real del botón de cámara¦Garantizar objetivo táctil de 48 px que recibe clics.
Ampliar gate de backend¦Comprobar salida estructurada y trigger AFTER INSERT activo.
Verificar registro entre sesiones reales¦Reporte acredita 61 checks con cinco cuentas temporales.
Verificar aislamiento de fotos entre usuarios¦Probar subir, leer, reemplazar y quitar con JWT individual.
Limpiar cuentas y archivos de comprobación¦Confirmar cero recursos temporales propios.
Actualizar APK en emulador conservando datos¦Comprobar Inicio con sesión y posts reales.
Detectar respuesta de registro repetido¦Rechazar usuario sin identidades ni sesión como registro incompleto.
Ofrecer login o recuperación en correo repetido¦Conservar correo y no afirmar envío de OTP inexistente.
Verificar SMTP Gmail y plantilla de confirmación¦Reporte del 28 acredita SMTP activo y token en plantilla.
Registrar recepción de confirmación existente¦El documento acredita una confirmación el 18; no valida todos los correos nuevos.
`,'La prueba de recepción del último registro tiene fecha propia 2026-09-18; se corrige en el registro individual al finalizar la carga.');
add('PRO04','Herramientas y permisos de los cuatro perfiles',4,4,'2026-09-28','Completado',
 ['output/ux-permissions-progress.md','docs/community.md','lib/features/profile/presentation/profile_tools_sheet.dart'],'PRO03, MIS01',`
Crear panel privado de herramientas¦Mostrar acciones sobre la navegación global.
Abrir creación de publicación desde perfil¦Permitir a todos los tipos publicar comunidad.
Abrir creación de misión desde perfil¦Dar permisos de organización a los cuatro tipos.
Ofrecer obra al creador¦Mantener herramientas de portafolio específicas.
Ofrecer producto y servicio al emprendimiento¦Mantener capacidades de catálogo.
Ofrecer servicio al negocio¦Conservar separación respecto de Productos.
Abrir datos profesionales desde herramientas¦Seleccionar pestaña correspondiente del editor.
Abrir colaboraciones compatibles¦Consultar misiones para el tipo actual y para todos.
Agregar filtros de respuestas en postulaciones¦Separar pendientes, aceptadas, rechazadas y retiradas.
Mostrar causas específicas de inelegibilidad¦Explicar cierre, fecha, cupo y tipo solicitado.
Verificar matriz de permisos de misiones¦Reporte acredita 337 checks SQL y cuatro tipos organizadores.
Verificar herramientas en interfaz¦Reporte acredita 269 pruebas Flutter y revisión móvil/escritorio.
`);
add('DIS01','Evolución visual y propuestas sustituidas',4,4,'2026-09-29','Sustituido',
 ['docs/home-social-ui-v3.md','docs/home-vertical-ui-v4.md','docs/home-brand-ui-v5.md','docs/home-final-ui-v6.md','docs/design-experiments/README.md'],'MVP02, COM01',`
Explorar composición híbrida de Inicio¦Conservar prompt local como antecedente, sin acreditar implementación.
Explorar composición editorial v2¦Conservar prompt local previo al diseño social v3.
Diseñar unidad social v3¦Definir foto, texto, autor, reacciones y participación.
Diseñar acciones y estados sociales v3¦Definir guardados, actividad, errores y reintentos.
Diseñar post vertical v4¦Reordenar lectura y fotografía dentro de una unidad.
Diseñar adaptación móvil y web v4¦Mantener límites y comportamiento por superficie.
Diseñar cabecera con marca v5¦Usar originales oficiales como referencia de colocación.
Diseñar distribución de escritorio v5¦Revisar composición de cabecera y contenido.
Diseñar Buscar y Actividad v5¦Definir acceso y estados de estos paneles.
Diseñar cabeceras definitivas v6¦Separar marca, guardados, notificaciones y Crear.
Diseñar colección de Guardados v6¦Distinguir colección de un panel de actividad.
Diseñar Notificaciones v6¦Definir filtros y marcado de lectura al abrir destino.
Retirar visor independiente de foto en v6¦Conservar lectura y expansión dentro del post.
Corregir láminas v6¦Revisar dock, Crear web, Ver más y etiquetas de guardados.
Archivar concepto social mobile redesign¦Conservar propuesta sin sustituir la experiencia integrada.
Archivar concepto mobile social UI¦Conservar segundo experimento visual como antecedente.
`,'Las propuestas son entregables de diseño, no funciones probadas. Los prompts iniciales carecen de fecha propia; el 29 acredita conservación/integración de antecedentes.');
add('DIS02','Acabado v7 e identidad oficial',4,4,'2026-09-29','Completado',
 ['docs/home-polished-ui-v7.md','git:37d4c23:README.md','docs/home-social-v7-integration.md'],'DIS01',`
Definir paleta neutral del acabado v7¦Usar Paper, blanco, navy, aqua y mint con contraste.
Definir profundidad de superficies¦Aplicar sombras y brillos moderados.
Diseñar cápsula de navegación web¦Mantener destinos con selección mint.
Diseñar cápsula móvil y Crear separado¦Reservar espacio de navegación en el contenido.
Equilibrar columnas del post v7¦Concentrar color en selección y acciones principales.
Integrar logotipo oficial móvil¦Usar archivo original sin deformar proporciones.
Integrar isotipo oficial escritorio¦Usar recurso de marca en cabecera.
Actualizar assets oficiales de marca¦Conservar archivos de identidad en el proyecto.
`);
add('SOC01','Implementación de Inicio y post social v7',4,4,'2026-09-29','Completado',
 ['docs/home-social-v7-integration.md','git:9f2f91d:lib/features/community/presentation/posts_feed.dart','git:9c551ab:README.md'],'DIS02, COM01, PRO02',`
Integrar cabecera compacta móvil¦Presentar marca y controles accesibles.
Integrar navegación neumórfica escritorio¦Compartir cápsula entre destinos del shell.
Mover búsqueda a Explorar¦Retirar controles de búsqueda del encabezado de Inicio.
Crear componente de post reutilizable¦Usarlo en Inicio, Explorar, perfil y detalle.
Aplicar ancho máximo de post¦Limitar a 820 px y adaptar desde 760 px disponibles.
Mostrar imagen completa sin deformación¦Usar contain en bloque fotográfico 3:5.
Centrar lectura de posts sin fotografía¦Evitar columna vacía reservada a imagen.
Mostrar autor, avatar y metadata reales¦Cargar fecha, tipo y categoría del contenido.
Expandir texto dentro del post¦Alternar Ver más y Ver menos sin visor separado.
Consultar estadísticas por lote¦Evitar una consulta independiente por cada post.
Paginar feed en páginas de 30¦Conservar contenido recibido al cargar más.
Descartar respuestas antiguas del feed¦Evitar que consulta obsoleta reemplace resultados actuales.
Reintentar carga sin perder páginas¦Mantener contenido visible ante fallo posterior.
Integrar detalle de post con URL interna¦Usar /posts/:id como destino de lectura.
Integrar v7 con el perfil y cuenta existentes¦Unir ramas sin duplicar capacidades.
`);
add('SOC02','Reacciones, comentarios y compartir',4,4,'2026-09-29','Completado',
 ['docs/home-social-v7-integration.md','supabase/migrations/009_post_reactions.sql','supabase/migrations/010_post_comments.sql','lib/features/community/data/social_repository.dart'],'SOC01',`
Crear reacción única por usuario y post¦Persistir selección sin duplicados.
Crear selector de tres reacciones¦Ofrecer Me gusta, Me inspira y Lo apoyo.
Retirar reacción activa¦Interpretar selección repetida como eliminación.
Cambiar tipo de reacción¦Reemplazar selección previa conservando unicidad.
Calcular total de reacciones¦Mostrar agregado confirmado por servidor.
Crear estadísticas sociales privadas/autorizadas¦Evitar escritura directa de conteos desde el cliente.
Crear tabla de comentarios¦Persistir autor, post y contenido plano.
Validar longitud de comentario¦Aceptar texto de 1 a 1000 caracteres.
Crear panel de comentarios móvil/web¦Adaptar sheet inferior y panel lateral.
Paginar comentarios en páginas de 30¦Cargar entradas siguientes con offset real.
Conservar borrador e ID de comentario¦Mantener operación estable al cerrar y reintentar.
Eliminar comentario autorizado¦Solicitar confirmación y aplicar permisos de servidor.
Crear notificación transaccional de comentario¦Coordinar publicación del comentario y evento.
Corregir paginación con comentario destacado¦Contar solo filas de páginas recibidas.
Generar enlace público del post¦Usar APP_PUBLIC_URL y ruta interna.
Compartir enlace mediante plataforma¦Integrar share_plus y gestionar disponibilidad.
Ofrecer copiar enlace como alternativa¦Usar Clipboard cuando compartir no está disponible.
Manejar cancelación de compartir¦No mostrar confirmación de éxito tras cancelar.
`);
add('SOC03','Guardados y colaboración en publicaciones',4,4,'2026-09-29','Completado',
 ['docs/home-social-v7-integration.md','supabase/migrations/011_post_collaboration.sql','lib/features/community/presentation/social_panels.dart'],'SOC01, SOC02, PRO02',`
Abrir Guardados desde cabecera¦Usar /explore?section=saved y repositorios existentes.
Separar Publicaciones y Fichas guardadas¦Reutilizar colecciones privadas sin almacenamiento paralelo.
Agregar confirmación temporal de guardado¦Mostrar acción Deshacer sin bloquear navegación.
Deshacer quitar guardado¦Conservar fila durante ventana de recuperación.
Crear menú de acciones del post¦Mostrar guardar, detalle, reporte y edición según permisos.
Agregar invitación opcional de colaboración¦Mantener desactivada inicialmente en compositor.
Mostrar CTA solo en posts habilitados¦No ofrecer interés al autor de su propia publicación.
Capturar mensaje privado de interés¦Validar entre 1 y 1000 caracteres.
Persistir interés único por solicitante¦Evitar duplicados tras cerrar o reintentar.
Restringir lectura de mensaje de interés¦Permitir solo a participantes autorizados.
Actualizar CTA tras enviar interés¦Mostrar Interés enviado sin depender del cierre del panel.
Notificar interés al autor¦Crear evento sin añadir conversación de chat.
`);
add('SOC04','Bandeja, privacidad y enlaces sociales',4,4,'2026-09-29','Completado',
 ['docs/home-social-v7-integration.md','lib/features/community/data/notifications_controller.dart','supabase/migrations/009_post_reactions.sql'],'SOC02, SOC03, ACC03',`
Crear bandeja privada de notificaciones¦Mostrar reacciones, comentarios e intereses reales.
Filtrar Todo y Sin leer¦Conservar selección al recargar.
Mostrar punto de actividad pendiente¦Sincronizar indicador con entradas no leídas.
Marcar lectura al abrir destino válido¦No leer entradas únicamente al mostrar el listado.
Marcar todo con corte temporal de servidor¦Evitar afectar eventos nuevos fuera del corte.
Sincronizar bandeja mediante Realtime¦Actualizar mientras la cuenta está activa.
Recargar bandeja al abrir o reanudar¦Recuperar cambios perdidos fuera de sesión activa.
Limpiar controlador al cerrar sesión¦Separar notificaciones entre cuentas.
Evitar autonotificaciones¦No avisar al autor de sus propias acciones.
Actualizar evento al cambiar reacción¦Mantener coherencia de reacción y notificación.
Eliminar evento al retirar reacción¦Retirar actividad que ya no corresponde.
Proteger destinos después de autenticación¦Conservar ruta interna durante login y registro.
Rechazar destinos externos o inválidos¦Evitar navegación no autorizada desde parámetros.
Resolver contenido retirado¦Mostrar estado explícito en lugar de detalle inexistente.
Mantener un panel modal activo¦Restaurar foco con cierre, regreso o Escape.
`);
add('SOC05','Validación y correcciones de la experiencia social',4,4,'2026-09-29','Completado',
 ['docs/home-social-v7-integration.md','docs/implementation/home-social-v7-progress.md','tool/check_live_social_flow.mjs'],'SOC01, SOC02, SOC03, SOC04',`
Aplicar migraciones sociales 009 a 011¦Actualizar backend con gate remoto aprobado.
Validar idempotencia y privacidad social¦Reporte acredita 21 comprobaciones Supabase reales.
Verificar publicación Realtime¦Cubrir entrega y limpieza asociadas a la cuenta.
Verificar cascadas de contenido social¦No conservar relaciones huérfanas tras eliminación.
Actualizar gate histórico de migraciones¦Comprobar 009–011 y publicación Realtime.
Corregir pie con teclado y texto ampliado¦Mantener campos y acción alcanzables.
Corregir límite semántico de Navigator¦Hacer accesibles controles de cabecera Web.
Retirar refresco aislado de Inicio¦Conservar actualización del feed dentro del contenido.
Validar layouts entre 360 y 1440 px¦Cubrir móvil, tablet, escritorio y texto 200%.
Validar compartir cancelado y Deshacer¦Cubrir estados sin éxito ficticio ni SnackBar permanente.
Verificar recarga directa del enlace de post¦Comprobar fallback a index.html y retorno tras login.
Compilar Web, Android e iOS sin firma¦Reporte acredita builds de v7 correctos.
Registrar suite social integrada¦Reporte acredita 295 Flutter y 820 checks SQL aislados.
Limpiar datos temporales de validación¦Retirar cuentas, posts e imagen de comprobación.
`);
add('MAP01','Mapa de misiones y consulta geográfica',4,5,'2026-10-02','Completado',
 ['docs/map.md','supabase/migrations/012_mission_map.sql','git:ffd8990:lib/features/map/presentation/mission_map_screen.dart'],'COM02, MIS01, SOC01',`
Crear ruta /map integrada al shell¦Conservar navegación y Crear en móvil.
Crear lienzo OpenStreetMap¦Ocupar área disponible con atribución visible.
Configurar proveedor de teselas por defines¦Permitir URL y atribución sin cambiar widgets.
Extraer DeviceLocationService¦Reutilizar permisos y ubicación del selector existente.
Consultar posición con permiso ya concedido¦No solicitar permiso automáticamente al abrir mapa.
Solicitar permiso desde botón de ubicación¦Mantener exploración manual si se rechaza.
Manejar rechazo permanente o timeout¦Mostrar alternativas sin seguimiento en segundo plano.
Aplicar centro de respaldo del mapa¦Usar perfil válido o centro CDMX sin fingir GPS actual.
Cancelar centrado tras interacción manual¦No mover cámara si la persona ya exploró.
Crear RPC list_map_missions¦Consultar viewport, texto, categoría, fechas y radio.
Crear índice parcial de misiones ubicadas¦Optimizar conjunto disponible del mapa.
Filtrar misiones abiertas y futuras¦Excluir ocultas, sin coordenadas o sin cupo.
Buscar texto dentro del viewport¦Consultar título, lugar, categoría y organizador.
Crear chips Todo y Hoy¦Compartir estado con los filtros.
Crear hoja de filtros de mapa¦Configurar categoría, fecha y radio 1/3/5/10 km.
Limpiar filtros conservando búsqueda¦Restablecer estado sin borrar el texto introducido.
Convertir límites de fecha a UTC¦Usar días locales y próximos siete días correctamente.
Crear clusters de puntos reales¦Contar miembros y desplegar posiciones coincidentes.
Crear preview de misión seleccionada¦Mostrar categoría, título, autor, fecha, lugar y foto.
Mostrar distancia solo con ubicación real¦Presentar aproximación sin tiempo de ruta inventado.
Cerrar preview con mapa o deslizamiento¦Mantener salidas explícitas de la tarjeta.
Conservar cámara y filtros al volver¦Actualizar disponibilidad tras visitar detalle.
Crear acción Buscar en esta zona¦Mostrarla tras cambio relevante sin consultar en cada gesto.
Descartar respuestas antiguas de mapa¦Proteger resultados frente a consultas obsoletas.
Conservar resultados ante error¦Ofrecer reintento sin vaciar contenido válido.
Manejar límite de 300 misiones¦Mostrar recorte y pedir acercamiento de zona.
Aceptar viewport sobre antimeridiano¦Tratar límites oeste mayores que este.
Proteger RPC de consulta anónima¦Exigir cuenta activa y campos públicos autorizados.
Crear pruebas y arnés de mapa¦Cubrir UI, ubicación, repositorio y consulta SQL.
`,'El intervalo E es propuesto. El commit del 2 acredita integración de mapa, no duración real; despliegue posterior se acredita por el historial 001–015 del piloto.');
add('MIS02','Rediseño del compositor y borradores de misión',4,4,'2026-09-30','Completado',
 ['docs/missions-redesign.md','docs/implementation/missions-redesign-progress.md','supabase/migrations/013_missions_redesign.sql'],'MIS01, MAP01, PRO02',`
Dividir compositor en cuatro pasos¦Organizar idea, colaboración, lugar/fecha y revisión.
Compartir flujo entre crear y editar¦Mantener restricciones y datos existentes.
Agregar portada opcional de misión¦Conservar privacidad mientras es borrador.
Capturar requisitos de participación¦Mostrar condiciones claras de la convocatoria.
Capturar condiciones de colaboración¦Conservar acuerdos antes de publicar.
Agregar compensación sin pago¦Registrar modalidad explícita.
Agregar compensación por acordar¦Separar ausencia de importe de modalidad acordable.
Agregar importe fijo en céntimos MXN¦Validar monto sin introducir pagos en la aplicación.
Mostrar compensación histórica no indicada¦No inventar importe para misiones previas.
Bloquear compensación tras candidatura¦Mantener condiciones de participantes existentes.
Crear tabla de borradores privados¦Separar preparación del contenido público.
Guardar borradores incompletos¦Aceptar texto temporalmente inválido sin publicarlo.
Recuperar borrador desde Mis misiones¦Retomar preparación persistida.
Ofrecer guardar, descartar o continuar al salir¦Evitar pérdida silenciosa de edición.
Publicar borrador con UUID estable¦Evitar duplicación por reintentos.
Registrar journal de publicación¦Recuperar misión publicada tras respuesta perdida.
Evitar resurrección de misión eliminada¦No volver a mostrarla como borrador.
Limpiar portadas sin referencias¦Retirar imágenes tras borrar borrador o misión.
`);
add('MIS03','Candidatura estructurada y seguimiento',4,4,'2026-09-30','Completado',
 ['docs/missions-redesign.md','lib/features/community/presentation/mission_application_screen.dart','supabase/migrations/013_missions_redesign.sql'],'MIS02, PRO02',`
Crear pantalla de candidatura en tres pasos¦Separar revisión, datos y envío.
Mostrar revisión inicial de misión¦Presentar condiciones y elegibilidad actual.
Capturar motivación de candidatura¦Guardar mensaje estructurado del participante.
Exigir confirmación de disponibilidad¦Confirmar participación con acción explícita.
Agregar hasta tres muestras opcionales¦Limitar evidencia profesional de la solicitud.
Seleccionar fichas propias publicadas¦Validar propiedad y disponibilidad en servidor.
Agregar enlaces HTTPS con título¦Permitir muestra externa identificable.
Mostrar muestra no disponible¦Explicar ficha retirada u oculta sin romper historial.
Mostrar revisión antes de enviar¦Permitir corregir información del formulario.
Enviar con ID estable de candidatura¦Recuperar reintentos sin solicitudes duplicadas.
Detectar conflicto de payload¦No aceptar otro contenido bajo el mismo ID.
Conservar formulario tras fallo¦Permitir reintento sin perder motivación ni muestras.
Refrescar elegibilidad al fallar¦Explicar cambios de cupo, fecha o estado.
Mostrar confirmación con misión real¦No prometer tiempos de respuesta del organizador.
Filtrar Mis candidaturas por estado¦Mostrar pendiente, aceptada, no seleccionada y retirada.
Permitir retirada y repostulación válida¦Conservar historial y restricciones del ciclo.
`);
add('MIS04','Gestión privada y avisos del ciclo de misión',4,4,'2026-09-30','Completado',
 ['docs/missions-redesign.md','lib/features/community/presentation/mission_management_screen.dart','supabase/migrations/013_missions_redesign.sql'],'MIS02, MIS03, SOC04',`
Crear pantalla privada del organizador¦Excluir controles de gestión para visitantes.
Mostrar contadores reales de candidaturas¦Consultar estados desde backend.
Filtrar candidatos de gestión¦Conservar organización de solicitudes por estado.
Consultar perfil y muestras del candidato¦Respetar acceso privado de organizador y participante.
Marcar finalistas internos¦No cambiar estado público ni enviar aviso.
Crear selección provisional de grupo¦Permitir revisar personas antes de confirmar.
Confirmar selección atómica¦Aceptar grupo sin superar cupo en concurrencia.
Conservar rechazo individual¦Permitir decisión específica sin rechazar al resto.
Cerrar y reabrir sin selección automática¦Separar estado de convocatoria y candidaturas.
Avisar candidatura recibida¦Crear notificación idempotente para organizador.
Avisar aceptación y rechazo¦Informar resolución al participante autorizado.
Avisar retirada de candidatura¦Actualizar conocimiento del organizador.
Avisar cierre, reapertura y cancelación¦Notificar participantes activos según el evento.
Avisar finalización de misión¦Completar información del ciclo sin avisos duplicados.
Conservar navegación si falla lectura de aviso¦No impedir apertura por fallo de marcado leído.
Integrar panel Crear por tipo de perfil¦Ofrecer misión a todos y fichas profesionales autorizadas.
Guardar misiones en colección privada¦Ofrecer Guardadas dentro de Explorar.
Conservar filtros y scroll del listado¦Volver del detalle sin perder posición.
`);
add('MIS05','Verificación y despliegue del rediseño de misiones',4,4,'2026-09-30','Completado',
 ['docs/deployment-status.md','docs/implementation/missions-redesign-progress.md','tool/check_live_missions_flow.mjs'],'MIS02, MIS03, MIS04',`
Validar contrato 013 en aislamiento¦Reporte acredita 146 comprobaciones específicas previas al despliegue.
Aplicar únicamente migración 013¦Comparar historial y dry-run antes de actualizar.
Verificar gate y lint remotos¦Confirmar contrato 001–013 y esquema sin errores.
Probar publicación y candidatura idempotentes¦Cubrir reintentos y operaciones concurrentes.
Probar selección atómica con cupo uno¦Evitar sobreadmisión en condiciones simultáneas.
Probar privacidad de borradores y finalistas¦Separar datos de organización y contenido público.
Probar bloqueo de compensación y muestras¦Validar propiedad y restricciones de edición.
Probar retirada, repostulación y avisos¦Verificar ciclo entre sesiones.
Registrar validación real de misiones¦Reporte acredita 54 comprobaciones remotas.
Ejecutar regresión social del rediseño¦Reporte acredita otras 21 comprobaciones con Realtime.
Registrar suite integrada de misiones¦Reporte acredita 387 Flutter, 720 SQL aislados y 10 del gate.
Revisar móvil, tablet y escritorio¦Comprobar capturas, texto ampliado y teclado.
Compilar clientes del rediseño¦Registrar Web, APK debug e iOS sin firma correctos.
Limpiar recursos temporales de misiones¦Confirmar cero cuentas de pruebas remotas restantes.
`);
add('MAR01','Iconos y recursos de identidad de la aplicación',5,5,'2026-10-02','Completado',
 ['git:ffd8990:assets/brand/marea_app.png','git:ffd8990:android/app/src/main/res/mipmap-hdpi/ic_launcher.png','git:ffd8990:ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'],'DIS02',`
Preparar imagen de icono de aplicación¦Agregar marea_app como recurso de marca.
Generar iconos Android por densidad¦Actualizar hdpi, mdpi, xhdpi, xxhdpi y xxxhdpi.
Generar variantes del icono iOS¦Actualizar AppIcon en los tamaños del proyecto.
Actualizar catálogo AppIcon¦Relacionar archivos con sus tamaños y escalas.
Actualizar configuración de identidad iOS¦Mantener referencia al icono y nombre de aplicación.
Conservar logotipo e isotipo separados¦No reemplazar recursos de cabecera por icono de launcher.
`);

const localCurrent='Estado reconstruido por inspección del checkout al 06/10/2026 y reportes locales. La fecha de evidencia es la fecha de corte, salvo fecha individual explícita. Sin duración real registrada.';
add('INT01','Reacciones e interacciones modernas',5,5,'2026-10-06','Completado',
 ['docs/implementation/modern-interactions-push-progress.md','lib/features/community/presentation/reaction_button.dart','test/features/community/social_ui_test.dart'],'SOC02, SOC04',`
Reaccionar con toque directo¦Activar reacción desde el control principal.
Abrir selector manteniendo pulsado¦Mostrar alternativas mediante gesto sostenido.
Seleccionar mediante deslizar y soltar¦Resolver reacción al finalizar el gesto.
Actualizar reacción de forma optimista¦Mostrar selección inmediata mientras confirma servidor.
Restaurar selección tras error¦Revertir cambio optimista y permitir reintento.
Operar selector mediante teclado¦Mantener navegación y elección accesibles.
Cancelar selector sin modificar reacción¦Cerrar con gesto o acción de cancelación.
Ignorar respuesta tardía de cuenta anterior¦No aplicar reacción tras cambio de sesión.
Evitar controles semánticos duplicados¦Presentar una acción accesible coherente.
Usar InkRipple compatible con pruebas¦Conservar ondas Material y animación de escala.
Coordinar paneles en navegación raíz¦Evitar desplazamiento inesperado del feed.
Ocultar dock al abrir panel¦Mantener espacio y visibilidad coordinados.
Restaurar dock al cerrar panel¦Recuperar navegación tras regresar.
Proteger cierre de paneles anidados¦No dejar estado de navegación residual.
`,localCurrent);
add('INT02','Cargas, botones y paneles compartidos',5,5,'2026-10-06','Completado',
 ['docs/implementation/modern-interactions-push-progress.md','lib/shared/widgets/marea_action_button.dart','lib/shared/widgets/marea_panel.dart','lib/shared/widgets/marea_skeleton.dart'],'INT01, SOC01, PRO02',`
Crear MareaSkeleton compartido¦Representar carga sin ruedas en contenido.
Agregar esqueletos al feed¦Mostrar estructura de publicaciones durante carga.
Agregar esqueletos a comentarios¦Mantener contexto del panel mientras consulta.
Agregar esqueletos a perfiles y fichas¦Adaptar cargas de recursos profesionales.
Agregar esqueletos a misiones y mapa¦Unificar estados de consulta disponibles.
Crear botón con texto de progreso¦Mostrar acción en curso sin perder nombre del control.
Bloquear doble envío en botones compartidos¦Evitar mutaciones repetidas mientras espera.
Crear panel compartido de acciones¦Unificar disposición y estados de superficies.
Reemplazar refresco por indicador lineal¦Conservar contenido durante actualización.
Conservar contenido de showcase al recargar¦No vaciar fichas mientras llega consulta.
Adaptar esqueletos pequeños¦Evitar errores con tamaños mínimos.
Respetar movimiento reducido¦Mantener experiencia usable sin animaciones innecesarias.
Abreviar Acciones a Más donde corresponde¦Evitar desbordamiento con texto ampliado.
`,localCurrent);
add('PUS01','Cliente Android de notificaciones y preferencias',5,5,'2026-10-06','Completado',
 ['docs/android-push.md','lib/features/notifications/data/push_controller.dart','lib/features/notifications/data/android_push_gateway.dart','lib/features/notifications/presentation/notification_settings.dart'],'SOC04, INT02',`
Crear modelos de preferencias de notificación¦Representar permisos de eventos y mensajes.
Crear repositorio de preferencias¦Persistir opciones privadas en Supabase.
Crear abstracción PushGateway¦Separar Android de clientes con bandeja únicamente.
Inicializar Firebase solo en transporte Android¦Mantener Web e iOS con bandeja interna.
Solicitar permiso de avisos del celular¦Hacer explícita la autorización del dispositivo.
Registrar dispositivo y token FCM¦Asociar versión del token a la cuenta activa.
Actualizar registro tras renovación del token¦Evitar conservar un token anterior como vigente.
Mostrar configuración de notificaciones¦Permitir cambiar preferencias desde ajustes.
Desactivar mensajes ocasionales¦Cancelar pendientes al retirar preferencia.
Presentar aviso local en primer plano¦Evitar duplicación del mismo evento.
Recibir apertura de aviso en segundo plano¦Resolver destino compartido con la bandeja.
Recibir apertura con proceso cerrado¦Recuperar ruta desde arranque en frío.
Marcar lectura al abrir destino de push¦Coordinar navegación con read_at.
Actualizar actividad durante sesión¦Registrar entrada, reanudación y actividad periódica.
Cancelar programación al volver¦No enviar mensaje de inactividad a una cuenta activa.
Limpiar registro al cerrar sesión¦Conservar seguridad entre cuentas y recuperación offline.
Mostrar ausencia de configuración Firebase¦Mantener bandeja sin afirmar avisos disponibles.
`,localCurrent);
add('PUS02','Cola y entrega push en Supabase',5,5,'2026-10-06','Completado',
 ['supabase/migrations/014_android_push.sql','supabase/functions/send-push/index.ts','supabase/functions/send-push/delivery.ts','docs/android-push.md'],'PUS01, SOC04',`
Crear migración 014 de push¦Agregar dispositivos, preferencias y cola privada.
Proteger dispositivos con permisos de servidor¦No exponer tokens de otras cuentas.
Crear settings privados de envío¦Permitir activar o pausar backend.
Encolar eventos sociales autorizados¦Relacionar notificación y trabajo de entrega.
Crear worker send-push¦Procesar trabajos fuera del cliente Flutter.
Autenticar worker con secreto propio¦Rechazar llamadas sin autorización.
Obtener OAuth de cuenta FCM¦Usar credencial de backend para HTTP v1.
Enviar aviso mediante FCM HTTP v1¦Transportar notificación al Android registrado.
Reintentar fallos de entrega¦Mantener intentos y estado de cola.
Terminar trabajos tras cinco fallos¦Evitar reintentos indefinidos.
Desactivar versión reclamada de token inválido¦No afectar una renovación posterior del dispositivo.
Programar mensaje tras 72 horas sin actividad¦Separar evento ocasional de actividad social.
Respetar horario 10:00 a 19:00 local¦Usar zona registrada de la cuenta.
Limitar mensajes a dos en siete días¦Mantener separación de 72 horas.
Cancelar mensaje al desactivar preferencia¦Conservar bandeja sin entregar pendientes cancelados.
Despertar worker desde triggers¦Ejecutar entrega inmediata y dejar cron para continuidad.
Crear activación idempotente del scheduler¦Instalar un proceso por minuto con nombre estable.
`,localCurrent);
add('PUS03','Configuración Firebase, despliegue y distribución',5,5,'2026-10-06','Completado',
 ['docs/android-push.md','docs/implementation/modern-interactions-push-progress.md','supabase/push/activate.sql','android/app/build.gradle.kts'],'PUS01, PUS02',`
Crear proyecto Firebase MAREA¦Registrar proyecto sin Analytics para transporte de avisos.
Registrar Android com.marea.app¦Vincular aplicación con proyecto FCM.
Obtener configuración pública Firebase¦Guardar defines Android en archivo ignorado.
Habilitar API FCM HTTP v1¦Preparar transporte de envío desde backend.
Crear cuenta dedicada de envío¦Asignar rol autorizado de Firebase Cloud Messaging.
Transferir credencial FCM a Supabase¦Conservar clave privada únicamente en backend.
Desactivar credencial fallida anterior¦Evitar claves duplicadas activas tras descarga fallida.
Eliminar copias temporales de credenciales¦Retirar archivos usados en la transferencia.
Aplicar migración 014 al proyecto¦Confirmar contrato remoto antes de activar.
Desplegar send-push¦Configurar secretos y comprobar worker remoto.
Configurar URL y secreto en Vault¦Preparar invocación privada del scheduler.
Generar recursos públicos Firebase en Gradle¦Permitir inicialización nativa al despertar proceso cerrado.
Mantener auto-init bajo permiso¦No registrar avisos antes de autorización del dispositivo.
Actualizar target iOS a 15¦Conservar compatibilidad de compilación con plugins Firebase.
Compilar APK con configuración Firebase¦Preparar cliente Android para pruebas reales.
Instalar APK en Samsung SM-A556E¦Actualizar dispositivo autorizado para validar recepción.
Publicar Web compatible en Netlify¦El documento acredita publicación del 05/10/2026.
Comparar main.dart.js público y local¦Confirmar hash idéntico de la compilación publicada.
Activar cron y bandera de envíos¦Habilitar procesamiento tras validar Android y Web.
Verificar una sola ejecución por minuto¦Comprobar cron succeeded y cola vacía.
`,localCurrent);
add('PUS04','Correcciones y pruebas de push ejecutadas',5,5,'2026-10-06','Completado',
 ['docs/android-push.md','docs/implementation/modern-interactions-push-progress.md','test/features/notifications/push_controller_test.dart'],'PUS01, PUS02, PUS03',`
Corregir logout offline o colgado¦Evitar conservar registro de una sesión finalizada.
Corregir reset tardío entre cuentas¦No borrar estado nuevo por respuesta anterior.
Corregir clasificación refresh_token_not_found¦Recuperar acceso al reconocer sesión inválida.
Corregir recuperación de diálogo de permiso¦Persistir solicitud solo después de terminar.
Usar promptOnce al refrescar permiso¦Permitir recuperación sin diálogos repetidos.
Corregir inicialización nativa en segundo plano¦Resolver primer aviso físico que no llegó.
Probar aviso con aplicación abierta¦Usuario confirmó un único aviso del sistema.
Probar aviso visible en segundo plano¦Reporte acredita recepción tras corregir recursos nativos.
Probar aviso con proceso realmente cerrado¦Reporte acredita aviso y apertura desde arranque en frío.
Verificar apertura y read_at de avisos¦Confirmar destino Inicio y evento leído en pruebas físicas.
Limpiar cinco eventos de diagnóstico¦Restaurar actividad y zona antes de activar cron.
Validar cola y worker reales¦Comprobar configuración activa y dispositivo habilitado.
Registrar suite automática de push¦Reporte acredita 439 Flutter y 28 de comunidad posteriores.
Validar backend y gate de push¦Reporte acredita nueve pruebas backend y once del gate.
`,localCurrent);

add('TOU01','Diseño de recorridos y experiencia presencial',5,5,'2026-10-06','Completado',
 ['docs/ar-experience-design.md','docs/implementation/tours-360-plan.md','output/imagegen/ar/README.md'],'INV03, PRO04, MAP01',`
Separar visita 360° y recorrido con cámara¦Definir experiencias diferentes sobre el mismo recorrido.
Definir jerarquía espacial¦Organizar local, zonas, posiciones, puntos y contenido vinculado.
Definir versiones públicas y borradores¦Separar lectura del visitante y edición privada.
Definir responsabilidad del espacio¦No acreditar local por ser tipo Negocio.
Definir permisos de contenido vinculado¦Separar autor del contenido y responsable del local.
Diseñar asistente de preparación¦Organizar Local, Zonas, Puntos, Conexiones, Preview y Publicación.
Diseñar captura desde posición fija¦Evitar prometer reconstrucción navegable 3D.
Diseñar visita sin permisos de cámara¦Permitir explorar panoramas desde casa.
Diseñar alternativa de lista en AR¦Mantener lectura cuando no hay soporte o permiso.
Crear seis láminas de referencia¦Conservar diseño y prompts sin tratarlos como pruebas físicas.
Actualizar fichas de pantalla del recorrido¦Describir acciones, regreso y estados por flujo.
Definir criterios de aceptación física¦Exigir captura, recuperación, procesamiento y reconocimiento reales.
`);
add('TOU02','Editor del local, zonas, puntos y versiones',5,5,'2026-10-06','Completado',
 ['docs/ar-experience-design.md','docs/implementation/tours-360-delivery.md','lib/features/tours/presentation/tour_editor_screen.dart','lib/features/tours/models/tour_models.dart'],'TOU01, PRO04',`
Crear modelos tipados del recorrido¦Representar documento, zonas, posiciones, puntos y progreso.
Crear repositorio de recorridos¦Conectar editor, publicación y lectura con RPC del servidor.
Crear administración de recorridos¦Consultar propios, solicitudes y acciones disponibles.
Confirmar nombre y ubicación del local¦Recuperar datos de perfil y permitir completarlos.
Capturar contexto y evidencia privada¦Separar responsabilidad del espacio de presentación pública.
Crear y editar zonas¦Agrupar varias posiciones del local.
Crear y editar posiciones 360°¦Definir nombre, panorama y orientación inicial.
Seleccionar posición de inicio¦Determinar primera vista del recorrido.
Crear puntos con explicación propia¦Conservar información aunque falle un vínculo externo.
Ubicar puntos mediante yaw y pitch¦Normalizar ángulos dentro del panorama.
Crear puntos solo en lista¦Permitir detalle sin posición angular.
Vincular contenido existente¦Referenciar posts, obras, productos, servicios y misiones sin duplicarlos.
Solicitar permiso al autor vinculado¦Distinguir disponible, pendiente y retirado.
Crear conexiones entre posiciones¦Guardar destino, nombre e indicación escrita.
Ordenar paradas del recorrido¦Definir secuencia de visita y alternativas.
Configurar vigencia de versión¦Persistir inicio y fin coherentes en UTC.
Crear vista previa privada¦Revisar borrador antes del envío.
Guardar borrador inmediatamente en local¦Conservar cambios antes de sincronizar.
Recuperar edición sin red¦Abrir documento local por cuenta.
Esperar guardado al salir del editor¦Evitar pérdida del último cambio.
Congelar snapshot al enviar versión¦No reemplazar envío en revisión con edición posterior.
Recuperar envío tras respuesta perdida¦Consultar journal antes de repetir.
Pausar recorrido público¦Retirar descubrimiento mientras se actualiza.
Invalidar puntos al reemplazar panorama¦Exigir revisión de puntos y conexiones afectados.
`);
add('TOU03','Captura guiada y persistencia local',5,5,'2026-10-06','Completado',
 ['docs/ar-experience-design.md','docs/implementation/tours-native.md','lib/features/tours/capture/tour_capture_screen.dart','lib/features/tours/capture/capture_plan.dart'],'TOU02, INV03',`
Abrir cámara principal posterior a 1×¦Mantener lente y zoom coherentes para captura.
Bloquear orientación de captura en retrato¦Conservar eje óptico esperado.
Tomar JPEG de calibración¦Medir proporción real con EXIF aplicado.
Excluir calibración del conteo de tomas¦No incorporarla como fotografía aceptada.
Consultar FOV nativo de la cámara¦No usar apertura constante de respaldo.
Crear objetivos según FOV¦Distribuir anillos con al menos 40% de solapamiento.
Agregar objetivos de cenit y nadir¦Incluir techo y piso de la esfera.
Mostrar objetivo y estabilidad¦Guiar siguiente captura con orientación.
Aceptar y contar tomas confirmadas¦Conservar solo imágenes válidas de la sesión.
Repetir una toma confirmada¦Permitir corregir fotografía eliminando la previa.
Guardar fotos por cuenta en dispositivo¦Separar archivos entre sesiones de usuario.
Guardar manifiesto y orientación de tomas¦Persistir dimensiones, FOV y objetivo asociado.
Recuperar sesión de captura interrumpida¦Mantener tomas aceptadas al regresar.
Comprobar lente y FOV al retomar¦Rechazar recuperación incompatible con la cámara original.
Realinear con primera foto al retomar¦Exigir volver a posición antes de reiniciar yaw.
Ofrecer nueva captura si cambia lente¦Conservar versión publicada mientras se repite trabajo.
Detener cámara al salir o cambiar cuenta¦Evitar recursos activos en otra sesión.
Separar captura y vista AR¦Liberar CameraController antes del tracking.
`,'Implementación y pruebas de recuperación documentadas; calibración y captura óptica reales permanecen pendientes en FIS01.');
add('TOU04','Orientación nativa Android e iOS',5,5,'2026-10-06','Completado',
 ['docs/implementation/tours-native.md','android/app/src/main/kotlin/com/marea/app/TourNative.kt','ios/Runner/TourOrientation.swift','ios/NativeTests/orientation.swift'],'TOU03',`
Registrar canal marea/tour_motion Android¦Integrar start, stop y cameraInfo sin romper notificaciones.
Registrar canal de orientación en iOS¦Usar motor implícito de Flutter.
Transformar RotationVector Android¦Calcular yaw, pitch y roll desde eje óptico posterior.
Invertir quaternion CoreMotion iOS¦Transformar referencia y dispositivo en orden correcto.
Normalizar yaw respecto del inicio¦Conservar pitch del horizonte y los polos.
Diferir origen azimutal en inicio polar¦Evitar yaw indefinido en cenit o nadir.
Calcular FOV Android desde características¦Aplicar focal, área activa y crop real del JPEG.
Rechazar cámaras Android ambiguas¦No inferir apertura de múltiples focales incompatibles.
Calcular FOV iOS desde cámara identificada¦Usar activeFormat y proporción JPEG a zoom 1×.
Emitir error sin datos de cámara¦Mostrar camera_info_unavailable en lugar de constante ficticia.
Liberar sensores al pausar¦Detener canales y recursos cuando dejan de usarse.
Verificar matemáticas y callbacks nativos¦Reporte acredita tres pruebas Android, siete matemáticas y ocho de orden Swift.
`,'Las pruebas nativas no acreditan sensor, óptica ni AR físico en teléfonos.');
add('TOU05','Importación GPano y carga privada reanudable',5,5,'2026-10-06','Completado',
 ['docs/ar-experience-design.md','lib/features/tours/data/tus_uploader.dart','lib/features/tours/data/tour_local_store_io.dart','lib/features/tours/data/tour_local_store_web.dart'],'TOU02, TOU03',`
Importar JPEG equirectangular GPano¦Exigir metadatos de esfera completa.
Validar dimensiones y área GPano¦Rechazar relación 2:1 que no acredita proyección.
Permitir administración e importación web¦No ofrecer captura guiada ni tracking Web.
Explicar reselección de archivo Web¦No fingir persistencia de bytes tras cerrar pantalla.
Crear carga TUS de fragmentos 6 MiB¦Subir originales a bucket privado.
Guardar URL y offset de carga¦Crear checkpoint durable por sesión.
Consultar HEAD al reanudar¦Recuperar offset real del servidor.
Validar host del endpoint TUS¦Evitar uso de destino no autorizado.
Validar cuenta activa durante carga¦No continuar escritura tras cambio de sesión.
Subir todos los archivos del manifiesto¦No iniciar procesamiento de captura incompleta.
Confirmar captura enviada inmutable¦Separar edición local del envío congelado.
Recuperar respuesta perdida de envío¦Consultar estado persistido antes de repetir.
Mantener cuenta original de archivos locales¦No trasladar fotos al cambiar sesión.
Probar interrupción y hash de TUS¦Piloto acredita reanudación con bytes idénticos.
`);
add('TOU06','Backend de recorridos, permisos y limpieza',5,5,'2026-10-06','Completado',
 ['supabase/migrations/015_tours.sql','supabase/functions/delete-account/tour-storage.ts','supabase/tours/repair-cleanup-lease.sql','docs/implementation/tours-local-pilot-report.md'],'TOU02, TOU05',`
Crear migración 015 de recorridos¦Agregar documentos, revisiones, permisos y progreso.
Crear buckets tour-inputs y tour-assets¦Mantener originales, evidencias y borradores privados.
Crear cola privada de procesamiento¦Separar trabajos de datos expuestos al visitante.
Crear leases transaccionales de ejecución¦Limitar reclamación concurrente de trabajos.
Imponer dos trabajos activos globales¦Controlar cupo desde PostgreSQL.
Proteger escritura de resultados¦Reservar confirmaciones al backend autorizado.
Crear recibo durable del lease¦Resolver respuesta perdida tras completar trabajo.
Rechazar ejecución antigua o duplicada¦No sustituir una recaptura posterior.
Cancelar trabajo sin sobrescribir resultado¦Aplicar estado y guardas de ejecución.
Crear acreditación administrativa del espacio¦Autorizar responsabilidad mediante revisión.
Separar revisión espacial y permiso de autor¦No conceder derechos por un vínculo de contenido.
Excluir evidencia de local al revisor de vínculo¦Mantener privada documentación espacial.
Publicar versión activa atómicamente¦Conservar borrador más nuevo y snapshot aprobado.
Filtrar recursos públicos por vigencia¦Servir únicamente versión disponible al visitante.
Revalidar contenido ajeno al leer¦Omitir vínculos retirados o sin permiso.
Revocar responsabilidad espacial¦Impedir reanudar sin otro permiso válido.
Cancelar trabajos al eliminar cuenta¦Bloquear nuevas escrituras antes de limpiar.
Eliminar recursos anidados de tours¦Limpiar ambos buckets recursivamente.
Renovar lease de limpieza¦Evitar que GC borre recursos con token vencido.
Desplegar correctivo de cleanup lease¦Piloto acredita repair-cleanup-lease aplicado y comprobado.
`);
add('TOU07','Procesador Hugin y Enblend',5,5,'2026-10-06','Completado',
 ['processing/tours/README.md','processing/tours/worker.py','processing/tours/Dockerfile','docs/implementation/tours-local-pilot-report.md'],'TOU05, TOU06',`
Crear contenedor de procesamiento¦Empaquetar herramientas Hugin/Enblend y worker Python.
Descargar originales de captura autorizada¦Usar manifiesto y recursos privados del backend.
Generar archivo PTO¦Representar fotografías y orientación para cosido.
Detectar puntos con cpfind¦Encontrar coincidencias reales entre fotografías.
Limpiar coincidencias con cpclean¦Eliminar puntos inconsistentes antes de optimizar.
Comprobar grafo conectado¦Rechazar conjunto sin relaciones suficientes.
Optimizar geometría con autooptimiser¦Ajustar alineación de las tomas.
Definir canvas 360°×180° con pano_modify¦Preparar proyección equirectangular completa.
Remapear fotografías con nona¦Crear contribuciones por imagen al panorama.
Comprobar cobertura alpha¦Rechazar huecos sin inventar techo o piso.
Mezclar remapeos con Enblend¦Unir exposición y costuras del conjunto.
Generar panorama 4096×2048¦Guardar JPEG final con GPano.
Generar preview 2048×1024¦Preparar recurso de visualización de menor tamaño.
Generar miniatura 512×256¦Preparar descubrimiento y tarjetas.
Clasificar errores transitorios¦Reintentar solo fallos recuperables y con límite.
Confirmar resultado con recibo persistido¦No interpretar exit0 como ready sin aceptación del servidor.
Corregir SIGSEGV de Enblend 4.2¦Usar --no-optimize conservando mezcla y cobertura estricta.
Corregir respuesta PostgREST 204¦No intentar decodificar JSON inexistente.
Corregir descargas parciales interrumpidas¦Cerrar respuesta y clasificar fallo transitorio.
`);
add('TOU08','Visor 360° y navegación del recorrido',5,5,'2026-10-06','Completado',
 ['docs/ar-experience-design.md','lib/features/tours/presentation/tour_panorama.dart','lib/features/tours/presentation/tour_visit_screen.dart','test/features/tours/tour_ui_test.dart'],'TOU02, TOU07',`
Mostrar presentación pública del recorrido¦Cargar versión vigente desde perfil o enlace.
Renderizar panorama por arrastre¦Permitir mirar alrededor sin solicitar cámara.
Normalizar costura angular y polos¦Evitar bordes de fotografía plana en la esfera.
Mostrar conexiones sobre panorama¦Permitir cambiar de posición con indicación.
Mostrar lista alternativa de posiciones¦Ofrecer navegación sin gesto espacial.
Mostrar puntos angulares en panorama¦Abrir explicación de la parada.
Mostrar puntos solo en lista¦Mantener contenido sin anclaje en esfera.
Abrir detalle del punto¦Conservar texto independiente y vínculo disponible.
Abrir detalle existente del contenido¦Reutilizar rutas de publicaciones y fichas.
Volver al panorama de origen¦Conservar posición y contexto tras consultar detalle.
Informar contenido retirado o vencido¦No dejar enlaces activos hacia recursos inaccesibles.
Dar regreso explícito en enlaces directos¦Mantener salida de visita y editor.
Revisar visor a 320 px¦Reporte acredita interfaz real y navegación A→B→A.
`);
add('AR01','Implementación AR nativa y recuperación — WIP',5,7,'2026-10-06','WIP',
 ['docs/implementation/tours-native.md','docs/ar-experience-design.md','android/app/src/main/kotlin/com/marea/app/TourAR.kt','ios/Runner/AppDelegate.swift'],'TOU02, TOU04, TOU08',`
Consultar soporte AR del dispositivo¦Código incorpora supported; falta aceptación en hardware real.
Preparar referencia JPEG de activador¦Código usa archivo local identificable; falta reconocimiento físico.
Validar ancho físico positivo¦La referencia requiere widthMeters; falta comprobar medidas en local.
Invalidar prueba al cambiar referencia¦Cambiar ancho o versión exige otra prueba física.
Crear PlatformView Android ARCore¦Vista nativa implementada; falta validar en Android compatible.
Crear AugmentedImageDatabase¦Referencia incorporada a base de reconocimiento de ARCore.
Renderizar cámara Android con textura OES¦Render implementado; falta validar imagen y lifecycle físicos.
Crear anchor de imagen reconocida¦Señal depende de anclaje real de ARCore.
Confirmar FULL_TRACKING y cámara TRACKING¦No tratar última pose conocida como reconocimiento vigente.
Crear configuración ARKit de imágenes¦Implementación usa ARReferenceImage de ancho conocido.
Crear vista ARSCNView iOS¦Cámara y escena preparadas; falta prueba en iPhone firmado.
Vincular señal con ARImageAnchor¦Confirmar isTracked y estado de cámara en hardware.
Emitir eventos tracking, lost y error¦Canal nativo definido para estado de referencia.
Retirar señal al perder tracking¦Ficha conserva lectura mientras desaparece anclaje.
Mantener una sola vista AR activa¦Evitar sesiones simultáneas de cámara.
Cancelar descargas tardías de referencias¦No reactivar una sesión abandonada.
Detener AR al abrir detalle o cambiar parada¦Conservar lectura sin cámara residual.
Detener AR al ir a segundo plano¦Liberar sesión y recursos al pausar.
Liberar EGL, anchors y Session Android¦Implementación de cierre pendiente de aceptación física.
Pausar escena y delegado ARKit¦Implementación de liberación pendiente de aceptación física.
Ofrecer lista sin cámara ante fallo¦Mantener alternativa ante permiso, soporte o referencia ilegible.
Probar recuperación automática de AR¦Pruebas de código disponibles; no acreditan reconocimiento físico.
`,'Código presente y compilaciones reportadas. Estado WIP por validación física/aceptación pendiente; no se afirma que falta escribir toda la implementación.');
add('TOU09','Progreso e integración de recorridos',5,5,'2026-10-06','Completado',
 ['docs/ar-experience-design.md','lib/features/tours/data/tour_progress_store.dart','lib/core/router/app_router.dart','docs/implementation/tours-360-delivery.md'],'TOU02, TOU08, SOC04',`
Guardar progreso privado por cuenta y versión¦Persistir posición y estado de paradas.
Distinguir visitadas y saltadas¦No considerar salto como visita.
Crear outbox local de progreso¦Guardar antes de enviar RPC.
Sincronizar progreso pendiente al volver¦Recuperar cambios tras error o falta de red.
Informar nueva versión del recorrido¦Pedir reinicio sin copiar IDs antiguos.
Integrar entrada desde Crear¦Ofrecer administración a perfiles profesionales.
Integrar recorridos en herramientas propias¦Abrir solicitudes y contenido del responsable.
Integrar tarjeta en perfil público¦Mostrar Explorar el local 360° cuando está disponible.
Integrar revisión en moderación¦Agregar Espacios y recorridos con controles privados.
Agregar capa de recorridos al mapa¦Mantener filtros y consultas de misiones separados.
Crear descubrimiento de recorridos vigentes¦Consultar experiencias y ubicación aproximada.
Crear enlaces /tours/:id y punto¦Conservar destino tras autenticación.
Crear enlace de entrada AR¦Resolver /tours/:id/ar?point sin prometer posicionamiento por QR.
`);
add('PIL01','Piloto Docker local con Supabase real',5,5,'2026-10-06','Completado',
 ['docs/implementation/tours-local-pilot-report.md','processing/tours/pilot-image.json','processing/tours/local_runner.py','processing/tours/check_live.py'],'TOU05, TOU06, TOU07, TOU08',`
Preparar Python y configuración local del procesador¦Separar credenciales de servicio de la configuración Flutter.
Construir imagen linux/amd64 validada¦Registrar digest y herramientas en pilot-image.
Crear fixtures geométricos de 26 fotografías¦Probar pipeline sin atribuirles captura óptica real.
Ejecutar herramientas Hugin realmente¦Piloto acredita cpfind, cpclean, autooptimiser, pano_modify y nona.
Ejecutar Enblend sobre fixture completo¦Generar esfera válida sin huecos sintéticos.
Confirmar ready en Supabase¦Comprobar recibo después de procesamiento local.
Medir runtime de worker y ejecución local¦Reporte registra 162.279 s y 166.751 s; no son tiempo laboral de tarea.
Rechazar fixture sin techo¦Comprobar incomplete_sphere_coverage.
Rechazar fixture sin coincidencias¦Comprobar disconnected_control_points.
Rechazar JPEG 2:1 sin GPano¦Comprobar gpano_full_sphere_required contra backend real.
Aplicar migración 015 exclusivamente¦Verificar historial 001–015 y buckets privados.
Desplegar tour-dispatch autenticado¦Validar 401 sin secreto y 503 mientras falta Google.
Volver a desplegar limpieza anidada de cuenta¦Recuperar fuente remota y verificar versión correcta.
Probar dos leases y contenedores concurrentes¦Comprobar límite global real del backend.
Probar cancelación y recaptura durante trabajo¦No sustituir captura posterior por ejecución antigua.
Probar respuesta duplicada o perdida¦Reconciliar estado con recibo persistido.
Probar borrado durante escritura¦Bloquear cuenta y limpiar recursos anidados.
Probar publicación y recursos de visitante¦Verificar HTTP autorizado y disponibilidad antes de limpiar.
Probar progreso privado contra Supabase¦Separar lectura y escritura entre cuentas temporales.
Probar renovación de cleanup lease¦Reporte acredita ocho comprobaciones reales del correctivo.
Crear runner --once y --watch¦Controlar contenedores, plazo y confirmación backend.
Rechazar upload futuro de imagen distinta¦Verificar ID de la imagen validada antes de llamar a Google.
Limpiar recursos propios del piloto¦Confirmar cero cuentas, trabajos, recorridos y objetos temporales.
Limpiar 175 objetos de checkpoints antiguos¦Restringir limpieza a recursos de pruebas identificados.
Mostrar panorama final en widgets reales¦Revisar navegación y detalle con copia offline del fixture.
`);
add('TOU10','Verificación automática de recorridos',5,5,'2026-10-06','Completado',
 ['docs/implementation/tours-local-pilot-report.md','test/features/tours/tour_editor_recovery_test.dart','test/features/tours/tour_ar_recovery_test.dart','tool/check_tours_migrations.mjs'],'TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09',`
Probar recuperación offline del editor¦Cubrir conservación local y salida tras escritura.
Probar cambios de lente al retomar¦Mantener coherencia de la captura local.
Probar checkpoint y recuperación TUS¦Cubrir offset y errores de sesión.
Probar progreso durable y sincronización¦No perder paradas tras fallo remoto.
Probar descargas AR invalidadas¦Impedir reactivación después de abandonar sesión.
Validar contratos SQL de recorridos¦Piloto acredita 90 contratos y 17 flags del catálogo.
Validar dispatcher y limpieza recursiva¦Piloto acredita seis pruebas dispatcher y tres de limpieza.
Validar worker y runner Python¦Piloto acredita 25 pruebas Python.
Registrar suite Flutter completa¦Piloto acredita 459 tests y análisis sin incidencias.
Validar backend real del piloto¦Reporte acredita 57 comprobaciones Supabase más ocho de lease.
Compilar APK, Web e iOS sin firma¦Piloto acredita compilaciones locales del proyecto.
Conservar límites de validación automática¦No marcar referencia AR como probada físicamente.
`);

const future='Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura.';
add('FIS01','Captura óptica real y calibración de panoramas',6,6,null,'Pendiente',
 ['docs/implementation/tours-local-pilot-report.md','docs/implementation/tours-native.md'],'TOU03, TOU04, PIL01',`
Preparar local autorizado para prueba¦Seleccionar posiciones reales con permiso del responsable.
Preparar Android de captura¦Conectar dispositivo y verificar cámara posterior principal.
Preparar iPhone de captura¦Configurar firma y equipo Apple antes de instalar.¦Bloqueado
Validar FOV frente al JPEG real¦Comprobar crop y posibles correcciones del ISP.
Validar signo yaw y pitch en teléfono¦Comparar horizonte y giros con orientación esperada.
Validar cenit y nadir¦Comprobar lectura de sensores apuntando a techo y piso.
Validar orientación al reabrir captura¦Recuperar sesión tras detener cámara.
Capturar esfera interior con techo y piso¦Mantener posición de lente y solapamiento.
Capturar escena con ventanas¦Evaluar contraste y reflejos del panorama.
Capturar escena de poca textura¦Comprobar suficiencia de coincidencias entre tomas.
Capturar objetos próximos¦Evaluar paralaje y errores de alineación.
Capturar patrones repetidos¦Detectar coincidencias geométricas incorrectas.
Interrumpir captura y retomar¦Comprobar persistencia y realineación en el dispositivo.
Cambiar lente durante recuperación¦Verificar rechazo o nueva captura sin pérdida de versión publicada.
Subir fotografías reales y procesarlas¦Ejecutar cadena completa contra Supabase y Docker.
Revisar cierre y costura ±180°¦Comprobar continuidad del resultado físico.
Revisar techo, piso y huecos¦Rechazar esferas con cobertura incompleta.
Medir tiempo y memoria con fotos reales¦Registrar consumo operativo separado del tiempo de trabajo.
Registrar recapturas necesarias¦Documentar defectos observados sin inventar resultados.
`,future);
add('FIS02','Aceptación física de reconocimiento AR',6,7,null,'Pendiente',
 ['docs/implementation/tours-local-pilot-report.md','docs/implementation/tours-native.md','docs/ar-experience-design.md'],'AR01, FIS01',`
Medir activador físico del local¦Registrar ancho real utilizado por la referencia AR.
Probar reconocimiento ARCore en Android¦Confirmar identificación sostenida de imagen física.
Probar reconocimiento ARKit en iPhone¦Depende de equipo Apple, firma y dispositivo compatible.¦Bloqueado
Probar rechazo del permiso de cámara¦Mantener lista y detalle operables.
Probar dispositivo sin soporte AR¦Mostrar alternativa sin iniciar sesión incompatible.
Probar referencia ilegible¦Explicar fallo sin fabricar reconocimiento.
Probar activador con reflejos¦Observar estabilidad en condiciones reales.
Retirar activador del encuadre¦Verificar pérdida de tracking y retiro de señal.
Recuperar tracking al reencuadrar¦Mantener ficha y recuperar señal solo con reconocimiento.
Enviar aplicación a segundo plano¦Comprobar liberación física de cámara.
Apagar y reanudar pantalla¦Validar continuidad de sesión y recursos.
Abrir contenido y regresar durante AR¦No conservar cámara activa fuera de la vista.
Cambiar de parada durante descarga¦No reactivar referencia anterior por respuesta tardía.
Cambiar cuenta durante AR¦Detener cámara, sensores y operaciones de la sesión anterior.
Cambiar mobiliario del espacio¦Identificar referencias y conexiones que requieren revisión.
Comprobar ancho y colocación de señal¦Validar escala y anclaje sobre referencia reconocida.
Guardar prueba física de versión de activador¦Acreditar tested_version solo tras prueba real satisfactoria.
Cerrar aceptación del módulo AR¦Cambiar WIP únicamente cuando criterios físicos estén cubiertos.
`,future);
add('COR01','Correcciones posteriores a pruebas físicas',7,7,null,'Pendiente',
 ['docs/implementation/tours-local-pilot-report.md','docs/ar-experience-design.md'],'FIS01, FIS02',`
Clasificar fallos de calibración observados¦Crear incidencias solo a partir de resultados de la prueba.
Corregir FOV o crop si se detecta error¦Ajustar implementación únicamente con evidencia óptica.
Corregir recuperación de captura si falla¦Conservar tomas y contexto de cuenta.
Corregir costura si la prueba lo exige¦Ajustar pipeline sin rellenar regiones ausentes.
Corregir reconocimiento AR si falla¦Distinguir calidad de activador, soporte y código.
Corregir lifecycle si quedan recursos activos¦Resolver cierre de cámara, sensores y escenas.
Añadir regresión para cada fallo confirmado¦Probar comportamiento afectado y límites pertinentes.
Repetir escenarios físicos afectados¦Confirmar solución en el dispositivo que falló.
Actualizar límites conocidos del módulo¦Conservar pendientes que aún no cumplen aceptación.
`,future+' Correcciones condicionales: no se afirma que esos defectos existan hoy.');
add('CLO01','Traspaso del procesador a Cloud Run',8,8,null,'Pendiente',
 ['docs/implementation/tours-local-pilot-report.md','processing/tours/README.md','processing/tours/bootstrap.sh','processing/tours/deploy.sh'],'PIL01, FIS01',`
Resolver verificación de facturación Google¦Requisito externo pendiente para Cloud Run.¦Bloqueado
Instalar y autenticar gcloud¦Requiere acceso autorizado al proyecto y cuenta.¦Bloqueado
Verificar permisos del proyecto Google¦Comprobar IAM antes de ejecutar scripts de despliegue.¦Bloqueado
Definir presupuesto de procesamiento¦Registrar coste permitido antes de operación continua.
Crear Artifact Registry autorizado¦Preparar destino de la imagen ya validada.
Subir la misma imagen validada¦Comprobar digest antes de publicar contenedor.
Crear cuentas de servicio del procesador¦Separar ejecución de jobs y despacho.
Configurar secretos de servidor¦Guardar credenciales en Secret Manager y backend.
Desplegar Cloud Run Job¦Usar 4 vCPU, 8 GiB y plazo 900 s del plan existente.
Autorizar dispatcher para ejecutar jobs¦Configurar OAuth e IAM de ejecución con overrides.
Probar trabajo remoto con recibo¦Exigir resultado confirmado en Supabase.
Probar concurrencia de dos jobs¦Verificar límite global y recursos reales.
Probar cancelación y respuesta perdida remotas¦No aceptar resultado antiguo ni duplicado.
Configurar canales de alerta¦Verificar entrega real de una alerta operativa.
Detener runner local antes de traspaso¦Evitar operación paralela no prevista del procesador.
Activar Vault y cron de tours¦Habilitar solo después del job remoto satisfactorio.
Comprobar primera ejecución programada¦Registrar estado, cola y logs del scheduler.
Medir coste del procesamiento remoto¦Comparar consumo y presupuesto del piloto.
`,future+' El despliegue está preparado por scripts, pero Cloud Run no se considera desplegado.');
add('QA02','Pruebas reales pendientes de acceso, medios y ubicación',9,9,null,'Pendiente',
 ['docs/email-setup.md','docs/deployment-status.md','docs/map.md','docs/access-redesign.md'],'ACC04, MAP01, PUS04',`
Registrar cuenta con un correo nuevo propio¦Comprobar entrega de OTP además de respuesta aceptada.
Completar confirmación con OTP recibido¦Verificar acceso desde el código real.
Solicitar y recibir recuperación real¦Probar entrega de código nuevo por SMTP.
Cambiar contraseña con código recuperado¦Comprobar login posterior con nueva contraseña.
Probar código incorrecto y reutilizado¦No conceder acceso fuera del flujo válido.
Probar selección nativa de avatar y portada¦Comprobar galería física, vista previa y persistencia.
Probar selección nativa de foto de post¦Validar permiso y upload desde teléfono.
Probar GPS y permiso en mapa físico¦Comprobar exactitud, rechazo y servicios desactivados.
Probar teclado físico en registro y compositor¦Verificar controles visibles con teclado real.
Probar lector de pantalla en destinos principales¦Comprobar etiquetas y orden de foco del dispositivo.
`,future);
add('QA03','Matriz física adicional de push y regresión integrada',9,9,null,'Pendiente',
 ['docs/android-push.md','docs/implementation/tours-local-pilot-report.md','docs/home-social-v7-integration.md'],'PUS04, COR01, CLO01',`
Probar permiso push denegado físicamente¦Mantener bandeja y ajustes disponibles.
Probar recuperación de permiso desde ajustes¦Registrar dispositivo solo cuando permiso sea válido.
Probar cambio de cuenta con push físico¦No abrir contenido ni registrar token en cuenta anterior.
Probar renovación real del token¦Comprobar versión nueva sin desactivar registro vigente.
Probar logout sin conexión en teléfono¦Verificar recuperación y separación de identidad.
Probar contenido eliminado desde aviso¦Abrir estado explicativo y conservar navegación.
Probar preferencias de mensajes ocasionales¦Comprobar horario y cancelación con condiciones controladas.
Ejecutar regresión automática integrada¦Validar módulos afectados por correcciones nuevas.
Verificar contratos de backend al cierre¦Comparar migraciones, permisos y funciones desplegadas.
Probar rutas directas del build final¦Cubrir posts, misiones, fichas y recorridos tras acceso.
Probar aislamiento entre dos cuentas reales¦Cubrir preferencias, muestras, borradores y progreso.
Revisar interfaz móvil y escritorio final¦Comprobar texto ampliado, teclado y paneles.
`,future);
add('PIL02','Piloto de aceptación en un local real',10,10,null,'Pendiente',
 ['docs/ar-experience-design.md','docs/implementation/tours-local-pilot-report.md'],'FIS01, FIS02, COR01, CLO01, QA02, QA03',`
Acreditar responsabilidad del local piloto¦Registrar permiso administrativo real del espacio.
Capturar varias posiciones del local¦Preparar contenido real autorizado.
Procesar y revisar panoramas del piloto¦Aceptar cobertura y calidad óptica del conjunto.
Configurar puntos y conexiones reales¦Comprobar nombres e indicaciones entre posiciones.
Solicitar permisos de contenido vinculado¦Excluir recursos no autorizados del envío.
Preparar y validar activadores reales¦Asociar prueba física a referencia y ancho exactos.
Enviar snapshot del recorrido piloto¦Mantener versión de revisión congelada.
Aprobar y publicar recorrido piloto¦Cambiar versión activa con permisos válidos.
Explorar recorrido desde otro usuario¦Comprobar lectura pública autorizada y contenido vigente.
Recorrer paradas físicamente con AR¦Validar reconocimiento y alternativa sin cámara.
Interrumpir subida y visita durante aceptación¦Confirmar recuperación y progreso real.
Registrar fallos y resultados del piloto¦Separar evidencia observada de criterios aún pendientes.
Corregir incidencias del piloto si aparecen¦No ampliar alcance sin necesidad demostrada.
Repetir criterios afectados¦Aceptar únicamente funciones verificadas tras corrección.
`,future);
add('ENT01','Estabilización y entrega técnica de la aplicación',11,11,null,'Pendiente',
 ['README.md','tool/README.md','docs/implementation/tours-local-pilot-report.md'],'PIL02, QA03',`
Revisar pendientes antes de cierre¦No declarar terminado AR si falta aceptación física.
Ejecutar análisis y pruebas finales¦Validar versión exacta que se entregará.
Confirmar contrato del backend final¦Verificar funciones y migraciones requeridas por el cliente.
Compilar Web de entrega¦Usar configuración pública correspondiente al entorno.
Preparar APK de entrega¦Definir artefacto de prueba o distribución según firma disponible.
Preparar iOS si existe firma y dispositivo¦Condicionar entrega iOS al equipo Apple y validación física.¦Bloqueado
Publicar actualización Web acordada¦Verificar recursos servidos y rutas después del despliegue.
Verificar instalación y arranque Android¦Comprobar acceso y funciones principales del build entregado.
Verificar operación de push y tours¦Comprobar schedulers, colas y procesadores activos.
Actualizar instrucciones técnicas¦Documentar ejecución, límites y recuperación de la aplicación.
Registrar versión y archivos entregados¦Relacionar artefactos con commit o snapshot verificable.
Cerrar aceptación técnica el 18 de noviembre¦Registrar responsable, resultado y pendientes que permanezcan.
`,future);

// Fechas individuales con significado explícito distinto del corte del grupo.
tasks.find(t=>t.id==='ACC04.015').date='2026-09-18';
tasks.find(t=>t.id==='ACC04.015').note='docs/email-setup.md acredita recepción y confirmación de una cuenta el 18/09; no duración de la actividad.';
tasks.find(t=>t.id==='PUS03.017').date='2026-10-05';
tasks.find(t=>t.id==='PUS03.017').note='docs/android-push.md fecha la publicación Web el 05/10/2026; no acredita duración de publicación.';
tasks.find(t=>t.id==='DIS01.001').date=null;
tasks.find(t=>t.id==='DIS01.001').sources=['output/imagegen/marea-home-hybrid.prompt.txt'];
tasks.find(t=>t.id==='DIS01.002').date=null;
tasks.find(t=>t.id==='DIS01.002').sources=['output/imagegen/marea-home-editorial-v2.prompt.txt'];
for(const id of ['QA01.001','QA01.002','QA01.003']) tasks.find(t=>t.id===id).date='2026-09-14';
tasks.find(t=>t.id==='QA01.004').date=null;
tasks.find(t=>t.id==='QA01.004').note='Documento actualizado de despliegue; publicación escolar confirmada sin fecha individual explícita en ese apartado.';
// El mapa no es prerrequisito del rediseño del compositor: sí lo es el selector de ubicación existente.
for(const t of tasks.filter(t=>t.parent==='MIS02')) t.deps='MIS01, COM02, PRO02';
groups.find(g=>g.id==='MIS02').deps='MIS01, COM02, PRO02';

add('DIS03','Implementaciones experimentales archivadas',4,4,'2026-09-29','Sustituido',
 ['docs/design-experiments/README.md','git:b565ef0:lib/features/shell/presentation/app_shell.dart','git:d54f4e5:lib/features/shell/presentation/app_shell.dart','docs/design-experiments/mobile-social-ui-design.md','docs/design-experiments/social-mobile-redesign-design.md'],'DIS01',`
Probar shell de navegación Corrientes locales¦Conservar composición móvil y rail de escritorio del experimento archivado.
Probar superficies Paper y acentos mint¦Conservar tema experimental sin aplicarlo a la interfaz v7 vigente.
Probar encabezados de comunidad experimentales¦Conservar énfasis editorial y contexto de autor.
Probar reorganización experimental de perfil¦Mantener implementación archivada como antecedente.
Probar rail adaptable a 600 y 1024 px¦Conservar distribución del segundo concepto móvil.
Probar anillos aqua de avatar¦Conservar tratamiento visual del experimento.
Archivar código de ambos experimentos¦Documentar implementaciones existentes sin contar los merges de conservación como funciones nuevas.
`,'Los commits b565ef0 y d54f4e5 conservan código de las propuestas. El merge con estrategia ours mantiene v7 como interfaz activa.');

// Orden de lectura por bloque estimado y evidencia fechada; los IDs permanecen estables.
groups.sort((a,b)=>a.start-b.start || (a.date||'2026-09-01').localeCompare(b.date||'2026-09-01'));
const order=new Map(groups.map((g,i)=>[g.id,i]));
tasks.sort((a,b)=>order.get(a.parent)-order.get(b.parent)||a.id.localeCompare(b.id));

export const metadata = {
  cutoff:'2026-10-06', start:'2026-09-01', end:'2026-11-18', timezone:'America/Mexico_City',
  estimatedPolicy:'Propuesta retrospectiva hasta el 06/10 y planificación futura después del corte. La barra cubre bloques de programación; no mide horas de esfuerzo ni capacidad del equipo.',
  realPolicy:'R es duración de trabajo efectiva acreditada. Commits, reportes y runtimes técnicos no acreditan por sí solos ese intervalo; se conservan como evidencia. Sin intervalo, R permanece vacía.',
  researchPolicy:research,
};
