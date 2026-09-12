import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../core/geo/route_geometry.dart';
import '../models/hazard_model.dart';

class HazardDbService {
  HazardDbService._();

  static const String _databaseAsset =
      'assets/data/naxos_hazards.geojson';

  static List<HazardFeature> _cachedHazards = [];
  static bool _initialized = false;

  /// True after the database has successfully been loaded.
  static bool get isInitialized => _initialized;

  /// Read-only access to all loaded hazards.
  static List<HazardFeature> get hazards =>
      List.unmodifiable(_cachedHazards);

  /// Loads and parses the local GeoJSON accident database.
  ///
  /// Malformed individual records are ignored instead of causing the
  /// entire accident database to fail.
  static Future<List<HazardFeature>> initializeDatabase({
    bool forceReload = false,
  }) async {
    if (_initialized && !forceReload) {
      return List.unmodifiable(_cachedHazards);
    }

    try {
      final jsonString = await rootBundle.loadString(
        _databaseAsset,
      );

      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Hazard database must contain a GeoJSON object.',
        );
      }

      final rawFeatures = decoded['features'];

      if (rawFeatures is! List) {
        throw const FormatException(
          'Hazard database does not contain a valid features array.',
        );
      }

      final parsedHazards = <HazardFeature>[];

      for (final rawFeature in rawFeatures) {
        if (rawFeature is! Map) {
          continue;
        }

        try {
          final feature = HazardFeature.fromJson(
            Map<String, dynamic>.from(rawFeature),
          );

          parsedHazards.add(feature);
        } catch (error) {
          // One malformed accident record should not stop
          // the rest of the database from loading.
          if (kDebugMode) {
            debugPrint(
              'Skipping invalid hazard record: $error',
            );
          }
        }
      }

      _cachedHazards = parsedHazards;
      _initialized = true;

      if (kDebugMode) {
        debugPrint(
          'Loaded ${_cachedHazards.length} hazard records.',
        );
      }

      return List.unmodifiable(_cachedHazards);
    } catch (error) {
      _cachedHazards = [];
      _initialized = false;

      if (kDebugMode) {
        debugPrint(
          'Hazard database load error: $error',
        );
      }

      return const [];
    }
  }

  /// Returns hazards whose safety radius intersects the actual route line.
  ///
  /// Unlike the old implementation, this does NOT compare hazards only
  /// against individual route coordinates. Instead it calculates the
  /// shortest distance between each hazard and the route segments.
  static List<HazardFeature> getHazardsAlongRoute(
    List<LatLng> routePoints, {
    double bufferMeters = 50,
  }) {
    if (routePoints.length < 2 || _cachedHazards.isEmpty) {
      return const [];
    }

    final detected = <HazardFeature>[];

    for (final hazard in _cachedHazards) {
      final projection = RouteGeometry.projectPointOntoRoute(
        hazard.location,
        routePoints,
      );

      final allowedDistance =
          hazard.radiusMeters + bufferMeters;

      if (projection.distanceMeters <= allowedDistance) {
        detected.add(hazard);
      }
    }

    return detected;
  }

  /// Finds the distance between a hazard and the route.
  ///
  /// This will be useful later for debugging, map visualization and
  /// explaining why a particular accident zone was associated with a route.
  static double distanceFromRouteMeters(
    HazardFeature hazard,
    List<LatLng> routePoints,
  ) {
    if (routePoints.length < 2) {
      return double.infinity;
    }

    return RouteGeometry.projectPointOntoRoute(
      hazard.location,
      routePoints,
    ).distanceMeters;
  }

  /// Clears the in-memory cache.
  ///
  /// Mainly useful during development or if we later support downloading
  /// an updated accident database while the application is running.
  static void clearCache() {
    _cachedHazards = [];
    _initialized = false;
  }
}