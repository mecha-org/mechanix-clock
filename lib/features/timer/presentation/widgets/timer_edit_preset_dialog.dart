import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_event.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_custom_picker.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class TimerEditPresetDialog extends StatefulWidget {
  final TimerPreset preset;
  final TimerBloc timerBloc;

  const TimerEditPresetDialog({
    super.key,
    required this.preset,
    required this.timerBloc,
  });

  @override
  State<TimerEditPresetDialog> createState() => _TimerEditPresetDialogState();
}

class _TimerEditPresetDialogState extends State<TimerEditPresetDialog> {
  late final TextEditingController _controller;
  late int _editHours;
  late int _editMinutes;
  late int _editSeconds;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.preset.name ?? '');
    _editHours = widget.preset.duration.inHours;
    _editMinutes = widget.preset.duration.inMinutes.remainder(60);
    _editSeconds = widget.preset.duration.inSeconds.remainder(60);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.edit_preset,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: l10n.timer_preset_name,
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                hintText: l10n.timer_preset_name_hint,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGrey,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TimerCustomPicker(
              selectedHours: _editHours,
              selectedMinutes: _editMinutes,
              selectedSeconds: _editSeconds,
              onHoursChanged: (val) => setState(() => _editHours = val),
              onMinutesChanged: (val) => setState(() => _editMinutes = val),
              onSecondsChanged: (val) => setState(() => _editSeconds = val),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () {
                    final name = _controller.text.trim();
                    final updatedDuration = Duration(
                      hours: _editHours,
                      minutes: _editMinutes,
                      seconds: _editSeconds,
                    );
                    if (updatedDuration == Duration.zero) return;

                    widget.timerBloc.add(
                      UpdateTimerPreset(
                        id: widget.preset.id,
                        name: name,
                        duration: updatedDuration,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
