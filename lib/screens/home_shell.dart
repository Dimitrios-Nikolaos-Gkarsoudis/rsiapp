import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_setup_provider.dart';
import '../services/location_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/onboarding/onboarding_dialog.dart';
import 'live_tracking_screen.dart';

/// Top-level layout: the side drawer around the map screen, plus the
/// first-launch onboarding on top of it.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  Future<void> _finishOnboarding(
    BuildContext context,
    WidgetRef ref, {
    required bool useLocation,
  }) async {
    // Location permission is only requested once the user chooses to share it.
    final granted =
        useLocation && await LocationService.checkAndRequestPermissions();

    await ref
        .read(appSetupProvider.notifier)
        .completeOnboarding(useDeviceLocation: granted);

    if (useLocation && !granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location access was not allowed. You can turn it on later '
            'with the location button.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(
      appSetupProvider.select((setup) => setup.onboardingCompleted),
    );

    return Scaffold(
      drawer: const AppDrawer(),
      // Edge swipes would fight with panning the map.
      drawerEnableOpenDragGesture: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LiveTrackingScreen(),
          if (!onboardingCompleted)
            OnboardingDialog(
              onUseLocation: () =>
                  _finishOnboarding(context, ref, useLocation: true),
              onSkipLocation: () =>
                  _finishOnboarding(context, ref, useLocation: false),
            ),
        ],
      ),
    );
  }
}
