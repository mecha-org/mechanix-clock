# Changelog

All notable changes to the **Mechanix Clock** application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

## [1.1.0] - 2026-11-25

### Added

* **Alarm labels**: an alarm can be given a name (e.g. "Medicine"), shown in the list and in mxclockd's notification.
* **Snooze length**: each alarm picks how long Snooze waits (1, 5, 10, 15, 20 or 30 minutes; 10 by default).
* **Keyboard**: ↑/↓ move between rows in every list and Enter opens or picks the row; Ctrl+N adds an alarm on the Alarms tab; Space starts or stops the Stopwatch.  
* Restores the last selected tab on launch and displays a small indicator on the Stopwatch and Timer tabs while they are running.
* The stopwatch keeps counting while the app is closed and is picked up again, laps included, when it reopens.
* Clear messages when mxclockd isn't running, refuses a change, or is a version the app doesn't know: "Couldn't save alarm: …" and similar for switching, deleting and timers, and a Retry screen when the alarm list can't be loaded. The list reloads by itself when mxclockd starts.

### Changed

* **Alarms and timers run in mxclockd**: the alarm list, scheduling, ringing (notification with Snooze/Dismiss, looping sound, waking from suspend, blocking sleep while ringing) and timers now live in the `org.mechanix.services.Clock` daemon, so they work with the app closed. The app talks to it over D-Bus (`lib/core/services/clockd_client.dart`) and has no ringing screen of its own: the daemon's notification is how an alarm or timer is stopped or snoozed.
* Alarm sounds picked in the app are passed to the daemon as file paths. Timers ring with the daemon's sound: the Timer screen's sound picker is removed.
* **Sounds**: the four sounds are now CC0 sounds from Freesound, named after what they are: Digital beeps (default), Bedside alarm, Music box and Morning melody (were Dancing Flames, Comet on the go, Phoenix song and Wake up and party). Sources in `assets/sounds/README.md`.
* Alarms are listed by time of day (12 AM first); a new or edited alarm goes to its place instead of the bottom. Times show a two-digit hour (e.g. 07:05 AM).
* Only one alarm per time: an alarm set for the same time as another alarm that is switched on (whatever the repeat days) can't be saved; Save shows "An alarm already exists for this time" at the top, as Ubuntu's Clocks does. An alarm at that time that is off doesn't block it. Opening an alarm that clashes shows the message straight away, and switching such an alarm on in the list is refused with the same message.
* Saving an alarm switches it on.
* Running and paused timers are picked up again when the app restarts.

### Fixed

* **Snooze on/off now works**: it is sent to mxclockd, which rings an alarm with snooze off with Dismiss only.
* A timer that ended while the device or mxclockd was off never rang; it is no longer shown as running or restored (mxclockd keeps it as missed for the launcher). The timer list is also re-read when mxclockd restarts while the app is open.
* If mxclockd can't start or resume a timer, the timer it stopped to make way is shown paused instead of still counting down.
* Leaving the sound picker stops the sound preview straight away.

### Removed

* Alarms saved by 1.0.0 are not carried over: 1.1.0 is meant to be installed fresh.
* The `com.example.clock/alarm` method channel and its `systemd-run` alarm/timer jobs in the eLinux runner, the app's own `org.mechanix.clock` ring service, alarm notifications and full-screen ringing screen, and the "rang while closed" marker files.

## [1.0.0] - 2026-10-09

### Added

* **Alarm Management**: Create, edit, and toggle multiple alarms with repeat options (Once, Daily, Custom days), sound selection, snooze configuration, and swipe-to-delete with confirmation modal.
* **World Clock**: Search and add global cities across timezones with automatic timezone offset calculation, relative day indicators (Today, Tomorrow, Yesterday), time difference displays, and swipe-to-delete list items.
* **Stopwatch**: Elapsed time tracking with millisecond precision, start/stop/resume/reset controls, lap recording, and lap history table.
* **Timers & Presets**: Custom duration picker (hours, minutes, seconds), concurrent active timer support with pause/resume, swipe-to-delete presets, sound selection.
* **Mechanix UI & Theming**: Integrated Mechanix design system components (`MechanixSwipableList`, `MechanixSwipableListTile`, `MechanixAppBar`, `MechanixIconButton`, `MechanixFloatingActionButton`, `MechanixDivider`, `MechanixBottomSheet`), Geist and Geist Mono typography, and responsive layouts.
* **State Management & Persistence**: Reactive state management using the BLoC pattern (`flutter_bloc`) with local data persistence via `shared_preferences`.
* **Internationalization (i18n)**: Localized strings using Flutter `l10n` ARB specifications for all screens, dialogs, labels, and duration units.
