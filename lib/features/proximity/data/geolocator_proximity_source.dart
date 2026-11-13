import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marea/core/location/device_location_service.dart';

import '../models/proximity_models.dart';
import 'proximity_services.dart';

class GeolocatorProximityLocationSource implements ProximityLocationSource {
  const GeolocatorProximityLocationSource();

  LocationSettings get settings =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          intervalDuration: const Duration(seconds: 3),
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        );

  @override
  Future<void> prepare({
    required bool requestPermission,
    required bool Function() isCurrent,
  }) async {
    void checkCurrent() {
      if (!isCurrent()) {
        throw const DeviceLocationFailure(DeviceLocationFailureKind.cancelled);
      }
    }

    try {
      checkCurrent();
      final enabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 10),
      );
      checkCurrent();
      if (!enabled) {
        throw const DeviceLocationFailure(DeviceLocationFailureKind.disabled);
      }
      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 10),
      );
      checkCurrent();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 30),
        );
        checkCurrent();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const DeviceLocationFailure(
          DeviceLocationFailureKind.deniedForever,
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine &&
              !requestPermission) {
        throw DeviceLocationFailure(
          requestPermission
              ? DeviceLocationFailureKind.denied
              : DeviceLocationFailureKind.permissionRequired,
        );
      }
    } on DeviceLocationFailure {
      rethrow;
    } on TimeoutException {
      throw const DeviceLocationFailure(DeviceLocationFailureKind.timeout);
    } catch (_) {
      throw const DeviceLocationFailure(DeviceLocationFailureKind.unavailable);
    }
  }

  @override
  Stream<ProximityFix> watch() =>
      Geolocator.getPositionStream(locationSettings: settings).map(
        (position) => ProximityFix(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ),
      );
}
