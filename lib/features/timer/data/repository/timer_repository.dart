import 'dart:convert';

import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:mechanix_clock/core/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_preset.dart';

class TimerRepository {
  static const String _storageKey = 'timer_presets_list';
  static const String _soundKey = 'timer_selected_sound';

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

  Future<String> getSelectedSound() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.reload();
      return preferences.getString(_soundKey) ?? sounds[0];
    } catch (e) {
      return sounds[0];
    }
  }

  Future<void> saveSelectedSound(String sound) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setString(_soundKey, sound);
    } catch (e) {
      AppLogger.e('Failed to save timer selected sound: $e');
    }
  }
}
