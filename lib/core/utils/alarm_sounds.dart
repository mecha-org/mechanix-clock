import 'dart:io';

/// An alarm sound: [id] is saved and names the file `<id>.ogg`; [label] is
/// shown to the user.
class AlarmSound {
  final String id;
  final String label;

  const AlarmSound(this.id, this.label);

  String get fileName => '$id.ogg';
}

/// Sounds shipped in `assets/sounds/` (CC0, from Freesound; see its README).
const List<AlarmSound> alarmSounds = [
  AlarmSound('digital_beeps', 'Digital beeps'),
  AlarmSound('bedside_alarm', 'Bedside alarm'),
  AlarmSound('music_box', 'Music box'),
  AlarmSound('morning_melody', 'Morning melody'),
];

const AlarmSound defaultAlarmSound = AlarmSound(
  'digital_beeps',
  'Digital beeps',
);

/// Where the package installs the sounds (see packaging/nfpm/nfpm.yaml).
const String systemSoundsDirectory = '/usr/share/sounds/mechanix/clock';

/// The sound with [id]; anything else gives the default.
AlarmSound alarmSoundFor(String? id) {
  for (final sound in alarmSounds) {
    if (sound.id == id) return sound;
  }
  return defaultAlarmSound;
}

/// The file for [id], or null if missing: the installed copy in
/// [systemSoundsDirectory] (readable by mxclockd), else the build's
/// `flutter_assets` copy.
String? alarmSoundPath(
  String? id, {
  String systemDirectory = systemSoundsDirectory,
  String? executablePath,
}) {
  final fileName = alarmSoundFor(id).fileName;
  final executable = File(executablePath ?? Platform.resolvedExecutable);
  final candidates = [
    '$systemDirectory/$fileName',
    '${executable.parent.path}/data/flutter_assets/assets/sounds/$fileName',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}
