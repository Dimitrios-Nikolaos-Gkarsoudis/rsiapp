import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rsi/models/accident_model.dart';
import 'package:rsi/services/accident_service.dart';

bool _within(
  LatLng point, {
  required double south,
  required double north,
  required double west,
  required double east,
}) {
  return point.latitude >= south &&
      point.latitude <= north &&
      point.longitude >= west &&
      point.longitude <= east;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled mock accidents parse without skipping any record', () async {
    final errors = <Object>[];

    final catalog = await AccidentService.loadCatalog(
      onInvalidRecord: errors.add,
    );

    expect(errors, isEmpty);
    expect(catalog.accidents, isNotEmpty);
    expect(
      catalog.accidents.every((accident) => accident.source != null),
      isTrue,
    );
  });

  test('mock accidents cover central Athens and Ioannina', () async {
    final catalog = await AccidentService.loadCatalog();
    final points = catalog.accidents.map((accident) => accident.location);

    final athens = points.where(
      (point) => _within(
        point,
        south: 37.94,
        north: 38.01,
        west: 23.70,
        east: 23.77,
      ),
    );
    final ioannina = points.where(
      (point) => _within(
        point,
        south: 39.60,
        north: 39.70,
        west: 20.82,
        east: 20.88,
      ),
    );

    expect(athens.length, greaterThanOrEqualTo(20));
    expect(ioannina.length, greaterThanOrEqualTo(20));
    expect(athens.length + ioannina.length, catalog.accidents.length);
  });

  test('includes every severity so all marker colours are exercised',
      () async {
    final catalog = await AccidentService.loadCatalog();
    final severities = catalog.accidents
        .map((accident) => accident.severity)
        .whereType<AccidentSeverity>()
        .toSet();

    expect(severities, AccidentSeverity.values.toSet());
  });
}
