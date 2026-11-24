import 'package:equatable/equatable.dart';

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

class LoadTimerPresets extends TimerEvent {}

class DeleteTimerPreset extends TimerEvent {
  final String id;

  const DeleteTimerPreset(this.id);

  @override
  List<Object?> get props => [id];
}

class StartTimer extends TimerEvent {
  final Duration duration;
  final String presetId;
  final bool resetOldActiveTimers;

  const StartTimer(
    this.duration, {
    this.presetId = '',
    this.resetOldActiveTimers = false,
  });

  @override
  List<Object?> get props => [duration, presetId, resetOldActiveTimers];
}

class PauseTimer extends TimerEvent {
  final String presetId;

  const PauseTimer({this.presetId = ''});

  @override
  List<Object?> get props => [presetId];
}

class ResumeTimer extends TimerEvent {
  final String presetId;

  const ResumeTimer({this.presetId = ''});

  @override
  List<Object?> get props => [presetId];
}

class CancelTimer extends TimerEvent {
  final String presetId;

  const CancelTimer({this.presetId = ''});

  @override
  List<Object?> get props => [presetId];
}

class TimerTick extends TimerEvent {
  const TimerTick();
}

/// Re-read the timers from mxclockd (it restarted: timers that ended while
/// it was down are now missed).
class RefreshTimers extends TimerEvent {
  const RefreshTimers();
}
