import 'dart:math' as math;

import 'package:flutter/material.dart';

class SegmentedCountdownRing extends StatelessWidget {
  final double value;
  final int totalSegments;
  final Color activeColor;
  final Color inactiveColor;
  final Color glowColor;
  final double strokeWidth;
  final double tickLength;

  const SegmentedCountdownRing({
    super.key,
    required this.value,
    this.totalSegments = 60,
    required this.activeColor,
    required this.inactiveColor,
    required this.glowColor,
    this.strokeWidth = 6.0,
    this.tickLength = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SegmentedCountdownRingPainter(
        value: value,
        totalSegments: totalSegments,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        glowColor: glowColor,
        strokeWidth: strokeWidth,
        tickLength: tickLength,
      ),
    );
  }
}

class _SegmentedCountdownRingPainter extends CustomPainter {
  final double value;
  final int totalSegments;
  final Color activeColor;
  final Color inactiveColor;
  final Color glowColor;
  final double strokeWidth;
  final double tickLength;

  _SegmentedCountdownRingPainter({
    required this.value,
    required this.totalSegments,
    required this.activeColor,
    required this.inactiveColor,
    required this.glowColor,
    required this.strokeWidth,
    required this.tickLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = 2 * math.pi / totalSegments;

    for (int i = 0; i < totalSegments; i++) {
      // Rotate by -math.pi / 2 to start at the top (12 o'clock).
      final angle = -math.pi / 2 + i * angleStep;

      // Radial ticks extend inwards from the outer edge.
      final outerRadius = size.width / 2 - strokeWidth / 2;
      final innerRadius = outerRadius - tickLength;

      if (innerRadius <= 0) continue;

      // Determine active fraction for smooth transition.
      final segmentStart = i / totalSegments;
      final segmentEnd = (i + 1) / totalSegments;

      double activeFraction = 0.0;
      if (value >= segmentEnd) {
        activeFraction = 1.0;
      } else if (value <= segmentStart) {
        activeFraction = 0.0;
      } else {
        activeFraction = (value - segmentStart) / (segmentEnd - segmentStart);
      }

      // Interpolate color.
      final color = Color.lerp(inactiveColor, activeColor, activeFraction)!;

      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);

      final startOffset = Offset(
        center.dx + innerRadius * cosAngle,
        center.dy + innerRadius * sinAngle,
      );
      final endOffset = Offset(
        center.dx + outerRadius * cosAngle,
        center.dy + outerRadius * sinAngle,
      );

      // Draw dual-layer glow if active.
      if (activeFraction > 0) {
        // Tight, higher-intensity glow layer
        final tightGlowPaint = Paint()
          ..color = glowColor.withValues(alpha: activeFraction * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 2.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawLine(startOffset, endOffset, tightGlowPaint);

        // Wide, atmospheric glow layer
        final wideGlowPaint = Paint()
          ..color = glowColor.withValues(alpha: activeFraction * 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawLine(startOffset, endOffset, wideGlowPaint);
      }

      // Draw segment line (capsule shape due to StrokeCap.round).
      final segmentPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startOffset, endOffset, segmentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedCountdownRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.totalSegments != totalSegments ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.tickLength != tickLength;
  }
}
