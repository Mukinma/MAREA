enum AppFailureKind {
  general,
  emailNotConfirmed,
  invalidSession,
  usernameTaken,
  emailAlreadyUsed,
  weakPassword,
}

class AppFailure implements Exception {
  const AppFailure(this.message, {this.kind = AppFailureKind.general});

  final String message;
  final AppFailureKind kind;

  @override
  String toString() => message;
}

abstract final class AppFailureMapper {
  static AppFailure from(Object error) => fromMessage(error.toString());

  static AppFailure fromMessage(String rawMessage) {
    final message = rawMessage.toLowerCase();
    if (message.contains('pgrst202') ||
        message.contains('pgrst204') ||
        message.contains('42703')) {
      return const AppFailure(
        'El servicio de MAREA necesita actualizarse para guardar estos cambios. Tus datos siguen aquí; vuelve a intentarlo cuando esté disponible.',
      );
    }
    if (message.contains('initial_profile_already_confirmed')) {
      return const AppFailure(
        'La elección inicial de tu perfil ya está confirmada. Actualiza la pantalla para continuar.',
      );
    }
    if (message.contains('initial_profile_required') ||
        message.contains('initial_profile_choices_required')) {
      return const AppFailure('Confirma tu tipo de perfil para continuar.');
    }
    if (message.contains('invalid_business_hours')) {
      return const AppFailure(
        'Revisa tus horarios: usa un intervalo como 09:00-18:00.',
      );
    }
    if (message.contains('showcase_kind_not_allowed')) {
      return const AppFailure(
        'Esta ficha no está disponible para tu tipo de perfil.',
      );
    }
    if (message.contains('showcase_photo_required')) {
      return const AppFailure('Agrega al menos una fotografía para publicar.');
    }
    if (message.contains('showcase_owner_required') ||
        message.contains('showcase_unavailable')) {
      return const AppFailure(
        'Esta ficha ya no está disponible para esta acción.',
      );
    }
    if (message.contains('report_showcase_unique')) {
      return const AppFailure('Ya enviaste un reporte para esta ficha.');
    }
    if (message.contains('email_address_not_authorized') ||
        message.contains('email address not authorized')) {
      return const AppFailure(
        'El servicio de correo de MAREA todavía no puede enviar a esta dirección. No necesitas cambiar tu correo; inténtalo cuando el servicio esté disponible.',
      );
    }
    if (message.contains('error sending') && message.contains('email') ||
        message.contains('smtp')) {
      return const AppFailure(
        'No pudimos solicitar el correo. El servicio de correo no está disponible; inténtalo más tarde.',
      );
    }
    if (message.contains('retry_deletion')) {
      return const AppFailure(
        'La eliminación no ha terminado. Espera a que finalice la subida de imágenes y vuelve a intentarlo. Si se interrumpió, algunos archivos pueden haberse eliminado ya.',
      );
    }
    if (message.contains('media_operation_unavailable')) {
      return const AppFailure(
        'Hay otra operación con imágenes o una eliminación en curso. Espera un momento y vuelve a intentarlo.',
      );
    }
    if (message.contains('invalid_image') || message.contains('image_size')) {
      return const AppFailure(
        'No pudimos validar la imagen. Prueba con otra más pequeña.',
      );
    }
    if (message.contains('too_many_image_drafts')) {
      return const AppFailure(
        'Hay varias imágenes pendientes de limpieza. Vuelve a intentarlo más tarde.',
      );
    }
    if (message.contains('registration_closed') ||
        message.contains('legal_acceptance_required')) {
      return const AppFailure(
        'El registro requiere los documentos legales vigentes. Actualiza la pantalla e inténtalo de nuevo.',
      );
    }
    if (message.contains('account_deletion_pending')) {
      return const AppFailure(
        'La eliminación de tu cuenta está en curso. Vuelve a Configuración para reintentar.',
      );
    }
    if (message.contains('over_email_send_rate_limit') ||
        message.contains('over_request_rate_limit') ||
        message.contains('rate limit') ||
        message.contains('429')) {
      return const AppFailure(
        'Espera un momento antes de volver a intentarlo.',
      );
    }
    if (message.contains('otp_expired') ||
        message.contains('token has expired') ||
        message.contains('invalid token')) {
      return const AppFailure('Código incorrecto o vencido.');
    }
    if (message.contains('email_not_confirmed') ||
        message.contains('email not confirmed')) {
      return const AppFailure(
        'Confirma tu correo antes de iniciar sesión. Puedes reenviar el código.',
        kind: AppFailureKind.emailNotConfirmed,
      );
    }
    if (message.contains('reauthentication') || message.contains('nonce')) {
      return const AppFailure(
        'Confirma el código de seguridad enviado a tu correo para continuar.',
      );
    }
    if (message.contains('same_password') ||
        message.contains('weak_password')) {
      return const AppFailure(
        'Elige una contraseña nueva y más segura.',
        kind: AppFailureKind.weakPassword,
      );
    }

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return const AppFailure('El correo o la contraseña no son correctos.');
    }
    if (message.contains('pgrst116')) {
      return const AppFailure(
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
        kind: AppFailureKind.invalidSession,
      );
    }
    if (message.contains('username') &&
        (message.contains('duplicate') || message.contains('unique'))) {
      return const AppFailure(
        'Este nombre de usuario ya está ocupado.',
        kind: AppFailureKind.usernameTaken,
      );
    }
    if (message.contains('user already registered') ||
        message.contains('email already')) {
      return const AppFailure(
        'Ya existe una cuenta con este correo.',
        kind: AppFailureKind.emailAlreadyUsed,
      );
    }
    if (message.contains('socketexception') ||
        message.contains('network') ||
        message.contains('failed host lookup') ||
        message.contains('connection')) {
      return const AppFailure('No pudimos conectarnos. Inténtalo nuevamente.');
    }
    if (message.contains('jwt') || message.contains('session')) {
      return const AppFailure(
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
        kind: AppFailureKind.invalidSession,
      );
    }
    return const AppFailure('Algo salió mal. Inténtalo nuevamente.');
  }
}
