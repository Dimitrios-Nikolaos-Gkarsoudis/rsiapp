import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/format/formatters.dart';
import '../../models/accident_model.dart';
import '../detail_row.dart';

/// Opens the details of a tapped accident point.
Future<void> showAccidentDetailsSheet(
  BuildContext context,
  AccidentRecord accident,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AccidentDetailsSheet(accident: accident),
  );
}

/// Details of one recorded accident. Only fields present in the data are
/// shown.
class AccidentDetailsSheet extends StatelessWidget {
  const AccidentDetailsSheet({super.key, required this.accident});

  final AccidentRecord accident;

  @override
  Widget build(BuildContext context) {
    final severity = accident.severity;
    final occurredAt = accident.occurredAt;
    final type = accident.type;
    final cause = accident.cause;
    final source = accident.source;
    final place = [accident.locationName, accident.area]
        .whereType<String>()
        .join(', ');

    final rows = [
      if (occurredAt != null)
        DetailRow(
          icon: Icons.event_outlined,
          label: 'Date',
          value: formatDateTime(occurredAt),
        ),
      if (place.isNotEmpty)
        DetailRow(icon: Icons.place_outlined, label: 'Location', value: place),
      if (accident.injuries != null)
        DetailRow(
          icon: Icons.personal_injury_outlined,
          label: 'Injured',
          value: '${accident.injuries}',
        ),
      if (accident.fatalities != null)
        DetailRow(
          icon: Icons.heart_broken_outlined,
          label: 'Deaths',
          value: '${accident.fatalities}',
        ),
      if (type != null)
        DetailRow(
          icon: Icons.car_crash_outlined,
          label: 'Accident type',
          value: type.label,
        ),
      if (cause != null)
        DetailRow(
          icon: Icons.info_outline_rounded,
          label: 'Likely cause',
          value: cause,
        ),
      if (source != null)
        DetailRow(icon: Icons.source_outlined, label: 'Source', value: source),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Traffic accident',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (severity != null) _SeverityBadge(severity: severity),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No further details are available for this accident.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...rows,
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final AccidentSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = Color(severity.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            severity.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
