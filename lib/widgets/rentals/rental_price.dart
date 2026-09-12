import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/format/formatters.dart';
import '../../models/rental_model.dart';

/// Daily price, showing the original price struck through during a promotion.
class RentalPrice extends StatelessWidget {
  const RentalPrice({
    super.key,
    required this.offer,
    required this.now,
    this.large = false,
    this.alignment = CrossAxisAlignment.end,
  });

  final RentalOffer offer;
  final DateTime now;
  final bool large;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final price = offer.pricePerDayOn(now);
    final isDiscounted = price < offer.pricePerDay;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        if (isDiscounted)
          Text(
            formatPrice(offer.pricePerDay, offer.currency),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: large ? 14 : 12,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: formatPrice(price, offer.currency),
                style: TextStyle(
                  color: isDiscounted ? AppColors.promo : AppColors.textPrimary,
                  fontSize: large ? 24 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' / day',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: large ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RentalDiscountBadge extends StatelessWidget {
  const RentalDiscountBadge({
    super.key,
    required this.percent,
    this.large = false,
  });

  final int percent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 9,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.promo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '-$percent%',
        style: TextStyle(
          color: Colors.white,
          fontSize: large ? 15 : 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
