import 'package:geolocator/geolocator.dart';

/// A position on the map.
class GeoPoint {
  /// Creates a point.
  const GeoPoint(this.lat, this.lng);

  /// Latitude.
  final double lat;

  /// Longitude.
  final double lng;
}

/// The device position, asked for only when a feature needs it (PRD §11: never
/// tracked while offline).
abstract interface class LocationService {
  /// Returns the position, or null when location is off or refused.
  Future<GeoPoint?> current();
}

/// [LocationService] on the platform GPS.
class DeviceLocationService implements LocationService {
  /// Creates the service over [platform].
  DeviceLocationService([GeolocatorPlatform? platform])
    : _gps = platform ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _gps;

  @override
  Future<GeoPoint?> current() async {
    if (!await _gps.isLocationServiceEnabled()) return null;
    var permission = await _gps.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _gps.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final p = await _gps.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return GeoPoint(p.latitude, p.longitude);
  }
}
