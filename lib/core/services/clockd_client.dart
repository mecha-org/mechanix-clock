import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';

/// A call to mxclockd failed. Either [ClockdUnavailable] (the daemon isn't
/// there) or [ClockdRejected] (it answered with an error).
sealed class ClockdException implements Exception {
  const ClockdException(this.errorName, this.message);

  /// The D-Bus error name, or empty when the call never reached the bus.
  final String errorName;

  /// What went wrong, as the daemon or the bus put it.
  final String message;

  @override
  String toString() => '$runtimeType($errorName): $message';
}

/// mxclockd isn't running and couldn't be started (not installed, D-Bus
/// activation failed, no session bus), or it went away mid-call.
final class ClockdUnavailable extends ClockdException {
  const ClockdUnavailable(super.errorName, super.message);
}

/// mxclockd refused the call (e.g. `InvalidArgs` for an unreadable sound);
/// [message] is its reason.
final class ClockdRejected extends ClockdException {
  const ClockdRejected(super.errorName, super.message);
}

/// An alarm as mxclockd stores it (`ListAlarms` → `a(ssyyybsubu)`).
class ClockdAlarm {
  final String id;
  final String label;

  /// 0..23 and 0..59, local time.
  final int hour;
  final int minute;

  /// Bit 0 = Monday … bit 6 = Sunday; 0 = rings once.
  final int days;
  final bool enabled;

  /// Absolute path of the sound file; empty for the daemon's default.
  final String sound;

  /// Stops ringing on its own after this long (1..60).
  final int ringMinutes;

  /// Whether it rings with a Snooze button; false offers only Dismiss.
  final bool snoozeEnabled;

  /// How long Snooze puts it off (1..60); kept while snooze is off.
  final int snoozeMinutes;

  const ClockdAlarm({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    required this.days,
    required this.enabled,
    required this.sound,
    required this.ringMinutes,
    this.snoozeEnabled = true,
    required this.snoozeMinutes,
  });
}

/// What happened to a timer, as mxclockd reports it.
enum ClockdTimerStatus {
  /// Counting down; rings at its end time.
  running,

  /// Ended while the device or mxclockd was off, so it never rang. mxclockd
  /// keeps it (and sends `TimerMissed` on every start) until it is dismissed.
  missed,

  /// A missed timer that was dismissed; quiet, listed until `RemoveTimer`.
  dismissed,
}

/// A timer as mxclockd stores it (`ListTimers` → `a(ssxs)`).
class ClockdTimer {
  final String id;
  final String label;

  /// When it rings, or for a missed one, when it ended.
  final DateTime endsAt;
  final ClockdTimerStatus status;

  const ClockdTimer({
    required this.id,
    required this.label,
    required this.endsAt,
    this.status = ClockdTimerStatus.running,
  });
}

/// D-Bus client for mxclockd (`org.mechanix.services.Clock`), which stores,
/// schedules and rings alarms and timers. Calls start it via D-Bus activation.
class ClockdClient {
  ClockdClient({DBusClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? DBusClient.session;

  static const busName = 'org.mechanix.services.Clock';
  static const objectPath = '/org/mechanix/services/Clock';
  static const interface = 'org.mechanix.services.Clock';

  final DBusClient Function() _clientFactory;
  DBusClient? _client;
  DBusRemoteObject? _object;

  final _alarmsChanged = StreamController<void>.broadcast();
  final _subscriptions = <StreamSubscription<DBusSignal>>[];

  final _started = StreamController<void>.broadcast();

  /// The alarm list changed (from any client, the notification buttons, or a
  /// one-time alarm switching itself off after ringing). Re-read it.
  Stream<void> get alarmsChanged => _alarmsChanged.stream;

  /// mxclockd (re)started: it took its bus name. Calls that failed with
  /// [ClockdUnavailable] can be tried again.
  Stream<void> get started => _started.stream;

  DBusRemoteObject get _remote {
    final existing = _object;
    if (existing != null) return existing;
    final client = _client = _clientFactory();
    final object = _object = DBusRemoteObject(
      client,
      name: busName,
      path: DBusObjectPath(objectPath),
    );
    _listen(object);
    _nameOwnerSubscription = client.nameOwnerChanged
        .where((e) => e.name == busName && e.newOwner != null)
        .listen(
          (_) => _started.add(null),
          onError: (Object e) => AppLogger.e('[clockd] NameOwnerChanged: $e'),
        );
    return object;
  }

  StreamSubscription<void>? _nameOwnerSubscription;

  /// Subscribes to `AlarmsChanged`. Called on first use.
  void start() => _remote;

  void _listen(DBusRemoteObject object) {
    // A malformed signal is logged and skipped, not fatal to the stream.
    Stream<DBusSignal> signal(String name, String signature) =>
        DBusRemoteObjectSignalStream(
          object: object,
          interface: interface,
          name: name,
          signature: DBusSignature(signature),
        ).handleError((Object e) => AppLogger.e('[clockd] $name: $e'));

    _subscriptions.addAll([
      signal('AlarmsChanged', '').listen((_) => _alarmsChanged.add(null)),
    ]);
  }

  Future<List<DBusValue>> _call(
    String method,
    List<DBusValue> args,
    String replySignature,
  ) async {
    try {
      final result = await _remote.callMethod(
        interface,
        method,
        args,
        replySignature: DBusSignature(replySignature),
      );
      return result.returnValues;
    } on DBusMethodResponseException catch (e) {
      throw classify(e.errorName, _errorText(e));
    } on DBusReplySignatureException catch (e) {
      // mxclockd answered in another format: a version the app doesn't know.
      throw ClockdRejected(
        versionMismatch,
        '$method replied ${e.response.signature.value}, '
        'expected $replySignature',
      );
    } catch (e) {
      // No session bus, or the connection was lost. Callers log failures.
      throw ClockdUnavailable('', e.toString());
    }
  }

  /// [ClockdRejected.errorName] when mxclockd's reply has an unexpected
  /// format (its version doesn't match the app's).
  static const versionMismatch = 'mechanix_clock.VersionMismatch';

  /// D-Bus errors meaning nobody answered: the daemon isn't installed,
  /// couldn't be started, or went away.
  static const _unavailableErrors = {
    'org.freedesktop.DBus.Error.ServiceUnknown',
    'org.freedesktop.DBus.Error.NameHasNoOwner',
    'org.freedesktop.DBus.Error.NoReply',
    'org.freedesktop.DBus.Error.Disconnected',
    'org.freedesktop.DBus.Error.NoServer',
    'org.freedesktop.DBus.Error.Timeout',
    'org.freedesktop.DBus.Error.TimedOut',
  };

  /// The kind of failure for a D-Bus error from mxclockd.
  static ClockdException classify(String errorName, String message) {
    if (_unavailableErrors.contains(errorName) ||
        errorName.startsWith('org.freedesktop.DBus.Error.Spawn.')) {
      return ClockdUnavailable(errorName, message);
    }
    return ClockdRejected(errorName, message);
  }

  static String _errorText(DBusMethodResponseException e) {
    final values = e.response.values;
    if (values.isNotEmpty && values.first is DBusString) {
      return values.first.asString();
    }
    return e.errorName;
  }

  List<DBusValue> _alarmArgs({
    required String label,
    required int hour,
    required int minute,
    required int days,
    required String sound,
    required int ringMinutes,
    required bool snoozeEnabled,
    required int snoozeMinutes,
  }) => [
    DBusString(label),
    DBusByte(hour),
    DBusByte(minute),
    DBusByte(days),
    DBusString(sound),
    DBusUint32(ringMinutes),
    DBusBoolean(snoozeEnabled),
    DBusUint32(snoozeMinutes),
  ];

  // ---------- alarms ----------

  Future<List<ClockdAlarm>> listAlarms() async {
    final reply = await _call('ListAlarms', const [], 'a(ssyyybsubu)');
    return reply[0].asArray().map((value) {
      final f = value.asStruct();
      return ClockdAlarm(
        id: f[0].asString(),
        label: f[1].asString(),
        hour: f[2].asByte(),
        minute: f[3].asByte(),
        days: f[4].asByte(),
        enabled: f[5].asBoolean(),
        sound: f[6].asString(),
        ringMinutes: f[7].asUint32(),
        snoozeEnabled: f[8].asBoolean(),
        snoozeMinutes: f[9].asUint32(),
      );
    }).toList();
  }

  /// Returns the new alarm's id.
  Future<String> addAlarm({
    required String label,
    required int hour,
    required int minute,
    required int days,
    required String sound,
    required int ringMinutes,
    required bool snoozeEnabled,
    required int snoozeMinutes,
  }) async {
    final reply = await _call(
      'AddAlarm',
      _alarmArgs(
        label: label,
        hour: hour,
        minute: minute,
        days: days,
        sound: sound,
        ringMinutes: ringMinutes,
        snoozeEnabled: snoozeEnabled,
        snoozeMinutes: snoozeMinutes,
      ),
      's',
    );
    return reply[0].asString();
  }

  /// Replaces every editable field; the daemon also re-enables the alarm and
  /// clears any snooze.
  Future<void> updateAlarm(
    String id, {
    required String label,
    required int hour,
    required int minute,
    required int days,
    required String sound,
    required int ringMinutes,
    required bool snoozeEnabled,
    required int snoozeMinutes,
  }) async {
    await _call('UpdateAlarm', [
      DBusString(id),
      ..._alarmArgs(
        label: label,
        hour: hour,
        minute: minute,
        days: days,
        sound: sound,
        ringMinutes: ringMinutes,
        snoozeEnabled: snoozeEnabled,
        snoozeMinutes: snoozeMinutes,
      ),
    ], '');
  }

  Future<void> removeAlarm(String id) =>
      _call('RemoveAlarm', [DBusString(id)], '');

  Future<void> setAlarmEnabled(String id, bool enabled) =>
      _call('SetAlarmEnabled', [DBusString(id), DBusBoolean(enabled)], '');

  // ---------- timers ----------

  /// Starts a timer that rings after [duration] (rounded up to whole
  /// seconds) with the daemon's sound; returns its id.
  Future<String> addTimer(Duration duration, {String label = ''}) async {
    final seconds = duration.inMilliseconds <= 0
        ? 1
        : (duration.inMilliseconds + 999) ~/ 1000;
    final reply = await _call('AddTimer', [
      DBusUint32(seconds),
      DBusString(label),
    ], 's');
    return reply[0].asString();
  }

  Future<void> removeTimer(String id) =>
      _call('RemoveTimer', [DBusString(id)], '');

  Future<List<ClockdTimer>> listTimers() async {
    final reply = await _call('ListTimers', const [], 'a(ssxs)');
    return reply[0].asArray().map((value) {
      final f = value.asStruct();
      return ClockdTimer(
        id: f[0].asString(),
        label: f[1].asString(),
        endsAt: DateTime.fromMillisecondsSinceEpoch(f[2].asInt64() * 1000),
        status: switch (f[3].asString()) {
          'missed' => ClockdTimerStatus.missed,
          'dismissed' => ClockdTimerStatus.dismissed,
          _ => ClockdTimerStatus.running,
        },
      );
    }).toList();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _nameOwnerSubscription?.cancel();
    await _client?.close();
    await _alarmsChanged.close();
    await _started.close();
  }
}
