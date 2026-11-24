import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/alarm/data/utils/date_time_utils.dart';
import 'package:mechanix_clock/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  group('alarmSetFor', () {
    String setFor(Duration d) => DateTimeUtils.alarmSetFor(l10n, d);

    test('under a minute', () {
      expect(
        setFor(const Duration(seconds: 30)),
        'Alarm set for less than a minute from now',
      );
    });

    test('one part, singular and plural', () {
      expect(
        setFor(const Duration(minutes: 1)),
        'Alarm set for 1 minute from now',
      );
      expect(
        setFor(const Duration(minutes: 4, seconds: 10)),
        'Alarm set for 5 minutes from now',
      );
      expect(
        setFor(const Duration(hours: 2)),
        'Alarm set for 2 hours from now',
      );
    });

    test('two parts are joined with "and"', () {
      expect(
        setFor(const Duration(days: 3, minutes: 5)),
        'Alarm set for 3 days and 5 minutes from now',
      );
    });

    test('three parts', () {
      expect(
        setFor(const Duration(days: 1, hours: 2, minutes: 5)),
        'Alarm set for 1 day, 2 hours and 5 minutes from now',
      );
    });
  });
}
