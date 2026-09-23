import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';

void main() {
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
