import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/widgets/onboarding/onboarding_dialog.dart';

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  Future<void> Function()? onUseLocation,
  VoidCallback? onSkipLocation,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OnboardingDialog(
          onUseLocation: onUseLocation ?? () async {},
          onSkipLocation: onSkipLocation ?? () {},
        ),
      ),
    ),
  );
}

Future<void> _tapAndSettle(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('walks through the intro pages with Next', (tester) async {
    await _pumpOnboarding(tester);

    expect(find.text('Welcome to Road Safety Insights'), findsOneWidget);
    expect(find.text('Use my location'), findsNothing);

    await _tapAndSettle(tester, 'Next');
    expect(find.text('See risky spots'), findsOneWidget);

    await _tapAndSettle(tester, 'Next');
    expect(find.text('Get warned ahead'), findsOneWidget);

    await _tapAndSettle(tester, 'Next');
    expect(find.text('Use your location?'), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('pages can be swiped', (tester) async {
    await _pumpOnboarding(tester);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('See risky spots'), findsOneWidget);
  });

  testWidgets('Skip goes straight to the location choice', (tester) async {
    await _pumpOnboarding(tester);

    await _tapAndSettle(tester, 'Skip');

    expect(find.text('Use your location?'), findsOneWidget);
  });

  testWidgets('Use my location calls onUseLocation', (tester) async {
    var usedLocation = false;
    var skipped = false;

    await _pumpOnboarding(
      tester,
      onUseLocation: () async => usedLocation = true,
      onSkipLocation: () => skipped = true,
    );

    await _tapAndSettle(tester, 'Skip');
    await _tapAndSettle(tester, 'Use my location');

    expect(usedLocation, isTrue);
    expect(skipped, isFalse);
  });

  testWidgets('Not now calls onSkipLocation', (tester) async {
    var usedLocation = false;
    var skipped = false;

    await _pumpOnboarding(
      tester,
      onUseLocation: () async => usedLocation = true,
      onSkipLocation: () => skipped = true,
    );

    await _tapAndSettle(tester, 'Skip');
    await _tapAndSettle(tester, 'Not now');

    expect(skipped, isTrue);
    expect(usedLocation, isFalse);
  });
}
