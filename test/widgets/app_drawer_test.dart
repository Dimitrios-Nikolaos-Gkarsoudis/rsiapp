import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/config/app_routes.dart';
import 'package:rsi/widgets/app_drawer.dart';

Future<void> _pumpOpenDrawer(WidgetTester tester) async {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  await tester.pumpWidget(
    MaterialApp(
      routes: AppRoutes.routes,
      home: Scaffold(
        key: scaffoldKey,
        drawer: const AppDrawer(),
        body: const SizedBox.shrink(),
      ),
    ),
  );

  scaffoldKey.currentState!.openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  const destinations = [
    'About RSI',
    'Terms & Conditions',
    'Privacy Policy',
  ];

  testWidgets('drawer lists every destination', (tester) async {
    await _pumpOpenDrawer(tester);

    for (final label in destinations) {
      expect(find.text(label), findsOneWidget);
    }
  });

  for (final label in destinations) {
    testWidgets('tapping "$label" closes the drawer and opens its page',
        (tester) async {
      await _pumpOpenDrawer(tester);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsNothing);
      expect(find.widgetWithText(AppBar, label), findsOneWidget);
    });
  }
}
