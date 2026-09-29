import 'package:marea/features/profile/models/profile.dart';

const communityCategories = {...ProfilePreferences.interests, 'otros': 'Otros'};

enum PostKind {
  community('Comunidad', 'Comparte una idea, una pregunta o una novedad.'),
  project('Proyecto', 'Muestra tu proceso creativo y tus proyectos.'),
  product('Producto', 'Presenta un producto de tu emprendimiento.'),
  service('Servicio', 'Comparte los servicios que ofreces.'),
  space('Espacio', 'Da a conocer tu espacio y lo que ofrece.'),
  event('Evento', 'Invita a la comunidad a tu próximo evento.');

  const PostKind(this.label, this.description);
  final String label;
  final String description;
  String get value => name;

  static PostKind fromDatabase(String value) =>
      PostKind.values.firstWhere((kind) => kind.name == value);
}

extension UserCapabilities on UserType {
  List<PostKind> get postKinds => switch (this) {
    UserType.general => const [PostKind.community],
    UserType.creator => const [PostKind.community, PostKind.project],
    UserType.entrepreneur => const [
      PostKind.community,
      PostKind.product,
      PostKind.service,
    ],
    UserType.business => const [
      PostKind.community,
      PostKind.service,
      PostKind.space,
      PostKind.event,
    ],
  };

  String get headline => switch (this) {
    UserType.general => 'Encuentra tu comunidad',
    UserType.creator => 'Dale vida a tus ideas',
    UserType.entrepreneur => 'Haz crecer tu emprendimiento',
    UserType.business => 'Conecta tu negocio con la comunidad',
  };
  String get description => switch (this) {
    UserType.general =>
      'Descubre personas, guarda lo que te inspira y participa en misiones.',
    UserType.creator =>
      'Comparte tu portafolio y encuentra personas para crear contigo.',
    UserType.entrepreneur =>
      'Presenta tus productos y servicios y encuentra nuevas colaboraciones.',
    UserType.business =>
      'Presenta tus servicios, comparte tu espacio y organiza eventos.',
  };
  String get showcaseLabel => switch (this) {
    UserType.general => 'Publicaciones',
    UserType.creator => 'Portafolio',
    UserType.entrepreneur => 'Catálogo',
    UserType.business => 'Servicios',
  };
}

class CommunityProfile {
  const CommunityProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.userType,
    this.bio,
    this.website,
    this.avatarPath,
    this.coverPath,
    this.coverPreset = 'marea',
    this.contactUrl,
    this.openToCollaboration = false,
    this.location,
    this.locationLatitude,
    this.locationLongitude,
    this.locationPrecision,
    this.businessHours = const {},
  });
  final String id;
  final String fullName;
  final String username;
  final UserType userType;
  final String? bio;
  final String? website;
  final String? avatarPath, coverPath, contactUrl, location, locationPrecision;
  final String coverPreset;
  final bool openToCollaboration;
  final double? locationLatitude, locationLongitude;
  final Map<String, String?> businessHours;

  factory CommunityProfile.fromJson(Map<String, dynamic> json) =>
      CommunityProfile(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        username: json['username'] as String,
        userType: UserType.fromDatabase(json['user_type'] as String),
        bio: json['bio'] as String?,
        website: json['website'] as String?,
        avatarPath: json['avatar_path'] as String?,
        coverPath: json['cover_path'] as String?,
        coverPreset: json['cover_preset'] as String? ?? 'marea',
        contactUrl: json['contact_url'] as String?,
        openToCollaboration: json['open_to_collaboration'] as bool? ?? false,
        location: json['location'] as String?,
        locationLatitude: (json['location_latitude'] as num?)?.toDouble(),
        locationLongitude: (json['location_longitude'] as num?)?.toDouble(),
        locationPrecision: json['location_precision'] as String?,
        businessHours: Map<String, String?>.from(
          json['business_hours'] as Map? ?? {},
        ),
      );

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'M';
    return (parts.length == 1
            ? parts.first[0]
            : '${parts.first[0]}${parts.last[0]}')
        .toUpperCase();
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.kind,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.coordinates,
    this.price,
    this.imagePath,
    this.hidden = false,
  });
  final String id;
  final String authorId;
  final PostKind kind;
  final String title;
  final String body;
  final String category;
  final String? location;
  final PostCoordinates? coordinates;
  final double? price;
  final String? imagePath;
  final bool hidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
    id: json['id'] as String,
    authorId: json['author_id'] as String,
    kind: PostKind.fromDatabase(json['kind'] as String),
    title: json['title'] as String,
    body: json['body'] as String,
    category: json['category'] as String,
    location: json['location'] as String?,
    coordinates: PostCoordinates.fromJson(json),
    price: (json['price'] as num?)?.toDouble(),
    imagePath: json['image_path'] as String?,
    hidden: json['hidden'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

enum PostLocationPrecision { exact, approximate }

class PostCoordinates {
  const PostCoordinates({
    required this.latitude,
    required this.longitude,
    required this.precision,
  });

  final double latitude;
  final double longitude;
  final PostLocationPrecision precision;

  bool get isApproximate => precision == PostLocationPrecision.approximate;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  static PostCoordinates? fromJson(Map<String, dynamic> json) {
    final latitude = json['location_latitude'];
    final longitude = json['location_longitude'];
    final precision = json['location_precision'];
    if (latitude is! num ||
        longitude is! num ||
        !{'exact', 'approximate'}.contains(precision)) {
      return null;
    }
    final coordinates = PostCoordinates(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      precision: precision == 'approximate'
          ? PostLocationPrecision.approximate
          : PostLocationPrecision.exact,
    );
    return coordinates.isValid ? coordinates : null;
  }

  Map<String, dynamic> toJson() => {
    'location_latitude': latitude,
    'location_longitude': longitude,
    'location_precision': precision.name,
  };
}

class Mission {
  const Mission({
    required this.id,
    required this.authorId,
    required this.title,
    required this.body,
    required this.category,
    required this.location,
    required this.startsAt,
    required this.capacity,
    required this.createdAt,
    this.targetType,
    this.imagePath,
    this.coordinates,
    this.requirements,
    this.conditions,
    this.conditionsLockedAt,
    this.cancellationReason,
    this.acceptedCount = 0,
    this.pendingCount = 0,
    this.organizerName,
    this.organizerUsername,
    this.status = 'open',
    this.hidden = false,
  });
  final String id;
  final String authorId;
  final String title;
  final String body;
  final String category;
  final String location;
  final DateTime startsAt;
  final int capacity;
  final UserType? targetType;
  final String status;
  final bool hidden;
  final DateTime createdAt;
  final String? imagePath;
  final PostCoordinates? coordinates;
  final String? requirements;
  final String? conditions;
  final DateTime? conditionsLockedAt;
  final String? cancellationReason;
  final int acceptedCount;
  final int pendingCount;
  final String? organizerName;
  final String? organizerUsername;

  bool get isOpen => status == 'open' && !hidden;
  bool get isTerminal => status == 'cancelled' || status == 'completed';
  bool get isExpired => !startsAt.isAfter(DateTime.now());
  bool get isFull => acceptedCount >= capacity;
  int get availableSeats => (capacity - acceptedCount).clamp(0, capacity);
  bool get conditionsLocked => conditionsLockedAt != null;

  /// Mirrors the server's participation checks; the RPC remains authoritative.
  String? applicationRestriction({
    required String viewerId,
    required UserType viewerType,
    DateTime? now,
  }) {
    if (authorId == viewerId) return 'Esta es una misión que tú organizas.';
    if (hidden) return 'Esta misión está oculta por moderación.';
    if (status == 'cancelled') return 'El organizador canceló esta misión.';
    if (status == 'completed') return 'Esta misión ya finalizó.';
    if (status != 'open') return 'El organizador cerró la convocatoria.';
    if (!startsAt.isAfter(now ?? DateTime.now())) {
      return 'La fecha de esta convocatoria ya pasó.';
    }
    if (isFull) return 'Esta misión ya alcanzó su cupo.';
    if (targetType != null && targetType != viewerType) {
      return 'Esta misión busca ${targetType!.databaseValue}. Tu perfil es ${viewerType.databaseValue}.';
    }
    return null;
  }

  String get statusLabel => hidden
      ? 'Oculta por moderación'
      : isTerminal
      ? (status == 'cancelled' ? 'Cancelada' : 'Finalizada')
      : isExpired
      ? 'Convocatoria vencida'
      : status == 'open' && isFull
      ? 'Sin cupo'
      : switch (status) {
          'open' => 'Abierta',
          'closed' => 'Cerrada',
          'cancelled' => 'Cancelada',
          'completed' => 'Finalizada',
          _ => status,
        };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
    id: json['id'] as String,
    authorId: json['author_id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    category: json['category'] as String,
    location: json['location'] as String,
    startsAt: DateTime.parse(json['starts_at'] as String),
    capacity: json['capacity'] as int,
    imagePath: json['image_path'] as String?,
    coordinates: PostCoordinates.fromJson(json),
    requirements: json['requirements'] as String?,
    conditions: json['conditions'] as String?,
    conditionsLockedAt: json['conditions_locked_at'] == null
        ? null
        : DateTime.parse(json['conditions_locked_at'] as String),
    cancellationReason: json['cancellation_reason'] as String?,
    acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
    pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
    organizerName: json['organizer_name'] as String?,
    organizerUsername: json['organizer_username'] as String?,
    targetType: json['target_type'] == null
        ? null
        : UserType.fromDatabase(json['target_type'] as String),
    status: json['status'] as String,
    hidden: json['hidden'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class MissionApplication {
  const MissionApplication({
    required this.id,
    required this.missionId,
    required this.applicantId,
    required this.message,
    required this.status,
    required this.createdAt,
  });
  final String id;
  final String missionId;
  final String applicantId;
  final String message;
  final String status;
  final DateTime createdAt;

  factory MissionApplication.fromJson(Map<String, dynamic> json) =>
      MissionApplication(
        id: json['id'] as String,
        missionId: json['mission_id'] as String,
        applicantId: json['applicant_id'] as String,
        message: json['message'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ContentReport {
  const ContentReport({
    required this.id,
    required this.reporterId,
    required this.reason,
    required this.state,
    required this.createdAt,
    this.postId,
    this.missionId,
    this.showcaseId,
  });
  final String id;
  final String reporterId;
  final String? postId;
  final String? missionId;
  final String? showcaseId;
  final String reason;
  final String state;
  final DateTime createdAt;

  factory ContentReport.fromJson(Map<String, dynamic> json) => ContentReport(
    id: json['id'] as String,
    reporterId: json['reporter_id'] as String,
    postId: json['post_id'] as String?,
    missionId: json['mission_id'] as String?,
    showcaseId: json['showcase_id'] as String?,
    reason: json['reason'] as String,
    state: json['state'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class PostInput {
  const PostInput({
    required this.kind,
    required this.title,
    required this.body,
    required this.category,
    this.location,
    this.coordinates,
    this.price,
    this.imagePath,
  });
  final PostKind kind;
  final String title;
  final String body;
  final String category;
  final String? location;
  final PostCoordinates? coordinates;
  final double? price;
  final String? imagePath;

  String? validate({UserType? userType}) {
    if (userType != null && !userType.postKinds.contains(kind)) {
      return 'Este tipo de publicación no está disponible para tu perfil.';
    }
    final contentError = _contentError(title, body, category);
    if (contentError != null) return contentError;
    if ((kind == PostKind.space || kind == PostKind.event) &&
        (location?.trim().isEmpty ?? true)) {
      return 'Indica la ubicación del espacio o evento.';
    }
    if (price != null && kind != PostKind.product && kind != PostKind.service) {
      return 'Solo los productos y servicios pueden incluir un precio.';
    }
    if ((location?.trim().length ?? 0) > 180) {
      return 'La ubicación debe tener hasta 180 caracteres.';
    }
    if (coordinates != null && !coordinates!.isValid) {
      return 'La ubicación seleccionada no es válida.';
    }
    if (price != null &&
        (!price!.isFinite || price! < 0 || price! > 99999999)) {
      return 'Escribe un precio entre 0 y 99999999.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.value,
    'title': title.trim(),
    'body': body.trim(),
    'category': category,
    'location': _optionalText(location),
    if (coordinates != null) ...coordinates!.toJson(),
    if (coordinates == null) ...{
      'location_latitude': null,
      'location_longitude': null,
      'location_precision': null,
    },
    'price': price,
    'image_path': _optionalText(imagePath),
  };
}

class MissionInput {
  const MissionInput({
    required this.title,
    required this.body,
    required this.category,
    required this.location,
    required this.startsAt,
    required this.capacity,
    this.targetType,
    this.imagePath,
    this.coordinates,
    this.requirements,
    this.conditions,
  });
  final String title;
  final String body;
  final String category;
  final String location;
  final DateTime startsAt;
  final int capacity;
  final UserType? targetType;

  final String? imagePath;
  final PostCoordinates? coordinates;
  final String? requirements;
  final String? conditions;

  String? validate({DateTime? now, bool allowPast = false}) {
    final contentError = _contentError(title, body, category);
    if (contentError != null) return contentError;
    if (location.trim().isEmpty || location.trim().length > 180) {
      return 'Escribe una ubicación de hasta 180 caracteres.';
    }
    if (!allowPast && !startsAt.isAfter(now ?? DateTime.now())) {
      return 'Elige una fecha y hora futuras.';
    }
    if (coordinates != null && !coordinates!.isValid) {
      return 'La ubicación seleccionada no es válida.';
    }
    if ((requirements?.trim().length ?? 0) > 3000) {
      return 'Los requisitos deben tener hasta 3000 caracteres.';
    }
    if ((conditions?.trim().length ?? 0) > 3000) {
      return 'Las condiciones deben tener hasta 3000 caracteres.';
    }
    if (capacity < 1 || capacity > 100) {
      return 'El cupo debe estar entre 1 y 100 personas.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'body': body.trim(),
    'category': category,
    'location': location.trim(),
    'starts_at': startsAt.toUtc().toIso8601String(),
    'capacity': capacity,
    'target_type': targetType?.databaseValue,
    'image_path': _optionalText(imagePath),
    'requirements': _optionalText(requirements),
    'conditions': _optionalText(conditions),
    'location_latitude': coordinates?.latitude,
    'location_longitude': coordinates?.longitude,
    'location_precision': coordinates?.precision.name,
  };
}

String? _contentError(String title, String body, String category) {
  if (title.trim().length < 3 || title.trim().length > 100) {
    return 'El título debe tener entre 3 y 100 caracteres.';
  }
  if (body.trim().isEmpty || body.trim().length > 3000) {
    return 'La descripción debe tener entre 1 y 3000 caracteres.';
  }
  if (!communityCategories.containsKey(category)) {
    return 'Elige una categoría válida.';
  }
  return null;
}

String? _optionalText(String? value) =>
    value == null || value.trim().isEmpty ? null : value.trim();
