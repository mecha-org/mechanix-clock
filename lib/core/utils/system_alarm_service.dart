import 'package:flutter/services.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';

class SystemAlarmService {
  static const _channel = MethodChannel('com.example.clock/alarm');

  Future<void> setAlarm(
    String id,
    DateTime time,
    List<int> repeatDays,
    bool isSnoozeEnabled,
  ) async {
    try {
      final int timestamp = time.millisecondsSinceEpoch;
      await _channel.invokeMethod('setAlarm', {
        'id': id,
        'timestamp': timestamp,
        'repeatDays': repeatDays,
        'isSnoozeEnabled': isSnoozeEnabled,
      });
      AppLogger.i('SystemAlarmService: Alarm set for $time (ID: $id)');
    } on PlatformException catch (e) {
      AppLogger.e('Failed to set alarm: $e');
    }
  }

  Future<void> cancelAlarm(String id) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
      AppLogger.i('SystemAlarmService: Alarm cancelled (ID: $id)');
    } on PlatformException catch (e) {
      AppLogger.e('Failed to cancel alarm: $e');
    }
  }

  Future<void> setTimer(String id, Duration duration) async {
    try {
      await _channel.invokeMethod('setTimer', {
        'id': id,
        'durationSec': duration.inSeconds,
      });
      AppLogger.i('SystemAlarmService: System timer set for $duration (ID: $id)');
    } on PlatformException catch (e) {
      AppLogger.e('Failed to set system timer: $e');
    }
  }

  Future<void> cancelTimer(String id) async {
    try {
      await _channel.invokeMethod('cancelTimer', {'id': id});
      AppLogger.i('SystemAlarmService: System timer cancelled (ID: $id)');
    } on PlatformException catch (e) {
      AppLogger.e('Failed to cancel system timer: $e');
    }
  }

  Future<void> playCompletionSound() async {
    try {
      await _channel.invokeMethod('playCompletionSound');
      AppLogger.i('SystemAlarmService: Play completion sound');
    } on PlatformException catch (e) {
      AppLogger.e('Failed to play completion sound: $e');
    }
  }
}
