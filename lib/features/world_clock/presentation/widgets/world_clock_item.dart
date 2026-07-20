import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/world_clock_model.dart';

class WorldClockItem extends StatelessWidget {
  final WorldClock clock;
  final int index;
  final int totalCount;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String relativeInfo;
  final bool isDay;

  const WorldClockItem({
    super.key,
    required this.clock,
    required this.index,
    required this.totalCount,
    required this.isEditing,
    required this.onTap,
    required this.onDelete,
    required this.relativeInfo,
    required this.isDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);

    tz.Location location;
    try {
      location = tz.getLocation(clock.timezoneId);
    } catch (_) {
      location = tz.UTC;
    }
    final targetNow = tz.TZDateTime.now(location);

    final timeStr = DateFormat(use24Hour ? 'HH:mm' : 'h:mm').format(targetNow);
    final amPmStr = use24Hour ? '' : (targetNow.hour < 12 ? l10n.am : l10n.pm);

    return Column(
      key: ValueKey(clock.id),
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (isEditing) ...[
                  IconButton(
                    key: Key('delete_clock_${clock.id}'),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clock.cityName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        relativeInfo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontSize: 32,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    if (amPmStr.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        amPmStr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isEditing) ...[
                  const SizedBox(width: 16),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_handle,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (index < totalCount - 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              height: 1,
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
