import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/segmented_circular_progress.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class TimerCountdownDisplay extends StatelessWidget {
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  String _formatEndTime(DateTime endTime, AppLocalizations l10n) {
    final hour = endTime.hour;
    final minute = endTime.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final period = isPm ? l10n.pm : l10n.am;
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalSecs = totalDuration.inSeconds;
    final showEndTime = isPaused ? DateTime.now().add(remaining) : endTime;
    final remainingSecs = remaining.inSeconds;
    final progress = totalSecs > 0 ? remainingSecs / totalSecs : 0.0;

    // Animate from the previous second's progress for a smooth transition, but only if not paused
    final beginProgress =
        (remainingSecs < totalSecs && totalSecs > 0 && !isPaused)
        ? (remainingSecs + 1) / totalSecs
        : progress;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: beginProgress, end: progress),
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              builder: (context, value, child) {
                return SegmentedCountdownRing(
                  value: value,
                  totalSegments: 60,
                  activeColor: AppColors.accent,
                  inactiveColor: const Color(0xFF262626),
                  glowColor: AppColors.accent,
                  strokeWidth: 2.0,
                  tickLength: 12.0,
                );
              },
            ),
          ),
          SizedBox(
            width: 220,
            height: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (timerName != null && timerName!.isNotEmpty) ...[
                  Text(
                    timerName!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _formatDuration(remaining),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (showEndTime != null) ...[
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: isPaused ? 0.7 : 1.0,
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
                          _formatEndTime(showEndTime, l10n),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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
        ],
      ),
    );
  }
}
