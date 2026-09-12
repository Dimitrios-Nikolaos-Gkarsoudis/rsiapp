import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/models/accident_model.dart';

Map<String, dynamic> _feature({
  Object? id = 'acc-1',
  Object? coordinates = const [23.7265, 37.9645],
  String geometryType = 'Point',
  Map<String, dynamic> properties = const {},
}) {
  return {
    'type': 'Feature',
    'geometry': {'type': geometryType, 'coordinates': coordinates},
    'properties': {'id': id, ...properties},
  };
}

AccidentCatalog _catalog(List<Object?> features, {List<Object>? errors}) {
  return AccidentCatalog.fromGeoJson(
    {'type': 'FeatureCollection', 'features': features},
    onInvalidRecord: errors?.add,
  );
}

void main() {
  group('AccidentRecord.fromGeoJsonFeature', () {
    test('parses every field of a complete record', () {
      final accident = AccidentRecord.fromGeoJsonFeature(
        _feature(
          properties: {
            'date': '2025-11-03T18:40:00',
            'location': 'Syngrou Ave (Fix)',
            'area': 'Koukaki, Athens',
            'severity': 'serious',
            'injuries': 2,
            'fatalities': 0,
            'accidentType': 'rear_end',
            'cause': 'Speeding',
            'source': 'Mock data (development only)',
          },
        ),
      );

      expect(accident.id, 'acc-1');
      // GeoJSON is [longitude, latitude].
      expect(accident.location.latitude, 37.9645);
      expect(accident.location.longitude, 23.7265);
      expect(accident.occurredAt, DateTime(2025, 11, 3, 18, 40));
      expect(accident.locationName, 'Syngrou Ave (Fix)');
      expect(accident.area, 'Koukaki, Athens');
      expect(accident.severity, AccidentSeverity.serious);
      expect(accident.injuries, 2);
      expect(accident.fatalities, 0);
      expect(accident.type, AccidentType.rearEnd);
      expect(accident.cause, 'Speeding');
      expect(accident.source, 'Mock data (development only)');
    });

    test('leaves missing optional fields empty', () {
      final accident = AccidentRecord.fromGeoJsonFeature(_feature());

      expect(accident.occurredAt, isNull);
      expect(accident.locationName, isNull);
      expect(accident.severity, isNull);
      expect(accident.injuries, isNull);
      expect(accident.fatalities, isNull);
      expect(accident.type, isNull);
      expect(accident.cause, isNull);
      expect(accident.source, isNull);
    });
  });

  group('AccidentCatalog.fromGeoJson', () {
    test('skips and reports invalid records, keeping valid ones', () {
      final errors = <Object>[];

      final catalog = _catalog(
        [
          _feature(id: 'ok', properties: {'severity': 'damage_only'}),
          _feature(id: 'bad-severity', properties: {'severity': 'catastrophic'}),
          _feature(id: 'negative', properties: {'injuries': -1}),
          _feature(id: 'line', geometryType: 'LineString'),
          _feature(id: 'far', coordinates: [23.7, 137.0]),
          _feature(id: null),
          _feature(id: 'ok'),
          'not an object',
        ],
        errors: errors,
      );

      expect(catalog.accidents.map((accident) => accident.id), ['ok']);
      expect(catalog.byId('ok')?.severity, AccidentSeverity.damageOnly);
      expect(errors, hasLength(7));
      expect(errors.first.toString(), contains('bad-severity'));
    });

    test('throws when the data is not a FeatureCollection', () {
      expect(
        () => AccidentCatalog.fromGeoJson({'type': 'Feature'}),
        throwsFormatException,
      );
    });

    test('map GeoJSON contains only valid records with id and severity', () {
      final catalog = _catalog([
        _feature(id: 'a', properties: {'severity': 'fatal'}),
        _feature(id: 'b'),
        _feature(id: 'broken', properties: {'severity': 'unknown'}),
      ]);

      final features = catalog.toMapGeoJson()['features']! as List;

      expect(features, hasLength(2));
      expect(
        features.map((feature) => (feature as Map)['properties']),
        [
          {'id': 'a', 'severity': 'fatal'},
          {'id': 'b', 'severity': null},
        ],
      );
    });
  });
}
