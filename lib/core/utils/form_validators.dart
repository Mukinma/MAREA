abstract final class FormValidators {
  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
  );
  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9._]{3,24}$');

  static String normalizeUsername(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('@') ? normalized.substring(1) : normalized;
  }

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Escribe tu nombre.';
    if (name.length > 80) return 'Usa un nombre de máximo 80 caracteres.';
    return null;
  }

  static String? username(String? value) {
    final normalized = normalizeUsername(value ?? '');
    if (normalized.isEmpty) return 'Elige un nombre de usuario.';
    if (normalized.length < 3) return 'Usa al menos 3 caracteres.';
    if (normalized.length > 24) return 'Usa máximo 24 caracteres.';
    if (!_usernamePattern.hasMatch(normalized)) {
      return 'Usa solo letras, números, punto o guion bajo.';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value ?? '';
    if (email.isEmpty) return 'Escribe tu correo.';
    if (email != email.trim() || !_emailPattern.hasMatch(email)) {
      return 'Escribe un correo válido.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Escribe una contraseña.';
    if (password.length < 8) return 'Usa al menos 8 caracteres.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirma tu contraseña.';
    if (value != password) return 'Las contraseñas no coinciden.';
    return null;
  }

  static String? bio(String? value) {
    if ((value ?? '').length > 160) return 'Usa máximo 160 caracteres.';
    return null;
  }
}
