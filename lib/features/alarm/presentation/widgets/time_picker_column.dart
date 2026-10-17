import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PickerColumn extends StatefulWidget {
  final int itemCount;
  final int initialValue;
  final bool isHour;
  final double width;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final TextStyle? selectedTextStyle;
  final TextStyle? unselectedTextStyle;
  final double squeeze;

  const PickerColumn({
    super.key,
    required this.itemCount,
    required this.initialValue,
    required this.isHour,
    required this.width,
    required this.onChanged,
    this.enabled = true,
    this.squeeze = 1.0,
    this.selectedTextStyle,
    this.unselectedTextStyle,
  });

  @override
  State<PickerColumn> createState() => PickerColumnState();
}

class PickerColumnState extends State<PickerColumn> {
  late final FixedExtentScrollController _controller;
  late final ValueNotifier<int> _selectedIndex;
  bool _isProgrammaticJump = false;

  int _getNormalizedIndex(int value) {
    if (widget.isHour) {
      return (value - 1).clamp(0, widget.itemCount - 1);
    }
    return value.clamp(0, widget.itemCount - 1);
  }

  @override
  void initState() {
    super.initState();
    final initial = _getNormalizedIndex(widget.initialValue);
    _controller = FixedExtentScrollController(initialItem: initial);
    _selectedIndex = ValueNotifier(initial);
  }

  @override
  void didUpdateWidget(covariant PickerColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      final targetIndex = _getNormalizedIndex(widget.initialValue);
      if (_selectedIndex.value != targetIndex) {
        _selectedIndex.value = targetIndex;
        if (_controller.hasClients) {
          _isProgrammaticJump = true;
          _controller.jumpToItem(targetIndex);
          _isProgrammaticJump = false;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.onSurface;
    final inactiveColor = colorScheme.onSurfaceVariant;

    final selectedStyle = widget.selectedTextStyle?.copyWith(
      color: widget.enabled
          ? activeColor
          : activeColor.withValues(alpha: 0.3),
    );
    final unselectedStyle = widget.unselectedTextStyle?.copyWith(
      color: widget.enabled
          ? inactiveColor
          : inactiveColor.withValues(alpha: 0.2),
    );

    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              ignoring: !widget.enabled,
              child: CupertinoPicker.builder(
                itemExtent: (widget.selectedTextStyle?.fontSize ?? 80) + 2,
                scrollController: _controller,
                selectionOverlay: const SizedBox.shrink(),
                squeeze: widget.squeeze,
                diameterRatio: 180,
                onSelectedItemChanged: (index) {
                  final actualIndex =
                      (index % widget.itemCount + widget.itemCount) %
                      widget.itemCount;
                  _selectedIndex.value = actualIndex;
                  if (!_isProgrammaticJump) {
                    final value = widget.isHour ? actualIndex + 1 : actualIndex;
                    widget.onChanged(value);
                  }
                },
                itemBuilder: (context, index) {
                  final actualIndex =
                      (index % widget.itemCount + widget.itemCount) %
                      widget.itemCount;
                  final label = (widget.isHour ? actualIndex + 1 : actualIndex)
                      .toString()
                      .padLeft(2, '0');
                  return ValueListenableBuilder<int>(
                    valueListenable: _selectedIndex,
                    builder: (_, selected, _) {
                      final isSelected =
                          actualIndex == (selected % widget.itemCount);
                      final textStyle =
                          isSelected ? selectedStyle : unselectedStyle;

                      return Center(child: Text(label, style: textStyle));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
