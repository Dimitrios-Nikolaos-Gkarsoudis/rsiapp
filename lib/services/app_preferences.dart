import 'package:shared_preferences/shared_preferences.dart';

/// Settings saved on the device between app launches.
class AppPreferences {
  AppPreferences._(this._preferences);

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _useDeviceLocationKey = 'use_device_location';

  final SharedPreferences _preferences;

  static Future<AppPreferences> load() async {
    return AppPreferences._(await SharedPreferences.getInstance());
  }

  bool get onboardingCompleted {
    return _preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Whether the user agreed to share their device location with the app.
  bool get useDeviceLocation {
    return _preferences.getBool(_useDeviceLocationKey) ?? false;
  }

  Future<void> saveOnboardingCompleted({required bool useDeviceLocation}) async {
    await _preferences.setBool(_useDeviceLocationKey, useDeviceLocation);
    await _preferences.setBool(_onboardingCompletedKey, true);
  }

  Future<void> saveUseDeviceLocation(bool value) async {
    await _preferences.setBool(_useDeviceLocationKey, value);
  }
}
