import 'package:equatable/equatable.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_state.dart';

class ActiveTimerData extends Equatable {
  final String id;
  final Duration duration;
  final Duration remaining;
  final TimerStatus status;
  final DateTime? endTime;

  const ActiveTimerData({
    required this.id,
    required this.duration,
    required this.remaining,
    required this.status,
    this.endTime,
  });

  ActiveTimerData copyWith({
    String? id,
    Duration? duration,
    Duration? remaining,
    TimerStatus? status,
    DateTime? endTime,
    bool clearEndTime = false,
  }) {
    return ActiveTimerData(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      status: status ?? this.status,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
    );
  }

  @override
  List<Object?> get props => [id, duration, remaining, status, endTime];
}
