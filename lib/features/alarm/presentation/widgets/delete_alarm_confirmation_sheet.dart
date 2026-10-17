import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

Future<bool?> showDeleteAlarmConfirmationSheet(BuildContext context) {
  return MechanixBottomSheet.showModal<bool>(
    context: context,
    builder: (sheetContext) => const DeleteAlarmConfirmationSheet(),
  );
}

class DeleteAlarmConfirmationSheet extends StatelessWidget {
  const DeleteAlarmConfirmationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.delete_alarm_question,
                style: TextStyle(
                  fontFamily: MechanixFontFamily.geist,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: MechanixButton.outline(
                      key: const Key('delete_alarm_cancel_button'),
                      size: ButtonSize.large,
                      icon: ImageIcon(
                        const AssetImage(ClockIcons.cancel),
                        size: 32,
                        color: colorScheme.onSurface,
                      ),
                      label: l10n.cancel_uppercase,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MechanixButton(
                      key: const Key('delete_alarm_delete_button'),
                      size: ButtonSize.large,
                      icon: ImageIcon(
                        const AssetImage(ClockIcons.delete),
                        color: colorScheme.error,
                        size: 32,
                      ),
                      label: l10n.delete.toUpperCase(),

                      backgroundColor: colorScheme.surfaceContainerHigh,
                      foregroundColor: colorScheme.error,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
