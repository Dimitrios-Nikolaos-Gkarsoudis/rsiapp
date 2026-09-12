import 'accident_model.dart';
import 'road_risk_model.dart';

enum AccidentPeriod {
  lastYear('Last 12 months', 365),
  lastThreeYears('Last 3 years', 3 * 365),
  allTime('All time', null);

  const AccidentPeriod(this.label, this.days);

  final String label;

  /// Length of the period in days; null means no limit.
  final int? days;
}

/// What the map shows.
///
/// Filters only hide accident points and road lines. Road risk levels are
/// always calculated from all recorded accidents, so a road never looks
/// safer just because a shorter period is selected.
class MapFilter {
  const MapFilter({
    this.showAccidents = true,
    this.showRoadRisk = true,
    this.severities = allSeverities,
    this.period = AccidentPeriod.allTime,
    this.riskLevels = allRiskLevels,
  });

  static const Set<AccidentSeverity> allSeverities = {
    AccidentSeverity.fatal,
    AccidentSeverity.serious,
    AccidentSeverity.minor,
    AccidentSeverity.damageOnly,
  };

  static const Set<RiskLevel> allRiskLevels = {
    RiskLevel.low,
    RiskLevel.moderate,
    RiskLevel.high,
    RiskLevel.veryHigh,
  };

  final bool showAccidents;
  final bool showRoadRisk;
  final Set<AccidentSeverity> severities;
  final AccidentPeriod period;
  final Set<RiskLevel> riskLevels;

  /// Number of filters changed from their defaults, for the button badge.
  int get activeCount {
    return [
      !showAccidents,
      !showRoadRisk,
      severities.length < allSeverities.length,
      period != AccidentPeriod.allTime,
      riskLevels.length < allRiskLevels.length,
    ].where((isActive) => isActive).length;
  }

  bool get isDefault => activeCount == 0;

  MapFilter copyWith({
    bool? showAccidents,
    bool? showRoadRisk,
    Set<AccidentSeverity>? severities,
    AccidentPeriod? period,
    Set<RiskLevel>? riskLevels,
  }) {
    return MapFilter(
      showAccidents: showAccidents ?? this.showAccidents,
      showRoadRisk: showRoadRisk ?? this.showRoadRisk,
      severities: severities ?? this.severities,
      period: period ?? this.period,
      riskLevels: riskLevels ?? this.riskLevels,
    );
  }

  /// Whether [accident] matches the severity and time period filters.
  ///
  /// Accidents without a severity or date only show while that filter is
  /// left at its default.
  bool includesAccident(AccidentRecord accident, DateTime now) {
    final severity = accident.severity;

    if (severities.length < allSeverities.length &&
        (severity == null || !severities.contains(severity))) {
      return false;
    }

    final days = period.days;

    if (days == null) {
      return true;
    }

    final occurredAt = accident.occurredAt;
    return occurredAt != null && now.difference(occurredAt).inDays < days;
  }

  bool includesRoad(RiskAssessment assessment) {
    return riskLevels.contains(assessment.level);
  }
}
