import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/rental_model.dart';

/// Shows how to reach [company] to book. Bookings are handled by the company.
Future<void> showRentalContactSheet(
  BuildContext context,
  RentalCompany company,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (_) => _RentalContactSheet(company: company),
  );
}

class _RentalContactSheet extends StatelessWidget {
  const _RentalContactSheet({required this.company});

  final RentalCompany company;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact ${company.name}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bookings are handled directly by the rental company.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (company.phone.isNotEmpty)
              _ContactRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: company.phone,
              ),
            if (company.email.isNotEmpty)
              _ContactRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: company.email,
              ),
            if (company.website.isNotEmpty)
              _ContactRow(
                icon: Icons.language_rounded,
                label: 'Website',
                value: company.website,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      subtitle: SelectableText(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
