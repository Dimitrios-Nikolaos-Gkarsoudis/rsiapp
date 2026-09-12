import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../models/accident_model.dart';
import '../../models/road_risk_model.dart';
import '../../models/road_segment_model.dart';
import '../geo/route_geometry.dart';

/// Estimates how risky a road segment is, as a score from 0 to 100.
///
/// This is a heuristic risk index, not a statistically validated crash
/// probability. It combines:
/// * accidents within [matchDistanceMeters] of the road, per km of road;
/// * how severe each accident was, plus its injuries and deaths;
/// * how recent each accident is (older ones count less);
/// * road features where known: junctions, high speed limits, poor lighting
///   and heavy pedestrian activity.
class RiskCalculator {
  const RiskCalculator({this.matchDistanceMeters = 75});

  /// Short segments count as at least this long, so one accident on a tiny
  /// stretch of road does not max out the score.
  static const double _minimumLengthKm = 0.2;

  /// Weighted accidents per km that give a score of about 63.
  static const double _scoreScale = 20;

  static const double _injuryWeight = 0.5;
  static const double _fatalityWeight = 4;

  static const Distance _distance = Distance();

  final double matchDistanceMeters;

  RiskAssessment assess(
    RoadSegment segment,
    Iterable<AccidentRecord> accidents,
    DateTime now,
  ) {
    final nearby = accidents.where((accident) {
      final projection = RouteGeometry.projectPointOntoRoute(
        accident.location,
        segment.points,
      );
      return projection.distanceMeters <= matchDistanceMeters;
    }).toList(growable: false);

    var weightedAccidents = 0.0;
    var fatalAccidents = 0;
    var seriousAccidents = 0;
    var injuries = 0;
    var fatalities = 0;
    DateTime? firstAccidentAt;
    DateTime? lastAccidentAt;

    for (final accident in nearby) {
      final casualtyWeight = (accident.injuries ?? 0) * _injuryWeight +
          (accident.fatalities ?? 0) * _fatalityWeight;

      weightedAccidents += (_severityWeight(accident.severity) +
              casualtyWeight) *
          _recencyWeight(accident.occurredAt, now);

      if (accident.severity == AccidentSeverity.fatal) fatalAccidents++;
      if (accident.severity == AccidentSeverity.serious) seriousAccidents++;
      injuries += accident.injuries ?? 0;
      fatalities += accident.fatalities ?? 0;

      final occurredAt = accident.occurredAt;
      if (occurredAt != null) {
        if (firstAccidentAt == null || occurredAt.isBefore(firstAccidentAt)) {
          firstAccidentAt = occurredAt;
        }
        if (lastAccidentAt == null || occurredAt.isAfter(lastAccidentAt)) {
          lastAccidentAt = occurredAt;
        }
      }
    }

    final lengthKm = math.max(_lengthKm(segment.points), _minimumLengthKm);
    final riskPerKm = weightedAccidents /
        lengthKm *
        _featureFactor(segment.characteristics);
    final score =
        (100 * (1 - math.exp(-riskPerKm / _scoreScale))).round().clamp(0, 100);

    return RiskAssessment(
      segment: segment,
      score: score,
      accidentCount: nearby.length,
      fatalAccidents: fatalAccidents,
      seriousAccidents: seriousAccidents,
      injuries: injuries,
      fatalities: fatalities,
      firstAccidentAt: firstAccidentAt,
      lastAccidentAt: lastAccidentAt,
    );
  }

  static double _severityWeight(AccidentSeverity? severity) {
    return switch (severity) {
      AccidentSeverity.fatal => 10,
      AccidentSeverity.serious => 5,
      AccidentSeverity.minor => 2,
      AccidentSeverity.damageOnly || null => 1,
    };
  }

  /// Full weight for the last year, less for older accidents.
  static double _recencyWeight(DateTime? occurredAt, DateTime now) {
    if (occurredAt == null) return 0.6;

    final ageInDays = now.difference(occurredAt).inDays;

    if (ageInDays < 365) return 1;
    if (ageInDays < 3 * 365) return 0.6;
    return 0.3;
  }

  static double _featureFactor(RoadCharacteristics characteristics) {
    var factor = 1.0;

    if (characteristics.isJunction == true) factor += 0.15;
    if ((characteristics.speedLimitKmh ?? 0) >= 70) factor += 0.1;
    if (characteristics.lighting == RoadLighting.poor) factor += 0.1;
    if (characteristics.pedestrianActivity == PedestrianActivity.high) {
      factor += 0.1;
    }

    return factor;
  }

  static double _lengthKm(List<LatLng> points) {
    var meters = 0.0;

    for (var index = 0; index < points.length - 1; index++) {
      meters += _distance.as(LengthUnit.Meter, points[index], points[index + 1]);
    }

    return meters / 1000;
  }
}
