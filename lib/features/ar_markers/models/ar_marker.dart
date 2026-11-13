class ArMarker {
  ArMarker(Map<String, dynamic> data) : data = Map.unmodifiable(data);

  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get ownerId => data['owner_id'] as String;
  String get name => data['name'] as String? ?? '';
  String get description => data['description'] as String? ?? '';
  String? get menuUrl => data['menu_url'] as String?;
  double get widthCm => (data['width_cm'] as num).toDouble();
  String get referenceVersion => data['reference_version'] as String;
  String? get testedVersion => data['tested_version'] as String?;
  String? get referencePath => data['reference_path'] as String?;
  double? get latitude => (data['latitude'] as num?)?.toDouble();
  double? get longitude => (data['longitude'] as num?)?.toDouble();
  bool get locationExact => data['location_exact'] == true;
  double? get locationAccuracy =>
      (data['location_accuracy'] as num?)?.toDouble();
  bool get isTested =>
      referenceVersion.isNotEmpty && testedVersion == referenceVersion;
  bool get active => data['active'] == true;
  bool get isLocal => data['storage'] == 'local' || data['is_local'] == true;
}
