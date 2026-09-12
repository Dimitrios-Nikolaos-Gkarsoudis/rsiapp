import 'package:latlong2/latlong.dart';

enum AccidentSeverity {
  fatal('fatal', 'Fatal', 0xFFC5221F),
  serious('serious', 'Serious injury', 0xFFE8710A),
  minor('minor', 'Minor injury', 0xFFF9AB00),
  damageOnly('damage_only', 'Damage only', 0xFF80868B);

  const AccidentSeverity(this.code, this.label, this.colorValue);

  /// Value of the `severity` property in the GeoJSON data.
  final String code;
  final String label;

  /// ARGB colour for markers and badges.
  final int colorValue;
}

enum AccidentType {
  rearEnd('rear_end', 'Rear-end collision'),
  sideImpact('side_impact', 'Side impact'),
  headOn('head_on', 'Head-on collision'),
  pedestrian('pedestrian', 'Pedestrian struck'),
  singleVehicle('single_vehicle', 'Single-vehicle crash'),
  motorcycle('motorcycle', 'Motorcycle crash'),
  other('other', 'Other');

  const AccidentType(this.code, this.label);

  /// Value of the `accidentType` property in the GeoJSON data.
  final String code;
  final String label;
}

/// One recorded traffic accident.
///
/// Only [id] and [location] are guaranteed; every other field is shown only
/// where the source data provides it.
class AccidentRecord {
  final String id;
  final LatLng location;
  final DateTime? occurredAt;
  final String? locationName;
  final String? area;
  final AccidentSeverity? severity;
  final int? injuries;
  final int? fatalities;
  final AccidentType? type;
  final String? cause;
  final String? source;

  const AccidentRecord({
    required this.id,
    required this.location,
    this.occurredAt,
    this.locationName,
    this.area,
    this.severity,
    this.injuries,
    this.fatalities,
    this.type,
    this.cause,
    this.source,
  });

  factory AccidentRecord.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final geometry = _asJsonObject(feature['geometry'], 'geometry');

    if (geometry['type'] != 'Point') {
      throw const FormatException('geometry must be a Point.');
    }

    final coordinates = geometry['coordinates'];

    if (coordinates is! List ||
        coordinates.length < 2 ||
        coordinates[0] is! num ||
        coordinates[1] is! num) {
      throw const FormatException('Point needs [longitude, latitude].');
    }

    // GeoJSON coordinates are [longitude, latitude].
    final longitude = (coordinates[0] as num).toDouble();
    final latitude = (coordinates[1] as num).toDouble();

    if (latitude.abs() > 90 || longitude.abs() > 180) {
      throw FormatException(
        'coordinates out of range: $latitude, $longitude.',
      );
    }

    final properties = _asJsonObject(feature['properties'], 'properties');
    final id = properties['id'] ?? feature['id'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('missing "id".');
    }

    return AccidentRecord(
      id: id,
      location: LatLng(latitude, longitude),
      occurredAt: _optionalDate(properties, 'date'),
      locationName: _optionalText(properties, 'location'),
      area: _optionalText(properties, 'area'),
      severity: _optionalCode(
        properties,
        'severity',
        AccidentSeverity.values,
        (severity) => severity.code,
      ),
      injuries: _optionalCount(properties, 'injuries'),
      fatalities: _optionalCount(properties, 'fatalities'),
      type: _optionalCode(
        properties,
        'accidentType',
        AccidentType.values,
        (type) => type.code,
      ),
      cause: _optionalText(properties, 'cause'),
      source: _optionalText(properties, 'source'),
    );
  }
}

class AccidentCatalog {
  final List<AccidentRecord> accidents;
  final Map<String, AccidentRecord> _accidentsById;

  AccidentCatalog._(this.accidents, this._accidentsById);

  AccidentRecord? byId(String id) => _accidentsById[id];

  /// Parses a GeoJSON FeatureCollection of accident points.
  ///
  /// Malformed features are skipped and reported through [onInvalidRecord]
  /// so one bad record does not hide the rest.
  factory AccidentCatalog.fromGeoJson(
    Map<String, dynamic> json, {
    void Function(Object error)? onInvalidRecord,
  }) {
    final features = json['features'];

    if (json['type'] != 'FeatureCollection' || features is! List) {
      throw const FormatException(
        'Accident data must be a GeoJSON FeatureCollection.',
      );
    }

    final accidentsById = <String, AccidentRecord>{};

    for (final raw in features) {
      try {
        final accident = AccidentRecord.fromGeoJsonFeature(
          _asJsonObject(raw, 'feature'),
        );

        if (accidentsById.containsKey(accident.id)) {
          throw FormatException('duplicate id "${accident.id}".');
        }

        accidentsById[accident.id] = accident;
      } on FormatException catch (error) {
        onInvalidRecord?.call(
          FormatException('accident ${_recordId(raw)}: ${error.message}'),
        );
      }
    }

    return AccidentCatalog._(
      List.unmodifiable(accidentsById.values),
      Map.unmodifiable(accidentsById),
    );
  }

  /// GeoJSON for the map source, built from validated records only, with the
  /// properties the map layers need: `id` for taps and `severity` for colour.
  Map<String, Object?> toMapGeoJson() => mapGeoJsonFor(accidents);

  /// Map source GeoJSON for any set of accidents, e.g. the filtered ones.
  static Map<String, Object?> mapGeoJsonFor(
    Iterable<AccidentRecord> accidents,
  ) {
    return {
      'type': 'FeatureCollection',
      'features': [
        for (final accident in accidents)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [
                accident.location.longitude,
                accident.location.latitude,
              ],
            },
            'properties': {
              'id': accident.id,
              'severity': accident.severity?.code,
            },
          },
      ],
    };
  }
}

String _recordId(Object? raw) {
  if (raw is Map) {
    final properties = raw['properties'];
    final id = properties is Map ? properties['id'] : raw['id'];
    if (id != null) return '"$id"';
  }

  return '(no id)';
}

Map<String, dynamic> _asJsonObject(Object? value, String name) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw FormatException('"$name" must be a JSON object.');
}

String? _optionalText(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value == null) return null;

  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  throw FormatException('"$key" must be text.');
}

int? _optionalCount(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value == null) return null;

  if (value is num && value >= 0 && value == value.roundToDouble()) {
    return value.toInt();
  }

  throw FormatException('"$key" must be a whole number of zero or more.');
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value == null) return null;

  final parsed = value is String ? DateTime.tryParse(value) : null;

  if (parsed == null) {
    throw FormatException('invalid date "$value" for "$key".');
  }

  return parsed;
}

T? _optionalCode<T>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
  String Function(T value) codeOf,
) {
  final raw = json[key];

  if (raw == null) return null;

  for (final value in values) {
    if (codeOf(value) == raw) return value;
  }

  throw FormatException('unknown $key "$raw".');
}
