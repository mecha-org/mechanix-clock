import 'dart:ui';

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
                    ? _buildPlayPauseListScreen(
                        context,
                        l10n,
                        theme,
                        colorScheme,
                      )
                    : _buildSettingScreen(
                        context,
                        l10n,
                        theme,
                        colorScheme,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayPauseListScreen(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return BlocSelector<TimerBloc, TimerState, List<TimerPreset>>(
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

        return [...activePresets, ...inactivePresets];
      },
      builder: (context, allItems) {
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
                  BlocSelector<TimerBloc, TimerState, _PlayPauseItemData>(
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
                      final isActive =
                          itemData.isRunning || itemData.isPaused;

                      if (isActive) {
                        return TimerActiveItem(
                          duration: itemData.displayDuration,
                          isRunning: itemData.isRunning,
                          isPaused: itemData.isPaused,
                          onPause: () {
                            context.read<TimerBloc>().add(
                              PauseTimer(presetId: preset.id),
                            );
                          },
                          onResume: () {
                            context.read<TimerBloc>().add(
                              ResumeTimer(presetId: preset.id),
                            );
                          },
                        );
                      } else {
                        return TimerPresetItem(
                          preset: preset,
                          isEditing: false,
                          onSelect: () {
                            setState(() {
                              _selectedHours = preset.duration.inHours;
                              _selectedMinutes =
                                  preset.duration.inMinutes.remainder(60);
                              _selectedSeconds =
                                  preset.duration.inSeconds.remainder(60);
                              _isSettingMode = true;
                            });
                          },
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
                            context.read<TimerBloc>().add(
                              DeleteTimerPreset(preset.id),
                            );
                          },
                          onEdit: () {},
                          formatPresetDuration: _formatPresetDuration,
                        );
                      }
                    },
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

  Widget _buildSettingScreen(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return BlocSelector<TimerBloc, TimerState, bool>(
      selector: (state) => state.isEditingPresets,
      builder: (context, isEditingPresets) {
        final hasTime =
            _selectedHours > 0 || _selectedMinutes > 0 || _selectedSeconds > 0;
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
                    ),
                  ),

                const SizedBox(height: 24),

                // Action Buttons Row
                Padding(
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
                          color: theme.colorScheme.onSecondaryFixed,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedHours = 0;
                            _selectedMinutes = 0;
                            _selectedSeconds = 0;
                          });
                        },
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
                        onPressed: canStart
                            ? () {
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
                              }
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                MechanixDivider(
                  color: colorScheme.outline.withValues(alpha: 0.38),
                  space: 1,
                ),

                // Sound Selection Row
                BlocSelector<TimerBloc, TimerState, String>(
                  selector: (state) => state.sound,
                  builder: (context, sound) {
                    return TimerSoundRow(
                      sound: sound,
                      isIdle: true,
                      onTap: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SoundSelectionScreen(initialSound: sound),
                          ),
                        );
                        if (result != null && context.mounted) {
                          context.read<TimerBloc>().add(SetTimerSound(result));
                        }
                      },
                    );
                  },
                ),
                MechanixDivider(
                  color: colorScheme.outline.withValues(alpha: 0.38),
                  space: 1,
                ),

                // Presets List
                BlocSelector<TimerBloc, TimerState, List<TimerPreset>>(
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
                              onSelect: () {
                                final hours = preset.duration.inHours;
                                final minutes =
                                    preset.duration.inMinutes.remainder(60);
                                final seconds =
                                    preset.duration.inSeconds.remainder(60);
                                setState(() {
                                  _selectedHours = hours;
                                  _selectedMinutes = minutes;
                                  _selectedSeconds = seconds;
                                });
                              },
                              onPlay: () {
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
                              onDelete: () {
                                context.read<TimerBloc>().add(
                                  DeleteTimerPreset(preset.id),
                                );
                              },
                              onEdit: () {},
                              formatPresetDuration: _formatPresetDuration,
                            ),
                            if (index < presets.length - 1)
                              MechanixDivider(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.38),
                                space: 1,
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
        );
      },
    );
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
