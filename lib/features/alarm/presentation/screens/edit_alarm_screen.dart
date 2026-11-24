import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/core/utils/alarm_sounds.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_state.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/features/alarm/data/utils/date_time_utils.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/repeat_selection_screen.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/snooze_duration_screen.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/sound_selection_screen.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/alarm_label_sheet.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/am_pm_switch.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/day_bubble.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/delete_alarm_confirmation_sheet.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/time_picker.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

/// What the editor returns after Save: the alarm, and how saving it went
/// (null when it worked; see [AlarmSaveResult]).
class SavedAlarm {
  final Alarm alarm;
  final Future<ClockdException?> result;

  const SavedAlarm(this.alarm, this.result);
}

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
  late int _snoozeMinutes;
  late String _label;

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
    _sound = alarmSoundFor(alarm?.sound).id;
    _isSnoozeEnabled = alarm?.isSnoozeEnabled ?? true;
    _snoozeMinutes = alarm?.snoozeMinutes ?? Alarm.defaultSnoozeMinutes;
    _label = alarm?.label ?? '';

    // Like Ubuntu's Clocks: opening an alarm whose time another alarm (that
    // is on) already has says so straight away, not only on Save.
    if (alarm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _warnIfDuplicate();
      });
    }
  }

  void _saveAlarm() {
    if (_warnIfDuplicate()) return;

    final newAlarm = Alarm(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      hour: _selectedHour,
      minute: _selectedMinute,
      isAm: _isAm,
      repeatDays: _repeatDays,
      sound: _sound,
      isSnoozeEnabled: _isSnoozeEnabled,
      label: _label,
      snoozeMinutes: _snoozeMinutes,
    );

    final result = AlarmSaveResult();
    if (widget.alarm == null) {
      context.read<AlarmBloc>().add(AddAlarm(newAlarm, result: result));
    } else {
      context.read<AlarmBloc>().add(UpdateAlarm(newAlarm, result: result));
    }

    // The caller says when it rings next, or that saving failed (see
    // openAlarmEditor).
    Navigator.pop(context, SavedAlarm(newAlarm, result.future));
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
        _sound != alarmSoundFor(alarm.sound).id ||
        _isSnoozeEnabled != alarm.isSnoozeEnabled ||
        _snoozeMinutes != alarm.snoozeMinutes ||
        _label != alarm.label;
  }

  /// Shows "An alarm already exists for this time" if the chosen time is
  /// taken ([_isDuplicate]); returns whether it did.
  bool _warnIfDuplicate() {
    final state = context.read<AlarmBloc>().state;
    if (state is! AlarmLoaded || !_isDuplicate(state.alarms)) return false;
    MechanixSnackbar.text(
      position: MechanixSnackbarPosition.top,
      text: AppLocalizations.of(context)!.alarm_already_exists,
    ).show(context, duration: const Duration(seconds: 4));
    return true;
  }

  /// Whether another alarm that is on already has the time chosen here (see
  /// [alarmTimeTaken]).
  bool _isDuplicate(List<Alarm> alarms) => alarmTimeTaken(
    alarms,
    hour: _selectedHour,
    minute: _selectedMinute,
    isAm: _isAm,
    exceptId: widget.alarm?.id,
  );

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
      body: RepaintBoundary(
        child: ScrollConfiguration(
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

              // Label row
              _LabelSection(
                label: _label,
                onChanged: (label) => setState(() => _label = label),
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

              // Snooze duration row (only changeable with snooze on)
              _SnoozeDurationSection(
                minutes: _snoozeMinutes,
                enabled: _isSnoozeEnabled,
                onChanged: (minutes) {
                  setState(() {
                    _snoozeMinutes = minutes;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// "Label" row: shows the label (or "Enter label") with an edit button;
/// tapping anywhere opens [showAlarmLabelSheet].
class _LabelSection extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;

  const _LabelSection({required this.label, required this.onChanged});

  void _edit(BuildContext context) =>
      showAlarmLabelSheet(context, initialLabel: label, onSave: onChanged);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasLabel = label.isNotEmpty;

    return _TappableTile(
      onTap: () => _edit(context),
      child: MechanixListTile(
        key: const Key('option_label'),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        labelText: l10n.alarm_label,
        trailingWidgets: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              hasLabel ? label : l10n.enter_label,
              key: const Key('alarm_label_value'),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.titleLarge!.copyWith(
                color: hasLabel
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
              ),
            ),
          ),
          MechanixIconButton.standard(
            key: const Key('edit_label_button'),
            type: IconButtonType.rounded,
            icon: Image.asset(
              ClockIcons.edit,
              height: 20,
              width: 20,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => _edit(context),
          ),
        ],
        onTap: () => _edit(context),
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
      child: RepaintBoundary(
        child: CustomTimePicker(
          selectedHour: selectedHour,
          selectedMinute: selectedMinute,
          onHourChanged: onHourChanged,
          onMinuteChanged: onMinuteChanged,
        ),
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
    final repeatType = _repeatType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TappableTile(
          onTap: () => _openRepeatSelection(context),
          child: MechanixListTile(
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
              if (repeatType == RepeatType.custom)
                Builder(
                  builder: (context) {
                    final days = DateTimeUtils.getWeekdayAbbreviations(context);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: List.generate(7, (index) {
                        return DayBubble(
                          size: 20,
                          label: days[index],
                          isSelected: repeatDays.contains(index),
                        );
                      }),
                    );
                  },
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

    return _TappableTile(
      onTap: () => _openSoundSelection(context),
      child: MechanixListTile(
        key: const Key('option_sound'),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        labelText: l10n.sound,
        trailingWidgets: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              alarmSoundFor(sound).label,
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
      ),
    );
  }
}

class _SnoozeDurationSection extends StatelessWidget {
  final int minutes;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _SnoozeDurationSection({
    required this.minutes,
    required this.enabled,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => SnoozeDurationScreen(initialMinutes: minutes),
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return _TappableTile(
      onTap: enabled ? () => _open(context) : null,
      child: MechanixListTile(
        key: const Key('option_snooze_duration'),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        labelText: l10n.snooze_duration,
        trailingWidgets: [
          Text(
            l10n.minutes_value(minutes),
            style: theme.textTheme.titleLarge!.copyWith(
              color: enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            ),
          ),
          MechanixIconButton.standard(
            icon: Icon(Icons.chevron_right, size: 28, color: color),
            type: IconButtonType.rounded,
            onPressed: enabled ? () => _open(context) : null,
          ),
        ],
        onTap: enabled ? () => _open(context) : null,
      ),
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

/// Makes the whole tile tappable, trailing text included ([MechanixListTile]
/// only handles its label). Trailing buttons still take their own taps.
class _TappableTile extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _TappableTile({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}
