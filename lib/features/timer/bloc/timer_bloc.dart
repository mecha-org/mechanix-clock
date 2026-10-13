import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';

import '../data/models/active_timer_data.dart';
import '../data/models/timer_preset.dart';
import '../data/repository/timer_repository.dart';
import 'timer_event.dart';
import 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final TimerRepository repository;
  final SystemAlarmService systemAlarmService;
  Timer? _ticker;

  TimerBloc({required this.repository, SystemAlarmService? systemAlarmService})
    : systemAlarmService = systemAlarmService ?? SystemAlarmService(),
      super(const TimerState()) {
    on<LoadTimerPresets>(_onLoadPresets, transformer: sequential());
    on<AddTimerPreset>(_onAddPreset, transformer: sequential());
    on<UpdateTimerPreset>(_onUpdatePreset, transformer: sequential());
    on<DeleteTimerPreset>(_onDeletePreset, transformer: sequential());
    on<ToggleEditPresetsMode>(_onToggleEditMode, transformer: sequential());
    on<ReorderTimerPresets>(_onReorderPresets, transformer: sequential());
    on<StartTimer>(_onStart, transformer: sequential());
    on<PauseTimer>(_onPause, transformer: sequential());
    on<ResumeTimer>(_onResume, transformer: sequential());
    on<CancelTimer>(_onCancel, transformer: sequential());
    on<TimerTick>(_onTick, transformer: sequential());
    on<SetTimerSound>(_onSetSound, transformer: sequential());
    on<ResetTimerToIdle>(_onResetToIdle, transformer: sequential());
  }

  Future<void> _onLoadPresets(
    LoadTimerPresets event,
    Emitter<TimerState> emit,
  ) async {
    try {
      final presets = await repository.getPresets();
      final sound = await repository.getSelectedSound();
      emit(
        state.copyWith(
          presets: presets,
          sound: sound,
          status: TimerStatus.idle,
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to load presets: $e');
      emit(state.copyWith(status: TimerStatus.idle, presets: const []));
    }
  }

  Future<void> _onAddPreset(
    AddTimerPreset event,
    Emitter<TimerState> emit,
  ) async {
    if (state.presets.any((p) => p.duration == event.duration)) {
      return;
    }
    final newPreset = TimerPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      duration: event.duration,
      name: event.name,
    );
    final updatedPresets = List<TimerPreset>.from(state.presets)
      ..add(newPreset);

    try {
      await repository.savePresets(updatedPresets);
      if (state.duration == event.duration && state.activePresetId.isEmpty) {
        emit(
          state.copyWith(presets: updatedPresets, activePresetId: newPreset.id),
        );
      } else {
        emit(state.copyWith(presets: updatedPresets));
      }
    } catch (e) {
      AppLogger.e('Failed to add timer preset: $e');
      emit(state.copyWith(presets: state.presets));
    }
  }

  Future<void> _onUpdatePreset(
    UpdateTimerPreset event,
    Emitter<TimerState> emit,
  ) async {
    final updatedPresets = state.presets.map((p) {
      if (p.id == event.id) {
        return p.copyWith(
          name: event.name,
          duration: event.duration ?? p.duration,
        );
      }
      return p;
    }).toList();

    try {
      await repository.savePresets(updatedPresets);
      emit(state.copyWith(presets: updatedPresets));
    } catch (e) {
      AppLogger.e('Failed to update timer preset: $e');
      emit(state.copyWith(presets: state.presets));
    }
  }

  Future<void> _onDeletePreset(
    DeleteTimerPreset event,
    Emitter<TimerState> emit,
  ) async {
    final updatedPresets = state.presets
        .where((p) => p.id != event.id)
        .toList();

    final updatedActiveTimers = Map<String, ActiveTimerData>.from(
      state.activeTimers,
    )..remove(event.id);

    try {
      await repository.savePresets(updatedPresets);
      if (state.activePresetId == event.id ||
          !updatedActiveTimers.values.any(
            (t) => t.status == TimerStatus.running,
          )) {
        if (!updatedActiveTimers.values.any(
          (t) => t.status == TimerStatus.running,
        )) {
          _ticker?.cancel();
        }
        try {
          await systemAlarmService.cancelTimer(event.id);
        } catch (err) {
          AppLogger.e('Failed to cancel timer on delete: $err');
        }
      }

      final hasRunning = updatedActiveTimers.values.any(
        (t) => t.status == TimerStatus.running,
      );
      final hasPaused = updatedActiveTimers.values.any(
        (t) => t.status == TimerStatus.paused,
      );
      final newStatus = hasRunning
          ? TimerStatus.running
          : (hasPaused ? TimerStatus.paused : TimerStatus.idle);

      emit(
        state.copyWith(
          presets: updatedPresets,
          activeTimers: updatedActiveTimers,
          status: newStatus,
          duration: state.activePresetId == event.id
              ? Duration.zero
              : state.duration,
          remaining: state.activePresetId == event.id
              ? Duration.zero
              : state.remaining,
          activePresetId: state.activePresetId == event.id
              ? ''
              : state.activePresetId,
          clearEndTime: state.activePresetId == event.id,
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to delete timer preset: $e');
      emit(state.copyWith(presets: state.presets));
    }
  }

  void _onToggleEditMode(
    ToggleEditPresetsMode event,
    Emitter<TimerState> emit,
  ) {
    emit(state.copyWith(isEditingPresets: !state.isEditingPresets));
  }

  Future<void> _onReorderPresets(
    ReorderTimerPresets event,
    Emitter<TimerState> emit,
  ) async {
    final updatedPresets = List<TimerPreset>.from(state.presets);
    final item = updatedPresets.removeAt(event.oldIndex);
    updatedPresets.insert(event.newIndex, item);

    try {
      await repository.savePresets(updatedPresets);
      emit(state.copyWith(presets: updatedPresets));
    } catch (e) {
      AppLogger.e('Failed to reorder timer presets: $e');
      emit(state.copyWith(presets: state.presets));
    }
  }

  Future<void> _onStart(StartTimer event, Emitter<TimerState> emit) async {
    var currentPresets = List<TimerPreset>.from(state.presets);
    final existingPresetIndex = currentPresets.indexWhere(
      (p) => p.duration == event.duration,
    );

    String timerId;
    if (existingPresetIndex != -1) {
      timerId = event.presetId.isNotEmpty
          ? event.presetId
          : currentPresets[existingPresetIndex].id;
    } else {
      timerId = event.presetId.isNotEmpty
          ? event.presetId
          : DateTime.now().millisecondsSinceEpoch.toString();
      final newPreset = TimerPreset(id: timerId, duration: event.duration);
      currentPresets.add(newPreset);
      try {
        await repository.savePresets(currentPresets);
      } catch (e) {
        AppLogger.e('Failed to auto-save preset on start: $e');
      }
    }

    final now = DateTime.now();
    final updatedActiveTimers = Map<String, ActiveTimerData>.from(
      state.activeTimers,
    );

    if (event.resetOldActiveTimers) {
      for (final timerId in updatedActiveTimers.keys) {
        try {
          await systemAlarmService.cancelTimer(timerId);
        } catch (e) {
          AppLogger.e('Failed to cancel old timer on reset: $e');
        }
      }

      updatedActiveTimers.clear();
    } else {
      // Pause any other currently running timer and capture its remaining time
      for (final entry in updatedActiveTimers.entries) {
        if (entry.key != timerId && entry.value.status == TimerStatus.running) {
          final remaining = entry.value.endTime != null
              ? entry.value.endTime!.difference(now)
              : entry.value.remaining;
          final ceiledSeconds = (remaining.inMilliseconds + 999) ~/ 1000;
          final ceiledRemaining = ceiledSeconds > 0
              ? Duration(seconds: ceiledSeconds)
              : Duration.zero;

          updatedActiveTimers[entry.key] = entry.value.copyWith(
            status: TimerStatus.paused,
            remaining: ceiledRemaining,
            clearEndTime: true,
          );

          try {
            await systemAlarmService.cancelTimer(entry.key);
          } catch (e) {
            AppLogger.e('Failed to cancel system timer on auto-pause: $e');
          }
        }
      }
    }

    // Set the selected timer to running
    final initialDuration = event.duration;
    final existingData = updatedActiveTimers[timerId];
    final remainingToUse =
        (existingData != null && existingData.remaining > Duration.zero)
        ? existingData.remaining
        : initialDuration;

    final endTime = now.add(remainingToUse);
    updatedActiveTimers[timerId] = ActiveTimerData(
      id: timerId,
      duration: initialDuration,
      remaining: remainingToUse,
      status: TimerStatus.running,
      endTime: endTime,
    );

    try {
      await systemAlarmService.setTimer(timerId, remainingToUse);
      emit(
        state.copyWith(
          status: TimerStatus.running,
          duration: initialDuration,
          remaining: remainingToUse,
          activePresetId: timerId,
          endTime: endTime,
          presets: currentPresets,
          activeTimers: updatedActiveTimers,
        ),
      );

      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        add(const TimerTick());
      });
    } catch (e) {
      AppLogger.e('Failed to start timer: $e');
      emit(
        state.copyWith(
          status: TimerStatus.idle,
          duration: Duration.zero,
          remaining: Duration.zero,
          activePresetId: '',
          clearEndTime: true,
          presets: currentPresets,
        ),
      );
    }
  }

  Future<void> _onPause(PauseTimer event, Emitter<TimerState> emit) async {
    final targetId = event.presetId.isNotEmpty
        ? event.presetId
        : (state.activePresetId.isNotEmpty
              ? state.activePresetId
              : state.activeTimers.entries
                    .firstWhere(
                      (e) => e.value.status == TimerStatus.running,
                      orElse: () => const MapEntry(
                        '',
                        ActiveTimerData(
                          id: '',
                          duration: Duration.zero,
                          remaining: Duration.zero,
                          status: TimerStatus.idle,
                        ),
                      ),
                    )
                    .key);

    if (targetId.isEmpty) return;

    final now = DateTime.now();
    final updatedActiveTimers = Map<String, ActiveTimerData>.from(
      state.activeTimers,
    );
    final timerData = updatedActiveTimers[targetId];

    if (timerData != null && timerData.status == TimerStatus.running) {
      final remaining = timerData.endTime != null
          ? timerData.endTime!.difference(now)
          : timerData.remaining;
      final validRemaining = remaining.isNegative ? Duration.zero : remaining;
      updatedActiveTimers[targetId] = timerData.copyWith(
        status: TimerStatus.paused,
        remaining: validRemaining,
        clearEndTime: true,
      );

      try {
        await systemAlarmService.cancelTimer(targetId);
      } catch (e) {
        AppLogger.e('Failed to cancel timer on pause: $e');
      }

      final hasRunning = updatedActiveTimers.values.any(
        (t) => t.status == TimerStatus.running,
      );
      if (!hasRunning) {
        _ticker?.cancel();
      }

      emit(
        state.copyWith(
          status: hasRunning ? TimerStatus.running : TimerStatus.paused,
          activeTimers: updatedActiveTimers,
          remaining: state.activePresetId == targetId
              ? validRemaining
              : state.remaining,
          clearEndTime: state.activePresetId == targetId,
        ),
      );
    }
  }

  Future<void> _onResume(ResumeTimer event, Emitter<TimerState> emit) async {
    final targetId = event.presetId.isNotEmpty
        ? event.presetId
        : (state.activePresetId.isNotEmpty
              ? state.activePresetId
              : state.activeTimers.entries
                    .firstWhere(
                      (e) => e.value.status == TimerStatus.paused,
                      orElse: () => const MapEntry(
                        '',
                        ActiveTimerData(
                          id: '',
                          duration: Duration.zero,
                          remaining: Duration.zero,
                          status: TimerStatus.idle,
                        ),
                      ),
                    )
                    .key);

    if (targetId.isEmpty) return;

    final now = DateTime.now();
    final updatedActiveTimers = Map<String, ActiveTimerData>.from(
      state.activeTimers,
    );

    // Pause any other running timer
    for (final entry in updatedActiveTimers.entries) {
      if (entry.key != targetId && entry.value.status == TimerStatus.running) {
        final remaining = entry.value.endTime != null
            ? entry.value.endTime!.difference(now)
            : entry.value.remaining;
        final ceiledSeconds = (remaining.inMilliseconds + 999) ~/ 1000;
        final ceiledRemaining = ceiledSeconds > 0
            ? Duration(seconds: ceiledSeconds)
            : Duration.zero;

        updatedActiveTimers[entry.key] = entry.value.copyWith(
          status: TimerStatus.paused,
          remaining: ceiledRemaining,
          clearEndTime: true,
        );

        try {
          await systemAlarmService.cancelTimer(entry.key);
        } catch (e) {
          AppLogger.e('Failed to cancel timer on auto-pause: $e');
        }
      }
    }

    final timerData = updatedActiveTimers[targetId];
    final remaining = (timerData != null && timerData.remaining > Duration.zero)
        ? timerData.remaining
        : (timerData?.duration ?? Duration.zero);

    if (remaining <= Duration.zero) return;

    final newEndTime = now.add(remaining);
    updatedActiveTimers[targetId] =
        (timerData ??
                ActiveTimerData(
                  id: targetId,
                  duration: remaining,
                  remaining: remaining,
                  status: TimerStatus.running,
                ))
            .copyWith(
              status: TimerStatus.running,
              remaining: remaining,
              endTime: newEndTime,
            );

    try {
      await systemAlarmService.setTimer(targetId, remaining);
      emit(
        state.copyWith(
          status: TimerStatus.running,
          duration: updatedActiveTimers[targetId]!.duration,
          remaining: remaining,
          activePresetId: targetId,
          endTime: newEndTime,
          activeTimers: updatedActiveTimers,
        ),
      );

      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        add(const TimerTick());
      });
    } catch (e) {
      AppLogger.e('Failed to resume timer: $e');
    }
  }

  Future<void> _onCancel(CancelTimer event, Emitter<TimerState> emit) async {
    final targetId = event.presetId.isNotEmpty
        ? event.presetId
        : state.activePresetId;

    final updatedActiveTimers = Map<String, ActiveTimerData>.from(
      state.activeTimers,
    );

    if (targetId.isNotEmpty) {
      updatedActiveTimers.remove(targetId);
      try {
        await systemAlarmService.cancelTimer(targetId);
      } catch (e) {
        AppLogger.e('Failed to cancel timer: $e');
      }
    } else {
      for (final key in updatedActiveTimers.keys) {
        try {
          await systemAlarmService.cancelTimer(key);
        } catch (_) {}
      }
      updatedActiveTimers.clear();
    }

    final hasRunning = updatedActiveTimers.values.any(
      (t) => t.status == TimerStatus.running,
    );
    final hasPaused = updatedActiveTimers.values.any(
      (t) => t.status == TimerStatus.paused,
    );
    final newStatus = hasRunning
        ? TimerStatus.running
        : (hasPaused ? TimerStatus.paused : TimerStatus.idle);

    if (!hasRunning) {
      _ticker?.cancel();
    }

    emit(
      state.copyWith(
        status: newStatus,
        duration: targetId == state.activePresetId
            ? Duration.zero
            : state.duration,
        remaining: targetId == state.activePresetId
            ? Duration.zero
            : state.remaining,
        activePresetId: targetId == state.activePresetId
            ? ''
            : state.activePresetId,
        clearEndTime: targetId == state.activePresetId,
        activeTimers: updatedActiveTimers,
      ),
    );
  }

  Future<void> _onTick(TimerTick event, Emitter<TimerState> emit) async {
    final now = DateTime.now();
    final updatedActiveTimers = Map<String, ActiveTimerData>.from(
      state.activeTimers,
    );
    String? finishedId;
    Duration? finishedDuration;

    for (final entry in updatedActiveTimers.entries.toList()) {
      if (entry.value.status == TimerStatus.running) {
        if (entry.value.endTime == null) continue;
        final newRemaining = entry.value.endTime!.difference(now);

        if (newRemaining <= Duration.zero) {
          finishedId = entry.key;
          finishedDuration = entry.value.duration;
          updatedActiveTimers[entry.key] = entry.value.copyWith(
            status: TimerStatus.finished,
            remaining: Duration.zero,
            clearEndTime: true,
          );

          try {
            await systemAlarmService.cancelTimer(entry.key);
          } catch (e) {
            AppLogger.e('Failed to cancel timer on tick completion: $e');
          }
          try {
            await systemAlarmService.playCompletionSound();
          } catch (e) {
            AppLogger.e('Failed to play completion sound on tick: $e');
          }
        } else {
          final ceiledSeconds = (newRemaining.inMilliseconds + 999) ~/ 1000;
          final ceiledRemaining = Duration(seconds: ceiledSeconds);
          updatedActiveTimers[entry.key] = entry.value.copyWith(
            remaining: ceiledRemaining,
          );
        }
      }
    }

    final hasRunning = updatedActiveTimers.values.any(
      (t) => t.status == TimerStatus.running,
    );
    if (!hasRunning) {
      _ticker?.cancel();
    }

    if (finishedId != null) {
      emit(
        state.copyWith(
          status: TimerStatus.finished,
          duration: finishedDuration ?? state.duration,
          remaining: Duration.zero,
          activePresetId: finishedId,
          clearEndTime: true,
          activeTimers: updatedActiveTimers,
        ),
      );
    } else {
      final primaryRemaining =
          state.activePresetId.isNotEmpty &&
              updatedActiveTimers.containsKey(state.activePresetId)
          ? updatedActiveTimers[state.activePresetId]!.remaining
          : state.remaining;

      emit(
        state.copyWith(
          remaining: primaryRemaining,
          activeTimers: updatedActiveTimers,
        ),
      );
    }
  }

  Future<void> _onSetSound(
    SetTimerSound event,
    Emitter<TimerState> emit,
  ) async {
    try {
      await repository.saveSelectedSound(event.sound);
      emit(state.copyWith(sound: event.sound));
    } catch (e) {
      AppLogger.e('Failed to set selected sound: $e');
      emit(state.copyWith(sound: state.sound));
    }
  }

  void _onResetToIdle(ResetTimerToIdle event, Emitter<TimerState> emit) {
    _ticker?.cancel();
    emit(
      state.copyWith(
        status: TimerStatus.idle,
        duration: Duration.zero,
        remaining: Duration.zero,
        activePresetId: '',
        clearEndTime: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
