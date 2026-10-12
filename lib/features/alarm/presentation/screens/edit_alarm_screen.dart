import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/features/alarm/data/utils/date_time_utils.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/repeat_selection_screen.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/sound_selection_screen.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/am_pm_switch.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/day_bubble.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/delete_alarm_confirmation_sheet.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/time_picker.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class EditAlarmScreen extends StatefulWidget {
  final Alarm? alarm;

  const EditAlarmScreen({super.key, this.alarm});

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAm;
  late List<int> _repeatDays;
  late String _sound;
  late bool _isSnoozeEnabled;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;

    // default to current time + 1 minute
    final defaultTime = DateTime.now().add(const Duration(minutes: 1));

    _selectedHour =
        alarm?.hour ??
        (defaultTime.hour % 12 == 0 ? 12 : defaultTime.hour % 12);
    _selectedMinute = alarm?.minute ?? defaultTime.minute;
    _isAm = alarm?.isAm ?? (defaultTime.hour < 12);
    _repeatDays = List<int>.from(alarm?.repeatDays ?? []);
    _sound = alarm?.sound ?? 'Dancing Flames';
    _isSnoozeEnabled = alarm?.isSnoozeEnabled ?? true;
  }

  void _saveAlarm() {
    final newAlarm = Alarm(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      hour: _selectedHour,
      minute: _selectedMinute,
      isAm: _isAm,
      repeatDays: _repeatDays,
      sound: _sound,
      isSnoozeEnabled: _isSnoozeEnabled,
    );

    if (widget.alarm == null) {
      context.read<AlarmBloc>().add(AddAlarm(newAlarm));
    } else {
      context.read<AlarmBloc>().add(UpdateAlarm(newAlarm));
    }

    Navigator.pop(context);
  }

  void _deleteAlarm() async {
    if (widget.alarm != null) {
      final confirmed = await showDeleteAlarmConfirmationSheet(context);
      if (confirmed == true && mounted) {
        context.read<AlarmBloc>().add(DeleteAlarm(widget.alarm!.id));
        Navigator.pop(context);
      }
    }
  }

  bool get _hasChanges {
    final alarm = widget.alarm;
    if (alarm == null) return true;

    final sortedCurrent = List<int>.from(_repeatDays)..sort();
    final sortedOriginal = List<int>.from(alarm.repeatDays)..sort();
    final bool repeatDaysChanged =
        sortedCurrent.length != sortedOriginal.length ||
        !listEquals(sortedCurrent, sortedOriginal);

    return _selectedHour != alarm.hour ||
        _selectedMinute != alarm.minute ||
        _isAm != alarm.isAm ||
        repeatDaysChanged ||
        _sound != alarm.sound ||
        _isSnoozeEnabled != alarm.isSnoozeEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _hasChanges;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        backgroundColor: Colors.transparent,
        leading: MechanixIconButton.standard(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          MechanixIconButton.standard(
            key: const Key('save_alarm_button'),
            icon: const Icon(Icons.check),
            onPressed: hasChanges ? _saveAlarm : null,
          ),
          if (widget.alarm != null)
            MechanixIconButton.standard(
              key: const Key('delete_alarm_button'),
              icon: ImageIcon(
                const AssetImage(ClockIcons.delete),
                color: theme.colorScheme.error,
              ),
              onPressed: _deleteAlarm,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Large Time Display
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _TimePickerSection(
                  selectedHour: _selectedHour,
                  selectedMinute: _selectedMinute,
                  onHourChanged: (value) {
                    setState(() {
                      _selectedHour = value;
                    });
                  },
                  onMinuteChanged: (value) {
                    setState(() {
                      _selectedMinute = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Alarm time row with AM/PM Switch
              _AlarmTimeSection(
                isAm: _isAm,
                onAmPmChanged: (bool isAm) {
                  setState(() {
                    _isAm = isAm;
                  });
                },
              ),

              // Repeat section
              _RepeatSection(
                repeatDays: _repeatDays,
                onRepeatDaysChanged: (days) {
                  setState(() {
                    _repeatDays = days;
                  });
                },
              ),

              // Sound row
              _SoundSection(
                sound: _sound,
                onSoundChanged: (sound) {
                  setState(() {
                    _sound = sound;
                  });
                },
              ),

              // Snooze row
              _SnoozeSection(
                isSnoozeEnabled: _isSnoozeEnabled,
                onSnoozeChanged: (enabled) {
                  setState(() {
                    _isSnoozeEnabled = enabled;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerSection extends StatelessWidget {
  final int selectedHour;
  final int selectedMinute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  const _TimePickerSection({
    required this.selectedHour,
    required this.selectedMinute,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomTimePicker(
        selectedHour: selectedHour,
        selectedMinute: selectedMinute,
        onHourChanged: onHourChanged,
        onMinuteChanged: onMinuteChanged,
      ),
    );
  }
}

class _AlarmTimeSection extends StatelessWidget {
  final bool isAm;
  final ValueChanged<bool> onAmPmChanged;

  const _AlarmTimeSection({required this.isAm, required this.onAmPmChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MechanixListTile(
      labelText: l10n.alarm_time,
      trailingWidgets: [AmPmSwitch(isAm: isAm, onChanged: onAmPmChanged)],
    );
  }
}

class _RepeatSection extends StatelessWidget {
  final List<int> repeatDays;
  final ValueChanged<List<int>> onRepeatDaysChanged;

  const _RepeatSection({
    required this.repeatDays,
    required this.onRepeatDaysChanged,
  });

  RepeatType get _repeatType {
    if (repeatDays.isEmpty) return RepeatType.once;
    if (repeatDays.length == 7) return RepeatType.daily;
    return RepeatType.custom;
  }

  Future<void> _openRepeatSelection(BuildContext context) async {
    final result = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (context) => RepeatSelectionScreen(initialDays: repeatDays),
      ),
    );
    if (result != null) {
      onRepeatDaysChanged(List<int>.from(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final days = DateTimeUtils.getWeekdayAbbreviations(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MechanixListTile(
          key: const Key('option_repeat'),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          labelText: l10n.repeat,
          trailingWidgets: [
            if (repeatDays.isEmpty)
              Text(
                l10n.once.toUpperCase(),
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (repeatDays.length == 7)
              Text(
                l10n.daily.toUpperCase(),
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (_repeatType == RepeatType.custom)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: List.generate(7, (index) {
                  return DayBubble(
                    size: 20,
                    label: days[index],
                    isSelected: repeatDays.contains(index),
                  );
                }),
              ),
            MechanixIconButton.standard(
              key: const Key('option_repeat_button'),
              icon: Icon(
                Icons.chevron_right,
                size: 28,
                color: theme.colorScheme.onSurface,
              ),
              type: IconButtonType.rounded,
              onPressed: () => _openRepeatSelection(context),
            ),
          ],
          onTap: () => _openRepeatSelection(context),
        ),
      ],
    );
  }
}

class _SoundSection extends StatelessWidget {
  final String sound;
  final ValueChanged<String> onSoundChanged;

  const _SoundSection({required this.sound, required this.onSoundChanged});

  Future<void> _openSoundSelection(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SoundSelectionScreen(initialSound: sound),
      ),
    );
    if (result != null) {
      onSoundChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return MechanixListTile(
      key: const Key('option_sound'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      labelText: l10n.sound,
      trailingWidgets: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            sound,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: theme.textTheme.titleLarge!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        MechanixIconButton.standard(
          icon: Icon(
            Icons.chevron_right,
            size: 28,
            color: theme.colorScheme.onSurface,
          ),
          type: IconButtonType.rounded,
          onPressed: () => _openSoundSelection(context),
        ),
      ],
      onTap: () => _openSoundSelection(context),
    );
  }
}

class _SnoozeSection extends StatelessWidget {
  final bool isSnoozeEnabled;
  final ValueChanged<bool> onSnoozeChanged;

  const _SnoozeSection({
    required this.isSnoozeEnabled,
    required this.onSnoozeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MechanixListTile(
      key: const Key('snooze_switch'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      labelText: l10n.snooze,
      trailingWidgets: [
        MechanixSwitch(value: isSnoozeEnabled, onChanged: onSnoozeChanged),
      ],
    );
  }
}
