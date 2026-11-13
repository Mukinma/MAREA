// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get inicio => 'Inicio';

  @override
  String get iniciarSesion => 'Iniciar sesión';

  @override
  String get correo => 'Correo';

  @override
  String get contrasena => 'Contraseña';

  @override
  String get mostrarContrasena => 'Mostrar contraseña';

  @override
  String get ocultarContrasena => 'Ocultar contraseña';

  @override
  String get olvideContrasena => 'Olvidé mi contraseña';

  @override
  String get entrar => 'Entrar';

  @override
  String get continuarConGoogle => 'Continuar con Google';

  @override
  String get confirmarMiCorreo => 'Confirmar mi correo';

  @override
  String get noTienesCuenta => '¿No tienes cuenta?';

  @override
  String get crearCuenta => 'Crear cuenta';

  @override
  String get revisaTuCorreo => 'Revisa tu correo';

  @override
  String get enlaceConfirmarCuenta =>
      'Te enviamos un enlace para confirmar tu cuenta.';

  @override
  String enlaceCorreoConfirmarCuenta(String email) {
    return 'Te enviamos un enlace a $email para confirmar tu cuenta.';
  }

  @override
  String get despuesConfirmarSesion =>
      'Después de confirmar, vuelve a MAREA e inicia sesión.';

  @override
  String get irIniciarSesion => 'Ir a iniciar sesión';

  @override
  String get quePerfilQuieresCrear => '¿Qué perfil quieres crear?';

  @override
  String get eligePerfil => 'Elige un perfil.';

  @override
  String get usuarioOcupado => 'Este usuario ya está ocupado.';

  @override
  String get reintentar => 'Reintentar';

  @override
  String get continuar => 'Continuar';

  @override
  String get crearCuentaAccion => 'Crear cuenta';

  @override
  String get recuperarContrasena => 'Recuperar contraseña';

  @override
  String get verificaCodigo => 'Verifica el código';

  @override
  String get verificaCorreo => 'Verifica tu correo';

  @override
  String get recuperaTuAcceso => 'Recupera tu acceso';

  @override
  String get escribeCodigoRecibiste => 'Escribe el código que recibiste.';

  @override
  String get escribeCorreoCuenta => 'Escribe el correo de tu cuenta.';

  @override
  String get usaCorreoRegistro => 'Usa el correo con el que te registraste.';

  @override
  String get errorCodigoCorreo =>
      'Escribe el código del correo (6 a 10 dígitos).';

  @override
  String get verificarCodigo => 'Verificar código';

  @override
  String get enviarCodigo => 'Enviar código';

  @override
  String get nuevaContrasena => 'Nueva contraseña';

  @override
  String get cambiarCorreo => 'Cambiar correo';

  @override
  String get cambiarContrasena => 'Cambiar contraseña';

  @override
  String get guardarContrasena => 'Guardar contraseña';

  @override
  String get contrasenaActual => 'Contraseña actual';

  @override
  String get confirmarNuevaContrasena => 'Confirmar nueva contraseña';

  @override
  String get codigoSeguridad => 'Código de seguridad';

  @override
  String get soloSiSeSolicita => 'Solo si se solicita.';

  @override
  String get enviarCodigoCorreo => 'Enviar código por correo';

  @override
  String get solicitarCambioCorreo => 'Solicitar cambio de correo';

  @override
  String get contrasenaActualizada => 'Contraseña actualizada';

  @override
  String pasoRegistro(int step) {
    return '$step de 3';
  }

  @override
  String get tuPerfil => 'Tu perfil';

  @override
  String get creaTuAcceso => 'Crea tu acceso';

  @override
  String get usuario => 'Usuario';

  @override
  String get tipoPerfilFijo => 'El tipo de perfil queda fijo.';

  @override
  String get minimoCaracteres => 'Mínimo 8 caracteres';

  @override
  String get registroNoDisponible =>
      'El registro no está disponible. Intenta de nuevo.';

  @override
  String get usarOtroCorreo => 'Usar otro correo';

  @override
  String get codigo => 'Código';

  @override
  String solicitarCodigoEn(int seconds) {
    return 'Solicitar de nuevo en ${seconds}s';
  }

  @override
  String reenviarEn(int seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get reenviarCodigo => 'Reenviar código';

  @override
  String get yaTengoCodigo => 'Ya tengo un código';

  @override
  String get codigoNoLlego => '¿No llegó? Revisa spam o reenvía el código.';

  @override
  String get recibirasCodigo =>
      'Recibirás un código si hay una cuenta con ese correo.';

  @override
  String get confirmacionCambioCorreo =>
      'El cambio necesita confirmación en tus correos. Hasta completarla seguirás usando el actual.';

  @override
  String get usaContrasenaUnica =>
      'Usa una contraseña única de al menos 8 caracteres.';

  @override
  String get escribeContrasenaActual => 'Escribe tu contraseña actual.';

  @override
  String get nuevoCorreo => 'Nuevo correo';

  @override
  String get cambiar => 'Cambiar';

  @override
  String get atras => 'Atrás';

  @override
  String get tusRecorridos => 'Tus recorridos';

  @override
  String get muestraTuLocal360 => 'Muestra tu local en 360°';

  @override
  String get capturaConectaPanoramas =>
      'Captura desde varias posiciones y conecta sus panoramas. Añade AR a los puntos que quieras reconocer en el local.';

  @override
  String get crearRecorrido => 'Crear recorrido';

  @override
  String get solicitudesRevision => 'Solicitudes y revisión';

  @override
  String get versionPublicaConserva =>
      'La versión pública se conserva mientras editas.';

  @override
  String get editarBorrador => 'Editar borrador';

  @override
  String get verRecorrido => 'Ver recorrido';

  @override
  String get reanudar => 'Reanudar';

  @override
  String get pausar => 'Pausar';

  @override
  String get todaviaSinRecorridos => 'Todavía no tienes recorridos.';

  @override
  String get autorizacionEspacioContenido =>
      'La autorización del espacio y la del contenido se revisan por separado.';

  @override
  String get sinSolicitudesPendientes => 'No hay solicitudes pendientes.';

  @override
  String get solicitud => 'Solicitud';

  @override
  String get permisoAutor => 'Permiso del autor';

  @override
  String get responsabilidadEspacio => 'Responsabilidad del espacio';

  @override
  String get publicacion => 'Publicación';

  @override
  String get panoramaNoListoPosicion =>
      'Esta posición todavía no tiene un panorama listo.';

  @override
  String get permisoEspacioRetiradoError =>
      'El permiso del espacio fue retirado. Solicita una nueva revisión para volver a publicar.';

  @override
  String get capturaSustituidaError =>
      'Esta captura fue sustituida por otra más reciente. Vuelve a la posición para continuar con la captura actual.';

  @override
  String get contenidoVinculado => 'Contenido vinculado';

  @override
  String get evidenciaNoDisponible => 'Evidencia no disponible';

  @override
  String get verVersionEnviada => 'Ver versión enviada';

  @override
  String get retirarPermisoPausar => 'Retirar permiso y pausar recorrido';

  @override
  String get retirarPermisoContenido => 'Retirar permiso del contenido';

  @override
  String get aprobar => 'Aprobar';

  @override
  String get pedirCambios => 'Pedir cambios';

  @override
  String get queDebeCorregirse => 'Qué debe corregirse';

  @override
  String get volver => 'Volver';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get guardar => 'Guardar';

  @override
  String get noPudimosAbrirPanorama => 'No pudimos abrir el panorama.';

  @override
  String get mirarArrastrando => 'Mirar arrastrando';

  @override
  String get mirarMovimientoTelefono => 'Mirar con el movimiento del teléfono';

  @override
  String get colocarPunto => 'Colocar punto';

  @override
  String get instruccionColocarPunto =>
      'Mira hacia el lugar del punto y pulsa Colocar aquí. También puedes dejarlo solo en la lista.';

  @override
  String get colocarAqui => 'Colocar aquí';

  @override
  String get explorarLocales => 'Explorar locales';

  @override
  String get conoceEspacios360 =>
      'Conoce espacios en 360° y descubre sus paradas con cámara cuando estés ahí.';

  @override
  String get buscandoUbicacion => 'Buscando tu ubicación…';

  @override
  String get descubrirCerca => 'Descubrir cerca de mí';

  @override
  String get errorUbicacion =>
      'No pudimos obtener tu ubicación. Puedes explorar la lista de locales.';

  @override
  String get ubicacionAproximada =>
      'La ubicación y dirección del local son aproximadas. Dentro, usa las fotografías e indicaciones de cada parada.';

  @override
  String get sinRecorridosDisponibles =>
      'Todavía no hay recorridos disponibles aquí.';

  @override
  String get vistaPreviaPrivada => 'Vista previa privada';

  @override
  String get compartirRecorrido => 'Compartir recorrido';

  @override
  String get zonas => 'Zonas';

  @override
  String get irAOtraPosicion => 'Ir a otra posición';

  @override
  String get finalizarVisita => 'Finalizar visita';

  @override
  String get miraAlrededor360 =>
      'Mira alrededor en 360° y cambia entre posiciones. Puedes conocer cada punto sin usar la cámara ni compartir tu ubicación.';

  @override
  String get recorridoCambio =>
      'El recorrido cambió desde tu última visita. Empieza la versión actual.';

  @override
  String get empezarVisita => 'Empezar visita';

  @override
  String get retomarVisita => 'Retomar visita';

  @override
  String get recorrerConCamara => 'Recorrer con cámara';

  @override
  String get volverPerfil => 'Volver al perfil';

  @override
  String get recorridoNoDisponible =>
      'Este recorrido no está disponible. Puede estar pausado o haber finalizado.';

  @override
  String get versionNuevaRecorrido =>
      'Este recorrido tiene una versión nueva. Al empezar se reiniciará el progreso anterior.';

  @override
  String get errorGuardarProgreso =>
      'No pudimos guardar el progreso en este dispositivo. Mantén la pantalla abierta e inténtalo de nuevo.';

  @override
  String get progresoGuardado =>
      'Progreso guardado en este dispositivo. Se sincronizará al volver a abrir el recorrido.';

  @override
  String get otraPosicion => 'otra posición';

  @override
  String get verContenido => 'Ver contenido';

  @override
  String get contenidoNoDisponible =>
      'Este contenido todavía no está disponible.';

  @override
  String get continuarRecorrido => 'Continuar recorrido';

  @override
  String get probarArEnLocal => 'Probar AR en el local';

  @override
  String get recorridoCambioParadas =>
      'El recorrido cambió. Estas paradas pertenecen a la versión actual.';

  @override
  String get arNoDisponible =>
      'AR no está disponible en este dispositivo. Puedes consultar las paradas y explorar el panorama.';

  @override
  String paradasVisitadas(int visited, int total, int skipped) {
    return '$visited de $total paradas visitadas · $skipped saltadas';
  }

  @override
  String get imagenReconocida => 'Imagen reconocida';

  @override
  String get encuadraImagenParada => 'Encuadra la imagen de esta parada';

  @override
  String get referenciaNoConfirmada =>
      'Ya no podemos confirmar la posición. Vuelve a encuadrar la referencia.';

  @override
  String get referenciaNoDisponible => 'Referencia no disponible';

  @override
  String get escanearImagen => 'Escanear esta imagen';

  @override
  String get volverLista => 'Volver a la lista';

  @override
  String get guardarPruebaReconocimiento => 'Guardar prueba de reconocimiento';

  @override
  String get pruebaGuardadaReferencia =>
      'Prueba guardada para esta referencia.';

  @override
  String get pruebaReferenciaNoConfirmada =>
      'No pudimos confirmar que la prueba se guardó para esta referencia. Mantén la imagen encuadrada y vuelve a intentarlo.';

  @override
  String get errorAbrirReferenciaParada =>
      'No pudimos abrir la referencia de esta parada.';

  @override
  String get reintentarConsultaRa => 'Reintentar consultar RA';

  @override
  String get explorarEnRa => 'Explorar en RA';

  @override
  String get eligeImagenBuscar => 'Elige la imagen que vas a buscar';

  @override
  String get sesionCambioExperiencia =>
      'La sesión cambió. Vuelve a abrir la experiencia.';

  @override
  String get tocaVerMas => 'Toca para ver más';

  @override
  String get buscaImagenReferencia =>
      'Busca la imagen de referencia. Acércate despacio y evita reflejos.';

  @override
  String get imagenReconocidaTocaTarjeta =>
      'Imagen reconocida. Toca la tarjeta.';

  @override
  String get cerrarCamara => 'Cerrar cámara';

  @override
  String get buscaImagenLugarTarjeta =>
      'Busca esta imagen en el lugar para descubrir su tarjeta.';

  @override
  String buscaParadaEn(String destination) {
    return 'Busca la parada en $destination.';
  }

  @override
  String get referenciaNoMostrar => 'No pudimos mostrar la referencia.';

  @override
  String get reintentarImagen => 'Reintentar imagen';

  @override
  String get camaraCompatibleAr =>
      'La cámara de RA necesita un teléfono compatible con ARCore o ARKit. Puedes consultar el perfil.';

  @override
  String get comprobarCompatibilidad => 'Volver a comprobar compatibilidad';

  @override
  String get preparandoCamara => 'Preparando cámara…';

  @override
  String get abrirCamara => 'Abrir cámara';

  @override
  String get volverCamara => 'Volver a cámara';

  @override
  String get misionesActivas => 'Misiones activas';

  @override
  String get sinMisionesActivasOrganizador =>
      'Este organizador no tiene Misiones activas por ahora.';

  @override
  String get consultarMasMisiones => 'Consultar más Misiones';

  @override
  String get reintentarMisiones => 'Reintentar Misiones';

  @override
  String get errorConsultarMisiones => 'No pudimos consultar las Misiones.';

  @override
  String get errorCamaraInterrumpida => 'Se interrumpió la cámara. Reintenta.';

  @override
  String get errorDescargarImagen =>
      'No pudimos descargar la imagen. Reintenta.';

  @override
  String get errorIniciarCamara => 'No pudimos iniciar la cámara.';

  @override
  String get errorIniciarCamaraAr =>
      'No pudimos iniciar la cámara AR. Puedes consultar la lista.';

  @override
  String get procesamientoEnEspera => 'Esperando procesamiento';

  @override
  String get procesandoPanorama => 'Armando tu panorama';

  @override
  String get panoramaListoRevision => 'Panorama listo para revisar';

  @override
  String get necesitamosNuevasFotografias => 'Necesitamos nuevas fotografías';

  @override
  String get procesamientoCancelado => 'Procesamiento cancelado';

  @override
  String get noPudimosProcesarPanorama => 'No pudimos procesar el panorama';

  @override
  String get volverElegirArchivoCarga =>
      'Vuelve a elegir el archivo para continuar la carga.';

  @override
  String get fotoSubidaNoConfirmada =>
      'El servidor no confirmó la fotografía completa.';

  @override
  String get raNoDisponible => 'RA no está disponible.';

  @override
  String get experienciaRaNoDisponible =>
      'Esta experiencia de RA ya no está disponible.';

  @override
  String get perfilNoDisponible => 'El perfil ya no está disponible.';

  @override
  String get estadoPublicado => 'Publicado';

  @override
  String get estadoAprobado => 'Aprobado';

  @override
  String get estadoPausado => 'Pausado';

  @override
  String get estadoEnRevision => 'En revisión';

  @override
  String get estadoRequiereCambios => 'Requiere cambios';

  @override
  String get estadoFinalizado => 'Finalizado';

  @override
  String get estadoBorrador => 'Borrador';

  @override
  String get estadoRechazado => 'Rechazado';

  @override
  String get solicitudSustituida => 'Solicitud sustituida';

  @override
  String get estadoRevocado => 'Revocado';

  @override
  String get crearRecorrido360 => 'Crear recorrido 360°';

  @override
  String get borradorNoRecuperado => 'No pudimos recuperar el borrador.';

  @override
  String get necesitasPerfilProfesional => 'Necesitas un perfil profesional.';

  @override
  String get pasoLocal => 'Local';

  @override
  String get pasoZonas => 'Zonas';

  @override
  String get pasoPuntosAr => 'Puntos y AR';

  @override
  String get pasoConexiones => 'Conexiones';

  @override
  String get pasoVistaPrevia => 'Vista previa';

  @override
  String get pasoPublicacion => 'Publicación';

  @override
  String get tituloRecorrido => 'Título del recorrido';

  @override
  String get nombreLocal => 'Nombre del local';

  @override
  String get ubicacionPublica => 'Ubicación pública';

  @override
  String get confirmarUbicacionMapa => 'Confirmar ubicación en el mapa';

  @override
  String get relacionLocal => 'Tu relación con el local';

  @override
  String get revisaraResponsabilidad =>
      'El administrador revisará la responsabilidad del espacio. No incluyas documentos sensibles.';

  @override
  String get anadirEvidenciaPrivada => 'Añadir evidencia privada del local';

  @override
  String imagenesPrivadasRevision(int count) {
    return '$count imágenes privadas para revisión';
  }

  @override
  String horarios(String hours) {
    return 'Horarios: $hours';
  }

  @override
  String contacto(String contact) {
    return 'Contacto: $contact';
  }

  @override
  String get editarDatosPerfil => 'Editar datos del perfil';

  @override
  String get zonaAgrupaPosiciones =>
      'Una zona agrupa posiciones 360°. Captura cada posición sin caminar durante las tomas.';

  @override
  String get agregarZona => 'Agregar zona';

  @override
  String get editarZona => 'Editar zona';

  @override
  String get editarNombre => 'Editar nombre';

  @override
  String get sinPanoramaListo => 'Sin panorama listo';

  @override
  String get panoramaListo => 'Panorama listo';

  @override
  String get capturarRetomar => 'Capturar / retomar';

  @override
  String get importar360 => 'Importar 360°';

  @override
  String get agregarPosicion => 'Agregar posición';

  @override
  String get revisarPuntoCambioPanorama =>
      'Revisa este punto después del cambio de panorama.';

  @override
  String get marcarEn360 => 'Marcar en 360°';

  @override
  String get explicacion => 'Explicación';

  @override
  String get editarTexto => 'Editar texto';

  @override
  String get soloEnLista => 'Solo en lista';

  @override
  String get vincularContenido => 'Vincular contenido';

  @override
  String get imagenParaAr => 'Imagen para AR';

  @override
  String get distintivoImprimible => 'Distintivo imprimible';

  @override
  String get volverProbarAr => 'Volver a probar AR';

  @override
  String get agregarPunto => 'Agregar punto';

  @override
  String get posicionInicial => 'Posición inicial';

  @override
  String get ordenZonas => 'Orden de zonas';

  @override
  String get subirZona => 'Subir zona';

  @override
  String get bajarZona => 'Bajar zona';

  @override
  String get revisarConexion => 'Revisa esta conexión';

  @override
  String get eliminarConexion => 'Eliminar conexión';

  @override
  String get conectarOtraPosicion => 'Conectar otra posición';

  @override
  String get paradasConCamara => 'Paradas con cámara';

  @override
  String get ordenRecorridoPresencial => 'Orden del recorrido presencial';

  @override
  String get subirParada => 'Subir parada';

  @override
  String get bajarParada => 'Bajar parada';

  @override
  String get revisarAntesVistaPrevia =>
      'Revisa el panorama, sus conexiones y sus puntos. Las pruebas AR se realizan en el local.';

  @override
  String get abrirVistaPreviaPrivada => 'Abrir vista previa privada';

  @override
  String get espacioAutorizado => 'Espacio: autorizado';

  @override
  String get espacioPendienteRevision => 'Espacio: pendiente de revisión';

  @override
  String get problemaAgregarPosicion360 => 'Agrega una posición 360°';

  @override
  String get problemaElegirPosicionInicial => 'Elige una posición inicial';

  @override
  String get problemaPanoramasPendientes =>
      'Espera a que todos los panoramas estén listos';

  @override
  String get problemaRevisarPuntosPanoramas =>
      'Revisa los puntos de panoramas reemplazados';

  @override
  String get problemaRevisarConexionesPanoramas =>
      'Revisa las conexiones de panoramas reemplazados';

  @override
  String version(String state) {
    return 'Versión: $state';
  }

  @override
  String get versionPublicaDisponible =>
      'La versión pública anterior seguirá disponible hasta aprobar estos cambios.';

  @override
  String get vinculosPendientes =>
      'Los vínculos pendientes no aparecerán en la versión pública.';

  @override
  String get inicioVigencia => 'Inicio de vigencia';

  @override
  String get finVigencia => 'Fin de vigencia';

  @override
  String horaDispositivo(String title) {
    return '$title · hora de este dispositivo';
  }

  @override
  String get finPosteriorInicio => 'El fin debe ser posterior al inicio.';

  @override
  String get definirVigenciaTemporal => 'Definir vigencia temporal';

  @override
  String get vigenciaPermanente => 'Vigencia permanente';

  @override
  String get publicarVersion => 'Publicar versión';

  @override
  String get enviarRevision => 'Enviar a revisión';

  @override
  String get guardando => 'Guardando…';

  @override
  String get guardarBorrador => 'Guardar borrador';

  @override
  String get continuarPaso => 'Continuar';

  @override
  String get guardandoToma => 'Guardando la toma…';

  @override
  String get esperandoOrientacionMover =>
      'Esperando orientación del teléfono. Muévelo suavemente.';

  @override
  String get posicionListaAceptar => 'Posición lista. Pulsa Aceptar toma.';

  @override
  String get mantenerTelefonoEstableMomento =>
      'Mantén el teléfono estable un momento.';

  @override
  String inclinaArribaGrados(int degrees) {
    return 'Inclina hacia arriba $degrees°';
  }

  @override
  String inclinaAbajoGrados(int degrees) {
    return 'Inclina hacia abajo $degrees°';
  }

  @override
  String giraDerechaGrados(int degrees) {
    return 'Gira $degrees° a la derecha';
  }

  @override
  String giraIzquierdaGrados(int degrees) {
    return 'Gira $degrees° a la izquierda';
  }

  @override
  String get ajustaEncuadreAlinear =>
      'Ajusta ligeramente el encuadre hasta alinear la cámara.';

  @override
  String lecturaOrientacion(
    int currentYaw,
    int currentPitch,
    int targetYaw,
    int targetPitch,
  ) {
    return 'Actual: giro $currentYaw° · inclinación $currentPitch°\nObjetivo: giro $targetYaw° · inclinación $targetPitch°';
  }

  @override
  String get aceptarToma => 'Aceptar toma';

  @override
  String get capturarPosicion360 => 'Capturar posición 360°';

  @override
  String get instruccionCapturaPanorama =>
      'Quédate en la misma posición. Gira alrededor de la lente, sin caminar, e incluye techo y piso. Evita personas identificables y objetos demasiado cerca.';

  @override
  String get panoramaProcesado => 'Panorama procesado';

  @override
  String get confirmacionRevisionPanorama =>
      'Revisé la costura, el techo y el piso sin huecos ni errores visibles.';

  @override
  String get usarPanoramaRevisado => 'Usar panorama revisado';

  @override
  String get cancelarProcesamiento => 'Cancelar procesamiento';

  @override
  String get prepararNuevaCaptura => 'Preparar nueva captura';

  @override
  String get archivoWebNoConservado =>
      'El navegador no conserva este archivo al cerrar la pantalla. Elige el panorama de nuevo para iniciar otra subida.';

  @override
  String get volverElegirPanorama => 'Volver a elegir panorama';

  @override
  String get capturaCompleta => 'Captura completa';

  @override
  String get esperandoOrientacion => 'Esperando orientación del teléfono';

  @override
  String get mantenerTelefonoEstable => 'Mantén el teléfono estable';

  @override
  String apuntarObjetivo(String yaw, String pitch) {
    return 'Apunta a $yaw° · inclinación $pitch°';
  }

  @override
  String tomasAceptadas(int count, int total) {
    return '$count de $total tomas aceptadas';
  }

  @override
  String get alinearPrimeraToma => 'Ya alineé la primera toma';

  @override
  String get repetirUltimaToma => 'Repetir última toma';

  @override
  String get empezarOtraCaptura => 'Empezar otra captura';

  @override
  String get capturasDejaranPosicion =>
      'Las tomas actuales dejarán de formar parte de esta posición. La versión publicada se conserva.';

  @override
  String get conservarTomas => 'Conservar tomas';

  @override
  String get empezarOtra => 'Empezar otra';

  @override
  String get abrirCamaraGuiada => 'Abrir cámara guiada';

  @override
  String get retomarCaptura => 'Retomar captura';

  @override
  String get importarPanoramaEsferico => 'Importar panorama esférico';

  @override
  String subiendoPorcentaje(String percent) {
    return 'Subiendo $percent %';
  }

  @override
  String get subirProcesarPanorama => 'Subir y procesar panorama';

  @override
  String get subidaWebEnCurso =>
      'Mantén esta pantalla abierta durante la subida. Si la cierras, tendrás que elegir el archivo de nuevo. El procesamiento empieza tras confirmar la subida completa.';

  @override
  String get subidaDispositivoEnCurso =>
      'Las tomas aceptadas se guardan en este dispositivo. El procesamiento empieza después de confirmar la subida completa.';

  @override
  String get proporcionEsfericaGpano =>
      'Elige una esfera equirectangular completa de proporción 2:1, con metadatos GPano.';

  @override
  String get panoramaSuperaLimite =>
      'El panorama supera 32 MB. Exporta un JPEG de menor tamaño.';

  @override
  String get sinCamaraTrasera =>
      'No hay cámara trasera disponible. Puedes importar un panorama.';

  @override
  String get errorDatosLente =>
      'No pudimos obtener los datos de la lente. Importa un panorama 360°.';

  @override
  String get mismaCamaraCaptura =>
      'Retoma con la misma cámara o empieza otra captura.';

  @override
  String get fotoNoLeida => 'No pudimos leer la fotografía.';

  @override
  String get estadoSesionCambio => 'La sesión cambió.';

  @override
  String get orientacionNoLeida =>
      'No pudimos leer la orientación. Puedes importar un panorama.';

  @override
  String get orientacionTelefonoNoLeida =>
      'No pudimos leer la orientación del teléfono. Puedes importar un panorama.';

  @override
  String get noConocemosLente =>
      'No pudimos conocer la lente. Puedes importar un panorama 360°.';

  @override
  String get lenteCambio =>
      'La lente cambió desde la primera toma. Usa la misma cámara o empieza otra captura.';

  @override
  String get demasiadasTomasLente =>
      'Esta lente requiere demasiadas tomas. Usa la cámara principal o importa una esfera completa.';

  @override
  String get alinearCapturaInicialAyuda =>
      'Vuelve al mismo lugar. Alinea la cámara con esta primera fotografía para recuperar la dirección.';

  @override
  String get yaAlineePrimeraToma => 'Ya alineé la primera toma';

  @override
  String get errorLeerImagen => 'No pudimos leer la imagen.';

  @override
  String get perfilProfesionalRecorridos =>
      'Los recorridos se crean desde un perfil profesional.';

  @override
  String get borradorNoDisponible => 'Este borrador no está disponible.';

  @override
  String get borradorOtraCuenta => 'Este borrador pertenece a otra cuenta.';

  @override
  String get borradorRecuperado =>
      'Borrador recuperado del dispositivo. Conecta para sincronizar.';

  @override
  String get cambiosLocalesPendientes =>
      'Hay cambios locales pendientes de sincronizar.';

  @override
  String get errorGuardarCambiosLocal =>
      'No pudimos guardar los últimos cambios en este dispositivo.';

  @override
  String get guardadoDispositivo => 'Guardado en este dispositivo';

  @override
  String get noSeGuardaronCambios => 'No se guardaron los cambios';

  @override
  String get volverIntentarCambios =>
      'Puedes volver a intentarlo o salir y descartar los últimos cambios.';

  @override
  String get volverIntentar => 'Volver a intentar';

  @override
  String get descartarSalir => 'Descartar y salir';

  @override
  String get errorTituloNombreLocal =>
      'Escribe el título del recorrido y el nombre del local.';

  @override
  String get borradorNoDisponibleSincronizar =>
      'Este borrador no está disponible para sincronizar.';

  @override
  String get borradorSincronizado => 'Borrador sincronizado';

  @override
  String get nombreZona => 'Nombre de zona';

  @override
  String get ejemploZonas => 'Por ejemplo: Entrada, Barra, Mural o Terraza.';

  @override
  String get posicionCaptura => 'Posición de captura';

  @override
  String get ejemploPosiciones =>
      'Una zona puede tener varias posiciones. Por ejemplo: Frente a la barra.';

  @override
  String get nombrePunto => 'Nombre del punto';

  @override
  String get explicacionPunto => 'Explicación del punto';

  @override
  String get buscarContenido => 'Buscar contenido';

  @override
  String get tiposContenidoVinculable =>
      'Obras, servicios, productos de emprendimientos, publicaciones o misiones.';

  @override
  String get vincularContenidoTitulo => 'Vincular contenido';

  @override
  String get sinContenidoDisponible => 'No encontramos contenido disponible.';

  @override
  String get solicitudVinculacionEnviada =>
      'Solicitud de vinculación enviada al autor';

  @override
  String get anchoFisicoCentimetros => 'Ancho físico en centímetros';

  @override
  String get medirImagenInstalada =>
      'Mide la imagen instalada. Para el distintivo, imprime a este ancho y compruébalo con una regla.';

  @override
  String imprimirAnchoExacto(double width) {
    return 'Imprimir con ancho exacto de $width cm, sin recortar. Medir antes de probar AR.';
  }

  @override
  String get agregaPosicionConectar => 'Agrega otra posición para conectarla.';

  @override
  String get conectarCon => 'Conectar con';

  @override
  String get comoLlegar => 'Cómo llegar';

  @override
  String get ejemploIndicacion =>
      'Por ejemplo: Camina hacia el mural junto a la barra.';

  @override
  String get informacion => 'Información';

  @override
  String get titulo => 'Título';

  @override
  String get descripcion => 'Descripción';

  @override
  String get categoria => 'Categoría';

  @override
  String get disponible => 'Disponible';

  @override
  String get precioMxnOpcional => 'Precio en MXN (opcional)';

  @override
  String get sinPrecioConsultar => 'Sin precio se mostrará “Consultar precio”.';

  @override
  String get enlaceProyectoOpcional => 'Enlace del proyecto (opcional)';

  @override
  String get estadoFicha => 'Estado de la ficha';

  @override
  String get fichasNoDisponiblesAdministracion =>
      'Las fichas no disponibles solo aparecen en tu administración.';

  @override
  String get borradoresArchivadosSoloVisibles =>
      'Los borradores y las fichas archivadas solo son visibles para ti.';

  @override
  String fotografiasCount(int count) {
    return 'Fotografías · $count de 6';
  }

  @override
  String get moverFotografiaAntes => 'Mover fotografía antes';

  @override
  String get moverFotografiaDespues => 'Mover fotografía después';

  @override
  String get quitarFotografia => 'Quitar fotografía';

  @override
  String get agregarFotografia => 'Agregar fotografía';

  @override
  String get tuApartado => 'Tu apartado';

  @override
  String get perfilSinApartadoProfesional =>
      'Este tipo de perfil no tiene un apartado profesional.';

  @override
  String get editarFicha => 'Editar ficha';

  @override
  String get guardarFicha => 'Guardar ficha';

  @override
  String get fichaNoDisponible => 'Ficha no disponible.';

  @override
  String get errorCargarFicha =>
      'No pudimos cargar esta ficha. Puedes reintentar.';

  @override
  String get fichaGuardada => 'Ficha guardada.';

  @override
  String get descartarCambios => '¿Descartar tus cambios?';

  @override
  String get cambiosNoGuardados => 'Los cambios todavía no se han guardado.';

  @override
  String get seguirEditando => 'Seguir editando';

  @override
  String get descartar => 'Descartar';

  @override
  String get errorPrecioInvalidoMxn => 'Escribe un precio válido en MXN.';

  @override
  String get errorPrecioFicha =>
      'Usa un precio válido en MXN para productos o servicios.';

  @override
  String get errorFichaTipoPerfil =>
      'Este apartado no está disponible para tu tipo de perfil.';

  @override
  String get errorTituloFicha => 'Escribe un título de 3 a 100 caracteres.';

  @override
  String get errorDescripcionFicha =>
      'Agrega una descripción de hasta 3000 caracteres.';

  @override
  String get errorCategoriaFicha => 'Elige una categoría válida.';

  @override
  String get errorFotosFicha => 'Elige hasta seis fotografías distintas.';

  @override
  String get errorFotoRequeridaFicha =>
      'Agrega al menos una fotografía para publicar.';

  @override
  String get errorEnlaceSoloObras =>
      'El enlace de proyecto solo está disponible para obras.';

  @override
  String get errorEnlaceSeguro =>
      'Usa un enlace completo y seguro, por ejemplo https://tusitio.com.';

  @override
  String get sesionCambioGuardarFicha =>
      'Tu sesión cambió. Vuelve a entrar antes de guardar.';

  @override
  String errorGuardarFicha(String error) {
    return '$error Tus cambios siguen aquí para reintentar.';
  }

  @override
  String get tipoObraProyecto => 'Obra / proyecto';

  @override
  String get tipoProducto => 'Producto';

  @override
  String get tipoServicio => 'Servicio';

  @override
  String get agregarObra => 'Agregar obra';

  @override
  String get agregarProducto => 'Agregar producto';

  @override
  String get agregarServicio => 'Agregar servicio';

  @override
  String get estadoArchivado => 'Archivado';

  @override
  String get categoriaArte => 'Arte';

  @override
  String get categoriaMusica => 'Música';

  @override
  String get categoriaDigital => 'Digital';

  @override
  String get categoriaGastronomia => 'Gastronomía';

  @override
  String get categoriaModa => 'Moda';

  @override
  String get categoriaEscritura => 'Escritura';

  @override
  String get categoriaFotografia => 'Fotografía';

  @override
  String get categoriaDiseno => 'Diseño';

  @override
  String get categoriaOtros => 'Otros';

  @override
  String get mensajes => 'Mensajes';

  @override
  String get seleccionaConversacion => 'Selecciona una conversación';

  @override
  String get sinConversaciones => 'Aún no tienes conversaciones.';

  @override
  String get solicitudEnviada => 'Solicitud enviada';

  @override
  String get solicitudMensaje => 'Solicitud de mensaje';

  @override
  String solicitudChatQuiereIniciar(String name) {
    return '$name quiere iniciar una conversación contigo. ¿Deseas aceptar la solicitud?';
  }

  @override
  String get rechazar => 'Rechazar';

  @override
  String get aceptar => 'Aceptar';

  @override
  String get solicitudEnviadaPodrasEscribir =>
      'Solicitud enviada. Podrás escribir cuando la otra persona acepte.';

  @override
  String get estaPersonaQuiereConversar =>
      'Esta persona quiere iniciar una conversación contigo.';

  @override
  String get revisarSolicitud => 'Revisar solicitud';

  @override
  String get solicitudChatRechazada => 'Esta solicitud de chat fue rechazada.';

  @override
  String get aunNoHayMensajes => 'Aún no hay mensajes.';

  @override
  String get iniciaLaConversacion => 'Inicia la conversación.';

  @override
  String get escribeUnMensaje => 'Escribe un mensaje';

  @override
  String get chatBloqueadoTemporalmente =>
      'Este chat está bloqueado temporalmente.';

  @override
  String get bloquearUsuario => 'Bloquear usuario';

  @override
  String get reportarConversacion => 'Reportar conversación';

  @override
  String get accionRegistrada => 'Acción registrada.';

  @override
  String get estaPersona => 'Esta persona';

  @override
  String get chat => 'Chat';

  @override
  String get verPerfil => 'Ver perfil';

  @override
  String get leerDetalleParada => 'Leer detalle de la parada';

  @override
  String get siguienteParada => 'Siguiente parada';

  @override
  String get saltarParada => 'Saltar parada';

  @override
  String get terminasteRecorrido =>
      'Terminaste el recorrido. Puedes volver al perfil o explorar el local en 360°.';

  @override
  String get listaParadas => 'Lista de paradas';

  @override
  String get visitada => 'Visitada';

  @override
  String get saltada => 'Saltada';

  @override
  String get pendiente => 'Pendiente';

  @override
  String get instruccionBuscarImagen =>
      'Busca cada imagen con la fotografía de referencia y la indicación del local. La lista permite leer sin cámara.';

  @override
  String irAUbicacion(String location) {
    return 'Ir a $location';
  }

  @override
  String get explorarLocal => 'Explorar el local';

  @override
  String get recorrido360 => 'Recorrido 360°';

  @override
  String get tusHerramientas => 'Tus herramientas';

  @override
  String get cerrarHerramientas => 'Cerrar herramientas';

  @override
  String get tipoPerfilGeneral => 'Usuario general';

  @override
  String get tipoPerfilCreador => 'Artista / creador';

  @override
  String get tipoPerfilEmprendedor => 'Emprendedor';

  @override
  String get tipoPerfilNegocio => 'Negocio';

  @override
  String get descripcionPerfilGeneral =>
      'Descubre personas, guarda lo que te inspira y participa en misiones.';

  @override
  String get descripcionPerfilCreador =>
      'Comparte tu portafolio y encuentra personas para crear contigo.';

  @override
  String get descripcionPerfilEmprendedor =>
      'Presenta tus productos y servicios y encuentra nuevas colaboraciones.';

  @override
  String get descripcionPerfilNegocio =>
      'Presenta tus servicios, comparte tu espacio y organiza eventos.';

  @override
  String get crearPublicacionPerfil => 'Crear publicación';

  @override
  String get descripcionCrearPublicacion =>
      'Comparte con la comunidad. Elige entre los formatos de tu perfil.';

  @override
  String get crearMisionHerramientas => 'Crear misión';

  @override
  String get descripcionCrearMision =>
      'Todos los perfiles pueden organizar una colaboración.';

  @override
  String get encontrarColaboraciones => 'Encontrar colaboraciones';

  @override
  String get descripcionColaboraciones =>
      'Misiones para tu tipo de perfil y convocatorias abiertas a todos.';

  @override
  String get descripcionGestionarFichas =>
      'Gestiona borradores, fotografías y fichas de tu perfil.';

  @override
  String get tusRecorridos360 => 'Tus recorridos 360°';

  @override
  String get descripcionTusRecorridos360 =>
      'Captura posiciones del local, conecta panoramas y prepara AR.';

  @override
  String get solicitudesRecorridos => 'Solicitudes de recorridos';

  @override
  String get descripcionSolicitudesRecorridos =>
      'Autoriza contenido y revisa propuestas.';

  @override
  String get mapa => 'Mapa';

  @override
  String get descripcionMapaMisiones => 'Explora las misiones en el mapa.';

  @override
  String get notificaciones => 'Notificaciones';

  @override
  String get descripcionNotificaciones => 'Revisa tus avisos.';

  @override
  String get guardados => 'Guardados';

  @override
  String get descripcionGuardados => 'Contenido que guardaste.';

  @override
  String get misMisiones => 'Mis misiones';

  @override
  String get descripcionMisMisiones => 'Misiones de tu cuenta.';

  @override
  String get misPostulaciones => 'Mis postulaciones';

  @override
  String get descripcionMisPostulaciones => 'Revisa tus candidaturas.';

  @override
  String get guiaPerfil => 'Guía de perfil';

  @override
  String get completarPerfil => 'Completar perfil';

  @override
  String get descripcionPerfilSetup =>
      'Presentación, intereses y opciones de tu cuenta.';

  @override
  String get datosProfesionales => 'Datos profesionales';

  @override
  String get descripcionDatosProfesionalesNegocio =>
      'Edita contacto, ubicación y horarios.';

  @override
  String get descripcionDatosProfesionalesCreador =>
      'Edita contacto y disponibilidad para colaborar.';

  @override
  String get descripcionDatosProfesionales =>
      'Edita la información profesional de tu perfil.';

  @override
  String get moderacion => 'Moderación';

  @override
  String get descripcionModeracion =>
      'Revisa reportes y visibilidad de contenido.';

  @override
  String get comoFuncionanMisiones => 'Cómo funcionan las misiones';

  @override
  String get ayudaOrganizarMisiones =>
      'Puedes organizar misiones con cualquier tipo de perfil. Para postularte, el perfil solicitado debe coincidir con el tuyo o aceptar a todos.';

  @override
  String get ayudaGestionarMisiones =>
      'El organizador revisa y selecciona participantes. Solo él puede editar, cerrar, cancelar o finalizar su misión. La moderación de contenido requiere una cuenta administradora.';

  @override
  String get seccionPublicaciones => 'Publicaciones';

  @override
  String get seccionPortafolio => 'Portafolio';

  @override
  String get seccionCatalogo => 'Catálogo';

  @override
  String get seccionServicios => 'Servicios';

  @override
  String get opcionesPerfil => 'Opciones del perfil';

  @override
  String verApartadoPerfil(String section) {
    return 'Ver $section';
  }

  @override
  String get cerrarMenu => 'Cerrar menú';

  @override
  String get verMisionesPerfil => 'Ver misiones del perfil';

  @override
  String get verPublicaciones => 'Ver publicaciones';

  @override
  String get crear => 'Crear';

  @override
  String get crearHistoria => 'Crear historia';

  @override
  String get descripcionCrearHistoria =>
      'Comparte una foto o texto durante 24 horas.';

  @override
  String get descripcionCrearMisionInicio =>
      'Convoca a tu comunidad para hacer algo juntos.';

  @override
  String get publicarEnInicio => 'Publicar en Inicio';

  @override
  String get descripcionPublicarEnInicio =>
      'Comparte una idea, una novedad o lo que estás creando.';

  @override
  String get descripcionCrearRecorrido360 =>
      'Muestra tu local y añade puntos con AR.';

  @override
  String get descripcionCrearFichaPerfil =>
      'Para tu perfil. Publica o guarda un borrador.';

  @override
  String get ponTuIdeaMovimiento => 'Pon tu idea en movimiento';

  @override
  String get eliminarEstaFicha => '¿Eliminar esta ficha?';

  @override
  String get eliminarFichaAdvertencia =>
      'Se eliminará del apartado junto con sus fotografías. Esta acción no se puede deshacer.';

  @override
  String get eliminar => 'Eliminar';

  @override
  String get fichaEliminada => 'Ficha eliminada.';

  @override
  String fichaTipoCategoria(String itemKind, String category) {
    return '$itemKind · $category';
  }

  @override
  String get consultarPrecio => 'Consultar precio';

  @override
  String get quitarDeGuardados => 'Quitar de guardados';

  @override
  String get verProyectoFicha => 'Ver proyecto';

  @override
  String get reportarFicha => 'Reportar ficha';

  @override
  String get motivoReporteFicha => 'Motivo del reporte';

  @override
  String get reporteFichaEnviado => 'Reporte enviado.';

  @override
  String get reportar => 'Reportar';

  @override
  String administrarFichaEstado(String status) {
    return 'Administrar ficha · $status';
  }

  @override
  String get noDisponibleSoloAdministracion =>
      'No disponible: solo aparece en tu administración.';

  @override
  String get ocultaPorModeracion =>
      'Oculta por moderación. Editarla no cambia ese estado.';

  @override
  String get volverABorrador => 'Volver a borrador';

  @override
  String get archivarFicha => 'Archivar';

  @override
  String get eliminarFicha => 'Eliminar ficha';

  @override
  String get ficha => 'Ficha';

  @override
  String get estaFichaNoDisponible => 'Esta ficha ya no está disponible.';

  @override
  String get contactar => 'Contactar';

  @override
  String get fotografiaAnterior => 'Fotografía anterior';

  @override
  String get fotografiaSiguiente => 'Fotografía siguiente';

  @override
  String get verTodo => 'Ver todo';

  @override
  String get verTodas => 'Ver todas';

  @override
  String get contenidoNoDisponibleAhora =>
      'El contenido no está disponible en este momento.';

  @override
  String get perfilSinContenido =>
      'Este perfil aún no tiene contenido para mostrar.';

  @override
  String get misionesDestacadas => 'Misiones destacadas';

  @override
  String get misionesNoDisponiblesAhora =>
      'Las misiones no están disponibles en este momento.';

  @override
  String get perfilSinMisionesPublicadas =>
      'Este perfil aún no ha publicado misiones.';

  @override
  String get misionesDelPerfil => 'Misiones del perfil';

  @override
  String get cerrarLista => 'Cerrar lista';

  @override
  String get cargarMasMisiones => 'Cargar más misiones';

  @override
  String get herramientas => 'Herramientas';

  @override
  String get agregarPublicacion => 'Agregar publicación';

  @override
  String get configuracion => 'Configuración';

  @override
  String get configuracionCuenta => 'Configuración de tu cuenta';

  @override
  String get editarPerfil => 'Editar perfil';

  @override
  String get solicitudChatAceptada =>
      'Solicitud aceptada. Ya pueden conversar.';

  @override
  String get verMensajes => 'Ver mensajes';

  @override
  String get aceptarSolicitud => 'Aceptar solicitud';

  @override
  String get solicitarChat => 'Solicitar chat';

  @override
  String get cambiarFotoPortada => 'Cambiar foto de portada';

  @override
  String get galeria => 'Galería';

  @override
  String get estilosMarea => 'Estilos de MAREA';

  @override
  String get errorAbrirFotos =>
      'No pudimos abrir tus fotos. Inténtalo nuevamente.';

  @override
  String get errorGuardarImagenes =>
      'No pudimos guardar las imágenes. Tus cambios siguen aquí para reintentar.';

  @override
  String get cambiarFotoPerfil => 'Cambiar foto de perfil';

  @override
  String get meMueve => 'Me mueve';

  @override
  String get listo => 'Listo';

  @override
  String get elegirFotoOPreset =>
      'Elige una foto o usa un estilo predeterminado';

  @override
  String get personalizarOlitas => 'Personalizar olitas';

  @override
  String get coloresIndependientesFoto =>
      'Colores independientes de tu fotografía';

  @override
  String get editarIntereses => 'Editar intereses';

  @override
  String get anadirIntereses => 'Añadir intereses';

  @override
  String get opcionesImagenes => 'Opciones de imágenes';

  @override
  String get quitarFoto => 'Quitar foto';

  @override
  String get quitarPortada => 'Quitar portada';

  @override
  String get nombreCompleto => 'Nombre completo';

  @override
  String get tipoPerfil => 'Tipo de perfil';

  @override
  String get ubicacion => 'Ubicación';

  @override
  String get agregarUbicacion => 'Añadir ubicación';

  @override
  String get sobreMi => 'Sobre mí';

  @override
  String get hintSobreMi => '¿Qué haces y qué te mueve?';

  @override
  String get masInformacion => 'Más información';

  @override
  String get nombreUsuario => 'Nombre de usuario';

  @override
  String tipoPerfilConValor(String type) {
    return 'Tipo de perfil: $type';
  }

  @override
  String get elegidoAlCrearPerfil => 'Elegido al crear tu perfil.';

  @override
  String get sitioWeb => 'Sitio web';

  @override
  String get identidad => 'Identidad';

  @override
  String get profesional => 'Profesional';

  @override
  String get informacionProfesional => 'Información profesional';

  @override
  String get enlaceContacto => 'Enlace de contacto';

  @override
  String get hintEnlaceContacto => 'https://wa.me/... o tu página de contacto';

  @override
  String get disponibleColaborar => 'Disponible para colaborar';

  @override
  String get ubicacionNegocio => 'Ubicación del negocio';

  @override
  String get sinUbicacion => 'Sin ubicación';

  @override
  String get quitarUbicacion => 'Quitar ubicación';

  @override
  String get horariosSemanales => 'Horarios semanales · hora local del negocio';

  @override
  String get horariosInstruccion =>
      'Usa 09:00-18:00. Escribe cerrado para un día sin atención; vacío si no quieres mostrarlo.';

  @override
  String get horarioEjemplo => '09:00-18:00 o cerrado';

  @override
  String get lunes => 'Lunes';

  @override
  String get martes => 'Martes';

  @override
  String get miercoles => 'Miércoles';

  @override
  String get jueves => 'Jueves';

  @override
  String get viernes => 'Viernes';

  @override
  String get sabado => 'Sábado';

  @override
  String get domingo => 'Domingo';

  @override
  String get marea => 'Marea';

  @override
  String get lavanda => 'Lavanda';

  @override
  String get durazno => 'Durazno';

  @override
  String get menta => 'Menta';

  @override
  String get errorCargarPerfil =>
      'No pudimos cargar tu perfil. Volver a intentarlo.';

  @override
  String get guardarCambios => 'Guardar cambios';

  @override
  String accionSeccion(String action) {
    return '$action ›';
  }

  @override
  String get misionesCompletadas => 'Misiones completadas';

  @override
  String get valoracion => 'Valoración';

  @override
  String get porcentajeRespuesta => 'Porcentaje de respuesta';

  @override
  String get colaboracionesLocales => 'Colaboraciones locales';

  @override
  String get sinDatos => 'Sin datos';

  @override
  String get sobreNosotros => 'Sobre nosotros';

  @override
  String get perfilSinDescripcion =>
      'Este perfil aún no ha añadido una descripción.';

  @override
  String get sinInteresesSeleccionados => 'Aún no hay intereses seleccionados.';

  @override
  String get menuPerfil => 'Menú del perfil';

  @override
  String get ubicacionNoIndicada => 'Ubicación no indicada';

  @override
  String get confirmarEliminarPublicacion => '¿Eliminar publicación?';

  @override
  String get eliminarPublicacionAdvertencia =>
      'Se retirará de tu perfil y de los guardados de otras personas.';

  @override
  String get enviar => 'Enviar';
}
