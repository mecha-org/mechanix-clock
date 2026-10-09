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
      parts.add('$hours${hours == 1 ? l10n.hour_abbr : l10n.hours_abbr}');
    }
    if (minutes > 0) {
      parts.add('$minutes${minutes == 1 ? l10n.min_abbr : l10n.minutes_abbr}');
    }
    if (seconds > 0) {
      parts.add('$seconds${seconds == 1 ? l10n.sec_abbr : l10n.seconds_abbr}');
    }
    if (parts.isEmpty) {
      return l10n.zero_min;
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

    return MechanixSwipableListTile(
      labelSupportingGap: 8.0,
      minHeight: 72.0,
      extentRatio: 0.16,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: isEditing ? onEdit : onSelect,
      actions: [
        MechanixIconButton.filled(
          key: Key('timer_preset_delete_button_${preset.id}'),
          onPressed: onDelete,
          icon: ImageIcon(
            const AssetImage(ClockIcons.delete),
            color: colorScheme.onPrimary,
          ),
          size: IconButtonSize.large,
          type: ButtonType.rounded,
          backgroundColor: colorScheme.errorContainer,
        ),
      ],
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedTime,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontFamily: MechanixFontFamily.geistMono,
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSecondaryContainer,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontFamily: MechanixFontFamily.geist,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailingWidgets: [
        if (!isEditing)
          MechanixIconButton.filled(
            key: Key('timer_preset_play_button_${preset.id}'),
            type: ButtonType.rounded,
            size: IconButtonSize.medium,
            backgroundColor: colorScheme.surfaceContainerHigh,
            foregroundColor: colorScheme.onSurface,
            icon: const ImageIcon(AssetImage(ClockIcons.play)),
            onPressed: onPlay,
          ),
      ],
    );
  }
}
