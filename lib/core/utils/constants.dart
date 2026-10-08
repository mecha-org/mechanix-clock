import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';

const List<TimerPreset> defaultTimerPresets = [
  TimerPreset(id: '1', duration: Duration(minutes: 1)),
  TimerPreset(id: '2', duration: Duration(minutes: 5)),
  TimerPreset(id: '3', duration: Duration(minutes: 10)),
  TimerPreset(id: '4', duration: Duration(minutes: 30)),
];

const List<String> sounds = [
  'Dancing Flames',
  'Comet on the go',
  'Phoenix song',
  'Wake up and party',
];
