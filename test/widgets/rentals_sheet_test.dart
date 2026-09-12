import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/models/rental_model.dart';
import 'package:rsi/providers/rentals_provider.dart';
import 'package:rsi/screens/rentals/rental_detail_screen.dart';
import 'package:rsi/widgets/rentals/rentals_sheet.dart';

Map<String, dynamic> _rental(
  String id,
  String title, {
  Map<String, dynamic>? promotion,
  bool available = true,
}) {
  return {
    'id': id,
    'companyId': 'partner',
    'title': title,
    'category': 'economy',
    'image': 'assets/images/rentals/missing_in_tests.jpg',
    'pricePerDay': 40,
    'currency': 'EUR',
    'promotion': promotion,
    'transmission': 'automatic',
    'fuelType': 'hybrid',
    'seats': 5,
    'doors': 5,
    'luggage': 2,
    'airConditioning': true,
    'minDriverAge': 21,
    'depositAmount': 300,
    'insurance': 'full',
    'mileageLimitKmPerDay': null,
    'pickup': {'name': 'Naxos Port', 'latitude': 37.1, 'longitude': 25.37},
    'available': available,
  };
}

RentalCatalog _fixture() {
  return RentalCatalog.fromJson({
    'companies': [
      {
        'id': 'partner',
        'name': 'Partner Cars',
        'tagline': 'Test partner',
        'isPartner': true,
        'brandColor': '#0B7A75',
        'rating': 4.7,
        'reviewCount': 20,
        'phone': '+30 22850 99999',
        'email': 'book@partner.example',
        'website': 'https://partner.example',
      },
    ],
    'rentals': [
      _rental(
        'promo',
        'Promo Panda',
        promotion: {
          'label': 'Launch deal',
          'discountPercent': 20,
          'validUntil': '2026-12-31',
        },
      ),
      _rental('busy', 'Busy Jimny', available: false),
      _rental('plain', 'Plain Polo'),
    ],
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required Future<RentalCatalog> Function() load,
}) async {
  tester.view.physicalSize = const Size(400, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rentalCatalogProvider.overrideWith((ref) => load()),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 12)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: RentalsSheet(topClearance: 80)),
            ],
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _expand(WidgetTester tester) async {
  await tester.tap(find.text('Car rentals'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('collapsed sheet summarises partner deals and cars',
      (tester) async {
    await _pumpSheet(tester, load: () async => _fixture());

    expect(find.text('Car rentals'), findsOneWidget);
    expect(find.text('1 partner deal · 3 cars'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
  });

  testWidgets('tapping the header expands to partner offers and all cars',
      (tester) async {
    await _pumpSheet(tester, load: () async => _fixture());
    await _expand(tester);

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.text('Partner offers'), findsOneWidget);
    expect(find.text('LAUNCH DEAL'), findsOneWidget);
    // Promoted car appears in the offer strip and in the full list.
    expect(find.text('Promo Panda'), findsNWidgets(2));
    expect(find.text('-20%'), findsNWidgets(2));
    // 20% off €40, with the original price struck through.
    expect(find.text('€32 / day'), findsNWidgets(2));
    expect(find.text('€40'), findsNWidgets(2));

    expect(find.text('3 cars'), findsOneWidget);
    expect(find.text('Plain Polo'), findsOneWidget);
    expect(find.text('Busy Jimny'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
  });

  testWidgets('lists bookable cars before unavailable ones', (tester) async {
    await _pumpSheet(tester, load: () async => _fixture());
    await _expand(tester);

    final plainTop = tester.getTopLeft(find.text('Plain Polo')).dy;
    final busyTop = tester.getTopLeft(find.text('Busy Jimny')).dy;

    expect(plainTop, lessThan(busyTop));
  });

  testWidgets('back button collapses the expanded sheet', (tester) async {
    await _pumpSheet(tester, load: () async => _fixture());
    await _expand(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
  });

  testWidgets('opens a car and shows how to contact the company',
      (tester) async {
    await _pumpSheet(tester, load: () async => _fixture());
    await _expand(tester);

    await tester.tap(find.text('Plain Polo'));
    await tester.pumpAndSettle();

    expect(find.byType(RentalDetailScreen), findsOneWidget);
    expect(find.text('Rental terms'), findsOneWidget);
    expect(find.text('Unlimited'), findsOneWidget);

    await tester.tap(find.text('Contact to book'));
    await tester.pumpAndSettle();

    expect(find.text('Contact Partner Cars'), findsOneWidget);
    expect(find.text('+30 22850 99999'), findsOneWidget);
  });

  testWidgets('an unavailable car cannot be booked', (tester) async {
    await _pumpSheet(tester, load: () async => _fixture());
    await _expand(tester);

    await tester.tap(find.text('Busy Jimny'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Not available'),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('shows an error with retry when loading fails', (tester) async {
    var attempts = 0;

    await _pumpSheet(
      tester,
      load: () async {
        attempts++;

        if (attempts == 1) {
          throw const FormatException('broken catalog');
        }

        return _fixture();
      },
    );

    expect(find.text("Couldn't load rentals"), findsOneWidget);

    await _expand(tester);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('1 partner deal · 3 cars'), findsOneWidget);
    expect(attempts, 2);
  });
}
