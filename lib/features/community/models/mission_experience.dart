/// Optional work samples; the server verifies ownership of referenced fiches.
class MissionEvidence {
  const MissionEvidence({required this.title, this.showcaseId, this.url});
  final String title;
  final String? showcaseId, url;
  factory MissionEvidence.fromJson(Map<String, dynamic> json) =>
      MissionEvidence(
        title: json['title'] as String,
        showcaseId: json['showcase_id'] as String?,
        url: json['url'] as String?,
      );
  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'showcase_id': showcaseId,
    'url': url?.trim(),
  };
  String? validate() {
    if (title.trim().isEmpty || title.trim().length > 100) {
      return 'Agrega un título de hasta 100 caracteres a la muestra.';
    }
    if ((showcaseId == null) == (url == null)) {
      return 'Elige una ficha o un enlace para cada muestra.';
    }
    if (showcaseId?.trim().isEmpty == true) {
      return 'Selecciona una ficha válida.';
    }
    if (url != null) {
      final uri = Uri.tryParse(url!.trim());
      if (url!.length > 2000 ||
          uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        return 'Usa un enlace HTTPS válido.';
      }
    }
    return null;
  }
}

class MissionApplicationInput {
  const MissionApplicationInput({
    required this.message,
    required this.availabilityConfirmed,
    required this.operationId,
    this.evidence = const [],
  });
  final String message, operationId;
  final bool availabilityConfirmed;
  final List<MissionEvidence> evidence;
  String? validate() {
    if (message.trim().isEmpty || message.trim().length > 1000) {
      return 'Cuenta por qué quieres participar usando entre 1 y 1000 caracteres.';
    }
    if (!availabilityConfirmed) {
      return 'Confirma tu disponibilidad para la fecha de la misión.';
    }
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(operationId)) {
      return 'No pudimos identificar el envío. Vuelve a abrir la candidatura.';
    }
    if (evidence.length > 3) {
      return 'Puedes incluir hasta tres muestras de trabajo.';
    }
    final seen = <String>{};
    for (final sample in evidence) {
      final error = sample.validate();
      if (error != null) return error;
      if (!seen.add(sample.showcaseId ?? sample.url!.trim())) {
        return 'Cada muestra debe ser distinta.';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'message': message.trim(),
    'availability_confirmed': availabilityConfirmed,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'operation_id': operationId,
  };
}

class MissionDraft {
  const MissionDraft({
    required this.id,
    required this.data,
    required this.updatedAt,
    this.publishedMissionId,
    this.publishedAt,
  });
  final String id;
  final Map<String, dynamic> data;
  final DateTime updatedAt;
  final String? publishedMissionId;
  final DateTime? publishedAt;
  bool get isPublished => publishedAt != null || publishedMissionId != null;
  String get title => (data['title'] as String?)?.trim().isNotEmpty == true
      ? data['title'] as String
      : 'Misión sin título';
  factory MissionDraft.fromJson(Map<String, dynamic> json) => MissionDraft(
    id: json['id'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    publishedMissionId: json['published_mission_id'] as String?,
    publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
  );
}

String? validateMissionCompensation(String? type, int? cents) {
  if (type == null) {
    return cents == null ? null : 'Elige el tipo de compensación.';
  }
  if (!{'unpaid', 'negotiable', 'paid'}.contains(type)) {
    return 'Elige una compensación válida.';
  }
  if (type == 'paid') {
    if (cents == null || cents <= 0 || cents > 9999999900) {
      return 'Indica un importe positivo en MXN, con hasta dos decimales.';
    }
  } else if (cents != null) {
    return 'Solo las misiones remuneradas admiten un importe.';
  }
  return null;
}

String missionCompensationLabel(String? type, int? cents) => switch (type) {
  'unpaid' => 'Sin pago',
  'negotiable' => 'Compensación por acordar',
  'paid' when cents != null =>
    '\$${(cents / 100).toStringAsFixed(2)} MXN por participante',
  _ => 'Compensación no indicada',
};
