import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../services/location_service.dart';
import 'app_setup_provider.dart';

/// Continuous stream of the user's GPS coordinates.
///
/// Location is only read after the user agrees to share it (onboarding or the
/// location button); until then the stream is empty.
final locationStreamProvider = StreamProvider<ll.LatLng>((ref) {
  final useDeviceLocation = ref.watch(
    appSetupProvider.select((setup) => setup.useDeviceLocation),
  );

  if (!useDeviceLocation) {
    return const Stream<ll.LatLng>.empty();
  }

  return LocationService.getRealtimeLocationStream();
});
