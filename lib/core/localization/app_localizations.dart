import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;
  static Locale _activeLocale = const Locale('es', 'MX');
  static const supportedLocales = [Locale('es', 'MX'), Locale('en', 'US')];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return value ?? const AppLocalizations(Locale('es', 'MX'));
  }

  bool get isEnglish => locale.languageCode == 'en';

  String get settings => isEnglish ? 'Settings' : 'Configuración';
  String get account => isEnglish ? 'Account' : 'Cuenta';
  String get noEmail =>
      isEnglish ? 'No email available' : 'Sin correo disponible';
  String get changeEmail => isEnglish ? 'Change email' : 'Cambiar correo';
  String get changePassword =>
      isEnglish ? 'Change password' : 'Cambiar contraseña';
  String get profile => isEnglish ? 'Profile' : 'Perfil';
  String get editProfile => isEnglish ? 'Edit profile' : 'Editar perfil';
  String get interests =>
      isEnglish ? 'Interests and goals' : 'Intereses y objetivos';
  String get preferences => isEnglish ? 'Preferences' : 'Preferencias';
  String get language => isEnglish ? 'Language' : 'Idioma';
  String get notifications => isEnglish ? 'Notifications' : 'Notificaciones';
  String get session => isEnglish ? 'Session' : 'Sesión';
  String get signOut => isEnglish ? 'Sign out' : 'Cerrar sesión';
  String get deleteAccount => isEnglish ? 'Delete account' : 'Eliminar cuenta';
  String get permanentAction =>
      isEnglish ? 'This action is permanent.' : 'Esta acción es permanente.';
  String get spanish => 'Español';
  String get english => 'English';
  String get deleteQuestion =>
      isEnglish ? 'Delete your account?' : '¿Eliminar tu cuenta?';
  String get deleteWarning => isEnglish
      ? 'Your access, profile, preferences, and images will be permanently deleted. This action cannot be undone. If the process is interrupted, return here to complete the deletion.'
      : 'Se eliminarán permanentemente tu acceso, perfil, preferencias e imágenes. Esta acción no se puede deshacer. Si se interrumpe, vuelve aquí para completar la eliminación.';
  String get typeDelete => isEnglish
      ? 'Type DELETE to confirm.'
      : 'Escribe ELIMINAR para confirmar.';
  String get cancel => isEnglish ? 'Cancel' : 'Cancelar';
  String get deletePermanently =>
      isEnglish ? 'Delete permanently' : 'Eliminar definitivamente';
  String get deleteConfirmation => isEnglish ? 'DELETE' : 'ELIMINAR';

  String get settingsLanguage => isEnglish ? 'Language' : 'Idioma';
  String get notificationUnavailable => isEnglish
      ? 'This notification is no longer available.'
      : 'Esta notificación ya no está disponible.';

  /// Translates exact catalog phrases or matching templates, preserving values.
  /// Unknown phrases intentionally remain in Spanish until reviewed.
  static String tr(String spanish) {
    if (_activeLocale.languageCode != 'en') return spanish;
    return _englishCatalog[spanish] ??
        _translateCatalogTemplate(spanish) ??
        spanish;
  }

  static String? _translateCatalogTemplate(String phrase) {
    for (final entry in _englishCatalog.entries) {
      final placeholders = RegExp(
        r'\{([A-Za-z0-9_]+)\}',
      ).allMatches(entry.key).toList();
      if (placeholders.isEmpty) continue;

      final pattern = StringBuffer('^');
      var offset = 0;
      for (final placeholder in placeholders) {
        pattern
          ..write(RegExp.escape(entry.key.substring(offset, placeholder.start)))
          ..write('(.*?)');
        offset = placeholder.end;
      }
      pattern
        ..write(RegExp.escape(entry.key.substring(offset)))
        ..write(r'$');
      final match = RegExp(pattern.toString(), dotAll: true).firstMatch(phrase);
      if (match == null) continue;

      var translated = entry.value;
      for (var i = 0; i < placeholders.length; i++) {
        translated = translated.replaceAll(
          placeholders[i].group(0)!,
          match.group(i + 1)!,
        );
      }
      return translated;
    }
    return null;
  }

  static String trTemplate(String key, Map<String, String> values) {
    var value = _activeLocale.languageCode == 'en'
        ? _englishCatalog[key] ?? key
        : key;
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  static const _englishCatalog = <String, String>{
    'No se pudo iniciar la conexión con el servidor.':
        'Could not connect to the server.',
    'El servicio de MAREA necesita actualizarse para guardar estos cambios. Tus datos siguen aquí; vuelve a intentarlo cuando esté disponible.':
        'MAREA needs a service update to save these changes. Your data is still here; try again when the service is available.',
    'La elección inicial de tu perfil ya está confirmada. Actualiza la pantalla para continuar.':
        'Your initial profile choice is already confirmed. Refresh the screen to continue.',
    'Confirma tu tipo de perfil para continuar.':
        'Confirm your profile type to continue.',
    'Revisa tus horarios: usa un intervalo como 09:00-18:00.':
        'Check your hours and use a time range such as 09:00–18:00.',
    'Esta ficha no está disponible para tu tipo de perfil.':
        'This listing is not available for your profile type.',
    'Esta ficha ya no está disponible para esta acción.':
        'This listing is no longer available for this action.',
    'Ya enviaste un reporte para esta ficha.':
        'You have already reported this listing.',
    'El servicio de correo de MAREA todavía no puede enviar a esta dirección. No necesitas cambiar tu correo; inténtalo cuando el servicio esté disponible.':
        'MAREA’s email service cannot send to this address yet. You do not need to change your email; try again when the service is available.',
    'No pudimos solicitar el correo. El servicio de correo no está disponible; inténtalo más tarde.':
        'We could not request the email. The email service is unavailable; try again later.',
    'La eliminación no ha terminado. Espera a que finalice la subida de imágenes y vuelve a intentarlo. Si se interrumpió, algunos archivos pueden haberse eliminado ya.':
        'Deletion is not finished. Wait for image uploads to complete, then try again. If it was interrupted, some files may already have been deleted.',
    'Hay otra operación con imágenes o una eliminación en curso. Espera un momento y vuelve a intentarlo.':
        'Another image operation or deletion is in progress. Wait a moment, then try again.',
    'No pudimos validar la imagen. Prueba con otra más pequeña.':
        'We could not validate the image. Try a smaller one.',
    'Hay varias imágenes pendientes de limpieza. Vuelve a intentarlo más tarde.':
        'Several images are pending cleanup. Try again later.',
    'El registro requiere los documentos legales vigentes. Actualiza la pantalla e inténtalo de nuevo.':
        'Registration requires the current legal documents. Refresh the screen and try again.',
    'La eliminación de tu cuenta está en curso. Vuelve a Configuración para reintentar.':
        'Your account deletion is in progress. Return to Settings to try again.',
    'Espera un momento antes de volver a intentarlo.':
        'Wait a moment before trying again.',
    'Código incorrecto o vencido.': 'Incorrect or expired code.',
    'Confirma tu correo antes de iniciar sesión. Puedes reenviar el código.':
        'Confirm your email before signing in. You can resend the code.',
    'Confirma el código de seguridad enviado a tu correo para continuar.':
        'Confirm the security code sent to your email to continue.',
    'Elige una contraseña nueva y más segura.':
        'Choose a new, stronger password.',
    'El correo o la contraseña no son correctos.':
        'The email or password is incorrect.',
    'Tu sesión ya no es válida. Inicia sesión nuevamente.':
        'Your session is no longer valid. Sign in again.',
    'Este nombre de usuario ya está ocupado.':
        'This username is already taken.',
    'Ya existe una cuenta con este correo.':
        'An account with this email already exists.',
    'No pudimos conectarnos. Inténtalo nuevamente.':
        'We could not connect. Please try again.',
    'Algo salió mal. Inténtalo nuevamente.':
        'Something went wrong. Please try again.',
    'El chat todavía no está habilitado en este servicio. Aplica la migración 022_private_chat.sql y vuelve a intentarlo.':
        'Chat is not enabled for this service yet. Apply the 022_private_chat.sql migration and try again.',
    'Este chat está bloqueado.': 'This chat is blocked.',
    'Este chat ya no está disponible.': 'This chat is no longer available.',
    'Escribe entre 1 y 2.000 caracteres.':
        'Enter between 1 and 2,000 characters.',
    'No pudimos abrir la cámara.': 'We could not open the camera.',
    'No pudimos abrir la cámara. Inténtalo nuevamente.':
        'We could not open the camera. Please try again.',
    'No pudimos capturar la foto. Inténtalo nuevamente.':
        'We could not take the photo. Please try again.',
    'No pudimos abrir esa foto. Inténtalo nuevamente.':
        'We could not open that photo. Please try again.',
    'Traducir publicación': 'Translate post',
    'Ver original': 'Show original',
    'No pudimos identificar el idioma de esta publicación.':
        'We could not identify the language of this post.',
    'Todavía no podemos traducir publicaciones en este idioma.':
        'Posts in this language cannot be translated yet.',
    'No se pudo descargar el modelo de traducción. Conéctate a internet e inténtalo de nuevo.':
        'Could not download the translation model. Connect to the internet and try again.',
    'Esta publicación ya está en el idioma seleccionado.':
        'This post is already in your selected language.',
    'Ir a iniciar sesión': 'Go to sign in',
    'Código': 'Code',
    'Fotografía': 'Photo',
    'Contraseña': 'Password',
    'Contraseña actual': 'Current password',
    'Código de seguridad': 'Security code',
    'Más filtros': 'More filters',
    'Reportar misión': 'Report mission',
    'Opciones de misión': 'Mission options',
    'Compartir misión': 'Share mission',
    'Abre la conversación con el primer comentario.':
        'Open the conversation with the first comment.',
    'Esta sección está reservada para administradores.':
        'This section is reserved for administrators.',
    'Reportar publicación': 'Report post',
    'Cuéntanos qué ocurre': 'Tell us what happened',
    'Interés de colaboración': 'Collaboration interest',
    'Abrir galería': 'Open gallery',
    'Cerrar misión': 'Close mission',
    'Imágenes': 'Images',
    'Añadir intereses': 'Add interests',
    'Sobre mí': 'About me',
    'Más información': 'More information',
    'Información profesional': 'Professional information',
    'Quitar ubicación': 'Remove location',
    'Menú del perfil': 'Profile menu',
    'Cerrar menú': 'Close menu',
    'Cerrar menú de creación': 'Close creation menu',
    'Información': 'Information',
    'Fotografía anterior': 'Previous photo',
    'Fotografía siguiente': 'Next photo',
    'Eliminar conexión': 'Delete connection',
    'Música': 'Music',
    'Aceptar': 'Accept',
    'Abrir cámara': 'Open camera',
    'Acción registrada.': 'Action recorded.',
    'Añadir': 'Add',
    'Añadir enlace': 'Add link',
    'Añadir muestra': 'Add sample',
    'Atrás': 'Back',
    'Cancelar': 'Cancel',
    'Cargar más misiones': 'Load more missions',
    'Cerrar cámara': 'Close camera',
    'Cerrar sesión': 'Sign out',
    'Continuar': 'Continue',
    'Continuar recorrido': 'Continue tour',
    'Crear cuenta': 'Create account',
    'Crear misión': 'Create mission',
    'Crear publicación': 'Create post',
    'Crear recorrido 360°': 'Create 360° tour',
    'Editar': 'Edit',
    'Eliminar': 'Delete',
    'Eliminar publicación': 'Delete post',
    'Enviar': 'Send',
    'English': 'English',
    'Escribe ELIMINAR para confirmar.': 'Type DELETE to confirm.',
    'Finalizar visita': 'Finish visit',
    'Guardar': 'Save',
    'Iniciar sesión': 'Sign in',
    'La sesión cambió. Vuelve a abrir la experiencia.':
        'The session changed. Open the experience again.',
    'Misión': 'Mission',
    'Mensajes': 'Messages',
    'No hay solicitudes pendientes.': 'There are no pending requests.',
    'No pudimos conectar con la comunidad.':
        'We could not connect to the community.',
    'Perfil': 'Profile',
    'Publicación': 'Post',
    'Recorrer con cámara': 'Explore with camera',
    'Reintentar': 'Retry',
    'Reintentar imagen': 'Retry image',
    'Revisa tu correo y spam.': 'Check your email and spam folder.',
    'Saltar parada': 'Skip stop',
    'Selecciona una conversación': 'Select to conversation',
    'Solicitudes y revisión': 'Requests and review',
    'Todas': 'All',
    'Todas las categorías': 'All categories',
    'Ver contenido': 'View content',
    'Ver perfil': 'View profile',
    'Ver ubicación': 'View location',
    'Volver': 'Back',
    'Volver al perfil': 'Back to profile',
    'Ya tengo un código': 'I already have to code',
    '¿No tienes cuenta?': "Don't have an account?",
    '¿Qué perfil quieres crear?': 'What profile do you want to create?',
    '¿Eliminar publicación?': 'Delete post?',
    'Esta página no existe.': 'This page does not exist.',
    'Tu publicación': 'Your post',
    'Correo': 'Email',
    'Usar otro correo': 'Use another email',
    '¿No llegó? Revisa spam o reenvía el código.':
        'Didn’t receive it? Check your spam folder or resend the code.',
    'Inicio': 'Home',
    'Descubrir': 'Discover',
    'Mapa': 'Map',
    'Notificaciones': 'Notifications',
    'Guardados': 'Saved',
    'Herramientas': 'Tools',
    'Mis postulaciones': 'My applications',
    'Agregar publicación': 'Add post',
    'Configuración': 'Settings',
    'Configuración de tu cuenta': 'Account settings',
    'Solicitud aceptada. Ya pueden conversar.':
        'Request accepted. You can now chat.',
    'Solicitud enviada. Podrás escribir cuando la otra persona acepte.':
        'Request sent. You can message once the other person accepts.',
    'Ver mensajes': 'View messages',
    'Aceptar solicitud': 'Accept request',
    'Solicitar chat': 'Request chat',
    'Ver todo': 'View all',
    'Ver todas': 'View all',
    'El contenido no está disponible en este momento.':
        'Content is unavailable right now.',
    'Este perfil aún no tiene contenido para mostrar.':
        'This profile has no content to show yet.',
    'Misiones destacadas': 'Featured missions',
    'Las misiones no están disponibles en este momento.':
        'Missions are unavailable right now.',
    'Este perfil aún no ha publicado misiones.':
        'This profile has not published any missions yet.',
    'Misiones del perfil': 'Profile missions',
    'Ubicación no indicada': 'Location not provided',
    'Portafolio': 'Portfolio',
    'Catálogo': 'Catalog',
    'Servicios': 'Services',
    'Obra / proyecto': 'Project',
    'Agregar obra': 'Add project',
    'Agregar producto': 'Add product',
    'Agregar servicio': 'Add service',
    'Archivado': 'Archived',
    'Tus herramientas': 'Your tools',
    'Cerrar herramientas': 'Close tools',
    'Comparte con la comunidad. Elige entre los formatos de tu perfil.':
        'Share with the community using a format available for your profile.',
    'Todos los perfiles pueden organizar una colaboración.':
        'All profile types can organize a collaboration.',
    'Encontrar colaboraciones': 'Find collaborations',
    'Misiones para tu tipo de perfil y convocatorias abiertas a todos.':
        'Missions for your profile type and opportunities open to everyone.',
    'Gestiona borradores, fotografías y fichas de tu perfil.':
        'Manage drafts, photos, and listings on your profile.',
    'Tus recorridos 360°': 'Your 360° tours',
    'Captura posiciones del local, conecta panoramas y prepara AR.':
        'Capture locations in your venue, connect panoramas, and prepare AR.',
    'Solicitudes de recorridos': 'Tour requests',
    'Autoriza contenido y revisa propuestas.':
        'Approve content and review submissions.',
    'Explora las misiones en el mapa.': 'Explore missions on the map.',
    'Revisa tus avisos.': 'Review your notifications.',
    'Contenido que guardaste.': 'Content you saved.',
    'Misiones de tu cuenta.': 'Missions from your account.',
    'Revisa tus candidaturas.': 'Review your applications.',
    'Guía de perfil': 'Profile guide',
    'Completar perfil': 'Complete profile',
    'Presentación, intereses y opciones de tu cuenta.':
        'Your introduction, interests, and account options.',
    'Datos profesionales': 'Professional details',
    'Edita contacto, ubicación y horarios.':
        'Edit contact details, location, and hours.',
    'Edita contacto y disponibilidad para colaborar.':
        'Edit your contact details and collaboration availability.',
    'Edita la información profesional de tu perfil.':
        'Edit the professional information on your profile.',
    'Revisa reportes y visibilidad de contenido.':
        'Review reports and content visibility.',
    'Cómo funcionan las misiones': 'How missions work',
    'Puedes organizar misiones con cualquier tipo de perfil. Para postularte, el perfil solicitado debe coincidir con el tuyo o aceptar a todos.':
        'Any profile type can organize missions. To apply, your profile type must match the requested type, or the mission must be open to everyone.',
    'El organizador revisa y selecciona participantes. Solo él puede editar, cerrar, cancelar o finalizar su misión. La moderación de contenido requiere una cuenta administradora.':
        'The organizer reviews and selects participants. Only the organizer can edit, close, cancel, or complete their mission. Content moderation requires an administrator account.',
    'Opciones del perfil': 'Profile options',
    'Ver {section}': 'View {section}',
    'Misiones completadas': 'Completed missions',
    'Valoración': 'Rating',
    'Porcentaje de respuesta': 'Response rate',
    'Colaboraciones locales': 'Local collaborations',
    'Sin datos': 'No data',
    'Sobre nosotros': 'About us',
    'Este perfil aún no ha añadido una descripción.':
        'This profile has not added a description yet.',
    'Aún no hay intereses seleccionados.':
        'No interests have been selected yet.',
    'Me mueve': 'What drives me',
    'Editar intereses': 'Edit interests',
    'No hay contenido para mostrar.': 'There is no content to show.',
    'Cerrar lista': 'Close list',
    'Sitio web': 'Website',
    'Sin pendientes': 'No pending items',
    '{count} sin leer': '{count} unread',
    'Publicaciones': 'Posts',
    'Para ti': 'For you',
    'Cerca': 'Nearby',
    'Siguiendo': 'Following',
    'Tendencias': 'Trending',
    'A {radius} km': 'Within {radius} km',
    'No hay contenido de personas que sigues. Encuentra personas en Explorar y pulsa Seguir.':
        'There is no content from people you follow. Find people in Explore and tap Follow.',
    'Elige tu ubicación para ver qué hay cerca.':
        'Choose your location to see what is nearby.',
    'No hay contenido con estos filtros. Vuelve más tarde o cambia los filtros.':
        'There is no content with these filters. Come back later or change the filters.',
    'Olvidé mi contraseña': 'Olvidé mi contraseñto',
    'Continuar con Google': 'Continue with Google',
    'Saltar': 'Skip',
    'Cambiar': 'Change',
    'Recuperar contraseña': 'Recover contraseñto',
    'Guardar contraseña': 'Save contraseñto',
    'Confirmar nueva contraseña': 'Confirm new contraseñto',
    'Enviar código por correo': 'Send código by email',
    'Aún no tienes conversaciones.': 'Aún not you have conversations.',
    'Reportar conversación': 'Report conversación',
    'Este chat está bloqueado temporalmente.':
        'This chat está blocked temporarily.',
    'No encontramos perfiles con ese nombre.':
        'We could not find profiles with that name.',
    '¿Eliminar borrador?': 'Delete draft?',
    'Retirar postulación': 'Withdraw postulación',
    'Volver a misiones': 'Back to missions',
    '¿Salir de tu candidatura?': '¿Leave of your application?',
    'Tu candidatura': 'Your application',
    'Esta misión ya no está disponible.':
        'This mission is no longer available.',
    'Ver mis candidaturas': 'View my applications',
    'Añadir enlace · {count}/3': 'Add link · {count}/3',
    'Editar candidatura': 'Edit application',
    'Añadir una muestra': 'Add a sample',
    'No pudimos abrir el enlace.': 'We could not open the link.',
    'No encontramos una candidatura tuya para esta misión.':
        'We could not find an application from you for this mission.',
    '¿Salir sin guardar?': 'Leave without saving?',
    '¿Qué hacemos con tu idea?': 'What would you like to do with your idea?',
    'Guardar borrador': 'Save draft',
    'Revisar selección': 'Review selection',
    '• {name}': '• {name}',
    'Cancelar misión': 'Cancel mission',
    'Motivo de cancelación (visible para la comunidad)':
        'Reason of cancelación (visible for the community)',
    'Editar misión': 'Edit mission',
    'Finalizar misión': 'Finish mission',
    'Inicio · {date}': 'Home · {date}',
    'No hay candidaturas en este grupo.':
        'There are no applications in this group.',
    'No seleccionar': 'Do not select',
    'Tu comentario': 'Your comment',
    'Enviando…': 'Sending…',
    'Este comentario fue retirado.': 'This comment was removed.',
    'Cargar más comentarios': 'Load more comments',
    'Gestionar misión': 'Manage mission',
    'Ver misión': 'View mission',
    'Moderación': 'Moderation',
    'Cargar más reportes': 'Load more reports',
    'Ubicación: {location}': 'Location: {location}',
    'Cancelación: {reason}': 'Cancellation: {reason}',
    'Marcando…': 'Marking…',
    'Marcar todo como leído': 'Mark all as read',
    'Cargar más notificaciones': 'Load more notifications',
    'Cargar más publicaciones': 'Load more posts',
    'Ver más': 'View more',
    '¿Descartar borrador?': 'Discard draft?',
    'Los cambios todavía no se han publicado.':
        'Your changes have not been published yet.',
    'Escribe una dirección o elige en el mapa':
        'Enter an address or choose a point on the map',
    'Elegir ubicación en el mapa': 'Choose a location on the map',
    'No pudimos cargar la imagen.': 'We could not load the image.',
    'Quitar fotografía': 'Remove photo',
    'Esta publicación fue retirada o ya no está disponible.':
        'This post was removed or is no longer available.',
    '© OpenStreetMap contributors': '© OpenStreetMap contributors',
    'Usar mi ubicación actual': 'Use mi ubicación current',
    'Reintentar ubicación': 'Retry ubicación',
    'Usar esta ubicación': 'Use this location',
    'Ubicación': 'Location',
    'Retirar reacción': 'Withdraw reacción',
    'Elegir reacción': 'Choose reacción',
    'Tu mensaje': 'Your mensaje',
    'Enviar interés': 'Send interés',
    'Reintentar ciudad': 'Retry ciudad',
    'Punto elegido': 'Point selected',
    'Contenido': 'Content',
    'Categoría': 'Category',
    'Distancia': 'Distance',
    'Aplicar filtros': 'Apply filters',
    'Restablecer': 'Reset',
    'Filtrar Inicio': 'Filter Home',
    'Localizando…': 'Locating…',
    'Mi ubicación': 'My ubicación',
    'Elegir punto': 'Choose punto',
    'La comunidad no está disponible.': 'The community not está available.',
    'Cargar más': 'Load more',
    'Ver detalles': 'View detalles',
    'Tu historia': 'Your story',
    'Cambiar flash': 'Change flash',
    'Cambiar cámara': 'Change camera',
    'Añadir texto': 'Add text',
    'Escribe algo...': 'Enter something...',
    'Actualizar historias reportadas': 'Refresh stories reported',
    'No hay historias reportadas.': 'There are no stories reported.',
    'La foto no está disponible.': 'The photo is unavailable.',
    'Motivo: {reason}': 'Reason: {reason}',
    '¿Eliminar historia?': '¿Delete historia?',
    'Reportar historia': 'Report story',
    'Motivo (mínimo 5 caracteres)': 'Reason (mínimo 5 characters)',
    'Enviar reporte': 'Send report',
    'Términos': 'Terms',
    'Términos y condiciones': 'Terms and conditions',
    'Aviso de privacidad': 'Privacy notice',
    'Notificaciones en este celular': 'Notifications on this device',
    'Los avisos en este celular aún no están disponibles':
        'Notifications on this device are not available yet',
    'Permitidas por Android': 'Allowed by Android',
    'Activa el permiso de notificaciones en Android':
        'Enable notification permission in Android',
    'Permiso Android': 'Android permission',
    'Reacciones, comentarios, colaboraciones y misiones':
        'Reactions, comments, collaborations, and missions',
    'Un empujoncito creativo después de unos días sin entrar':
        'A creative nudge after a few days away',
    'Filtros del mapa': 'Map filters',
    'Radio alrededor del centro de esta zona':
        'Radius around the center of this area',
    'Sin límite': 'No limit',
    'Fecha': 'Date',
    'Cualquier fecha': 'Any date',
    'Hoy': 'Today',
    'Próximos siete días': 'Next seven days',
    'Limpiar filtros': 'Clear filters',
    'Puedes cambiar el permiso en los ajustes del navegador o del dispositivo.':
        'You can change permission in your browser or device settings.',
    'Descubrir cerca': 'Discover nearby',
    'Buscar en esta zona': 'Search this area',
    'No pudimos cargar el mapa base. Puedes seguir usando los filtros.':
        'We could not load the base map. You can still use the filters.',
    'Ajustes': 'Settings',
    'Cerrar': 'Close',
    'Buscando ubicación…': 'Finding location…',
    'Centrar en mi ubicación': 'Center on my location',
    'Resultados de la zona anterior': 'Results from the previous area',
    'No encontramos misiones por aquí todavía.':
        'No missions found nearby yet.',
    'Mostrando {shown} de {total} · Acerca el mapa':
        'Showing {shown} of {total} · Zoom in',
    '{count} misión en esta zona': '{count} mission in this area',
    '{count} misiones en esta zona': '{count} missions in this area',
    'Elige tu perfil': 'Choose your profile',
    'El tipo de perfil queda fijo.': 'Your profile type cannot be changed.',
    'Confirmar y entrar': 'Confirm and enter',
    'Todos los perfiles': 'All profiles',
    'Sin pago': 'Unpaid',
    'Compensación por acordar': 'Compensation to be agreed',
    '{amount} MXN por participante': '{amount} MXN per participant',
    'Compensación no indicada': 'Compensation not specified',
    'Usuario general': 'General user',
    'Artista / creador': 'Artist / creator',
    'Emprendedor': 'Entrepreneur',
    'Negocio': 'Business',
    'Arte': 'Art',
    'Digital': 'Digital',
    'Gastronomía': 'Food',
    'Escritura': 'Writing',
    'Diseño': 'Design',
    'Otros': 'Other',
    'Esta misión no está disponible para editar.':
        'This mission is not available for editing.',
    'Este borrador no está disponible.': 'This draft is not available.',
    'Tienes cambios que todavía no has guardado.': 'You have unsaved changes.',
    'Puedes guardar lo que llevas y continuar después.':
        'You can save your progress and continue later.',
    'Seguir editando': 'Keep editing',
    'Descartar cambios': 'Discard changes',
    'Fecha de la misión': 'Mission date',
    'Hora de inicio': 'Start time',
    'No pudimos conectar. Inténtalo de nuevo.':
        'We could not connect. Please try again.',
    'Borrador guardado. Puedes retomarlo en Mis misiones.':
        'Draft saved. You can resume it in My missions.',
    'Esta misión ya fue publicada y ya no está disponible.':
        'This mission has already been published and is no longer available.',
    'Tu misión ya fue publicada. Los cambios posteriores no se publicaron.':
        'Your mission was published. Later changes were not published.',
    'Revisa el título de la misión.': 'Check the mission title.',
    'Completa la descripción de la misión.':
        'Complete the mission description.',
    'Revisa el cupo de la misión.': 'Check the mission capacity.',
    'Revisa los requisitos y condiciones.': 'Check the requirements and terms.',
    'Revisa la compensación de la misión.': 'Check the mission compensation.',
    'Completa el lugar de la misión.': 'Complete the mission location.',
    'Selecciona la fecha y la hora.': 'Select a date and time.',
    'Elige una fecha y hora futuras.': 'Choose a future date and time.',
    '¿Qué quieres hacer posible?': 'What do you want to make possible?',
    'Demos forma a la colaboración': "Let's shape the collaboration",
    'Un lugar y un momento': 'A place and a time',
    'Revisa tu misión': 'Review your mission',
    'La idea': 'The idea',
    'La colaboración': 'The collaboration',
    'Lugar y fecha': 'Place and date',
    'Una idea clara invita a más personas a sumarse.':
        'A clear idea invites more people to join.',
    'Cuenta qué necesitas y qué ofreces a quienes participen.':
        'Describe what you need and what you offer participants.',
    'Ayuda a las personas a organizarse y llegar.':
        'Help people plan and get there.',
    'Así se verá tu convocatoria. Puedes corregir cada sección.':
        'This is how your mission will appear. You can edit each section.',
    'Nueva misión': 'New mission',
    'Paso {step} de 4: {section}': 'Step {step} of 4: {section}',
    'PASO {step} DE 4 · {section}': 'STEP {step} OF 4 · {section}',
    'Ya recibiste candidaturas: el perfil, la fecha, el lugar y la compensación quedan fijos. Puedes corregir los textos y aumentar el cupo.':
        'You have received applications: the profile, date, place, and compensation are fixed. You can edit the text and increase the capacity.',
    'Título de la misión': 'Mission title',
    'Ej. Retrata la vida de nuestro mercado': 'e.g. Capture life in our market',
    '¿Qué haremos y por qué vale la pena sumarse?':
        'What will we do, and why is it worth joining?',
    'Imagen de portada': 'Cover image',
    'Cambiar fotografía': 'Change photo',
    'Opcional · JPG, PNG o WebP · hasta 10 MB':
        'Optional · JPG, PNG, or WebP · up to 10 MB',
    'Perfil participante': 'Participant profile',
    'Número de participantes': 'Number of participants',
    'Elige entre 1 y 100 personas.': 'Choose between 1 and 100 people.',
    'El cupo solo puede aumentar (mínimo {capacity}).':
        'Capacity can only be increased (minimum {capacity}).',
    'Elige una compensación.': 'Choose compensation.',
    'Por acordar': 'To be agreed',
    'Importe fijo': 'Fixed amount',
    'Compensación no indicada en la misión original.':
        'Compensation not specified in the original mission.',
    'Importe por participante (MXN)': 'Amount per participant (MXN)',
    'Ej. 250.50': 'e.g. 250.50',
    'Introduce un importe positivo con hasta dos decimales.':
        'Enter a positive amount with up to two decimal places.',
    'Requisitos (opcional)': 'Requirements (optional)',
    'Experiencia, materiales o habilidades necesarias':
        'Required experience, materials, or skills',
    'Qué ofrecemos y condiciones (opcional)':
        'What we offer and terms (optional)',
    'Recursos, acuerdos y detalles de la participación':
        'Resources, agreements, and participation details',
    'Ej. Casa de la Cultura, Manzanillo': 'e.g. Casa de la Cultura, Manzanillo',
    'Ubicar en el mapa (opcional)': 'Pin on map (optional)',
    'Cambiar punto del mapa': 'Change map point',
    'Puedes escribir el lugar sin usar el mapa ni compartir tu ubicación.':
        'You can enter a place without using the map or sharing your location.',
    'Punto aproximado guardado': 'Approximate point saved',
    'Punto del mapa guardado': 'Map point saved',
    'Las personas podrán enviar su candidatura hasta el inicio de la misión.':
        'People can apply until the mission starts.',
    '{target} · {count} lugar': '{target} · {count} place',
    '{target} · {count} lugares': '{target} · {count} places',
    'Editar {section}': 'Edit {section}',
    'Ver misión publicada': 'View published mission',
    'Guardar cambios': 'Save changes',
    'Publicar misión': 'Publish mission',
    'Completa este campo.': 'Complete this field.',
    'Escribe al menos {min} caracteres.': 'Enter at least {min} characters.',
    'Usa hasta {max} caracteres.': 'Use at most {max} characters.',
    'Inicia sesión para participar.': 'Sign in to apply.',
    'No pudimos cargar tus fichas. Puedes adjuntar un enlace o reintentar.':
        'We could not load your showcases. You can attach a link or try again.',
    'Los datos de esta candidatura todavía no se han enviado.':
        'This application has not been submitted yet.',
    'Descartar y salir': 'Discard and leave',
    'Tu candidatura ya fue enviada. Los cambios posteriores no se enviaron.':
        'Your application was already submitted. Later changes were not sent.',
    'Este enlace ya está en tu candidatura.':
        'This link is already in your application.',
    'Cerrar candidatura': 'Close application',
    'Ya tienes una candidatura para esta misión. Puedes seguir su estado en Mis candidaturas.':
        'You already applied to this mission. You can track its status in My applications.',
    'Candidatura enviada': 'Application submitted',
    'Disponibilidad confirmada': 'Availability confirmed',
    'Disponibilidad no registrada': 'Availability not recorded',
    'PASO {step} DE 3': 'STEP {step} OF 3',
    'Antes de sumarte': 'Before you join',
    'Haz que tu trabajo hable': 'Let your work speak',
    'Tu candidatura, lista para salir': 'Your application is ready to send',
    'Revisa lo que haremos juntos y las condiciones de la misión.':
        'Review what we will do together and the mission terms.',
    'Cuéntanos qué puedes aportar. Las muestras de trabajo son opcionales.':
        'Tell us what you can contribute. Work samples are optional.',
    'Comprueba tus datos antes de compartirlos con el organizador.':
        'Check your details before sharing them with the organizer.',
    'Lo que necesitas': 'What you will need',
    'Condiciones de colaboración': 'Collaboration terms',
    'Enviar una candidatura expresa tu interés. El organizador revisará tu propuesta y podrás consultar la respuesta en MAREA.':
        'Submitting an application shows your interest. The organizer will review your proposal, and you can check their response in MAREA.',
    'Elige hasta 3 muestras relevantes': 'Choose up to 3 relevant samples',
    'Puedes incluir hasta tres muestras.':
        'You can include up to three samples.',
    'Cargando fichas…': 'Loading showcases…',
    'Quitar muestra': 'Remove sample',
    'Cuéntanos por qué encajas': 'Tell us why you are a good fit',
    'Cuéntanos por qué encajas.': 'Tell us why you are a good fit.',
    'Cuenta qué puedes aportar de forma concreta. Una candidatura personal ayuda a conocer tu propuesta.':
        'Describe specifically what you can contribute. A personal application helps us understand your proposal.',
    'Confirmo mi disponibilidad': 'I confirm my availability',
    'Confirma tu disponibilidad para la fecha de la misión.':
        'Confirm your availability for the mission date.',
    'Disponibilidad confirmada · {date}': 'Availability confirmed · {date}',
    'Tu propuesta': 'Your proposal',
    'Tus muestras': 'Your samples',
    'Tu candidatura y tus muestras solo serán visibles para ti y para el organizador.':
        'Your application and samples will only be visible to you and the organizer.',
    'Revisar candidatura': 'Review application',
    'Enviar candidatura': 'Submit application',
    'Título de la muestra': 'Sample title',
    'Escribe un título.': 'Enter a title.',
    'Enlace HTTPS': 'HTTPS link',
    'Muestra no disponible': 'Sample unavailable',
    'Cargando muestra…': 'Loading sample…',
    '¡Tu candidatura ya está en movimiento!': 'Your application is on its way!',
    'Tu candidatura se guardó. La misión ya no está disponible; puedes consultar tu historial.':
        'Your application was saved. The mission is no longer available; you can check your history.',
    'Hemos enviado tu candidatura para «{title}». Puedes seguir su estado en Mis candidaturas.':
        'We submitted your application for “{title}”. You can track its status in My applications.',
    '¿Qué pasa ahora? El organizador revisará tu propuesta. Cuando haya una respuesta, aparecerá en tus notificaciones de MAREA.':
        'What happens next? The organizer will review your proposal. When they respond, you will see it in your MAREA notifications.',
    'Seguir explorando': 'Keep exploring',
    'ASÍ LA VERÁ LA COMUNIDAD': 'HOW THE COMMUNITY WILL SEE IT',
    'Por {organizer}': 'By {organizer}',
    'la comunidad MAREA': 'the MAREA community',
    '{available} de {total} lugares disponibles':
        '{available} of {total} spots available',
    '{available} de {total} lugar disponible':
        '{available} of {total} spot available',
    '{pending} pendientes · {accepted} aceptadas':
        '{pending} pending · {accepted} accepted',
    'Misión que organizas': 'Mission you organize',
    'Compatible con tu perfil': 'Matches your profile',
    'Busca otro tipo de perfil': 'Looking for another profile type',
    'Qué ofrecemos y condiciones': 'What we offer and terms',
    'Oculta por moderación': 'Hidden by moderation',
    'Cancelada': 'Cancelled',
    'Finalizada': 'Completed',
    'Convocatoria vencida': 'Mission expired',
    'Sin cupo': 'Full',
    'Abierta': 'Open',
    'Cerrada': 'Closed',
    'Inicia sesión para gestionar tus misiones.':
        'Sign in to manage your missions.',
    'Solo el organizador puede gestionar esta misión.':
        'Only the organizer can manage this mission.',
    'Solo quedan {count} lugares disponibles. Ajusta tu selección.':
        'Only {count} spots are available. Adjust your selection.',
    'Solo queda {count} lugar disponible. Ajusta tu selección.':
        'Only {count} spot is available. Adjust your selection.',
    'Confirmarás {count} participantes para «{title}».':
        'You will confirm {count} participants for “{title}”.',
    'Confirmarás 1 participante para «{title}».':
        'You will confirm 1 participant for “{title}”.',
    'La convocatoria conservará su estado. Las otras candidaturas seguirán pendientes.':
        'The mission will keep its current status. Other applications will remain pending.',
    'Confirmar participantes': 'Confirm participants',
    'Participantes confirmados.': 'Participants confirmed.',
    '¿Cerrar convocatoria?': 'Close this mission?',
    '¿Reabrir convocatoria?': 'Reopen this mission?',
    '¿Cancelar definitivamente?': 'Cancel permanently?',
    '¿Finalizar misión?': 'Complete this mission?',
    'No llegarán nuevas candidaturas. Podrás revisar las recibidas y reabrir antes de la fecha de inicio.':
        'No new applications will be accepted. You can review existing ones and reopen before the start date.',
    'La comunidad podrá volver a presentar candidaturas.':
        'The community will be able to apply again.',
    'La misión quedará en el historial y no podrá reabrirse.':
        'The mission will remain in your history and cannot be reopened.',
    'La misión quedará en el historial y ya no se podrá modificar.':
        'The mission will remain in your history and can no longer be edited.',
    'Misión actualizada.': 'Mission updated.',
    'Cerrar convocatoria': 'Close mission',
    'Reabrir convocatoria': 'Reopen mission',
    'Esta misión fue ocultada. Sus acciones de gestión están suspendidas.':
        'This mission was hidden. Management actions are suspended.',
    'Motivo de cancelación: {reason}': 'Cancellation reason: {reason}',
    'No seleccionadas': 'Not selected',
    'Esta misión ya no permite confirmar participantes.':
        'This mission no longer allows participants to be confirmed.',
    'Confirmar selección ({count})': 'Confirm selection ({count})',
    'No seleccionada': 'Not selected',
    'Esta candidatura anterior no registró disponibilidad.':
        'This earlier application did not record availability.',
    'Disponibilidad sin confirmar.': 'Availability not confirmed.',
    'Muestras de trabajo': 'Work samples',
    'Quitar finalista': 'Remove finalist',
    'Marcar finalista': 'Mark as finalist',
    'Finalista retirado.': 'Finalist removed.',
    'Candidatura marcada como finalista.': 'Application marked as finalist.',
    '¿No seleccionar esta candidatura?': 'Reject this application?',
    'El participante recibirá la respuesta.':
        'The applicant will receive the decision.',
    'Candidatura revisada.': 'Application reviewed.',
    'Algo nuevo está por llegar': 'Something new is on the way',
    'Estamos preparando una nueva forma de descubrir talento, experiencias y oportunidades en MAREA.':
        'We are preparing a new way to discover talent, experiences, and opportunities in MAREA.',
    'En desarrollo': 'In development',
    'Acepto los términos y he leído el aviso de privacidad.':
        'I accept the terms and have read the privacy notice.',
    'Eliminar mi cuenta': 'Delete my account',
    'Disponible para colaborar': 'Available for collaboration',
    'Contactar': 'Contact',
    'Horarios': 'Business hours',
    'Hora local del negocio': 'Local business time',
    'Cerrado': 'Closed',
    'Lunes': 'Monday',
    'Martes': 'Tuesday',
    'Miércoles': 'Wednesday',
    'Jueves': 'Thursday',
    'Viernes': 'Friday',
    'Sábado': 'Saturday',
    'Domingo': 'Sunday',
    'Tú decides cuándo irte.': 'You decide when to leave.',
    'Puedes eliminar tu cuenta de MAREA desde Configuración → Eliminar cuenta. Se borrarán tu acceso, perfil, preferencias e imágenes. Es una acción permanente.':
        'You can delete your MAREA account from Settings → Delete account. Your access, profile, preferences, and images will be deleted. This action is permanent.',
    'Ir a Configuración': 'Go to Settings',
    'Iniciar sesión para eliminar mi cuenta': 'Sign in to delete my account',
    'Solicitud de eliminación de cuenta MAREA':
        'MAREA account deletion request',
    'Solicitar ayuda: {email}': 'Request help: {email}',
    'Documento pendiente de publicación': 'Document pending publication',
    'MAREA todavía no ha publicado este documento. No es posible crear una cuenta hasta que estén disponibles los términos y el aviso de privacidad.':
        'MAREA has not published this document yet. You cannot create an account until the terms and privacy notice are available.',
    'Antes de continuar': 'Before continuing',
    'Conoce las condiciones de MAREA': 'Learn about MAREA terms',
    'La comunidad es para mayores de 18 años. Revisa los documentos vigentes antes de continuar. Si no deseas aceptarlos, puedes cerrar sesión o eliminar tu cuenta.':
        'The community is for people aged 18 and over. Review the current documents before continuing. If you do not want to accept them, you can sign out or delete your account.',
    'Gestionar o eliminar mi cuenta': 'Manage or delete my account',
    'Tengo 18 años o más.': 'I am 18 years old or older.',
    'No puedo acceder a mi cuenta': 'I cannot access my account',
    'Escríbenos a {email}': 'Write to us at {email}',
    'Versión {version} · México': 'Version {version} · Mexico',
    'Volver a cargar': 'Reload',
    'Aceptar y continuar': 'Accept and continue',
    'Tu ubicación': 'Your location',
    'No pudimos cargar los recorridos de esta zona.':
        'We could not load tours in this area.',
    'Locales 360°': 'Venues 360°',
    'Actividad de tu comunidad': 'Your community activity',
    'Mensajes de MAREA 👀': 'Messages from MAREA 👀',
    'No pudimos preparar tu portada. Prueba otra fotografía.':
        'We could not prepare your cover photo. Try a different image.',
    'Alejar foto': 'Zoom out',
    'Restablecer encuadre': 'Reset crop',
    'Acercar foto': 'Zoom in',
    'Preparando foto…': 'Preparing photo…',
    '¿Descartar tus cambios?': 'Discard your changes?',
    'Los cambios todavía no se han guardado.':
        'Your changes have not been saved yet.',
    'Galería': 'Gallery',
    'No pudimos abrir tus fotos. Inténtalo nuevamente.':
        'We could not open your photos. Please try again.',
    'No pudimos guardar las imágenes. Tus cambios siguen aquí para reintentar.':
        'We could not save the images. Your changes are still here if you want to try again.',
    'Cambiar foto de perfil': 'Change profile photo',
    'Cambiar foto de portada': 'Change cover photo',
    'Elige una foto o usa un estilo predeterminado':
        'Choose a photo or use a preset style',
    'Colores independientes de tu fotografía':
        'Wave colors are independent of your photo',
    'Quitar foto': 'Remove photo',
    'Ubicación del negocio': 'Business location',
    'Sin ubicación': 'No location',
    'Horarios semanales · hora local del negocio':
        'Weekly hours · local business time',
    'Editar perfil': 'Edit profile',
    'Crear': 'Create',
    'No pudimos cargar tu perfil.': 'We could not load your profile.',
    '{action} ›': '{action} ›',
    'Elegir foto': 'Choose photo',
    'Descartar foto': 'Discard photo',
    '¿Qué buscas?': 'What are you looking for?',
    'Ver misiones del perfil': 'View profile missions',
    'Ver publicaciones': 'View posts',
    'Más colores': 'More colors',
    'Más oscuro o más claro': 'Darker or lighter',
    'Usar color': 'Use color',
    'Restablecer colores predeterminados': 'Reset to default colors',
    'Aplicar colores': 'Apply colors',
    'Crear historia': 'Create story',
    'Comparte una foto o texto durante 24 horas.':
        'Share a photo or text for 24 hours.',
    'Convoca a tu comunidad para hacer algo juntos.':
        'Invite your community to do something together.',
    'Publicar en Inicio': 'Post in Home',
    'Mover fotografía antes': 'Move photo earlier',
    'Mover fotografía después': 'Move photo later',
    'Agregar fotografía': 'Add photo',
    'Tu apartado': 'Your section',
    'Este tipo de perfil no tiene un apartado profesional.':
        'This profile type does not have a professional section.',
    'Guardando…': 'Saving…',
    '¿Eliminar esta ficha?': 'Delete this listing?',
    '{itemKind} · {category}': '{itemKind} · {category}',
    'Ver proyecto': 'View project',
    'Reportar ficha': 'Report listing',
    'Motivo del reporte': 'Reason of the report',
    'Reportar': 'Report',
    'No disponible: solo aparece en tu administración.':
        'Unavailable: only visible in your management area.',
    'Eliminar ficha': 'Delete listing',
    'Esta ficha ya no está disponible.': 'This listing is no longer available.',
    'Editar ficha': 'Edit listing',
    'Volver a cargar fotografía': 'Reload photo',
    'No disponible': 'Unavailable',
    'Oculto por moderación': 'Hidden by moderation',
    'Cargar más fichas': 'Load more listings',
    'Capturar posición 360°': 'Capture 360° position',
    'Ya alineé la primera toma': 'I aligned the first capture',
    'Repetir última toma': 'Repeat last capture',
    'Importar panorama esférico': 'Import a spherical panorama',
    'Reintentar consultar RA': 'Retry AR check',
    'Volver a comprobar compatibilidad': 'Check compatibility again',
    'Preparando cámara…': 'Preparing camera…',
    'Volver a cámara': 'Back to camera',
    'Este organizador no tiene Misiones activas por ahora.':
        'This organizer has no active missions right now.',
    'Referencia no disponible': 'Reference not available',
    'Volver a la lista': 'Back to the list',
    'Guardar prueba de reconocimiento': 'Save recognition test',
    'Explorar el local en 360°': 'Explore the venue in 360°',
    'Confirmar ubicación en el mapa': 'Confirm location on the map',
    'Añadir evidencia privada del local': 'Add private venue evidence',
    'Importar 360°': 'Import 360°',
    'Agregar posición': 'Add position',
    'Marcar en 360°': 'Mark in 360°',
    'Conectar otra posición': 'Connect another position',
    'Paradas con cámara': 'Camera stops',
    'Tus recorridos': 'Your tours',
    'Crear recorrido': 'Create tour',
    'Editar borrador': 'Edit draft',
    'Ver recorrido': 'View tour',
    'Evidencia no disponible': 'Evidence not available',
    'Ver versión enviada': 'View submitted version',
    'Recorrido 360°': 'Tour 360°',
    'No pudimos abrir el panorama.': 'We could not open the panorama.',
    'Colocar aquí': 'Place here',
    'Volver a cargar imagen': 'Reload image',
    'Las misiones aún no están disponibles.': 'Missions are not available yet.',
    'No pudimos cargar las misiones. Inténtalo de nuevo.':
        'We could not load missions. Please try again.',
    'No pudimos cargar esta misión.': 'We could not load this mission.',
    'Buscar nombre o usuario': 'Search by name or username',
    'Buscar fichas por título': 'Search listings by title',
    'Buscar por título': 'Search by title',
    'Todos los tipos': 'All types',
    'Publicaciones guardadas': 'Saved posts',
    'Fichas guardadas': 'Saved listings',
    'Se muestran los primeros {count} perfiles. Usa la búsqueda para encontrar a alguien.':
        'Showing the first {count} profiles. Use search to find someone.',
    'Este perfil ya no está disponible.':
        'This profile is no longer available.',
    'Seleccionar fecha': 'Select date',
    'Seleccionar hora': 'Select time',
    'Historial': 'History',
    'Candidatura': 'Application',
    'Sin requisitos adicionales.': 'No additional requirements.',
    'Sin condiciones adicionales.': 'No additional conditions.',
    'Ubicación aproximada en el mapa': 'Approximate location on the map',
    'Punto del mapa incluido': 'Map point included',
    'Fecha y hora por definir': 'Date and time to be determined',
    'Las candidaturas son privadas. Podrás revisarlas y elegir a las personas participantes desde la gestión de tu misión.':
        'Applications are private. You can review them and choose participants from your mission management page.',
    'Escribe entre 1 y 1.000 caracteres.':
        'Write between 1 and 1,000 characters.',
    'Comentario retirado.': 'Comment removed.',
    'Cuenta no disponible': 'Account unavailable',
    'Retirar comentario': 'Remove comment',
    'Me interesa colaborar': 'I am interested in collaborating',
    'Interés enviado': 'Interest sent',
    'El autor recibió tu mensaje. Solo ustedes dos pueden consultarlo.':
        'The author received your message. Only the two of you can view it.',
    'Listo': 'Done',
    'Cuéntale al autor cómo te gustaría participar. Este mensaje es privado y no inicia un chat.':
        'Tell the author how you would like to participate. This message is private and does not start a chat.',
    'Enlace copiado.': 'Link copied.',
    'Compartir enlace': 'Share link',
    'Copiar enlace': 'Copy link',
    'Puedes copiar el enlace y enviarlo desde otra aplicación.':
        'You can copy the link and send it from another app.',
    'Reportes de la comunidad': 'Community reports',
    'Revisa el contenido antes de ocultarlo. Los reportes revisados se conservan para poder restaurarlo.':
        'Review the content before hiding it. Reviewed reports are kept so the content can be restored.',
    'Espacios y recorridos': 'Spaces and tours',
    'Acreditar responsables y revisar versiones enviadas.':
        'Verify owners and review submitted versions.',
    'No hay reportes para revisar.': 'There are no reports to review.',
    'Pendiente de revisión': 'Pending review',
    'Revisado': 'Reviewed',
    'El contenido fue eliminado.': 'The content was deleted.',
    'Precio: {price} MXN': 'Price: {price} MXN',
    'Imagen de la publicación reportada': 'Reported post image',
    'No pudimos cargar la fotografía reportada.':
        'We could not load the reported photo.',
    'Categoría: {category}': 'Category: {category}',
    'Fecha: {date}': 'Date: {date}',
    'Cupo: {capacity} · {status}': 'Capacity: {capacity} · {status}',
    'Dirigida a: {target}': 'Targeted at: {target}',
    'Oculto para la comunidad': 'Hidden from the community',
    'Visible para la comunidad': 'Visible to the community',
    'Contenido restaurado.': 'Content restored.',
    'Contenido ocultado.': 'Content hidden.',
    'Restaurar contenido': 'Restore content',
    'Ocultar contenido': 'Hide content',
    'reaccionó a': 'reacted to',
    'comentó en': 'commented on',
    'quiere colaborar en': 'is interested in collaborating on',
    'envió una candidatura a': 'applied to',
    'aceptó tu candidatura en': 'accepted your application to',
    'revisó tu candidatura sin seleccionarla en':
        'reviewed your application and did not select you for',
    'retiró su candidatura de': 'withdrew their application from',
    'cerró la convocatoria de': 'closed the mission',
    'reabrió la convocatoria de': 'reopened the mission',
    'canceló': 'cancelled',
    'finalizó': 'completed',
    'Todo': 'All',
    'Sin leer': 'Unread',
    '{actor} te envió una solicitud de mensaje.':
        '{actor} sent you a message request.',
    '{actor} rechazó tu solicitud de mensaje.':
        '{actor} declined your message request.',
    '{actor} {verb} «{title}».': '{actor} {verb} “{title}”.',
    'Una persona': 'Someone',
    'Estás al día. No hay notificaciones sin leer.':
        'You are all caught up. There are no unread notifications.',
    'Aquí aparecerán las novedades de tu comunidad y tus misiones.':
        'Updates from your community and missions will appear here.',
    'Las publicaciones no están disponibles. Vuelve a iniciar la aplicación.':
        'Posts are not available. Please restart the app.',
    'Tus guardados': 'Your saved posts',
    'Publicaciones recientes': 'Recent posts',
    'Actualizar publicaciones': 'Refresh posts',
    'Guarda las publicaciones que te interesen para encontrarlas aquí.':
        'Save posts you are interested in to find them here.',
    'Este espacio está listo para sus primeras publicaciones.':
        'This space is ready for its first posts.',
    'Todavía no hay publicaciones con estos filtros. Comparte la primera idea.':
        'There are no posts with these filters yet. Share the first idea.',
    'Publicación guardada.': 'Post saved.',
    'Publicación retirada de Guardados.': 'Post removed from Saved.',
    'Publicación eliminada.': 'Post deleted.',
    'Reporte enviado a moderación.': 'Report sent to moderation.',
    'Quitar guardado': 'Remove saved item',
    'Ver menos': 'See less',
    'Perfil de MAREA': 'MAREA profile',
    '{date} · {kind}': '{date} · {kind}',
    '{date} · {kind} · {category}': '{date} · {kind} · {category}',
    'Ver mapa': 'View map',
    'La fotografía no está disponible.': 'The photo is unavailable.',
    'Esta publicación no está disponible para editar.':
        'This post is not available for editing.',
    'No pudimos conectar con las publicaciones. Vuelve a intentarlo.':
        'We could not connect to posts. Please try again.',
    'Tu publicación ya está en MAREA.': 'Your post is now on MAREA.',
    'Publicación actualizada.': 'Post updated.',
    'Carga tu perfil para publicar.': 'Load your profile to post.',
    'Comparte con MAREA': 'Share with MAREA',
    'Editar publicación': 'Edit post',
    'Invitar a colaborar': 'Invite people to collaborate',
    'Recibe mensajes privados de interés para esta publicación.':
        'Receive private messages from people interested in this post.',
    'No encontramos la publicación.': 'We could not find the post.',
    'Publicas como {profile}': 'Posting as {profile}',
    'Escribe al menos 3 caracteres.': 'Enter at least 3 characters.',
    'Cuéntanos sobre tu proyecto': 'Tell us about your project',
    'Describe tu producto': 'Describe your product',
    '¿Qué servicio ofreces?': 'What service do you offer?',
    'Describe tu espacio': 'Describe your space',
    'Detalles del evento': 'Event details',
    '¿Qué quieres compartir?': 'What would you like to share?',
    'Agrega una descripción.': 'Add a description.',
    'Ubicación del espacio o evento': 'Location of the space or event',
    'Ubicación (opcional)': 'Location (optional)',
    'Indica dónde se encuentra.': 'Enter its location.',
    'Precio en MXN (opcional)': 'Price in MXN (optional)',
    'Escribe un precio entre 0 y 99,999,999.':
        'Enter a price between 0 and 99,999,999.',
    'Tu publicación será visible para las personas con cuenta en MAREA.':
        'Your post will be visible to people with a MAREA account.',
    'Este interés ya no está disponible.':
        'This interest is no longer available.',
    'Mensaje privado entre el solicitante y el autor.':
        'Private message between the applicant and the author.',
    'Escribe al menos 3 caracteres para buscar.':
        'Enter at least 3 characters to search.',
    'No encontramos lugares con ese nombre.':
        'We could not find any places with that name.',
    'No pudimos buscar ese lugar. Puedes elegir un punto en el mapa o escribir la dirección al cerrar.':
        'We could not search for that place. You can choose a point on the map or enter the address when closing.',
    'Ubicación seleccionada ({latitude}, {longitude})':
        'Location selected ({latitude}, {longitude})',
    'No pudimos consultar la dirección. Puedes usar el punto o reintentar.':
        'We could not look up the address. You can use the point or try again.',
    'Activa el servicio de ubicación de tu dispositivo e inténtalo de nuevo.':
        'Turn on your device location service and try again.',
    'Permite el acceso a tu ubicación en el navegador o en Ajustes del dispositivo.':
        'Allow location access in your browser or device settings.',
    'En Web, la ubicación requiere HTTPS o abrir la app desde localhost.':
        'On the web, location requires HTTPS or opening the app from localhost.',
    'No pudimos obtener tu ubicación. Revisa el permiso y el GPS, o elige el punto manualmente.':
        'We could not get your location. Check the permission and GPS, or choose the point manually.',
    'Elegir ubicación': 'Choose location',
    'Buscar lugar o dirección': 'Search for a place or address',
    'Toca el mapa para elegir un punto': 'Tap the map to choose a point',
    'Zona aproximada': 'Approximate area',
    'Comunidad': 'Community',
    'Comparte una idea, una pregunta o una novedad.':
        'Share an idea, a question, or an update.',
    'Proyecto': 'Project',
    'Muestra tu proceso creativo y tus proyectos.':
        'Show your creative process and projects.',
    'Producto': 'Product',
    'Presenta un producto de tu emprendimiento.':
        'Showcase a product from your business.',
    'Servicio': 'Service',
    'Comparte los servicios que ofreces.': 'Share the services you offer.',
    'Espacio': 'Space',
    'Da a conocer tu espacio y lo que ofrece.':
        'Introduce your space and what it offers.',
    'Evento': 'Event',
    'Invita a la comunidad a tu próximo evento.':
        'Invite the community to your next event.',
    'Descubre personas, guarda lo que te inspira y participa en misiones.':
        'Discover people, save what inspires you, and join missions.',
    'Comparte tu portafolio y encuentra personas para crear contigo.':
        'Share your portfolio and find people to create with.',
    'Presenta tus productos y servicios y encuentra nuevas colaboraciones.':
        'Showcase your products and services and find new collaborations.',
    'Presenta tus servicios, comparte tu espacio y organiza eventos.':
        'Showcase your services, share your space, and host events.',
    'Este tipo de publicación no está disponible para tu perfil.':
        'This post type is not available for your profile.',
    'Indica la ubicación del espacio o evento.':
        'Enter the location of the space or event.',
    'Solo los productos y servicios pueden incluir un precio.':
        'Only products and services can include a price.',
    'La ubicación debe tener hasta 180 caracteres.':
        'The location must be 180 characters or fewer.',
    'La ubicación seleccionada no es válida.':
        'The selected location is invalid.',
    'Escribe un precio entre 0 y 99999999.':
        'Enter a price between 0 and 99,999,999.',
    'El título debe tener entre 3 y 100 caracteres.':
        'The title must be between 3 and 100 characters.',
    'La descripción debe tener entre 1 y 3000 caracteres.':
        'The description must be between 1 and 3,000 characters.',
    'Elige una categoría válida.': 'Choose a valid category.',
    'Usa el botón de ubicación para descubrir misiones cerca de ti.':
        'Use the location button to discover missions near you.',
    'Puedes seguir explorando. Permite la ubicación cuando quieras ver qué hay cerca de ti.':
        'You can keep exploring. Allow location access whenever you want to see what is nearby.',
    'Activa el servicio de ubicación de tu dispositivo o sigue explorando el mapa.':
        'Turn on your device location service or keep exploring the map.',
    'Tu ubicación tardó demasiado. Inténtalo de nuevo o explora el mapa.':
        'Your location took too long to find. Try again or explore the map.',
    'Muestra tu local en 360°': 'Show your venue in 360°',
    'Captura desde varias posiciones y conecta sus panoramas. Añade AR a los puntos que quieras reconocer en el local.':
        'Capture from multiple positions and connect the panoramas. Add AR to the points you want to recognize in the venue.',
    'La versión pública se conserva mientras editas.':
        'The public version remains available while you edit.',
    'Reanudar': 'Resume',
    'Pausar': 'Pause',
    'Todavía no tienes recorridos.': 'You do not have any tours yet.',
    'La autorización del espacio y la del contenido se revisan por separado.':
        'Venue and content permissions are reviewed separately.',
    'Solicitud': 'Request',
    'Permiso del autor': 'Author permission',
    'Responsabilidad del espacio': 'Venue responsibility',
    'Contenido vinculado': 'Linked content',
    'Retirar permiso y pausar recorrido': 'Revoke permission and pause tour',
    'Retirar permiso del contenido': 'Revoke content permission',
    'Aprobar': 'Approve',
    'Pedir cambios': 'Request changes',
    'Qué debe corregirse': 'What needs to be corrected',
    'Publicado': 'Published',
    'Aprobado': 'Approved',
    'Pausado': 'Paused',
    'En revisión': 'In review',
    'Requiere cambios': 'Changes requested',
    'Finalizado': 'Completed',
    'Rechazado': 'Rejected',
    'Solicitud sustituida': 'Superseded request',
    'Revocado': 'Revoked',
    'Explorar el local': 'Explore the venue',
    '{kind} · {status}': '{kind} · {status}',
    'El permiso del espacio fue retirado. Solicita una nueva revisión para volver a publicar.':
        'Venue permission was revoked. Request a new review before publishing again.',
    'Esta captura fue sustituida por otra más reciente. Vuelve a la posición para continuar con la captura actual.':
        'This capture was replaced by a newer one. Return to the position to continue with the current capture.',
    'Postulación retirada.': 'Application withdrawn.',
    'Filtrar misiones': 'Filter missions',
    'Perfil buscado': 'Profile sought',
    'Cualquier perfil': 'Any profile',
    'Eliminar borrador': 'Delete draft',
    'Borrador eliminado.': 'Draft deleted.',
    'Misiones': 'Missions',
    'Explorar': 'Explore',
    'Mis misiones': 'My missions',
    'Mis candidaturas': 'My applications',
    'Para mi perfil': 'For my profile',
    'Guardadas': 'Saved',
    'Para {profile} y convocatorias para todos.':
        'For {profile} and open to all profiles.',
    'Buscar misiones': 'Search missions',
    'Convocatorias activas': 'Active missions',
    'Borradores': 'Drafts',
    'Postulación {status} · {missionStatus}':
        'Application {status} · {missionStatus}',
    'Borrador · {date}': 'Draft · {date}',
    'Tus ideas guardadas aparecerán aquí.':
        'Your saved ideas will appear here.',
    'Aún no has creado misiones. Invita a la comunidad a colaborar.':
        'You have not created any missions yet. Invite the community to collaborate.',
    'Tus postulaciones y sus respuestas aparecerán aquí.':
        'Your applications and their responses will appear here.',
    'No tienes postulaciones en este estado.':
        'You have no applications in this status.',
    'Aún no has guardado misiones.': 'You have not saved any missions yet.',
    'No hay misiones abiertas en esta página. Vuelve pronto o crea la primera.':
        'There are no open missions on this page. Come back soon or create the first one.',
    'Borrador': 'Draft',
    'Misión no disponible': 'Mission unavailable',
    'Postulación {status}': 'Application {status}',
    'Recibimos tu reporte.': 'We received your report.',
    'Misión guardada.': 'Mission saved.',
    'Misión retirada de guardadas.': 'Mission removed from saved.',
    'Inicia sesión para postularte.': 'Sign in to apply.',
    'Quitar de guardadas': 'Remove from saved',
    'Guardar misión': 'Save mission',
    'Organizador': 'Organizer',
    'Ver organizador': 'View organizer',
    '@{username} · {profile}': '@{username} · {profile}',
    'Fecha y hora': 'Date and time',
    'Participantes': 'Participants',
    '{available} de {capacity} lugares disponibles':
        '{available} of {capacity} places available',
    'Perfil solicitado': 'Requested profile',
    'La misión': 'The mission',
    'Tu postulación: {status}.': 'Your application: {status}.',
    'Candidatura {status}': 'Application {status}',
    'Quiero participar': 'I want to participate',
    'Participación no disponible': 'Participation unavailable',
    'Aceptada': 'Accepted',
    'Retirada': 'Withdrawn',
    'Pendiente': 'Pending',
    'Esta es una misión que tú organizas.':
        'This is a mission that you organize.',
    'Esta misión está oculta por moderación.':
        'This mission is hidden by moderation.',
    'El organizador canceló esta misión.':
        'The organizer cancelled this mission.',
    'Esta misión ya finalizó.': 'This mission has already ended.',
    'El organizador cerró la convocatoria.':
        'The organizer closed this mission.',
    'La fecha de esta convocatoria ya pasó.':
        'The date for this mission has passed.',
    'Esta misión ya alcanzó su cupo.': 'This mission is already full.',
    'Esta misión busca {target}. Tu perfil es {profile}.':
        'This mission is seeking {target}. Your profile is {profile}.',
    'Buscar': 'Search',
    'Personas': 'People',
    'Fichas': 'Listings',
    'Quitar': 'Remove',
    'Compensación': 'Compensation',
    'Requisitos': 'Requirements',
    'Condiciones': 'Terms',
    'Participante': 'Participant',
    'Candidaturas': 'Applications',
    'Confirmadas': 'Confirmed',
    'Disponibles': 'Available',
    'Confirmando…': 'Confirming…',
    'Disponible': 'Available',
    'Comentarios': 'Comments',
    'Descartar': 'Discard',
    'Título': 'Title',
    'Publicar': 'Publish',
    'Exacta': 'Exact',
    'Aproximada': 'Approximate',
    'Deshacer': 'Undo',
    'Compartir': 'Share',
    'Acciones': 'Actions',
    'Más': 'More',
    'Bio': 'Bio',
    'Contacto': 'Contact',
    'Opcional': 'Optional',
    'Hora local · vacío para omitir': 'Local time · leave blank to omit',
    'cerrado': 'closed',
    '09:00-18:00 o cerrado': '09:00-18:00 or closed',
    'Usa 09:00-18:00. Escribe cerrado para un día sin atención; vacío si no quieres mostrarlo.':
        'Use 09:00-18:00. Enter closed for a day with no opening hours; leave blank to hide it.',
    'Tus intereses': 'Your interests',
    'Tu imagen': 'Your photo',
    'Tu marca': 'Your brand',
    'Dónde y cuándo': 'Where and when',
    'Tu primera ficha': 'Your first listing',
    'Tu trabajo': 'Your work',
    'Tu contacto': 'Your contact',
    'Crear mi primera obra': 'Create my first project',
    'Crear mi primera ficha': 'Create my first listing',
    'Crear mi primer servicio': 'Create my first service',
    'Crear perfil': 'Create profile',
    'Terminar': 'Finish',
    'Guardar y continuar': 'Save and continue',
    'Ahora no': 'Not now',
    'Marea': 'MAREA',
    'Lavanda': 'Lavender',
    'Durazno': 'Peach',
    'Menta': 'Mint',
    'Añadir ubicación': 'Add location',
    'Elegido al crear tu perfil.': 'Chosen when you created your profile.',
    'Enlace de contacto': 'Contact link',
    'No pudimos cargar tu perfil. Volver a intentarlo.':
        'We could not load your profile. Try again.',
    'Estilos de MAREA': 'MAREA styles',
    'https://wa.me/... o tu página de contacto':
        'https://wa.me/... or your contact page',
    '¿Qué haces y qué te mueve?': 'What do you do, and what drives you?',
    'Identidad': 'Identity',
    'Nombre completo': 'Full name',
    'Nombre de usuario': 'Username',
    'Opciones de imágenes': 'Image options',
    'Personalizar olitas': 'Customize waves',
    'Profesional': 'Professional',
    'Quitar portada': 'Remove cover',
    'Tipo de perfil': 'Profile type',
    'Tipo de perfil: {type}': 'Profile type: {type}',
    'Persona': 'Person',
    'Emprendimiento': 'Entrepreneurship',
    'Descubre y conecta': 'Discover and connect',
    'Comparte tu trabajo': 'Share your work',
    'Presenta tus productos y servicios': 'Showcase your products and services',
    'Ofrece servicios, espacios y eventos':
        'Offer services, spaces, and events',
    'Tu nombre': 'Your name',
    'Nombre artístico': 'Artist name',
    'Nombre del emprendimiento': 'Business name',
    'Nombre del negocio': 'Business name',
    'Usa un horario como 09:00-18:00, con cierre después de apertura.':
        'Enter hours such as 09:00-18:00, with closing time after opening time.',
    'Día de la semana inválido.': 'Invalid day of the week.',
    'Escribe tu nombre.': 'Enter your name.',
    'Usa un nombre de máximo 80 caracteres.':
        'Use a name with no more than 80 characters.',
    'Elige un nombre de usuario.': 'Choose a username.',
    'Usa al menos 3 caracteres.': 'Use at least 3 characters.',
    'Usa máximo 24 caracteres.': 'Use no more than 24 characters.',
    'Usa solo letras, números, punto o guion bajo.':
        'Use only letters, numbers, periods, or underscores.',
    'Escribe tu correo.': 'Enter your email.',
    'Escribe un correo válido.': 'Enter a valid email address.',
    'Escribe una contraseña.': 'Enter a password.',
    'Usa al menos 8 caracteres.': 'Use at least 8 characters.',
    'Confirma tu contraseña.': 'Confirm your password.',
    'Las contraseñas no coinciden.': 'Passwords do not match.',
    'Usa máximo 160 caracteres.': 'Use no more than 160 characters.',
    'Ajustar foto de portada': 'Adjust cover photo',
    'Arrastra la foto para encuadrarla. Pellizca o usa los botones para acercarla.':
        'Drag the photo to frame it. Pinch or use the buttons to zoom in.',
    'Usar foto': 'Use photo',
    'No pudimos abrir esta imagen. Prueba con otra fotografía.':
        'We could not open this image. Try another photo.',
    'Elegir un color más claro o más oscuro':
        'Choose a lighter or darker color',
    'Elegir cualquier color': 'Choose any color',
    'Toca o desliza para elegir': 'Tap or drag to choose',
    'Color de la ola superior': 'Top wave color',
    'Color de la ola inferior': 'Bottom wave color',
    'Elegir {color}': 'Choose {color}',
    'Toca un color': 'Tap a color',
    'Combinaciones': 'Combinations',
    'Turquesa y verde agua': 'Turquoise and aqua',
    'Rosa pastel y lila': 'Pastel pink and lilac',
    'Rojo oscuro y vino': 'Dark red and burgundy',
    'Azul cielo y azul marino': 'Sky blue and navy',
    'Morado y lavanda': 'Purple and lavender',
    'Verde menta y esmeralda': 'Mint and emerald',
    'Naranja y amarillo': 'Orange and yellow',
    'Coral y durazno': 'Coral and peach',
    'Beige y café': 'Beige and brown',
    'Gris y negro': 'Gray and black',
    'Fucsia y rosa': 'Fuchsia and pink',
    'Azul petróleo y turquesa': 'Petrol blue and turquoise',
    'Verde oliva y beige': 'Olive green and beige',
    'Azul pastel y blanco': 'Pastel blue and white',
    'Rosa palo y crema': 'Dusty pink and cream',
    'Morado oscuro y fucsia': 'Dark purple and fuchsia',
    'Negro y dorado': 'Black and gold',
    'Verde bosque y menta': 'Forest green and mint',
    'Terracota y arena': 'Terracotta and sand',
    'Amarillo pastel y naranja': 'Pastel yellow and orange',
    'Después de confirmar, vuelve a MAREA e inicia sesión.':
        'After confirming, return to MAREA and sign in.',
    'Te enviamos un enlace para confirmar tu cuenta.':
        'We sent you a link to confirm your account.',
    'Revisa tu correo': 'Check your email',
    'Enviar código': 'Send code',
    'Escribe el código del correo (6 a 10 dígitos).':
        'Enter the code from the email (6 to 10 digits).',
    'Escribe el código que recibiste.': 'Enter the code you received.',
    'Escribe el correo de tu cuenta.': 'Enter your account email.',
    'Recibirás un código si hay una cuenta con ese correo.':
        'If an account exists for that email, you will receive a code.',
    'Recupera tu acceso': 'Recover your access',
    'Reenviar código': 'Resend code',
    'Usa el correo con el que te registraste.':
        'Use the email address you registered with.',
    'Verifica el código': 'Verify the code',
    'Verifica tu correo': 'Verify your email',
    'Verificar código': 'Verify code',
    'Confirmar mi correo': 'Confirm my email',
    'Entrar': 'Sign in',
    'Mostrar contraseña': 'Show password',
    'Ocultar contraseña': 'Hide password',
    'Crea tu acceso': 'Create your account',
    'Elige un perfil.': 'Choose a profile.',
    'Mínimo 8 caracteres': 'At least 8 characters',
    'El registro no está disponible. Intenta de nuevo.':
        'Sign-up is unavailable. Try again.',
    'Tu perfil': 'Your profile',
    'Usuario': 'Username',
    'Este usuario ya está ocupado.': 'This username is already taken.',
    'Cambiar contraseña': 'Change password',
    'Cambiar correo': 'Change email',
    'El cambio necesita confirmación en tus correos. Hasta completarla seguirás usando el actual.':
        'The change must be confirmed from your email accounts. You will keep using the current one until it is confirmed.',
    'Escribe tu contraseña actual.': 'Enter your current password.',
    'Nueva contraseña': 'New password',
    'Nuevo correo': 'New email',
    'Solicitar cambio de correo': 'Request email change',
    'Solo si se solicita.': 'Only if requested.',
    'Usa una contraseña única de al menos 8 caracteres.':
        'Use a unique password with at least 8 characters.',
    'Aún no hay mensajes.': 'There are no messages yet.',
    'Bloquear usuario': 'Block user',
    'Chat': 'Chat',
    'Escribe un mensaje': 'Write a message',
    'Esta persona': 'This person',
    'Esta persona quiere iniciar una conversación contigo.':
        'This person wants to start a conversation with you.',
    'Inicia la conversación.': 'Start the conversation.',
    'Rechazar': 'Decline',
    'Revisar solicitud': 'Review request',
    'Esta solicitud de chat fue rechazada.': 'This chat request was declined.',
    'Solicitud enviada': 'Request sent',
    'Solicitud de mensaje': 'Message request',
    'Se retirará de tu perfil y de los guardados de otras personas.':
        'It will be removed from your profile and from other people’s saved items.',
    'Para tu perfil. Publica o guarda un borrador.':
        'For your profile. Publish it or save it as a draft.',
    'Muestra tu local y añade puntos con AR.':
        'Show your venue and add AR points.',
    'Comparte una idea, una novedad o lo que estás creando.':
        'Share an idea, an update, or what you are creating.',
    'Pon tu idea en movimiento': 'Put your idea in motion',
    'Los borradores y las fichas archivadas solo son visibles para ti.':
        'Drafts and archived listings are only visible to you.',
    'Descripción': 'Description',
    'Enlace del proyecto (opcional)': 'Project link (optional)',
    'No pudimos cargar esta ficha. Puedes reintentar.':
        'We could not load this listing. You can try again.',
    'Agrega una descripción de hasta 3000 caracteres.':
        'Add a description of up to 3,000 characters.',
    'Usa un enlace completo y seguro, por ejemplo https://tusitio.com.':
        'Use a complete, secure link, such as https://yoursite.com.',
    'El enlace de proyecto solo está disponible para obras.':
        'The project link is only available for projects.',
    'Este apartado no está disponible para tu tipo de perfil.':
        'This section is not available for your profile type.',
    'Agrega al menos una fotografía para publicar.':
        'Add at least one photo to publish.',
    'Elige hasta seis fotografías distintas.':
        'Choose up to six different photos.',
    'Usa un precio válido en MXN para productos o servicios.':
        'Enter a valid price in MXN for products or services.',
    'Escribe un precio válido en MXN.': 'Enter a valid price in MXN.',
    'Escribe un título de 3 a 100 caracteres.':
        'Enter a title between 3 and 100 characters.',
    'Estado de la ficha': 'Listing status',
    'Ficha guardada.': 'Listing saved.',
    'Ficha no disponible.': 'Listing unavailable.',
    'Las fichas no disponibles solo aparecen en tu administración.':
        'Unavailable listings only appear in your management area.',
    'Guardar ficha': 'Save listing',
    'Tu sesión cambió. Vuelve a entrar antes de guardar.':
        'Your session changed. Sign in again before saving.',
    'Sin precio se mostrará “Consultar precio”.':
        'Without a price, “Contact for price” will be shown.',
    'Archivar': 'Archive',
    'Consultar precio': 'Contact for price',
    'Ficha': 'Listing',
    'Oculta por moderación. Editarla no cambia ese estado.':
        'Hidden by moderation. Editing it will not change that status.',
    'Quitar de guardados': 'Remove from saved',
    'Reporte enviado.': 'Report submitted.',
    'Volver a borrador': 'Move back to draft',
    'AR no está disponible en este dispositivo. Puedes consultar las paradas y explorar el panorama.':
        'AR is unavailable on this device. You can browse the stops and explore the panorama.',
    'Abrir cámara guiada': 'Open guided camera',
    'Abrir vista previa privada': 'Open private preview',
    'Aceptar toma': 'Accept capture',
    'Agrega otra posición para conectarla.':
        'Add another position to connect it.',
    'Agrega una posición 360°': 'Add a 360° position',
    'Agregar punto': 'Add point',
    'Agregar zona': 'Add zone',
    'Ajusta ligeramente el encuadre hasta alinear la cámara.':
        'Slightly adjust the framing until the camera is aligned.',
    'Ancho físico en centímetros': 'Physical width in centimeters',
    'Armando tu panorama': 'Building your panorama',
    'Bajar parada': 'Move stop down',
    'Bajar zona': 'Move zone down',
    'Borrador recuperado del dispositivo. Conecta para sincronizar.':
        'Draft recovered from this device. Connect to sync.',
    'Borrador sincronizado': 'Draft synced',
    'Busca cada imagen con la fotografía de referencia y la indicación del local. La lista permite leer sin cámara.':
        'Find each image using its reference photo and the venue instructions. You can read the list without using the camera.',
    'Busca esta imagen en el lugar para descubrir su tarjeta.':
        'Find this image at the venue to reveal its card.',
    'Busca la imagen de referencia. Acércate despacio y evita reflejos.':
        'Find the reference image. Move closer slowly and avoid reflections.',
    'Buscando tu ubicación…': 'Finding your location…',
    'Buscar contenido': 'Search content',
    'Cancelar procesamiento': 'Cancel processing',
    'Captura completa': 'Capture complete',
    'Capturar / retomar': 'Capture / resume',
    'Compartir recorrido': 'Share tour',
    'Conectar con': 'Connect to',
    'Conexiones': 'Connections',
    'Conoce espacios en 360° y descubre sus paradas con cámara cuando estés ahí.':
        'Explore places in 360° and discover their stops with your camera when you are there.',
    'Conservar tomas': 'Keep captures',
    'Consultar más Misiones': 'See more missions',
    'Cómo llegar': 'Directions',
    'Definir vigencia temporal': 'Set a time period',
    'Descubrir cerca de mí': 'Discover nearby',
    'Distintivo imprimible': 'Printable marker',
    'Editar datos del perfil': 'Edit profile details',
    'Editar nombre': 'Edit name',
    'Editar texto': 'Edit text',
    'Editar zona': 'Edit zone',
    'El administrador revisará la responsabilidad del espacio. No incluyas documentos sensibles.':
        'An administrator will review authorization for the venue. Do not include sensitive documents.',
    'El fin debe ser posterior al inicio.':
        'The end time must be after the start time.',
    'El navegador no conserva este archivo al cerrar la pantalla. Elige el panorama de nuevo para iniciar otra subida.':
        'The browser will not keep this file after you close the screen. Select the panorama again to start another upload.',
    'El panorama supera 32 MB. Exporta un JPEG de menor tamaño.':
        'The panorama exceeds 32 MB. Export a smaller JPEG.',
    'El perfil ya no está disponible.': 'The profile is no longer available.',
    'El recorrido cambió desde tu última visita. Empieza la versión actual.':
        'The tour has changed since your last visit. Start the current version.',
    'El recorrido cambió. Estas paradas pertenecen a la versión actual.':
        'The tour has changed. These stops belong to the current version.',
    'El servidor no confirmó la fotografía completa.':
        'The server did not confirm the complete photo upload.',
    'Elige la imagen que vas a buscar': 'Choose the image to look for',
    'Elige una esfera equirectangular completa de proporción 2:1, con metadatos GPano.':
        'Choose a complete 2:1 equirectangular sphere with GPano metadata.',
    'Elige una posición inicial': 'Choose a starting position',
    'Empezar otra': 'Start another',
    'Empezar otra captura': 'Start another capture',
    'Empezar visita': 'Start visit',
    'Encuadra la imagen de esta parada': 'Frame this stop’s image',
    'Enviar a revisión': 'Submit for review',
    'Escanear esta imagen': 'Scan this image',
    'Escribe el título del recorrido y el nombre del local.':
        'Enter the tour title and venue name.',
    'Espacio: autorizado': 'Venue: authorized',
    'Espacio: pendiente de revisión': 'Venue: pending review',
    'Espera a que todos los panoramas estén listos':
        'Wait until all panoramas are ready',
    'Esperando orientación del teléfono': 'Waiting for phone orientation',
    'Esperando orientación del teléfono. Muévelo suavemente.':
        'Waiting for phone orientation. Move it gently.',
    'Esperando procesamiento': 'Waiting for processing',
    'Esta experiencia de RA ya no está disponible.':
        'This AR experience is no longer available.',
    'Esta lente requiere demasiadas tomas. Usa la cámara principal o importa una esfera completa.':
        'This lens requires too many captures. Use the main camera or import a complete sphere.',
    'Esta posición todavía no tiene un panorama listo.':
        'This position does not have a panorama ready yet.',
    'Este borrador no está disponible para sincronizar.':
        'This draft is not available to sync.',
    'Este borrador pertenece a otra cuenta.':
        'This draft belongs to another account.',
    'Este contenido todavía no está disponible.':
        'This content is not available yet.',
    'Este recorrido no está disponible. Puede estar pausado o haber finalizado.':
        'This tour is unavailable. It may be paused or completed.',
    'Este recorrido tiene una versión nueva. Al empezar se reiniciará el progreso anterior.':
        'A new version of this tour is available. Starting it will reset your previous progress.',
    'Explicación': 'Explanation',
    'Explicación del punto': 'Point description',
    'Explorar en RA': 'Explore in AR',
    'Explorar locales': 'Explore venues',
    'Fin de vigencia': 'End date',
    'Guardado en este dispositivo': 'Saved on this device',
    'Guardando la toma…': 'Saving capture…',
    'Hay cambios locales pendientes de sincronizar.':
        'There are local changes waiting to sync.',
    'Imagen para AR': 'Image for AR',
    'Imagen reconocida': 'Image recognized',
    'Imagen reconocida. Toca la tarjeta.': 'Image recognized. Tap the card.',
    'Inicio de vigencia': 'Start date',
    'La cámara de RA necesita un teléfono compatible con ARCore o ARKit. Puedes consultar el perfil.':
        'The AR camera requires a phone compatible with ARCore or ARKit. You can view the profile.',
    'La lente cambió desde la primera toma. Usa la misma cámara o empieza otra captura.':
        'The lens changed since the first capture. Use the same camera or start a new capture.',
    'La sesión cambió.': 'The session changed.',
    'La ubicación y dirección del local son aproximadas. Dentro, usa las fotografías e indicaciones de cada parada.':
        'The venue location and address are approximate. Once inside, use the photos and directions for each stop.',
    'La versión pública anterior seguirá disponible hasta aprobar estos cambios.':
        'The previous public version will remain available until these changes are approved.',
    'Las tomas aceptadas se guardan en este dispositivo. El procesamiento empieza después de confirmar la subida completa.':
        'Accepted captures are saved on this device. Processing starts after the full upload is confirmed.',
    'Las tomas actuales dejarán de formar parte de esta posición. La versión publicada se conserva.':
        'The current captures will be removed from this position. The published version will be kept.',
    'Leer detalle de la parada': 'Read stop details',
    'Lista de paradas': 'Stop list',
    'Local': 'Venue',
    'Los recorridos se crean desde un perfil profesional.':
        'Tours are created from a professional profile.',
    'Los vínculos pendientes no aparecerán en la versión pública.':
        'Pending links will not appear in the public version.',
    'Mantén el teléfono estable': 'Keep your phone steady',
    'Mantén el teléfono estable un momento.':
        'Keep your phone steady for a moment.',
    'Mantén esta pantalla abierta durante la subida. Si la cierras, tendrás que elegir el archivo de nuevo. El procesamiento empieza tras confirmar la subida completa.':
        'Keep this screen open while the file uploads. If you close it, you will need to select the file again. Processing starts after the full upload is confirmed.',
    'Mide la imagen instalada. Para el distintivo, imprime a este ancho y compruébalo con una regla.':
        'Measure the installed image. For the marker, print it at this width and check it with a ruler.',
    'Mira alrededor en 360° y cambia entre posiciones. Puedes conocer cada punto sin usar la cámara ni compartir tu ubicación.':
        'Look around in 360° and switch between positions. You can explore each point without using the camera or sharing your location.',
    'Misiones activas': 'Active missions',
    'Necesitamos nuevas fotografías': 'We need new photos',
    'Necesitas un perfil profesional.': 'You need a professional profile.',
    'No encontramos contenido disponible.': 'No content was found.',
    'No hay cámara trasera disponible. Puedes importar un panorama.':
        'No rear camera is available. You can import a panorama.',
    'No pudimos abrir la referencia de esta parada.':
        'We could not open this stop’s reference image.',
    'No pudimos confirmar que la prueba se guardó para esta referencia. Mantén la imagen encuadrada y vuelve a intentarlo.':
        'We could not confirm that the test was saved for this reference. Keep the image framed and try again.',
    'No pudimos conocer la lente. Puedes importar un panorama 360°.':
        'We could not identify the lens. You can import a 360° panorama.',
    'No pudimos descargar la imagen. Reintenta.':
        'We could not download the image. Try again.',
    'No pudimos guardar el progreso en este dispositivo. Mantén la pantalla abierta e inténtalo de nuevo.':
        'We could not save your progress on this device. Keep the screen open and try again.',
    'No pudimos guardar los últimos cambios en este dispositivo.':
        'We could not save the latest changes on this device.',
    'No pudimos iniciar la cámara AR. Puedes consultar la lista.':
        'We could not start the AR camera. You can view the list instead.',
    'No pudimos iniciar la cámara.': 'We could not start the camera.',
    'No pudimos leer la fotografía.': 'We could not read the photo.',
    'No pudimos leer la imagen.': 'We could not read the image.',
    'No pudimos leer la orientación. Puedes importar un panorama.':
        'We could not read the orientation. You can import a panorama.',
    'No pudimos mostrar la referencia.':
        'We could not display the reference image.',
    'No pudimos obtener los datos de la lente. Importa un panorama 360°.':
        'We could not get the lens information. Import a 360° panorama.',
    'No pudimos procesar el panorama': 'We could not process the panorama',
    'No pudimos recuperar el borrador.': 'We could not recover the draft.',
    'No se guardaron los cambios': 'Changes were not saved',
    'Nombre de zona': 'Zone name',
    'Nombre del local': 'Venue name',
    'Nombre del punto': 'Point name',
    'Obras, servicios, productos de emprendimientos, publicaciones o misiones.':
        'Projects, services, products, posts, or missions.',
    'Orden de zonas': 'Zone order',
    'Orden del recorrido presencial': 'In-person tour order',
    'Panorama listo': 'Panorama ready',
    'Panorama listo para revisar': 'Panorama ready for review',
    'Panorama procesado': 'Panorama processed',
    'Por ejemplo: Camina hacia el mural junto a la barra.':
        'For example: Walk toward the mural next to the bar.',
    'Por ejemplo: Entrada, Barra, Mural o Terraza.':
        'For example: Entrance, Bar, Mural, or Patio.',
    'Posición de captura': 'Capture position',
    'Posición inicial': 'Starting position',
    'Posición lista. Pulsa Aceptar toma.':
        'Position ready. Tap Accept capture.',
    'Preparar nueva captura': 'Prepare a new capture',
    'Probar AR en el local': 'Test AR at the venue',
    'Procesamiento cancelado': 'Processing cancelled',
    'Progreso guardado en este dispositivo. Se sincronizará al volver a abrir el recorrido.':
        'Progress saved on this device. It will sync when you reopen the tour.',
    'Publicar versión': 'Publish version',
    'Puedes volver a intentarlo o salir y descartar los últimos cambios.':
        'You can try again or exit and discard the latest changes.',
    'Puntos y AR': 'Points and AR',
    'Quédate en la misma posición. Gira alrededor de la lente, sin caminar, e incluye techo y piso. Evita personas identificables y objetos demasiado cerca.':
        'Stay in the same position. Rotate around the lens without walking, and capture the ceiling and floor. Avoid identifiable people and objects that are too close.',
    'RA no está disponible.': 'AR is unavailable.',
    'Reintentar Misiones': 'Retry missions',
    'Retoma con la misma cámara o empieza otra captura.':
        'Resume with the same camera or start a new capture.',
    'Retomar captura': 'Resume capture',
    'Retomar visita': 'Resume visit',
    'Revisa el panorama, sus conexiones y sus puntos. Las pruebas AR se realizan en el local.':
        'Review the panorama, its connections, and its points. AR tests must be done at the venue.',
    'Revisa esta conexión': 'Review this connection',
    'Revisa este punto después del cambio de panorama.':
        'Review this point after changing the panorama.',
    'Revisa las conexiones de panoramas reemplazados':
        'Review connections for replaced panoramas',
    'Revisa los puntos de panoramas reemplazados':
        'Review points for replaced panoramas',
    'Revisé la costura, el techo y el piso sin huecos ni errores visibles.':
        'I checked the seam, ceiling, and floor for gaps and visible errors.',
    'Saltada': 'Skipped',
    'Se eliminará del apartado junto con sus fotografías. Esta acción no se puede deshacer.':
        'It will be removed from this section along with its photos. This action cannot be undone.',
    'Se interrumpió la cámara. Reintenta.':
        'The camera was interrupted. Try again.',
    'Siguiente parada': 'Next stop',
    'Sin panorama listo': 'No panorama ready',
    'Solicitud de vinculación enviada al autor':
        'Link request sent to the creator',
    'Solo en lista': 'List only',
    'Subir parada': 'Move stop up',
    'Subir y procesar panorama': 'Upload and process panorama',
    'Subir zona': 'Move zone up',
    'Terminaste el recorrido. Puedes volver al perfil o explorar el local en 360°.':
        'You finished the tour. You can return to the profile or explore the venue in 360°.',
    'Toca para ver más': 'Tap to see more',
    'Todavía no hay recorridos disponibles aquí.':
        'There are no tours available here yet.',
    'Tu relación con el local': 'Your relationship to the venue',
    'Título del recorrido': 'Tour title',
    'Ubicación pública': 'Public location',
    'Una zona agrupa posiciones 360°. Captura cada posición sin caminar durante las tomas.':
        'A zone groups 360° positions. Capture each position without walking during the shots.',
    'Una zona puede tener varias posiciones. Por ejemplo: Frente a la barra.':
        'A zone can have multiple positions. For example: In front of the bar.',
    'Usar panorama revisado': 'Use reviewed panorama',
    'Vigencia permanente': 'Ongoing',
    'Vincular contenido': 'Link content',
    'Visitada': 'Visited',
    'Vista previa': 'Preview',
    'Vista previa privada': 'Private preview',
    'Volver a elegir panorama': 'Choose panorama again',
    'Volver a intentar': 'Try again',
    'Volver a probar AR': 'Test AR again',
    'Vuelve a elegir el archivo para continuar la carga.':
        'Select the file again to continue uploading.',
    'Vuelve al mismo lugar. Alinea la cámara con esta primera fotografía para recuperar la dirección.':
        'Return to the same place. Align the camera with this first photo to restore the direction.',
    'Ya no podemos confirmar la posición. Vuelve a encuadrar la referencia.':
        'We can no longer confirm the position. Frame the reference again.',
    'Zonas': 'Zones',
    'otra posición': 'another position',
    'Falta conectar Supabase': 'Supabase is not connected',
    'Inicia la app con --dart-define=SUPABASE_URL=... y --dart-define=SUPABASE_ANON_KEY=...':
        'Start the app with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...',
    'Terraza 6–10 pm': 'Terrace 6–10 pm',
    'Sesión en vivo': 'Live session',
    'Sáb, 18 oct • 7:00 pm': 'Sat, Oct 18 • 7:00 pm',
    'Pintura': 'Painting',
    'Moda': 'Fashion',
    'Comida': 'Food',
    'Pantalla {number} de 4': 'Screen {number} of 4',
    'HISTORIA': 'STORY',
    'Todos': 'All',
    'Público': 'Audience',
    'Texto': 'Text',
    'Dibujar': 'Draw',
    'Opciones': 'Options',
    'Las historias todavía no están disponibles.':
        'Stories are not available yet.',
    'Toma una foto o elige una de tu galería.':
        'Take a photo or choose one from your gallery.',
    'Historias reportadas': 'Reported stories',
    'Dejará de estar disponible para la comunidad.':
        'It will no longer be available to the community.',
    'Reporte enviado': 'Report submitted',
    'Conecta. Crea. Explora.': 'Connect. Create. Explore.',
    'MAREA. Conecta. Crea. Explora.': 'MAREA. Connect. Create. Explore.',
    'Tu ciudad\ntambién ': 'Your city\nalso ',
    'crea.': 'creates.',
    'Conecta con artistas, emprendedores\ny negocios que hacen la ciudad más viva.':
        'Connect with artists, entrepreneurs, and businesses that make the city more vibrant.',
    'Misión guardada': 'Mission saved',
    'Misión retirada de guardados': 'Mission removed from saved',
    'Fecha de misión: {date}': 'Mission date: {date}',
    '{date} · Misión': '{date} · Mission',
    'No pudimos actualizar las misiones. Los últimos resultados siguen visibles.':
        'We could not refresh missions. The latest results are still visible.',
    'No pudimos cargar esta foto.': 'We could not load this photo.',
    'Escribe algo o añade una foto.': 'Write something or add a photo.',
    'Usa hasta 500 caracteres.': 'Use no more than 500 characters.',
    'tu@correo.com': 'you@example.com',
    '{step} de {total}': '{step} of {total}',
    'Buscar en el mapa': 'Search the map',
    'Buscar misiones o lugares': 'Search missions or places',
    '{category}: {title}': '{category}: {title}',
    '{count} misiones agrupadas': '{count} grouped missions',
    'Explorar {name}': 'Explore {name}',
    'Próximamente': 'Coming soon',
    'Te enviamos un enlace a {email} para confirmar tu cuenta.':
        'We sent a confirmation link to {email}.',
    '{step} de 3': '{step} of 3',
    'Solicitar de nuevo en {seconds}s': 'Request again in {seconds}s',
    'Reenviar en {seconds}s': 'Resend in {seconds}s',
    '{visited} de {total} paradas visitadas · {skipped} saltadas':
        '{visited} of {total} stops visited · {skipped} skipped',
    'Busca la parada en {destination}.': 'Find the stop at {destination}.',
    '{count} imágenes privadas para revisión':
        '{count} private images for review',
    'Horarios: {hours}': 'Business hours: {hours}',
    'Contacto: {contact}': 'Contact: {contact}',
    'Versión: {state}': 'Version: {state}',
    '{title} · hora de este dispositivo': '{title} · this device’s time',
    'Inclina hacia arriba {degrees}°': 'Tilt up {degrees}°',
    'Inclina hacia abajo {degrees}°': 'Tilt down {degrees}°',
    'Gira {degrees}° a la derecha': 'Turn {degrees}° to the right',
    'Gira {degrees}° a la izquierda': 'Turn {degrees}° to the left',
    'Actual: giro {currentYaw}° · inclinación {currentPitch}°\nObjetivo: giro {targetYaw}° · inclinación {targetPitch}°':
        'Current: rotation {currentYaw}° · tilt {currentPitch}°\nTarget: rotation {targetYaw}° · tilt {targetPitch}°',
    'Apunta a {yaw}° · inclinación {pitch}°': 'Point to {yaw}° · tilt {pitch}°',
    '{count} de {total} tomas aceptadas':
        '{count} of {total} accepted captures',
    'Subiendo {percent} %': 'Uploading {percent}%',
    'Imprimir con ancho exacto de {width} cm, sin recortar. Medir antes de probar AR.':
        'Print at exactly {width} cm wide without cropping. Measure it before testing AR.',
    'Fotografías · {count} de 6': 'Photos · {count} of 6',
    '{error} Tus cambios siguen aquí para reintentar.':
        '{error} Your changes are still here if you want to try again.',
    '{name} quiere iniciar una conversación contigo. ¿Deseas aceptar la solicitud?':
        '{name} wants to start a conversation with you. Would you like to accept the request?',
    'Ir a {location}': 'Go to {location}',
    'Administrar ficha · {status}': 'Manage listing · {status}',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale) ||
      const ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    AppLocalizations._activeLocale = locale;
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
