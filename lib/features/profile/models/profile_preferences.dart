enum OnboardingStatus { pending, completed, skipped }

abstract final class ProfilePreferences {
  static const interests = {
    'arte': 'Arte',
    'musica': 'Música',
    'digital': 'Digital',
    'gastronomia': 'Gastronomía',
    'moda': 'Moda',
    'escritura': 'Escritura',
    'fotografia': 'Fotografía',
    'diseno': 'Diseño',
  };
  static const goals = {
    'inspiracion': 'Encontrar inspiración',
    'compartir': 'Compartir mis proyectos',
    'colaborar': 'Conocer y colaborar',
  };
  static const covers = {
    'marea': 'Marea',
    'lavanda': 'Lavanda',
    'durazno': 'Durazno',
    'menta': 'Menta',
  };
  static List<String> normalizeInterests(Iterable<String> values) =>
      _normalize(values, interests);
  static List<String> normalizeGoals(Iterable<String> values) =>
      _normalize(values, goals);
  static List<String> _normalize(
    Iterable<String> values,
    Map<String, String> catalog,
  ) {
    final result = values.toSet().toList();
    if (result.any((value) => !catalog.containsKey(value))) {
      throw ArgumentError('Unknown preference');
    }
    return List.unmodifiable(result);
  }

  static String? websiteError(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (value.length > 300 ||
        uri == null ||
        uri.scheme != 'https' ||
        !uri.host.contains('.') ||
        uri.userInfo.isNotEmpty ||
        RegExp(r'\s').hasMatch(value)) {
      return 'Usa un enlace completo y seguro, por ejemplo https://tusitio.com.';
    }
    return null;
  }
}
