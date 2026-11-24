import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/in_order.dart';

import '../data/models/lap_time_model.dart';
import '../data/repository/stopwatch_repository.dart';
import 'stopwatch_event.dart';
import 'stopwatch_state.dart';

/// Phone-like stopwatch: keeps counting with the app closed or the device
/// asleep. Elapsed time is worked out from the saved start time
/// ([StopwatchRepository]); the ticker only refreshes the display.
class StopwatchBloc extends Bloc<StopwatchEvent, StopwatchState> {
  StopwatchBloc({StopwatchRepository? repository, DateTime Function()? now})
    : _repository = repository ?? StopwatchRepository(),
      _now = now ?? DateTime.now,
      super(const StopwatchState()) {
    on<LoadStopwatch>((_, emit) => _onLoad(emit), transformer: _inOrder());
    on<StartStopwatch>((_, emit) => _onStart(emit), transformer: _inOrder());
    on<StopStopwatch>((_, emit) => _onStop(emit), transformer: _inOrder());
    on<ResetStopwatch>((_, emit) => _onReset(emit), transformer: _inOrder());
    on<LapStopwatch>((_, emit) => _onLap(emit), transformer: _inOrder());
    on<StopwatchTick>((_, emit) => _onTick(emit), transformer: _inOrder());
  }

  final StopwatchRepository _repository;
  final DateTime Function() _now;
  SavedStopwatch _saved = const SavedStopwatch();
  Timer? _ticker;
  final _inOrder = InOrder();

  /// Picks up a stopwatch left running (or paused) last time.
  Future<void> _onLoad(Emitter<StopwatchState> emit) async {
    _saved = await _repository.load();
    _emitSaved(emit);
    if (_saved.isRunning) _startTicker();
  }

  Future<void> _onStart(Emitter<StopwatchState> emit) async {
    if (_saved.isRunning) return;
    _saved = SavedStopwatch(
      startedAt: _now(),
      accumulated: _saved.accumulated,
      laps: _saved.laps,
    );
    await _repository.save(_saved);
    _startTicker();
    _emitSaved(emit);
  }

  Future<void> _onStop(Emitter<StopwatchState> emit) async {
    if (!_saved.isRunning) return;
    _saved = SavedStopwatch(
      accumulated: _saved.elapsedAt(_now()),
      laps: _saved.laps,
    );
    _ticker?.cancel();
    await _repository.save(_saved);
    _emitSaved(emit);
  }

  Future<void> _onReset(Emitter<StopwatchState> emit) async {
    _ticker?.cancel();
    _saved = const SavedStopwatch();
    await _repository.clear();
    emit(const StopwatchState());
  }

  Future<void> _onLap(Emitter<StopwatchState> emit) async {
    final total = _saved.elapsedAt(_now());
    final lastTotal = _saved.laps.isEmpty
        ? Duration.zero
        : _saved.laps.first.totalTime;
    final lap = LapTime(
      lapNumber: _saved.laps.length + 1,
      duration: total - lastTotal,
      totalTime: total,
    );
    _saved = SavedStopwatch(
      startedAt: _saved.startedAt,
      accumulated: _saved.accumulated,
      laps: [lap, ..._saved.laps],
    );
    await _repository.save(_saved);
    emit(state.copyWith(laps: _saved.laps, elapsed: total));
  }

  Future<void> _onTick(Emitter<StopwatchState> emit) async {
    if (!_saved.isRunning) return;
    emit(state.copyWith(elapsed: _saved.elapsedAt(_now())));
  }

  void _emitSaved(Emitter<StopwatchState> emit) {
    final elapsed = _saved.elapsedAt(_now());
    final status = _saved.isRunning
        ? StopwatchStatus.running
        : (elapsed == Duration.zero && _saved.laps.isEmpty
              ? StopwatchStatus.initial
              : StopwatchStatus.stopped);
    emit(StopwatchState(status: status, elapsed: elapsed, laps: _saved.laps));
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 40),
      (_) => add(const StopwatchTick()),
    );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
