import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/rental_model.dart';

class RentalService {
  RentalService._();

  static const String catalogAsset = 'assets/data/rentals.json';

  /// Loads the rental catalog from the bundled mock JSON.
  ///
  /// Malformed individual records are skipped and reported through
  /// [onInvalidRecord]. A missing or malformed file throws, so the UI can
  /// show an error instead of an empty list.
  static Future<RentalCatalog> loadCatalog({
    AssetBundle? bundle,
    void Function(Object error)? onInvalidRecord,
  }) async {
    try {
      final jsonString = await (bundle ?? rootBundle).loadString(
        catalogAsset,
      );

      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Rental catalog must be a JSON object.');
      }

      final catalog = RentalCatalog.fromJson(
        decoded,
        onInvalidRecord: (error) {
          if (kDebugMode) {
            debugPrint('Skipping invalid rental record: $error');
          }

          onInvalidRecord?.call(error);
        },
      );

      if (kDebugMode) {
        debugPrint(
          'Loaded ${catalog.rentals.length} rentals from '
          '${catalog.companies.length} companies.',
        );
      }

      return catalog;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Rental catalog load error: $error');
      }

      rethrow;
    }
  }
}
