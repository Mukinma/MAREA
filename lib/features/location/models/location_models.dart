import 'package:marea/features/community/models/community_models.dart';

/// Settlement metadata from the selected content point, never from the reader.
class LocationCity {
  const LocationCity({
    required this.name,
    this.region,
    this.country,
    this.countryCode,
  });
  final String name;
  final String? region, country, countryCode;
  static LocationCity? fromJson(Object? value) {
    if (value is! Map || value['name'] is! String) return null;
    final name = (value['name'] as String).trim();
    if (name.isEmpty || name.length > 120) return null;
    return LocationCity(
      name: name,
      region: value['region'] is String ? value['region'] as String : null,
      country: value['country'] is String ? value['country'] as String : null,
      countryCode: value['countryCode'] is String
          ? value['countryCode'] as String
          : null,
    );
  }

  /// Attach the point used for this resolution when persisting content metadata.
  Map<String, dynamic> toJson({PostCoordinates? coordinates}) => {
    'name': name,
    if (coordinates != null)
      'point': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
    if (region != null) 'region': region,
    if (country != null) 'country': country,
    if (countryCode != null) 'countryCode': countryCode,
  };
}

class LocationPlace {
  const LocationPlace({
    required this.label,
    required this.coordinates,
    this.city,
  });
  final String label;
  final PostCoordinates coordinates;
  final LocationCity? city;
  static LocationPlace? fromJson(Object? value) {
    if (value is! Map ||
        value['label'] is! String ||
        value['latitude'] is! num ||
        value['longitude'] is! num) {
      return null;
    }
    final coordinates = PostCoordinates(
      latitude: (value['latitude'] as num).toDouble(),
      longitude: (value['longitude'] as num).toDouble(),
      precision: PostLocationPrecision.exact,
    );
    if (!coordinates.isValid) return null;
    return LocationPlace(
      label: value['label'] as String,
      coordinates: coordinates,
      city: LocationCity.fromJson(value['city']),
    );
  }
}
