import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'stopwatch_event.dart';
import 'stopwatch_state.dart';
import '../data/models/lap_time_model.dart';

class StopwatchBloc extends Bloc<StopwatchEvent, StopwatchState> {
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  StopwatchBloc() : super(const StopwatchState()) {
    on<StartStopwatch>(_onStart);
    on<StopStopwatch>(_onStop);
    on<ResetStopwatch>(_onReset);
    on<LapStopwatch>(_onLap);
    on<StopwatchTick>(_onTick);
  }

  void _onStart(StartStopwatch event, Emitter<StopwatchState> emit) {
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      add(StopwatchTick(_stopwatch.elapsed));
    });
    emit(state.copyWith(status: StopwatchStatus.running));
  }

  void _onStop(StopStopwatch event, Emitter<StopwatchState> emit) {
    _stopwatch.stop();
    _timer?.cancel();
    emit(state.copyWith(status: StopwatchStatus.stopped));
  }

  void _onReset(ResetStopwatch event, Emitter<StopwatchState> emit) {
    _stopwatch.stop();
    _stopwatch.reset();
    _timer?.cancel();
    emit(const StopwatchState());
  }

  void _onLap(LapStopwatch event, Emitter<StopwatchState> emit) {
    final currentTotal = _stopwatch.elapsed;
    final lastLapTotal = state.laps.isEmpty
        ? Duration.zero
        : state.laps.first.totalTime;
    final lapDuration = currentTotal - lastLapTotal;

    final newLap = LapTime(
      lapNumber: state.laps.length + 1,
      duration: lapDuration,
      totalTime: currentTotal,
    );

    final updatedLaps = List<LapTime>.from(state.laps)..insert(0, newLap);
    emit(state.copyWith(laps: updatedLaps));
  }

  void _onTick(StopwatchTick event, Emitter<StopwatchState> emit) {
    emit(state.copyWith(elapsed: event.elapsed));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
