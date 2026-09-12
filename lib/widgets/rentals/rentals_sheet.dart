import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_colors.dart';
import '../../models/rental_model.dart';
import '../../providers/rentals_provider.dart';
import 'rentals_slivers.dart';

/// Draggable sheet over the map with partner offers and every rental car.
///
/// Collapsed it shows a one-line summary; drag it up or tap the header to
/// expand. The system back button collapses it while expanded.
class RentalsSheet extends ConsumerStatefulWidget {
  const RentalsSheet({super.key, required this.topClearance});

  /// Height of the collapsed sheet above the bottom safe area.
  static const double peekHeight = 84;

  /// Space left uncovered at the top when fully expanded, e.g. for the
  /// search bar.
  final double topClearance;

  @override
  ConsumerState<RentalsSheet> createState() => _RentalsSheetState();
}

class _RentalsSheetState extends ConsumerState<RentalsSheet> {
  static const Duration _toggleDuration = Duration(milliseconds: 280);

  final DraggableScrollableController _controller =
      DraggableScrollableController();

  // Sheet sizes as fractions of the available height, updated on layout.
  double _collapsedSize = 0;
  double _expandedSize = 1;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleSizeChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSizeChanged);
    _controller.dispose();
    super.dispose();
  }

  bool get _sheetIsPastMidpoint {
    return _controller.isAttached &&
        _controller.size > (_collapsedSize + _expandedSize) / 2;
  }

  void _handleSizeChanged() {
    if (_sheetIsPastMidpoint == _isExpanded) {
      return;
    }

    // The sheet can resize while the tree is building (e.g. on rotation),
    // where setState is not allowed; defer to after the frame in that case.
    final phase = SchedulerBinding.instance.schedulerPhase;

    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isExpanded = _sheetIsPastMidpoint);
        }
      });
      return;
    }

    setState(() => _isExpanded = _sheetIsPastMidpoint);
  }

  void _toggle() {
    if (!_controller.isAttached) {
      return;
    }

    _controller.animateTo(
      _isExpanded ? _collapsedSize : _expandedSize,
      duration: _toggleDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final catalogState = ref.watch(rentalCatalogProvider);
    final now = ref.watch(clockProvider)();

    return PopScope(
      canPop: !_isExpanded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _toggle();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;

          _collapsedSize = math.min(
            (RentalsSheet.peekHeight + safeBottom) / height,
            1.0,
          );
          _expandedSize = math.max(
            (height - widget.topClearance) / height,
            _collapsedSize,
          );

          return DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: _collapsedSize,
            minChildSize: _collapsedSize,
            maxChildSize: _expandedSize,
            snap: true,
            builder: (context, scrollController) {
              return Material(
                color: AppColors.surfaceMuted,
                surfaceTintColor: Colors.transparent,
                elevation: 12,
                shadowColor: const Color(0x40000000),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _SheetHeader(
                        subtitle: _summary(catalogState, now),
                        isExpanded: _isExpanded,
                        onTap: _toggle,
                      ),
                    ),
                    ...catalogState.when<List<Widget>>(
                      loading: () => const [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ],
                      error: (_, _) => [
                        SliverToBoxAdapter(
                          child: _LoadError(
                            onRetry: () =>
                                ref.invalidate(rentalCatalogProvider),
                          ),
                        ),
                      ],
                      data: (catalog) => [
                        RentalsSlivers(catalog: catalog, now: now),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: safeBottom + 16),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _summary(AsyncValue<RentalCatalog> catalogState, DateTime now) {
  return catalogState.when(
    loading: () => 'Loading rentals…',
    error: (_, _) => "Couldn't load rentals",
    data: (catalog) {
      final cars = _countLabel(catalog.rentals.length, 'car');
      final deals = catalog.partnerOffersOn(now).length;

      return deals == 0 ? cars : '${_countLabel(deals, 'partner deal')} · $cars';
    },
  );
}

String _countLabel(int count, String noun) {
  return '$count ${count == 1 ? noun : '${noun}s'}';
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
  });

  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isExpanded ? 'Collapse car rentals' : 'Expand car rentals',
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: RentalsSheet.peekHeight,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.car_rental_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Car rentals',
                              maxLines: 1,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Rentals are unavailable right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
