import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxConfiguration {
  const MapboxConfiguration({
    this.accessToken = const String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
  });
  final String accessToken;
  bool get isConfigured => accessToken.trim().startsWith('pk.');
}

bool _initialized = false;

/// Shared by the application and standalone QA entrypoints; never logs tokens.
void initializeMareaMapbox({
  MapboxConfiguration configuration = const MapboxConfiguration(),
}) {
  if (_initialized || !configuration.isConfigured) return;
  MapboxOptions.setAccessToken(configuration.accessToken.trim());
  _initialized = true;
}
