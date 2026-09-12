import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'config/app_config.dart';
import 'screens/live_tracking_screen.dart';
import 'services/background_navigation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.validate();

  MapboxOptions.setAccessToken(
    AppConfig.mapboxAccessToken,
  );

  await initializeBackgroundService();

  runApp(
    const ProviderScope(
      child: RoadSafetyInsightsApp(),
    ),
  );
}

class RoadSafetyInsightsApp extends StatelessWidget {
  const RoadSafetyInsightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A73E8);

    return MaterialApp(
      title: 'RSI Road Safety Insights',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.light,
          primary: blue,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF1F3F4),
        splashFactory:
            InkSparkle.splashFactory,
        textSelectionTheme:
            const TextSelectionThemeData(
          cursorColor: blue,
          selectionColor:
              Color(0x443366FF),
          selectionHandleColor: blue,
        ),
      ),
      home:
          const LiveTrackingScreen(),
    );
  }
}