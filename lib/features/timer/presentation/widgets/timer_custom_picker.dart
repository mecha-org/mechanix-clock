import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/time_picker_column.dart';

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
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: PickerColumn(
              itemCount: 24,
              initialValue: selectedHours,
              isHour: false,
              showBorder: false,
              width: 70,
              onChanged: onHoursChanged,
              enabled: enabled,
            ),
          ),
          Text(
            ':',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.textPrimary.withValues(
                alpha: enabled ? 0.3 : 0.1,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: PickerColumn(
              itemCount: 60,
              initialValue: selectedMinutes,
              isHour: false,
              showBorder: false,
              width: 70,
              onChanged: onMinutesChanged,
              enabled: enabled,
            ),
          ),
          Text(
            ':',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.textPrimary.withValues(
                alpha: enabled ? 0.3 : 0.1,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: PickerColumn(
              itemCount: 60,
              initialValue: selectedSeconds,
              isHour: false,
              showBorder: false,
              width: 70,
              onChanged: onSecondsChanged,
              enabled: enabled,
            ),
          ),
        ],
      ),
    );
  }
}
