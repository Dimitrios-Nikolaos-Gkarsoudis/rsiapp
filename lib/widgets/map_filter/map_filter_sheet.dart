import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_colors.dart';
import '../../models/accident_model.dart';
import '../../models/map_filter_model.dart';
import '../../models/road_risk_model.dart';
import '../../providers/map_filter_provider.dart';

/// Opens the map filters. Changes apply to the map immediately.
Future<void> showMapFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const MapFilterSheet(),
  );
}

class MapFilterSheet extends ConsumerWidget {
  const MapFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    final notifier = ref.read(mapFilterProvider.notifier);

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
                    'Map filters',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: filter.isDefault ? null : notifier.reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const _SectionTitle('Show on map'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Accidents'),
              value: filter.showAccidents,
              onChanged: notifier.setShowAccidents,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Road risk'),
              value: filter.showRoadRisk,
              onChanged: notifier.setShowRoadRisk,
            ),
            const _SectionTitle('Accident severity'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final severity in AccidentSeverity.values)
                  FilterChip(
                    showCheckmark: false,
                    avatar: _ColorDot(colorValue: severity.colorValue),
                    label: Text(severity.label),
                    selected: filter.severities.contains(severity),
                    onSelected: filter.showAccidents
                        ? (_) => notifier.toggleSeverity(severity)
                        : null,
                  ),
              ],
            ),
            const _SectionTitle('Time period'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final period in AccidentPeriod.values)
                  ChoiceChip(
                    label: Text(period.label),
                    selected: filter.period == period,
                    onSelected: filter.showAccidents
                        ? (_) => notifier.setPeriod(period)
                        : null,
                  ),
              ],
            ),
            const _SectionTitle('Road risk level'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in RiskLevel.values)
                  FilterChip(
                    showCheckmark: false,
                    avatar: _ColorDot(colorValue: level.colorValue),
                    label: Text(level.label),
                    selected: filter.riskLevels.contains(level),
                    onSelected: filter.showRoadRisk
                        ? (_) => notifier.toggleRiskLevel(level)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Road colours always use all recorded accidents.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.colorValue});

  final int colorValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
      ),
    );
  }
}
