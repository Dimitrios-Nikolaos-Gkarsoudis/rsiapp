import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/models/rental_model.dart';

Map<String, dynamic> _company({
  String id = 'acme',
  bool isPartner = true,
}) {
  return {
    'id': id,
    'name': 'Acme Cars',
    'tagline': 'Test company',
    'isPartner': isPartner,
    'brandColor': '#0B7A75',
    'rating': 4.5,
    'reviewCount': 10,
    'phone': '+30 000 000',
    'email': 'hello@acme.example',
    'website': 'https://acme.example',
  };
}

Map<String, dynamic> _rental({
  String id = 'car-1',
  String companyId = 'acme',
  num price = 40,
  Map<String, dynamic>? promotion,
  bool available = true,
  Object? category = 'mini',
  Object? mileageLimit,
}) {
  return {
    'id': id,
    'companyId': companyId,
    'title': 'Test Car',
    'category': category,
    'image': 'assets/images/rentals/test.jpg',
    'pricePerDay': price,
    'currency': 'EUR',
    'promotion': promotion,
    'transmission': 'manual',
    'fuelType': 'petrol',
    'seats': 4,
    'doors': 5,
    'luggage': 2,
    'airConditioning': true,
    'minDriverAge': 21,
    'depositAmount': 250,
    'insurance': 'basic',
    'mileageLimitKmPerDay': mileageLimit,
    'pickup': {
      'name': 'Naxos Port',
      'latitude': 37.1,
      'longitude': 25.37,
    },
    'available': available,
  };
}

Map<String, dynamic> _promotion(int discount, {String? validUntil}) {
  return {
    'label': 'Deal',
    'discountPercent': discount,
    'validUntil': validUntil,
  };
}

RentalCatalog _catalog(
  List<Object?> rentals, {
  List<Object?>? companies,
  List<Object>? errors,
}) {
  return RentalCatalog.fromJson(
    {
      'companies': companies ?? [_company()],
      'rentals': rentals,
    },
    onInvalidRecord: errors?.add,
  );
}

final DateTime _today = DateTime(2026, 9, 12);

void main() {
  group('RentalCatalog.fromJson', () {
    test('links each rental to its company and parses fields', () {
      final catalog = _catalog([_rental()]);
      final rental = catalog.rentals.single;

      expect(catalog.companies, hasLength(1));
      expect(rental.company.name, 'Acme Cars');
      expect(rental.company.brandColorValue, 0xFF0B7A75);
      expect(rental.company.initials, 'AC');
      expect(rental.category, RentalCategory.mini);
      expect(rental.transmission, Transmission.manual);
      expect(rental.pickup.location.latitude, 37.1);
      expect(rental.promotion, isNull);
      expect(rental.hasUnlimitedMileage, isTrue);
    });

    test('keeps a daily mileage limit when one is set', () {
      final rental = _catalog([_rental(mileageLimit: 200)]).rentals.single;

      expect(rental.hasUnlimitedMileage, isFalse);
      expect(rental.mileageLimitKmPerDay, 200);
    });

    test('skips and reports invalid records without dropping valid ones', () {
      final errors = <Object>[];

      final catalog = _catalog(
        [
          _rental(id: 'ok'),
          _rental(id: 'orphan', companyId: 'missing'),
          _rental(id: 'bad-category', category: 'spaceship'),
          _rental(id: 'free', price: 0),
          _rental(id: 'huge-discount', promotion: _promotion(95)),
          'not an object',
        ],
        errors: errors,
      );

      expect(catalog.rentals.map((rental) => rental.id), ['ok']);
      expect(errors, hasLength(5));
      expect(errors.first.toString(), contains('orphan'));
    });

    test('throws when the top-level arrays are missing', () {
      expect(
        () => RentalCatalog.fromJson({'companies': []}),
        throwsFormatException,
      );
    });
  });

  group('promotions', () {
    test('an active promotion discounts the daily price', () {
      final rental = _catalog([
        _rental(price: 40, promotion: _promotion(15, validUntil: '2026-10-31')),
      ]).rentals.single;

      expect(rental.activePromotionOn(_today), isNotNull);
      expect(rental.pricePerDayOn(_today), 34);
    });

    test('a promotion applies through the end of its last day', () {
      final rental = _catalog([
        _rental(price: 40, promotion: _promotion(25, validUntil: '2026-09-12')),
      ]).rentals.single;

      expect(rental.pricePerDayOn(DateTime(2026, 9, 12, 23, 59)), 30);
      expect(rental.pricePerDayOn(DateTime(2026, 9, 13)), 40);
    });

    test('a promotion without an end date is always active', () {
      final rental = _catalog([
        _rental(price: 40, promotion: _promotion(10)),
      ]).rentals.single;

      expect(rental.pricePerDayOn(DateTime(2030)), 36);
    });

    test('partner offers are bookable partner deals, biggest discount first',
        () {
      final catalog = _catalog(
        [
          _rental(id: 'small', promotion: _promotion(10)),
          _rental(id: 'big', promotion: _promotion(25)),
          _rental(id: 'booked', promotion: _promotion(30), available: false),
          _rental(id: 'not-partner', companyId: 'other', promotion: _promotion(50)),
          _rental(
            id: 'expired',
            promotion: _promotion(40, validUntil: '2026-09-01'),
          ),
          _rental(id: 'no-deal'),
        ],
        companies: [_company(), _company(id: 'other', isPartner: false)],
      );

      expect(
        catalog.partnerOffersOn(_today).map((rental) => rental.id),
        ['big', 'small'],
      );
    });
  });
}
