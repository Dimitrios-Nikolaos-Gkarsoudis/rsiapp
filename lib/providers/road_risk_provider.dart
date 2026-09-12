import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/risk/risk_calculator.dart';
import '../models/road_risk_model.dart';
import '../models/road_segment_model.dart';
import '../services/road_segment_service.dart';
import 'accidents_provider.dart';
import 'clock_provider.dart';

final roadSegmentCatalogProvider = FutureProvider<RoadSegmentCatalog>((ref) {
  return RoadSegmentService.loadCatalog();
});

/// Risk level of every mapped road segment, worked out from the recorded
/// accidents near it.
final roadRiskProvider = FutureProvider<List<RiskAssessment>>((ref) async {
  final segments = await ref.watch(roadSegmentCatalogProvider.future);
  final accidents = await ref.watch(accidentCatalogProvider.future);
  final now = ref.watch(clockProvider)();

  const calculator = RiskCalculator();

  return List.unmodifiable([
    for (final segment in segments.segments)
      calculator.assess(segment, accidents.accidents, now),
  ]);
});
