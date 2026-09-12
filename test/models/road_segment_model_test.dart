import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/models/road_segment_model.dart';

Map<String, dynamic> _feature({
  Object? id = 'seg-1',
  String geometryType = 'LineString',
  Object? coordinates = const [
    [23.7265, 37.9645],
    [23.7283, 37.9668],
  ],
  Map<String, dynamic> properties = const {'name': 'Syngrou Ave'},
}) {
  return {
    'type': 'Feature',
    'geometry': {'type': geometryType, 'coordinates': coordinates},
    'properties': {'id': id, ...properties},
  };
}

void main() {
  test('parses the road shape, name and features', () {
    final segment = RoadSegment.fromGeoJsonFeature(
      _feature(
        properties: {
          'name': 'Syngrou Ave (Fix)',
          'area': 'Koukaki, Athens',
          'characteristics': {
            'speedLimitKmh': 70,
            'junction': true,
            'lighting': 'poor',
            'pedestrianActivity': 'high',
          },
          'source': 'Mock data (development only)',
        },
      ),
    );

    expect(segment.id, 'seg-1');
    expect(segment.name, 'Syngrou Ave (Fix)');
    expect(segment.area, 'Koukaki, Athens');
    // GeoJSON is [longitude, latitude].
    expect(segment.points, hasLength(2));
    expect(segment.points.first.latitude, 37.9645);
    expect(segment.points.first.longitude, 23.7265);
    expect(segment.characteristics.speedLimitKmh, 70);
    expect(segment.characteristics.isJunction, isTrue);
    expect(segment.characteristics.lighting, RoadLighting.poor);
    expect(
      segment.characteristics.pedestrianActivity,
      PedestrianActivity.high,
    );
    expect(segment.source, 'Mock data (development only)');
  });

  test('features the data does not provide stay unknown', () {
    final segment = RoadSegment.fromGeoJsonFeature(_feature());

    expect(segment.area, isNull);
    expect(segment.characteristics.speedLimitKmh, isNull);
    expect(segment.characteristics.isJunction, isNull);
    expect(segment.characteristics.lighting, isNull);
    expect(segment.characteristics.pedestrianActivity, isNull);
  });

  test('skips and reports invalid segments, keeping valid ones', () {
    final errors = <Object>[];

    final catalog = RoadSegmentCatalog.fromGeoJson(
      {
        'type': 'FeatureCollection',
        'features': [
          _feature(id: 'ok'),
          _feature(id: 'point', geometryType: 'Point'),
          _feature(
            id: 'one-point',
            coordinates: const [
              [23.7, 37.9],
            ],
          ),
          _feature(id: 'no-name', properties: const {}),
          _feature(
            id: 'bad-lighting',
            properties: const {
              'name': 'Dim St',
              'characteristics': {'lighting': 'dim'},
            },
          ),
          _feature(id: 'ok'),
        ],
      },
      onInvalidRecord: errors.add,
    );

    expect(catalog.segments.map((segment) => segment.id), ['ok']);
    expect(errors, hasLength(5));
  });
}
