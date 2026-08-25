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

  // Cached paint objects to avoid allocating paints and mask filters on every frame
  final Paint _inactivePaint;
  final Paint _activePaint;
  final Paint _tightGlowPaint;
  final Paint _wideGlowPaint;
  final Paint _transTightGlowPaint;
  final Paint _transWideGlowPaint;
  final Paint _transSegmentPaint;

  static const MaskFilter _tightBlur = MaskFilter.blur(BlurStyle.normal, 3.0);
  static const MaskFilter _wideBlur = MaskFilter.blur(BlurStyle.normal, 8.0);

  _SegmentedCountdownRingPainter({
    required this.value,
    required this.totalSegments,
    required this.activeColor,
    required this.inactiveColor,
    required this.glowColor,
    required this.strokeWidth,
    required this.tickLength,
  }) : _inactivePaint = Paint()
         ..color = inactiveColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth
         ..strokeCap = StrokeCap.round,
       _activePaint = Paint()
         ..color = activeColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth
         ..strokeCap = StrokeCap.round,
       _tightGlowPaint = Paint()
         ..color = glowColor.withValues(alpha: 0.4)
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth + 2.0
         ..strokeCap = StrokeCap.round
         ..maskFilter = _tightBlur,
       _wideGlowPaint = Paint()
         ..color = glowColor.withValues(alpha: 0.18)
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth + 6.0
         ..strokeCap = StrokeCap.round
         ..maskFilter = _wideBlur,
       _transTightGlowPaint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth + 2.0
         ..strokeCap = StrokeCap.round
         ..maskFilter = _tightBlur,
       _transWideGlowPaint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth + 6.0
         ..strokeCap = StrokeCap.round
         ..maskFilter = _wideBlur,
       _transSegmentPaint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth
         ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSegments <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - strokeWidth / 2;
    final innerRadius = outerRadius - tickLength;

    if (innerRadius <= 0) return;

    final angleStep = 2 * math.pi / totalSegments;
    final clampedValue = value.clamp(0.0, 1.0);

    // Batch paths for active and inactive segments to minimize GPU draw calls & blur passes
    final inactivePath = Path();
    final activePath = Path();

    // Hold transitioning segment data if one exists (at most 1)
    Offset? transStart;
    Offset? transEnd;
    double transFraction = 0.0;

    for (int i = 0; i < totalSegments; i++) {
      final angle = -math.pi / 2 + i * angleStep;
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

      final segmentStart = i / totalSegments;
      final segmentEnd = (i + 1) / totalSegments;

      if (clampedValue >= segmentEnd) {
        // Fully active segment
        activePath.moveTo(startOffset.dx, startOffset.dy);
        activePath.lineTo(endOffset.dx, endOffset.dy);
      } else if (clampedValue <= segmentStart) {
        // Inactive segment
        inactivePath.moveTo(startOffset.dx, startOffset.dy);
        inactivePath.lineTo(endOffset.dx, endOffset.dy);
      } else {
        // Transitioning segment
        transFraction =
            (clampedValue - segmentStart) / (segmentEnd - segmentStart);
        transStart = startOffset;
        transEnd = endOffset;
      }
    }

    // 1. Draw all inactive segments in a single draw call
    canvas.drawPath(inactivePath, _inactivePaint);

    // 2. Draw fully active segments with batched glow and stroke (only 3 draw calls total)
    // Draw wide glow pass
    canvas.drawPath(activePath, _wideGlowPaint);
    // Draw tight glow pass
    canvas.drawPath(activePath, _tightGlowPaint);
    // Draw active segment lines
    canvas.drawPath(activePath, _activePaint);

    // 3. Draw single transitioning segment if present
    if (transStart != null && transEnd != null && transFraction > 0) {
      // Transition wide glow
      _transWideGlowPaint.color = glowColor.withValues(
        alpha: transFraction * 0.18,
      );
      canvas.drawLine(transStart, transEnd, _transWideGlowPaint);

      // Transition tight glow
      _transTightGlowPaint.color = glowColor.withValues(
        alpha: transFraction * 0.4,
      );
      canvas.drawLine(transStart, transEnd, _transTightGlowPaint);

      // Transition segment line
      final color = Color.lerp(inactiveColor, activeColor, transFraction)!;
      _transSegmentPaint.color = color;
      canvas.drawLine(transStart, transEnd, _transSegmentPaint);
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
