import 'package:flutter/material.dart';

import '../services/osrm_service.dart';

class RouteSummarySheet
    extends StatelessWidget {
  final FullRouteDetails routeDetails;
  final int simulationMultiplier;
  final String formattedDuration;

  final ValueChanged<int?>
      onSimulationSpeedChanged;

  final VoidCallback
      onStartNavigation;

  const RouteSummarySheet({
    super.key,
    required this.routeDetails,
    required this.simulationMultiplier,
    required this.formattedDuration,
    required this.onSimulationSpeedChanged,
    required this.onStartNavigation,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final hazards =
        routeDetails.dbHazards.length;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Color(0x24000000),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFDADCE0,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      99,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedDuration,
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF188038,
                      ),
                      fontSize: 26,
                      height: 1,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing:
                          -0.7,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      bottom: 2,
                    ),
                    child: Text(
                      '${routeDetails.distanceKm.toStringAsFixed(1)} km',
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF5F6368,
                        ),
                        fontSize: 14,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                hazards == 0
                    ? 'No recorded risk zones detected on this route'
                    : hazards == 1
                        ? '1 recorded risk zone on this route'
                        : '$hazards recorded risk zones on this route',
                style: TextStyle(
                  color: hazards == 0
                      ? const Color(
                          0xFF5F6368,
                        )
                      : const Color(
                          0xFFB06000,
                        ),
                  fontSize: 13.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              if (routeDetails
                  .routeWarningBadges
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 12,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: routeDetails
                      .routeWarningBadges
                      .map(
                        (badge) =>
                            Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                10,
                            vertical: 6,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFFFF4E5,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              999,
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              const Icon(
                                Icons
                                    .shield_outlined,
                                size: 15,
                                color:
                                    Color(
                                  0xFFB06000,
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                badge,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF7A4600,
                                  ),
                                  fontSize:
                                      11.5,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(
                height: 18,
              ),

              Row(
                children: [
                  Container(
                    height: 48,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF1F3F4,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        24,
                      ),
                    ),
                    child:
                        DropdownButtonHideUnderline(
                      child:
                          DropdownButton<
                              int>(
                        value:
                            simulationMultiplier,
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                        icon:
                            const Icon(
                          Icons
                              .expand_more_rounded,
                          color:
                              Color(
                            0xFF5F6368,
                          ),
                        ),
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF3C4043,
                          ),
                          fontSize: 13,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                        items:
                            const [
                          DropdownMenuItem(
                            value: 1,
                            child:
                                Text(
                              'SIM 1×',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child:
                                Text(
                              'SIM 5×',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 20,
                            child:
                                Text(
                              'SIM 20×',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 50,
                            child:
                                Text(
                              'SIM 50×',
                            ),
                          ),
                        ],
                        onChanged:
                            onSimulationSpeedChanged,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child:
                          FilledButton.icon(
                        style:
                            FilledButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF1A73E8,
                          ),
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              25,
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed:
                            onStartNavigation,
                        icon:
                            const Icon(
                          Icons
                              .navigation_rounded,
                          size: 20,
                        ),
                        label:
                            const Text(
                          'Start',
                          style:
                              TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}