import 'package:latlong2/latlong.dart';

enum RentalCategory {
  mini('Mini'),
  economy('Economy'),
  compact('Compact'),
  suv('SUV'),
  offroad('4x4'),
  convertible('Convertible'),
  van('Van');

  const RentalCategory(this.label);

  final String label;
}

enum Transmission {
  manual('Manual'),
  automatic('Automatic');

  const Transmission(this.label);

  final String label;
}

enum FuelType {
  petrol('Petrol'),
  diesel('Diesel'),
  hybrid('Hybrid'),
  electric('Electric');

  const FuelType(this.label);

  final String label;
}

enum InsuranceCoverage {
  basic('Basic (CDW)'),
  full('Full coverage');

  const InsuranceCoverage(this.label);

  final String label;
}

/// A rental company. Partners are the companies RSI collaborates with and
/// promotes inside the app.
class RentalCompany {
  final String id;
  final String name;
  final String tagline;
  final bool isPartner;

  /// ARGB brand colour, e.g. 0xFF0B7A75.
  final int brandColorValue;
  final double rating;
  final int reviewCount;
  final String phone;
  final String email;
  final String website;

  const RentalCompany({
    required this.id,
    required this.name,
    required this.tagline,
    required this.isPartner,
    required this.brandColorValue,
    required this.rating,
    required this.reviewCount,
    required this.phone,
    required this.email,
    required this.website,
  });

  /// Up to two initials, used as a logo placeholder.
  String get initials {
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  factory RentalCompany.fromJson(Map<String, dynamic> json) {
    return RentalCompany(
      id: _requireString(json, 'id'),
      name: _requireString(json, 'name'),
      tagline: _optionalString(json, 'tagline'),
      isPartner: json['isPartner'] == true,
      brandColorValue: _parseHexColor(json['brandColor']),
      rating: _optionalNum(json, 'rating')?.toDouble() ?? 0,
      reviewCount: _optionalNum(json, 'reviewCount')?.toInt() ?? 0,
      phone: _optionalString(json, 'phone'),
      email: _optionalString(json, 'email'),
      website: _optionalString(json, 'website'),
    );
  }
}

/// A partner promotion applied to a rental's daily price.
class RentalPromotion {
  static const int maxDiscountPercent = 90;

  final String label;
  final int discountPercent;

  /// Last day the promotion applies (inclusive). Null means no end date.
  final DateTime? validUntil;

  const RentalPromotion({
    required this.label,
    required this.discountPercent,
    this.validUntil,
  });

  bool isActiveOn(DateTime date) {
    final end = validUntil;

    if (end == null) {
      return true;
    }

    final day = DateTime(date.year, date.month, date.day);
    final lastDay = DateTime(end.year, end.month, end.day);

    return !day.isAfter(lastDay);
  }

  factory RentalPromotion.fromJson(Map<String, dynamic> json) {
    final discount = _requireNum(json, 'discountPercent').toInt();

    if (discount < 1 || discount > maxDiscountPercent) {
      throw FormatException(
        'discountPercent must be between 1 and $maxDiscountPercent, '
        'got $discount.',
      );
    }

    return RentalPromotion(
      label: _requireString(json, 'label'),
      discountPercent: discount,
      validUntil: _optionalDate(json, 'validUntil'),
    );
  }
}

class PickupLocation {
  final String name;
  final LatLng location;

  const PickupLocation({
    required this.name,
    required this.location,
  });

  factory PickupLocation.fromJson(Map<String, dynamic> json) {
    final latitude = _requireNum(json, 'latitude').toDouble();
    final longitude = _requireNum(json, 'longitude').toDouble();

    if (latitude.abs() > 90 || longitude.abs() > 180) {
      throw FormatException(
        'Pickup coordinates out of range: $latitude, $longitude.',
      );
    }

    return PickupLocation(
      name: _requireString(json, 'name'),
      location: LatLng(latitude, longitude),
    );
  }
}

/// One car offered for rent by a company.
class RentalOffer {
  final String id;
  final RentalCompany company;
  final String title;
  final RentalCategory category;

  /// Asset path of the car photo.
  final String image;
  final double pricePerDay;
  final String currency;
  final RentalPromotion? promotion;
  final Transmission transmission;
  final FuelType fuelType;
  final int seats;
  final int doors;
  final int luggage;
  final bool airConditioning;
  final int minDriverAge;
  final double depositAmount;
  final InsuranceCoverage insurance;

  /// Daily distance allowance. Null means unlimited mileage.
  final int? mileageLimitKmPerDay;
  final PickupLocation pickup;
  final bool available;

  const RentalOffer({
    required this.id,
    required this.company,
    required this.title,
    required this.category,
    required this.image,
    required this.pricePerDay,
    required this.currency,
    required this.promotion,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.doors,
    required this.luggage,
    required this.airConditioning,
    required this.minDriverAge,
    required this.depositAmount,
    required this.insurance,
    required this.mileageLimitKmPerDay,
    required this.pickup,
    required this.available,
  });

  bool get hasUnlimitedMileage => mileageLimitKmPerDay == null;

  RentalPromotion? activePromotionOn(DateTime date) {
    final current = promotion;
    return current != null && current.isActiveOn(date) ? current : null;
  }

  /// Daily price after any promotion running on [date].
  double pricePerDayOn(DateTime date) {
    final active = activePromotionOn(date);

    if (active == null) {
      return pricePerDay;
    }

    return pricePerDay * (100 - active.discountPercent) / 100;
  }

  factory RentalOffer.fromJson(
    Map<String, dynamic> json,
    Map<String, RentalCompany> companiesById,
  ) {
    final id = _requireString(json, 'id');
    final companyId = _requireString(json, 'companyId');
    final company = companiesById[companyId];

    if (company == null) {
      throw FormatException('unknown company "$companyId".');
    }

    final rawPromotion = json['promotion'];

    return RentalOffer(
      id: id,
      company: company,
      title: _requireString(json, 'title'),
      category: _requireEnum(RentalCategory.values, json, 'category'),
      image: _requireString(json, 'image'),
      pricePerDay: _requirePositive(json, 'pricePerDay'),
      currency: _requireString(json, 'currency'),
      promotion: rawPromotion == null
          ? null
          : RentalPromotion.fromJson(_asJsonObject(rawPromotion)),
      transmission: _requireEnum(Transmission.values, json, 'transmission'),
      fuelType: _requireEnum(FuelType.values, json, 'fuelType'),
      seats: _requireNum(json, 'seats').toInt(),
      doors: _requireNum(json, 'doors').toInt(),
      luggage: _requireNum(json, 'luggage').toInt(),
      airConditioning: json['airConditioning'] == true,
      minDriverAge: _requireNum(json, 'minDriverAge').toInt(),
      depositAmount: _requireNum(json, 'depositAmount').toDouble(),
      insurance: _requireEnum(InsuranceCoverage.values, json, 'insurance'),
      mileageLimitKmPerDay:
          _optionalNum(json, 'mileageLimitKmPerDay')?.toInt(),
      pickup: PickupLocation.fromJson(_asJsonObject(json['pickup'])),
      available: json['available'] != false,
    );
  }
}

class RentalCatalog {
  final List<RentalCompany> companies;
  final List<RentalOffer> rentals;

  const RentalCatalog({
    required this.companies,
    required this.rentals,
  });

  /// Bookable partner cars with a promotion running on [date], biggest
  /// discount first.
  List<RentalOffer> partnerOffersOn(DateTime date) {
    final offers = rentals
        .where(
          (rental) =>
              rental.available &&
              rental.company.isPartner &&
              rental.activePromotionOn(date) != null,
        )
        .toList()
      ..sort(
        (a, b) => b.promotion!.discountPercent.compareTo(
          a.promotion!.discountPercent,
        ),
      );

    return List.unmodifiable(offers);
  }

  /// Parses the catalog JSON.
  ///
  /// Malformed companies or rentals are skipped and reported through
  /// [onInvalidRecord] so one bad record does not hide the whole catalog.
  factory RentalCatalog.fromJson(
    Map<String, dynamic> json, {
    void Function(Object error)? onInvalidRecord,
  }) {
    final rawCompanies = json['companies'];
    final rawRentals = json['rentals'];

    if (rawCompanies is! List || rawRentals is! List) {
      throw const FormatException(
        'Rental catalog needs "companies" and "rentals" arrays.',
      );
    }

    final companiesById = <String, RentalCompany>{};

    for (final raw in rawCompanies) {
      try {
        final company = RentalCompany.fromJson(_asJsonObject(raw));
        companiesById[company.id] = company;
      } on FormatException catch (error) {
        onInvalidRecord?.call(
          FormatException('company ${_recordId(raw)}: ${error.message}'),
        );
      }
    }

    final rentals = <RentalOffer>[];

    for (final raw in rawRentals) {
      try {
        rentals.add(RentalOffer.fromJson(_asJsonObject(raw), companiesById));
      } on FormatException catch (error) {
        onInvalidRecord?.call(
          FormatException('rental ${_recordId(raw)}: ${error.message}'),
        );
      }
    }

    return RentalCatalog(
      companies: List.unmodifiable(companiesById.values),
      rentals: List.unmodifiable(rentals),
    );
  }
}

String _recordId(Object? raw) {
  return raw is Map && raw['id'] != null ? '"${raw['id']}"' : '(no id)';
}

Map<String, dynamic> _asJsonObject(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw const FormatException('expected a JSON object.');
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  throw FormatException('missing or empty "$key".');
}

String _optionalString(Map<String, dynamic> json, String key) {
  return json[key]?.toString() ?? '';
}

num _requireNum(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is num) {
    return value;
  }

  throw FormatException('missing or non-numeric "$key".');
}

num? _optionalNum(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value == null || value is num) {
    return value as num?;
  }

  throw FormatException('"$key" must be a number.');
}

double _requirePositive(Map<String, dynamic> json, String key) {
  final value = _requireNum(json, key).toDouble();

  if (value <= 0) {
    throw FormatException('"$key" must be greater than zero.');
  }

  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value == null) {
    return null;
  }

  final parsed = DateTime.tryParse(value.toString());

  if (parsed == null) {
    throw FormatException('invalid date "$value" for "$key".');
  }

  return parsed;
}

T _requireEnum<T extends Enum>(
  List<T> values,
  Map<String, dynamic> json,
  String key,
) {
  final raw = _requireString(json, key);
  final match = values.asNameMap()[raw];

  if (match == null) {
    throw FormatException('unknown $key "$raw".');
  }

  return match;
}

int _parseHexColor(Object? value) {
  const fallback = 0xFF1A73E8;

  if (value is! String) {
    return fallback;
  }

  final hex = value.replaceFirst('#', '');

  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return fallback;
  }

  return 0xFF000000 | int.parse(hex, radix: 16);
}
