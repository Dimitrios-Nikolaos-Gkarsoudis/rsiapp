import 'package:flutter/material.dart';

class TurnByTurnPanel
    extends StatelessWidget {
  final String instruction;
  final double distanceMeters;
  final IconData maneuverIcon;

  const TurnByTurnPanel({
    super.key,
    required this.instruction,
    required this.distanceMeters,
    required this.maneuverIcon,
  });

  String _formatDistance(
    double meters,
  ) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(
        meters >= 10000 ? 0 : 1,
      )} km';
    }

    return '${meters.round()} m';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          14,
        ),
        decoration: BoxDecoration(
          color:
              const Color(0xFF1A73E8),
          borderRadius:
              BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color:
                  Color(0x26000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(
                  alpha: 0.16,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              alignment:
                  Alignment.center,
              child: Icon(
                maneuverIcon,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    _formatDistance(
                      distanceMeters,
                    ),
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 24,
                      height: 1,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing:
                          -0.5,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    instruction,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight:
                          FontWeight.w600,
                    ),
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