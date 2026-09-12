import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../models/hazard_model.dart';
import '../services/osrm_service.dart';

const Object _unset = Object();

class NavigationState {
  final bool isNavigating;
  final bool isSimulating;
  final int simulationMultiplier;

  final FullRouteDetails? activeRouteDetails;
  final ll.LatLng? activeVehiclePosition;

  final String currentTurnInstruction;
  final double distanceToNextTurnMeters;

  final HazardFeature? activeApproachingHazard;

  /// Distance to the currently displayed hazard measured
  /// ALONG the active route, not straight-line distance.
  final double? activeHazardDistanceMeters;

  const NavigationState({
    this.isNavigating = false,
    this.isSimulating = false,
    this.simulationMultiplier = 5,
    this.activeRouteDetails,
    this.activeVehiclePosition,
    this.currentTurnInstruction = 'Συνεχίστε στην πορεία σας',
    this.distanceToNextTurnMeters = 0,
    this.activeApproachingHazard,
    this.activeHazardDistanceMeters,
  });

  NavigationState copyWith({
    bool? isNavigating,
    bool? isSimulating,
    int? simulationMultiplier,
    Object? activeRouteDetails = _unset,
    Object? activeVehiclePosition = _unset,
    String? currentTurnInstruction,
    double? distanceToNextTurnMeters,
    Object? activeApproachingHazard = _unset,
    Object? activeHazardDistanceMeters = _unset,
  }) {
    return NavigationState(
      isNavigating:
          isNavigating ?? this.isNavigating,

      isSimulating:
          isSimulating ?? this.isSimulating,

      simulationMultiplier:
          simulationMultiplier ??
          this.simulationMultiplier,

      activeRouteDetails:
          identical(activeRouteDetails, _unset)
              ? this.activeRouteDetails
              : activeRouteDetails
                  as FullRouteDetails?,

      activeVehiclePosition:
          identical(activeVehiclePosition, _unset)
              ? this.activeVehiclePosition
              : activeVehiclePosition
                  as ll.LatLng?,

      currentTurnInstruction:
          currentTurnInstruction ??
          this.currentTurnInstruction,

      distanceToNextTurnMeters:
          distanceToNextTurnMeters ??
          this.distanceToNextTurnMeters,

      activeApproachingHazard:
          identical(
            activeApproachingHazard,
            _unset,
          )
              ? this.activeApproachingHazard
              : activeApproachingHazard
                  as HazardFeature?,

      activeHazardDistanceMeters:
          identical(
            activeHazardDistanceMeters,
            _unset,
          )
              ? this.activeHazardDistanceMeters
              : activeHazardDistanceMeters
                  as double?,
    );
  }
}

class NavigationNotifier
    extends StateNotifier<NavigationState> {
  NavigationNotifier()
      : super(
          const NavigationState(),
        );

  void setRoute(
    FullRouteDetails details,
  ) {
    state = state.copyWith(
      activeRouteDetails: details,
      activeApproachingHazard: null,
      activeHazardDistanceMeters: null,
    );
  }

  void startNavigation({
    required bool simulate,
    required ll.LatLng startPos,
  }) {
    FlutterBackgroundService()
        .startService();

    state = state.copyWith(
      isNavigating: true,
      isSimulating: simulate,
      activeVehiclePosition: startPos,
      currentTurnInstruction:
          'Συνεχίστε στην πορεία σας',
      distanceToNextTurnMeters: 0,
      activeApproachingHazard: null,
      activeHazardDistanceMeters: null,
    );
  }

  void stopNavigation() {
    FlutterBackgroundService()
        .invoke(
          'stopService',
        );

    state = state.copyWith(
      isNavigating: false,
      isSimulating: false,
      activeApproachingHazard: null,
      activeHazardDistanceMeters: null,
      currentTurnInstruction:
          'Συνεχίστε στην πορεία σας',
      distanceToNextTurnMeters: 0,
    );
  }

  void updateSimulationMultiplier(
    int multiplier,
  ) {
    state = state.copyWith(
      simulationMultiplier: multiplier,
    );
  }

  void updateVehiclePosition(
    ll.LatLng position,
  ) {
    state = state.copyWith(
      activeVehiclePosition: position,
    );
  }

  void updateTurnInstruction(
    String instruction,
    double distance,
  ) {
    state = state.copyWith(
      currentTurnInstruction: instruction,
      distanceToNextTurnMeters: distance,
    );
  }

  void updateApproachingHazard(
    HazardFeature? hazard, {
    double? distanceAheadMeters,
  }) {
    if (hazard != null) {
      final previousHazard =
          state.activeApproachingHazard;

      final isNewHazard =
          previousHazard == null ||
          previousHazard.stableKey !=
              hazard.stableKey;

      if (isNewHazard) {
        FlutterBackgroundService()
            .invoke(
              'playHazardAlert',
            );
      }
    }

    state = state.copyWith(
      activeApproachingHazard: hazard,
      activeHazardDistanceMeters:
          hazard == null
              ? null
              : distanceAheadMeters,
    );
  }
}

final navigationProvider =
    StateNotifierProvider<
        NavigationNotifier,
        NavigationState>(
  (ref) {
    return NavigationNotifier();
  },
);