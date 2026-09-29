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

  static const weekdays = {
    'mon': 'Lunes',
    'tue': 'Martes',
    'wed': 'Miércoles',
    'thu': 'Jueves',
    'fri': 'Viernes',
    'sat': 'Sábado',
    'sun': 'Domingo',
  };
  static String? hoursError(Map<String, String?> hours) {
    for (final entry in hours.entries) {
      if (!weekdays.containsKey(entry.key)) return 'Día de la semana inválido.';
      if (entry.value == null) continue;
      final match = RegExp(
        r'^([01][0-9]|2[0-3]):([0-5][0-9])-([01][0-9]|2[0-3]):([0-5][0-9])$',
      ).firstMatch(entry.value!);
      if (match == null ||
          entry.value!.substring(0, 5).compareTo(entry.value!.substring(6)) >=
              0) {
        return 'Usa un horario como 09:00-18:00, con cierre después de apertura.';
      }
    }
    return null;
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
