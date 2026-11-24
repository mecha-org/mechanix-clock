import 'package:equatable/equatable.dart';

class Alarm extends Equatable {
  /// The snooze lengths the user can pick, in minutes.
  static const snoozeOptions = [1, 5, 10, 15, 20, 30];
  static const defaultSnoozeMinutes = 10;

  /// How long an unanswered alarm rings before it stops on its own.
  static const defaultRingMinutes = 5;

  final String id;
  final int hour;
  final int minute;
  final bool isAm;
  final List<int> repeatDays;
  final String sound;
  final bool isSnoozeEnabled;
  final bool isActive;

  /// The user's name for the alarm ("Medicine"); empty when not set.
  final String label;

  /// How long Snooze waits before ringing again.
  final int snoozeMinutes;

  /// How long it rings when nobody stops it (kept as the daemon has it).
  final int ringMinutes;

  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.isAm,
    required this.repeatDays,
    required this.sound,
    required this.isSnoozeEnabled,
    this.isActive = true,
    this.label = '',
    this.snoozeMinutes = defaultSnoozeMinutes,
    this.ringMinutes = defaultRingMinutes,
  });

  /// The alarm time as shown to the user, e.g. "07:05 AM".
  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} '
      '${isAm ? 'AM' : 'PM'}';

  /// "07:05 AM · Medicine", or just the time when there is no label.
  String get description =>
      label.trim().isEmpty ? timeText : '$timeText · ${label.trim()}';

  /// The next time this alarm rings after [now]. [repeatDays] are
  /// Sunday-first (0 = Sunday … 6 = Saturday); without repeat days it rings
  /// once, today or tomorrow.
  DateTime nextRing(DateTime now) {
    var hour24 = hour % 12;
    if (!isAm) hour24 += 12;
    for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      final ring = DateTime(day.year, day.month, day.day, hour24, minute);
      if (!ring.isAfter(now)) continue;
      if (repeatDays.isEmpty || repeatDays.contains(ring.weekday % 7)) {
        return ring;
      }
    }
    // Unreachable for valid repeat days; ring a week from now.
    return now.add(const Duration(days: 7));
  }

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    bool? isAm,
    List<int>? repeatDays,
    String? sound,
    bool? isSnoozeEnabled,
    bool? isActive,
    String? label,
    int? snoozeMinutes,
    int? ringMinutes,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isAm: isAm ?? this.isAm,
      repeatDays: repeatDays ?? this.repeatDays,
      sound: sound ?? this.sound,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
      isActive: isActive ?? this.isActive,
      label: label ?? this.label,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      ringMinutes: ringMinutes ?? this.ringMinutes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    hour,
    minute,
    isAm,
    repeatDays,
    sound,
    isSnoozeEnabled,
    isActive,
    label,
    snoozeMinutes,
    ringMinutes,
  ];
}

/// Whether another alarm that is on (not [exceptId]) has this time, whatever
/// its days. One alarm per time, as in Ubuntu's Clocks.
bool alarmTimeTaken(
  List<Alarm> alarms, {
  required int hour,
  required int minute,
  required bool isAm,
  String? exceptId,
}) => alarms.any(
  (a) =>
      a.id != exceptId &&
      a.isActive &&
      a.hour == hour &&
      a.minute == minute &&
      a.isAm == isAm,
);
