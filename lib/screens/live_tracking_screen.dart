import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../core/geo/route_geometry.dart';
import '../map/accident_map_layer.dart';
import '../map/road_risk_map_layer.dart';
import '../models/hazard_model.dart';
import '../providers/accidents_provider.dart';
import '../providers/app_setup_provider.dart';
import '../providers/clock_provider.dart';
import '../providers/location_provider.dart';
import '../providers/map_filter_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/road_risk_provider.dart';
import '../services/hazard_db_service.dart';
import '../services/location_service.dart';
import '../services/mapbox_service.dart';
import '../services/osrm_service.dart';
import '../widgets/accidents/accident_details_sheet.dart';
import '../widgets/map_compass_button.dart';
import '../widgets/map_filter/map_filter_sheet.dart';
import '../widgets/rentals/rentals_sheet.dart';
import '../widgets/road_risk/road_risk_details_sheet.dart';
import '../widgets/route_summary_sheet.dart';
import '../widgets/safety_alert_card.dart';
import '../widgets/turn_by_turn_panel.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  ConsumerState<LiveTrackingScreen> createState() =>
      _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  static const Color _mapsBlue = Color(0xFF1A73E8);
  static const Color _textPrimary = Color(0xFF202124);
  static const Color _textSecondary = Color(0xFF5F6368);
  static const ll.Distance _distance = ll.Distance();

  // Must stay one instance: MapWidget re-applies its viewport whenever it
  // receives a different object, which would snap the camera back here on
  // every rebuild.
  static final mapbox.CameraViewportState _initialViewport =
      mapbox.CameraViewportState(
    center: mapbox.Point(
      coordinates: mapbox.Position(23.7275, 37.9838),
    ),
    zoom: 12.5,
  );

  mapbox.MapboxMap? _map;
  mapbox.PolylineAnnotationManager? _routeLineManager;
  mapbox.CircleAnnotationManager? _hazardManager;
  mapbox.CircleAnnotationManager? _vehicleManager;
  mapbox.CircleAnnotation? _vehicleAnnotation;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();

  Timer? _searchDebouncer;
  Timer? _simulationTimer;
  Timer? _hazardDismissTimer;

  List<MapboxSearchResult> _suggestions = [];
  MapboxSearchResult? _selectedOrigin;
  MapboxSearchResult? _selectedDestination;

  ll.LatLng? _currentGpsPosition;
  double _lastHeading = 0;

  bool _plannerExpanded = false;
  bool _searchingOrigin = false;
  bool _isSearching = false;
  bool _isCalculatingRoute = false;
  bool _cameraFollowing = true;
  bool _is3d = true;
  bool _simulationMode = true;
  bool _arrivalPending = false;
  bool _hasCenteredOnUser = false;

  /// During navigation: true keeps the map north-up instead of following
  /// the driving direction. Toggled by tapping the compass.
  bool _navigationNorthUp = false;

  /// Live map bearing, for the compass needle without rebuilding the map.
  final ValueNotifier<double> _mapBearing = ValueNotifier<double>(0);

  late final AccidentMapLayer _accidentLayer = AccidentMapLayer(
    onAccidentTap: (accident) {
      if (mounted) showAccidentDetailsSheet(context, accident);
    },
  );

  late final RoadRiskMapLayer _roadRiskLayer = RoadRiskMapLayer(
    onSegmentTap: (assessment) {
      if (mounted) showRoadRiskDetailsSheet(context, assessment);
    },
  );

  int _simulationIndex = 0;
  int _lastDrawnRouteIndex = -1;

  double _simulationMetersAlongRoute = 0.0;

  List<double> _routeCumulativeMeters = const [];

  DateTime? _lastSimulationTick;
  DateTime? _lastCameraUpdate;
  DateTime? _lastNavigationLogicUpdate;

  double _smoothedCameraBearing = 0.0;

  final Set<String> _shownHazardIds = {};

  double _remainingDistanceKm = 0;
  double _remainingDurationMinutes = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    HazardDbService.initializeDatabase();
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _simulationTimer?.cancel();
    _hazardDismissTimer?.cancel();
    _originController.dispose();
    _destinationController.dispose();
    _originFocus.dispose();
    _destinationFocus.dispose();
    _mapBearing.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(mapbox.MapboxMap map) async {
    _map = map;

    // Keep the Mapbox logo and attribution visible above the rentals sheet.
    final ornamentMarginBottom =
        RentalsSheet.peekHeight + MediaQuery.paddingOf(context).bottom + 8;

    await _map?.compass.updateSettings(
      mapbox.CompassSettings(enabled: false),
    );
    await _map?.scaleBar.updateSettings(
      mapbox.ScaleBarSettings(enabled: false),
    );
    await _map?.attribution.updateSettings(
      mapbox.AttributionSettings(
        marginBottom: ornamentMarginBottom,
        marginLeft: 8,
      ),
    );
    await _map?.logo.updateSettings(
      mapbox.LogoSettings(
        marginBottom: ornamentMarginBottom,
        marginLeft: 8,
      ),
    );
    await _map?.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: false,
      ),
    );

    _routeLineManager =
        await _map?.annotations.createPolylineAnnotationManager();
    _hazardManager =
        await _map?.annotations.createCircleAnnotationManager();
    _vehicleManager =
        await _map?.annotations.createCircleAnnotationManager();

    final position = _currentGpsPosition;
    if (position != null) {
      _centerOnFirstFix(position);
    }
  }

  void _onSearchChanged(String query, {required bool origin}) {
    _searchDebouncer?.cancel();
    _searchingOrigin = origin;

    _searchDebouncer = Timer(const Duration(milliseconds: 280), () async {
      final clean = query.trim();
      if (clean.isEmpty || clean == 'Your location') {
        if (!mounted) return;
        setState(() => _suggestions = []);
        return;
      }

      setState(() => _isSearching = true);
      final results = await MapboxService.searchPlaces(
        clean,
        userLocation: _currentGpsPosition,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  void _selectSuggestion(MapboxSearchResult result) {
    FocusScope.of(context).unfocus();

    setState(() {
      _suggestions = [];
      if (_searchingOrigin) {
        _selectedOrigin = result;
        _originController.text = result.displayName;
      } else {
        _selectedDestination = result;
        _destinationController.text = result.displayName;
      }
    });

    if (_selectedDestination != null) {
      _calculateRoute();
    }
  }

  void _swapOriginDestination() {
    final currentLocationResult = _currentGpsPosition == null
        ? null
        : MapboxSearchResult(
            displayName: 'Your location',
            location: _currentGpsPosition!,
          );

    final effectiveOrigin = _selectedOrigin ?? currentLocationResult;
    final previousDestination = _selectedDestination;

    if (effectiveOrigin == null || previousDestination == null) return;

    setState(() {
      _selectedOrigin = previousDestination;
      _selectedDestination = effectiveOrigin;
      _originController.text = previousDestination.displayName;
      _destinationController.text = effectiveOrigin.displayName;
    });

    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    final start = _selectedOrigin?.location ?? _currentGpsPosition;
    final end = _selectedDestination?.location;
    if (start == null || end == null) return;

    setState(() {
      _isCalculatingRoute = true;
      _suggestions = [];
    });

    final details = await OsrmService.fetchRouteDetails(
      start: start,
      end: end,
    );

    if (!mounted) return;
    setState(() => _isCalculatingRoute = false);

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not calculate this route.')),
      );
      return;
    }

    ref.read(navigationProvider.notifier).setRoute(details);

    setState(() {
      _plannerExpanded = false;
      _remainingDistanceKm = details.distanceKm;
      _remainingDurationMinutes = details.durationMinutes;
      _lastDrawnRouteIndex = -1;
    });

    await _drawRoute(details.polyline);
    await _drawHazards(details.dbHazards);
    await _showRouteOverview(details.polyline);
  }

  Future<void> _showRouteOverview(List<ll.LatLng> route) async {
    final map = _map;
    if (map == null || route.length < 2) return;

    final points = route
        .map(
          (p) => mapbox.Point(
            coordinates: mapbox.Position(p.longitude, p.latitude),
          ),
        )
        .toList();

    final camera = await map.cameraForCoordinatesPadding(
      points,
      mapbox.CameraOptions(bearing: 0, pitch: 0),
      mapbox.MbxEdgeInsets(
        top: 150,
        left: 44,
        bottom: 310,
        right: 44,
      ),
      16,
      null,
    );

    await map.easeTo(
      camera,
      mapbox.MapAnimationOptions(duration: 650),
    );
  }

  Future<void> _drawRoute(List<ll.LatLng> points) async {
    final manager = _routeLineManager;
    if (manager == null) return;

    await manager.deleteAll();
    if (points.length < 2) return;

    final geometry = mapbox.LineString(
      coordinates: points
          .map((p) => mapbox.Position(p.longitude, p.latitude))
          .toList(),
    );

    await manager.create(
      mapbox.PolylineAnnotationOptions(
        geometry: geometry,
        lineColor: Colors.white.toARGB32(),
        lineWidth: 10,
        lineOpacity: 0.95,
        lineJoin: mapbox.LineJoin.ROUND,
      ),
    );

    await manager.create(
      mapbox.PolylineAnnotationOptions(
        geometry: geometry,
        lineColor: _mapsBlue.toARGB32(),
        lineWidth: 6.5,
        lineOpacity: 1,
        lineJoin: mapbox.LineJoin.ROUND,
      ),
    );
  }

  Future<void> _drawHazards(List<HazardFeature> hazards) async {
    final manager = _hazardManager;
    if (manager == null) return;

    await manager.deleteAll();

    for (final hazard in hazards) {
      final point = mapbox.Point(
        coordinates: mapbox.Position(
          hazard.location.longitude,
          hazard.location.latitude,
        ),
      );

      await manager.create(
        mapbox.CircleAnnotationOptions(
          geometry: point,
          circleRadius: 17,
          circleColor: const Color(0xFFF29900).toARGB32(),
          circleOpacity: 0.18,
          circleStrokeColor: const Color(0xFFF29900).toARGB32(),
          circleStrokeWidth: 1.5,
        ),
      );

      await manager.create(
        mapbox.CircleAnnotationOptions(
          geometry: point,
          circleRadius: 7,
          circleColor: const Color(0xFFF29900).toARGB32(),
          circleOpacity: 1,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.5,
        ),
      );
    }
  }

  Future<void> _updateVehicleMarker(ll.LatLng position) async {
    final manager = _vehicleManager;
    if (manager == null) return;

    if (_vehicleAnnotation == null) {
      _vehicleAnnotation = await manager.create(
        mapbox.CircleAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              position.longitude,
              position.latitude,
            ),
          ),
          circleRadius: 7,
          circleColor: _mapsBlue.toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.5,
          circleOpacity: 1,
        ),
      );
      return;
    }

    _vehicleAnnotation!.geometry = mapbox.Point(
      coordinates: mapbox.Position(position.longitude, position.latitude),
    );
    await manager.update(_vehicleAnnotation!);
  }

  double _bearing(ll.LatLng from, ll.LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Compass tap: turns the map back to north. While navigating it switches
  /// between north-up and following the driving direction.
  void _onCompassTap() {
    if (ref.read(navigationProvider).isNavigating) {
      setState(() => _navigationNorthUp = !_navigationNorthUp);

      if (!_navigationNorthUp) {
        _recenter();
        return;
      }
    }

    _map?.easeTo(
      mapbox.CameraOptions(bearing: 0),
      mapbox.MapAnimationOptions(duration: 300),
    );
  }

  Future<void> _followDriver(ll.LatLng position, double heading) async {
    if (!_cameraFollowing || _map == null) return;

    await _map!.easeTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(position.longitude, position.latitude),
        ),
        zoom: 17.2,
        pitch: _is3d ? 58 : 0,
        bearing: _navigationNorthUp &&
                ref.read(navigationProvider).isNavigating
            ? 0
            : heading,
        padding: mapbox.MbxEdgeInsets(
          top: 150,
          left: 0,
          bottom: 240,
          right: 0,
        ),
      ),
      mapbox.MapAnimationOptions(duration: 300),
    );
  }

  void _startNavigation() {
    final nav = ref.read(navigationProvider);
    final route = nav.activeRouteDetails;
    if (route == null || route.polyline.isEmpty) return;

    _simulationTimer?.cancel();
    _hazardDismissTimer?.cancel();
    _shownHazardIds.clear();
    _arrivalPending = false;
    _simulationIndex = 0;
    _lastDrawnRouteIndex = -1;

    final start = _simulationMode
        ? route.polyline.first
        : (_currentGpsPosition ?? route.polyline.first);

    ref.read(navigationProvider.notifier).startNavigation(
          simulate: _simulationMode,
          startPos: start,
        );

    setState(() {
      _cameraFollowing = true;
      _plannerExpanded = false;
      _remainingDistanceKm = route.distanceKm;
      _remainingDurationMinutes = route.durationMinutes;
    });

    _updateVehicleMarker(start);
    _followDriver(start, _lastHeading);

    if (!_simulationMode) return;

    final interval = (350 / nav.simulationMultiplier).round().clamp(55, 1000);

    _simulationTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (timer) {
        if (!mounted || _arrivalPending) {
          timer.cancel();
          return;
        }

        final currentNav = ref.read(navigationProvider);
        final activeRoute = currentNav.activeRouteDetails;
        if (!currentNav.isNavigating || activeRoute == null) {
          timer.cancel();
          return;
        }

        if (_simulationIndex >= activeRoute.polyline.length - 1) {
          timer.cancel();
          _completeArrival();
          return;
        }

        final from = activeRoute.polyline[_simulationIndex];
        _simulationIndex++;
        final to = activeRoute.polyline[_simulationIndex];
        final heading = _bearing(from, to);

        ref.read(navigationProvider.notifier).updateVehiclePosition(to);
        _updateVehicleMarker(to);
        _followDriver(to, heading);
        _updateNavigationTick(to, _simulationIndex);
      },
    );
  }

  void _completeArrival() {
    if (_arrivalPending) return;
    _arrivalPending = true;
    _simulationTimer?.cancel();

    ref.read(navigationProvider.notifier).updateTurnInstruction(
          'You have arrived',
          0,
        );

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _arrivalPending) _stopNavigation();
    });
  }

  void _stopNavigation() {
    _simulationTimer?.cancel();
    _hazardDismissTimer?.cancel();
    _shownHazardIds.clear();
    _arrivalPending = false;

    ref.read(navigationProvider.notifier).stopNavigation();

    setState(() {
      _cameraFollowing = true;
    });

    final route = ref.read(navigationProvider).activeRouteDetails;
    if (route != null) {
      _drawRoute(route.polyline);
      _showRouteOverview(route.polyline);
    }
  }

  void _toggleNavigationMode() {
    setState(() => _simulationMode = !_simulationMode);
  }

  void _recenter() {
    final nav = ref.read(navigationProvider);
    final position = nav.isNavigating
        ? nav.activeVehiclePosition
        : _currentGpsPosition;

    if (position == null) {
      if (!ref.read(appSetupProvider).useDeviceLocation) {
        _enableDeviceLocation();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Finding your location. Make sure location is turned on.',
          ),
        ),
      );
      return;
    }

    setState(() => _cameraFollowing = true);
    // Follow the driving direction while navigating (unless north-up is
    // chosen); when browsing keep the map's current rotation.
    _followDriver(
      position,
      nav.isNavigating ? _lastHeading : _mapBearing.value,
    );
  }

  /// Asks for location access when the user skipped it during onboarding
  /// and later taps the location button.
  Future<void> _enableDeviceLocation() async {
    final granted = await LocationService.checkAndRequestPermissions();

    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location is off. Allow location access for Road Safety Insights '
            'in your phone settings.',
          ),
        ),
      );
      return;
    }

    await ref.read(appSetupProvider.notifier).setUseDeviceLocation(true);
  }

  /// Road lines are thin, so taps this close to a line still select it.
  static const double _roadTapRadiusDp = 20;

  /// Converts a tap radius in logical pixels to the map's screen units.
  /// Mapbox on Android measures in physical pixels; iOS uses points.
  double _mapTapRadius(double logicalPixels) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return isAndroid
        ? logicalPixels * MediaQuery.devicePixelRatioOf(context)
        : logicalPixels;
  }

  /// Shows road risk levels and recorded accidents once the map style has
  /// loaded. Road lines go first so accident points draw on top of them.
  Future<void> _addSafetyLayers() async {
    final map = _map;
    if (map == null) return;

    try {
      final assessments = await ref.read(roadRiskProvider.future);
      if (!mounted) return;
      await _roadRiskLayer.addTo(
        map,
        assessments,
        tapRadius: _mapTapRadius(_roadTapRadiusDp),
      );
    } catch (error) {
      debugPrint('RSI could not show road risk levels: $error');
    }

    try {
      final catalog = await ref.read(accidentCatalogProvider.future);
      if (!mounted) return;
      await _accidentLayer.addTo(map, catalog);
    } catch (error) {
      debugPrint('RSI could not show accident points: $error');
    }

    await _applyMapFilter();
  }

  /// Shows only the accidents and roads that match the map filters.
  Future<void> _applyMapFilter() async {
    final map = _map;
    if (map == null) return;

    final filter = ref.read(mapFilterProvider);
    final now = ref.read(clockProvider)();

    try {
      final catalog = await ref.read(accidentCatalogProvider.future);
      final assessments = await ref.read(roadRiskProvider.future);
      if (!mounted) return;

      await _accidentLayer.update(
        map,
        visible: filter.showAccidents,
        accidents: catalog.accidents.where(
          (accident) => filter.includesAccident(accident, now),
        ),
      );
      await _roadRiskLayer.update(
        map,
        visible: filter.showRoadRisk,
        assessments: assessments.where(filter.includesRoad),
      );
    } catch (error) {
      debugPrint('RSI could not apply map filters: $error');
    }
  }

  /// Moves the map from its default view to the user once, on the first fix.
  void _centerOnFirstFix(ll.LatLng position) {
    final map = _map;

    if (_hasCenteredOnUser || map == null) return;
    if (ref.read(navigationProvider).activeRouteDetails != null) return;

    _hasCenteredOnUser = true;

    map.easeTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(position.longitude, position.latitude),
        ),
        zoom: 15,
        bearing: 0,
        pitch: 0,
      ),
      mapbox.MapAnimationOptions(duration: 600),
    );
  }

  int _nearestRouteIndex(ll.LatLng position, List<ll.LatLng> route) {
    var index = 0;
    var best = double.infinity;

    for (var i = 0; i < route.length; i++) {
      final d = _distance.as(ll.LengthUnit.Meter, position, route[i]);
      if (d < best) {
        best = d;
        index = i;
      }
    }
    return index;
  }

  void _updateNavigationTick(ll.LatLng position, int currentIndex) {
    final nav = ref.read(navigationProvider);
    final route = nav.activeRouteDetails;
    if (route == null || route.polyline.length < 2 || _arrivalPending) return;

    final driverProjection = RouteGeometry.projectPointOntoRoute(
      position,
      route.polyline,
    );
    final driverAlong = RouteGeometry.distanceAlongRouteMeters(
      route.polyline,
      driverProjection,
    );

    final remainingMeters = RouteGeometry.remainingRouteDistanceMeters(
      position,
      route.polyline,
    );
    final totalMeters = math.max(1, route.distanceKm * 1000);
    final fractionRemaining = (remainingMeters / totalMeters).clamp(0.0, 1.0);

    if (mounted) {
      setState(() {
        _remainingDistanceKm = remainingMeters / 1000;
        _remainingDurationMinutes = route.durationMinutes * fractionRemaining;
      });
    }

    if (remainingMeters <= 18) {
      _completeArrival();
      return;
    }

    if (currentIndex > _lastDrawnRouteIndex + 3 &&
        currentIndex < route.polyline.length - 1) {
      _lastDrawnRouteIndex = currentIndex;
      _drawRoute(route.polyline.sublist(currentIndex));
    }

    NavigationStep? nextStep;
    double? nextStepDistance;

    for (final step in route.steps) {
      final stepProjection = RouteGeometry.projectPointOntoRoute(
        step.location,
        route.polyline,
      );
      final stepAlong = RouteGeometry.distanceAlongRouteMeters(
        route.polyline,
        stepProjection,
      );
      final ahead = stepAlong - driverAlong;

      if (ahead < 8) continue;
      if (nextStepDistance == null || ahead < nextStepDistance) {
        nextStep = step;
        nextStepDistance = ahead;
      }
    }

    if (nextStep != null && nextStepDistance != null) {
      ref.read(navigationProvider.notifier).updateTurnInstruction(
            nextStep.instruction,
            nextStepDistance,
          );
    }

    if (nav.activeApproachingHazard != null) return;

    HazardFeature? closestHazard;
    double? closestHazardDistance;

    for (final hazard in route.dbHazards) {
      if (_shownHazardIds.contains(hazard.stableKey)) continue;

      final hazardProjection = RouteGeometry.projectPointOntoRoute(
        hazard.location,
        route.polyline,
      );

      if (hazardProjection.distanceMeters > hazard.radiusMeters + 50) continue;

      final hazardAlong = RouteGeometry.distanceAlongRouteMeters(
        route.polyline,
        hazardProjection,
      );
      final ahead = hazardAlong - driverAlong;

      if (ahead < -25) continue;

      final warningDistance = math.max(
        300.0,
        math.min(800.0, hazard.radiusMeters + 250),
      );
      if (ahead > warningDistance) continue;

      if (closestHazardDistance == null || ahead < closestHazardDistance) {
        closestHazard = hazard;
        closestHazardDistance = math.max(0, ahead);
      }
    }

    if (closestHazard == null || closestHazardDistance == null) return;

    _shownHazardIds.add(closestHazard.stableKey);
    ref.read(navigationProvider.notifier).updateApproachingHazard(
          closestHazard,
          distanceAheadMeters: closestHazardDistance,
        );

    _hazardDismissTimer?.cancel();
    _hazardDismissTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      ref.read(navigationProvider.notifier).updateApproachingHazard(null);
    });
  }

  IconData _maneuverIcon(String instruction) {
    final text = instruction.toLowerCase();
    if (text.contains('left') || text.contains('αριστερ')) {
      return Icons.turn_left_rounded;
    }
    if (text.contains('right') || text.contains('δεξ')) {
      return Icons.turn_right_rounded;
    }
    if (text.contains('roundabout') || text.contains('κυκλ')) {
      return Icons.roundabout_right_rounded;
    }
    if (text.contains('arriv') || text.contains('φτά')) {
      return Icons.flag_rounded;
    }
    if (text.contains('u-turn') || text.contains('αναστροφ')) {
      return Icons.u_turn_left_rounded;
    }
    return Icons.straight_rounded;
  }

  String _duration(double minutes) {
    final total = minutes.round();
    if (total < 60) return '$total min';
    final hours = total ~/ 60;
    final remaining = total % 60;
    return remaining == 0 ? '$hours hr' : '$hours hr $remaining min';
  }

  String _arrivalTime(double minutes) {
    final arrival = DateTime.now().add(Duration(minutes: minutes.round()));
    final h = arrival.hour.toString().padLeft(2, '0');
    final m = arrival.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _mapButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    String? label,
  }) {
    return Material(
      color: active ? _mapsBlue : Colors.white,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 12 : 14,
            vertical: 11,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: active ? Colors.white : _textSecondary,
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : _textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _collapsedSearchBar() {
    final hasRoute = ref.watch(navigationProvider).activeRouteDetails != null;
    final title = _selectedDestination?.displayName;
    final activeFilters = ref.watch(
      mapFilterProvider.select((filter) => filter.activeCount),
    );

    return Material(
      color: Colors.white,
      elevation: 7,
      shadowColor: const Color(0x26000000),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          setState(() {
            _plannerExpanded = true;
            _searchingOrigin = false;
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _destinationFocus.requestFocus();
          });
        },
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Menu',
                // The State's context sits above this screen's Scaffold, so
                // it reaches the HomeShell scaffold that owns the drawer.
                onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
                icon: const Icon(Icons.menu_rounded),
                color: _textPrimary,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  hasRoute && title != null ? title : 'Where to?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: title == null ? _textSecondary : _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Material(
                color: const Color(0xFFE8F0FE),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Map filters',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showMapFilterSheet(context),
                  color: _mapsBlue,
                  icon: Badge(
                    isLabelVisible: activeFilters > 0,
                    label: Text('$activeFilters'),
                    child: const Icon(Icons.tune_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 9),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plannerCard() {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x26000000),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _plannerExpanded = false;
                      _suggestions = [];
                    });
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: _textPrimary,
                ),
                const SizedBox(width: 2),
                Column(
                  children: [
                    const Icon(Icons.my_location_rounded, color: _mapsBlue, size: 17),
                    Container(
                      width: 2,
                      height: 25,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: const Color(0xFFDADCE0),
                    ),
                    const Icon(Icons.location_on_rounded, color: Color(0xFFEA4335), size: 20),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      _routeTextField(
                        controller: _originController,
                        focusNode: _originFocus,
                        hint: 'Your location',
                        origin: true,
                      ),
                      const Divider(height: 1, color: Color(0xFFE8EAED)),
                      _routeTextField(
                        controller: _destinationController,
                        focusNode: _destinationFocus,
                        hint: 'Choose destination',
                        origin: false,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _swapOriginDestination,
                  icon: const Icon(Icons.swap_vert_rounded),
                  color: _textSecondary,
                ),
              ],
            ),
          ),
          if (_isSearching || _isCalculatingRoute)
            const LinearProgressIndicator(
              minHeight: 2,
              color: _mapsBlue,
              backgroundColor: Color(0xFFE8EAED),
            ),
          if (_suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 58,
                  color: Color(0xFFF1F3F4),
                ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F3F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.place_outlined,
                        size: 19,
                        color: _textSecondary,
                      ),
                    ),
                    title: Text(
                      suggestion.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _routeTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool origin,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: 1,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF80868B)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onTap: () => setState(() => _searchingOrigin = origin),
      onChanged: (value) => _onSearchChanged(value, origin: origin),
    );
  }

  Widget _navigationBottomBar(NavigationState nav) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _arrivalTime(_remainingDurationMinutes),
                        style: const TextStyle(
                          color: Color(0xFF188038),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _duration(_remainingDurationMinutes),
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_remainingDistanceKm.toStringAsFixed(1)} km remaining',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Overview',
              onPressed: () {
                final route = nav.activeRouteDetails;
                if (route != null) _showRouteOverview(route.polyline);
                setState(() => _cameraFollowing = false);
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F3F4),
                foregroundColor: _textPrimary,
              ),
              icon: const Icon(Icons.route_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'End navigation',
              onPressed: _stopNavigation,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFEA4335),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    ref.listen(mapFilterProvider, (_, _) => _applyMapFilter());

    ref.listen<AsyncValue<ll.LatLng>>(
      locationStreamProvider,
      (previous, next) {
        if (next.hasError) {
          debugPrint('RSI location stream error: ${next.error}');
        }

        next.whenData((position) {
          final previousPosition = _currentGpsPosition;
          if (previousPosition != null) {
            final moved = _distance.as(
              ll.LengthUnit.Meter,
              previousPosition,
              position,
            );
            if (moved > 1.5) {
              _lastHeading = _bearing(previousPosition, position);
            }
          }

          _currentGpsPosition = position;

          if (_originController.text.isEmpty && _selectedOrigin == null) {
            _originController.text = 'Your location';
          }

          if (!nav.isNavigating) {
            _updateVehicleMarker(position);
            _centerOnFirstFix(position);
            return;
          }

          if (!nav.isSimulating) {
            ref.read(navigationProvider.notifier).updateVehiclePosition(position);
            _updateVehicleMarker(position);
            _followDriver(position, _lastHeading);

            final route = nav.activeRouteDetails;
            if (route != null) {
              final index = _nearestRouteIndex(position, route.polyline);
              _updateNavigationTick(position, index);
            }
          }
        });
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: Stack(
        children: [
          Listener(
            onPointerDown: (_) {
              if (nav.isNavigating && _cameraFollowing) {
                setState(() => _cameraFollowing = false);
              }
            },
            child: mapbox.MapWidget(
              key: const ValueKey('rsi-map'),
              onMapCreated: _onMapCreated,
              styleUri: mapbox.MapboxStyles.STANDARD,
              viewport: _initialViewport,
              onStyleLoadedListener: (_) => _addSafetyLayers(),
              onCameraChangeListener: (event) {
                _mapBearing.value = event.cameraState.bearing;
              },
            ),
          ),

          if (!nav.isNavigating)
            Positioned(
              top: safeTop + 10,
              left: 14,
              right: 14,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _plannerExpanded
                    ? _plannerCard()
                    : _collapsedSearchBar(),
              ),
            ),

          if (nav.isNavigating)
            Positioned(
              top: safeTop + 10,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  TurnByTurnPanel(
                    instruction: nav.currentTurnInstruction,
                    distanceMeters: nav.distanceToNextTurnMeters,
                    maneuverIcon: _maneuverIcon(nav.currentTurnInstruction),
                  ),
                  if (nav.activeApproachingHazard != null) ...[
                    const SizedBox(height: 10),
                    SafetyAlertCard(
                      hazard: nav.activeApproachingHazard!,
                      distanceAheadMeters: nav.activeHazardDistanceMeters,
                    ),
                  ],
                ],
              ),
            ),

          Positioned(
            right: 14,
            bottom: nav.isNavigating
                ? 114 + safeBottom
                : nav.activeRouteDetails != null
                    ? 232 + safeBottom
                    : _plannerExpanded
                        ? 28 + safeBottom
                        : RentalsSheet.peekHeight + 16 + safeBottom,
            child: Column(
              children: [
                if (nav.isNavigating) ...[
                  _mapButton(
                    icon: _is3d ? Icons.view_in_ar_rounded : Icons.map_outlined,
                    onTap: () {
                      setState(() => _is3d = !_is3d);
                      _recenter();
                    },
                    active: _is3d,
                  ),
                  const SizedBox(height: 10),
                ],
                MapCompassButton(
                  bearing: _mapBearing,
                  tooltip: !nav.isNavigating
                      ? 'Reset map to north'
                      : _navigationNorthUp
                          ? 'Follow driving direction'
                          : 'Keep north up',
                  onTap: _onCompassTap,
                ),
                const SizedBox(height: 10),
                _mapButton(
                  icon: Icons.my_location_rounded,
                  onTap: _recenter,
                  active: _cameraFollowing,
                ),
              ],
            ),
          ),

          if (!nav.isNavigating && nav.activeRouteDetails != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RouteSummarySheet(
                routeDetails: nav.activeRouteDetails!,
                simulationMultiplier: nav.simulationMultiplier,
                formattedDuration: _duration(
                  nav.activeRouteDetails!.durationMinutes,
                ),
                onSimulationSpeedChanged: (value) {
                  if (value != null) {
                    ref
                        .read(navigationProvider.notifier)
                        .updateSimulationMultiplier(value);
                  }
                },
                onStartNavigation: _startNavigation,
              ),
            ),

          if (!nav.isNavigating && nav.activeRouteDetails != null)
            Positioned(
              left: 14,
              bottom: 218 + safeBottom,
              child: _mapButton(
                icon: _simulationMode
                    ? Icons.speed_rounded
                    : Icons.gps_fixed_rounded,
                label: _simulationMode ? 'Simulation' : 'Live GPS',
                active: _simulationMode,
                onTap: _toggleNavigationMode,
              ),
            ),

          if (nav.isNavigating)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _navigationBottomBar(nav),
            ),

          if (!nav.isNavigating &&
              nav.activeRouteDetails == null &&
              !_plannerExpanded)
            Positioned.fill(
              child: RentalsSheet(
                // Keeps the search bar visible above the expanded sheet.
                topClearance: safeTop + 78,
              ),
            ),
        ],
      ),
    );
  }
}
