import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rsi/core/risk/risk_calculator.dart';
import 'package:rsi/models/accident_model.dart';
import 'package:rsi/models/road_risk_model.dart';
import 'package:rsi/models/road_segment_model.dart';

final DateTime _now = DateTime(2026, 9, 12);
const RiskCalculator _calculator = RiskCalculator();

// About 222 m of road running north.
final List<LatLng> _roadPoints = [
  LatLng(37.9700, 23.7300),
  LatLng(37.9720, 23.7300),
];

RoadSegment _segment({
  RoadCharacteristics characteristics = const RoadCharacteristics(),
}) {
  return RoadSegment(
    id: 'seg',
    name: 'Test Ave',
    points: _roadPoints,
    characteristics: characteristics,
  );
}

AccidentRecord _accident({
  String id = 'a',
  LatLng? location,
  AccidentSeverity severity = AccidentSeverity.minor,
  int injuries = 1,
  int fatalities = 0,
  DateTime? occurredAt,
}) {
  return AccidentRecord(
    id: id,
    location: location ?? LatLng(37.9710, 23.7300),
    severity: severity,
    injuries: injuries,
    fatalities: fatalities,
    occurredAt: occurredAt ?? DateTime(2026, 6, 1),
  );
}

int _score(RoadSegment segment, List<AccidentRecord> accidents) {
  return _calculator.assess(segment, accidents, _now).score;
}

void main() {
  group('RiskLevel.forScore', () {
    test('uses the 0–24, 25–49, 50–74 and 75–100 bands', () {
      expect(RiskLevel.forScore(0), RiskLevel.low);
      expect(RiskLevel.forScore(24), RiskLevel.low);
      expect(RiskLevel.forScore(25), RiskLevel.moderate);
      expect(RiskLevel.forScore(49), RiskLevel.moderate);
      expect(RiskLevel.forScore(50), RiskLevel.high);
      expect(RiskLevel.forScore(74), RiskLevel.high);
      expect(RiskLevel.forScore(75), RiskLevel.veryHigh);
      expect(RiskLevel.forScore(100), RiskLevel.veryHigh);
    });
  });

  group('RiskCalculator', () {
    test('a road without recorded accidents is low risk', () {
      final assessment = _calculator.assess(
        _segment(),
        const <AccidentRecord>[],
        _now,
      );

      expect(assessment.score, 0);
      expect(assessment.level, RiskLevel.low);
      expect(assessment.accidentCount, 0);
      expect(assessment.firstAccidentAt, isNull);
    });

    test('ignores accidents further away than the match distance', () {
      final assessment = _calculator.assess(
        _segment(),
        [_accident(location: LatLng(37.9710, 23.7340))], // ~350 m east
        _now,
      );

      expect(assessment.accidentCount, 0);
      expect(assessment.score, 0);
    });

    test('counts nearby accidents, casualties and the period covered', () {
      final assessment = _calculator.assess(
        _segment(),
        [
          _accident(
            id: 'fatal',
            severity: AccidentSeverity.fatal,
            injuries: 1,
            fatalities: 1,
            occurredAt: DateTime(2024, 3, 1),
          ),
          _accident(
            id: 'serious',
            severity: AccidentSeverity.serious,
            injuries: 2,
            occurredAt: DateTime(2026, 5, 1),
          ),
        ],
        _now,
      );

      expect(assessment.accidentCount, 2);
      expect(assessment.fatalAccidents, 1);
      expect(assessment.seriousAccidents, 1);
      expect(assessment.injuries, 3);
      expect(assessment.fatalities, 1);
      expect(assessment.firstAccidentAt, DateTime(2024, 3, 1));
      expect(assessment.lastAccidentAt, DateTime(2026, 5, 1));
    });

    test('more severe accidents give a higher score', () {
      final fatal = _score(_segment(), [
        _accident(severity: AccidentSeverity.fatal, fatalities: 1),
      ]);
      final damageOnly = _score(_segment(), [
        _accident(severity: AccidentSeverity.damageOnly, injuries: 0),
      ]);

      expect(fatal, greaterThan(damageOnly));
    });

    test('recent accidents weigh more than old ones', () {
      final recent = _score(_segment(), [
        _accident(occurredAt: DateTime(2026, 6, 1)),
      ]);
      final old = _score(_segment(), [
        _accident(occurredAt: DateTime(2020, 6, 1)),
      ]);

      expect(recent, greaterThan(old));
    });

    test('junctions, high speed, poor lighting and crowds raise the score', () {
      final accidents = [_accident(severity: AccidentSeverity.serious)];

      final plain = _score(_segment(), accidents);
      final risky = _score(
        _segment(
          characteristics: const RoadCharacteristics(
            speedLimitKmh: 80,
            isJunction: true,
            lighting: RoadLighting.poor,
            pedestrianActivity: PedestrianActivity.high,
          ),
        ),
        accidents,
      );

      expect(risky, greaterThan(plain));
    });

    test('the score never goes above 100', () {
      final assessment = _calculator.assess(
        _segment(),
        [
          for (var index = 0; index < 30; index++)
            _accident(
              id: 'fatal-$index',
              severity: AccidentSeverity.fatal,
              fatalities: 2,
            ),
        ],
        _now,
      );

      expect(assessment.score, 100);
      expect(assessment.level, RiskLevel.veryHigh);
    });
  });
}
