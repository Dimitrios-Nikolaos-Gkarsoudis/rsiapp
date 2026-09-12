import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/accident_model.dart';
import '../services/accident_service.dart';

/// Recorded accidents shown as points on the map.
final accidentCatalogProvider = FutureProvider<AccidentCatalog>((ref) {
  return AccidentService.loadCatalog();
});
