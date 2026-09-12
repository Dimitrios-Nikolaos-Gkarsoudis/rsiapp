import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/rental_model.dart';
import 'rental_image.dart';
import 'rental_price.dart';

/// Compact card for the horizontal "Partner offers" strip.
class PartnerOfferCard extends StatelessWidget {
  const PartnerOfferCard({
    super.key,
    required this.offer,
    required this.now,
    required this.onTap,
  });

  static const double width = 272;
  static const double height = 318;

  final RentalOffer offer;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final promotion = offer.activePromotionOn(now);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RentalImage(asset: offer.image),
                    if (promotion != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: RentalDiscountBadge(
                          percent: promotion.discountPercent,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (promotion != null)
                      Text(
                        promotion.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.promo,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      offer.company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RentalPrice(
                      offer: offer,
                      now: now,
                      alignment: CrossAxisAlignment.start,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
