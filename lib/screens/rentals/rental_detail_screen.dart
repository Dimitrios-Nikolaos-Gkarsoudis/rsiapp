import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/format/formatters.dart';
import '../../models/rental_model.dart';
import '../../widgets/rentals/rental_image.dart';
import '../../widgets/rentals/rental_price.dart';
import '../../widgets/rentals/rental_spec_chip.dart';
import 'rental_contact_sheet.dart';

class RentalDetailScreen extends StatelessWidget {
  const RentalDetailScreen({
    super.key,
    required this.offer,
    required this.now,
  });

  final RentalOffer offer;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final promotion = offer.activePromotionOn(now);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Material(
                color: Colors.white,
                shape: CircleBorder(),
                child: BackButton(color: AppColors.textPrimary),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  RentalImage(asset: offer.image),
                  if (promotion != null)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: RentalDiscountBadge(
                        percent: promotion.discountPercent,
                        large: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            sliver: SliverList.list(
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.category.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _CompanyTile(company: offer.company),
                if (promotion != null) ...[
                  const SizedBox(height: 12),
                  _PromotionBanner(promotion: promotion),
                ],
                if (!offer.available) ...[
                  const SizedBox(height: 12),
                  const _UnavailableBanner(),
                ],
                const _SectionTitle('Specifications'),
                _SpecGrid(offer: offer),
                const _SectionTitle('Rental terms'),
                _TermRow(
                  icon: Icons.badge_outlined,
                  label: 'Minimum driver age',
                  value: '${offer.minDriverAge}',
                ),
                _TermRow(
                  icon: Icons.savings_outlined,
                  label: 'Deposit',
                  value: formatPrice(offer.depositAmount, offer.currency),
                ),
                _TermRow(
                  icon: Icons.shield_outlined,
                  label: 'Insurance',
                  value: offer.insurance.label,
                ),
                _TermRow(
                  icon: Icons.route_outlined,
                  label: 'Mileage',
                  value: offer.hasUnlimitedMileage
                      ? 'Unlimited'
                      : '${offer.mileageLimitKmPerDay} km / day',
                ),
                const _SectionTitle('Pick-up'),
                _TermRow(
                  icon: Icons.place_outlined,
                  label: 'Location',
                  value: offer.pickup.name,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BookingBar(offer: offer, now: now),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company});

  final RentalCompany company;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(company.brandColorValue),
            child: Text(
              company.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (company.isPartner)
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'RSI partner',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (company.tagline.isNotEmpty)
                  Text(
                    company.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          if (company.reviewCount > 0) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star_rounded, size: 18, color: AppColors.rating),
            const SizedBox(width: 2),
            Text(
              '${company.rating.toStringAsFixed(1)} (${company.reviewCount})',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PromotionBanner extends StatelessWidget {
  const _PromotionBanner({required this.promotion});

  final RentalPromotion promotion;

  @override
  Widget build(BuildContext context) {
    final validUntil = promotion.validUntil;
    final discount = '${promotion.discountPercent}% off the daily price';
    final details = validUntil == null
        ? discount
        : '$discount · until ${formatShortDate(validUntil)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.promoContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_offer_rounded, color: AppColors.promo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.label,
                  style: const TextStyle(
                    color: AppColors.promo,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_busy_rounded, color: AppColors.error),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This car is not available right now.',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.offer});

  static const double _spacing = 10;
  static const int _columns = 3;

  final RentalOffer offer;

  @override
  Widget build(BuildContext context) {
    final specs = <(IconData, String, String)>[
      (Icons.person_outline_rounded, '${offer.seats}', 'Seats'),
      (Icons.sensor_door_outlined, '${offer.doors}', 'Doors'),
      (Icons.luggage_outlined, '${offer.luggage}', 'Bags'),
      (Icons.settings_outlined, offer.transmission.label, 'Gearbox'),
      (fuelTypeIcon(offer.fuelType), offer.fuelType.label, 'Fuel'),
      (Icons.ac_unit_rounded, offer.airConditioning ? 'Yes' : 'No', 'A/C'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            ((constraints.maxWidth - _spacing * (_columns - 1)) / _columns)
                .floorToDouble();

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final (icon, value, label) in specs)
              _SpecTile(width: tileWidth, icon: icon, value: value, label: label),
          ],
        );
      },
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.offer, required this.now});

  final RentalOffer offer;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: RentalPrice(
                  offer: offer,
                  now: now,
                  large: true,
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: offer.available
                    ? () => showRentalContactSheet(context, offer.company)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
                child: Text(offer.available ? 'Contact to book' : 'Not available'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
