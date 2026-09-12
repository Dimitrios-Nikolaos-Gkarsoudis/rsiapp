import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/services/rental_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled mock catalog parses without skipping any record', () async {
    final errors = <Object>[];

    final catalog = await RentalService.loadCatalog(
      onInvalidRecord: errors.add,
    );

    expect(errors, isEmpty);
    expect(catalog.companies, hasLength(2));
    expect(catalog.companies.every((company) => company.isPartner), isTrue);
    expect(catalog.rentals, hasLength(8));
  });

  test('every rental image in the catalog is bundled', () async {
    final catalog = await RentalService.loadCatalog();

    for (final rental in catalog.rentals) {
      await expectLater(
        rootBundle.load(rental.image),
        completes,
        reason: '${rental.id} uses ${rental.image}',
      );
    }
  });
}
