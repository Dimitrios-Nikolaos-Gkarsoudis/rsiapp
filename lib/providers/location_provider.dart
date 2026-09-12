import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../services/location_service.dart';

// Provides a continuous stream of the user's GPS coordinates
final locationStreamProvider = StreamProvider<ll.LatLng>((ref) {
  return LocationService.getRealtimeLocationStream();
});