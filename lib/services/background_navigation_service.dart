import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:just_audio/just_audio.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundStart,
      autoStart: false,
      isForegroundMode: true,
      // No custom notificationChannelId: the plugin only creates its default
      // channel itself. A custom id needs a channel created by the app first,
      // otherwise Android kills the app with "Bad notification for
      // startForeground" as soon as the service starts.
      initialNotificationTitle: 'Πλοήγηση RSI',
      initialNotificationContent: 'Η πλοήγηση είναι ενεργή',
      // foregroundServiceType removed to prevent the undefined error
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onBackgroundStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onBackgroundStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final player = AudioPlayer();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('playHazardAlert').listen((event) async {
    await player.setAudioSource(AudioSource.uri(Uri.parse('asset:///assets/audio/hazard_alert.mp3')));
    await player.play();
  });
}