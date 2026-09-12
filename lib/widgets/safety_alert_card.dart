import 'package:flutter/material.dart';

import '../models/hazard_model.dart';

class SafetyAlertCard
    extends StatelessWidget {
  final HazardFeature hazard;
  final double? distanceAheadMeters;

  const SafetyAlertCard({
    super.key,
    required this.hazard,
    required this.distanceAheadMeters,
  });

  bool get _isSevere {
    final severity =
        hazard.severity.toLowerCase();

    return severity.contains(
          'fatal',
        ) ||
        severity.contains(
          'serious',
        ) ||
        severity.contains(
          'severe',
        ) ||
        severity.contains(
          'θανατ',
        ) ||
        severity.contains(
          'σοβαρ',
        );
  }

  String get _distanceLabel {
    final meters =
        distanceAheadMeters;

    if (meters == null) {
      return 'Ahead on your route';
    }

    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km ahead';
    }

    return '${meters.round()} m ahead';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final accent = _isSevere
        ? const Color(0xFFD93025)
        : const Color(0xFFF29900);

    final background = _isSevere
        ? const Color(0xFFFCE8E6)
        : const Color(0xFFFFF4E5);

    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.32,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color:
                Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            alignment:
                Alignment.center,
            child: const Icon(
              Icons
                  .warning_amber_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isSevere
                            ? 'High-risk area'
                            : 'Safety alert',
                        style:
                            TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                    ),

                    Text(
                      _distanceLabel,
                      style:
                          TextStyle(
                        color: accent,
                        fontSize: 12.5,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  hazard.nearestArea
                          .trim()
                          .isNotEmpty
                      ? '${hazard.hazardType} · ${hazard.nearestArea}'
                      : hazard
                          .hazardType,
                  maxLines: 2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF3C4043,
                    ),
                    fontSize: 13,
                    height: 1.25,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),

                if (hazard
                        .totalAccidents >
                    1) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '${hazard.totalAccidents} recorded incidents in this zone',
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF5F6368,
                      ),
                      fontSize: 11.5,
                      fontWeight:
                          FontWeight
                              .w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}