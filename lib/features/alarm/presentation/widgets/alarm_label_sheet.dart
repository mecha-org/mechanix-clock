import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

/// Longest alarm label allowed.
const int maxAlarmLabelLength = 40;

/// Bottom sheet to edit the alarm label (styled like Settings' Bluetooth
/// device-name sheet). Check or Enter calls [onSave] with the trimmed text;
/// empty removes the label.
void showAlarmLabelSheet(
  BuildContext context, {
  required String initialLabel,
  required ValueChanged<String> onSave,
}) {
  MechanixBottomSheet.showModal(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) =>
        AlarmLabelSheet(initialLabel: initialLabel, onSave: onSave),
  );
}

class AlarmLabelSheet extends StatefulWidget {
  const AlarmLabelSheet({
    super.key,
    required this.initialLabel,
    required this.onSave,
  });

  final String initialLabel;
  final ValueChanged<String> onSave;

  @override
  State<AlarmLabelSheet> createState() => _AlarmLabelSheetState();
}

class _AlarmLabelSheetState extends State<AlarmLabelSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValid(String text) => text.trim().length <= maxAlarmLabelLength;

  void _saveAndPop() {
    if (!_isValid(_controller.text)) return;
    widget.onSave(_controller.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 24),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          final isValid = _isValid(value.text);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MechanixIconButton.standard(
                    key: const Key('label_sheet_back'),
                    icon: ImageIcon(
                      const AssetImage(ClockIcons.back),
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.edit_label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  MechanixIconButton.standard(
                    key: const Key('label_sheet_save'),
                    icon: ImageIcon(
                      const AssetImage(ClockIcons.check),
                      color: isValid
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed: isValid ? _saveAndPop : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Keyed wrapper so tests can find the field.
              KeyedSubtree(
                key: const Key('alarm_label_field'),
                child: MechanixTextField.outlined(
                  controller: _controller,
                  autofocus: true,
                  hintText: l10n.enter_label,
                  errorText: isValid
                      ? null
                      : l10n.alarm_label_limit(maxAlarmLabelLength),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveAndPop(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
