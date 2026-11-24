import 'package:equatable/equatable.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';

import '../data/models/active_timer_data.dart';
import '../data/models/timer_preset.dart';

enum TimerStatus { initial, idle, running, paused, finished }

/// What the user tried when a timer change failed.
enum TimerChange { start, pause, cancel }

/// A timer change mxclockd couldn't make. [seq] tells two failures apart, so
/// each one is shown.
class TimerFailure extends Equatable {
  final TimerChange change;
  final ClockdException error;
  final int seq;

  const TimerFailure(this.change, this.error, this.seq);

  @override
  List<Object?> get props => [change, seq];
}

class TimerState extends Equatable {
  final TimerStatus status;
  final Duration duration;
  final Duration remaining;
  final List<TimerPreset> presets;
  final String activePresetId;
  final DateTime? endTime;
  final Map<String, ActiveTimerData> activeTimers;

  /// The last timer change that failed, for the screen to show once.
  final TimerFailure? failure;

  const TimerState({
    this.status = TimerStatus.initial,
    this.duration = Duration.zero,
    this.remaining = Duration.zero,
    this.presets = const [],
    this.activePresetId = '',
    this.endTime,
    this.activeTimers = const {},
    this.failure,
  });

  TimerState copyWith({
    TimerStatus? status,
    Duration? duration,
    Duration? remaining,
    List<TimerPreset>? presets,
    String? activePresetId,
    DateTime? endTime,
    bool clearEndTime = false,
    Map<String, ActiveTimerData>? activeTimers,
    TimerFailure? failure,
  }) {
    return TimerState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      activeTimers: activeTimers ?? this.activeTimers,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    duration,
    remaining,
    presets,
    activePresetId,
    endTime,
    activeTimers,
    failure,
  ];
}
