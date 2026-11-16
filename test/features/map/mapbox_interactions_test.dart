import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:marea/core/maps/mapbox_interactions.dart';

class _Style implements StylePlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Platform implements MapboxMapPlatformInterface {
  _Platform({required this.web});
  final bool web;
  final interactions = <InteractionType>[];
  @override
  final style = _Style();
  @override
  void addInteraction<T extends TypedFeaturesetFeature<FeaturesetDescriptor>>(
    TypedInteraction<T> interaction, {
    String? interactionID,
  }) {
    if (web && interaction.interactionType == InteractionType.longTap) {
      throw UnsupportedError('LongTapInteraction is not supported on web.');
    }
    interactions.add(interaction.interactionType);
  }

  @override
  void removeInteraction(String interactionID) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test(
    'web registration completes without unsupported long-tap interactions',
    () {
      final platform = _Platform(web: true);
      registerMareaPointInteractions(
        MapboxMap(platform),
        isWeb: true,
        onTap: (_) {},
        onLongTap: (_) {},
      );
      expect(platform.interactions, [InteractionType.tap]);
    },
  );
  test('native points retain both selection and tooltip interaction', () {
    final platform = _Platform(web: false);
    registerMareaPointInteractions(
      MapboxMap(platform),
      isWeb: false,
      onTap: (_) {},
      onLongTap: (_) {},
    );
    expect(platform.interactions, [
      InteractionType.tap,
      InteractionType.longTap,
    ]);
  });
}
// The facade constructor is intentionally used to replace only SDK transport.
// Production code receives its MapboxMap exclusively through onMapCreated.
// ignore_for_file: invalid_use_of_internal_member
