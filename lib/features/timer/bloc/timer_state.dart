import 'package:equatable/equatable.dart';

import '../data/models/active_timer_data.dart';
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
  final Map<String, ActiveTimerData> activeTimers;

  const TimerState({
    this.status = TimerStatus.initial,
    this.duration = Duration.zero,
    this.remaining = Duration.zero,
    this.sound = '',
    this.presets = const [],
    this.isEditingPresets = false,
    this.activePresetId = '',
    this.endTime,
    this.activeTimers = const {},
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
    Map<String, ActiveTimerData>? activeTimers,
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
      activeTimers: activeTimers ?? this.activeTimers,
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
    activeTimers,
  ];
}
