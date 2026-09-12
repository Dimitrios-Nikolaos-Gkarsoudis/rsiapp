import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/models/accident_model.dart';
import 'package:rsi/models/map_filter_model.dart';
import 'package:rsi/providers/map_filter_provider.dart';
import 'package:rsi/widgets/map_filter/map_filter_sheet.dart';

Future<ProviderContainer> _pumpSheet(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: MapFilterSheet())),
    ),
  );

  return container;
}

void main() {
  testWidgets('shows every filter section with defaults', (tester) async {
    await _pumpSheet(tester);

    for (final text in [
      'Map filters',
      'Show on map',
      'Accidents',
      'Road risk',
      'Accident severity',
      'Fatal',
      'Damage only',
      'Time period',
      'Last 12 months',
      'All time',
      'Road risk level',
      'Very high risk',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    final reset = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Reset'),
    );
    expect(reset.onPressed, isNull);
  });

  testWidgets('tapping chips updates the filter and enables Reset',
      (tester) async {
    final container = await _pumpSheet(tester);

    await tester.tap(find.text('Damage only'));
    await tester.tap(find.text('Last 12 months'));
    await tester.pump();

    final filter = container.read(mapFilterProvider);
    expect(filter.severities, isNot(contains(AccidentSeverity.damageOnly)));
    expect(filter.period, AccidentPeriod.lastYear);

    await tester.tap(find.text('Reset'));
    await tester.pump();

    expect(container.read(mapFilterProvider).isDefault, isTrue);
  });

  testWidgets('hiding accidents disables their severity and period chips',
      (tester) async {
    final container = await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Accidents'));
    await tester.pump();

    expect(container.read(mapFilterProvider).showAccidents, isFalse);

    final fatalChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Fatal'),
    );
    expect(fatalChip.onSelected, isNull);

    final periodChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Last 3 years'),
    );
    expect(periodChip.onSelected, isNull);
  });
}
