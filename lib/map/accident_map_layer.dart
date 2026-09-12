import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../models/accident_model.dart';
import 'map_colors.dart';

typedef _TappedFeature
    = mapbox.TypedFeaturesetFeature<mapbox.FeaturesetDescriptor>;

/// Draws recorded accidents on the map as individual points.
///
/// Mapbox groups nearby accidents into numbered clusters so busy areas stay
/// readable. Tapping a cluster zooms in until it splits; tapping a single
/// point calls [onAccidentTap].
class AccidentMapLayer {
  AccidentMapLayer({required this.onAccidentTap});

  static const String sourceId = 'rsi-accidents';
  static const String clusterLayerId = 'rsi-accident-clusters';
  static const String clusterCountLayerId = 'rsi-accident-cluster-counts';
  static const String pointLayerId = 'rsi-accident-points';

  static const String _pointTapId = 'rsi-accident-point-tap';
  static const String _clusterTapId = 'rsi-accident-cluster-tap';

  /// Above this zoom level accidents are always shown individually.
  static const double _clusterMaxZoom = 15;
  static const double _clusterRadius = 48;
  static const String _unknownSeverityColor = '#9AA0A6';

  final void Function(AccidentRecord accident) onAccidentTap;

  AccidentCatalog? _catalog;

  /// Adds the accident source, layers and tap handling to [map].
  ///
  /// Call once the style has loaded. Calling again replaces the previous
  /// setup, e.g. after a style reload.
  Future<void> addTo(mapbox.MapboxMap map, AccidentCatalog catalog) async {
    _catalog = catalog;

    await _removeFrom(map);

    final style = map.style;

    await style.addSource(
      mapbox.GeoJsonSource(
        id: sourceId,
        data: jsonEncode(catalog.toMapGeoJson()),
        cluster: true,
        clusterRadius: _clusterRadius,
        clusterMaxZoom: _clusterMaxZoom,
      ),
    );

    await style.addLayer(
      mapbox.CircleLayer(
        id: clusterLayerId,
        sourceId: sourceId,
        filter: const ['has', 'point_count'],
        // Bigger and redder as more accidents are grouped.
        circleColorExpression: const [
          'step',
          ['get', 'point_count'],
          '#F29900',
          10,
          '#E8710A',
          25,
          '#C5221F',
        ],
        circleRadiusExpression: const [
          'step',
          ['get', 'point_count'],
          16,
          10,
          20,
          25,
          25,
        ],
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
      ),
    );

    await style.addLayer(
      mapbox.SymbolLayer(
        id: clusterCountLayerId,
        sourceId: sourceId,
        filter: const ['has', 'point_count'],
        textFieldExpression: const ['get', 'point_count_abbreviated'],
        textSize: 13,
        textColor: 0xFFFFFFFF,
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
    );

    await style.addLayer(
      mapbox.CircleLayer(
        id: pointLayerId,
        sourceId: sourceId,
        filter: const [
          '!',
          ['has', 'point_count'],
        ],
        circleColorExpression: _severityColorExpression(),
        circleRadius: 7,
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
      ),
    );

    map.addInteraction(
      mapbox.TapInteraction(
        mapbox.FeaturesetDescriptor(layerId: pointLayerId),
        (feature, _) => _handlePointTap(feature),
      ),
      interactionID: _pointTapId,
    );

    map.addInteraction(
      mapbox.TapInteraction(
        mapbox.FeaturesetDescriptor(layerId: clusterLayerId),
        (feature, _) => _zoomIntoCluster(map, feature),
      ),
      interactionID: _clusterTapId,
    );
  }

  /// Shows only [accidents] (e.g. the ones matching the map filters) and
  /// sets whether the accident layers are visible. Clusters are recalculated
  /// from the accidents shown. Does nothing until [addTo] has run.
  Future<void> update(
    mapbox.MapboxMap map, {
    required bool visible,
    required Iterable<AccidentRecord> accidents,
  }) async {
    final style = map.style;

    if (!await style.styleSourceExists(sourceId)) {
      return;
    }

    final source = await style.getSource(sourceId);
    if (source is mapbox.GeoJsonSource) {
      await source.updateGeoJSON(
        jsonEncode(AccidentCatalog.mapGeoJsonFor(accidents)),
      );
    }

    for (final layerId in [clusterLayerId, clusterCountLayerId, pointLayerId]) {
      await style.setStyleLayerProperty(
        layerId,
        'visibility',
        visible ? 'visible' : 'none',
      );
    }
  }

  Future<void> _removeFrom(mapbox.MapboxMap map) async {
    map
      ..removeInteraction(_pointTapId)
      ..removeInteraction(_clusterTapId);

    final style = map.style;

    for (final layerId in [pointLayerId, clusterCountLayerId, clusterLayerId]) {
      if (await style.styleLayerExists(layerId)) {
        await style.removeStyleLayer(layerId);
      }
    }

    if (await style.styleSourceExists(sourceId)) {
      await style.removeStyleSource(sourceId);
    }
  }

  void _handlePointTap(_TappedFeature feature) {
    final id = feature.properties['id'];
    final accident = id is String ? _catalog?.byId(id) : null;

    if (accident == null) {
      debugPrint('Tapped an accident point with an unknown id: $id');
      return;
    }

    onAccidentTap(accident);
  }

  Future<void> _zoomIntoCluster(
    mapbox.MapboxMap map,
    _TappedFeature feature,
  ) async {
    try {
      final coordinates = feature.geometry['coordinates'];

      if (coordinates is! List ||
          coordinates.length < 2 ||
          coordinates[0] is! num ||
          coordinates[1] is! num) {
        return;
      }

      final expansion = await map.getGeoJsonClusterExpansionZoom(sourceId, {
        'type': 'Feature',
        'geometry': feature.geometry,
        'properties': feature.properties,
      });

      final zoom = double.tryParse(expansion.value ?? '');

      if (zoom == null) {
        return;
      }

      await map.easeTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              coordinates[0] as num,
              coordinates[1] as num,
            ),
          ),
          zoom: zoom,
        ),
        mapbox.MapAnimationOptions(duration: 500),
      );
    } catch (error) {
      debugPrint('Could not expand accident cluster: $error');
    }
  }

  /// Point colour by severity, from the same colours as the details sheet.
  static List<Object> _severityColorExpression() {
    return [
      'match',
      ['get', 'severity'],
      for (final severity in AccidentSeverity.values) ...[
        severity.code,
        mapHexColor(severity.colorValue),
      ],
      _unknownSeverityColor,
    ];
  }
}
