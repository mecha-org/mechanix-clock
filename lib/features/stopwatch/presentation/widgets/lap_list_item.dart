import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/utils/helper.dart';
import 'package:mechanix_clock/features/stopwatch/data/models/lap_time_model.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class LapListItem extends StatelessWidget {
  final LapTime lap;
  final bool isLatest;

  const LapListItem({super.key, required this.lap, this.isLatest = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final paddedNumber = lap.lapNumber.toString().padLeft(2, '0');
    final lapNumberStr = l10n?.lap_padded(paddedNumber) ?? 'LAP $paddedNumber';
    final durationStr =
        '+ ${formatDuration(lap.duration, includeHundredths: true)}';
    final totalTimeStr = formatDuration(lap.totalTime, includeHundredths: true);

    final indicatorColor = isLatest ? colorScheme.primary : colorScheme.outline;
    final labelColor = isLatest
        ? colorScheme.primary
        : colorScheme.onSecondaryContainer;
    final timeColor = isLatest
        ? colorScheme.onSurface
        : colorScheme.onSecondaryContainer;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Vertical Line Indicator
          Container(
            width: 2,
            height: 18,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),
          // Lap Number (e.g. LAP 01)
          Text(
            lapNumberStr,
            style: theme.textTheme.titleMedium!.copyWith(color: labelColor),
          ),
          // Lap split duration (+ 00:00.00)
          Expanded(
            child: Text(
              durationStr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: MechanixFontFamily.geistMono,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          // Total elapsed time (00:00.00)
          Text(
            totalTimeStr,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: MechanixFontFamily.geistMono,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: timeColor,
            ),
          ),
        ],
      ),
    );
  }
}
