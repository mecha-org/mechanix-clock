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

    return MechanixListTile(
      onTap: isIdle ? onTap : null,
      labelText: l10n.sound,
      trailingWidgets: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            sound,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        MechanixIconButton.standard(
          icon: Icon(
            Icons.chevron_right,
            size: 28,
            color: Theme.of(context).colorScheme.onSurface,
          ),

          type: IconButtonType.rounded,
          onPressed: isIdle ? onTap : null,
        ),
      ],
    );
  }
}
