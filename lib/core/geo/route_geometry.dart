import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Represents the closest position of a point relative to a route.
///
/// For example, if an accident occurred beside a road, this tells us:
///
/// - which part of the route it is closest to
/// - how far away from the actual route it is
/// - where along that route segment it lies
class RouteProjection {
  final int segmentIndex;
  final double distanceMeters;
  final double fractionOnSegment;

  const RouteProjection({
    required this.segmentIndex,
    required this.distanceMeters,
    required this.fractionOnSegment,
  });
}

class RouteGeometry {
  const RouteGeometry._();

  static const double _earthRadiusMeters = 6371000.0;

  /// Finds the closest part of a route to [point].
  ///
  /// This is much more accurate than simply comparing [point] against
  /// individual sampled route coordinates.
  static RouteProjection projectPointOntoRoute(
    LatLng point,
    List<LatLng> route,
  ) {
    if (route.isEmpty) {
      return const RouteProjection(
        segmentIndex: 0,
        distanceMeters: double.infinity,
        fractionOnSegment: 0,
      );
    }

    if (route.length == 1) {
      return RouteProjection(
        segmentIndex: 0,
        distanceMeters: const Distance().as(
          LengthUnit.Meter,
          point,
          route.first,
        ),
        fractionOnSegment: 0,
      );
    }

    double bestDistance = double.infinity;
    int bestSegment = 0;
    double bestFraction = 0;

    for (int i = 0; i < route.length - 1; i++) {
      final result = _distanceToSegmentMeters(
        point,
        route[i],
        route[i + 1],
      );

      final distance = result.$1;
      final fraction = result.$2;

      if (distance < bestDistance) {
        bestDistance = distance;
        bestSegment = i;
        bestFraction = fraction;
      }
    }

    return RouteProjection(
      segmentIndex: bestSegment,
      distanceMeters: bestDistance,
      fractionOnSegment: bestFraction,
    );
  }

  /// Calculates how far along the route a projected point lies.
  ///
  /// Example:
  ///
  /// Driver:
  /// 2.1 km along route
  ///
  /// Hazard:
  /// 2.7 km along route
  ///
  /// Hazard is approximately 600 m ahead.
  static double distanceAlongRouteMeters(
    List<LatLng> route,
    RouteProjection projection,
  ) {
    if (route.length < 2) {
      return 0;
    }

    const distanceCalculator = Distance();

    double total = 0;

    for (int i = 0; i < projection.segmentIndex; i++) {
      total += distanceCalculator.as(
        LengthUnit.Meter,
        route[i],
        route[i + 1],
      );
    }

    final segmentLength = distanceCalculator.as(
      LengthUnit.Meter,
      route[projection.segmentIndex],
      route[projection.segmentIndex + 1],
    );

    return total +
        segmentLength * projection.fractionOnSegment;
  }

  /// Calculates the remaining route distance from an arbitrary position.
  static double remainingRouteDistanceMeters(
    LatLng from,
    List<LatLng> route,
  ) {
    if (route.isEmpty) {
      return 0;
    }

    if (route.length == 1) {
      return const Distance().as(
        LengthUnit.Meter,
        from,
        route.first,
      );
    }

    final projection = projectPointOntoRoute(
      from,
      route,
    );

    final alreadyTravelled = distanceAlongRouteMeters(
      route,
      projection,
    );

    const distanceCalculator = Distance();

    double totalRouteLength = 0;

    for (int i = 0; i < route.length - 1; i++) {
      totalRouteLength += distanceCalculator.as(
        LengthUnit.Meter,
        route[i],
        route[i + 1],
      );
    }

    return math.max(
      0,
      totalRouteLength - alreadyTravelled,
    );
  }

  /// Calculates the shortest distance between [point] and the line segment
  /// from [start] to [end].
  ///
  /// Returns:
  ///
  /// (distance in meters, fraction along segment)
  static (double, double) _distanceToSegmentMeters(
    LatLng point,
    LatLng start,
    LatLng end,
  ) {
    final referenceLatitude =
        (
          point.latitude +
          start.latitude +
          end.latitude
        ) /
        3;

    final cosLatitude = math.cos(
      referenceLatitude * math.pi / 180,
    );

    (double, double) toXY(LatLng position) {
      final x =
          position.longitude *
          math.pi /
          180 *
          _earthRadiusMeters *
          cosLatitude;

      final y =
          position.latitude *
          math.pi /
          180 *
          _earthRadiusMeters;

      return (x, y);
    }

    final p = toXY(point);
    final a = toXY(start);
    final b = toXY(end);

    final abX = b.$1 - a.$1;
    final abY = b.$2 - a.$2;

    final apX = p.$1 - a.$1;
    final apY = p.$2 - a.$2;

    final abSquared =
        abX * abX +
        abY * abY;

    final rawT = abSquared == 0
        ? 0.0
        : (
            apX * abX +
            apY * abY
          ) /
          abSquared;

    final t = rawT
        .clamp(0.0, 1.0)
        .toDouble();

    final closestX =
        a.$1 +
        abX * t;

    final closestY =
        a.$2 +
        abY * t;

    final dx = p.$1 - closestX;
    final dy = p.$2 - closestY;

    final distance = math.sqrt(
      dx * dx +
      dy * dy,
    );

    return (
      distance,
      t,
    );
  }
}