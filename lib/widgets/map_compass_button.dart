import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Google Maps-style compass. The needle turns with the map so it always
/// points north; tapping it is handled by [onTap] (e.g. reset to north).
class MapCompassButton extends StatelessWidget {
  const MapCompassButton({
    super.key,
    required this.bearing,
    required this.onTap,
    this.tooltip = 'Reset map to north',
  });

  static const Key needleKey = ValueKey('map-compass-needle');

  /// Current map bearing in degrees clockwise from north.
  final ValueListenable<double> bearing;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x33000000),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 45,
            height: 45,
            child: Center(
              child: ValueListenableBuilder<double>(
                valueListenable: bearing,
                builder: (context, degrees, needle) {
                  // Counter-rotate so the needle keeps pointing north.
                  return Transform.rotate(
                    key: needleKey,
                    angle: -degrees * math.pi / 180,
                    child: needle,
                  );
                },
                child: const CustomPaint(
                  size: Size(14, 28),
                  painter: _CompassNeedlePainter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A diamond needle: red half points north, grey half points south.
class _CompassNeedlePainter extends CustomPainter {
  const _CompassNeedlePainter();

  static const Color _southColor = Color(0xFFBDC1C6);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final north = Path()
      ..moveTo(centerX, 0)
      ..lineTo(size.width, centerY)
      ..lineTo(0, centerY)
      ..close();

    final south = Path()
      ..moveTo(centerX, size.height)
      ..lineTo(0, centerY)
      ..lineTo(size.width, centerY)
      ..close();

    canvas
      ..drawPath(north, Paint()..color = AppColors.error)
      ..drawPath(south, Paint()..color = _southColor);
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) => false;
}
