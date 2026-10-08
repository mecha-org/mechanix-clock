import 'package:flutter/material.dart';

/// A custom day bubble widget representing a single day of the week,
/// supporting selected and unselected visual states based on the design system.
class DayBubble extends StatelessWidget {
  /// The label to display inside the bubble (e.g. 'S', 'M', 'T', 'W', 'T', 'F', 'S').
  final String label;

  /// Whether the day bubble is currently selected.
  final bool isSelected;

  /// Callback triggered when the bubble is tapped.
  final VoidCallback? onTap;

  /// Size of the bubble (defaults to 40.0 according to design specifications).
  final double size;

  const DayBubble({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color backgroundColor = colorScheme.surfaceContainerLow;

    final Color outlineBase = colorScheme.outline;
    final Color borderColor = isSelected
        ? outlineBase
        : outlineBase.withValues(alpha: 0.16);

    final Color textColor = isSelected
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: theme.textTheme.labelLarge!.copyWith(color: textColor),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
