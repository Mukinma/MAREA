import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';

void main() {
  for (final error in [
    'PostgrestException(code: PGRST204, message: Could not find setup_step in the schema cache)',
    'PostgrestException(code: 42703, message: column setup_step does not exist)',
    'PostgrestException(code: PGRST202, message: Could not find complete_initial_profile in the schema cache)',
  ]) {
    test('explains an outdated backend: $error', () {
      expect(
        AppFailureMapper.fromMessage(error).message,
        'El servicio de MAREA necesita actualizarse para guardar estos cambios. Tus datos siguen aquí; vuelve a intentarlo cuando esté disponible.',
      );
    });
  }
  test('maps invalid credentials to a natural Spanish message', () {
    final failure = AppFailureMapper.fromMessage('Invalid login credentials');
    expect(failure.message, 'El correo o la contraseña no son correctos.');
  });

  test('maps a duplicate username without exposing database details', () {
    final failure = AppFailureMapper.fromMessage(
      'duplicate key value violates unique constraint profiles_username_key',
    );
    expect(failure.message, 'Este nombre de usuario ya está ocupado.');
  });

  test('uses a recoverable network message for connection failures', () {
    final failure = AppFailureMapper.fromMessage('SocketException: offline');
    expect(failure.message, 'No pudimos conectarnos. Inténtalo nuevamente.');
  });

  test('recognizes a missing profile as an invalid persisted session', () {
    final failure = AppFailureMapper.fromMessage(
      'PostgrestException: PGRST116 JSON object requested, 0 rows',
    );

    expect(failure.kind, AppFailureKind.invalidSession);
    expect(
      failure.message,
      'Tu sesión ya no es válida. Inicia sesión nuevamente.',
    );
  });

  test('does not leak unknown technical errors', () {
    final failure = AppFailureMapper.fromMessage('PostgrestException 42501');
    expect(failure.message, 'Algo salió mal. Inténtalo nuevamente.');
    expect(failure.message, isNot(contains('Postgrest')));
  });
}
