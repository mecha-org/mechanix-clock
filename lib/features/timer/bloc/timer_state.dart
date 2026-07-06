import 'package:equatable/equatable.dart';

import '../data/models/timer_preset.dart';

enum TimerStatus { initial, idle, running, paused, finished }

class TimerState extends Equatable {
  final TimerStatus status;
  final Duration duration;
  final Duration remaining;
  final String sound;
  final List<TimerPreset> presets;
  final bool isEditingPresets;
  final String activePresetId;
  final DateTime? endTime;

  const TimerState({
    this.status = TimerStatus.initial,
    this.duration = Duration.zero,
    this.remaining = Duration.zero,
    this.sound = '',
    this.presets = const [],
    this.isEditingPresets = false,
    this.activePresetId = '',
    this.endTime,
  });

  TimerState copyWith({
    TimerStatus? status,
    Duration? duration,
    Duration? remaining,
    String? sound,
    List<TimerPreset>? presets,
    bool? isEditingPresets,
    String? activePresetId,
    DateTime? endTime,
    bool clearEndTime = false,
  }) {
    return TimerState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      sound: sound ?? this.sound,
      presets: presets ?? this.presets,
      isEditingPresets: isEditingPresets ?? this.isEditingPresets,
      activePresetId: activePresetId ?? this.activePresetId,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
    );
  }

  @override
  List<Object?> get props => [
    status,
    duration,
    remaining,
    sound,
    presets,
    isEditingPresets,
    activePresetId,
    endTime,
  ];
}
