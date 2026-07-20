import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class TimerPresetItem extends StatelessWidget {
  final TimerPreset preset;
  final bool isEditing;
  final VoidCallback onSelect;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String Function(Duration) formatPresetDuration;

  const TimerPresetItem({
    super.key,
    required this.preset,
    required this.isEditing,
    required this.onSelect,
    required this.onPlay,
    required this.onDelete,
    required this.onEdit,
    required this.formatPresetDuration,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedTime = formatPresetDuration(preset.duration);
    final isHourBased = preset.duration.inHours > 0;
    final unitLabel = isHourBased ? l10n.hours_abbr : l10n.minutes_abbr;
    final numericPart = formattedTime.replaceAll(unitLabel, '').trim();

    return InkWell(
      onTap: isEditing ? onEdit : onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (isEditing) ...[
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
            ],
            // Column to support custom name or default time display
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preset.name != null && preset.name!.isNotEmpty) ...[
                    Text(
                      preset.name!,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formattedTime,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textGrey),
                          ),
                          TextSpan(
                            text: ' $unitLabel',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: 18,
                                  color: AppColors.textGrey,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: numericPart,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const WidgetSpan(child: SizedBox(width: 6)),
                          TextSpan(
                            text: unitLabel,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isEditing)
              IconButton(
                icon: const Icon(
                  Icons.play_arrow_outlined,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
                onPressed: onPlay,
              ),
          ],
        ),
      ),
    );
  }
}
