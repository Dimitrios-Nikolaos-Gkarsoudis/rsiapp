import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/rental_model.dart';
import '../services/rental_service.dart';

export 'clock_provider.dart' show clockProvider;

/// The rental catalog, loaded from the bundled mock JSON.
final rentalCatalogProvider = FutureProvider<RentalCatalog>((ref) {
  return RentalService.loadCatalog();
});
