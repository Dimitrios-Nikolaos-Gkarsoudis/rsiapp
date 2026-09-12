import 'package:latlong2/latlong.dart';

enum RoadLighting {
  good('good', 'Good lighting'),
  poor('poor', 'Poor lighting');

  const RoadLighting(this.code, this.label);

  final String code;
  final String label;
}

enum PedestrianActivity {
  low('low', 'Low pedestrian activity'),
  medium('medium', 'Moderate pedestrian activity'),
  high('high', 'High pedestrian activity');

  const PedestrianActivity(this.code, this.label);

  final String code;
  final String label;
}

/// Physical features of a road segment. Each one is optional: only what the
/// data provides is known.
class RoadCharacteristics {
  const RoadCharacteristics({
    this.speedLimitKmh,
    this.isJunction,
    this.lighting,
    this.pedestrianActivity,
  });

  final int? speedLimitKmh;
  final bool? isJunction;
  final RoadLighting? lighting;
  final PedestrianActivity? pedestrianActivity;

  factory RoadCharacteristics.fromJson(Map<String, dynamic> json) {
    final junction = json['junction'];

    if (junction != null && junction is! bool) {
      throw const FormatException('"junction" must be true or false.');
    }

    return RoadCharacteristics(
      speedLimitKmh: _optionalPositiveInt(json, 'speedLimitKmh'),
      isJunction: junction as bool?,
      lighting: _optionalCode(
        json,
        'lighting',
        RoadLighting.values,
        (lighting) => lighting.code,
      ),
      pedestrianActivity: _optionalCode(
        json,
        'pedestrianActivity',
        PedestrianActivity.values,
        (activity) => activity.code,
      ),
    );
  }
}

/// A mapped stretch of road that gets its own risk level.
class RoadSegment {
  const RoadSegment({
    required this.id,
    required this.name,
    required this.points,
    this.area,
    this.characteristics = const RoadCharacteristics(),
    this.source,
  });

  final String id;
  final String name;
  final String? area;

  /// The road's shape, in order along the road.
  final List<LatLng> points;
  final RoadCharacteristics characteristics;
  final String? source;

  factory RoadSegment.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final geometry = _asJsonObject(feature['geometry'], 'geometry');

    if (geometry['type'] != 'LineString') {
      throw const FormatException('geometry must be a LineString.');
    }

    final coordinates = geometry['coordinates'];

    if (coordinates is! List || coordinates.length < 2) {
      throw const FormatException('LineString needs at least two points.');
    }

    final properties = _asJsonObject(feature['properties'], 'properties');
    final id = properties['id'] ?? feature['id'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('missing "id".');
    }

    final name = _optionalText(properties, 'name');

    if (name == null) {
      throw const FormatException('missing "name".');
    }

    final rawCharacteristics = properties['characteristics'];

    return RoadSegment(
      id: id,
      name: name,
      area: _optionalText(properties, 'area'),
      points: List.unmodifiable([
        for (final position in coordinates) _parsePosition(position),
      ]),
      characteristics: rawCharacteristics == null
          ? const RoadCharacteristics()
          : RoadCharacteristics.fromJson(
              _asJsonObject(rawCharacteristics, 'characteristics'),
            ),
      source: _optionalText(properties, 'source'),
    );
  }
}

class RoadSegmentCatalog {
  RoadSegmentCatalog._(this.segments);

  final List<RoadSegment> segments;

  /// Parses a GeoJSON FeatureCollection of road segments (LineStrings).
  ///
  /// Malformed features are skipped and reported through [onInvalidRecord].
  factory RoadSegmentCatalog.fromGeoJson(
    Map<String, dynamic> json, {
    void Function(Object error)? onInvalidRecord,
  }) {
    final features = json['features'];

    if (json['type'] != 'FeatureCollection' || features is! List) {
      throw const FormatException(
        'Road segment data must be a GeoJSON FeatureCollection.',
      );
    }

    final segmentsById = <String, RoadSegment>{};

    for (final raw in features) {
      try {
        final segment = RoadSegment.fromGeoJsonFeature(
          _asJsonObject(raw, 'feature'),
        );

        if (segmentsById.containsKey(segment.id)) {
          throw FormatException('duplicate id "${segment.id}".');
        }

        segmentsById[segment.id] = segment;
      } on FormatException catch (error) {
        onInvalidRecord?.call(
          FormatException('road segment ${_recordId(raw)}: ${error.message}'),
        );
      }
    }

    return RoadSegmentCatalog._(List.unmodifiable(segmentsById.values));
  }
}

LatLng _parsePosition(Object? position) {
  if (position is! List ||
      position.length < 2 ||
      position[0] is! num ||
      position[1] is! num) {
    throw const FormatException('positions must be [longitude, latitude].');
  }

  final longitude = (position[0] as num).toDouble();
  final latitude = (position[1] as num).toDouble();

  if (latitude.abs() > 90 || longitude.abs() > 180) {
    throw FormatException('coordinates out of range: $latitude, $longitude.');
  }

  return LatLng(latitude, longitude);
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

int? _optionalPositiveInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value == null) return null;

  if (value is num && value > 0 && value == value.roundToDouble()) {
    return value.toInt();
  }

  throw FormatException('"$key" must be a positive whole number.');
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
