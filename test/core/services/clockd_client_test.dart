import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';

/// Stands in for mxclockd on a private in-process bus.
class FakeClockd extends DBusObject {
  FakeClockd() : super(DBusObjectPath(ClockdClient.objectPath));

  /// Arguments of the last call to each method.
  final calls = <String, List<DBusValue>>{};

  /// Replaces the reply to the next call.
  DBusMethodResponse? nextReply;

  List<DBusValue> alarms = [];
  List<DBusValue> timers = [];

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    if (call.interface != ClockdClient.interface) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    calls[call.name] = call.values;
    final reply = nextReply;
    if (reply != null) {
      nextReply = null;
      return reply;
    }
    return switch (call.name) {
      'ListAlarms' => DBusMethodSuccessResponse([
        DBusArray(DBusSignature('(ssyyybsubu)'), alarms),
      ]),
      'ListTimers' => DBusMethodSuccessResponse([
        DBusArray(DBusSignature('(ssxs)'), timers),
      ]),
      'AddAlarm' => DBusMethodSuccessResponse([const DBusString('alarm-1')]),
      'AddTimer' => DBusMethodSuccessResponse([const DBusString('timer-1')]),
      'UpdateAlarm' ||
      'RemoveAlarm' ||
      'SetAlarmEnabled' ||
      'RemoveTimer' => DBusMethodSuccessResponse(),
      _ => DBusMethodErrorResponse.unknownMethod(),
    };
  }
}

DBusStruct timer(String id, String status) => DBusStruct([
  DBusString(id),
  const DBusString('5 min'),
  const DBusInt64(1800000000),
  DBusString(status),
]);

void main() {
  late DBusServer server;
  late DBusAddress address;
  late DBusClient daemonBus;
  late FakeClockd fake;
  late ClockdClient client;

  setUp(() async {
    server = DBusServer();
    address = await server.listenAddress(
      DBusAddress.unix(dir: Directory.systemTemp),
    );
    daemonBus = DBusClient(address);
    fake = FakeClockd();
    await daemonBus.registerObject(fake);
    await daemonBus.requestName(ClockdClient.busName);
    client = ClockdClient(clientFactory: () => DBusClient(address));
  });

  tearDown(() async {
    await client.dispose();
    await daemonBus.close();
    await server.close();
  });

  group('alarms', () {
    test('ListAlarms is read into ClockdAlarm', () async {
      fake.alarms = [
        DBusStruct([
          const DBusString('a1'),
          const DBusString('Gym'),
          const DBusByte(7),
          const DBusByte(30),
          const DBusByte(31),
          const DBusBoolean(true),
          const DBusString('/s/digital_beeps.ogg'),
          const DBusUint32(5),
          const DBusBoolean(false),
          const DBusUint32(10),
        ]),
      ];
      final alarm = (await client.listAlarms()).single;
      expect(alarm.id, 'a1');
      expect(alarm.label, 'Gym');
      expect((alarm.hour, alarm.minute, alarm.days), (7, 30, 31));
      expect(alarm.enabled, isTrue);
      expect(alarm.sound, '/s/digital_beeps.ogg');
      expect(alarm.ringMinutes, 5);
      expect(alarm.snoozeEnabled, isFalse);
      expect(alarm.snoozeMinutes, 10);
    });

    test('AddAlarm sends the fields in order and returns the id', () async {
      final id = await client.addAlarm(
        label: 'Gym',
        hour: 7,
        minute: 30,
        days: 31,
        sound: '/s.ogg',
        ringMinutes: 5,
        snoozeEnabled: false,
        snoozeMinutes: 10,
      );
      expect(id, 'alarm-1');
      expect(fake.calls['AddAlarm'], [
        const DBusString('Gym'),
        const DBusByte(7),
        const DBusByte(30),
        const DBusByte(31),
        const DBusString('/s.ogg'),
        const DBusUint32(5),
        const DBusBoolean(false),
        const DBusUint32(10),
      ]);
    });

    test('UpdateAlarm, RemoveAlarm and SetAlarmEnabled send the id', () async {
      await client.updateAlarm(
        'a1',
        label: '',
        hour: 6,
        minute: 0,
        days: 0,
        sound: '',
        ringMinutes: 5,
        snoozeEnabled: true,
        snoozeMinutes: 5,
      );
      expect(fake.calls['UpdateAlarm']!.first, const DBusString('a1'));
      expect(fake.calls['UpdateAlarm'], hasLength(9));

      await client.removeAlarm('a1');
      expect(fake.calls['RemoveAlarm'], [const DBusString('a1')]);

      await client.setAlarmEnabled('a1', false);
      expect(fake.calls['SetAlarmEnabled'], [
        const DBusString('a1'),
        const DBusBoolean(false),
      ]);
    });
  });

  group('timers', () {
    test('AddTimer rounds up to whole seconds (at least 1)', () async {
      expect(
        await client.addTimer(const Duration(milliseconds: 1500), label: 'x'),
        'timer-1',
      );
      expect(fake.calls['AddTimer'], [
        const DBusUint32(2),
        const DBusString('x'),
      ]);
      await client.addTimer(Duration.zero);
      expect(fake.calls['AddTimer']!.first, const DBusUint32(1));
    });

    test('ListTimers reads the status', () async {
      fake.timers = [
        timer('t1', 'running'),
        timer('t2', 'missed'),
        timer('t3', 'dismissed'),
        timer('t4', 'something-new'),
      ];
      final timers = await client.listTimers();
      expect(timers.map((t) => t.status).toList(), [
        ClockdTimerStatus.running,
        ClockdTimerStatus.missed,
        ClockdTimerStatus.dismissed,
        ClockdTimerStatus.running,
      ]);
      expect(timers.first.label, '5 min');
      expect(
        timers.first.endsAt,
        DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000),
      );
    });

    test('RemoveTimer sends the id', () async {
      await client.removeTimer('t1');
      expect(fake.calls['RemoveTimer'], [const DBusString('t1')]);
    });
  });

  group('failures', () {
    test('an error from mxclockd is ClockdRejected with its reason', () async {
      fake.nextReply = DBusMethodErrorResponse(
        'org.freedesktop.DBus.Error.InvalidArgs',
        [const DBusString("can't read sound")],
      );
      await expectLater(
        client.removeAlarm('a1'),
        throwsA(
          isA<ClockdRejected>()
              .having((e) => e.message, 'message', "can't read sound")
              .having(
                (e) => e.errorName,
                'errorName',
                'org.freedesktop.DBus.Error.InvalidArgs',
              ),
        ),
      );
    });

    test('a reply in another format is a version mismatch', () async {
      fake.nextReply = DBusMethodSuccessResponse([
        DBusArray(DBusSignature('(ssx)'), []),
      ]);
      await expectLater(
        client.listTimers(),
        throwsA(
          isA<ClockdRejected>().having(
            (e) => e.errorName,
            'errorName',
            ClockdClient.versionMismatch,
          ),
        ),
      );
    });

    test('no mxclockd on the bus is ClockdUnavailable', () async {
      await daemonBus.releaseName(ClockdClient.busName);
      await expectLater(client.listAlarms(), throwsA(isA<ClockdUnavailable>()));
    });

    test('classify: bus errors meaning "nobody answered" are unavailable', () {
      for (final name in [
        'org.freedesktop.DBus.Error.ServiceUnknown',
        'org.freedesktop.DBus.Error.NoReply',
        'org.freedesktop.DBus.Error.Spawn.ChildExited',
      ]) {
        expect(ClockdClient.classify(name, ''), isA<ClockdUnavailable>());
      }
      expect(
        ClockdClient.classify('org.freedesktop.DBus.Error.Failed', 'x'),
        isA<ClockdRejected>(),
      );
      expect(
        const ClockdRejected('E', 'why').toString(),
        'ClockdRejected(E): why',
      );
    });
  });

  group('signals', () {
    test('AlarmsChanged reaches alarmsChanged', () async {
      client.start();
      final changed = client.alarmsChanged.first;
      // Give the match rule and name lookup time to reach the bus.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await fake.emitSignal(ClockdClient.interface, 'AlarmsChanged');
      await changed.timeout(const Duration(seconds: 2));
    });

    test('mxclockd taking its name again fires started', () async {
      client.start();
      final started = client.started.first;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await daemonBus.releaseName(ClockdClient.busName);
      await daemonBus.requestName(ClockdClient.busName);
      await started.timeout(const Duration(seconds: 2));
    });
  });
}
