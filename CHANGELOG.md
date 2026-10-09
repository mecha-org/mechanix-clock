# Changelog

All notable changes to the **Mechanix Clock** application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-09

### Added

* **Alarm Management**: Create, edit, and toggle multiple alarms with repeat options (Once, Daily, Custom days), sound selection, snooze configuration, and swipe-to-delete with confirmation modal.
* **World Clock**: Search and add global cities across timezones with automatic timezone offset calculation, relative day indicators (Today, Tomorrow, Yesterday), time difference displays, and swipe-to-delete list items.
* **Stopwatch**: Elapsed time tracking with millisecond precision, start/stop/resume/reset controls, lap recording, and lap history table.
* **Timers & Presets**: Custom duration picker (hours, minutes, seconds), concurrent active timer support with pause/resume, swipe-to-delete presets, sound selection.
* **Mechanix UI & Theming**: Integrated Mechanix design system components (`MechanixSwipableList`, `MechanixSwipableListTile`, `MechanixAppBar`, `MechanixIconButton`, `MechanixFloatingActionButton`, `MechanixDivider`, `MechanixBottomSheet`), Geist and Geist Mono typography, and responsive layouts.
* **State Management & Persistence**: Reactive state management using the BLoC pattern (`flutter_bloc`) with local data persistence via `shared_preferences`.
* **Internationalization (i18n)**: Localized strings using Flutter `l10n` ARB specifications for all screens, dialogs, labels, and duration units.
