# Mechanix Clock

A modern, functional clock app built with Flutter Elinux for Mechanix OS. It features a clean UI, alarm management, and a stopwatch.

## ✨ Features

- **Alarm**: Set, edit, and manage multiple alarms with custom sounds.
- **Stopwatch**: Track elapsed time with lap support.
- **World Clock**: Search and add global cities across timezones.
- **Timers & Presets**: Custom duration picker (hours, minutes, seconds), concurrent active timer support with pause/resume, swipe-to-delete presets, sound selection.
- **Modern UI**: Clean and intuitive interface designed for Mechanix OS.
- **Localization**: Support for English (default) and extensible to other languages.

## ⏰ Alarms and timers: mxclockd

Alarms and timers are kept, scheduled and rung by
[mxclockd](https://github.com/mineshp-mecha/mxclockd), a session-bus daemon
(`org.mechanix.services.Clock`). The app is one of its clients:

- the alarm list lives in the daemon (`ListAlarms`, `AddAlarm`, `UpdateAlarm`,
  `RemoveAlarm`, `SetAlarmEnabled`) and reloads on `AlarmsChanged`;
- timers are started with `AddTimer` and stopped with `RemoveTimer`; they ring
  with the daemon's sound (the Timer screen has no sound picker). `ListTimers`
  gives each timer's status: running ones come back after a restart; missed
  ones (ended while the device or daemon was off, never rang) are not shown
  by the app and are left in mxclockd for the launcher;
- ringing is entirely the daemon's: it shows the notification
  (Snooze/Dismiss), plays the sound, wakes the device from suspend and keeps
  it awake. The app has no ringing screen of its own.

See `lib/core/services/clockd_client.dart`. Alarms saved by older versions
(shared preferences) are moved into the daemon on first start. The alarm
editor's Snooze on/off is passed to the daemon: an alarm with snooze off rings with
Dismiss only.

## 🚀 Getting Started

### Prerequisites

- [Flutter-Elinux SDK](https://github.com/flutter-elinux/flutter-elinux)
- [Dart SDK](https://dart.dev/get-dart)
- mxclockd installed (its systemd user unit and D-Bus activation file), or
  running with `cargo run` from its repository

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/mecha-org/mechanix-clock
   ```

2. Navigate to the project directory:

   ```bash
   cd mechanix-clock
   ```

3. Get dependencies:

   ```bash
   flutter-elinux pub get
   ```

### Running the App

To run the app on your connected device or emulator:

```bash
flutter-elinux run
```

## 🧪 Testing

### Unit Tests

To run unit tests:

```bash
flutter-elinux test
```

### Integration Tests

Integration tests use the real mxclockd on the session bus; run a throwaway
one so your own alarms aren't touched (see `integration_test/app_test.dart`).
To run integration tests:

```bash
flutter-elinux test integration_test/app_test.dart -d linux
```

## 🛠 Tech Stack

- **Framework**: [flutter-elinux](https://github.com/flutter-elinux/flutter-elinux)
- **State Management**: [Bloc (flutter_bloc)](https://pub.dev/packages/flutter_bloc)
- **Data Persistence**: [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Localization**: [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html)

## 📝 TODOs

1. Load alarm sound list on dir: `/usr/share/alarm/alsa/Front_Center.wav`
