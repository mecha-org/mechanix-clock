import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:widgets/widgets.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/world_clock_model.dart';

class WorldClockItem extends StatelessWidget {
  static final DateFormat _timeFormat = DateFormat('h:mm');

  final WorldClock clock;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final String relativeInfo;

  const WorldClockItem({
    super.key,
    required this.clock,
    this.onTap,
    required this.onDelete,
    required this.relativeInfo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    tz.Location location;
    try {
      location = tz.getLocation(clock.timezoneId);
    } catch (_) {
      location = tz.UTC;
    }

    final targetNow = tz.TZDateTime.now(location);

    final timeStr = _timeFormat.format(targetNow);
    final amPmStr = targetNow.hour < 12 ? l10n.am : l10n.pm;

    return MechanixSwipableListTile(
      labelSupportingGap: 8.0,
      minHeight: 72.0,
      extentRatio: 0.14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onTap: onTap,
      actions: [
        MechanixIconButton.filled(
          key: Key('delete_clock_${clock.id}'),
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
      label: Text(
        clock.cityName,
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      supportingText: relativeInfo,
      trailingWidgets: [
        Text(
          [timeStr, amPmStr].where((value) => value.isNotEmpty).join(' '),
          style: theme.textTheme.displayMedium?.copyWith(
            fontFamily: MechanixFontFamily.geistMono,
            fontSize: 32,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
