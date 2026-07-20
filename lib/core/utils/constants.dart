import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';

const List<TimerPreset> defaultTimerPresets = [
  TimerPreset(id: '1', duration: Duration(minutes: 1)),
  TimerPreset(id: '2', duration: Duration(minutes: 3)),
  TimerPreset(id: '3', duration: Duration(minutes: 5)),
  TimerPreset(id: '4', duration: Duration(minutes: 10)),
];

const List<String> sounds = [
  'Wakeup',
  'Siren',
  'Chasing Stars - Beyond the Horizon',
  'Dancing Flames (Urban Pulse)',
  'Silent Echo - Reflections of Time (Time mus...)',
  'Lost in Dreams - The Sound of Silence',
];
