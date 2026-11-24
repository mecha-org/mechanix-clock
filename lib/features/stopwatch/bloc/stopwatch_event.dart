import 'package:equatable/equatable.dart';

abstract class StopwatchEvent extends Equatable {
  const StopwatchEvent();

  @override
  List<Object?> get props => [];
}

/// Restores the stopwatch saved last time (it may still be running).
class LoadStopwatch extends StopwatchEvent {
  const LoadStopwatch();
}

class StartStopwatch extends StopwatchEvent {}

class StopStopwatch extends StopwatchEvent {}

class ResetStopwatch extends StopwatchEvent {}

class LapStopwatch extends StopwatchEvent {}

/// Refreshes the shown time while running (the time itself comes from the
/// saved start and the wall clock).
class StopwatchTick extends StopwatchEvent {
  const StopwatchTick();
}
