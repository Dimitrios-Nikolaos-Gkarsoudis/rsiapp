import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rsi/models/accident_model.dart';
import 'package:rsi/models/map_filter_model.dart';
import 'package:rsi/models/road_risk_model.dart';
import 'package:rsi/models/road_segment_model.dart';

final DateTime _now = DateTime(2026, 9, 12);

AccidentRecord _accident({
  AccidentSeverity? severity = AccidentSeverity.minor,
  DateTime? occurredAt,
}) {
  return AccidentRecord(
    id: 'a',
    location: LatLng(37.97, 23.73),
    severity: severity,
    occurredAt: occurredAt,
  );
}

RiskAssessment _road(int score) {
  return RiskAssessment(
    segment: RoadSegment(
      id: 'seg',
      name: 'Test Ave',
      points: [LatLng(37.97, 23.73), LatLng(37.98, 23.73)],
    ),
    score: score,
    accidentCount: 0,
    fatalAccidents: 0,
    seriousAccidents: 0,
    injuries: 0,
    fatalities: 0,
  );
}

void main() {
  test('defaults show everything and count no active filters', () {
    const filter = MapFilter();

    expect(filter.isDefault, isTrue);
    expect(filter.activeCount, 0);
    expect(filter.includesAccident(_accident(), _now), isTrue);
    expect(filter.includesAccident(_accident(severity: null), _now), isTrue);
    expect(filter.includesRoad(_road(90)), isTrue);
  });

  test('counts each changed filter once', () {
    final filter = const MapFilter().copyWith(
      showRoadRisk: false,
      severities: {AccidentSeverity.fatal},
      period: AccidentPeriod.lastYear,
    );

    expect(filter.activeCount, 3);
    expect(filter.isDefault, isFalse);
  });

  test('severity filter keeps only selected severities', () {
    final filter = const MapFilter().copyWith(
      severities: {AccidentSeverity.fatal, AccidentSeverity.serious},
    );

    expect(
      filter.includesAccident(
        _accident(severity: AccidentSeverity.fatal),
        _now,
      ),
      isTrue,
    );
    expect(
      filter.includesAccident(
        _accident(severity: AccidentSeverity.minor),
        _now,
      ),
      isFalse,
    );
    expect(filter.includesAccident(_accident(severity: null), _now), isFalse);
  });

  test('time period keeps recent accidents and drops undated ones', () {
    final filter = const MapFilter().copyWith(period: AccidentPeriod.lastYear);

    expect(
      filter.includesAccident(_accident(occurredAt: DateTime(2026, 3, 1)), _now),
      isTrue,
    );
    expect(
      filter.includesAccident(_accident(occurredAt: DateTime(2024, 3, 1)), _now),
      isFalse,
    );
    expect(filter.includesAccident(_accident(), _now), isFalse);
  });

  test('risk level filter keeps only selected levels', () {
    final filter = const MapFilter().copyWith(
      riskLevels: {RiskLevel.high, RiskLevel.veryHigh},
    );

    expect(filter.includesRoad(_road(80)), isTrue);
    expect(filter.includesRoad(_road(55)), isTrue);
    expect(filter.includesRoad(_road(10)), isFalse);
  });
}
