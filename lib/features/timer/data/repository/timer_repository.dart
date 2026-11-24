import 'dart:convert';

import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:mechanix_clock/core/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_preset.dart';

/// A paused timer: mxclockd has no pause, so a paused timer exists only in
/// the app and is saved here to survive a restart.
class PausedTimer {
  final Duration duration;
  final Duration remaining;

  const PausedTimer({required this.duration, required this.remaining});

  @override
  bool operator ==(Object other) =>
      other is PausedTimer &&
      other.duration == duration &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(duration, remaining);
}

class TimerRepository {
  static const String _storageKey = 'timer_presets_list';
  static const String _pausedKey = 'timer_paused';

  Future<List<TimerPreset>> getPresets() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.reload();
      final String? presetsJson = preferences.getString(_storageKey);

      if (presetsJson == null || presetsJson.isEmpty) {
        return defaultTimerPresets;
      }

      final List<dynamic> decoded = jsonDecode(presetsJson);
      return decoded.map((item) => TimerPreset.fromJson(item)).toList();
    } catch (e) {
      AppLogger.e('Failed to load timer presets: $e');
      return defaultTimerPresets;
    }
  }

  Future<void> savePresets(List<TimerPreset> presets) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        presets.map((p) => p.toJson()).toList(),
      );
      await preferences.setString(_storageKey, encoded);
    } catch (e) {
      AppLogger.e('Failed to save timer presets: $e');
    }
  }

  /// Paused timers by timer id (see [PausedTimer]).
  Future<Map<String, PausedTimer>> getPausedTimers() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      final json = preferences.getString(_pausedKey);
      if (json == null || json.isEmpty) return {};
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          key: PausedTimer(
            duration: Duration(milliseconds: value['durationMs'] as int),
            remaining: Duration(milliseconds: value['remainingMs'] as int),
          ),
      };
    } catch (e) {
      AppLogger.e('Failed to load paused timers: $e');
      return {};
    }
  }

  Future<void> savePausedTimers(Map<String, PausedTimer> timers) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (timers.isEmpty) {
        await preferences.remove(_pausedKey);
        return;
      }
      await preferences.setString(
        _pausedKey,
        jsonEncode({
          for (final MapEntry(:key, :value) in timers.entries)
            key: {
              'durationMs': value.duration.inMilliseconds,
              'remainingMs': value.remaining.inMilliseconds,
            },
        }),
      );
    } catch (e) {
      AppLogger.e('Failed to save paused timers: $e');
    }
  }
}
