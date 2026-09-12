import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_preferences.dart';

/// Device-saved preferences, overridden in `main()` once they are loaded.
final appPreferencesProvider = Provider<AppPreferences>((ref) {
  throw UnimplementedError(
    'appPreferencesProvider must be overridden with AppPreferences.load().',
  );
});

class AppSetupState {
  const AppSetupState({
    required this.onboardingCompleted,
    required this.useDeviceLocation,
  });

  final bool onboardingCompleted;

  /// The user agreed to share their location; the location stream only runs
  /// while this is true.
  final bool useDeviceLocation;
}

class AppSetupNotifier extends Notifier<AppSetupState> {
  @override
  AppSetupState build() {
    final preferences = ref.watch(appPreferencesProvider);

    return AppSetupState(
      onboardingCompleted: preferences.onboardingCompleted,
      useDeviceLocation: preferences.useDeviceLocation,
    );
  }

  Future<void> completeOnboarding({required bool useDeviceLocation}) async {
    await ref
        .read(appPreferencesProvider)
        .saveOnboardingCompleted(useDeviceLocation: useDeviceLocation);

    state = AppSetupState(
      onboardingCompleted: true,
      useDeviceLocation: useDeviceLocation,
    );
  }

  Future<void> setUseDeviceLocation(bool value) async {
    await ref.read(appPreferencesProvider).saveUseDeviceLocation(value);

    state = AppSetupState(
      onboardingCompleted: state.onboardingCompleted,
      useDeviceLocation: value,
    );
  }
}

final appSetupProvider =
    NotifierProvider<AppSetupNotifier, AppSetupState>(AppSetupNotifier.new);
