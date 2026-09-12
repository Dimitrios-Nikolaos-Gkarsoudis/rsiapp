import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// First-launch introduction shown over the map: short pages about the app,
/// ending with the choice to share the device location.
class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({
    super.key,
    required this.onUseLocation,
    required this.onSkipLocation,
  });

  /// Called from the last page; should ask for location permission.
  final Future<void> Function() onUseLocation;
  final VoidCallback onSkipLocation;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  static const Duration _pageDuration = Duration(milliseconds: 280);
  static const double _pageHeight = 270;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.shield_rounded,
      title: 'Welcome to Road Safety Insights',
      body: 'A navigation app that knows where accidents have happened, '
          'so you can drive a little safer.',
    ),
    _OnboardingPage(
      icon: Icons.car_crash_outlined,
      title: 'See risky spots',
      body: 'Recorded accidents appear on the map. Tap one to see when it '
          'happened, how serious it was and what caused it.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_outlined,
      title: 'Get warned ahead',
      body: 'While you navigate, you are alerted before road segments with a '
          'history of accidents.',
    ),
    _OnboardingPage(
      icon: Icons.my_location_rounded,
      title: 'Use your location?',
      body: 'Your location lets the app show where you are, plan routes from '
          'your position and warn you about what is ahead. You can change '
          'this later with the location button.',
    ),
  ];

  final PageController _controller = PageController();

  int _page = 0;
  bool _isFinishing = false;

  bool get _isLastPage => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _useLocation() async {
    setState(() => _isFinishing = true);

    try {
      await widget.onUseLocation();
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black54),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: _pageHeight,
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: _pages.length,
                            onPageChanged: (page) {
                              setState(() => _page = page);
                            },
                            itemBuilder: (context, index) {
                              return _PageContent(page: _pages[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PageDots(count: _pages.length, current: _page),
                        const SizedBox(height: 20),
                        if (_isLastPage) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isFinishing ? null : _useLocation,
                              child: const Text('Use my location'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed:
                                  _isFinishing ? null : widget.onSkipLocation,
                              child: const Text('Not now'),
                            ),
                          ),
                        ] else
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _goTo(_pages.length - 1),
                                child: const Text('Skip'),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: () => _goTo(_page + 1),
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(page.icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: index == current ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == current ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
