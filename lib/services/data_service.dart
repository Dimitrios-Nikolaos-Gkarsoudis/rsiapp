import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hazard_model.dart';

class DataService {
  static Future<List<HazardFeature>> loadLocalHazards() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/naxos_hazards.geojson');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List features = data['features'] ?? [];
      
      return features.map((f) => HazardFeature.fromJson(f)).toList();
    } catch (e) {
      print("Error loading geojson: $e");
      return [];
    }
  }
}