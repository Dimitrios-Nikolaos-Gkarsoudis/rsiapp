import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/rental_model.dart';

class RentalSpecChip extends StatelessWidget {
  const RentalSpecChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// The three specs shown on list cards: seats, gearbox and fuel.
List<RentalSpecChip> summarySpecChips(RentalOffer offer) {
  return [
    RentalSpecChip(
      icon: Icons.person_outline_rounded,
      label: '${offer.seats} seats',
    ),
    RentalSpecChip(
      icon: Icons.settings_outlined,
      label: offer.transmission.label,
    ),
    RentalSpecChip(
      icon: fuelTypeIcon(offer.fuelType),
      label: offer.fuelType.label,
    ),
  ];
}

IconData fuelTypeIcon(FuelType fuelType) {
  return switch (fuelType) {
    FuelType.petrol || FuelType.diesel => Icons.local_gas_station_outlined,
    FuelType.hybrid => Icons.eco_outlined,
    FuelType.electric => Icons.electric_bolt_outlined,
  };
}
