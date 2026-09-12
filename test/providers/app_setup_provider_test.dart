import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/providers/app_setup_provider.dart';
import 'package:rsi/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fresh container reading saved preferences, like an app launch.
Future<ProviderContainer> _launchApp() async {
  final preferences = await AppPreferences.load();
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first launch shows onboarding and does not use location', () async {
    final app = await _launchApp();

    expect(app.read(appSetupProvider).onboardingCompleted, isFalse);
    expect(app.read(appSetupProvider).useDeviceLocation, isFalse);
  });

  test('finishing onboarding with location is remembered next launch',
      () async {
    final firstLaunch = await _launchApp();
    await firstLaunch
        .read(appSetupProvider.notifier)
        .completeOnboarding(useDeviceLocation: true);

    final nextLaunch = await _launchApp();

    expect(nextLaunch.read(appSetupProvider).onboardingCompleted, isTrue);
    expect(nextLaunch.read(appSetupProvider).useDeviceLocation, isTrue);
  });

  test('skipping location keeps it off but completes onboarding', () async {
    final app = await _launchApp();
    await app
        .read(appSetupProvider.notifier)
        .completeOnboarding(useDeviceLocation: false);

    expect(app.read(appSetupProvider).onboardingCompleted, isTrue);
    expect(app.read(appSetupProvider).useDeviceLocation, isFalse);
  });

  test('location can be turned on later and is saved', () async {
    final app = await _launchApp();
    await app
        .read(appSetupProvider.notifier)
        .completeOnboarding(useDeviceLocation: false);
    await app.read(appSetupProvider.notifier).setUseDeviceLocation(true);

    final nextLaunch = await _launchApp();

    expect(nextLaunch.read(appSetupProvider).useDeviceLocation, isTrue);
  });
}
