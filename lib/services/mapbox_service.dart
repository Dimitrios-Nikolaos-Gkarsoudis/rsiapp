import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapboxSearchResult {
  final String displayName;
  final LatLng location;

  MapboxSearchResult({required this.displayName, required this.location});
}

class MapboxService {
  static const String publicToken = 'pk.eyJ1IjoiZGltaXRyaXMtcnNpIiwiYSI6ImNtczhzN2psNjA0NnUyenBlNDF0bXhpYW4ifQ.-tryF4kaSRrHvZLU6tG7qQ';

  static Future<List<MapboxSearchResult>> searchPlaces(String query, {LatLng? userLocation}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(cleanQuery)}.json?access_token=$publicToken&autocomplete=true&limit=8&country=gr&language=el';

    if (userLocation != null) {
      url += '&proximity=${userLocation.longitude},${userLocation.latitude}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data['features'] ?? [];

        return features.map((f) {
          final List coords = f['geometry']['coordinates'];
          return MapboxSearchResult(
            displayName: f['place_name_el'] ?? f['place_name'] ?? '',
            location: LatLng(coords[1].toDouble(), coords[0].toDouble()),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Mapbox Geocoding Error: $e");
    }
    return [];
  }
}