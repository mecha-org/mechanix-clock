import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';

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
    on<LoadTimerPresets>(_onLoadPresets);
    on<AddTimerPreset>(_onAddPreset);
    on<UpdateTimerPreset>(_onUpdatePreset);
    on<DeleteTimerPreset>(_onDeletePreset);
    on<ToggleEditPresetsMode>(_onToggleEditMode);
    on<ReorderTimerPresets>(_onReorderPresets);
    on<StartTimer>(_onStart);
    on<PauseTimer>(_onPause);
    on<ResumeTimer>(_onResume);
    on<CancelTimer>(_onCancel);
    on<TimerTick>(_onTick);
    on<SetTimerSound>(_onSetSound);
    on<ResetTimerToIdle>(_onResetToIdle);
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

    try {
      await repository.savePresets(updatedPresets);
      if (state.activePresetId == event.id) {
        _ticker?.cancel();
        try {
          await systemAlarmService.cancelTimer(event.id);
        } catch (err) {
          AppLogger.e('Failed to cancel timer on delete: $err');
        }
        emit(
          state.copyWith(
            presets: updatedPresets,
            status: TimerStatus.idle,
            duration: Duration.zero,
            remaining: Duration.zero,
            activePresetId: '',
            clearEndTime: true,
          ),
        );
      } else {
        emit(state.copyWith(presets: updatedPresets));
      }
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
    _ticker?.cancel();

    final existingPreset = state.presets.firstWhere(
      (p) => p.duration == event.duration,
      orElse: () => const TimerPreset(id: '', duration: Duration.zero),
    );

    final presetId = event.presetId.isNotEmpty
        ? event.presetId
        : existingPreset.id;

    // Cancel existing system timer if any
    if (state.activePresetId.isNotEmpty) {
      try {
        await systemAlarmService.cancelTimer(state.activePresetId);
      } catch (err) {
        AppLogger.e('Failed to cancel existing timer on start: $err');
      }
    }

    final String timerId = presetId.isNotEmpty
        ? presetId
        : DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await systemAlarmService.setTimer(timerId, event.duration);
      final endTime = DateTime.now().add(event.duration);
      emit(
        state.copyWith(
          status: TimerStatus.running,
          duration: event.duration,
          remaining: event.duration,
          activePresetId: timerId,
          endTime: endTime,
        ),
      );

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
        ),
      );
    }
  }

  Future<void> _onPause(PauseTimer event, Emitter<TimerState> emit) async {
    if (state.status == TimerStatus.running) {
      _ticker?.cancel();
      if (state.activePresetId.isNotEmpty) {
        try {
          await systemAlarmService.cancelTimer(state.activePresetId);
        } catch (e) {
          AppLogger.e('Failed to cancel timer on pause: $e');
        }
      }
      emit(state.copyWith(status: TimerStatus.paused, clearEndTime: true));
    }
  }

  Future<void> _onResume(ResumeTimer event, Emitter<TimerState> emit) async {
    if (state.status == TimerStatus.paused) {
      try {
        if (state.activePresetId.isNotEmpty) {
          await systemAlarmService.setTimer(
            state.activePresetId,
            state.remaining,
          );
        }
        final newEndTime = DateTime.now().add(state.remaining);
        emit(state.copyWith(status: TimerStatus.running, endTime: newEndTime));
        _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
          add(const TimerTick());
        });
      } catch (e) {
        AppLogger.e('Failed to resume timer: $e');
        emit(state.copyWith(status: TimerStatus.paused, clearEndTime: true));
      }
    }
  }

  Future<void> _onCancel(CancelTimer event, Emitter<TimerState> emit) async {
    _ticker?.cancel();
    if (state.activePresetId.isNotEmpty) {
      try {
        await systemAlarmService.cancelTimer(state.activePresetId);
      } catch (e) {
        AppLogger.e('Failed to cancel timer: $e');
      }
    }
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

  Future<void> _onTick(TimerTick event, Emitter<TimerState> emit) async {
    if (state.status == TimerStatus.running) {
      if (state.endTime == null) return;
      final newRemaining = state.endTime!.difference(DateTime.now());

      if (newRemaining <= Duration.zero) {
        _ticker?.cancel();
        if (state.activePresetId.isNotEmpty) {
          try {
            await systemAlarmService.cancelTimer(state.activePresetId);
          } catch (e) {
            AppLogger.e('Failed to cancel timer on tick completion: $e');
          }
        }
        try {
          await systemAlarmService.playCompletionSound();
        } catch (e) {
          AppLogger.e('Failed to play completion sound on tick: $e');
        }
        emit(
          state.copyWith(
            status: TimerStatus.finished,
            remaining: Duration.zero,
            clearEndTime: true,
          ),
        );
      } else {
        emit(state.copyWith(remaining: newRemaining));
      }
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
