import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/accident_model.dart';

class AccidentService {
  AccidentService._();

  static const String dataAsset = 'assets/data/accidents.geojson';

  /// Loads recorded accidents from the bundled GeoJSON (mock data for now).
  ///
  /// Malformed individual features are skipped and reported through
  /// [onInvalidRecord]. A missing or malformed file throws.
  static Future<AccidentCatalog> loadCatalog({
    AssetBundle? bundle,
    void Function(Object error)? onInvalidRecord,
  }) async {
    try {
      final jsonString = await (bundle ?? rootBundle).loadString(dataAsset);
      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Accident data must be a JSON object.');
      }

      final catalog = AccidentCatalog.fromGeoJson(
        decoded,
        onInvalidRecord: (error) {
          if (kDebugMode) {
            debugPrint('Skipping invalid accident record: $error');
          }

          onInvalidRecord?.call(error);
        },
      );

      if (kDebugMode) {
        debugPrint('Loaded ${catalog.accidents.length} accident records.');
      }

      return catalog;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Accident data load error: $error');
      }

      rethrow;
    }
  }
}
