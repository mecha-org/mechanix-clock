import 'package:flutter/material.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class TimerSoundRow extends StatelessWidget {
  final String sound;
  final bool isIdle;
  final VoidCallback onTap;

  const TimerSoundRow({
    super.key,
    required this.sound,
    required this.isIdle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MechanixListTile(
      onTap: isIdle ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      label: Text(
        l10n.sound,
        style: TextStyle(
          fontFamily: MechanixFontFamily.geist,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isIdle ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        ),
      ),
      trailingWidgets: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sound,
              style: TextStyle(
                fontFamily: MechanixFontFamily.geist,
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isIdle) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
