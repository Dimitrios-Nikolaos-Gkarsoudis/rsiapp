import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/widgets/map_compass_button.dart';

Future<void> _pumpCompass(
  WidgetTester tester, {
  required ValueNotifier<double> bearing,
  VoidCallback? onTap,
  String? tooltip,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: tooltip == null
              ? MapCompassButton(bearing: bearing, onTap: onTap ?? () {})
              : MapCompassButton(
                  bearing: bearing,
                  onTap: onTap ?? () {},
                  tooltip: tooltip,
                ),
        ),
      ),
    ),
  );
}

Matrix4 _needleTransform(WidgetTester tester) {
  return tester
      .widget<Transform>(find.byKey(MapCompassButton.needleKey))
      .transform;
}

void main() {
  testWidgets('needle turns with the map to keep pointing north',
      (tester) async {
    final bearing = ValueNotifier<double>(0);
    addTearDown(bearing.dispose);

    await _pumpCompass(tester, bearing: bearing);

    // North-up: no rotation.
    expect(_needleTransform(tester).storage[0], closeTo(1, 1e-9));

    bearing.value = 90;
    await tester.pump();

    // Map rotated 90° clockwise, needle rotated -90°: cos = 0, sin = -1.
    expect(_needleTransform(tester).storage[0], closeTo(0, 1e-9));
    expect(_needleTransform(tester).storage[1], closeTo(-1, 1e-9));
  });

  testWidgets('tapping calls onTap', (tester) async {
    final bearing = ValueNotifier<double>(45);
    addTearDown(bearing.dispose);
    var taps = 0;

    await _pumpCompass(tester, bearing: bearing, onTap: () => taps++);

    await tester.tap(find.byType(MapCompassButton));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('uses the reset tooltip by default and accepts a custom one',
      (tester) async {
    final bearing = ValueNotifier<double>(0);
    addTearDown(bearing.dispose);

    await _pumpCompass(tester, bearing: bearing);
    expect(find.byTooltip('Reset map to north'), findsOneWidget);

    await _pumpCompass(tester, bearing: bearing, tooltip: 'Keep north up');
    expect(find.byTooltip('Keep north up'), findsOneWidget);
  });
}
