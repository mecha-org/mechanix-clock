import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:mechanix_clock/core/utils/in_order.dart';
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
  StreamSubscription<void>? _daemonStarted;
  int _failureSeq = 0;
  final _inOrder = InOrder();

  TimerFailure _failure(TimerChange change, Object error) => TimerFailure(
    change,
    error is ClockdException ? error : ClockdRejected('', error.toString()),
    ++_failureSeq,
  );

  /// Stops the daemon's timer [id]. On failure the timer is still running
  /// there: reports it as a failed [change] and returns false, so the caller
  /// leaves the timer as it was.
  Future<bool> _stopInDaemon(
    String id,
    TimerChange change,
    Emitter<TimerState> emit,
  ) async {
    try {
      await systemAlarmService.cancelTimer(id);
      return true;
    } catch (e) {
      AppLogger.e('Failed to stop timer $id in mxclockd: $e');
      emit(state.copyWith(failure: _failure(change, e)));
      return false;
    }
  }

  /// Shows [timers] as they now are after a start or resume that didn't
  /// happen (a timer stopped to make way for it is paused), reporting
  /// [error] if given. The status follows what is actually running.
  void _emitAfterFailedStart(
    Map<String, ActiveTimerData> timers,
    Emitter<TimerState> emit, {
    Object? error,
    List<TimerPreset>? presets,
  }) {
    final hasRunning = timers.values.any(
      (t) => t.status == TimerStatus.running,
    );
    final hasPaused = timers.values.any((t) => t.status == TimerStatus.paused);
    if (!hasRunning) _ticker?.cancel();
    final activeId = timers.containsKey(state.activePresetId)
        ? state.activePresetId
        : '';
    final active = timers[activeId];
    emit(
      state.copyWith(
        status: hasRunning
            ? TimerStatus.running
            : (hasPaused ? TimerStatus.paused : TimerStatus.idle),
        activeTimers: timers,
        activePresetId: activeId,
        duration: active?.duration ?? Duration.zero,
        remaining: active?.remaining ?? Duration.zero,
        endTime: active?.endTime,
        clearEndTime: active?.endTime == null,
        presets: presets,
        failure: error == null ? null : _failure(TimerChange.start, error),
      ),
    );
  }

  /// The paused timers in [state], as saved.
  static Map<String, PausedTimer> _paused(TimerState state) => {
    for (final t in state.activeTimers.values)
      if (t.status == TimerStatus.paused && t.remaining > Duration.zero)
        t.id: PausedTimer(duration: t.duration, remaining: t.remaining),
  };

  /// Saves the paused timers whenever they change, so they come back after
  /// a restart (the daemon only knows running ones).
  @override
  void onChange(Change<TimerState> change) {
    super.onChange(change);
    final paused = _paused(change.nextState);
    final before = _paused(change.currentState);
    if (paused.length == before.length &&
        paused.entries.every((e) => before[e.key] == e.value)) {
      return;
    }
    unawaited(
      Future.sync(() => repository.savePausedTimers(paused))
          .catchError((Object e) => AppLogger.e('Saving paused timers: $e')),
    );
  }

  TimerBloc({required this.repository, SystemAlarmService? systemAlarmService})
    : systemAlarmService = systemAlarmService ?? SystemAlarmService(),
      super(const TimerState()) {
    // One event at a time across all kinds, so handlers awaiting the daemon
    // can't overwrite each other (e.g. a resume and a cancel).
    on<LoadTimerPresets>(_onLoadPresets, transformer: _inOrder());
    on<DeleteTimerPreset>(_onDeletePreset, transformer: _inOrder());
    on<StartTimer>(_onStart, transformer: _inOrder());
    on<PauseTimer>(_onPause, transformer: _inOrder());
    on<ResumeTimer>(_onResume, transformer: _inOrder());
    on<CancelTimer>(_onCancel, transformer: _inOrder());
    on<TimerTick>(_onTick, transformer: _inOrder());
    on<RefreshTimers>(
      (_, emit) => _restoreFromDaemon(emit),
      transformer: _inOrder(),
    );
    _daemonStarted = this.systemAlarmService.daemonStarted.listen(
      (_) => add(const RefreshTimers()),
    );
  }

  Future<void> _onLoadPresets(
    LoadTimerPresets event,
    Emitter<TimerState> emit,
  ) async {
    try {
      final presets = await repository.getPresets();
      emit(state.copyWith(presets: presets, status: TimerStatus.idle));
      await _restorePaused(emit);
      await _restoreFromDaemon(emit);
    } catch (e) {
      AppLogger.e('Failed to load presets: $e');
      emit(state.copyWith(status: TimerStatus.idle, presets: const []));
    }
  }

  /// Timers that were paused when the app last closed.
  Future<void> _restorePaused(Emitter<TimerState> emit) async {
    Map<String, PausedTimer> paused;
    try {
      paused = await repository.getPausedTimers();
    } catch (e) {
      AppLogger.e('Failed to load paused timers: $e');
      return;
    }
    if (paused.isEmpty) return;
    final active = Map<String, ActiveTimerData>.from(state.activeTimers);
    for (final MapEntry(key: id, value: timer) in paused.entries) {
      active[id] = ActiveTimerData(
        id: id,
        duration: timer.duration,
        remaining: timer.remaining,
        status: TimerStatus.paused,
      );
    }
    final primary = active.values.first;
    emit(
      state.copyWith(
        status: TimerStatus.paused,
        activeTimers: active,
        activePresetId: primary.id,
        duration: primary.duration,
        remaining: primary.remaining,
        clearEndTime: true,
      ),
    );
  }

  /// Reloads timers from mxclockd after an app or daemon restart. Running
  /// ones come back; missed ones (ended while off) are dropped from the list.
  Future<void> _restoreFromDaemon(Emitter<TimerState> emit) async {
    final restored = await systemAlarmService.restoreTimers();
    final now = DateTime.now();
    final active = Map<String, ActiveTimerData>.from(state.activeTimers);
    for (final missed in restored.missed) {
      if (missed.appId != null) active.remove(missed.appId);
    }
    for (final timer in restored.running) {
      final remaining = timer.endsAt.difference(now);
      if (remaining <= Duration.zero) continue;
      final preset = state.presets.where((p) => p.id == timer.id).firstOrNull;
      active[timer.id] = ActiveTimerData(
        id: timer.id,
        duration: preset?.duration ?? remaining,
        remaining: remaining,
        status: TimerStatus.running,
        endTime: timer.endsAt,
      );
    }

    final hasRunning = active.values.any(
      (t) => t.status == TimerStatus.running,
    );
    final hasPaused = active.values.any((t) => t.status == TimerStatus.paused);
    // Show a running one (paused ones restored before may come first), else
    // the one shown before if it is still there, else a paused one.
    final primary =
        active.values
            .where((t) => t.status == TimerStatus.running)
            .firstOrNull ??
        active[state.activePresetId] ??
        active.values.firstOrNull;
    // A timer shown as running or paused that turned out to be missed
    // leaves nothing counting: back to idle.
    final wasCounting =
        state.status == TimerStatus.running ||
        state.status == TimerStatus.paused;
    final status = hasRunning
        ? TimerStatus.running
        : hasPaused
        ? TimerStatus.paused
        : wasCounting
        ? TimerStatus.idle
        : state.status;
    final idle = status == TimerStatus.idle && primary == null;
    emit(
      state.copyWith(
        status: status,
        activeTimers: active,
        activePresetId: primary?.id ?? '',
        duration: idle ? Duration.zero : (primary?.duration ?? state.duration),
        remaining: idle
            ? Duration.zero
            : (primary?.remaining ?? state.remaining),
        endTime: primary?.endTime,
        clearEndTime: primary?.endTime == null,
      ),
    );
    if (hasRunning) {
      _ticker?.cancel();
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => add(const TimerTick()),
      );
    } else {
      _ticker?.cancel();
    }
  }

  /// What the daemon's notification says: the preset's name, or its length.
  static String _label(
    List<TimerPreset> presets,
    String id,
    Duration duration,
  ) {
    final name = presets.where((p) => p.id == id).firstOrNull?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    return [
      if (h > 0) '$h h',
      if (m > 0) '$m min',
      if (s > 0) '$s s',
    ].join(' ');
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

    // A preset whose timer can't be stopped in the daemon is kept, or the
    // timer would ring with nothing in the app to stop it.
    if (!await _stopInDaemon(event.id, TimerChange.cancel, emit)) return;

    try {
      await repository.savePresets(updatedPresets);
      if (!updatedActiveTimers.values.any(
        (t) => t.status == TimerStatus.running,
      )) {
        _ticker?.cancel();
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
      for (final oldId in updatedActiveTimers.keys.toList()) {
        if (!await _stopInDaemon(oldId, TimerChange.start, emit)) {
          // Don't start a new one while an old one still runs; keep the
          // ones that did stop out of the list.
          _emitAfterFailedStart(
            updatedActiveTimers,
            emit,
            presets: currentPresets,
          );
          return;
        }
        updatedActiveTimers.remove(oldId);
      }
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

          // Only one timer runs at a time: the other one must stop first.
          // The new preset was saved above, so it stays in the list.
          if (!await _stopInDaemon(entry.key, TimerChange.start, emit)) {
            emit(state.copyWith(presets: currentPresets));
            return;
          }
          updatedActiveTimers[entry.key] = entry.value.copyWith(
            status: TimerStatus.paused,
            remaining: ceiledRemaining,
            clearEndTime: true,
          );
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
      await systemAlarmService.setTimer(
        timerId,
        remainingToUse,
        label: _label(currentPresets, timerId, initialDuration),
      );
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
      // Not running in the daemon: show it as it was before (or not at
      // all), and any timer stopped to make way for it as paused.
      if (existingData != null) {
        updatedActiveTimers[timerId] = existingData;
      } else {
        updatedActiveTimers.remove(timerId);
      }
      _emitAfterFailedStart(
        updatedActiveTimers,
        emit,
        error: e,
        presets: currentPresets,
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
      // Still running in the daemon if this fails: stays running here too.
      if (!await _stopInDaemon(targetId, TimerChange.pause, emit)) return;

      final remaining = timerData.endTime != null
          ? timerData.endTime!.difference(now)
          : timerData.remaining;
      final validRemaining = remaining.isNegative ? Duration.zero : remaining;
      updatedActiveTimers[targetId] = timerData.copyWith(
        status: TimerStatus.paused,
        remaining: validRemaining,
        clearEndTime: true,
      );

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

        // Only one timer runs at a time: the other one must stop first.
        if (!await _stopInDaemon(entry.key, TimerChange.start, emit)) return;
        updatedActiveTimers[entry.key] = entry.value.copyWith(
          status: TimerStatus.paused,
          remaining: ceiledRemaining,
          clearEndTime: true,
        );
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
      await systemAlarmService.setTimer(
        targetId,
        remaining,
        label: _label(
          state.presets,
          targetId,
          updatedActiveTimers[targetId]!.duration,
        ),
      );
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
      // Still paused; any timer stopped to make way for it is paused too.
      if (timerData != null) {
        updatedActiveTimers[targetId] = timerData;
      } else {
        updatedActiveTimers.remove(targetId);
      }
      _emitAfterFailedStart(updatedActiveTimers, emit, error: e);
    }
  }

  Future<void> _onCancel(CancelTimer event, Emitter<TimerState> emit) async {
    final targetId = event.presetId.isNotEmpty
        ? event.presetId
        : state.activePresetId;

    final updatedActiveTimers = Map<String, ActiveTimerData>.from(
      state.activeTimers,
    );

    // A timer the daemon couldn't stop stays, as it will still ring.
    if (targetId.isNotEmpty) {
      if (!await _stopInDaemon(targetId, TimerChange.cancel, emit)) return;
      updatedActiveTimers.remove(targetId);
    } else {
      for (final key in updatedActiveTimers.keys.toList()) {
        if (await _stopInDaemon(key, TimerChange.cancel, emit)) {
          updatedActiveTimers.remove(key);
        }
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

          // mxclockd rings it (sound and notification); the app only stops
          // counting.
          try {
            await systemAlarmService.forgetTimer(entry.key);
          } catch (e) {
            AppLogger.e('Failed to forget finished timer: $e');
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

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _daemonStarted?.cancel();
    return super.close();
  }
}
