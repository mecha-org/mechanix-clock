import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/sound_selection_screen.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_event.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_state.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_button.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_countdown_display.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_custom_picker.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_preset_item.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_sound_row.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  int _selectedHours = 0;
  int _selectedMinutes = 1;
  int _selectedSeconds = 0;

  Key _pickerKey = const Key('timer_picker_0_1_0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TimerBloc>().add(const TimerTick());
    }
  }

  String _formatPresetDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      final mStr = minutes.toString().padLeft(2, '0');
      final sStr = seconds.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    } else {
      final mStr = minutes.toString().padLeft(2, '0');
      final sStr = seconds.toString().padLeft(2, '0');
      return '$mStr:$sStr';
    }
  }

  bool _isIdleState(TimerState state) {
    return state.status == TimerStatus.idle ||
        state.status == TimerStatus.initial;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<TimerBloc, TimerState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == TimerStatus.finished,
      listener: (context, state) {
        _showFinishedDialog(
          context,
          state.sound,
          state.duration,
          state.activePresetId,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.timers,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          actions: [
            BlocBuilder<TimerBloc, TimerState>(
              buildWhen: (previous, current) =>
                  _isIdleState(previous) != _isIdleState(current) ||
                  previous.isEditingPresets != current.isEditingPresets,
              builder: (context, state) {
                final isIdle = _isIdleState(state);
                if (!isIdle) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('timer_add_preset_button'),
                      icon: const Icon(Icons.add, color: AppColors.textPrimary),
                      onPressed: () {
                        final duration = Duration(
                          hours: _selectedHours,
                          minutes: _selectedMinutes,
                          seconds: _selectedSeconds,
                        );
                        if (duration == Duration.zero) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.timer_preset_invalid_duration),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else if (state.presets.any(
                          (p) => p.duration == duration,
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.timer_preset_exists),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          _showAddPresetDialog(context, duration);
                        }
                      },
                    ),
                    IconButton(
                      key: const Key('timer_edit_mode_button'),
                      icon: Icon(
                        state.isEditingPresets
                            ? Icons.check
                            : Icons.edit_outlined,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () {
                        context.read<TimerBloc>().add(ToggleEditPresetsMode());
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    BlocBuilder<TimerBloc, TimerState>(
                      buildWhen: (previous, current) =>
                          _isIdleState(previous) != _isIdleState(current) ||
                          previous.isEditingPresets != current.isEditingPresets,
                      builder: (context, state) {
                        final isIdle = _isIdleState(state);
                        if (isIdle) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: TimerCustomPicker(
                              key: _pickerKey,
                              selectedHours: _selectedHours,
                              selectedMinutes: _selectedMinutes,
                              selectedSeconds: _selectedSeconds,
                              onHoursChanged: (v) => _selectedHours = v,
                              onMinutesChanged: (v) => _selectedMinutes = v,
                              onSecondsChanged: (v) => _selectedSeconds = v,
                              enabled: !state.isEditingPresets,
                            ),
                          );
                        } else {
                          return BlocBuilder<TimerBloc, TimerState>(
                            buildWhen: (previous, current) =>
                                previous.remaining != current.remaining ||
                                previous.duration != current.duration ||
                                previous.status != current.status ||
                                previous.endTime != current.endTime ||
                                previous.activePresetId !=
                                    current.activePresetId ||
                                previous.presets != current.presets,
                            builder: (context, state) {
                              final activePreset = state.presets.firstWhere(
                                (p) => p.id == state.activePresetId,
                                orElse: () => const TimerPreset(
                                  id: '',
                                  duration: Duration.zero,
                                ),
                              );
                              final timerName = activePreset.id.isNotEmpty
                                  ? activePreset.name
                                  : null;

                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 40,
                                  bottom: 40,
                                ),
                                child: TimerCountdownDisplay(
                                  remaining: state.remaining,
                                  totalDuration: state.duration,
                                  isPaused: state.status == TimerStatus.paused,
                                  timerName: timerName,
                                  endTime: state.endTime,
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),

                    // ── Sound Selection row ────────────────────────────
                    BlocBuilder<TimerBloc, TimerState>(
                      buildWhen: (previous, current) =>
                          previous.sound != current.sound ||
                          _isIdleState(previous) != _isIdleState(current),
                      builder: (context, state) {
                        final isIdle = _isIdleState(state);
                        return TimerSoundRow(
                          sound: state.sound,
                          isIdle: isIdle,
                          onTap: () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SoundSelectionScreen(
                                  initialSound: state.sound,
                                ),
                              ),
                            );
                            if (result != null && context.mounted) {
                              context.read<TimerBloc>().add(
                                SetTimerSound(result),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const Divider(
                      color: AppColors.border,
                      height: 1,
                      thickness: 0.5,
                    ),

                    // ── Presets / Recent list ─────────────────────────
                    BlocBuilder<TimerBloc, TimerState>(
                      buildWhen: (previous, current) =>
                          _isIdleState(previous) != _isIdleState(current) ||
                          previous.presets != current.presets ||
                          previous.isEditingPresets !=
                              current.isEditingPresets ||
                          previous.activePresetId != current.activePresetId,
                      builder: (context, state) {
                        final isIdle = _isIdleState(state);
                        if (!isIdle) return const SizedBox.shrink();

                        return ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.presets.length,
                          buildDefaultDragHandles: state.isEditingPresets,
                          onReorderItem: (oldIndex, newIndex) {
                            context.read<TimerBloc>().add(
                              ReorderTimerPresets(oldIndex, newIndex),
                            );
                          },
                          itemBuilder: (context, index) {
                            final preset = state.presets[index];
                            return Column(
                              key: ValueKey(preset.id),
                              children: [
                                TimerPresetItem(
                                  preset: preset,
                                  isEditing: state.isEditingPresets,
                                  onSelect: () {
                                    final hours = preset.duration.inHours;
                                    final minutes = preset.duration.inMinutes
                                        .remainder(60);
                                    final seconds = preset.duration.inSeconds
                                        .remainder(60);
                                    setState(() {
                                      _selectedHours = hours;
                                      _selectedMinutes = minutes;
                                      _selectedSeconds = seconds;
                                      _pickerKey = Key(
                                        'timer_picker_${hours}_${minutes}_${seconds}_${DateTime.now().millisecondsSinceEpoch}',
                                      );
                                    });
                                  },
                                  onPlay: () {
                                    context.read<TimerBloc>().add(
                                      StartTimer(
                                        preset.duration,
                                        presetId: preset.id,
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    context.read<TimerBloc>().add(
                                      DeleteTimerPreset(preset.id),
                                    );
                                  },
                                  onEdit: () {
                                    _showRenamePresetDialog(context, preset);
                                  },
                                  formatPresetDuration: _formatPresetDuration,
                                ),
                                if (index < state.presets.length - 1)
                                  const Divider(
                                    color: AppColors.border,
                                    height: 1,
                                    thickness: 0.5,
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Buttons ─────────────────────────────────────────
            const Divider(color: AppColors.border, height: 1, thickness: 0.5),
            Container(
              height: 72,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BlocBuilder<TimerBloc, TimerState>(
                buildWhen: (previous, current) =>
                    _isIdleState(previous) != _isIdleState(current) ||
                    previous.status != current.status ||
                    previous.activePresetId != current.activePresetId ||
                    previous.isEditingPresets != current.isEditingPresets,
                builder: (context, state) {
                  final isIdle = _isIdleState(state);
                  return isIdle
                      ? Center(
                          child: TimerButton(
                            label: l10n.start,
                            enabled:
                                !state.isEditingPresets &&
                                (_selectedHours > 0 ||
                                    _selectedMinutes > 0 ||
                                    _selectedSeconds > 0),
                            onTap: () {
                              final duration = Duration(
                                hours: _selectedHours,
                                minutes: _selectedMinutes,
                                seconds: _selectedSeconds,
                              );
                              context.read<TimerBloc>().add(
                                StartTimer(duration),
                              );
                            },
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TimerButton(
                              label: l10n.cancel,
                              enabled: true,
                              onTap: () {
                                context.read<TimerBloc>().add(CancelTimer());
                              },
                            ),
                            TimerButton(
                              label: state.status == TimerStatus.running
                                  ? l10n.pause
                                  : l10n.resume,
                              enabled: true,
                              onTap: () {
                                if (state.status == TimerStatus.running) {
                                  context.read<TimerBloc>().add(PauseTimer());
                                } else {
                                  context.read<TimerBloc>().add(ResumeTimer());
                                }
                              },
                            ),
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishedDialog(
    BuildContext context,
    String soundName,
    Duration duration,
    String presetId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final timerBloc = context.read<TimerBloc>();
    final formatted = _formatPresetDuration(duration);
    final isHourBased = duration.inHours > 0;
    final unitLabel = isHourBased ? l10n.hours_abbr : l10n.minutes_abbr;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                  Row(
                    children: [
                      const Icon(
                        Icons.alarm_on,
                        size: 28,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.timer_finished,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$formatted$unitLabel',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            timerBloc.add(ResetTimerToIdle());
                          },
                          child: Text(l10n.dismiss),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardBackground,
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            timerBloc.add(ResetTimerToIdle());
                            timerBloc.add(
                              StartTimer(duration, presetId: presetId),
                            );
                          },
                          child: Text(l10n.restart),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddPresetDialog(BuildContext context, Duration duration) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final formatted = _formatPresetDuration(duration);
    final isHourBased = duration.inHours > 0;
    final unitLabel = isHourBased ? l10n.hours_abbr : l10n.minutes_abbr;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
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
                '${l10n.add_preset} ($formatted$unitLabel)',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.timer_preset_name,
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: l10n.timer_preset_name_hint,
                  hintStyle: const TextStyle(color: AppColors.textGrey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(color: AppColors.textSecondary),
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
                      final name = controller.text.trim();
                      context.read<TimerBloc>().add(
                        AddTimerPreset(
                          duration,
                          name: name.isNotEmpty ? name : null,
                        ),
                      );
                      Navigator.pop(dialogCtx);
                    },
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenamePresetDialog(BuildContext context, TimerPreset preset) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: preset.name ?? '');
    final formatted = _formatPresetDuration(preset.duration);
    final isHourBased = preset.duration.inHours > 0;
    final unitLabel = isHourBased ? l10n.hours_abbr : l10n.minutes_abbr;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
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
                '${l10n.edit_preset} ($formatted$unitLabel)',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.timer_preset_name,
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: l10n.timer_preset_name_hint,
                  hintStyle: const TextStyle(color: AppColors.textGrey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(color: AppColors.textSecondary),
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
                      final name = controller.text.trim();
                      context.read<TimerBloc>().add(
                        UpdateTimerPreset(id: preset.id, name: name),
                      );
                      Navigator.pop(dialogCtx);
                    },
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
