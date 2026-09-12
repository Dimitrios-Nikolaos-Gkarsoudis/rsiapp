import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Car photo that fills its box, with a placeholder if the asset is missing.
class RentalImage extends StatelessWidget {
  const RentalImage({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.surfaceMuted,
        child: Center(
          child: Icon(
            Icons.directions_car_rounded,
            size: 48,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
