import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/utils/constants.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/data/repository/timer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late TimerRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = TimerRepository();
  });

  group('presets', () {
    test('defaults when nothing is saved', () async {
      expect(await repository.getPresets(), defaultTimerPresets);
    });

    test('saved presets are read back', () async {
      const presets = [
        TimerPreset(id: 'a', duration: Duration(minutes: 3), name: 'Tea'),
        TimerPreset(id: 'b', duration: Duration(seconds: 90)),
      ];
      await repository.savePresets(presets);
      expect(await repository.getPresets(), presets);
    });

    test('defaults when the saved value is broken', () async {
      SharedPreferences.setMockInitialValues({'timer_presets_list': 'nope'});
      expect(await repository.getPresets(), defaultTimerPresets);
    });

    test('copyWith keeps what is not given', () {
      const p = TimerPreset(id: 'a', duration: Duration(minutes: 1));
      expect(
        p.copyWith(name: 'x'),
        const TimerPreset(id: 'a', duration: Duration(minutes: 1), name: 'x'),
      );
      expect(p.copyWith(id: 'b', duration: Duration.zero).id, 'b');
    });
  });

  group('paused timers', () {
    const paused = PausedTimer(
      duration: Duration(minutes: 5),
      remaining: Duration(minutes: 2),
    );

    test('none saved', () async {
      expect(await repository.getPausedTimers(), isEmpty);
    });

    test('saved and read back', () async {
      await repository.savePausedTimers({'p1': paused});
      expect(await repository.getPausedTimers(), {'p1': paused});
    });

    test('saving none clears them', () async {
      await repository.savePausedTimers({'p1': paused});
      await repository.savePausedTimers({});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('timer_paused'), isNull);
    });

    test('a broken saved value reads as none', () async {
      SharedPreferences.setMockInitialValues({'timer_paused': '[1]'});
      expect(await repository.getPausedTimers(), isEmpty);
    });

    test('PausedTimer equality', () {
      expect(
        paused,
        const PausedTimer(
          duration: Duration(minutes: 5),
          remaining: Duration(minutes: 2),
        ),
      );
      expect(paused.hashCode, isNotNull);
      expect(
        paused ==
            const PausedTimer(
              duration: Duration(minutes: 5),
              remaining: Duration(minutes: 1),
            ),
        isFalse,
      );
    });
  });
}
