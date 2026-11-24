import 'dart:convert';
import 'dart:io';

import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/core/utils/alarm_sounds.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A timer the daemon is running for one of the app's timer ids.
class ScheduledTimer {
  final String id;
  final DateTime endsAt;

  const ScheduledTimer(this.id, this.endsAt);
}

/// A timer that ended while the device or mxclockd was off, so it never
/// rang. mxclockd keeps it as missed (the launcher can show it) until it is
/// dismissed and removed.
class MissedTimer {
  /// mxclockd's id for it.
  final String daemonId;

  /// The app's timer (preset) id when the app started it.
  final String? appId;
  final String label;
  final DateTime endedAt;

  const MissedTimer({
    required this.daemonId,
    this.appId,
    required this.label,
    required this.endedAt,
  });

  @override
  bool operator ==(Object other) =>
      other is MissedTimer &&
      other.daemonId == daemonId &&
      other.appId == appId &&
      other.label == label &&
      other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(daemonId, appId, label, endedAt);
}

/// The timers mxclockd has for the app (see [SystemAlarmService.restoreTimers]).
class RestoredTimers {
  /// The app's timers still counting down.
  final List<ScheduledTimer> running;

  /// Timers that ended while the device or mxclockd was off.
  final List<MissedTimer> missed;

  const RestoredTimers({this.running = const [], this.missed = const []});

  static const none = RestoredTimers();
}

/// Timers (run in mxclockd), sound previews and the time zone. Maps the app's
/// preset ids to the daemon's timer ids in shared preferences.
class SystemAlarmService {
  SystemAlarmService({
    ClockdClient? client,
    String? Function(String? sound)? soundPath,
    Future<SharedPreferences> Function()? preferences,
  }) : client = client ?? ClockdClient(),
       _soundPath = soundPath ?? alarmSoundPath,
       _preferences = preferences ?? SharedPreferences.getInstance;

  final ClockdClient client;
  final String? Function(String? sound) _soundPath;
  final Future<SharedPreferences> Function() _preferences;

  /// App timer id → daemon timer id.
  static const _timerIdsKey = 'clockd_timer_ids';

  Process? _preview;

  /// Bumped by every play and stop, so a preview whose player is still
  /// starting when it is replaced or stopped is killed as soon as it starts.
  int _previewRun = 0;

  /// Starts (or restarts) the timer [id] to ring after [duration], with the
  /// daemon's sound. Throws when the daemon refuses it.
  Future<void> setTimer(
    String id,
    Duration duration, {
    String label = '',
  }) async {
    await cancelTimer(id);
    final daemonId = await client.addTimer(duration, label: label);
    final ids = await _timerIds();
    ids[id] = daemonId;
    await _saveTimerIds(ids);
    AppLogger.i('SystemAlarmService: timer $id set for $duration ($daemonId)');
  }

  /// Stops the timer [id] if it is still counting down. Throws a
  /// [ClockdException] if mxclockd couldn't be told (the mapping is kept).
  Future<void> cancelTimer(String id) async {
    final ids = await _timerIds();
    final daemonId = ids[id];
    if (daemonId == null) return;
    await client.removeTimer(daemonId);
    ids.remove(id);
    await _saveTimerIds(ids);
  }

  /// The timer [id] reached zero: the daemon rings it and forgets it, so
  /// only the mapping goes. (Calling [cancelTimer] here could remove it
  /// before it rings, as the app's countdown may end first.)
  Future<void> forgetTimer(String id) async {
    final ids = await _timerIds();
    if (ids.remove(id) != null) await _saveTimerIds(ids);
  }

  /// mxclockd (re)started: timers that ended while it was down are now
  /// missed. Read [restoreTimers] again.
  Stream<void> get daemonStarted => client.started;

  /// The app's running timers and all missed ones, as mxclockd has them.
  /// The app's timers dismissed elsewhere are removed; other mappings dropped.
  Future<RestoredTimers> restoreTimers() async {
    final List<ClockdTimer> all;
    try {
      all = await client.listTimers();
    } catch (e) {
      AppLogger.e('Failed to list timers: $e');
      return RestoredTimers.none;
    }
    final ids = await _timerIds();
    final appIdOf = {for (final e in ids.entries) e.value: e.key};
    final running = <ScheduledTimer>[];
    final missed = <MissedTimer>[];
    for (final t in all) {
      final appId = appIdOf[t.id];
      switch (t.status) {
        case ClockdTimerStatus.running:
          if (appId != null) running.add(ScheduledTimer(appId, t.endsAt));
        case ClockdTimerStatus.missed:
          missed.add(
            MissedTimer(
              daemonId: t.id,
              appId: appId,
              label: t.label,
              endedAt: t.endsAt,
            ),
          );
        case ClockdTimerStatus.dismissed:
          // Seen and dismissed elsewhere; the app's own are cleared out.
          if (appId != null) await _removeQuietly(t.id);
      }
    }
    final kept = {
      for (final t in all)
        if (t.status != ClockdTimerStatus.dismissed) t.id,
    };
    ids.removeWhere((_, daemonId) => !kept.contains(daemonId));
    await _saveTimerIds(ids);
    missed.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return RestoredTimers(running: running, missed: missed);
  }

  Future<void> _removeQuietly(String daemonId) async {
    try {
      await client.removeTimer(daemonId);
    } catch (e) {
      AppLogger.e('Failed to remove dismissed timer $daemonId: $e');
    }
  }

  /// Plays [sound] once (preview in the sound picker), stopping the
  /// previous preview.
  Future<void> playCompletionSound({String? sound}) async {
    stopPreview();
    final run = _previewRun;
    final path = _soundPath(sound);
    if (path == null) return;
    final players = <(String, List<String>)>[
      ('pw-play', ['--media-role', 'Alarm', path]),
      ('paplay', ['--property=media.role=Alarm', path]),
    ];
    for (final (player, args) in players) {
      final Process process;
      try {
        process = await Process.start(player, args);
      } catch (_) {
        continue; // Not installed; try the next one.
      }
      if (run != _previewRun) {
        // Stopped or replaced while the player was starting.
        process.kill();
      } else {
        _preview = process;
      }
      return;
    }
    AppLogger.e('No audio player (pw-play/paplay) to preview $path');
  }

  /// Stops the sound picker's preview, if one is playing.
  void stopPreview() {
    _previewRun++;
    _preview?.kill();
    _preview = null;
  }

  Future<Map<String, String>> _timerIds() async {
    try {
      final prefs = await _preferences();
      final json = prefs.getString(_timerIdsKey);
      if (json == null) return {};
      return (jsonDecode(json) as Map<String, dynamic>).cast<String, String>();
    } catch (e) {
      AppLogger.e('Reading timer ids: $e');
      return {};
    }
  }

  Future<void> _saveTimerIds(Map<String, String> ids) async {
    try {
      final prefs = await _preferences();
      await prefs.setString(_timerIdsKey, jsonEncode(ids));
    } catch (e) {
      AppLogger.e('Saving timer ids: $e');
    }
  }

  String getTimezoneSync() {
    // 1. TZ environment variable
    final tzEnv = Platform.environment['TZ'];
    if (tzEnv != null && tzEnv.isNotEmpty) {
      return tzEnv;
    }

    // 2. timedatectl (systemd)
    try {
      final result = Process.runSync('timedatectl', [
        'show',
        '--property=Timezone',
        '--value',
      ]);

      if (result.exitCode == 0) {
        final timezone = (result.stdout as String).trim();
        if (timezone.isNotEmpty) {
          return timezone;
        }
      }
    } catch (e) {
      AppLogger.e('Failed to get timezone: $e');
    }

    // 3. /etc/localtime symlink
    try {
      final link = Link('/etc/localtime');

      if (link.existsSync()) {
        final target = link.targetSync();
        final match = RegExp(r'zoneinfo/(.+)$').firstMatch(target);

        if (match != null) {
          return match.group(1)!;
        }
      }
    } catch (e) {
      AppLogger.e('Failed to get timezone: $e');
    }

    // 4. Fallback
    return 'UTC';
  }
}
