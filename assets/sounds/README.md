# Alarm and timer sounds

One file per entry in `lib/core/utils/alarm_sounds.dart`, named `<id>.ogg`.
Ids are named after what the sound is. Alarms saved in mxclockd refer to the
installed path, so renaming a released sound needs those alarms moved to the
new file (mxclockd rings its default sound for a file it can't read).

- Format: Ogg Vorbis, mono, 44.1 kHz, a few seconds long and cut on a pause so
  it loops cleanly (mxclockd repeats it while ringing). Peak about -1 dBFS.
- Installed to `/usr/share/sounds/mechanix/clock/` by the package; when the app
  runs from a build, the copy in the bundle's `flutter_assets` is used.
- Use sounds the project owns or that are CC0/royalty-free, and note the source
  here.

## Sources

All from [Freesound](https://freesound.org), licensed
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (public domain;
no attribution required, listed for reference). Each is the Freesound preview,
trimmed, mixed to mono and normalized.

| File | Label | Freesound sound | Uploader | Cut used |
| --- | --- | --- | --- | --- |
| `digital_beeps.ogg` | Digital beeps | [Alarm clock beeping (digital, 20 seconds)](https://freesound.org/people/SupaSoundsEffects/sounds/873787/) (#873787) | SupaSoundsEffects | first 4 beeps, 0–3.85 s |
| `bedside_alarm.ogg` | Bedside alarm | [Bedside clock alarm.wav](https://freesound.org/people/Chelly01/sounds/541077/) (#541077) | Chelly01 | 4 beeps, 0.25–4.25 s |
| `music_box.ogg` | Music box | [Music Box Melody 1](https://freesound.org/people/DRFX/sounds/338986/) (#338986) | DRFX | one pass of the melody, 0–8 s (the file plays it twice) |
| `morning_melody.ogg` | Morning melody | [Mixolydian Ringtone](https://freesound.org/people/morkysound/sounds/512676/) (#512676) | morkysound | whole ringtone, 0.35–14.05 s |
