import 'package:flutter/material.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class AmPmSwitch extends StatelessWidget {
  const AmPmSwitch({super.key, required this.isAm, required this.onChanged});

  final bool isAm;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final activeColor = colorScheme.onSecondary;
    final inactiveColor = colorScheme.onSecondaryContainer;
    final segmentBgColor = colorScheme.secondaryContainer;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AmPmSegment(
            label: l10n.am,
            isSelected: isAm,
            onTap: () => onChanged(true),
            backgroundColor: segmentBgColor,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
          _AmPmSegment(
            label: l10n.pm,
            isSelected: !isAm,
            onTap: () => onChanged(false),
            backgroundColor: segmentBgColor,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
        ],
      ),
    );
  }
}

class _AmPmSegment extends StatefulWidget {
  const _AmPmSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.backgroundColor,
    required this.activeColor,
    required this.inactiveColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  @override
  State<_AmPmSegment> createState() => _AmPmSegmentState();
}

class _AmPmSegmentState extends State<_AmPmSegment> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color effectiveBg = widget.backgroundColor;

    if (_isPressed) {
      effectiveBg = Color.alphaBlend(
        theme.colorScheme.onSurface.withValues(alpha: 0.12),
        widget.backgroundColor,
      );
    } else if (_isHovered) {
      effectiveBg = Color.alphaBlend(
        theme.colorScheme.onSurface.withValues(alpha: 0.08),
        widget.backgroundColor,
      );
    }

    final textColor = widget.isSelected
        ? widget.activeColor
        : widget.inactiveColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: effectiveBg,
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
