import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../models/road_risk_model.dart';
import 'map_colors.dart';

/// Draws mapped road segments coloured by risk level: green (low), yellow
/// (moderate), orange (high) and red (very high). Tapping a segment calls
/// [onSegmentTap].
class RoadRiskMapLayer {
  RoadRiskMapLayer({required this.onSegmentTap});

  static const String sourceId = 'rsi-road-risk';
  static const String lineLayerId = 'rsi-road-risk-lines';

  static const String _tapId = 'rsi-road-risk-tap';

  final void Function(RiskAssessment assessment) onSegmentTap;

  Map<String, RiskAssessment> _assessmentsById = const {};

  /// Adds the road risk source, line layer and tap handling to [map].
  ///
  /// Call once the style has loaded, before layers that should draw on top
  /// of the roads. Calling again replaces the previous setup.
  Future<void> addTo(
    mapbox.MapboxMap map,
    List<RiskAssessment> assessments,
  ) async {
    _assessmentsById = {
      for (final assessment in assessments) assessment.segment.id: assessment,
    };

    await _removeFrom(map);

    final style = map.style;

    await style.addSource(
      mapbox.GeoJsonSource(
        id: sourceId,
        data: jsonEncode(_toGeoJson(assessments)),
      ),
    );

    await style.addLayer(
      mapbox.LineLayer(
        id: lineLayerId,
        sourceId: sourceId,
        lineColorExpression: _riskColorExpression(),
        // Thin when zoomed out, wider close in.
        lineWidthExpression: const [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          2,
          14,
          5,
          17,
          9,
        ],
        lineOpacity: 0.85,
        lineCap: mapbox.LineCap.ROUND,
        lineJoin: mapbox.LineJoin.ROUND,
      ),
    );

    map.addInteraction(
      mapbox.TapInteraction(
        mapbox.FeaturesetDescriptor(layerId: lineLayerId),
        (feature, _) => _handleTap(feature),
      ),
      interactionID: _tapId,
    );
  }

  Future<void> _removeFrom(mapbox.MapboxMap map) async {
    map.removeInteraction(_tapId);

    final style = map.style;

    if (await style.styleLayerExists(lineLayerId)) {
      await style.removeStyleLayer(lineLayerId);
    }

    if (await style.styleSourceExists(sourceId)) {
      await style.removeStyleSource(sourceId);
    }
  }

  void _handleTap(
    mapbox.TypedFeaturesetFeature<mapbox.FeaturesetDescriptor> feature,
  ) {
    final id = feature.properties['id'];
    final assessment = id is String ? _assessmentsById[id] : null;

    if (assessment == null) {
      debugPrint('Tapped a road segment with an unknown id: $id');
      return;
    }

    onSegmentTap(assessment);
  }

  static Map<String, Object?> _toGeoJson(List<RiskAssessment> assessments) {
    return {
      'type': 'FeatureCollection',
      'features': [
        for (final assessment in assessments)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                for (final point in assessment.segment.points)
                  [point.longitude, point.latitude],
              ],
            },
            'properties': {
              'id': assessment.segment.id,
              'riskLevel': assessment.level.code,
              'riskScore': assessment.score,
            },
          },
      ],
    };
  }

  static List<Object> _riskColorExpression() {
    return [
      'match',
      ['get', 'riskLevel'],
      for (final level in RiskLevel.values) ...[
        level.code,
        mapHexColor(level.colorValue),
      ],
      mapHexColor(RiskLevel.low.colorValue),
    ];
  }
}
