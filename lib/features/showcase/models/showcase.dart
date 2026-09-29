import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/community/models/community_models.dart';

enum ShowcaseKind {
  project('Obra / proyecto', 'Agregar obra'),
  product('Producto', 'Agregar producto'),
  service('Servicio', 'Agregar servicio');

  const ShowcaseKind(this.label, this.action);
  final String label, action;
}

enum ShowcaseStatus {
  draft('Borrador'),
  published('Publicado'),
  archived('Archivado');

  const ShowcaseStatus(this.label);
  final String label;
}

extension ShowcaseCapabilities on UserType {
  List<ShowcaseKind> get showcaseKinds => switch (this) {
    UserType.general => const [],
    UserType.creator => const [ShowcaseKind.project],
    UserType.entrepreneur => const [ShowcaseKind.product, ShowcaseKind.service],
    UserType.business => const [ShowcaseKind.service],
  };
}

class ShowcaseItem {
  const ShowcaseItem({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.title,
    required this.body,
    required this.category,
    required this.status,
    required this.createdAt,
    this.available = true,
    this.hidden = false,
    this.price,
    this.projectUrl,
    this.imagePaths = const [],
  });
  factory ShowcaseItem.fromJson(Map<String, dynamic> json) {
    final images = List<Map<String, dynamic>>.from(
      (json['showcase_images'] as List? ?? []).map(
        (v) => Map<String, dynamic>.from(v as Map),
      ),
    )..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return ShowcaseItem(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      kind: ShowcaseKind.values.byName(json['kind'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      status: ShowcaseStatus.values.byName(json['status'] as String),
      available: json['available'] as bool,
      hidden: json['hidden'] as bool,
      price: (json['price'] as num?)?.toDouble(),
      projectUrl: json['project_url'] as String?,
      imagePaths: images.map((v) => v['path'] as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  final String id, ownerId, title, body, category;
  final ShowcaseKind kind;
  final ShowcaseStatus status;
  final bool available, hidden;
  final double? price;
  final String? projectUrl;
  final List<String> imagePaths;
  final DateTime createdAt;
  ShowcaseInput get input => ShowcaseInput(
    kind: kind,
    title: title,
    body: body,
    category: category,
    status: status,
    available: available,
    price: price,
    projectUrl: projectUrl,
    imagePaths: imagePaths,
  );
}

class ShowcaseInput {
  const ShowcaseInput({
    required this.kind,
    required this.title,
    required this.body,
    required this.category,
    this.status = ShowcaseStatus.draft,
    this.available = true,
    this.price,
    this.projectUrl,
    this.imagePaths = const [],
  });
  final ShowcaseKind kind;
  final String title, body, category;
  final ShowcaseStatus status;
  final bool available;
  final double? price;
  final String? projectUrl;
  final List<String> imagePaths;
  String? validate({UserType? userType}) {
    if (userType != null && !userType.showcaseKinds.contains(kind)) {
      return 'Este apartado no está disponible para tu tipo de perfil.';
    }
    if (title.trim().length < 3 || title.trim().length > 100) {
      return 'Escribe un título de 3 a 100 caracteres.';
    }
    if (body.trim().length > 3000 ||
        (status == ShowcaseStatus.published && body.trim().isEmpty)) {
      return 'Agrega una descripción de hasta 3000 caracteres.';
    }
    if (!communityCategories.containsKey(category)) {
      return 'Elige una categoría válida.';
    }
    if (imagePaths.length > 6 || imagePaths.toSet().length != imagePaths.length) {
      return 'Elige hasta seis fotografías distintas.';
    }
    if (status == ShowcaseStatus.published &&
        kind != ShowcaseKind.service &&
        imagePaths.isEmpty) {
      return 'Agrega al menos una fotografía para publicar.';
    }
    if (price != null &&
        (kind == ShowcaseKind.project ||
            !price!.isFinite ||
            price! < 0 ||
            price! > 99999999)) {
      return 'Usa un precio válido en MXN para productos o servicios.';
    }
    if (projectUrl?.trim().isNotEmpty == true) {
      if (kind != ShowcaseKind.project) {
        return 'El enlace de proyecto solo está disponible para obras.';
      }
      final error = ProfilePreferences.websiteError(projectUrl);
      if (error != null) return error;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'title': title.trim(),
    'body': body.trim(),
    'category': category,
    'status': status.name,
    'available': available,
    'price': price,
    'project_url': projectUrl?.trim().isEmpty ?? true
        ? null
        : projectUrl!.trim(),
    'image_paths': imagePaths,
  };
}
