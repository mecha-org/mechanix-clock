import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';

class TimerButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const TimerButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 180,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: enabled
                ? AppColors.buttonBorder
                : AppColors.buttonBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            height: 1.2,
            color: enabled
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
