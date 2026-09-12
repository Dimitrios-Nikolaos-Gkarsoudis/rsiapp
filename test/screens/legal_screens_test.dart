import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/screens/legal/privacy_policy_screen.dart';
import 'package:rsi/screens/legal/terms_screen.dart';

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Terms & Conditions shows the full bundled document',
      (tester) async {
    await _pumpScreen(tester, const TermsScreen());

    expect(find.widgetWithText(AppBar, 'Terms & Conditions'), findsOneWidget);
    expect(find.text('4. Safety comes first'), findsOneWidget);
    expect(find.text('8. Car rentals and partner offers'), findsOneWidget);
    expect(find.text('18. Contact us'), findsOneWidget);
    expect(find.textContaining("couldn't be loaded"), findsNothing);
  });

  testWidgets('Privacy Policy shows the full bundled document',
      (tester) async {
    await _pumpScreen(tester, const PrivacyPolicyScreen());

    expect(find.widgetWithText(AppBar, 'Privacy Policy'), findsOneWidget);
    expect(find.text('1. Who is responsible for your data'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('8. Your rights'), findsOneWidget);
    expect(find.textContaining("couldn't be loaded"), findsNothing);
  });
}
