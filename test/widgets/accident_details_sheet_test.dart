import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rsi/models/accident_model.dart';
import 'package:rsi/widgets/accidents/accident_details_sheet.dart';

final AccidentRecord _complete = AccidentRecord(
  id: 'ath-001',
  location: LatLng(37.9645, 23.7265),
  occurredAt: DateTime(2025, 11, 3, 18, 40),
  locationName: 'Syngrou Ave (Fix)',
  area: 'Koukaki, Athens',
  severity: AccidentSeverity.serious,
  injuries: 2,
  fatalities: 0,
  type: AccidentType.rearEnd,
  cause: 'Speeding',
  source: 'Mock data (development only)',
);

final AccidentRecord _sparse = AccidentRecord(
  id: 'ioa-001',
  location: LatLng(39.6666, 20.8520),
  severity: AccidentSeverity.minor,
);

Future<void> _pumpSheet(WidgetTester tester, AccidentRecord accident) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AccidentDetailsSheet(accident: accident)),
    ),
  );
}

void main() {
  testWidgets('shows every available detail', (tester) async {
    await _pumpSheet(tester, _complete);

    expect(find.text('Traffic accident'), findsOneWidget);
    expect(find.text('Serious injury'), findsOneWidget);
    expect(find.text('3 Nov 2025, 18:40'), findsOneWidget);
    expect(find.text('Syngrou Ave (Fix), Koukaki, Athens'), findsOneWidget);
    expect(find.text('Injured'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Deaths'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Rear-end collision'), findsOneWidget);
    expect(find.text('Speeding'), findsOneWidget);
    expect(find.text('Mock data (development only)'), findsOneWidget);
  });

  testWidgets('leaves out details that are not available', (tester) async {
    await _pumpSheet(tester, _sparse);

    expect(find.text('Minor injury'), findsOneWidget);
    for (final label in [
      'Date',
      'Location',
      'Injured',
      'Deaths',
      'Accident type',
      'Likely cause',
      'Source',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(
      find.text('No further details are available for this accident.'),
      findsOneWidget,
    );
  });

  testWidgets('opens as a bottom sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAccidentDetailsSheet(context, _complete),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AccidentDetailsSheet), findsOneWidget);
  });
}
