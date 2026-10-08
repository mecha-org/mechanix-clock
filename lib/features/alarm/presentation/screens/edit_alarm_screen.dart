import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
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

  String _getRepeatSummary(AppLocalizations l10n) {
    if (_repeatDays.isEmpty) return l10n.once.toUpperCase();
    if (_repeatDays.length == 7) return l10n.daily.toUpperCase();
    return l10n.custom.toUpperCase();
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
    final l10n = AppLocalizations.of(context)!;

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
            icon: const Icon(Icons.check),
            onPressed: hasChanges ? _saveAlarm : null,
          ),
          if (widget.alarm != null)
            MechanixIconButton.standard(
              icon: ImageIcon(
                const AssetImage('assets/icons/delete.png'),
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

                child: _buildLargeTimePicker(),
              ),
              const SizedBox(height: 36),

              // Alarm time row with AM/PM Switch
              _buildAlarmTimeRow(l10n),
              const SizedBox(height: 28),

              // Repeat section
              _buildRepeatSection(l10n),
              const SizedBox(height: 28),

              // Sound row
              _buildSoundRow(l10n),
              const SizedBox(height: 28),

              // Snooze row
              _buildSnoozeRow(l10n),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeTimePicker() {
    return Center(
      child: CustomTimePicker(
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
    );
  }

  Widget _buildAlarmTimeRow(AppLocalizations l10n) {
    return MechanixListTile(
      labelText: l10n.alarm_time,
      trailingWidgets: [
        AmPmSwitch(
          isAm: _isAm,
          onChanged: (bool isAm) {
            setState(() {
              _isAm = isAm;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRepeatSection(AppLocalizations l10n) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MechanixListTile(
          labelText: l10n.repeat,
          trailingText: _getRepeatSummary(l10n),
          trailingWidgets: const [
            Icon(Icons.chevron_right, size: 20, color: Color(0xFFA1A1A5)),
          ],
          onTap: () async {
            final result = await Navigator.push<List<int>>(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RepeatSelectionScreen(initialDays: _repeatDays),
              ),
            );
            if (result != null) {
              setState(() => _repeatDays = List<int>.from(result));
            }
          },
          // ),
        ),
        const SizedBox(height: 16),
        // Days or Once / Daily text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildRepeatContent(context, days),
        ),
      ],
    );
  }

  Widget _buildSoundRow(AppLocalizations l10n) {
    return MechanixListTile(
      labelText: l10n.sound,
      trailingWidgets: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            _sound,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 16, color: Color(0xFFA1A1A5)),
          ),
        ),
        const Icon(Icons.chevron_right, size: 20, color: Color(0xFFA1A1A5)),
      ],
      onTap: () async {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => SoundSelectionScreen(initialSound: _sound),
          ),
        );
        if (result != null) {
          setState(() => _sound = result);
        }
      },
    );
  }

  Widget _buildSnoozeRow(AppLocalizations l10n) {
    return MechanixListTile(
      labelText: l10n.snooze,
      trailingWidgets: [
        MechanixSwitch(
          value: _isSnoozeEnabled,
          onChanged: (v) {
            setState(() => _isSnoozeEnabled = v);
          },
        ),
      ],
    );
  }

  RepeatType get _repeatType {
    if (_repeatDays.isEmpty) return RepeatType.once;
    if (_repeatDays.length == 7) return RepeatType.daily;
    return RepeatType.custom;
  }

  Widget? _buildRepeatContent(BuildContext context, List<String> days) {
    if (_repeatType == RepeatType.custom) {
      return Row(
        spacing: 8,
        children: List.generate(7, (index) {
          final isSelected = _repeatDays.contains(index);
          return DayBubble(
            label: days[index],
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _repeatDays.remove(index);
                } else {
                  _repeatDays.add(index);
                  _repeatDays.sort();
                }
              });
            },
          );
        }),
      );
    } else {
      return null;
    }
  }
}
