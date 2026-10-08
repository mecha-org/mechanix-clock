import 'package:flutter/material.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/time_picker_column.dart';
import 'package:widgets/widgets.dart';

class TimerCustomPicker extends StatelessWidget {
  final int selectedHours;
  final int selectedMinutes;
  final int selectedSeconds;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;
  final bool enabled;

  const TimerCustomPicker({
    super.key,
    required this.selectedHours,
    required this.selectedMinutes,
    required this.selectedSeconds,
    required this.onHoursChanged,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PickerColumn(
            itemCount: 24,
            initialValue: selectedHours,
            isHour: false,
            width: 80,
            selectedFontSize: 58,
            unselectedFontSize: 30,
            onChanged: onHoursChanged,
            enabled: enabled,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ':',
              style: TextStyle(
                fontFamily: MechanixFontFamily.geistMono,
                fontSize: 58,
                fontWeight: FontWeight.w300,
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.3),
                height: 1.0,
              ),
            ),
          ),
          PickerColumn(
            itemCount: 60,
            initialValue: selectedMinutes,
            isHour: false,
            width: 80,
            selectedFontSize: 58,
            unselectedFontSize: 30,
            onChanged: onMinutesChanged,
            enabled: enabled,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ':',
              style: TextStyle(
                fontFamily: MechanixFontFamily.geistMono,
                fontSize: 58,
                fontWeight: FontWeight.w300,
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.3),
                height: 1.0,
              ),
            ),
          ),
          PickerColumn(
            itemCount: 60,
            initialValue: selectedSeconds,
            isHour: false,
            width: 80,
            selectedFontSize: 58,
            unselectedFontSize: 30,
            onChanged: onSecondsChanged,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
