import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:widgets/widgets.dart';

class PickerColumn extends StatefulWidget {
  final int itemCount;
  final int initialValue;
  final bool isHour;
  final double width;
  final ValueChanged<int> onChanged;
  final bool showBorder;
  final bool enabled;
  final double selectedFontSize;
  final double unselectedFontSize;

  const PickerColumn({
    super.key,
    required this.itemCount,
    required this.initialValue,
    required this.isHour,
    required this.width,
    required this.onChanged,
    this.showBorder = false,
    this.enabled = true,
    this.selectedFontSize = 80,
    this.unselectedFontSize = 32,
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

    return SizedBox(
      width: widget.width,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            ignoring: !widget.enabled,
            child: CupertinoPicker(
              itemExtent: 82,
              scrollController: _controller,
              selectionOverlay: const SizedBox.shrink(),
              squeeze: 1.0,
              diameterRatio: 120,
              looping: true,
              onSelectedItemChanged: (index) {
                final actualIndex = index % widget.itemCount;
                _selectedIndex.value = actualIndex;
                if (!_isProgrammaticJump) {
                  final value = widget.isHour ? actualIndex + 1 : actualIndex;
                  widget.onChanged(value);
                }
              },
              children: List.generate(widget.itemCount, (index) {
                final label = (widget.isHour ? index + 1 : index)
                    .toString()
                    .padLeft(2, '0');
                return ValueListenableBuilder<int>(
                  valueListenable: _selectedIndex,
                  builder: (_, selected, _) {
                    final isSelected = index == (selected % widget.itemCount);
                    final activeColor = colorScheme.onSurface;
                    final inactiveColor = colorScheme.secondaryFixedDim;

                    final textStyle = isSelected
                        ? Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontFamily: MechanixFontFamily.geistMono,
                            fontSize: widget.selectedFontSize,
                            fontWeight: FontWeight.w400,
                            color: widget.enabled
                                ? activeColor
                                : activeColor.withValues(alpha: 0.3),
                          )
                        : Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontFamily: MechanixFontFamily.geistMono,
                            fontSize: widget.unselectedFontSize,
                            fontWeight: FontWeight.w400,
                            color: widget.enabled
                                ? inactiveColor
                                : inactiveColor.withValues(alpha: 0.2),
                          );

                    return Center(child: Text(label, style: textStyle));
                  },
                );
              }),
            ),
          ),
          if (widget.showBorder)
            Positioned(
              top: (220 - 72) / 2,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF2D2D2D),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
