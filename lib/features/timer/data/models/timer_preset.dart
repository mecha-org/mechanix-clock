import 'package:equatable/equatable.dart';

class TimerPreset extends Equatable {
  final String id;
  final Duration duration;
  final String? name;

  const TimerPreset({required this.id, required this.duration, this.name});

  TimerPreset copyWith({String? id, Duration? duration, String? name}) {
    return TimerPreset(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'durationMs': duration.inMilliseconds, 'name': name};
  }

  factory TimerPreset.fromJson(Map<String, dynamic> json) {
    return TimerPreset(
      id: json['id'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      name: json['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, duration, name];
}
