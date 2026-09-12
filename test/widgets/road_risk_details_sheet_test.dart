import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rsi/models/road_risk_model.dart';
import 'package:rsi/models/road_segment_model.dart';
import 'package:rsi/widgets/road_risk/road_risk_details_sheet.dart';

final RiskAssessment _risky = RiskAssessment(
  segment: RoadSegment(
    id: 'ath-seg-07',
    name: 'Syngrou Ave (Fix)',
    area: 'Koukaki, Athens',
    points: [LatLng(37.9668, 23.7283), LatLng(37.9620, 23.7248)],
    characteristics: const RoadCharacteristics(
      speedLimitKmh: 70,
      isJunction: true,
      lighting: RoadLighting.poor,
    ),
    source: 'Mock data (development only)',
  ),
  score: 82,
  accidentCount: 5,
  fatalAccidents: 1,
  seriousAccidents: 2,
  injuries: 6,
  fatalities: 1,
  firstAccidentAt: DateTime(2023, 2, 4),
  lastAccidentAt: DateTime(2026, 7, 19),
);

final RiskAssessment _quiet = RiskAssessment(
  segment: RoadSegment(
    id: 'quiet',
    name: 'Quiet St',
    points: [LatLng(39.6640, 20.8480), LatLng(39.6628, 20.8470)],
  ),
  score: 0,
  accidentCount: 0,
  fatalAccidents: 0,
  seriousAccidents: 0,
  injuries: 0,
  fatalities: 0,
);

Future<void> _pumpSheet(WidgetTester tester, RiskAssessment assessment) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: RoadRiskDetailsSheet(assessment: assessment)),
    ),
  );
}

void main() {
  testWidgets('shows the risk level, score and the data behind it',
      (tester) async {
    await _pumpSheet(tester, _risky);

    expect(find.text('Syngrou Ave (Fix)'), findsOneWidget);
    expect(find.text('Koukaki, Athens'), findsOneWidget);
    expect(find.text('Very high risk'), findsOneWidget);
    expect(find.text('Risk Score: 82/100'), findsOneWidget);
    expect(find.text('Recorded accidents'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Fatal or serious'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4 Feb 2023 – 19 Jul 2026'), findsOneWidget);
    expect(
      find.text('70 km/h limit · Junction · Poor lighting'),
      findsOneWidget,
    );
    expect(
      find.textContaining('not a prediction of future accidents'),
      findsOneWidget,
    );
  });

  testWidgets('a road without accidents only shows the count', (tester) async {
    await _pumpSheet(tester, _quiet);

    expect(find.text('Low risk'), findsOneWidget);
    expect(find.text('Risk Score: 0/100'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    for (final label in ['Fatal or serious', 'Injured', 'Deaths', 'Period']) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });
}
