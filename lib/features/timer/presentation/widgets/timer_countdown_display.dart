import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';
import 'package:mechanix_clock/core/utils/helper.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/segmented_circular_progress.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class TimerCountdownDisplay extends StatefulWidget {
  final Duration remaining;
  final Duration totalDuration;
  final bool isPaused;
  final String? timerName;
  final DateTime? endTime;

  const TimerCountdownDisplay({
    super.key,
    required this.remaining,
    required this.totalDuration,
    required this.isPaused,
    this.timerName,
    this.endTime,
  });

  @override
  State<TimerCountdownDisplay> createState() => _TimerCountdownDisplayState();
}

class _TimerCountdownDisplayState extends State<TimerCountdownDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _calculateProgress(Duration remaining, Duration total) {
    final totalMicros = total.inMicroseconds;
    if (totalMicros <= 0) return 0.0;
    final remainingMicros = remaining.inMicroseconds;
    if (remainingMicros <= 0) return 0.0;
    return (remainingMicros / totalMicros).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    final initialProgress = _calculateProgress(
      widget.remaining,
      widget.totalDuration,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(
      begin: initialProgress,
      end: initialProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(covariant TimerCountdownDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetProgress = _calculateProgress(
      widget.remaining,
      widget.totalDuration,
    );

    if (widget.isPaused) {
      _controller.stop();
      _animation = AlwaysStoppedAnimation<double>(targetProgress);
    } else {
      if (oldWidget.isPaused) {
        // Resumed from paused state: smoothly restart from target progress
        _controller.reset();
        _animation = Tween<double>(
          begin: targetProgress,
          end: targetProgress,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
      } else if (widget.totalDuration != oldWidget.totalDuration) {
        // Reset or changed duration
        _controller.stop();
        _animation = AlwaysStoppedAnimation<double>(targetProgress);
      } else {
        // Continuous smooth animation between ticks
        final startProgress = _animation.value;
        _animation = Tween<double>(
          begin: startProgress,
          end: targetProgress,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showEndTime = widget.isPaused
        ? DateTime.now().add(widget.remaining)
        : widget.endTime;

    return Center(
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Animated Segmented Ring (isolated with RepaintBoundary) ──
            RepaintBoundary(
              child: SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return SegmentedCountdownRing(
                      value: _animation.value,
                      totalSegments: 60,
                      activeColor: AppColors.accent,
                      inactiveColor: AppColors.cardBackground,
                      glowColor: AppColors.accent,
                      strokeWidth: 2.0,
                      tickLength: 12.0,
                    );
                  },
                ),
              ),
            ),

            // ── Static / 1-sec Timer Info Column (isolated with RepaintBoundary) ──
            RepaintBoundary(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.timerName != null &&
                        widget.timerName!.isNotEmpty) ...[
                      Text(
                        widget.timerName!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      formatDuration(widget.remaining),
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (showEndTime != null) ...[
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: widget.isPaused ? 0.7 : 1.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              size: 14,
                              color: AppColors.textOffWhite,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatEndTime(showEndTime, l10n),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textOffWhite,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
