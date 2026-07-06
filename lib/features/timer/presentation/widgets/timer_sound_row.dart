import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class TimerSoundRow extends StatelessWidget {
  final String sound;
  final bool isIdle;
  final VoidCallback onTap;

  const TimerSoundRow({
    super.key,
    required this.sound,
    required this.isIdle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: isIdle ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.sound,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isIdle ? AppColors.textPrimary : AppColors.textGrey,
                  fontSize: 20,
                ),
              ),
              Row(
                children: [
                  Text(
                    sound,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isIdle
                          ? AppColors.textPrimary
                          : AppColors.textGrey,
                    ),
                  ),
                  if (isIdle) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
