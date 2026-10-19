import 'package:flutter/material.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class AmPmSwitch extends StatelessWidget {
  const AmPmSwitch({super.key, required this.isAm, required this.onChanged});

  final bool isAm;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AmPmSegment(
            key: const Key('am_segment'),
            label: l10n.am,
            isSelected: isAm,
            onTap: () => onChanged(true),
          ),
          _AmPmSegment(
            key: const Key('pm_segment'),
            label: l10n.pm,
            isSelected: !isAm,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _AmPmSegment extends StatefulWidget {
  const _AmPmSegment({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_AmPmSegment> createState() => _AmPmSegmentState();
}

class _AmPmSegmentState extends State<_AmPmSegment> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color baseBg = widget.isSelected
        ? colorScheme.surfaceContainerLow
        : Colors.transparent;

    Color effectiveBg = baseBg;
    if (_isPressed) {
      effectiveBg = Color.alphaBlend(
        colorScheme.onSurface.withValues(alpha: 0.12),
        baseBg,
      );
    } else if (_isHovered) {
      effectiveBg = Color.alphaBlend(
        colorScheme.onSurface.withValues(alpha: 0.08),
        baseBg,
      );
    }

    final Color borderColor = widget.isSelected
        ? Colors.transparent
        : colorScheme.outline;

    final Color textColor = widget.isSelected
        ? colorScheme.primary
        : colorScheme.onSecondaryFixed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 26),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: borderColor, width: 1.0),
            borderRadius: BorderRadius.circular(100),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: theme.textTheme.titleMedium!.copyWith(color: textColor),
            child: Text(widget.label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
