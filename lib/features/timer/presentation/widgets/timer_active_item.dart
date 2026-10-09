import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:widgets/widgets.dart';

class TimerActiveItem extends StatelessWidget {
  final Duration duration;
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback? onTap;

  const TimerActiveItem({
    super.key,
    required this.duration,
    required this.isRunning,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dimColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    final activeColor = colorScheme.onSurface;

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hStr = '${twoDigits(hours)}:';
    final mStr = '${twoDigits(minutes)}:';
    final sStr = twoDigits(seconds);

    Color hColor, mColor, sColor;

    if (duration == Duration.zero) {
      hColor = dimColor;
      mColor = dimColor;
      sColor = dimColor;
    } else if (hours > 0) {
      hColor = activeColor;
      mColor = activeColor;
      sColor = activeColor;
    } else if (minutes > 0) {
      hColor = dimColor;
      mColor = activeColor;
      sColor = activeColor;
    } else {
      hColor = dimColor;
      mColor = dimColor;
      sColor = activeColor;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontFamily: MechanixFontFamily.geistMono,
                    fontSize: 80,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                  children: [
                    TextSpan(
                      text: hStr,
                      style: TextStyle(color: hColor),
                    ),
                    TextSpan(
                      text: mStr,
                      style: TextStyle(color: mColor),
                    ),
                    TextSpan(
                      text: sStr,
                      style: TextStyle(color: sColor),
                    ),
                  ],
                ),
              ),
            ),
            if (isRunning)
              MechanixIconButton.filled(
                key: const Key('timer_active_pause_button'),
                type: ButtonType.rounded,
                size: IconButtonSize.medium,
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.primary,
                icon: ImageIcon(
                  const AssetImage(ClockIcons.pause),
                  color: colorScheme.primary,
                ),
                onPressed: onPause,
              )
            else
              MechanixIconButton.filled(
                key: const Key('timer_active_resume_button'),
                type: ButtonType.rounded,
                size: IconButtonSize.medium,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                icon: ImageIcon(
                  const AssetImage(ClockIcons.play),
                  color: colorScheme.onPrimary,
                ),
                onPressed: onResume,
              ),
          ],
        ),
      ),
    );
  }
}
