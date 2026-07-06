import 'package:equatable/equatable.dart';

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

class LoadTimerPresets extends TimerEvent {}

class AddTimerPreset extends TimerEvent {
  final Duration duration;
  final String? name;

  const AddTimerPreset(this.duration, {this.name});

  @override
  List<Object?> get props => [duration, name];
}

class UpdateTimerPreset extends TimerEvent {
  final String id;
  final String name;

  const UpdateTimerPreset({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class DeleteTimerPreset extends TimerEvent {
  final String id;

  const DeleteTimerPreset(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleEditPresetsMode extends TimerEvent {}

class ReorderTimerPresets extends TimerEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderTimerPresets(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class StartTimer extends TimerEvent {
  final Duration duration;
  final String presetId;

  const StartTimer(this.duration, {this.presetId = ''});

  @override
  List<Object?> get props => [duration, presetId];
}

class PauseTimer extends TimerEvent {}

class ResumeTimer extends TimerEvent {}

class CancelTimer extends TimerEvent {}

class TimerTick extends TimerEvent {
  const TimerTick();
}

class SetTimerSound extends TimerEvent {
  final String sound;

  const SetTimerSound(this.sound);

  @override
  List<Object?> get props => [sound];
}

class ResetTimerToIdle extends TimerEvent {}
