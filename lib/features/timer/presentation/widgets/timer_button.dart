import 'package:flutter/material.dart';

class TimerButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const TimerButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 180,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: enabled
                ? const Color(0xFF474747)
                : const Color(0xFF474747).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            height: 1.2,
            color: enabled
                ? const Color(0xFFADADAD)
                : const Color(0xFFADADAD).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
