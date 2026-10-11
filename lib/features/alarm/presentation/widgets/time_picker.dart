import 'package:flutter/material.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/time_picker_column.dart';
import 'package:widgets/widgets.dart';

class CustomTimePicker extends StatelessWidget {
  final int selectedHour;
  final int selectedMinute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final bool enabled;

  const CustomTimePicker({
    super.key,
    required this.selectedHour,
    required this.selectedMinute,
    required this.onHourChanged,
    required this.onMinuteChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PickerColumn(
            itemCount: 12,
            initialValue: selectedHour,
            isHour: true,
            width: 180,
            onChanged: onHourChanged,
            enabled: enabled,
            squeeze: 1.2,
            selectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 128,
                  fontWeight: FontWeight.w100,
                ),
            unselectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 36,
                  fontWeight: FontWeight.w100,
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: TextStyle(
                fontFamily: MechanixFontFamily.geistMono,
                fontSize: 128,
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
            initialValue: selectedMinute,
            isHour: false,
            width: 180,
            squeeze: 1.2,
            selectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 128,
                  fontWeight: FontWeight.w100,
                ),
            unselectedTextStyle: Theme.of(context).textTheme.displayLarge
                ?.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 36,
                  fontWeight: FontWeight.w100,
                ),
            onChanged: onMinuteChanged,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
