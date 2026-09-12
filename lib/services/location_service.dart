import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Checks and requests device location permissions
  static Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Returns a continuous stream of real-time GPS position updates from device hardware
  static Stream<LatLng> getRealtimeLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // High precision for navigation
      distanceFilter: 5,             // Only emit updates when moved by 5+ meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((Position pos) => LatLng(pos.latitude, pos.longitude));
  }
}