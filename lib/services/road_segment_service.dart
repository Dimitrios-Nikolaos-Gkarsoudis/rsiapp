import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/road_segment_model.dart';

class RoadSegmentService {
  RoadSegmentService._();

  static const String dataAsset = 'assets/data/road_segments.geojson';

  /// Loads mapped road segments from the bundled GeoJSON (mock data for now).
  ///
  /// Malformed individual features are skipped and reported through
  /// [onInvalidRecord]. A missing or malformed file throws.
  static Future<RoadSegmentCatalog> loadCatalog({
    AssetBundle? bundle,
    void Function(Object error)? onInvalidRecord,
  }) async {
    try {
      final jsonString = await (bundle ?? rootBundle).loadString(dataAsset);
      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Road segment data must be a JSON object.');
      }

      final catalog = RoadSegmentCatalog.fromGeoJson(
        decoded,
        onInvalidRecord: (error) {
          if (kDebugMode) {
            debugPrint('Skipping invalid road segment: $error');
          }

          onInvalidRecord?.call(error);
        },
      );

      if (kDebugMode) {
        debugPrint('Loaded ${catalog.segments.length} road segments.');
      }

      return catalog;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Road segment data load error: $error');
      }

      rethrow;
    }
  }
}
