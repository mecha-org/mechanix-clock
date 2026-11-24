import 'dart:convert';

import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lap_time_model.dart';

/// Saved stopwatch state: last start time, time counted before it, and laps.
/// Elapsed time comes from the clock, so it keeps counting with the app closed.
class SavedStopwatch {
  /// When it was last started; null while paused or reset.
  final DateTime? startedAt;

  /// Time counted before [startedAt] (all of it while paused).
  final Duration accumulated;

  /// Newest first.
  final List<LapTime> laps;

  const SavedStopwatch({
    this.startedAt,
    this.accumulated = Duration.zero,
    this.laps = const [],
  });

  bool get isRunning => startedAt != null;

  /// Elapsed time at [now]. A clock set back before [startedAt] counts as
  /// no time passed, never as negative.
  Duration elapsedAt(DateTime now) {
    final start = startedAt;
    if (start == null) return accumulated;
    final running = now.difference(start);
    return accumulated + (running.isNegative ? Duration.zero : running);
  }

  Map<String, dynamic> toJson() => {
    'startedAtMs': startedAt?.millisecondsSinceEpoch,
    'accumulatedMs': accumulated.inMilliseconds,
    'laps': [
      for (final lap in laps)
        {
          'lap': lap.lapNumber,
          'durationMs': lap.duration.inMilliseconds,
          'totalMs': lap.totalTime.inMilliseconds,
        },
    ],
  };

  factory SavedStopwatch.fromJson(Map<String, dynamic> json) {
    final startedAtMs = json['startedAtMs'] as int?;
    return SavedStopwatch(
      startedAt: startedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startedAtMs),
      accumulated: Duration(milliseconds: json['accumulatedMs'] as int? ?? 0),
      laps: [
        for (final lap in (json['laps'] as List<dynamic>? ?? const []))
          LapTime(
            lapNumber: lap['lap'] as int,
            duration: Duration(milliseconds: lap['durationMs'] as int),
            totalTime: Duration(milliseconds: lap['totalMs'] as int),
          ),
      ],
    );
  }
}

class StopwatchRepository {
  StopwatchRepository({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  static const storageKey = 'stopwatch_state';

  final Future<SharedPreferences> Function() _preferences;

  Future<SavedStopwatch> load() async {
    try {
      final prefs = await _preferences();
      await prefs.reload();
      final json = prefs.getString(storageKey);
      if (json == null) return const SavedStopwatch();
      return SavedStopwatch.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e('[StopwatchRepository] Loading stopwatch failed: $e');
      return const SavedStopwatch();
    }
  }

  Future<void> save(SavedStopwatch stopwatch) async {
    try {
      final prefs = await _preferences();
      await prefs.setString(storageKey, jsonEncode(stopwatch.toJson()));
    } catch (e) {
      AppLogger.e('[StopwatchRepository] Saving stopwatch failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await _preferences();
      await prefs.remove(storageKey);
    } catch (e) {
      AppLogger.e('[StopwatchRepository] Clearing stopwatch failed: $e');
    }
  }
}
