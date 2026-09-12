import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/accident_model.dart';
import '../models/map_filter_model.dart';
import '../models/road_risk_model.dart';

class MapFilterNotifier extends Notifier<MapFilter> {
  @override
  MapFilter build() => const MapFilter();

  void setShowAccidents(bool value) {
    state = state.copyWith(showAccidents: value);
  }

  void setShowRoadRisk(bool value) {
    state = state.copyWith(showRoadRisk: value);
  }

  /// Turns a severity on or off. The last selected severity cannot be turned
  /// off; hide accidents with the switch instead.
  void toggleSeverity(AccidentSeverity severity) {
    final next = _toggled(state.severities, severity);
    if (next != null) {
      state = state.copyWith(severities: next);
    }
  }

  void setPeriod(AccidentPeriod period) {
    state = state.copyWith(period: period);
  }

  /// Turns a risk level on or off. The last selected level cannot be turned
  /// off; hide road risk with the switch instead.
  void toggleRiskLevel(RiskLevel level) {
    final next = _toggled(state.riskLevels, level);
    if (next != null) {
      state = state.copyWith(riskLevels: next);
    }
  }

  void reset() {
    state = const MapFilter();
  }

  /// A copy of [values] with [value] toggled, or null if that would leave
  /// nothing selected.
  static Set<T>? _toggled<T>(Set<T> values, T value) {
    final next = values.contains(value)
        ? values.where((item) => item != value).toSet()
        : {...values, value};

    return next.isEmpty ? null : Set.unmodifiable(next);
  }
}

final mapFilterProvider =
    NotifierProvider<MapFilterNotifier, MapFilter>(MapFilterNotifier.new);
