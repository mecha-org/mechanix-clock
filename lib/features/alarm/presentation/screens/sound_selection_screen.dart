import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/utils/constants.dart';
import 'package:widgets/widgets.dart';

class SoundSelectionScreen extends StatefulWidget {
  final String initialSound;
  const SoundSelectionScreen({super.key, required this.initialSound});

  @override
  State<SoundSelectionScreen> createState() => _SoundSelectionScreenState();
}

class _SoundSelectionScreenState extends State<SoundSelectionScreen> {
  late String _selectedSound;

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.initialSound;
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
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: sounds.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MechanixDivider(
            color: theme.colorScheme.outline.withValues(alpha: 0.38),
          ),
        ),
        itemBuilder: (context, index) {
          final sound = sounds[index];

          return MechanixListTile(
            key: Key('sound_$sound'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: MechanixRadio<String>(
              value: sound,
              groupValue: _selectedSound,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSound = val);
                }
              },
            ),
            labelText: sound,
            onTap: () {
              setState(() => _selectedSound = sound);
            },
          );
        },
      ),
    );
  }
}
