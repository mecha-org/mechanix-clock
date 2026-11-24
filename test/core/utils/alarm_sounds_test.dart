import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/utils/alarm_sounds.dart';

void main() {
  group('alarmSoundFor', () {
    test('finds a sound by id', () {
      expect(alarmSoundFor('music_box').label, 'Music box');
    });

    test('falls back to the default sound', () {
      expect(alarmSoundFor(null), defaultAlarmSound);
      expect(alarmSoundFor('Default'), defaultAlarmSound);
    });

    test('every sound has an asset file', () {
      for (final sound in alarmSounds) {
        expect(
          File('assets/sounds/${sound.fileName}').existsSync(),
          isTrue,
          reason: sound.fileName,
        );
      }
    });
  });

  group('alarmSoundPath', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('alarm_sounds_test_');
    });

    tearDown(() => dir.delete(recursive: true));

    test('prefers the installed copy', () {
      final system = Directory('${dir.path}/system')..createSync();
      File('${system.path}/bedside_alarm.ogg').writeAsBytesSync([0]);

      expect(
        alarmSoundPath(
          'bedside_alarm',
          systemDirectory: system.path,
          executablePath: '${dir.path}/bundle/mechanix_clock',
        ),
        '${system.path}/bedside_alarm.ogg',
      );
    });

    test('uses the bundle copy when not installed', () {
      final assets = Directory(
        '${dir.path}/bundle/data/flutter_assets/assets/sounds',
      )..createSync(recursive: true);
      File('${assets.path}/digital_beeps.ogg').writeAsBytesSync([0]);

      expect(
        alarmSoundPath(
          'Digital beeps',
          systemDirectory: '${dir.path}/missing',
          executablePath: '${dir.path}/bundle/mechanix_clock',
        ),
        '${assets.path}/digital_beeps.ogg',
      );
    });

    test('is null when the file is nowhere', () {
      expect(
        alarmSoundPath(
          'music_box',
          systemDirectory: '${dir.path}/missing',
          executablePath: '${dir.path}/bundle/mechanix_clock',
        ),
        isNull,
      );
    });
  });
}
