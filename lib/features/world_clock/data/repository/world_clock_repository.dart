import 'dart:convert';

import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/world_clock_model.dart';

class WorldClockRepository {
  static const String _storageKey = 'world_clocks_list';

  Future<List<WorldClock>> getWorldClocks() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.reload();

      final String? clocksJson = preferences.getString(_storageKey);
      if (clocksJson == null || clocksJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(clocksJson);
      return decoded.map((item) => WorldClock.fromJson(item)).toList();
    } catch (e) {
      AppLogger.e('Failed to load world clocks: $e');
      return [];
    }
  }

  Future<void> saveWorldClocks(List<WorldClock> clocks) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String encoded = jsonEncode(clocks.map((c) => c.toJson()).toList());

      bool success = await preferences.setString(_storageKey, encoded);
      if (success) {
        AppLogger.i('on_save: Successfully saved world clocks');
      } else {
        AppLogger.e('on_save: Failed to write world clocks to disk');
      }
    } catch (e) {
      AppLogger.e('Failed to save world clocks: $e');
    }
  }
}
