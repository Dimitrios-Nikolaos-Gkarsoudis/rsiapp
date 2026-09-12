import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/format/formatters.dart';
import '../../models/road_risk_model.dart';
import '../../models/road_segment_model.dart';
import '../detail_row.dart';

/// Opens the risk details of a tapped road segment.
Future<void> showRoadRiskDetailsSheet(
  BuildContext context,
  RiskAssessment assessment,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => RoadRiskDetailsSheet(assessment: assessment),
  );
}

/// Readable labels for the known features of a road.
List<String> roadFeatureLabels(RoadCharacteristics characteristics) {
  final speedLimit = characteristics.speedLimitKmh;
  final lighting = characteristics.lighting;
  final pedestrianActivity = characteristics.pedestrianActivity;

  return [
    if (speedLimit != null) '$speedLimit km/h limit',
    if (characteristics.isJunction == true) 'Junction',
    if (lighting != null) lighting.label,
    if (pedestrianActivity != null) pedestrianActivity.label,
  ];
}

class RoadRiskDetailsSheet extends StatelessWidget {
  const RoadRiskDetailsSheet({super.key, required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final segment = assessment.segment;
    final area = segment.area;
    final source = segment.source;
    final features = roadFeatureLabels(segment.characteristics);
    final firstAccidentAt = assessment.firstAccidentAt;
    final lastAccidentAt = assessment.lastAccidentAt;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              segment.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (area != null)
              Text(
                area,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 14),
            _RiskBanner(level: assessment.level, score: assessment.score),
            const SizedBox(height: 8),
            DetailRow(
              icon: Icons.car_crash_outlined,
              label: 'Recorded accidents',
              value: '${assessment.accidentCount}',
            ),
            if (assessment.accidentCount > 0) ...[
              DetailRow(
                icon: Icons.warning_amber_rounded,
                label: 'Fatal or serious',
                value:
                    '${assessment.fatalAccidents + assessment.seriousAccidents}',
              ),
              DetailRow(
                icon: Icons.personal_injury_outlined,
                label: 'Injured',
                value: '${assessment.injuries}',
              ),
              DetailRow(
                icon: Icons.heart_broken_outlined,
                label: 'Deaths',
                value: '${assessment.fatalities}',
              ),
            ],
            if (firstAccidentAt != null && lastAccidentAt != null)
              DetailRow(
                icon: Icons.date_range_outlined,
                label: 'Period',
                value: firstAccidentAt == lastAccidentAt
                    ? formatShortDate(firstAccidentAt)
                    : '${formatShortDate(firstAccidentAt)} – '
                        '${formatShortDate(lastAccidentAt)}',
              ),
            if (features.isNotEmpty)
              DetailRow(
                icon: Icons.add_road_rounded,
                label: 'Road features',
                value: features.join(' · '),
              ),
            if (source != null)
              DetailRow(
                icon: Icons.source_outlined,
                label: 'Source',
                value: source,
              ),
            const SizedBox(height: 8),
            const Text(
              'Risk is estimated from recorded accidents near this road and '
              'its features. It is not a prediction of future accidents.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  const _RiskBanner({required this.level, required this.score});

  final RiskLevel level;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = Color(level.colorValue);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              level.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'Risk Score: $score/100',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
