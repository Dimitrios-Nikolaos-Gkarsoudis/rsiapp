import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/models/accident_model.dart';
import 'package:rsi/models/map_filter_model.dart';
import 'package:rsi/models/road_risk_model.dart';
import 'package:rsi/providers/map_filter_provider.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('toggling a severity removes it and adds it back', () {
    final container = _container();
    final notifier = container.read(mapFilterProvider.notifier);

    notifier.toggleSeverity(AccidentSeverity.minor);
    expect(
      container.read(mapFilterProvider).severities,
      isNot(contains(AccidentSeverity.minor)),
    );

    notifier.toggleSeverity(AccidentSeverity.minor);
    expect(
      container.read(mapFilterProvider).severities,
      MapFilter.allSeverities,
    );
  });

  test('the last selected risk level cannot be turned off', () {
    final container = _container();
    final notifier = container.read(mapFilterProvider.notifier);

    notifier
      ..toggleRiskLevel(RiskLevel.low)
      ..toggleRiskLevel(RiskLevel.moderate)
      ..toggleRiskLevel(RiskLevel.high)
      ..toggleRiskLevel(RiskLevel.veryHigh);

    expect(container.read(mapFilterProvider).riskLevels, {RiskLevel.veryHigh});
  });

  test('reset brings every filter back to its default', () {
    final container = _container();
    final notifier = container.read(mapFilterProvider.notifier);

    notifier
      ..setShowAccidents(false)
      ..setPeriod(AccidentPeriod.lastThreeYears)
      ..toggleRiskLevel(RiskLevel.low);
    expect(container.read(mapFilterProvider).activeCount, 3);

    notifier.reset();
    expect(container.read(mapFilterProvider).isDefault, isTrue);
  });
}
