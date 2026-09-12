import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SearchResult {
  final String displayName;
  final LatLng location;

  SearchResult({required this.displayName, required this.location});
}

class SearchService {
  static Future<List<SearchResult>> searchPlaces(String query, {LatLng? userLocation}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    // Upgraded URL with 15 max results and user location bias
    String urlString = 'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(cleanQuery)}&limit=15&addressdetails=1&dedupe=1';

    // Prioritize results near user's current GPS position
    if (userLocation != null) {
      urlString += '&lat=${userLocation.latitude}&lon=${userLocation.longitude}';
    }

    final url = Uri.parse(urlString);

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RoadSafetyInsightsApp/1.0 (contact@roadsafetyinsights.org)',
          'Accept-Language': 'el,en',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) {
          return SearchResult(
            displayName: item['display_name'] ?? '',
            location: LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
            ),
          );
        }).toList();
      }
    } catch (e) {
      print("Search service exception: $e");
    }
    return [];
  }
}