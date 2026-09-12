import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/rental_model.dart';
import 'rental_image.dart';
import 'rental_price.dart';
import 'rental_spec_chip.dart';

class RentalCard extends StatelessWidget {
  const RentalCard({
    super.key,
    required this.offer,
    required this.now,
    required this.onTap,
  });

  final RentalOffer offer;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final promotion = offer.activePromotionOn(now);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RentalImage(asset: offer.image),
                  if (promotion != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: RentalDiscountBadge(
                        percent: promotion.discountPercent,
                      ),
                    ),
                  if (!offer.available) const _UnavailableOverlay(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _TitleBlock(offer: offer)),
                      const SizedBox(width: 12),
                      RentalPrice(offer: offer, now: now),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: summarySpecChips(offer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.offer});

  final RentalOffer offer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          offer.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                '${offer.category.label} · ${offer.company.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            if (offer.company.isPartner) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified_rounded,
                size: 15,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _UnavailableOverlay extends StatelessWidget {
  const _UnavailableOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Not available',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
