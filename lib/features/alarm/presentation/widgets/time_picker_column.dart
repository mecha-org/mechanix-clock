import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PickerColumn extends StatefulWidget {
  final int itemCount;
  final int initialValue;
  final bool isHour;
  final double width;
  final ValueChanged<int> onChanged; // plain callback, no setState in parent
  final bool showBorder;
  final bool enabled;

  const PickerColumn({
    super.key,
    required this.itemCount,
    required this.initialValue,
    required this.isHour,
    required this.width,
    required this.onChanged,
    this.showBorder = true,
    this.enabled = true,
  });

  @override
  State<PickerColumn> createState() => PickerColumnState();
}

class PickerColumnState extends State<PickerColumn> {
  late final FixedExtentScrollController _controller;
  late final ValueNotifier<int> _selectedIndex;

  @override
  void initState() {
    super.initState();
    final initial = widget.isHour
        ? widget.initialValue - 1
        : widget.initialValue;
    _controller = FixedExtentScrollController(initialItem: initial);
    _selectedIndex = ValueNotifier(initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            ignoring: !widget.enabled,
            child: CupertinoPicker(
              itemExtent: 87,
              scrollController: _controller,
              selectionOverlay: const SizedBox.shrink(),
              squeeze: 1.0,
              diameterRatio: 200,
              looping: true,
              onSelectedItemChanged: (index) {
                _selectedIndex.value =
                    index; // only notifies ValueListenableBuilder
                final value = widget.isHour ? index + 1 : index;
                widget.onChanged(value); // plain assignment in parent
              },
              children: List.generate(widget.itemCount, (index) {
                final label = (widget.isHour ? index + 1 : index)
                    .toString()
                    .padLeft(2, '0');
                return ValueListenableBuilder<int>(
                  valueListenable: _selectedIndex,
                  builder: (_, selected, _) {
                    final isSelected = index == selected;
                    final baseStyle = isSelected
                        ? Theme.of(context).textTheme.displayLarge
                        : Theme.of(context).textTheme.displaySmall;
                    return Center(
                      child: Text(
                        label,
                        style: widget.enabled
                            ? baseStyle
                            : baseStyle?.copyWith(
                                color: baseStyle.color?.withValues(alpha: 0.3),
                              ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          if (widget.showBorder)
            Positioned(
              top: 66.5,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 87,
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
