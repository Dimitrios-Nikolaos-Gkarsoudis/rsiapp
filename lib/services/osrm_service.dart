import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/hazard_model.dart';
import 'hazard_db_service.dart';

class NavigationStep {
  final String instruction;
  final double distanceMeters;
  final LatLng location;

  const NavigationStep({
    required this.instruction,
    required this.distanceMeters,
    required this.location,
  });
}

class FullRouteDetails {
  final List<LatLng> polyline;
  final double distanceKm;
  final double durationMinutes;
  final List<HazardFeature> dbHazards;
  final List<String> routeWarningBadges;
  final List<NavigationStep> steps;

  const FullRouteDetails({
    required this.polyline,
    required this.distanceKm,
    required this.durationMinutes,
    required this.dbHazards,
    required this.routeWarningBadges,
    required this.steps,
  });
}

class OsrmService {
  static const Duration _requestTimeout =
      Duration(seconds: 15);

  static Future<FullRouteDetails?> fetchRouteDetails({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      // Make sure the accident database is ready BEFORE
      // we attempt to match hazards against the route.
      await HazardDbService.initializeDatabase();

      final baseUrl = AppConfig.routingBaseUrl
          .trim()
          .replaceFirst(
            RegExp(r'/$'),
            '',
          );

      final coordinates =
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}';

      final url = Uri.parse(
        '$baseUrl/route/v1/driving/$coordinates',
      ).replace(
        queryParameters: const {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'true',
        },
      );

      final response = await http
          .get(url)
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            'OSRM HTTP error: ${response.statusCode}',
          );
        }

        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(decoded);

      if (data['code'] != 'Ok') {
        if (kDebugMode) {
          debugPrint(
            'OSRM routing error: ${data['code']}',
          );
        }

        return null;
      }

      final routes = data['routes'];

      if (routes is! List || routes.isEmpty) {
        return null;
      }

      final firstRoute = routes.first;

      if (firstRoute is! Map) {
        return null;
      }

      final route = Map<String, dynamic>.from(
        firstRoute,
      );

      final path = _parseRouteGeometry(route);

      if (path.length < 2) {
        if (kDebugMode) {
          debugPrint(
            'OSRM returned an invalid route geometry.',
          );
        }

        return null;
      }

      final distanceKm =
          _asDouble(route['distance']) / 1000;

      final durationMinutes =
          _asDouble(route['duration']) / 60;

      final steps = _parseNavigationSteps(route);

      // This now uses our new route-segment geometry
      // instead of simple route-point proximity.
      final matchedHazards =
          HazardDbService.getHazardsAlongRoute(
        path,
      );

      final warningBadges = _buildRouteWarnings(
        matchedHazards,
      );

      return FullRouteDetails(
        polyline: path,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        dbHazards: matchedHazards,
        routeWarningBadges: warningBadges,
        steps: steps,
      );
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint(
          'OSRM request timed out.',
        );
      }

      return null;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'OSRM route error: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      }

      return null;
    }
  }

  static List<LatLng> _parseRouteGeometry(
    Map<String, dynamic> route,
  ) {
    final geometry = route['geometry'];

    if (geometry is! Map) {
      return const [];
    }

    final geometryMap = Map<String, dynamic>.from(
      geometry,
    );

    final coordinates =
        geometryMap['coordinates'];

    if (coordinates is! List) {
      return const [];
    }

    final path = <LatLng>[];

    for (final coordinate in coordinates) {
      if (coordinate is! List ||
          coordinate.length < 2) {
        continue;
      }

      final longitude = coordinate[0];
      final latitude = coordinate[1];

      if (longitude is! num ||
          latitude is! num) {
        continue;
      }

      path.add(
        LatLng(
          latitude.toDouble(),
          longitude.toDouble(),
        ),
      );
    }

    return path;
  }

  static List<NavigationStep> _parseNavigationSteps(
    Map<String, dynamic> route,
  ) {
    final parsedSteps = <NavigationStep>[];

    final legs = route['legs'];

    if (legs is! List) {
      return parsedSteps;
    }

    for (final rawLeg in legs) {
      if (rawLeg is! Map) {
        continue;
      }

      final leg = Map<String, dynamic>.from(
        rawLeg,
      );

      final steps = leg['steps'];

      if (steps is! List) {
        continue;
      }

      for (final rawStep in steps) {
        if (rawStep is! Map) {
          continue;
        }

        final step = Map<String, dynamic>.from(
          rawStep,
        );

        final rawManeuver = step['maneuver'];

        if (rawManeuver is! Map) {
          continue;
        }

        final maneuver =
            Map<String, dynamic>.from(
          rawManeuver,
        );

        final location = maneuver['location'];

        if (location is! List ||
            location.length < 2) {
          continue;
        }

        final longitude = location[0];
        final latitude = location[1];

        if (longitude is! num ||
            latitude is! num) {
          continue;
        }

        final roadName =
            step['name']?.toString() ?? '';

        parsedSteps.add(
          NavigationStep(
            instruction: _formatInstruction(
              maneuver,
              roadName,
            ),
            distanceMeters:
                _asDouble(step['distance']),
            location: LatLng(
              latitude.toDouble(),
              longitude.toDouble(),
            ),
          ),
        );
      }
    }

    return parsedSteps;
  }

  static List<String> _buildRouteWarnings(
    List<HazardFeature> hazards,
  ) {
    final warnings = <String>[];

    if (hazards.isNotEmpty) {
      warnings.add(
        hazards.length == 1
            ? '1 περιοχή αυξημένου κινδύνου'
            : '${hazards.length} περιοχές αυξημένου κινδύνου',
      );
    }

    final weatherSensitive =
        hazards.any(_isWeatherSensitive);

    if (weatherSensitive) {
      warnings.add(
        'Κίνδυνος που επηρεάζεται από τον καιρό',
      );
    }

    return warnings;
  }

  static bool _isWeatherSensitive(
    HazardFeature hazard,
  ) {
    final value = hazard.weatherFactor
        .trim()
        .toLowerCase();

    if (value.isEmpty) {
      return false;
    }

    const ignoredValues = {
      'unknown',
      'none',
      'no',
      'n/a',
      'άγνωστο',
      'αγνωστο',
      'κανένα',
      'κανενα',
      'όχι',
      'οχι',
    };

    return !ignoredValues.contains(value);
  }

  static String _formatInstruction(
    Map<String, dynamic> maneuver,
    String roadName,
  ) {
    final type =
        maneuver['type']?.toString() ??
        'continue';

    final modifier =
        maneuver['modifier']
            ?.toString()
            .toLowerCase() ??
        '';

    final roadSuffix =
        roadName.trim().isEmpty
            ? ''
            : ' προς $roadName';

    switch (type) {
      case 'depart':
        return 'Ξεκινήστε τη διαδρομή σας$roadSuffix';

      case 'arrive':
        return 'Φτάσατε στον προορισμό σας';

      case 'roundabout':
      case 'rotary':
        final exit = maneuver['exit'];

        if (exit is num) {
          return 'Στον κυκλικό κόμβο, πάρτε την '
              '${exit.toInt()}η έξοδο$roadSuffix';
        }

        return 'Μπείτε στον κυκλικό κόμβο$roadSuffix';

      case 'merge':
        return 'Ενσωματωθείτε στην κυκλοφορία$roadSuffix';

      case 'fork':
        if (modifier.contains('left')) {
          return 'Κρατηθείτε αριστερά$roadSuffix';
        }

        if (modifier.contains('right')) {
          return 'Κρατηθείτε δεξιά$roadSuffix';
        }

        return 'Συνεχίστε στη διακλάδωση$roadSuffix';

      case 'on ramp':
        return 'Μπείτε στη ράμπα$roadSuffix';

      case 'off ramp':
        return 'Βγείτε από τη ράμπα$roadSuffix';

      case 'end of road':
      case 'turn':
        return _turnInstruction(
          modifier,
          roadSuffix,
        );

      case 'continue':
      case 'new name':
      default:
        if (modifier.contains('left')) {
          return 'Κινηθείτε αριστερά$roadSuffix';
        }

        if (modifier.contains('right')) {
          return 'Κινηθείτε δεξιά$roadSuffix';
        }

        return 'Συνεχίστε ευθεία$roadSuffix';
    }
  }

  static String _turnInstruction(
    String modifier,
    String roadSuffix,
  ) {
    if (modifier == 'sharp left') {
      return 'Στρίψτε απότομα αριστερά$roadSuffix';
    }

    if (modifier == 'slight left') {
      return 'Κινηθείτε ελαφρά αριστερά$roadSuffix';
    }

    if (modifier.contains('left')) {
      return 'Στρίψτε αριστερά$roadSuffix';
    }

    if (modifier == 'sharp right') {
      return 'Στρίψτε απότομα δεξιά$roadSuffix';
    }

    if (modifier == 'slight right') {
      return 'Κινηθείτε ελαφρά δεξιά$roadSuffix';
    }

    if (modifier.contains('right')) {
      return 'Στρίψτε δεξιά$roadSuffix';
    }

    if (modifier == 'uturn') {
      return 'Κάντε αναστροφή$roadSuffix';
    }

    return 'Συνεχίστε ευθεία$roadSuffix';
  }

  static double _asDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}