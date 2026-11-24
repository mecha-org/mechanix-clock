import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/utils/alarm_sounds.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';
import 'package:mechanix_clock/core/widgets/keyboard_list.dart';
import 'package:widgets/widgets.dart';

/// Lists the alarm sounds; picking one plays a preview and the check
/// button returns its id. Leaving the screen stops the preview.
class SoundSelectionScreen extends StatefulWidget {
  /// The current sound's id (an older saved label also works).
  final String initialSound;

  /// Plays a preview of a sound id; defaults to [SystemAlarmService].
  final ValueChanged<String>? onPreview;

  /// Stops the preview; defaults to [SystemAlarmService].
  final VoidCallback? onStopPreview;

  const SoundSelectionScreen({
    super.key,
    required this.initialSound,
    this.onPreview,
    this.onStopPreview,
  });

  @override
  State<SoundSelectionScreen> createState() => _SoundSelectionScreenState();
}

class _SoundSelectionScreenState extends State<SoundSelectionScreen> {
  late String _selectedSound;
  late final ValueChanged<String> _preview;
  late final VoidCallback _stopPreview;

  @override
  void initState() {
    super.initState();
    _selectedSound = alarmSoundFor(widget.initialSound).id;
    final service = SystemAlarmService();
    _preview =
        widget.onPreview ?? (id) => service.playCompletionSound(sound: id);
    _stopPreview = widget.onStopPreview ?? service.stopPreview;
  }

  @override
  void dispose() {
    _stopPreview();
    super.dispose();
  }

  void _select(String id) {
    setState(() => _selectedSound = id);
    _preview(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        primary: false,
        backgroundColor: Colors.transparent,
        leading: MechanixIconButton.standard(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          MechanixIconButton.standard(
            key: const Key('sound_done_button'),
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _selectedSound),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ↑/↓ move between sounds, Enter picks (and plays) one.
      body: KeyboardList(
        autofocus: true,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: alarmSounds.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MechanixDivider(),
          ),
          itemBuilder: (context, index) {
            final sound = alarmSounds[index];

            return KeyboardListItem(
              index: index,
              onActivate: () => _select(sound.id),
              child: MechanixListTile(
                key: Key('sound_${sound.id}'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leadingWidgets: [
                  MechanixRadio<String>(
                    value: sound.id,
                    groupValue: _selectedSound,
                    onChanged: (val) {
                      if (val != null) _select(val);
                    },
                  ),
                ],
                labelText: sound.label,
                onTap: () => _select(sound.id),
              ),
            );
          },
        ),
      ),
    );
  }
}
