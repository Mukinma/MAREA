import 'dart:async';
import 'package:geolocator/geolocator.dart';

enum DeviceLocationFailureKind {
  permissionRequired,
  denied,
  deniedForever,
  disabled,
  timeout,
  unavailable,
  cancelled,
}

class DeviceLocationFailure implements Exception {
  const DeviceLocationFailure(this.kind);
  final DeviceLocationFailureKind kind;
  String get message => switch (kind) {
    DeviceLocationFailureKind.permissionRequired =>
      'Usa el botón de ubicación para descubrir misiones cerca de ti.',
    DeviceLocationFailureKind.denied =>
      'Puedes seguir explorando. Permite la ubicación cuando quieras ver qué hay cerca de ti.',
    DeviceLocationFailureKind.deniedForever =>
      'Permite el acceso a tu ubicación en el navegador o en Ajustes del dispositivo.',
    DeviceLocationFailureKind.disabled =>
      'Activa el servicio de ubicación de tu dispositivo o sigue explorando el mapa.',
    DeviceLocationFailureKind.timeout =>
      'Tu ubicación tardó demasiado. Inténtalo de nuevo o explora el mapa.',
    DeviceLocationFailureKind.unavailable =>
      'No pudimos obtener tu ubicación. Revisa el permiso y el GPS, o elige el punto manualmente.',
    DeviceLocationFailureKind.cancelled => '',
  };
  @override
  String toString() => message;
}

class DevicePosition {
  const DevicePosition({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
  });
  final double latitude, longitude, accuracy;
}

abstract interface class DeviceLocationService {
  Future<DevicePosition> current({
    bool requestPermission = false,
    bool Function()? isCurrent,
  });
  Future<bool> openSettings({bool locationDisabled = false});
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  const GeolocatorDeviceLocationService({
    this.positionTimeout = const Duration(seconds: 15),
  });
  final Duration positionTimeout;
  @override
  Future<DevicePosition> current({
    bool requestPermission = false,
    bool Function()? isCurrent,
  }) async {
    void checkOwner() {
      if (isCurrent != null && !isCurrent()) {
        throw const DeviceLocationFailure(DeviceLocationFailureKind.cancelled);
      }
    }

    try {
      checkOwner();
      final enabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 10),
      );
      checkOwner();
      if (!enabled) {
        throw const DeviceLocationFailure(DeviceLocationFailureKind.disabled);
      }
      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 10),
      );
      checkOwner();
      if (permission == LocationPermission.deniedForever) {
        throw const DeviceLocationFailure(
          DeviceLocationFailureKind.deniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        if (!requestPermission) {
          throw const DeviceLocationFailure(
            DeviceLocationFailureKind.permissionRequired,
          );
        }
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 30),
        );
        checkOwner();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const DeviceLocationFailure(
          DeviceLocationFailureKind.deniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        throw const DeviceLocationFailure(DeviceLocationFailureKind.denied);
      }
      // Some web browsers cannot check permissions. Do not implicitly prompt.
      if (permission == LocationPermission.unableToDetermine &&
          !requestPermission) {
        throw const DeviceLocationFailure(
          DeviceLocationFailureKind.permissionRequired,
        );
      }
      final fix = await Geolocator.getCurrentPosition().timeout(
        positionTimeout,
      );
      checkOwner();
      if (!fix.latitude.isFinite ||
          !fix.longitude.isFinite ||
          fix.latitude < -90 ||
          fix.latitude > 90 ||
          fix.longitude < -180 ||
          fix.longitude > 180) {
        throw const DeviceLocationFailure(
          DeviceLocationFailureKind.unavailable,
        );
      }
      return DevicePosition(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracy: fix.accuracy,
      );
    } on DeviceLocationFailure {
      rethrow;
    } on TimeoutException {
      throw const DeviceLocationFailure(DeviceLocationFailureKind.timeout);
    } catch (error) {
      final denied = error.toString().toLowerCase().contains('permission');
      throw DeviceLocationFailure(
        denied
            ? DeviceLocationFailureKind.denied
            : DeviceLocationFailureKind.unavailable,
      );
    }
  }

  @override
  Future<bool> openSettings({bool locationDisabled = false}) async {
    try {
      return locationDisabled
          ? await Geolocator.openLocationSettings()
          : await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
