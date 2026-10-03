class MapTileConfiguration {
  const MapTileConfiguration({
    this.urlTemplate = const String.fromEnvironment(
      'MAP_TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    this.attribution = const String.fromEnvironment(
      'MAP_ATTRIBUTION',
      defaultValue: '© OpenStreetMap',
    ),
    this.attributionUrl = const String.fromEnvironment(
      'MAP_ATTRIBUTION_URL',
      defaultValue: 'https://www.openstreetmap.org/copyright',
    ),
  });
  final String urlTemplate, attribution, attributionUrl;
}
