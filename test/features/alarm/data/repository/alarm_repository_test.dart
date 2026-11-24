import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/features/alarm/data/repository/alarm_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockClockdClient extends Mock implements ClockdClient {}

void main() {
  late MockClockdClient client;
  late AlarmRepository repository;

  const alarm = Alarm(
    id: 'old-1',
    hour: 7,
    minute: 30,
    isAm: false, // 19:30
    repeatDays: [1, 2, 5], // Mon, Tue, Fri
    sound: 'music_box',
    isSnoozeEnabled: false,
    label: 'Gym',
    snoozeMinutes: 15,
  );

  const daemonAlarm = ClockdAlarm(
    id: 'uuid-1',
    label: 'Gym',
    hour: 19,
    minute: 30,
    days: 1 | 2 | 16,
    enabled: true,
    sound: '/usr/share/sounds/mechanix/clock/music_box.ogg',
    ringMinutes: 5,
    snoozeEnabled: false,
    snoozeMinutes: 15,
  );

  void stubAdd([String id = 'uuid-1']) => when(
    () => client.addAlarm(
      label: any(named: 'label'),
      hour: any(named: 'hour'),
      minute: any(named: 'minute'),
      days: any(named: 'days'),
      sound: any(named: 'sound'),
      ringMinutes: any(named: 'ringMinutes'),
      snoozeEnabled: any(named: 'snoozeEnabled'),
      snoozeMinutes: any(named: 'snoozeMinutes'),
    ),
  ).thenAnswer((_) async => id);

  setUp(() {
    client = MockClockdClient();
    repository = AlarmRepository(
      client: client,
      soundPath: (id) => '/usr/share/sounds/mechanix/clock/$id.ogg',
    );
  });

  group('conversions', () {
    test('repeat days map Sunday-first to the Monday-bit-0 mask', () {
      expect(AlarmRepository.maskFromDays([1, 2, 3, 4, 5]), 31);
      expect(AlarmRepository.maskFromDays([0]), 64);
      expect(AlarmRepository.maskFromDays([]), 0);
      expect(AlarmRepository.daysFromMask(31), [1, 2, 3, 4, 5]);
      expect(AlarmRepository.daysFromMask(127), [0, 1, 2, 3, 4, 5, 6]);
    });

    test('12-hour time maps to 24-hour and back', () {
      Alarm at(int h, bool am) => alarm.copyWith(hour: h, isAm: am);
      expect(AlarmRepository.hour24(at(12, true)), 0);
      expect(AlarmRepository.hour24(at(12, false)), 12);
      expect(AlarmRepository.hour24(at(7, false)), 19);

      final back = AlarmRepository.fromClockd(daemonAlarm);
      expect((back.hour, back.isAm), (7, false));
      final midnight = AlarmRepository.fromClockd(
        const ClockdAlarm(
          id: 'm',
          label: '',
          hour: 0,
          minute: 0,
          days: 0,
          enabled: true,
          sound: '',
          ringMinutes: 5,
          snoozeMinutes: 5,
        ),
      );
      expect((midnight.hour, midnight.isAm), (12, true));
    });

    test('sound path maps back to the sound id', () {
      expect(AlarmRepository.fromClockd(daemonAlarm).sound, 'music_box');
    });
  });

  test('addAlarm sends the daemon form, snooze off included', () async {
    stubAdd();
    final added = await repository.addAlarm(alarm);

    expect(added.id, 'uuid-1');
    verify(
      () => client.addAlarm(
        label: 'Gym',
        hour: 19,
        minute: 30,
        days: 19,
        sound: '/usr/share/sounds/mechanix/clock/music_box.ogg',
        ringMinutes: 5,
        snoozeEnabled: false,
        snoozeMinutes: 15,
      ),
    ).called(1);
    verifyNever(() => client.setAlarmEnabled(any(), any()));

    when(() => client.listAlarms()).thenAnswer((_) async => [daemonAlarm]);
    final listed = await repository.getAlarms();
    expect(listed.single.isSnoozeEnabled, isFalse);
    expect(listed.single.repeatDays, [1, 2, 5]);
  });

  test(
    'saving an alarm that is off switches it on, as mxclockd does',
    () async {
      stubAdd();
      final added = await repository.addAlarm(alarm.copyWith(isActive: false));

      expect(added.isActive, isTrue);
      verifyNever(() => client.setAlarmEnabled(any(), any()));
    },
  );

  test('delete and switch on/off go straight to mxclockd', () async {
    when(() => client.removeAlarm(any())).thenAnswer((_) async {});
    when(() => client.setAlarmEnabled(any(), any())).thenAnswer((_) async {});

    await repository.deleteAlarm('uuid-1');
    await repository.setAlarmEnabled('uuid-2', false);

    verify(() => client.removeAlarm('uuid-1')).called(1);
    verify(() => client.setAlarmEnabled('uuid-2', false)).called(1);
  });
}
