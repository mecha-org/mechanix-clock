import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';

void main() {
  group('AlarmModel', () {
    const testAlarm = Alarm(
      id: '1',
      hour: 7,
      minute: 15,
      isAm: true,
      repeatDays: [0, 1],
      sound: 'digital_beeps',
      isSnoozeEnabled: true,
      isActive: true,
    );

    test('should support value equality', () {
      expect(
        testAlarm,
        const Alarm(
          id: '1',
          hour: 7,
          minute: 15,
          isAm: true,
          repeatDays: [0, 1],
          sound: 'digital_beeps',
          isSnoozeEnabled: true,
          isActive: true,
        ),
      );
    });

    test('copyWith works correctly', () {
      final updatedAlarm = testAlarm.copyWith(hour: 8, isActive: false);
      expect(updatedAlarm.hour, 8);
      expect(updatedAlarm.isActive, false);
      expect(updatedAlarm.id, testAlarm.id);
      expect(updatedAlarm.minute, testAlarm.minute);
    });

    test('description shows the time and the label', () {
      expect(testAlarm.description, '07:15 AM');
      expect(
        testAlarm.copyWith(label: ' Medicine ', isAm: false).description,
        '07:15 PM · Medicine',
      );
    });

    group('nextRing', () {
      // Wednesday 2026-11-11, 08:00.
      final now = DateTime(2026, 11, 11, 8);

      test('one-time alarm later today rings today', () {
        final alarm = testAlarm.copyWith(hour: 9, minute: 30, repeatDays: []);
        expect(alarm.nextRing(now), DateTime(2026, 11, 11, 9, 30));
      });

      test('one-time alarm already past today rings tomorrow', () {
        final alarm = testAlarm.copyWith(hour: 7, minute: 0, repeatDays: []);
        expect(alarm.nextRing(now), DateTime(2026, 11, 12, 7));
      });

      test('PM and 12 AM/PM are converted to 24-hour time', () {
        expect(
          testAlarm
              .copyWith(hour: 7, isAm: false, repeatDays: [])
              .nextRing(now),
          DateTime(2026, 11, 11, 19, 15),
        );
        expect(
          testAlarm
              .copyWith(hour: 12, minute: 0, isAm: true, repeatDays: [])
              .nextRing(now),
          DateTime(2026, 11, 12, 0),
        );
        expect(
          testAlarm
              .copyWith(hour: 12, minute: 0, isAm: false, repeatDays: [])
              .nextRing(now),
          DateTime(2026, 11, 11, 12),
        );
      });

      test('repeat days are Sunday-first', () {
        // 0 = Sunday: the next Sunday is 2026-11-15.
        final alarm = testAlarm.copyWith(hour: 7, minute: 0, repeatDays: [0]);
        expect(alarm.nextRing(now), DateTime(2026, 11, 15, 7));
      });

      test('a repeating alarm later today rings today', () {
        // 3 = Wednesday.
        final alarm = testAlarm.copyWith(hour: 9, minute: 0, repeatDays: [3]);
        expect(alarm.nextRing(now), DateTime(2026, 11, 11, 9));
      });

      test('a repeating alarm past today rings next week', () {
        final alarm = testAlarm.copyWith(hour: 7, minute: 0, repeatDays: [3]);
        expect(alarm.nextRing(now), DateTime(2026, 11, 18, 7));
      });
    });
  });

  group('alarmTimeTaken', () {
    const a = Alarm(
      id: 'a',
      hour: 4,
      minute: 27,
      isAm: false,
      repeatDays: [3],
      sound: 'digital_beeps',
      isSnoozeEnabled: true,
    );

    bool taken(List<Alarm> alarms, {String? except}) => alarmTimeTaken(
      alarms,
      hour: 4,
      minute: 27,
      isAm: false,
      exceptId: except,
    );

    test('an alarm that is on at that time takes it, whatever its days', () {
      expect(taken([a]), isTrue);
      expect(taken([a.copyWith(repeatDays: [])]), isTrue);
    });

    test('an alarm that is off, or the one excepted, does not', () {
      expect(taken([a.copyWith(isActive: false)]), isFalse);
      expect(taken([a], except: 'a'), isFalse);
    });

    test('another minute or AM/PM does not', () {
      expect(taken([a.copyWith(minute: 28)]), isFalse);
      expect(taken([a.copyWith(isAm: true)]), isFalse);
    });
  });
}
