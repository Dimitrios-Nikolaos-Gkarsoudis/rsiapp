import 'package:latlong2/latlong.dart';

class HazardFeature {
  final String id;
  final String hazardType;
  final String locationDescription;
  final String nearestArea;
  final String severity;
  final String date;
  final String weatherFactor;
  final int totalAccidents;
  final int recentAccidents;
  final double radiusMeters;
  final LatLng location;

  const HazardFeature({
    required this.id,
    required this.hazardType,
    required this.locationDescription,
    required this.nearestArea,
    required this.severity,
    required this.date,
    required this.weatherFactor,
    required this.totalAccidents,
    required this.recentAccidents,
    required this.radiusMeters,
    required this.location,
  });

  /// A reliable identifier even if the GeoJSON record has no explicit id.
  String get stableKey {
    if (id.isNotEmpty) {
      return id;
    }

    return '${location.latitude.toStringAsFixed(6)}_'
        '${location.longitude.toStringAsFixed(6)}_'
        '$hazardType';
  }

  /// Converts the date string into DateTime when possible.
  ///
  /// Returns null if the source data does not contain a valid ISO date.
  DateTime? get parsedDate => DateTime.tryParse(date);

  factory HazardFeature.fromJson(Map<String, dynamic> json) {
    final geometry = Map<String, dynamic>.from(
      json['geometry'] as Map? ?? const {},
    );

    final coordinates = geometry['coordinates'] as List?;

    if (coordinates == null || coordinates.length < 2) {
      throw const FormatException(
        'Hazard feature is missing valid Point coordinates.',
      );
    }

    final properties = Map<String, dynamic>.from(
      json['properties'] as Map? ?? const {},
    );

    return HazardFeature(
      id: (properties['id'] ?? json['id'] ?? '').toString(),

      hazardType: (
        properties['hazardType'] ??
        'Τροχαίο ατύχημα'
      ).toString(),

      locationDescription: (
        properties['locationDescription'] ??
        ''
      ).toString(),

      nearestArea: (
        properties['nearestArea'] ??
        ''
      ).toString(),

      severity: (
        properties['severity'] ??
        ''
      ).toString(),

      date: (
        properties['date'] ??
        ''
      ).toString(),

      weatherFactor: (
        properties['weatherFactor'] ??
        'Άγνωστο'
      ).toString(),

      totalAccidents: _asInt(
        properties['totalAccidents'],
        fallback: 1,
      ),

      recentAccidents: _asInt(
        properties['recentAccidents'],
      ),

      radiusMeters: _asDouble(
        properties['radiusMeters'],
        fallback: 150,
      ),

      // GeoJSON coordinates are:
      //
      // [longitude, latitude]
      //
      // LatLng expects:
      //
      // latitude, longitude
      location: LatLng(
        (coordinates[1] as num).toDouble(),
        (coordinates[0] as num).toDouble(),
      ),
    );
  }

  static int _asInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static double _asDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }
}