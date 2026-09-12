class AppConfig {
  AppConfig._();

  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );

  static const String routingBaseUrl = String.fromEnvironment(
    'ROUTING_BASE_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  static bool get hasMapboxAccessToken => mapboxAccessToken.trim().isNotEmpty;

  static void validate() {
    if (!hasMapboxAccessToken) {
      throw StateError(
        'MAPBOX_ACCESS_TOKEN is missing.\n'
        'Run the app with:\n'
        'flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_TOKEN',
      );
    }
  }
}