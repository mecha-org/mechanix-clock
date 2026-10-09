# Mechanix Clock

A modern, functional clock app built with Flutter Elinux for Mechanix OS. It features a clean UI, alarm management, and a stopwatch.

## ✨ Features

- **Alarm**: Set, edit, and manage multiple alarms with custom sounds.
- **Stopwatch**: Track elapsed time with lap support.
- **World Clock**: Search and add global cities across timezones.
- **Timers & Presets**: Custom duration picker (hours, minutes, seconds), concurrent active timer support with pause/resume, swipe-to-delete presets, sound selection.
- **Modern UI**: Clean and intuitive interface designed for Mechanix OS.
- **Localization**: Support for English (default) and extensible to other languages.

## 🚀 Getting Started

### Prerequisites

- [Flutter-Elinux SDK](https://github.com/flutter-elinux/flutter-elinux)
- [Dart SDK](https://dart.dev/get-dart)

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
