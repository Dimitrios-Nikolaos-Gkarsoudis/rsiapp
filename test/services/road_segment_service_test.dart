import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/core/risk/risk_calculator.dart';
import 'package:rsi/models/road_risk_model.dart';
import 'package:rsi/services/accident_service.dart';
import 'package:rsi/services/road_segment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 12);
  const calculator = RiskCalculator();

  test('bundled mock road segments parse without skipping any', () async {
    final errors = <Object>[];

    final catalog = await RoadSegmentService.loadCatalog(
      onInvalidRecord: errors.add,
    );

    expect(errors, isEmpty);
    expect(catalog.segments.length, greaterThanOrEqualTo(20));
  });

  test('risk from the bundled accidents covers every level', () async {
    final segments = await RoadSegmentService.loadCatalog();
    final accidents = await AccidentService.loadCatalog();

    final levels = {
      for (final segment in segments.segments)
        calculator.assess(segment, accidents.accidents, now).level,
    };

    expect(levels, RiskLevel.values.toSet());
  });

  test('quiet streets without accidents are low risk', () async {
    final segments = await RoadSegmentService.loadCatalog();
    final accidents = await AccidentService.loadCatalog();
    const quietStreets = {'ath-seg-13', 'ath-seg-14', 'ioa-seg-10'};

    for (final segment in segments.segments) {
      if (!quietStreets.contains(segment.id)) continue;

      final assessment = calculator.assess(segment, accidents.accidents, now);

      expect(assessment.accidentCount, 0, reason: segment.id);
      expect(assessment.level, RiskLevel.low, reason: segment.id);
    }
  });
}
