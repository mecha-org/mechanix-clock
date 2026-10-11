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
      height: 186,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PickerColumn(
            itemCount: 24,
            initialValue: selectedHours,
            isHour: false,
            width: 100,
            onChanged: onHoursChanged,
            enabled: enabled,
            selectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 80,
                  fontWeight: FontWeight.w400,
                ),
            unselectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ':',
              style: TextStyle(
                fontFamily: MechanixFontFamily.geistMono,
                fontSize: 80,
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
            width: 100,
            onChanged: onMinutesChanged,
            enabled: enabled,
            selectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 80,
                  fontWeight: FontWeight.w400,
                ),
            unselectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ':',
              style: TextStyle(
                fontFamily: MechanixFontFamily.geistMono,
                fontSize: 80,
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
            width: 100,
            onChanged: onSecondsChanged,
            enabled: enabled,
            selectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 80,
                  fontWeight: FontWeight.w400,
                ),
            unselectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}
