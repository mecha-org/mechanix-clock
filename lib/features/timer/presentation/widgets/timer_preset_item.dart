import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

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

  String _getPresetSubtitle(BuildContext context, AppLocalizations l10n) {
    if (preset.name != null && preset.name!.isNotEmpty) {
      return preset.name!;
    }
    final hours = preset.duration.inHours;
    final minutes = preset.duration.inMinutes.remainder(60);
    final seconds = preset.duration.inSeconds.remainder(60);

    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? l10n.hours_abbr : l10n.hours_abbr}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'min' : l10n.minutes_abbr}');
    }
    if (seconds > 0) {
      parts.add('$seconds sec');
    }
    if (parts.isEmpty) {
      return '0 min';
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedTime = formatPresetDuration(preset.duration);
    final subtitle = _getPresetSubtitle(context, l10n);

    return InkWell(
      onTap: isEditing ? onEdit : onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (isEditing) ...[
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.remove_circle,
                  color: colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontFamily: MechanixFontFamily.geistMono,
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: MechanixFontFamily.geist,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!isEditing)
              MechanixIconButton.filled(
                type: ButtonType.rounded,
                size: IconButtonSize.medium,
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.onSurface,
                icon: const ImageIcon(AssetImage(ClockIcons.play)),
                onPressed: onPlay,
              ),
          ],
        ),
      ),
    );
  }
}
