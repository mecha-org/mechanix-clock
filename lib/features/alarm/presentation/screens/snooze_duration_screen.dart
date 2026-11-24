import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/widgets/keyboard_list.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

/// Lists the snooze lengths ([Alarm.snoozeOptions]); the check button
/// returns the picked number of minutes.
class SnoozeDurationScreen extends StatefulWidget {
  final int initialMinutes;

  const SnoozeDurationScreen({super.key, required this.initialMinutes});

  @override
  State<SnoozeDurationScreen> createState() => _SnoozeDurationScreenState();
}

class _SnoozeDurationScreenState extends State<SnoozeDurationScreen> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        primary: false,
        backgroundColor: Colors.transparent,
        leading: MechanixIconButton.standard(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          MechanixIconButton.standard(
            key: const Key('snooze_duration_done_button'),
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _selected),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ↑/↓ move between lengths, Enter picks one.
      body: KeyboardList(
        autofocus: true,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: Alarm.snoozeOptions.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MechanixDivider(),
          ),
          itemBuilder: (context, index) {
            final minutes = Alarm.snoozeOptions[index];

            return KeyboardListItem(
              index: index,
              onActivate: () => setState(() => _selected = minutes),
              child: MechanixListTile(
                key: Key('snooze_duration_$minutes'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leadingWidgets: [
                  MechanixRadio<int>(
                    value: minutes,
                    groupValue: _selected,
                    onChanged: (value) {
                      if (value != null) setState(() => _selected = value);
                    },
                  ),
                ],
                labelText: l10n.minutes_value(minutes),
                onTap: () => setState(() => _selected = minutes),
              ),
            );
          },
        ),
      ),
    );
  }
}
