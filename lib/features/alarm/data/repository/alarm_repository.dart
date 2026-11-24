import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/core/utils/alarm_sounds.dart';

import '../models/alarm_model.dart';

/// Alarms stored in mxclockd ([ClockdClient]); converts the app's [Alarm]
/// (12-hour, Sunday-first days, sound id) to the daemon's form and back.
/// Saving switches an alarm on, as mxclockd does; `AlarmsChanged` keeps the
/// list in step with the daemon.
class AlarmRepository {
  AlarmRepository({
    ClockdClient? client,
    String? Function(String? soundId)? soundPath,
  }) : client = client ?? ClockdClient(),
       _soundPath = soundPath ?? alarmSoundPath;

  final ClockdClient client;
  final String? Function(String? soundId) _soundPath;

  /// The alarm list changed in the daemon (any client, or the notification).
  Stream<void> get changes => client.alarmsChanged;

  /// The daemon (re)started; a list that failed to load can be read now.
  Stream<void> get serviceStarted => client.started;

  Future<List<Alarm>> getAlarms() async => [
    for (final a in await client.listAlarms()) fromClockd(a),
  ];

  /// Adds [alarm] (switched on) and returns it with the id the daemon gave it.
  Future<Alarm> addAlarm(Alarm alarm) async {
    final f = _fields(alarm);
    final id = await client.addAlarm(
      label: f.label,
      hour: f.hour,
      minute: f.minute,
      days: f.days,
      sound: f.sound,
      ringMinutes: f.ringMinutes,
      snoozeEnabled: alarm.isSnoozeEnabled,
      snoozeMinutes: f.snoozeMinutes,
    );
    return alarm.copyWith(id: id, isActive: true);
  }

  /// Replaces [alarm]'s fields; mxclockd also switches it on.
  Future<void> updateAlarm(Alarm alarm) async {
    final f = _fields(alarm);
    await client.updateAlarm(
      alarm.id,
      label: f.label,
      hour: f.hour,
      minute: f.minute,
      days: f.days,
      sound: f.sound,
      ringMinutes: f.ringMinutes,
      snoozeEnabled: alarm.isSnoozeEnabled,
      snoozeMinutes: f.snoozeMinutes,
    );
  }

  Future<void> deleteAlarm(String id) => client.removeAlarm(id);

  Future<void> setAlarmEnabled(String id, bool enabled) =>
      client.setAlarmEnabled(id, enabled);

  // ---------- conversions ----------

  /// The daemon's alarm as the app shows it.
  static Alarm fromClockd(ClockdAlarm a) {
    final hour12 = a.hour % 12 == 0 ? 12 : a.hour % 12;
    return Alarm(
      id: a.id,
      hour: hour12,
      minute: a.minute,
      isAm: a.hour < 12,
      repeatDays: daysFromMask(a.days),
      sound: soundIdFromPath(a.sound),
      isSnoozeEnabled: a.snoozeEnabled,
      isActive: a.enabled,
      label: a.label,
      snoozeMinutes: a.snoozeMinutes,
      ringMinutes: a.ringMinutes,
    );
  }

  /// 24-hour hour of [alarm] (12 AM = 0, 12 PM = 12).
  static int hour24(Alarm alarm) => alarm.hour % 12 + (alarm.isAm ? 0 : 12);

  /// App repeat days (0 = Sunday … 6 = Saturday) → daemon bitmask
  /// (bit 0 = Monday … bit 6 = Sunday).
  static int maskFromDays(List<int> days) {
    var mask = 0;
    for (final day in days) {
      mask |= 1 << ((day + 6) % 7);
    }
    return mask;
  }

  static List<int> daysFromMask(int mask) => [
    for (var day = 0; day < 7; day++)
      if (mask & (1 << ((day + 6) % 7)) != 0) day,
  ];

  /// `/usr/share/sounds/mechanix/clock/music_box.ogg` → `music_box`.
  /// Anything else (including the daemon's default) shows as the default.
  static String soundIdFromPath(String path) =>
      alarmSoundFor(_soundFileId(path)).id;

  /// The file name of [path] without `.ogg`; empty if it isn't an `.ogg`.
  static String _soundFileId(String path) {
    final name = path.split('/').last;
    return name.endsWith('.ogg') ? name.substring(0, name.length - 4) : '';
  }

  _ClockdFields _fields(Alarm alarm) => _ClockdFields(
    label: alarm.label.trim(),
    hour: hour24(alarm),
    minute: alarm.minute,
    days: maskFromDays(alarm.repeatDays),
    sound: _soundPath(alarm.sound) ?? '',
    ringMinutes: alarm.ringMinutes.clamp(1, 60).toInt(),
    snoozeMinutes: alarm.snoozeMinutes.clamp(1, 60).toInt(),
  );
}

class _ClockdFields {
  final String label;
  final int hour;
  final int minute;
  final int days;
  final String sound;
  final int ringMinutes;
  final int snoozeMinutes;

  const _ClockdFields({
    required this.label,
    required this.hour,
    required this.minute,
    required this.days,
    required this.sound,
    required this.ringMinutes,
    required this.snoozeMinutes,
  });
}
