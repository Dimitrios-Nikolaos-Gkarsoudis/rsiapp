import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/rental_model.dart';
import '../../screens/rentals/rental_detail_screen.dart';
import 'partner_offer_card.dart';
import 'rental_card.dart';

/// Partner offers strip followed by every car, as slivers for a scroll view.
class RentalsSlivers extends StatelessWidget {
  const RentalsSlivers({
    super.key,
    required this.catalog,
    required this.now,
  });

  final RentalCatalog catalog;
  final DateTime now;

  void _openDetail(BuildContext context, RentalOffer offer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RentalDetailScreen(offer: offer, now: now),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (catalog.rentals.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No rentals yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final offers = catalog.partnerOffersOn(now);

    // Bookable cars first, keeping catalog order within each group.
    final rentals = [
      ...catalog.rentals.where((rental) => rental.available),
      ...catalog.rentals.where((rental) => !rental.available),
    ];

    return SliverMainAxisGroup(
      slivers: [
        if (offers.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Partner offers',
              subtitle: 'Exclusive deals from RSI partners',
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: PartnerOfferCard.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: offers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final offer = offers[index];

                  return PartnerOfferCard(
                    offer: offer,
                    now: now,
                    onTap: () => _openDetail(context, offer),
                  );
                },
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'All cars',
            subtitle: rentals.length == 1 ? '1 car' : '${rentals.length} cars',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: rentals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final rental = rentals[index];

              return RentalCard(
                offer: rental,
                now: now,
                onTap: () => _openDetail(context, rental),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
