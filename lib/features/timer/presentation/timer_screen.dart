import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/sound_selection_screen.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_event.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_state.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_active_item.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_custom_picker.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_preset_item.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_sound_row.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  int _selectedHours = 0;
  int _selectedMinutes = 1;
  int _selectedSeconds = 0;
  bool _isSettingMode = false;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocSelector<TimerBloc, TimerState, bool>(
      selector: (state) {
        final isTimerActive =
            state.activeTimers.values.any(
              (t) =>
                  t.status == TimerStatus.running ||
                  t.status == TimerStatus.paused,
            ) ||
            state.status == TimerStatus.running ||
            state.status == TimerStatus.paused;
        return isTimerActive && !_isSettingMode;
      },
      builder: (context, showPlayScreen) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: MechanixAppBar.small(
            primary: false,
            backgroundColor: Colors.transparent,
            title: Text(
              l10n.timers.toUpperCase(),
              style: theme.textTheme.headlineMedium!.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                letterSpacing: 1.0,
              ),
            ),
            actions: showPlayScreen
                ? [
                    MechanixIconButton.tonal(
                      key: const Key('timer_goto_setting_button'),
                      type: ButtonType.rounded,
                      size: IconButtonSize.small,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      foregroundColor: colorScheme.primary,
                      icon: ImageIcon(
                        const AssetImage(ClockIcons.add),
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSettingMode = true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ]
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: MechanixDivider(
                color: theme.colorScheme.outline,
                space: 1,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: showPlayScreen
                    ? _TimerPlayPauseListScreen(
                        onSelectPreset: (preset) {
                          setState(() {
                            _selectedHours = preset.duration.inHours;
                            _selectedMinutes = preset.duration.inMinutes
                                .remainder(60);
                            _selectedSeconds = preset.duration.inSeconds
                                .remainder(60);
                            _isSettingMode = true;
                          });
                        },
                      )
                    : _TimerSettingScreen(
                        selectedHours: _selectedHours,
                        selectedMinutes: _selectedMinutes,
                        selectedSeconds: _selectedSeconds,
                        onHoursChanged: (v) {
                          if (_selectedHours != v && mounted) {
                            setState(() => _selectedHours = v);
                          }
                        },
                        onMinutesChanged: (v) {
                          if (_selectedMinutes != v && mounted) {
                            setState(() => _selectedMinutes = v);
                          }
                        },
                        onSecondsChanged: (v) {
                          if (_selectedSeconds != v && mounted) {
                            setState(() => _selectedSeconds = v);
                          }
                        },
                        onResetPicker: () {
                          setState(() {
                            _selectedHours = 0;
                            _selectedMinutes = 0;
                            _selectedSeconds = 0;
                          });
                        },
                        onStartTimer: () {
                          final duration = Duration(
                            hours: _selectedHours,
                            minutes: _selectedMinutes,
                            seconds: _selectedSeconds,
                          );
                          context.read<TimerBloc>().add(
                            StartTimer(duration, resetOldActiveTimers: true),
                          );
                          setState(() {
                            _isSettingMode = false;
                          });
                        },
                        onSelectPreset: (preset) {
                          final hours = preset.duration.inHours;
                          final minutes = preset.duration.inMinutes.remainder(
                            60,
                          );
                          final seconds = preset.duration.inSeconds.remainder(
                            60,
                          );
                          setState(() {
                            _selectedHours = hours;
                            _selectedMinutes = minutes;
                            _selectedSeconds = seconds;
                          });
                        },
                        onPlayPreset: (preset) {
                          context.read<TimerBloc>().add(
                            StartTimer(
                              preset.duration,
                              presetId: preset.id,
                              resetOldActiveTimers: true,
                            ),
                          );
                          setState(() {
                            _isSettingMode = false;
                          });
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderedTimerPresets {
  final List<TimerPreset> presets;

  const _OrderedTimerPresets(this.presets);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OrderedTimerPresets && listEquals(presets, other.presets);

  @override
  int get hashCode => Object.hashAll(presets);
}

class _TimerPlayPauseListScreen extends StatelessWidget {
  final ValueChanged<TimerPreset> onSelectPreset;

  const _TimerPlayPauseListScreen({required this.onSelectPreset});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocSelector<TimerBloc, TimerState, _OrderedTimerPresets>(
      selector: (state) {
        final activePresets = <TimerPreset>[];
        final inactivePresets = <TimerPreset>[];

        for (final preset in state.presets) {
          final timerData = state.activeTimers[preset.id];

          final isRunning =
              timerData?.status == TimerStatus.running ||
              (timerData == null &&
                  state.activePresetId == preset.id &&
                  state.status == TimerStatus.running);

          final isPaused =
              timerData?.status == TimerStatus.paused ||
              (timerData == null &&
                  state.activePresetId == preset.id &&
                  state.status == TimerStatus.paused);

          if (isRunning || isPaused) {
            activePresets.add(preset);
          } else {
            inactivePresets.add(preset);
          }
        }

        return _OrderedTimerPresets([...activePresets, ...inactivePresets]);
      },
      builder: (context, orderedPresets) {
        final allItems = orderedPresets.presets;

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: ListView.builder(
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final preset = allItems[index];

              return Column(
                key: ValueKey(preset.id),
                children: [
                  _PlayPausePresetItem(
                    preset: preset,
                    onSelect: () => onSelectPreset(preset),
                  ),
                  if (index < allItems.length - 1)
                    MechanixDivider(
                      color: colorScheme.outline.withValues(alpha: 0.38),
                      space: 1,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PlayPausePresetItem extends StatelessWidget {
  final TimerPreset preset;
  final VoidCallback onSelect;

  const _PlayPausePresetItem({required this.preset, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TimerBloc, TimerState, _PlayPauseItemData>(
      selector: (state) {
        final timerData = state.activeTimers[preset.id];
        final isRunning =
            timerData?.status == TimerStatus.running ||
            (timerData == null &&
                state.activePresetId == preset.id &&
                state.status == TimerStatus.running);
        final isPaused =
            timerData?.status == TimerStatus.paused ||
            (timerData == null &&
                state.activePresetId == preset.id &&
                state.status == TimerStatus.paused);
        final displayDuration =
            timerData?.remaining ??
            (state.activePresetId == preset.id &&
                    state.remaining > Duration.zero
                ? state.remaining
                : preset.duration);

        return _PlayPauseItemData(
          isRunning: isRunning,
          isPaused: isPaused,
          displayDuration: displayDuration,
        );
      },
      builder: (context, itemData) {
        final isActive = itemData.isRunning || itemData.isPaused;

        if (isActive) {
          return TimerActiveItem(
            duration: itemData.displayDuration,
            isRunning: itemData.isRunning,
            isPaused: itemData.isPaused,
            onPause: () {
              context.read<TimerBloc>().add(PauseTimer(presetId: preset.id));
            },
            onResume: () {
              context.read<TimerBloc>().add(ResumeTimer(presetId: preset.id));
            },
          );
        } else {
          return TimerPresetItem(
            preset: preset,
            isEditing: false,
            onSelect: onSelect,
            onPlay: () {
              context.read<TimerBloc>().add(
                StartTimer(
                  preset.duration,
                  presetId: preset.id,
                  resetOldActiveTimers: false,
                ),
              );
            },
            onDelete: () {
              context.read<TimerBloc>().add(DeleteTimerPreset(preset.id));
            },
            onEdit: () {},
            formatPresetDuration: _formatPresetDurationHelper,
          );
        }
      },
    );
  }
}

class _TimerSettingScreen extends StatelessWidget {
  final int selectedHours;
  final int selectedMinutes;
  final int selectedSeconds;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;
  final VoidCallback onResetPicker;
  final VoidCallback onStartTimer;
  final ValueChanged<TimerPreset> onSelectPreset;
  final ValueChanged<TimerPreset> onPlayPreset;

  const _TimerSettingScreen({
    required this.selectedHours,
    required this.selectedMinutes,
    required this.selectedSeconds,
    required this.onHoursChanged,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
    required this.onResetPicker,
    required this.onStartTimer,
    required this.onSelectPreset,
    required this.onPlayPreset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocSelector<TimerBloc, TimerState, bool>(
      selector: (state) => state.isEditingPresets,
      builder: (context, isEditingPresets) {
        final hasTime =
            selectedHours > 0 || selectedMinutes > 0 || selectedSeconds > 0;
        final canStart = !isEditingPresets && hasTime;

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                if (!isEditingPresets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TimerCustomPicker(
                      selectedHours: selectedHours,
                      selectedMinutes: selectedMinutes,
                      selectedSeconds: selectedSeconds,
                      onHoursChanged: onHoursChanged,
                      onMinutesChanged: onMinutesChanged,
                      onSecondsChanged: onSecondsChanged,
                    ),
                  ),

                const SizedBox(height: 24),

                // Action Buttons Row
                _TimerActionButtonsRow(
                  canReset: hasTime,
                  canStart: canStart,
                  onReset: onResetPicker,
                  onStart: onStartTimer,
                ),

                const SizedBox(height: 24),
                MechanixDivider(
                  color: colorScheme.outline.withValues(alpha: 0.38),
                  space: 1,
                ),

                // Sound Selection Row
                const _TimerSoundSection(),

                MechanixDivider(
                  color: colorScheme.outline.withValues(alpha: 0.38),
                  space: 1,
                ),

                // Presets List
                _TimerPresetsList(
                  isEditingPresets: isEditingPresets,
                  onSelectPreset: onSelectPreset,
                  onPlayPreset: onPlayPreset,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimerActionButtonsRow extends StatelessWidget {
  final bool canReset;
  final bool canStart;
  final VoidCallback onReset;
  final VoidCallback onStart;

  const _TimerActionButtonsRow({
    required this.canReset,
    required this.canStart,
    required this.onReset,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left Button: Reset time picker to 00:00:00
          MechanixIconButton.outline(
            key: const Key('timer_left_button'),
            type: ButtonType.rounded,
            size: IconButtonSize.large,
            backgroundColor: colorScheme.surfaceContainerHigh,
            foregroundColor: colorScheme.onSurface,
            icon: ImageIcon(
              const AssetImage(ClockIcons.cancel),
              color: canReset
                  ? theme.colorScheme.onSecondaryFixed
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            onPressed: canReset ? onReset : null,
          ),

          const SizedBox(width: 32),
          // Right Button: Start Timer
          MechanixIconButton.filled(
            key: const Key('timer_start_button'),
            type: ButtonType.rounded,
            size: IconButtonSize.large,
            backgroundColor: canStart
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            foregroundColor: canStart
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            icon: const ImageIcon(AssetImage(ClockIcons.play)),
            onPressed: canStart ? onStart : null,
          ),
        ],
      ),
    );
  }
}

class _TimerSoundSection extends StatelessWidget {
  const _TimerSoundSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TimerBloc, TimerState, String>(
      selector: (state) => state.sound,
      builder: (context, sound) {
        return TimerSoundRow(
          sound: sound,
          isIdle: true,
          onTap: () async {
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) => SoundSelectionScreen(initialSound: sound),
              ),
            );
            if (result != null && context.mounted) {
              context.read<TimerBloc>().add(SetTimerSound(result));
            }
          },
        );
      },
    );
  }
}

class _TimerPresetsList extends StatelessWidget {
  final bool isEditingPresets;
  final ValueChanged<TimerPreset> onSelectPreset;
  final ValueChanged<TimerPreset> onPlayPreset;

  const _TimerPresetsList({
    required this.isEditingPresets,
    required this.onSelectPreset,
    required this.onPlayPreset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocSelector<TimerBloc, TimerState, List<TimerPreset>>(
      selector: (state) => state.presets,
      builder: (context, presets) {
        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: presets.length,
          buildDefaultDragHandles: isEditingPresets,
          onReorderItem: (oldIndex, newIndex) {
            context.read<TimerBloc>().add(
              ReorderTimerPresets(oldIndex, newIndex),
            );
          },
          itemBuilder: (context, index) {
            final preset = presets[index];
            return Column(
              key: ValueKey(preset.id),
              children: [
                TimerPresetItem(
                  preset: preset,
                  isEditing: isEditingPresets,
                  onSelect: () => onSelectPreset(preset),
                  onPlay: () => onPlayPreset(preset),
                  onDelete: () {
                    context.read<TimerBloc>().add(DeleteTimerPreset(preset.id));
                  },
                  onEdit: () {},
                  formatPresetDuration: _formatPresetDurationHelper,
                ),
                if (index < presets.length - 1)
                  MechanixDivider(
                    color: colorScheme.outline.withValues(alpha: 0.38),
                    space: 1,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

String _formatPresetDurationHelper(Duration duration) {
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

class _PlayPauseItemData {
  final bool isRunning;
  final bool isPaused;
  final Duration displayDuration;

  const _PlayPauseItemData({
    required this.isRunning,
    required this.isPaused,
    required this.displayDuration,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PlayPauseItemData &&
          runtimeType == other.runtimeType &&
          isRunning == other.isRunning &&
          isPaused == other.isPaused &&
          displayDuration == other.displayDuration;

  @override
  int get hashCode => Object.hash(isRunning, isPaused, displayDuration);
}
