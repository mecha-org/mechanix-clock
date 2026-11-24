import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records timer calls instead of reaching mxclockd.
class FakeClockdClient extends ClockdClient {
  final added = <(Duration, String)>[];
  final removed = <String>[];
  List<ClockdTimer> timers = [];
  Object? removeError;
  Object? listError;
  final startedController = StreamController<void>.broadcast();
  int _next = 0;

  @override
  Future<String> addTimer(Duration duration, {String label = ''}) async {
    added.add((duration, label));
    return 'd${++_next}';
  }

  @override
  Future<void> removeTimer(String id) async {
    if (removeError case final e?) throw e;
    removed.add(id);
  }

  @override
  Future<List<ClockdTimer>> listTimers() async {
    if (listError case final e?) throw e;
    return timers;
  }

  @override
  Stream<void> get started => startedController.stream;
}

void main() {
  late FakeClockdClient client;
  late SystemAlarmService service;

  Future<Map<String, dynamic>> savedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('clockd_timer_ids');
    return json == null ? {} : jsonDecode(json) as Map<String, dynamic>;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = FakeClockdClient();
    service = SystemAlarmService(client: client, soundPath: (_) => null);
  });

  group('timers', () {
    test('setTimer starts a daemon timer and remembers its id', () async {
      await service.setTimer('p1', const Duration(minutes: 5), label: '5 min');
      expect(client.added, [(const Duration(minutes: 5), '5 min')]);
      expect(await savedIds(), {'p1': 'd1'});
    });

    test('setTimer again replaces the old run', () async {
      await service.setTimer('p1', const Duration(minutes: 5));
      await service.setTimer('p1', const Duration(minutes: 1));
      expect(client.removed, ['d1']);
      expect(await savedIds(), {'p1': 'd2'});
    });

    test('cancelTimer removes it from the daemon and the record', () async {
      await service.setTimer('p1', const Duration(minutes: 5));
      await service.cancelTimer('p1');
      expect(client.removed, ['d1']);
      expect(await savedIds(), isEmpty);
    });

    test('cancelTimer of an unknown id does nothing', () async {
      await service.cancelTimer('nope');
      expect(client.removed, isEmpty);
    });

    test('a failed cancel throws and keeps the record', () async {
      await service.setTimer('p1', const Duration(minutes: 5));
      client.removeError = const ClockdUnavailable('', 'down');
      await expectLater(
        service.cancelTimer('p1'),
        throwsA(isA<ClockdUnavailable>()),
      );
      expect(await savedIds(), {'p1': 'd1'});
    });

    test('forgetTimer drops the record without telling the daemon', () async {
      await service.setTimer('p1', const Duration(minutes: 5));
      await service.forgetTimer('p1');
      await service.forgetTimer('p1');
      expect(client.removed, isEmpty);
      expect(await savedIds(), isEmpty);
    });

    test('unreadable saved ids count as none', () async {
      SharedPreferences.setMockInitialValues({'clockd_timer_ids': '{oops'});
      await service.cancelTimer('p1');
      expect(client.removed, isEmpty);
    });

    test('daemonStarted is the client\'s started stream', () async {
      final got = service.daemonStarted.first;
      client.startedController.add(null);
      await got;
    });
  });

  group('restoreTimers', () {
    final t = DateTime(2026, 1, 1, 12);

    test('running, missed and dismissed timers', () async {
      await service.setTimer('run', const Duration(minutes: 5));
      await service.setTimer('miss', const Duration(minutes: 5));
      await service.setTimer('gone', const Duration(minutes: 5));
      await service.setTimer('dropped', const Duration(minutes: 5));
      client.timers = [
        ClockdTimer(id: 'd1', label: '', endsAt: t),
        ClockdTimer(
          id: 'd2',
          label: 'Tea',
          endsAt: t,
          status: ClockdTimerStatus.missed,
        ),
        ClockdTimer(
          id: 'other',
          label: 'Launcher',
          endsAt: t.add(const Duration(minutes: 1)),
          status: ClockdTimerStatus.missed,
        ),
        ClockdTimer(
          id: 'd3',
          label: '',
          endsAt: t,
          status: ClockdTimerStatus.dismissed,
        ),
        ClockdTimer(
          id: 'foreign',
          label: '',
          endsAt: t,
          status: ClockdTimerStatus.dismissed,
        ),
        ClockdTimer(id: 'foreign-run', label: '', endsAt: t),
      ];

      final restored = await service.restoreTimers();

      expect(restored.running.map((r) => (r.id, r.endsAt)).toList(), [
        ('run', t),
      ]);
      // Newest first.
      expect(restored.missed, [
        MissedTimer(
          daemonId: 'other',
          label: 'Launcher',
          endedAt: t.add(const Duration(minutes: 1)),
        ),
        MissedTimer(daemonId: 'd2', appId: 'miss', label: 'Tea', endedAt: t),
      ]);
      // Only the app's own dismissed timer is removed.
      expect(client.removed, ['d3']);
      // 'gone' (dismissed) and 'dropped' (no longer in mxclockd) are forgotten.
      expect(await savedIds(), {'run': 'd1', 'miss': 'd2'});
    });

    test('a failed removal of a dismissed timer is ignored', () async {
      await service.setTimer('gone', const Duration(minutes: 5));
      client.timers = [
        ClockdTimer(
          id: 'd1',
          label: '',
          endsAt: t,
          status: ClockdTimerStatus.dismissed,
        ),
      ];
      client.removeError = const ClockdRejected('E', 'no');
      final restored = await service.restoreTimers();
      expect(restored.running, isEmpty);
      expect(await savedIds(), isEmpty);
    });

    test('nothing when mxclockd can\'t be asked', () async {
      await service.setTimer('p1', const Duration(minutes: 5));
      client.listError = const ClockdUnavailable('', 'down');
      final restored = await service.restoreTimers();
      expect(restored.running, isEmpty);
      expect(restored.missed, isEmpty);
      expect(await savedIds(), {'p1': 'd1'});
    });

    test('MissedTimer equality', () {
      final a = MissedTimer(daemonId: 'x', label: 'l', endedAt: t);
      expect(a, MissedTimer(daemonId: 'x', label: 'l', endedAt: t));
      expect(
        a.hashCode,
        MissedTimer(daemonId: 'x', label: 'l', endedAt: t).hashCode,
      );
      expect(a == MissedTimer(daemonId: 'y', label: 'l', endedAt: t), isFalse);
    });
  });

  group('other', () {
    test('no sound path: preview plays nothing', () async {
      await service.playCompletionSound(sound: 'x');
      service.stopPreview();
    });

    test('a missing file is handed to a player (or none is found)', () async {
      final s = SystemAlarmService(
        client: client,
        soundPath: (_) => '/nonexistent/sound.ogg',
      );
      await s.playCompletionSound();
      s.stopPreview();
    });

    test('the time zone is never empty', () {
      expect(service.getTimezoneSync(), isNotEmpty);
    });
  });
}
