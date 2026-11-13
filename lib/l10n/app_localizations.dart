import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @inicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get inicio;

  /// No description provided for @iniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get iniciarSesion;

  /// No description provided for @correo.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get correo;

  /// No description provided for @contrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get contrasena;

  /// No description provided for @mostrarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get mostrarContrasena;

  /// No description provided for @ocultarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get ocultarContrasena;

  /// No description provided for @olvideContrasena.
  ///
  /// In es, this message translates to:
  /// **'Olvidé mi contraseña'**
  String get olvideContrasena;

  /// No description provided for @entrar.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get entrar;

  /// No description provided for @continuarConGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get continuarConGoogle;

  /// No description provided for @confirmarMiCorreo.
  ///
  /// In es, this message translates to:
  /// **'Confirmar mi correo'**
  String get confirmarMiCorreo;

  /// No description provided for @noTienesCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get noTienesCuenta;

  /// No description provided for @crearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get crearCuenta;

  /// No description provided for @revisaTuCorreo.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo'**
  String get revisaTuCorreo;

  /// No description provided for @enlaceConfirmarCuenta.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace para confirmar tu cuenta.'**
  String get enlaceConfirmarCuenta;

  /// No description provided for @enlaceCorreoConfirmarCuenta.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace a {email} para confirmar tu cuenta.'**
  String enlaceCorreoConfirmarCuenta(String email);

  /// No description provided for @despuesConfirmarSesion.
  ///
  /// In es, this message translates to:
  /// **'Después de confirmar, vuelve a MAREA e inicia sesión.'**
  String get despuesConfirmarSesion;

  /// No description provided for @irIniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Ir a iniciar sesión'**
  String get irIniciarSesion;

  /// No description provided for @quePerfilQuieresCrear.
  ///
  /// In es, this message translates to:
  /// **'¿Qué perfil quieres crear?'**
  String get quePerfilQuieresCrear;

  /// No description provided for @eligePerfil.
  ///
  /// In es, this message translates to:
  /// **'Elige un perfil.'**
  String get eligePerfil;

  /// No description provided for @usuarioOcupado.
  ///
  /// In es, this message translates to:
  /// **'Este usuario ya está ocupado.'**
  String get usuarioOcupado;

  /// No description provided for @reintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get reintentar;

  /// No description provided for @continuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continuar;

  /// No description provided for @crearCuentaAccion.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get crearCuentaAccion;

  /// No description provided for @recuperarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get recuperarContrasena;

  /// No description provided for @verificaCodigo.
  ///
  /// In es, this message translates to:
  /// **'Verifica el código'**
  String get verificaCodigo;

  /// No description provided for @verificaCorreo.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu correo'**
  String get verificaCorreo;

  /// No description provided for @recuperaTuAcceso.
  ///
  /// In es, this message translates to:
  /// **'Recupera tu acceso'**
  String get recuperaTuAcceso;

  /// No description provided for @escribeCodigoRecibiste.
  ///
  /// In es, this message translates to:
  /// **'Escribe el código que recibiste.'**
  String get escribeCodigoRecibiste;

  /// No description provided for @escribeCorreoCuenta.
  ///
  /// In es, this message translates to:
  /// **'Escribe el correo de tu cuenta.'**
  String get escribeCorreoCuenta;

  /// No description provided for @usaCorreoRegistro.
  ///
  /// In es, this message translates to:
  /// **'Usa el correo con el que te registraste.'**
  String get usaCorreoRegistro;

  /// No description provided for @errorCodigoCorreo.
  ///
  /// In es, this message translates to:
  /// **'Escribe el código del correo (6 a 10 dígitos).'**
  String get errorCodigoCorreo;

  /// No description provided for @verificarCodigo.
  ///
  /// In es, this message translates to:
  /// **'Verificar código'**
  String get verificarCodigo;

  /// No description provided for @enviarCodigo.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get enviarCodigo;

  /// No description provided for @nuevaContrasena.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get nuevaContrasena;

  /// No description provided for @cambiarCorreo.
  ///
  /// In es, this message translates to:
  /// **'Cambiar correo'**
  String get cambiarCorreo;

  /// No description provided for @cambiarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get cambiarContrasena;

  /// No description provided for @guardarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Guardar contraseña'**
  String get guardarContrasena;

  /// No description provided for @contrasenaActual.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get contrasenaActual;

  /// No description provided for @confirmarNuevaContrasena.
  ///
  /// In es, this message translates to:
  /// **'Confirmar nueva contraseña'**
  String get confirmarNuevaContrasena;

  /// No description provided for @codigoSeguridad.
  ///
  /// In es, this message translates to:
  /// **'Código de seguridad'**
  String get codigoSeguridad;

  /// No description provided for @soloSiSeSolicita.
  ///
  /// In es, this message translates to:
  /// **'Solo si se solicita.'**
  String get soloSiSeSolicita;

  /// No description provided for @enviarCodigoCorreo.
  ///
  /// In es, this message translates to:
  /// **'Enviar código por correo'**
  String get enviarCodigoCorreo;

  /// No description provided for @solicitarCambioCorreo.
  ///
  /// In es, this message translates to:
  /// **'Solicitar cambio de correo'**
  String get solicitarCambioCorreo;

  /// No description provided for @contrasenaActualizada.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get contrasenaActualizada;

  /// No description provided for @pasoRegistro.
  ///
  /// In es, this message translates to:
  /// **'{step} de 3'**
  String pasoRegistro(int step);

  /// No description provided for @tuPerfil.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil'**
  String get tuPerfil;

  /// No description provided for @creaTuAcceso.
  ///
  /// In es, this message translates to:
  /// **'Crea tu acceso'**
  String get creaTuAcceso;

  /// No description provided for @usuario.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get usuario;

  /// No description provided for @tipoPerfilFijo.
  ///
  /// In es, this message translates to:
  /// **'El tipo de perfil queda fijo.'**
  String get tipoPerfilFijo;

  /// No description provided for @minimoCaracteres.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get minimoCaracteres;

  /// No description provided for @registroNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'El registro no está disponible. Intenta de nuevo.'**
  String get registroNoDisponible;

  /// No description provided for @usarOtroCorreo.
  ///
  /// In es, this message translates to:
  /// **'Usar otro correo'**
  String get usarOtroCorreo;

  /// No description provided for @codigo.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get codigo;

  /// No description provided for @solicitarCodigoEn.
  ///
  /// In es, this message translates to:
  /// **'Solicitar de nuevo en {seconds}s'**
  String solicitarCodigoEn(int seconds);

  /// No description provided for @reenviarEn.
  ///
  /// In es, this message translates to:
  /// **'Reenviar en {seconds}s'**
  String reenviarEn(int seconds);

  /// No description provided for @reenviarCodigo.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get reenviarCodigo;

  /// No description provided for @yaTengoCodigo.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo un código'**
  String get yaTengoCodigo;

  /// No description provided for @codigoNoLlego.
  ///
  /// In es, this message translates to:
  /// **'¿No llegó? Revisa spam o reenvía el código.'**
  String get codigoNoLlego;

  /// No description provided for @recibirasCodigo.
  ///
  /// In es, this message translates to:
  /// **'Recibirás un código si hay una cuenta con ese correo.'**
  String get recibirasCodigo;

  /// No description provided for @confirmacionCambioCorreo.
  ///
  /// In es, this message translates to:
  /// **'El cambio necesita confirmación en tus correos. Hasta completarla seguirás usando el actual.'**
  String get confirmacionCambioCorreo;

  /// No description provided for @usaContrasenaUnica.
  ///
  /// In es, this message translates to:
  /// **'Usa una contraseña única de al menos 8 caracteres.'**
  String get usaContrasenaUnica;

  /// No description provided for @escribeContrasenaActual.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña actual.'**
  String get escribeContrasenaActual;

  /// No description provided for @nuevoCorreo.
  ///
  /// In es, this message translates to:
  /// **'Nuevo correo'**
  String get nuevoCorreo;

  /// No description provided for @cambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get cambiar;

  /// No description provided for @atras.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get atras;

  /// No description provided for @tusRecorridos.
  ///
  /// In es, this message translates to:
  /// **'Tus recorridos'**
  String get tusRecorridos;

  /// No description provided for @muestraTuLocal360.
  ///
  /// In es, this message translates to:
  /// **'Muestra tu local en 360°'**
  String get muestraTuLocal360;

  /// No description provided for @capturaConectaPanoramas.
  ///
  /// In es, this message translates to:
  /// **'Captura desde varias posiciones y conecta sus panoramas. Añade AR a los puntos que quieras reconocer en el local.'**
  String get capturaConectaPanoramas;

  /// No description provided for @crearRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Crear recorrido'**
  String get crearRecorrido;

  /// No description provided for @solicitudesRevision.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes y revisión'**
  String get solicitudesRevision;

  /// No description provided for @versionPublicaConserva.
  ///
  /// In es, this message translates to:
  /// **'La versión pública se conserva mientras editas.'**
  String get versionPublicaConserva;

  /// No description provided for @editarBorrador.
  ///
  /// In es, this message translates to:
  /// **'Editar borrador'**
  String get editarBorrador;

  /// No description provided for @verRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Ver recorrido'**
  String get verRecorrido;

  /// No description provided for @reanudar.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get reanudar;

  /// No description provided for @pausar.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pausar;

  /// No description provided for @todaviaSinRecorridos.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes recorridos.'**
  String get todaviaSinRecorridos;

  /// No description provided for @autorizacionEspacioContenido.
  ///
  /// In es, this message translates to:
  /// **'La autorización del espacio y la del contenido se revisan por separado.'**
  String get autorizacionEspacioContenido;

  /// No description provided for @sinSolicitudesPendientes.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes pendientes.'**
  String get sinSolicitudesPendientes;

  /// No description provided for @solicitud.
  ///
  /// In es, this message translates to:
  /// **'Solicitud'**
  String get solicitud;

  /// No description provided for @permisoAutor.
  ///
  /// In es, this message translates to:
  /// **'Permiso del autor'**
  String get permisoAutor;

  /// No description provided for @responsabilidadEspacio.
  ///
  /// In es, this message translates to:
  /// **'Responsabilidad del espacio'**
  String get responsabilidadEspacio;

  /// No description provided for @publicacion.
  ///
  /// In es, this message translates to:
  /// **'Publicación'**
  String get publicacion;

  /// No description provided for @panoramaNoListoPosicion.
  ///
  /// In es, this message translates to:
  /// **'Esta posición todavía no tiene un panorama listo.'**
  String get panoramaNoListoPosicion;

  /// No description provided for @permisoEspacioRetiradoError.
  ///
  /// In es, this message translates to:
  /// **'El permiso del espacio fue retirado. Solicita una nueva revisión para volver a publicar.'**
  String get permisoEspacioRetiradoError;

  /// No description provided for @capturaSustituidaError.
  ///
  /// In es, this message translates to:
  /// **'Esta captura fue sustituida por otra más reciente. Vuelve a la posición para continuar con la captura actual.'**
  String get capturaSustituidaError;

  /// No description provided for @contenidoVinculado.
  ///
  /// In es, this message translates to:
  /// **'Contenido vinculado'**
  String get contenidoVinculado;

  /// No description provided for @evidenciaNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Evidencia no disponible'**
  String get evidenciaNoDisponible;

  /// No description provided for @verVersionEnviada.
  ///
  /// In es, this message translates to:
  /// **'Ver versión enviada'**
  String get verVersionEnviada;

  /// No description provided for @retirarPermisoPausar.
  ///
  /// In es, this message translates to:
  /// **'Retirar permiso y pausar recorrido'**
  String get retirarPermisoPausar;

  /// No description provided for @retirarPermisoContenido.
  ///
  /// In es, this message translates to:
  /// **'Retirar permiso del contenido'**
  String get retirarPermisoContenido;

  /// No description provided for @aprobar.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get aprobar;

  /// No description provided for @pedirCambios.
  ///
  /// In es, this message translates to:
  /// **'Pedir cambios'**
  String get pedirCambios;

  /// No description provided for @queDebeCorregirse.
  ///
  /// In es, this message translates to:
  /// **'Qué debe corregirse'**
  String get queDebeCorregirse;

  /// No description provided for @volver.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get volver;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get guardar;

  /// No description provided for @noPudimosAbrirPanorama.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el panorama.'**
  String get noPudimosAbrirPanorama;

  /// No description provided for @mirarArrastrando.
  ///
  /// In es, this message translates to:
  /// **'Mirar arrastrando'**
  String get mirarArrastrando;

  /// No description provided for @mirarMovimientoTelefono.
  ///
  /// In es, this message translates to:
  /// **'Mirar con el movimiento del teléfono'**
  String get mirarMovimientoTelefono;

  /// No description provided for @colocarPunto.
  ///
  /// In es, this message translates to:
  /// **'Colocar punto'**
  String get colocarPunto;

  /// No description provided for @instruccionColocarPunto.
  ///
  /// In es, this message translates to:
  /// **'Mira hacia el lugar del punto y pulsa Colocar aquí. También puedes dejarlo solo en la lista.'**
  String get instruccionColocarPunto;

  /// No description provided for @colocarAqui.
  ///
  /// In es, this message translates to:
  /// **'Colocar aquí'**
  String get colocarAqui;

  /// No description provided for @explorarLocales.
  ///
  /// In es, this message translates to:
  /// **'Explorar locales'**
  String get explorarLocales;

  /// No description provided for @conoceEspacios360.
  ///
  /// In es, this message translates to:
  /// **'Conoce espacios en 360° y descubre sus paradas con cámara cuando estés ahí.'**
  String get conoceEspacios360;

  /// No description provided for @buscandoUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Buscando tu ubicación…'**
  String get buscandoUbicacion;

  /// No description provided for @descubrirCerca.
  ///
  /// In es, this message translates to:
  /// **'Descubrir cerca de mí'**
  String get descubrirCerca;

  /// No description provided for @errorUbicacion.
  ///
  /// In es, this message translates to:
  /// **'No pudimos obtener tu ubicación. Puedes explorar la lista de locales.'**
  String get errorUbicacion;

  /// No description provided for @ubicacionAproximada.
  ///
  /// In es, this message translates to:
  /// **'La ubicación y dirección del local son aproximadas. Dentro, usa las fotografías e indicaciones de cada parada.'**
  String get ubicacionAproximada;

  /// No description provided for @sinRecorridosDisponibles.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay recorridos disponibles aquí.'**
  String get sinRecorridosDisponibles;

  /// No description provided for @vistaPreviaPrivada.
  ///
  /// In es, this message translates to:
  /// **'Vista previa privada'**
  String get vistaPreviaPrivada;

  /// No description provided for @compartirRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Compartir recorrido'**
  String get compartirRecorrido;

  /// No description provided for @zonas.
  ///
  /// In es, this message translates to:
  /// **'Zonas'**
  String get zonas;

  /// No description provided for @irAOtraPosicion.
  ///
  /// In es, this message translates to:
  /// **'Ir a otra posición'**
  String get irAOtraPosicion;

  /// No description provided for @finalizarVisita.
  ///
  /// In es, this message translates to:
  /// **'Finalizar visita'**
  String get finalizarVisita;

  /// No description provided for @miraAlrededor360.
  ///
  /// In es, this message translates to:
  /// **'Mira alrededor en 360° y cambia entre posiciones. Puedes conocer cada punto sin usar la cámara ni compartir tu ubicación.'**
  String get miraAlrededor360;

  /// No description provided for @recorridoCambio.
  ///
  /// In es, this message translates to:
  /// **'El recorrido cambió desde tu última visita. Empieza la versión actual.'**
  String get recorridoCambio;

  /// No description provided for @empezarVisita.
  ///
  /// In es, this message translates to:
  /// **'Empezar visita'**
  String get empezarVisita;

  /// No description provided for @retomarVisita.
  ///
  /// In es, this message translates to:
  /// **'Retomar visita'**
  String get retomarVisita;

  /// No description provided for @recorrerConCamara.
  ///
  /// In es, this message translates to:
  /// **'Recorrer con cámara'**
  String get recorrerConCamara;

  /// No description provided for @volverPerfil.
  ///
  /// In es, this message translates to:
  /// **'Volver al perfil'**
  String get volverPerfil;

  /// No description provided for @recorridoNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Este recorrido no está disponible. Puede estar pausado o haber finalizado.'**
  String get recorridoNoDisponible;

  /// No description provided for @versionNuevaRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Este recorrido tiene una versión nueva. Al empezar se reiniciará el progreso anterior.'**
  String get versionNuevaRecorrido;

  /// No description provided for @errorGuardarProgreso.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el progreso en este dispositivo. Mantén la pantalla abierta e inténtalo de nuevo.'**
  String get errorGuardarProgreso;

  /// No description provided for @progresoGuardado.
  ///
  /// In es, this message translates to:
  /// **'Progreso guardado en este dispositivo. Se sincronizará al volver a abrir el recorrido.'**
  String get progresoGuardado;

  /// No description provided for @otraPosicion.
  ///
  /// In es, this message translates to:
  /// **'otra posición'**
  String get otraPosicion;

  /// No description provided for @verContenido.
  ///
  /// In es, this message translates to:
  /// **'Ver contenido'**
  String get verContenido;

  /// No description provided for @contenidoNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Este contenido todavía no está disponible.'**
  String get contenidoNoDisponible;

  /// No description provided for @continuarRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Continuar recorrido'**
  String get continuarRecorrido;

  /// No description provided for @probarArEnLocal.
  ///
  /// In es, this message translates to:
  /// **'Probar AR en el local'**
  String get probarArEnLocal;

  /// No description provided for @recorridoCambioParadas.
  ///
  /// In es, this message translates to:
  /// **'El recorrido cambió. Estas paradas pertenecen a la versión actual.'**
  String get recorridoCambioParadas;

  /// No description provided for @arNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'AR no está disponible en este dispositivo. Puedes consultar las paradas y explorar el panorama.'**
  String get arNoDisponible;

  /// No description provided for @paradasVisitadas.
  ///
  /// In es, this message translates to:
  /// **'{visited} de {total} paradas visitadas · {skipped} saltadas'**
  String paradasVisitadas(int visited, int total, int skipped);

  /// No description provided for @imagenReconocida.
  ///
  /// In es, this message translates to:
  /// **'Imagen reconocida'**
  String get imagenReconocida;

  /// No description provided for @encuadraImagenParada.
  ///
  /// In es, this message translates to:
  /// **'Encuadra la imagen de esta parada'**
  String get encuadraImagenParada;

  /// No description provided for @referenciaNoConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Ya no podemos confirmar la posición. Vuelve a encuadrar la referencia.'**
  String get referenciaNoConfirmada;

  /// No description provided for @referenciaNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Referencia no disponible'**
  String get referenciaNoDisponible;

  /// No description provided for @escanearImagen.
  ///
  /// In es, this message translates to:
  /// **'Escanear esta imagen'**
  String get escanearImagen;

  /// No description provided for @volverLista.
  ///
  /// In es, this message translates to:
  /// **'Volver a la lista'**
  String get volverLista;

  /// No description provided for @guardarPruebaReconocimiento.
  ///
  /// In es, this message translates to:
  /// **'Guardar prueba de reconocimiento'**
  String get guardarPruebaReconocimiento;

  /// No description provided for @pruebaGuardadaReferencia.
  ///
  /// In es, this message translates to:
  /// **'Prueba guardada para esta referencia.'**
  String get pruebaGuardadaReferencia;

  /// No description provided for @pruebaReferenciaNoConfirmada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar que la prueba se guardó para esta referencia. Mantén la imagen encuadrada y vuelve a intentarlo.'**
  String get pruebaReferenciaNoConfirmada;

  /// No description provided for @errorAbrirReferenciaParada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir la referencia de esta parada.'**
  String get errorAbrirReferenciaParada;

  /// No description provided for @reintentarConsultaRa.
  ///
  /// In es, this message translates to:
  /// **'Reintentar consultar RA'**
  String get reintentarConsultaRa;

  /// No description provided for @explorarEnRa.
  ///
  /// In es, this message translates to:
  /// **'Explorar en RA'**
  String get explorarEnRa;

  /// No description provided for @eligeImagenBuscar.
  ///
  /// In es, this message translates to:
  /// **'Elige la imagen que vas a buscar'**
  String get eligeImagenBuscar;

  /// No description provided for @sesionCambioExperiencia.
  ///
  /// In es, this message translates to:
  /// **'La sesión cambió. Vuelve a abrir la experiencia.'**
  String get sesionCambioExperiencia;

  /// No description provided for @tocaVerMas.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver más'**
  String get tocaVerMas;

  /// No description provided for @buscaImagenReferencia.
  ///
  /// In es, this message translates to:
  /// **'Busca la imagen de referencia. Acércate despacio y evita reflejos.'**
  String get buscaImagenReferencia;

  /// No description provided for @imagenReconocidaTocaTarjeta.
  ///
  /// In es, this message translates to:
  /// **'Imagen reconocida. Toca la tarjeta.'**
  String get imagenReconocidaTocaTarjeta;

  /// No description provided for @cerrarCamara.
  ///
  /// In es, this message translates to:
  /// **'Cerrar cámara'**
  String get cerrarCamara;

  /// No description provided for @buscaImagenLugarTarjeta.
  ///
  /// In es, this message translates to:
  /// **'Busca esta imagen en el lugar para descubrir su tarjeta.'**
  String get buscaImagenLugarTarjeta;

  /// No description provided for @buscaParadaEn.
  ///
  /// In es, this message translates to:
  /// **'Busca la parada en {destination}.'**
  String buscaParadaEn(String destination);

  /// No description provided for @referenciaNoMostrar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos mostrar la referencia.'**
  String get referenciaNoMostrar;

  /// No description provided for @reintentarImagen.
  ///
  /// In es, this message translates to:
  /// **'Reintentar imagen'**
  String get reintentarImagen;

  /// No description provided for @camaraCompatibleAr.
  ///
  /// In es, this message translates to:
  /// **'La cámara de RA necesita un teléfono compatible con ARCore o ARKit. Puedes consultar el perfil.'**
  String get camaraCompatibleAr;

  /// No description provided for @comprobarCompatibilidad.
  ///
  /// In es, this message translates to:
  /// **'Volver a comprobar compatibilidad'**
  String get comprobarCompatibilidad;

  /// No description provided for @preparandoCamara.
  ///
  /// In es, this message translates to:
  /// **'Preparando cámara…'**
  String get preparandoCamara;

  /// No description provided for @abrirCamara.
  ///
  /// In es, this message translates to:
  /// **'Abrir cámara'**
  String get abrirCamara;

  /// No description provided for @volverCamara.
  ///
  /// In es, this message translates to:
  /// **'Volver a cámara'**
  String get volverCamara;

  /// No description provided for @misionesActivas.
  ///
  /// In es, this message translates to:
  /// **'Misiones activas'**
  String get misionesActivas;

  /// No description provided for @sinMisionesActivasOrganizador.
  ///
  /// In es, this message translates to:
  /// **'Este organizador no tiene Misiones activas por ahora.'**
  String get sinMisionesActivasOrganizador;

  /// No description provided for @consultarMasMisiones.
  ///
  /// In es, this message translates to:
  /// **'Consultar más Misiones'**
  String get consultarMasMisiones;

  /// No description provided for @reintentarMisiones.
  ///
  /// In es, this message translates to:
  /// **'Reintentar Misiones'**
  String get reintentarMisiones;

  /// No description provided for @errorConsultarMisiones.
  ///
  /// In es, this message translates to:
  /// **'No pudimos consultar las Misiones.'**
  String get errorConsultarMisiones;

  /// No description provided for @errorCamaraInterrumpida.
  ///
  /// In es, this message translates to:
  /// **'Se interrumpió la cámara. Reintenta.'**
  String get errorCamaraInterrumpida;

  /// No description provided for @errorDescargarImagen.
  ///
  /// In es, this message translates to:
  /// **'No pudimos descargar la imagen. Reintenta.'**
  String get errorDescargarImagen;

  /// No description provided for @errorIniciarCamara.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar la cámara.'**
  String get errorIniciarCamara;

  /// No description provided for @errorIniciarCamaraAr.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar la cámara AR. Puedes consultar la lista.'**
  String get errorIniciarCamaraAr;

  /// No description provided for @procesamientoEnEspera.
  ///
  /// In es, this message translates to:
  /// **'Esperando procesamiento'**
  String get procesamientoEnEspera;

  /// No description provided for @procesandoPanorama.
  ///
  /// In es, this message translates to:
  /// **'Armando tu panorama'**
  String get procesandoPanorama;

  /// No description provided for @panoramaListoRevision.
  ///
  /// In es, this message translates to:
  /// **'Panorama listo para revisar'**
  String get panoramaListoRevision;

  /// No description provided for @necesitamosNuevasFotografias.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos nuevas fotografías'**
  String get necesitamosNuevasFotografias;

  /// No description provided for @procesamientoCancelado.
  ///
  /// In es, this message translates to:
  /// **'Procesamiento cancelado'**
  String get procesamientoCancelado;

  /// No description provided for @noPudimosProcesarPanorama.
  ///
  /// In es, this message translates to:
  /// **'No pudimos procesar el panorama'**
  String get noPudimosProcesarPanorama;

  /// No description provided for @volverElegirArchivoCarga.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a elegir el archivo para continuar la carga.'**
  String get volverElegirArchivoCarga;

  /// No description provided for @fotoSubidaNoConfirmada.
  ///
  /// In es, this message translates to:
  /// **'El servidor no confirmó la fotografía completa.'**
  String get fotoSubidaNoConfirmada;

  /// No description provided for @raNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'RA no está disponible.'**
  String get raNoDisponible;

  /// No description provided for @experienciaRaNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Esta experiencia de RA ya no está disponible.'**
  String get experienciaRaNoDisponible;

  /// No description provided for @perfilNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'El perfil ya no está disponible.'**
  String get perfilNoDisponible;

  /// No description provided for @estadoPublicado.
  ///
  /// In es, this message translates to:
  /// **'Publicado'**
  String get estadoPublicado;

  /// No description provided for @estadoAprobado.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get estadoAprobado;

  /// No description provided for @estadoPausado.
  ///
  /// In es, this message translates to:
  /// **'Pausado'**
  String get estadoPausado;

  /// No description provided for @estadoEnRevision.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get estadoEnRevision;

  /// No description provided for @estadoRequiereCambios.
  ///
  /// In es, this message translates to:
  /// **'Requiere cambios'**
  String get estadoRequiereCambios;

  /// No description provided for @estadoFinalizado.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get estadoFinalizado;

  /// No description provided for @estadoBorrador.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get estadoBorrador;

  /// No description provided for @estadoRechazado.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get estadoRechazado;

  /// No description provided for @solicitudSustituida.
  ///
  /// In es, this message translates to:
  /// **'Solicitud sustituida'**
  String get solicitudSustituida;

  /// No description provided for @estadoRevocado.
  ///
  /// In es, this message translates to:
  /// **'Revocado'**
  String get estadoRevocado;

  /// No description provided for @crearRecorrido360.
  ///
  /// In es, this message translates to:
  /// **'Crear recorrido 360°'**
  String get crearRecorrido360;

  /// No description provided for @borradorNoRecuperado.
  ///
  /// In es, this message translates to:
  /// **'No pudimos recuperar el borrador.'**
  String get borradorNoRecuperado;

  /// No description provided for @necesitasPerfilProfesional.
  ///
  /// In es, this message translates to:
  /// **'Necesitas un perfil profesional.'**
  String get necesitasPerfilProfesional;

  /// No description provided for @pasoLocal.
  ///
  /// In es, this message translates to:
  /// **'Local'**
  String get pasoLocal;

  /// No description provided for @pasoZonas.
  ///
  /// In es, this message translates to:
  /// **'Zonas'**
  String get pasoZonas;

  /// No description provided for @pasoPuntosAr.
  ///
  /// In es, this message translates to:
  /// **'Puntos y AR'**
  String get pasoPuntosAr;

  /// No description provided for @pasoConexiones.
  ///
  /// In es, this message translates to:
  /// **'Conexiones'**
  String get pasoConexiones;

  /// No description provided for @pasoVistaPrevia.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get pasoVistaPrevia;

  /// No description provided for @pasoPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Publicación'**
  String get pasoPublicacion;

  /// No description provided for @tituloRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Título del recorrido'**
  String get tituloRecorrido;

  /// No description provided for @nombreLocal.
  ///
  /// In es, this message translates to:
  /// **'Nombre del local'**
  String get nombreLocal;

  /// No description provided for @ubicacionPublica.
  ///
  /// In es, this message translates to:
  /// **'Ubicación pública'**
  String get ubicacionPublica;

  /// No description provided for @confirmarUbicacionMapa.
  ///
  /// In es, this message translates to:
  /// **'Confirmar ubicación en el mapa'**
  String get confirmarUbicacionMapa;

  /// No description provided for @relacionLocal.
  ///
  /// In es, this message translates to:
  /// **'Tu relación con el local'**
  String get relacionLocal;

  /// No description provided for @revisaraResponsabilidad.
  ///
  /// In es, this message translates to:
  /// **'El administrador revisará la responsabilidad del espacio. No incluyas documentos sensibles.'**
  String get revisaraResponsabilidad;

  /// No description provided for @anadirEvidenciaPrivada.
  ///
  /// In es, this message translates to:
  /// **'Añadir evidencia privada del local'**
  String get anadirEvidenciaPrivada;

  /// No description provided for @imagenesPrivadasRevision.
  ///
  /// In es, this message translates to:
  /// **'{count} imágenes privadas para revisión'**
  String imagenesPrivadasRevision(int count);

  /// No description provided for @horarios.
  ///
  /// In es, this message translates to:
  /// **'Horarios: {hours}'**
  String horarios(String hours);

  /// No description provided for @contacto.
  ///
  /// In es, this message translates to:
  /// **'Contacto: {contact}'**
  String contacto(String contact);

  /// No description provided for @editarDatosPerfil.
  ///
  /// In es, this message translates to:
  /// **'Editar datos del perfil'**
  String get editarDatosPerfil;

  /// No description provided for @zonaAgrupaPosiciones.
  ///
  /// In es, this message translates to:
  /// **'Una zona agrupa posiciones 360°. Captura cada posición sin caminar durante las tomas.'**
  String get zonaAgrupaPosiciones;

  /// No description provided for @agregarZona.
  ///
  /// In es, this message translates to:
  /// **'Agregar zona'**
  String get agregarZona;

  /// No description provided for @editarZona.
  ///
  /// In es, this message translates to:
  /// **'Editar zona'**
  String get editarZona;

  /// No description provided for @editarNombre.
  ///
  /// In es, this message translates to:
  /// **'Editar nombre'**
  String get editarNombre;

  /// No description provided for @sinPanoramaListo.
  ///
  /// In es, this message translates to:
  /// **'Sin panorama listo'**
  String get sinPanoramaListo;

  /// No description provided for @panoramaListo.
  ///
  /// In es, this message translates to:
  /// **'Panorama listo'**
  String get panoramaListo;

  /// No description provided for @capturarRetomar.
  ///
  /// In es, this message translates to:
  /// **'Capturar / retomar'**
  String get capturarRetomar;

  /// No description provided for @importar360.
  ///
  /// In es, this message translates to:
  /// **'Importar 360°'**
  String get importar360;

  /// No description provided for @agregarPosicion.
  ///
  /// In es, this message translates to:
  /// **'Agregar posición'**
  String get agregarPosicion;

  /// No description provided for @revisarPuntoCambioPanorama.
  ///
  /// In es, this message translates to:
  /// **'Revisa este punto después del cambio de panorama.'**
  String get revisarPuntoCambioPanorama;

  /// No description provided for @marcarEn360.
  ///
  /// In es, this message translates to:
  /// **'Marcar en 360°'**
  String get marcarEn360;

  /// No description provided for @explicacion.
  ///
  /// In es, this message translates to:
  /// **'Explicación'**
  String get explicacion;

  /// No description provided for @editarTexto.
  ///
  /// In es, this message translates to:
  /// **'Editar texto'**
  String get editarTexto;

  /// No description provided for @soloEnLista.
  ///
  /// In es, this message translates to:
  /// **'Solo en lista'**
  String get soloEnLista;

  /// No description provided for @vincularContenido.
  ///
  /// In es, this message translates to:
  /// **'Vincular contenido'**
  String get vincularContenido;

  /// No description provided for @imagenParaAr.
  ///
  /// In es, this message translates to:
  /// **'Imagen para AR'**
  String get imagenParaAr;

  /// No description provided for @distintivoImprimible.
  ///
  /// In es, this message translates to:
  /// **'Distintivo imprimible'**
  String get distintivoImprimible;

  /// No description provided for @volverProbarAr.
  ///
  /// In es, this message translates to:
  /// **'Volver a probar AR'**
  String get volverProbarAr;

  /// No description provided for @agregarPunto.
  ///
  /// In es, this message translates to:
  /// **'Agregar punto'**
  String get agregarPunto;

  /// No description provided for @posicionInicial.
  ///
  /// In es, this message translates to:
  /// **'Posición inicial'**
  String get posicionInicial;

  /// No description provided for @ordenZonas.
  ///
  /// In es, this message translates to:
  /// **'Orden de zonas'**
  String get ordenZonas;

  /// No description provided for @subirZona.
  ///
  /// In es, this message translates to:
  /// **'Subir zona'**
  String get subirZona;

  /// No description provided for @bajarZona.
  ///
  /// In es, this message translates to:
  /// **'Bajar zona'**
  String get bajarZona;

  /// No description provided for @revisarConexion.
  ///
  /// In es, this message translates to:
  /// **'Revisa esta conexión'**
  String get revisarConexion;

  /// No description provided for @eliminarConexion.
  ///
  /// In es, this message translates to:
  /// **'Eliminar conexión'**
  String get eliminarConexion;

  /// No description provided for @conectarOtraPosicion.
  ///
  /// In es, this message translates to:
  /// **'Conectar otra posición'**
  String get conectarOtraPosicion;

  /// No description provided for @paradasConCamara.
  ///
  /// In es, this message translates to:
  /// **'Paradas con cámara'**
  String get paradasConCamara;

  /// No description provided for @ordenRecorridoPresencial.
  ///
  /// In es, this message translates to:
  /// **'Orden del recorrido presencial'**
  String get ordenRecorridoPresencial;

  /// No description provided for @subirParada.
  ///
  /// In es, this message translates to:
  /// **'Subir parada'**
  String get subirParada;

  /// No description provided for @bajarParada.
  ///
  /// In es, this message translates to:
  /// **'Bajar parada'**
  String get bajarParada;

  /// No description provided for @revisarAntesVistaPrevia.
  ///
  /// In es, this message translates to:
  /// **'Revisa el panorama, sus conexiones y sus puntos. Las pruebas AR se realizan en el local.'**
  String get revisarAntesVistaPrevia;

  /// No description provided for @abrirVistaPreviaPrivada.
  ///
  /// In es, this message translates to:
  /// **'Abrir vista previa privada'**
  String get abrirVistaPreviaPrivada;

  /// No description provided for @espacioAutorizado.
  ///
  /// In es, this message translates to:
  /// **'Espacio: autorizado'**
  String get espacioAutorizado;

  /// No description provided for @espacioPendienteRevision.
  ///
  /// In es, this message translates to:
  /// **'Espacio: pendiente de revisión'**
  String get espacioPendienteRevision;

  /// No description provided for @problemaAgregarPosicion360.
  ///
  /// In es, this message translates to:
  /// **'Agrega una posición 360°'**
  String get problemaAgregarPosicion360;

  /// No description provided for @problemaElegirPosicionInicial.
  ///
  /// In es, this message translates to:
  /// **'Elige una posición inicial'**
  String get problemaElegirPosicionInicial;

  /// No description provided for @problemaPanoramasPendientes.
  ///
  /// In es, this message translates to:
  /// **'Espera a que todos los panoramas estén listos'**
  String get problemaPanoramasPendientes;

  /// No description provided for @problemaRevisarPuntosPanoramas.
  ///
  /// In es, this message translates to:
  /// **'Revisa los puntos de panoramas reemplazados'**
  String get problemaRevisarPuntosPanoramas;

  /// No description provided for @problemaRevisarConexionesPanoramas.
  ///
  /// In es, this message translates to:
  /// **'Revisa las conexiones de panoramas reemplazados'**
  String get problemaRevisarConexionesPanoramas;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión: {state}'**
  String version(String state);

  /// No description provided for @versionPublicaDisponible.
  ///
  /// In es, this message translates to:
  /// **'La versión pública anterior seguirá disponible hasta aprobar estos cambios.'**
  String get versionPublicaDisponible;

  /// No description provided for @vinculosPendientes.
  ///
  /// In es, this message translates to:
  /// **'Los vínculos pendientes no aparecerán en la versión pública.'**
  String get vinculosPendientes;

  /// No description provided for @inicioVigencia.
  ///
  /// In es, this message translates to:
  /// **'Inicio de vigencia'**
  String get inicioVigencia;

  /// No description provided for @finVigencia.
  ///
  /// In es, this message translates to:
  /// **'Fin de vigencia'**
  String get finVigencia;

  /// No description provided for @horaDispositivo.
  ///
  /// In es, this message translates to:
  /// **'{title} · hora de este dispositivo'**
  String horaDispositivo(String title);

  /// No description provided for @finPosteriorInicio.
  ///
  /// In es, this message translates to:
  /// **'El fin debe ser posterior al inicio.'**
  String get finPosteriorInicio;

  /// No description provided for @definirVigenciaTemporal.
  ///
  /// In es, this message translates to:
  /// **'Definir vigencia temporal'**
  String get definirVigenciaTemporal;

  /// No description provided for @vigenciaPermanente.
  ///
  /// In es, this message translates to:
  /// **'Vigencia permanente'**
  String get vigenciaPermanente;

  /// No description provided for @publicarVersion.
  ///
  /// In es, this message translates to:
  /// **'Publicar versión'**
  String get publicarVersion;

  /// No description provided for @enviarRevision.
  ///
  /// In es, this message translates to:
  /// **'Enviar a revisión'**
  String get enviarRevision;

  /// No description provided for @guardando.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get guardando;

  /// No description provided for @guardarBorrador.
  ///
  /// In es, this message translates to:
  /// **'Guardar borrador'**
  String get guardarBorrador;

  /// No description provided for @continuarPaso.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continuarPaso;

  /// No description provided for @guardandoToma.
  ///
  /// In es, this message translates to:
  /// **'Guardando la toma…'**
  String get guardandoToma;

  /// No description provided for @esperandoOrientacionMover.
  ///
  /// In es, this message translates to:
  /// **'Esperando orientación del teléfono. Muévelo suavemente.'**
  String get esperandoOrientacionMover;

  /// No description provided for @posicionListaAceptar.
  ///
  /// In es, this message translates to:
  /// **'Posición lista. Pulsa Aceptar toma.'**
  String get posicionListaAceptar;

  /// No description provided for @mantenerTelefonoEstableMomento.
  ///
  /// In es, this message translates to:
  /// **'Mantén el teléfono estable un momento.'**
  String get mantenerTelefonoEstableMomento;

  /// No description provided for @inclinaArribaGrados.
  ///
  /// In es, this message translates to:
  /// **'Inclina hacia arriba {degrees}°'**
  String inclinaArribaGrados(int degrees);

  /// No description provided for @inclinaAbajoGrados.
  ///
  /// In es, this message translates to:
  /// **'Inclina hacia abajo {degrees}°'**
  String inclinaAbajoGrados(int degrees);

  /// No description provided for @giraDerechaGrados.
  ///
  /// In es, this message translates to:
  /// **'Gira {degrees}° a la derecha'**
  String giraDerechaGrados(int degrees);

  /// No description provided for @giraIzquierdaGrados.
  ///
  /// In es, this message translates to:
  /// **'Gira {degrees}° a la izquierda'**
  String giraIzquierdaGrados(int degrees);

  /// No description provided for @ajustaEncuadreAlinear.
  ///
  /// In es, this message translates to:
  /// **'Ajusta ligeramente el encuadre hasta alinear la cámara.'**
  String get ajustaEncuadreAlinear;

  /// No description provided for @lecturaOrientacion.
  ///
  /// In es, this message translates to:
  /// **'Actual: giro {currentYaw}° · inclinación {currentPitch}°\nObjetivo: giro {targetYaw}° · inclinación {targetPitch}°'**
  String lecturaOrientacion(
    int currentYaw,
    int currentPitch,
    int targetYaw,
    int targetPitch,
  );

  /// No description provided for @aceptarToma.
  ///
  /// In es, this message translates to:
  /// **'Aceptar toma'**
  String get aceptarToma;

  /// No description provided for @capturarPosicion360.
  ///
  /// In es, this message translates to:
  /// **'Capturar posición 360°'**
  String get capturarPosicion360;

  /// No description provided for @instruccionCapturaPanorama.
  ///
  /// In es, this message translates to:
  /// **'Quédate en la misma posición. Gira alrededor de la lente, sin caminar, e incluye techo y piso. Evita personas identificables y objetos demasiado cerca.'**
  String get instruccionCapturaPanorama;

  /// No description provided for @panoramaProcesado.
  ///
  /// In es, this message translates to:
  /// **'Panorama procesado'**
  String get panoramaProcesado;

  /// No description provided for @confirmacionRevisionPanorama.
  ///
  /// In es, this message translates to:
  /// **'Revisé la costura, el techo y el piso sin huecos ni errores visibles.'**
  String get confirmacionRevisionPanorama;

  /// No description provided for @usarPanoramaRevisado.
  ///
  /// In es, this message translates to:
  /// **'Usar panorama revisado'**
  String get usarPanoramaRevisado;

  /// No description provided for @cancelarProcesamiento.
  ///
  /// In es, this message translates to:
  /// **'Cancelar procesamiento'**
  String get cancelarProcesamiento;

  /// No description provided for @prepararNuevaCaptura.
  ///
  /// In es, this message translates to:
  /// **'Preparar nueva captura'**
  String get prepararNuevaCaptura;

  /// No description provided for @archivoWebNoConservado.
  ///
  /// In es, this message translates to:
  /// **'El navegador no conserva este archivo al cerrar la pantalla. Elige el panorama de nuevo para iniciar otra subida.'**
  String get archivoWebNoConservado;

  /// No description provided for @volverElegirPanorama.
  ///
  /// In es, this message translates to:
  /// **'Volver a elegir panorama'**
  String get volverElegirPanorama;

  /// No description provided for @capturaCompleta.
  ///
  /// In es, this message translates to:
  /// **'Captura completa'**
  String get capturaCompleta;

  /// No description provided for @esperandoOrientacion.
  ///
  /// In es, this message translates to:
  /// **'Esperando orientación del teléfono'**
  String get esperandoOrientacion;

  /// No description provided for @mantenerTelefonoEstable.
  ///
  /// In es, this message translates to:
  /// **'Mantén el teléfono estable'**
  String get mantenerTelefonoEstable;

  /// No description provided for @apuntarObjetivo.
  ///
  /// In es, this message translates to:
  /// **'Apunta a {yaw}° · inclinación {pitch}°'**
  String apuntarObjetivo(String yaw, String pitch);

  /// No description provided for @tomasAceptadas.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total} tomas aceptadas'**
  String tomasAceptadas(int count, int total);

  /// No description provided for @alinearPrimeraToma.
  ///
  /// In es, this message translates to:
  /// **'Ya alineé la primera toma'**
  String get alinearPrimeraToma;

  /// No description provided for @repetirUltimaToma.
  ///
  /// In es, this message translates to:
  /// **'Repetir última toma'**
  String get repetirUltimaToma;

  /// No description provided for @empezarOtraCaptura.
  ///
  /// In es, this message translates to:
  /// **'Empezar otra captura'**
  String get empezarOtraCaptura;

  /// No description provided for @capturasDejaranPosicion.
  ///
  /// In es, this message translates to:
  /// **'Las tomas actuales dejarán de formar parte de esta posición. La versión publicada se conserva.'**
  String get capturasDejaranPosicion;

  /// No description provided for @conservarTomas.
  ///
  /// In es, this message translates to:
  /// **'Conservar tomas'**
  String get conservarTomas;

  /// No description provided for @empezarOtra.
  ///
  /// In es, this message translates to:
  /// **'Empezar otra'**
  String get empezarOtra;

  /// No description provided for @abrirCamaraGuiada.
  ///
  /// In es, this message translates to:
  /// **'Abrir cámara guiada'**
  String get abrirCamaraGuiada;

  /// No description provided for @retomarCaptura.
  ///
  /// In es, this message translates to:
  /// **'Retomar captura'**
  String get retomarCaptura;

  /// No description provided for @importarPanoramaEsferico.
  ///
  /// In es, this message translates to:
  /// **'Importar panorama esférico'**
  String get importarPanoramaEsferico;

  /// No description provided for @subiendoPorcentaje.
  ///
  /// In es, this message translates to:
  /// **'Subiendo {percent} %'**
  String subiendoPorcentaje(String percent);

  /// No description provided for @subirProcesarPanorama.
  ///
  /// In es, this message translates to:
  /// **'Subir y procesar panorama'**
  String get subirProcesarPanorama;

  /// No description provided for @subidaWebEnCurso.
  ///
  /// In es, this message translates to:
  /// **'Mantén esta pantalla abierta durante la subida. Si la cierras, tendrás que elegir el archivo de nuevo. El procesamiento empieza tras confirmar la subida completa.'**
  String get subidaWebEnCurso;

  /// No description provided for @subidaDispositivoEnCurso.
  ///
  /// In es, this message translates to:
  /// **'Las tomas aceptadas se guardan en este dispositivo. El procesamiento empieza después de confirmar la subida completa.'**
  String get subidaDispositivoEnCurso;

  /// No description provided for @proporcionEsfericaGpano.
  ///
  /// In es, this message translates to:
  /// **'Elige una esfera equirectangular completa de proporción 2:1, con metadatos GPano.'**
  String get proporcionEsfericaGpano;

  /// No description provided for @panoramaSuperaLimite.
  ///
  /// In es, this message translates to:
  /// **'El panorama supera 32 MB. Exporta un JPEG de menor tamaño.'**
  String get panoramaSuperaLimite;

  /// No description provided for @sinCamaraTrasera.
  ///
  /// In es, this message translates to:
  /// **'No hay cámara trasera disponible. Puedes importar un panorama.'**
  String get sinCamaraTrasera;

  /// No description provided for @errorDatosLente.
  ///
  /// In es, this message translates to:
  /// **'No pudimos obtener los datos de la lente. Importa un panorama 360°.'**
  String get errorDatosLente;

  /// No description provided for @mismaCamaraCaptura.
  ///
  /// In es, this message translates to:
  /// **'Retoma con la misma cámara o empieza otra captura.'**
  String get mismaCamaraCaptura;

  /// No description provided for @fotoNoLeida.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer la fotografía.'**
  String get fotoNoLeida;

  /// No description provided for @estadoSesionCambio.
  ///
  /// In es, this message translates to:
  /// **'La sesión cambió.'**
  String get estadoSesionCambio;

  /// No description provided for @orientacionNoLeida.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer la orientación. Puedes importar un panorama.'**
  String get orientacionNoLeida;

  /// No description provided for @orientacionTelefonoNoLeida.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer la orientación del teléfono. Puedes importar un panorama.'**
  String get orientacionTelefonoNoLeida;

  /// No description provided for @noConocemosLente.
  ///
  /// In es, this message translates to:
  /// **'No pudimos conocer la lente. Puedes importar un panorama 360°.'**
  String get noConocemosLente;

  /// No description provided for @lenteCambio.
  ///
  /// In es, this message translates to:
  /// **'La lente cambió desde la primera toma. Usa la misma cámara o empieza otra captura.'**
  String get lenteCambio;

  /// No description provided for @demasiadasTomasLente.
  ///
  /// In es, this message translates to:
  /// **'Esta lente requiere demasiadas tomas. Usa la cámara principal o importa una esfera completa.'**
  String get demasiadasTomasLente;

  /// No description provided for @alinearCapturaInicialAyuda.
  ///
  /// In es, this message translates to:
  /// **'Vuelve al mismo lugar. Alinea la cámara con esta primera fotografía para recuperar la dirección.'**
  String get alinearCapturaInicialAyuda;

  /// No description provided for @yaAlineePrimeraToma.
  ///
  /// In es, this message translates to:
  /// **'Ya alineé la primera toma'**
  String get yaAlineePrimeraToma;

  /// No description provided for @errorLeerImagen.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer la imagen.'**
  String get errorLeerImagen;

  /// No description provided for @perfilProfesionalRecorridos.
  ///
  /// In es, this message translates to:
  /// **'Los recorridos se crean desde un perfil profesional.'**
  String get perfilProfesionalRecorridos;

  /// No description provided for @borradorNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Este borrador no está disponible.'**
  String get borradorNoDisponible;

  /// No description provided for @borradorOtraCuenta.
  ///
  /// In es, this message translates to:
  /// **'Este borrador pertenece a otra cuenta.'**
  String get borradorOtraCuenta;

  /// No description provided for @borradorRecuperado.
  ///
  /// In es, this message translates to:
  /// **'Borrador recuperado del dispositivo. Conecta para sincronizar.'**
  String get borradorRecuperado;

  /// No description provided for @cambiosLocalesPendientes.
  ///
  /// In es, this message translates to:
  /// **'Hay cambios locales pendientes de sincronizar.'**
  String get cambiosLocalesPendientes;

  /// No description provided for @errorGuardarCambiosLocal.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los últimos cambios en este dispositivo.'**
  String get errorGuardarCambiosLocal;

  /// No description provided for @guardadoDispositivo.
  ///
  /// In es, this message translates to:
  /// **'Guardado en este dispositivo'**
  String get guardadoDispositivo;

  /// No description provided for @noSeGuardaronCambios.
  ///
  /// In es, this message translates to:
  /// **'No se guardaron los cambios'**
  String get noSeGuardaronCambios;

  /// No description provided for @volverIntentarCambios.
  ///
  /// In es, this message translates to:
  /// **'Puedes volver a intentarlo o salir y descartar los últimos cambios.'**
  String get volverIntentarCambios;

  /// No description provided for @volverIntentar.
  ///
  /// In es, this message translates to:
  /// **'Volver a intentar'**
  String get volverIntentar;

  /// No description provided for @descartarSalir.
  ///
  /// In es, this message translates to:
  /// **'Descartar y salir'**
  String get descartarSalir;

  /// No description provided for @errorTituloNombreLocal.
  ///
  /// In es, this message translates to:
  /// **'Escribe el título del recorrido y el nombre del local.'**
  String get errorTituloNombreLocal;

  /// No description provided for @borradorNoDisponibleSincronizar.
  ///
  /// In es, this message translates to:
  /// **'Este borrador no está disponible para sincronizar.'**
  String get borradorNoDisponibleSincronizar;

  /// No description provided for @borradorSincronizado.
  ///
  /// In es, this message translates to:
  /// **'Borrador sincronizado'**
  String get borradorSincronizado;

  /// No description provided for @nombreZona.
  ///
  /// In es, this message translates to:
  /// **'Nombre de zona'**
  String get nombreZona;

  /// No description provided for @ejemploZonas.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: Entrada, Barra, Mural o Terraza.'**
  String get ejemploZonas;

  /// No description provided for @posicionCaptura.
  ///
  /// In es, this message translates to:
  /// **'Posición de captura'**
  String get posicionCaptura;

  /// No description provided for @ejemploPosiciones.
  ///
  /// In es, this message translates to:
  /// **'Una zona puede tener varias posiciones. Por ejemplo: Frente a la barra.'**
  String get ejemploPosiciones;

  /// No description provided for @nombrePunto.
  ///
  /// In es, this message translates to:
  /// **'Nombre del punto'**
  String get nombrePunto;

  /// No description provided for @explicacionPunto.
  ///
  /// In es, this message translates to:
  /// **'Explicación del punto'**
  String get explicacionPunto;

  /// No description provided for @buscarContenido.
  ///
  /// In es, this message translates to:
  /// **'Buscar contenido'**
  String get buscarContenido;

  /// No description provided for @tiposContenidoVinculable.
  ///
  /// In es, this message translates to:
  /// **'Obras, servicios, productos de emprendimientos, publicaciones o misiones.'**
  String get tiposContenidoVinculable;

  /// No description provided for @vincularContenidoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Vincular contenido'**
  String get vincularContenidoTitulo;

  /// No description provided for @sinContenidoDisponible.
  ///
  /// In es, this message translates to:
  /// **'No encontramos contenido disponible.'**
  String get sinContenidoDisponible;

  /// No description provided for @solicitudVinculacionEnviada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de vinculación enviada al autor'**
  String get solicitudVinculacionEnviada;

  /// No description provided for @anchoFisicoCentimetros.
  ///
  /// In es, this message translates to:
  /// **'Ancho físico en centímetros'**
  String get anchoFisicoCentimetros;

  /// No description provided for @medirImagenInstalada.
  ///
  /// In es, this message translates to:
  /// **'Mide la imagen instalada. Para el distintivo, imprime a este ancho y compruébalo con una regla.'**
  String get medirImagenInstalada;

  /// No description provided for @imprimirAnchoExacto.
  ///
  /// In es, this message translates to:
  /// **'Imprimir con ancho exacto de {width} cm, sin recortar. Medir antes de probar AR.'**
  String imprimirAnchoExacto(double width);

  /// No description provided for @agregaPosicionConectar.
  ///
  /// In es, this message translates to:
  /// **'Agrega otra posición para conectarla.'**
  String get agregaPosicionConectar;

  /// No description provided for @conectarCon.
  ///
  /// In es, this message translates to:
  /// **'Conectar con'**
  String get conectarCon;

  /// No description provided for @comoLlegar.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get comoLlegar;

  /// No description provided for @ejemploIndicacion.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: Camina hacia el mural junto a la barra.'**
  String get ejemploIndicacion;

  /// No description provided for @informacion.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get informacion;

  /// No description provided for @titulo.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get titulo;

  /// No description provided for @descripcion.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get descripcion;

  /// No description provided for @categoria.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get categoria;

  /// No description provided for @disponible.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get disponible;

  /// No description provided for @precioMxnOpcional.
  ///
  /// In es, this message translates to:
  /// **'Precio en MXN (opcional)'**
  String get precioMxnOpcional;

  /// No description provided for @sinPrecioConsultar.
  ///
  /// In es, this message translates to:
  /// **'Sin precio se mostrará “Consultar precio”.'**
  String get sinPrecioConsultar;

  /// No description provided for @enlaceProyectoOpcional.
  ///
  /// In es, this message translates to:
  /// **'Enlace del proyecto (opcional)'**
  String get enlaceProyectoOpcional;

  /// No description provided for @estadoFicha.
  ///
  /// In es, this message translates to:
  /// **'Estado de la ficha'**
  String get estadoFicha;

  /// No description provided for @fichasNoDisponiblesAdministracion.
  ///
  /// In es, this message translates to:
  /// **'Las fichas no disponibles solo aparecen en tu administración.'**
  String get fichasNoDisponiblesAdministracion;

  /// No description provided for @borradoresArchivadosSoloVisibles.
  ///
  /// In es, this message translates to:
  /// **'Los borradores y las fichas archivadas solo son visibles para ti.'**
  String get borradoresArchivadosSoloVisibles;

  /// No description provided for @fotografiasCount.
  ///
  /// In es, this message translates to:
  /// **'Fotografías · {count} de 6'**
  String fotografiasCount(int count);

  /// No description provided for @moverFotografiaAntes.
  ///
  /// In es, this message translates to:
  /// **'Mover fotografía antes'**
  String get moverFotografiaAntes;

  /// No description provided for @moverFotografiaDespues.
  ///
  /// In es, this message translates to:
  /// **'Mover fotografía después'**
  String get moverFotografiaDespues;

  /// No description provided for @quitarFotografia.
  ///
  /// In es, this message translates to:
  /// **'Quitar fotografía'**
  String get quitarFotografia;

  /// No description provided for @agregarFotografia.
  ///
  /// In es, this message translates to:
  /// **'Agregar fotografía'**
  String get agregarFotografia;

  /// No description provided for @tuApartado.
  ///
  /// In es, this message translates to:
  /// **'Tu apartado'**
  String get tuApartado;

  /// No description provided for @perfilSinApartadoProfesional.
  ///
  /// In es, this message translates to:
  /// **'Este tipo de perfil no tiene un apartado profesional.'**
  String get perfilSinApartadoProfesional;

  /// No description provided for @editarFicha.
  ///
  /// In es, this message translates to:
  /// **'Editar ficha'**
  String get editarFicha;

  /// No description provided for @guardarFicha.
  ///
  /// In es, this message translates to:
  /// **'Guardar ficha'**
  String get guardarFicha;

  /// No description provided for @fichaNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Ficha no disponible.'**
  String get fichaNoDisponible;

  /// No description provided for @errorCargarFicha.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar esta ficha. Puedes reintentar.'**
  String get errorCargarFicha;

  /// No description provided for @fichaGuardada.
  ///
  /// In es, this message translates to:
  /// **'Ficha guardada.'**
  String get fichaGuardada;

  /// No description provided for @descartarCambios.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar tus cambios?'**
  String get descartarCambios;

  /// No description provided for @cambiosNoGuardados.
  ///
  /// In es, this message translates to:
  /// **'Los cambios todavía no se han guardado.'**
  String get cambiosNoGuardados;

  /// No description provided for @seguirEditando.
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get seguirEditando;

  /// No description provided for @descartar.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get descartar;

  /// No description provided for @errorPrecioInvalidoMxn.
  ///
  /// In es, this message translates to:
  /// **'Escribe un precio válido en MXN.'**
  String get errorPrecioInvalidoMxn;

  /// No description provided for @errorPrecioFicha.
  ///
  /// In es, this message translates to:
  /// **'Usa un precio válido en MXN para productos o servicios.'**
  String get errorPrecioFicha;

  /// No description provided for @errorFichaTipoPerfil.
  ///
  /// In es, this message translates to:
  /// **'Este apartado no está disponible para tu tipo de perfil.'**
  String get errorFichaTipoPerfil;

  /// No description provided for @errorTituloFicha.
  ///
  /// In es, this message translates to:
  /// **'Escribe un título de 3 a 100 caracteres.'**
  String get errorTituloFicha;

  /// No description provided for @errorDescripcionFicha.
  ///
  /// In es, this message translates to:
  /// **'Agrega una descripción de hasta 3000 caracteres.'**
  String get errorDescripcionFicha;

  /// No description provided for @errorCategoriaFicha.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría válida.'**
  String get errorCategoriaFicha;

  /// No description provided for @errorFotosFicha.
  ///
  /// In es, this message translates to:
  /// **'Elige hasta seis fotografías distintas.'**
  String get errorFotosFicha;

  /// No description provided for @errorFotoRequeridaFicha.
  ///
  /// In es, this message translates to:
  /// **'Agrega al menos una fotografía para publicar.'**
  String get errorFotoRequeridaFicha;

  /// No description provided for @errorEnlaceSoloObras.
  ///
  /// In es, this message translates to:
  /// **'El enlace de proyecto solo está disponible para obras.'**
  String get errorEnlaceSoloObras;

  /// No description provided for @errorEnlaceSeguro.
  ///
  /// In es, this message translates to:
  /// **'Usa un enlace completo y seguro, por ejemplo https://tusitio.com.'**
  String get errorEnlaceSeguro;

  /// No description provided for @sesionCambioGuardarFicha.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión cambió. Vuelve a entrar antes de guardar.'**
  String get sesionCambioGuardarFicha;

  /// No description provided for @errorGuardarFicha.
  ///
  /// In es, this message translates to:
  /// **'{error} Tus cambios siguen aquí para reintentar.'**
  String errorGuardarFicha(String error);

  /// No description provided for @tipoObraProyecto.
  ///
  /// In es, this message translates to:
  /// **'Obra / proyecto'**
  String get tipoObraProyecto;

  /// No description provided for @tipoProducto.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get tipoProducto;

  /// No description provided for @tipoServicio.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get tipoServicio;

  /// No description provided for @agregarObra.
  ///
  /// In es, this message translates to:
  /// **'Agregar obra'**
  String get agregarObra;

  /// No description provided for @agregarProducto.
  ///
  /// In es, this message translates to:
  /// **'Agregar producto'**
  String get agregarProducto;

  /// No description provided for @agregarServicio.
  ///
  /// In es, this message translates to:
  /// **'Agregar servicio'**
  String get agregarServicio;

  /// No description provided for @estadoArchivado.
  ///
  /// In es, this message translates to:
  /// **'Archivado'**
  String get estadoArchivado;

  /// No description provided for @categoriaArte.
  ///
  /// In es, this message translates to:
  /// **'Arte'**
  String get categoriaArte;

  /// No description provided for @categoriaMusica.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get categoriaMusica;

  /// No description provided for @categoriaDigital.
  ///
  /// In es, this message translates to:
  /// **'Digital'**
  String get categoriaDigital;

  /// No description provided for @categoriaGastronomia.
  ///
  /// In es, this message translates to:
  /// **'Gastronomía'**
  String get categoriaGastronomia;

  /// No description provided for @categoriaModa.
  ///
  /// In es, this message translates to:
  /// **'Moda'**
  String get categoriaModa;

  /// No description provided for @categoriaEscritura.
  ///
  /// In es, this message translates to:
  /// **'Escritura'**
  String get categoriaEscritura;

  /// No description provided for @categoriaFotografia.
  ///
  /// In es, this message translates to:
  /// **'Fotografía'**
  String get categoriaFotografia;

  /// No description provided for @categoriaDiseno.
  ///
  /// In es, this message translates to:
  /// **'Diseño'**
  String get categoriaDiseno;

  /// No description provided for @categoriaOtros.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get categoriaOtros;

  /// No description provided for @mensajes.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get mensajes;

  /// No description provided for @seleccionaConversacion.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una conversación'**
  String get seleccionaConversacion;

  /// No description provided for @sinConversaciones.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes conversaciones.'**
  String get sinConversaciones;

  /// No description provided for @solicitudEnviada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get solicitudEnviada;

  /// No description provided for @solicitudMensaje.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de mensaje'**
  String get solicitudMensaje;

  /// No description provided for @solicitudChatQuiereIniciar.
  ///
  /// In es, this message translates to:
  /// **'{name} quiere iniciar una conversación contigo. ¿Deseas aceptar la solicitud?'**
  String solicitudChatQuiereIniciar(String name);

  /// No description provided for @rechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get rechazar;

  /// No description provided for @aceptar.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get aceptar;

  /// No description provided for @solicitudEnviadaPodrasEscribir.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada. Podrás escribir cuando la otra persona acepte.'**
  String get solicitudEnviadaPodrasEscribir;

  /// No description provided for @estaPersonaQuiereConversar.
  ///
  /// In es, this message translates to:
  /// **'Esta persona quiere iniciar una conversación contigo.'**
  String get estaPersonaQuiereConversar;

  /// No description provided for @revisarSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Revisar solicitud'**
  String get revisarSolicitud;

  /// No description provided for @solicitudChatRechazada.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud de chat fue rechazada.'**
  String get solicitudChatRechazada;

  /// No description provided for @aunNoHayMensajes.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay mensajes.'**
  String get aunNoHayMensajes;

  /// No description provided for @iniciaLaConversacion.
  ///
  /// In es, this message translates to:
  /// **'Inicia la conversación.'**
  String get iniciaLaConversacion;

  /// No description provided for @escribeUnMensaje.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje'**
  String get escribeUnMensaje;

  /// No description provided for @chatBloqueadoTemporalmente.
  ///
  /// In es, this message translates to:
  /// **'Este chat está bloqueado temporalmente.'**
  String get chatBloqueadoTemporalmente;

  /// No description provided for @bloquearUsuario.
  ///
  /// In es, this message translates to:
  /// **'Bloquear usuario'**
  String get bloquearUsuario;

  /// No description provided for @reportarConversacion.
  ///
  /// In es, this message translates to:
  /// **'Reportar conversación'**
  String get reportarConversacion;

  /// No description provided for @accionRegistrada.
  ///
  /// In es, this message translates to:
  /// **'Acción registrada.'**
  String get accionRegistrada;

  /// No description provided for @estaPersona.
  ///
  /// In es, this message translates to:
  /// **'Esta persona'**
  String get estaPersona;

  /// No description provided for @chat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @verPerfil.
  ///
  /// In es, this message translates to:
  /// **'Ver perfil'**
  String get verPerfil;

  /// No description provided for @leerDetalleParada.
  ///
  /// In es, this message translates to:
  /// **'Leer detalle de la parada'**
  String get leerDetalleParada;

  /// No description provided for @siguienteParada.
  ///
  /// In es, this message translates to:
  /// **'Siguiente parada'**
  String get siguienteParada;

  /// No description provided for @saltarParada.
  ///
  /// In es, this message translates to:
  /// **'Saltar parada'**
  String get saltarParada;

  /// No description provided for @terminasteRecorrido.
  ///
  /// In es, this message translates to:
  /// **'Terminaste el recorrido. Puedes volver al perfil o explorar el local en 360°.'**
  String get terminasteRecorrido;

  /// No description provided for @listaParadas.
  ///
  /// In es, this message translates to:
  /// **'Lista de paradas'**
  String get listaParadas;

  /// No description provided for @visitada.
  ///
  /// In es, this message translates to:
  /// **'Visitada'**
  String get visitada;

  /// No description provided for @saltada.
  ///
  /// In es, this message translates to:
  /// **'Saltada'**
  String get saltada;

  /// No description provided for @pendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get pendiente;

  /// No description provided for @instruccionBuscarImagen.
  ///
  /// In es, this message translates to:
  /// **'Busca cada imagen con la fotografía de referencia y la indicación del local. La lista permite leer sin cámara.'**
  String get instruccionBuscarImagen;

  /// No description provided for @irAUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Ir a {location}'**
  String irAUbicacion(String location);

  /// No description provided for @explorarLocal.
  ///
  /// In es, this message translates to:
  /// **'Explorar el local'**
  String get explorarLocal;

  /// No description provided for @recorrido360.
  ///
  /// In es, this message translates to:
  /// **'Recorrido 360°'**
  String get recorrido360;

  /// No description provided for @tusHerramientas.
  ///
  /// In es, this message translates to:
  /// **'Tus herramientas'**
  String get tusHerramientas;

  /// No description provided for @cerrarHerramientas.
  ///
  /// In es, this message translates to:
  /// **'Cerrar herramientas'**
  String get cerrarHerramientas;

  /// No description provided for @tipoPerfilGeneral.
  ///
  /// In es, this message translates to:
  /// **'Usuario general'**
  String get tipoPerfilGeneral;

  /// No description provided for @tipoPerfilCreador.
  ///
  /// In es, this message translates to:
  /// **'Artista / creador'**
  String get tipoPerfilCreador;

  /// No description provided for @tipoPerfilEmprendedor.
  ///
  /// In es, this message translates to:
  /// **'Emprendedor'**
  String get tipoPerfilEmprendedor;

  /// No description provided for @tipoPerfilNegocio.
  ///
  /// In es, this message translates to:
  /// **'Negocio'**
  String get tipoPerfilNegocio;

  /// No description provided for @descripcionPerfilGeneral.
  ///
  /// In es, this message translates to:
  /// **'Descubre personas, guarda lo que te inspira y participa en misiones.'**
  String get descripcionPerfilGeneral;

  /// No description provided for @descripcionPerfilCreador.
  ///
  /// In es, this message translates to:
  /// **'Comparte tu portafolio y encuentra personas para crear contigo.'**
  String get descripcionPerfilCreador;

  /// No description provided for @descripcionPerfilEmprendedor.
  ///
  /// In es, this message translates to:
  /// **'Presenta tus productos y servicios y encuentra nuevas colaboraciones.'**
  String get descripcionPerfilEmprendedor;

  /// No description provided for @descripcionPerfilNegocio.
  ///
  /// In es, this message translates to:
  /// **'Presenta tus servicios, comparte tu espacio y organiza eventos.'**
  String get descripcionPerfilNegocio;

  /// No description provided for @crearPublicacionPerfil.
  ///
  /// In es, this message translates to:
  /// **'Crear publicación'**
  String get crearPublicacionPerfil;

  /// No description provided for @descripcionCrearPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Comparte con la comunidad. Elige entre los formatos de tu perfil.'**
  String get descripcionCrearPublicacion;

  /// No description provided for @crearMisionHerramientas.
  ///
  /// In es, this message translates to:
  /// **'Crear misión'**
  String get crearMisionHerramientas;

  /// No description provided for @descripcionCrearMision.
  ///
  /// In es, this message translates to:
  /// **'Todos los perfiles pueden organizar una colaboración.'**
  String get descripcionCrearMision;

  /// No description provided for @encontrarColaboraciones.
  ///
  /// In es, this message translates to:
  /// **'Encontrar colaboraciones'**
  String get encontrarColaboraciones;

  /// No description provided for @descripcionColaboraciones.
  ///
  /// In es, this message translates to:
  /// **'Misiones para tu tipo de perfil y convocatorias abiertas a todos.'**
  String get descripcionColaboraciones;

  /// No description provided for @descripcionGestionarFichas.
  ///
  /// In es, this message translates to:
  /// **'Gestiona borradores, fotografías y fichas de tu perfil.'**
  String get descripcionGestionarFichas;

  /// No description provided for @tusRecorridos360.
  ///
  /// In es, this message translates to:
  /// **'Tus recorridos 360°'**
  String get tusRecorridos360;

  /// No description provided for @descripcionTusRecorridos360.
  ///
  /// In es, this message translates to:
  /// **'Captura posiciones del local, conecta panoramas y prepara AR.'**
  String get descripcionTusRecorridos360;

  /// No description provided for @solicitudesRecorridos.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de recorridos'**
  String get solicitudesRecorridos;

  /// No description provided for @descripcionSolicitudesRecorridos.
  ///
  /// In es, this message translates to:
  /// **'Autoriza contenido y revisa propuestas.'**
  String get descripcionSolicitudesRecorridos;

  /// No description provided for @mapa.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get mapa;

  /// No description provided for @descripcionMapaMisiones.
  ///
  /// In es, this message translates to:
  /// **'Explora las misiones en el mapa.'**
  String get descripcionMapaMisiones;

  /// No description provided for @notificaciones.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificaciones;

  /// No description provided for @descripcionNotificaciones.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus avisos.'**
  String get descripcionNotificaciones;

  /// No description provided for @guardados.
  ///
  /// In es, this message translates to:
  /// **'Guardados'**
  String get guardados;

  /// No description provided for @descripcionGuardados.
  ///
  /// In es, this message translates to:
  /// **'Contenido que guardaste.'**
  String get descripcionGuardados;

  /// No description provided for @misMisiones.
  ///
  /// In es, this message translates to:
  /// **'Mis misiones'**
  String get misMisiones;

  /// No description provided for @descripcionMisMisiones.
  ///
  /// In es, this message translates to:
  /// **'Misiones de tu cuenta.'**
  String get descripcionMisMisiones;

  /// No description provided for @misPostulaciones.
  ///
  /// In es, this message translates to:
  /// **'Mis postulaciones'**
  String get misPostulaciones;

  /// No description provided for @descripcionMisPostulaciones.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus candidaturas.'**
  String get descripcionMisPostulaciones;

  /// No description provided for @guiaPerfil.
  ///
  /// In es, this message translates to:
  /// **'Guía de perfil'**
  String get guiaPerfil;

  /// No description provided for @completarPerfil.
  ///
  /// In es, this message translates to:
  /// **'Completar perfil'**
  String get completarPerfil;

  /// No description provided for @descripcionPerfilSetup.
  ///
  /// In es, this message translates to:
  /// **'Presentación, intereses y opciones de tu cuenta.'**
  String get descripcionPerfilSetup;

  /// No description provided for @datosProfesionales.
  ///
  /// In es, this message translates to:
  /// **'Datos profesionales'**
  String get datosProfesionales;

  /// No description provided for @descripcionDatosProfesionalesNegocio.
  ///
  /// In es, this message translates to:
  /// **'Edita contacto, ubicación y horarios.'**
  String get descripcionDatosProfesionalesNegocio;

  /// No description provided for @descripcionDatosProfesionalesCreador.
  ///
  /// In es, this message translates to:
  /// **'Edita contacto y disponibilidad para colaborar.'**
  String get descripcionDatosProfesionalesCreador;

  /// No description provided for @descripcionDatosProfesionales.
  ///
  /// In es, this message translates to:
  /// **'Edita la información profesional de tu perfil.'**
  String get descripcionDatosProfesionales;

  /// No description provided for @moderacion.
  ///
  /// In es, this message translates to:
  /// **'Moderación'**
  String get moderacion;

  /// No description provided for @descripcionModeracion.
  ///
  /// In es, this message translates to:
  /// **'Revisa reportes y visibilidad de contenido.'**
  String get descripcionModeracion;

  /// No description provided for @comoFuncionanMisiones.
  ///
  /// In es, this message translates to:
  /// **'Cómo funcionan las misiones'**
  String get comoFuncionanMisiones;

  /// No description provided for @ayudaOrganizarMisiones.
  ///
  /// In es, this message translates to:
  /// **'Puedes organizar misiones con cualquier tipo de perfil. Para postularte, el perfil solicitado debe coincidir con el tuyo o aceptar a todos.'**
  String get ayudaOrganizarMisiones;

  /// No description provided for @ayudaGestionarMisiones.
  ///
  /// In es, this message translates to:
  /// **'El organizador revisa y selecciona participantes. Solo él puede editar, cerrar, cancelar o finalizar su misión. La moderación de contenido requiere una cuenta administradora.'**
  String get ayudaGestionarMisiones;

  /// No description provided for @seccionPublicaciones.
  ///
  /// In es, this message translates to:
  /// **'Publicaciones'**
  String get seccionPublicaciones;

  /// No description provided for @seccionPortafolio.
  ///
  /// In es, this message translates to:
  /// **'Portafolio'**
  String get seccionPortafolio;

  /// No description provided for @seccionCatalogo.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get seccionCatalogo;

  /// No description provided for @seccionServicios.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get seccionServicios;

  /// No description provided for @opcionesPerfil.
  ///
  /// In es, this message translates to:
  /// **'Opciones del perfil'**
  String get opcionesPerfil;

  /// No description provided for @verApartadoPerfil.
  ///
  /// In es, this message translates to:
  /// **'Ver {section}'**
  String verApartadoPerfil(String section);

  /// No description provided for @cerrarMenu.
  ///
  /// In es, this message translates to:
  /// **'Cerrar menú'**
  String get cerrarMenu;

  /// No description provided for @verMisionesPerfil.
  ///
  /// In es, this message translates to:
  /// **'Ver misiones del perfil'**
  String get verMisionesPerfil;

  /// No description provided for @verPublicaciones.
  ///
  /// In es, this message translates to:
  /// **'Ver publicaciones'**
  String get verPublicaciones;

  /// No description provided for @crear.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get crear;

  /// No description provided for @crearHistoria.
  ///
  /// In es, this message translates to:
  /// **'Crear historia'**
  String get crearHistoria;

  /// No description provided for @descripcionCrearHistoria.
  ///
  /// In es, this message translates to:
  /// **'Comparte una foto o texto durante 24 horas.'**
  String get descripcionCrearHistoria;

  /// No description provided for @descripcionCrearMisionInicio.
  ///
  /// In es, this message translates to:
  /// **'Convoca a tu comunidad para hacer algo juntos.'**
  String get descripcionCrearMisionInicio;

  /// No description provided for @publicarEnInicio.
  ///
  /// In es, this message translates to:
  /// **'Publicar en Inicio'**
  String get publicarEnInicio;

  /// No description provided for @descripcionPublicarEnInicio.
  ///
  /// In es, this message translates to:
  /// **'Comparte una idea, una novedad o lo que estás creando.'**
  String get descripcionPublicarEnInicio;

  /// No description provided for @descripcionCrearRecorrido360.
  ///
  /// In es, this message translates to:
  /// **'Muestra tu local y añade puntos con AR.'**
  String get descripcionCrearRecorrido360;

  /// No description provided for @descripcionCrearFichaPerfil.
  ///
  /// In es, this message translates to:
  /// **'Para tu perfil. Publica o guarda un borrador.'**
  String get descripcionCrearFichaPerfil;

  /// No description provided for @ponTuIdeaMovimiento.
  ///
  /// In es, this message translates to:
  /// **'Pon tu idea en movimiento'**
  String get ponTuIdeaMovimiento;

  /// No description provided for @eliminarEstaFicha.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta ficha?'**
  String get eliminarEstaFicha;

  /// No description provided for @eliminarFichaAdvertencia.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará del apartado junto con sus fotografías. Esta acción no se puede deshacer.'**
  String get eliminarFichaAdvertencia;

  /// No description provided for @eliminar.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get eliminar;

  /// No description provided for @fichaEliminada.
  ///
  /// In es, this message translates to:
  /// **'Ficha eliminada.'**
  String get fichaEliminada;

  /// No description provided for @fichaTipoCategoria.
  ///
  /// In es, this message translates to:
  /// **'{itemKind} · {category}'**
  String fichaTipoCategoria(String itemKind, String category);

  /// No description provided for @consultarPrecio.
  ///
  /// In es, this message translates to:
  /// **'Consultar precio'**
  String get consultarPrecio;

  /// No description provided for @quitarDeGuardados.
  ///
  /// In es, this message translates to:
  /// **'Quitar de guardados'**
  String get quitarDeGuardados;

  /// No description provided for @verProyectoFicha.
  ///
  /// In es, this message translates to:
  /// **'Ver proyecto'**
  String get verProyectoFicha;

  /// No description provided for @reportarFicha.
  ///
  /// In es, this message translates to:
  /// **'Reportar ficha'**
  String get reportarFicha;

  /// No description provided for @motivoReporteFicha.
  ///
  /// In es, this message translates to:
  /// **'Motivo del reporte'**
  String get motivoReporteFicha;

  /// No description provided for @reporteFichaEnviado.
  ///
  /// In es, this message translates to:
  /// **'Reporte enviado.'**
  String get reporteFichaEnviado;

  /// No description provided for @reportar.
  ///
  /// In es, this message translates to:
  /// **'Reportar'**
  String get reportar;

  /// No description provided for @administrarFichaEstado.
  ///
  /// In es, this message translates to:
  /// **'Administrar ficha · {status}'**
  String administrarFichaEstado(String status);

  /// No description provided for @noDisponibleSoloAdministracion.
  ///
  /// In es, this message translates to:
  /// **'No disponible: solo aparece en tu administración.'**
  String get noDisponibleSoloAdministracion;

  /// No description provided for @ocultaPorModeracion.
  ///
  /// In es, this message translates to:
  /// **'Oculta por moderación. Editarla no cambia ese estado.'**
  String get ocultaPorModeracion;

  /// No description provided for @volverABorrador.
  ///
  /// In es, this message translates to:
  /// **'Volver a borrador'**
  String get volverABorrador;

  /// No description provided for @archivarFicha.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get archivarFicha;

  /// No description provided for @eliminarFicha.
  ///
  /// In es, this message translates to:
  /// **'Eliminar ficha'**
  String get eliminarFicha;

  /// No description provided for @ficha.
  ///
  /// In es, this message translates to:
  /// **'Ficha'**
  String get ficha;

  /// No description provided for @estaFichaNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Esta ficha ya no está disponible.'**
  String get estaFichaNoDisponible;

  /// No description provided for @contactar.
  ///
  /// In es, this message translates to:
  /// **'Contactar'**
  String get contactar;

  /// No description provided for @fotografiaAnterior.
  ///
  /// In es, this message translates to:
  /// **'Fotografía anterior'**
  String get fotografiaAnterior;

  /// No description provided for @fotografiaSiguiente.
  ///
  /// In es, this message translates to:
  /// **'Fotografía siguiente'**
  String get fotografiaSiguiente;

  /// No description provided for @verTodo.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get verTodo;

  /// No description provided for @verTodas.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get verTodas;

  /// No description provided for @contenidoNoDisponibleAhora.
  ///
  /// In es, this message translates to:
  /// **'El contenido no está disponible en este momento.'**
  String get contenidoNoDisponibleAhora;

  /// No description provided for @perfilSinContenido.
  ///
  /// In es, this message translates to:
  /// **'Este perfil aún no tiene contenido para mostrar.'**
  String get perfilSinContenido;

  /// No description provided for @misionesDestacadas.
  ///
  /// In es, this message translates to:
  /// **'Misiones destacadas'**
  String get misionesDestacadas;

  /// No description provided for @misionesNoDisponiblesAhora.
  ///
  /// In es, this message translates to:
  /// **'Las misiones no están disponibles en este momento.'**
  String get misionesNoDisponiblesAhora;

  /// No description provided for @perfilSinMisionesPublicadas.
  ///
  /// In es, this message translates to:
  /// **'Este perfil aún no ha publicado misiones.'**
  String get perfilSinMisionesPublicadas;

  /// No description provided for @misionesDelPerfil.
  ///
  /// In es, this message translates to:
  /// **'Misiones del perfil'**
  String get misionesDelPerfil;

  /// No description provided for @cerrarLista.
  ///
  /// In es, this message translates to:
  /// **'Cerrar lista'**
  String get cerrarLista;

  /// No description provided for @cargarMasMisiones.
  ///
  /// In es, this message translates to:
  /// **'Cargar más misiones'**
  String get cargarMasMisiones;

  /// No description provided for @herramientas.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get herramientas;

  /// No description provided for @agregarPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Agregar publicación'**
  String get agregarPublicacion;

  /// No description provided for @configuracion.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get configuracion;

  /// No description provided for @configuracionCuenta.
  ///
  /// In es, this message translates to:
  /// **'Configuración de tu cuenta'**
  String get configuracionCuenta;

  /// No description provided for @editarPerfil.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editarPerfil;

  /// No description provided for @solicitudChatAceptada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aceptada. Ya pueden conversar.'**
  String get solicitudChatAceptada;

  /// No description provided for @verMensajes.
  ///
  /// In es, this message translates to:
  /// **'Ver mensajes'**
  String get verMensajes;

  /// No description provided for @aceptarSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Aceptar solicitud'**
  String get aceptarSolicitud;

  /// No description provided for @solicitarChat.
  ///
  /// In es, this message translates to:
  /// **'Solicitar chat'**
  String get solicitarChat;

  /// No description provided for @cambiarFotoPortada.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto de portada'**
  String get cambiarFotoPortada;

  /// No description provided for @galeria.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get galeria;

  /// No description provided for @estilosMarea.
  ///
  /// In es, this message translates to:
  /// **'Estilos de MAREA'**
  String get estilosMarea;

  /// No description provided for @errorAbrirFotos.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir tus fotos. Inténtalo nuevamente.'**
  String get errorAbrirFotos;

  /// No description provided for @errorGuardarImagenes.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar las imágenes. Tus cambios siguen aquí para reintentar.'**
  String get errorGuardarImagenes;

  /// No description provided for @cambiarFotoPerfil.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto de perfil'**
  String get cambiarFotoPerfil;

  /// No description provided for @meMueve.
  ///
  /// In es, this message translates to:
  /// **'Me mueve'**
  String get meMueve;

  /// No description provided for @listo.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get listo;

  /// No description provided for @elegirFotoOPreset.
  ///
  /// In es, this message translates to:
  /// **'Elige una foto o usa un estilo predeterminado'**
  String get elegirFotoOPreset;

  /// No description provided for @personalizarOlitas.
  ///
  /// In es, this message translates to:
  /// **'Personalizar olitas'**
  String get personalizarOlitas;

  /// No description provided for @coloresIndependientesFoto.
  ///
  /// In es, this message translates to:
  /// **'Colores independientes de tu fotografía'**
  String get coloresIndependientesFoto;

  /// No description provided for @editarIntereses.
  ///
  /// In es, this message translates to:
  /// **'Editar intereses'**
  String get editarIntereses;

  /// No description provided for @anadirIntereses.
  ///
  /// In es, this message translates to:
  /// **'Añadir intereses'**
  String get anadirIntereses;

  /// No description provided for @opcionesImagenes.
  ///
  /// In es, this message translates to:
  /// **'Opciones de imágenes'**
  String get opcionesImagenes;

  /// No description provided for @quitarFoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get quitarFoto;

  /// No description provided for @quitarPortada.
  ///
  /// In es, this message translates to:
  /// **'Quitar portada'**
  String get quitarPortada;

  /// No description provided for @nombreCompleto.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get nombreCompleto;

  /// No description provided for @tipoPerfil.
  ///
  /// In es, this message translates to:
  /// **'Tipo de perfil'**
  String get tipoPerfil;

  /// No description provided for @ubicacion.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get ubicacion;

  /// No description provided for @agregarUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Añadir ubicación'**
  String get agregarUbicacion;

  /// No description provided for @sobreMi.
  ///
  /// In es, this message translates to:
  /// **'Sobre mí'**
  String get sobreMi;

  /// No description provided for @hintSobreMi.
  ///
  /// In es, this message translates to:
  /// **'¿Qué haces y qué te mueve?'**
  String get hintSobreMi;

  /// No description provided for @masInformacion.
  ///
  /// In es, this message translates to:
  /// **'Más información'**
  String get masInformacion;

  /// No description provided for @nombreUsuario.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get nombreUsuario;

  /// No description provided for @tipoPerfilConValor.
  ///
  /// In es, this message translates to:
  /// **'Tipo de perfil: {type}'**
  String tipoPerfilConValor(String type);

  /// No description provided for @elegidoAlCrearPerfil.
  ///
  /// In es, this message translates to:
  /// **'Elegido al crear tu perfil.'**
  String get elegidoAlCrearPerfil;

  /// No description provided for @sitioWeb.
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get sitioWeb;

  /// No description provided for @identidad.
  ///
  /// In es, this message translates to:
  /// **'Identidad'**
  String get identidad;

  /// No description provided for @profesional.
  ///
  /// In es, this message translates to:
  /// **'Profesional'**
  String get profesional;

  /// No description provided for @informacionProfesional.
  ///
  /// In es, this message translates to:
  /// **'Información profesional'**
  String get informacionProfesional;

  /// No description provided for @enlaceContacto.
  ///
  /// In es, this message translates to:
  /// **'Enlace de contacto'**
  String get enlaceContacto;

  /// No description provided for @hintEnlaceContacto.
  ///
  /// In es, this message translates to:
  /// **'https://wa.me/... o tu página de contacto'**
  String get hintEnlaceContacto;

  /// No description provided for @disponibleColaborar.
  ///
  /// In es, this message translates to:
  /// **'Disponible para colaborar'**
  String get disponibleColaborar;

  /// No description provided for @ubicacionNegocio.
  ///
  /// In es, this message translates to:
  /// **'Ubicación del negocio'**
  String get ubicacionNegocio;

  /// No description provided for @sinUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicación'**
  String get sinUbicacion;

  /// No description provided for @quitarUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Quitar ubicación'**
  String get quitarUbicacion;

  /// No description provided for @horariosSemanales.
  ///
  /// In es, this message translates to:
  /// **'Horarios semanales · hora local del negocio'**
  String get horariosSemanales;

  /// No description provided for @horariosInstruccion.
  ///
  /// In es, this message translates to:
  /// **'Usa 09:00-18:00. Escribe cerrado para un día sin atención; vacío si no quieres mostrarlo.'**
  String get horariosInstruccion;

  /// No description provided for @horarioEjemplo.
  ///
  /// In es, this message translates to:
  /// **'09:00-18:00 o cerrado'**
  String get horarioEjemplo;

  /// No description provided for @lunes.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get lunes;

  /// No description provided for @martes.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get martes;

  /// No description provided for @miercoles.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get miercoles;

  /// No description provided for @jueves.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get jueves;

  /// No description provided for @viernes.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get viernes;

  /// No description provided for @sabado.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get sabado;

  /// No description provided for @domingo.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get domingo;

  /// No description provided for @marea.
  ///
  /// In es, this message translates to:
  /// **'Marea'**
  String get marea;

  /// No description provided for @lavanda.
  ///
  /// In es, this message translates to:
  /// **'Lavanda'**
  String get lavanda;

  /// No description provided for @durazno.
  ///
  /// In es, this message translates to:
  /// **'Durazno'**
  String get durazno;

  /// No description provided for @menta.
  ///
  /// In es, this message translates to:
  /// **'Menta'**
  String get menta;

  /// No description provided for @errorCargarPerfil.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu perfil. Volver a intentarlo.'**
  String get errorCargarPerfil;

  /// No description provided for @guardarCambios.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get guardarCambios;

  /// No description provided for @accionSeccion.
  ///
  /// In es, this message translates to:
  /// **'{action} ›'**
  String accionSeccion(String action);

  /// No description provided for @misionesCompletadas.
  ///
  /// In es, this message translates to:
  /// **'Misiones completadas'**
  String get misionesCompletadas;

  /// No description provided for @valoracion.
  ///
  /// In es, this message translates to:
  /// **'Valoración'**
  String get valoracion;

  /// No description provided for @porcentajeRespuesta.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje de respuesta'**
  String get porcentajeRespuesta;

  /// No description provided for @colaboracionesLocales.
  ///
  /// In es, this message translates to:
  /// **'Colaboraciones locales'**
  String get colaboracionesLocales;

  /// No description provided for @sinDatos.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get sinDatos;

  /// No description provided for @sobreNosotros.
  ///
  /// In es, this message translates to:
  /// **'Sobre nosotros'**
  String get sobreNosotros;

  /// No description provided for @perfilSinDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Este perfil aún no ha añadido una descripción.'**
  String get perfilSinDescripcion;

  /// No description provided for @sinInteresesSeleccionados.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay intereses seleccionados.'**
  String get sinInteresesSeleccionados;

  /// No description provided for @menuPerfil.
  ///
  /// In es, this message translates to:
  /// **'Menú del perfil'**
  String get menuPerfil;

  /// No description provided for @ubicacionNoIndicada.
  ///
  /// In es, this message translates to:
  /// **'Ubicación no indicada'**
  String get ubicacionNoIndicada;

  /// No description provided for @confirmarEliminarPublicacion.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar publicación?'**
  String get confirmarEliminarPublicacion;

  /// No description provided for @eliminarPublicacionAdvertencia.
  ///
  /// In es, this message translates to:
  /// **'Se retirará de tu perfil y de los guardados de otras personas.'**
  String get eliminarPublicacionAdvertencia;

  /// No description provided for @enviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get enviar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
