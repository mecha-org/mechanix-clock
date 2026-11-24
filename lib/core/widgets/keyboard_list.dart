import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ↑/↓ moves between [KeyboardListItem]s, Enter activates. Wrap the scroll
/// view; keys arrive via [autofocus] (full-screen lists) or a
/// [KeyboardListHost] (main tabs).
class KeyboardList extends StatefulWidget {
  const KeyboardList({super.key, required this.child, this.autofocus = false});

  final Widget child;

  /// Take focus when shown, so ↑/↓ work straight away.
  final bool autofocus;

  static KeyboardListState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<KeyboardListState>();

  @override
  State<KeyboardList> createState() => KeyboardListState();
}

class KeyboardListState extends State<KeyboardList> {
  /// Rows that are built, by index (a lazy list only builds what is near
  /// the screen).
  final _items = SplayTreeMap<int, _KeyboardListItemState>();
  final _node = FocusNode(debugLabel: 'KeyboardList', skipTraversal: true);
  KeyboardListHostState? _host;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = KeyboardListHost.maybeOf(context);
    if (host != _host) {
      _host?._unregister(this);
      _host = host?.._register(this);
    }
  }

  @override
  void dispose() {
    _host?._unregister(this);
    _node.dispose();
    super.dispose();
  }

  void _register(int index, _KeyboardListItemState item) =>
      _items[index] = item;

  void _unregister(int index, _KeyboardListItemState item) {
    if (_items[index] == item) _items.remove(index);
  }

  int? get _focusedIndex {
    for (final entry in _items.entries) {
      if (entry.value._node.hasFocus) return entry.key;
    }
    return null;
  }

  /// Focuses the first row ([last] false) or the last built row. Returns
  /// false when there are no rows.
  bool focusEdge({required bool last}) {
    if (_items.isEmpty) return false;
    _focus(last ? _items.lastKey()! : _items.firstKey()!, down: !last);
    return true;
  }

  /// Moves focus one row down ([delta] > 0) or up. Stays put at either end.
  void move(int delta) {
    final current = _focusedIndex;
    if (current == null) {
      focusEdge(last: delta < 0);
      return;
    }
    final target = delta > 0
        ? _items.firstKeyAfter(current)
        : _items.lastKeyBefore(current);
    if (target != null) _focus(target, down: delta > 0);
  }

  void _focus(int index, {required bool down}) {
    final item = _items[index]!;
    item._focusWithRing();
    final itemContext = item.mounted ? item.context : null;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 120),
        alignmentPolicy: down
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      move(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}

/// A [KeyboardList] row: Enter calls [onActivate]. The focus ring shows only
/// when reached with ↑/↓, and stays off after returning from a page.
class KeyboardListItem extends StatefulWidget {
  const KeyboardListItem({
    super.key,
    required this.index,
    required this.onActivate,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  /// Position in the list; rows are visited in this order.
  final int index;

  /// Null when Enter does nothing for this row.
  final VoidCallback? onActivate;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<KeyboardListItem> createState() => _KeyboardListItemState();
}

class _KeyboardListItemState extends State<KeyboardListItem> {
  final _node = FocusNode(debugLabel: 'KeyboardListItem');
  KeyboardListState? _list;

  /// Reached with ↑/↓ and not left since: draw the ring.
  bool _ring = false;

  void _focusWithRing() {
    _node.requestFocus();
    if (!_ring) setState(() => _ring = true);
  }

  void _onFocusChange(bool focused) {
    if (!focused && _ring) {
      setState(() => _ring = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final list = KeyboardList.maybeOf(context);
    if (list != _list) {
      _list?._unregister(widget.index, this);
      _list = list?.._register(widget.index, this);
    }
  }

  @override
  void didUpdateWidget(KeyboardListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _list?._unregister(oldWidget.index, this);
      _list?._register(widget.index, this);
    }
  }

  @override
  void dispose() {
    _list?._unregister(widget.index, this);
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // Only for the row itself: Enter on a switch or button inside the row
    // keeps doing what it does there.
    if (event is! KeyDownEvent || !_node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    final onActivate = widget.onActivate;
    if (onActivate == null) return KeyEventResult.ignored;
    onActivate();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final showRing = _ring && _node.hasPrimaryFocus;

    return Focus(
      focusNode: _node,
      onKeyEvent: _onKey,
      onFocusChange: _onFocusChange,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: showRing
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Holds keyboard focus for a screen that has a [KeyboardList] somewhere
/// below it (each main tab): ↓/↑ arriving here, i.e. with no row focused,
/// go to that list's first/last row.
class KeyboardListHost extends StatefulWidget {
  const KeyboardListHost({super.key, required this.child});

  final Widget child;

  static KeyboardListHostState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<KeyboardListHostState>();

  @override
  State<KeyboardListHost> createState() => KeyboardListHostState();
}

class KeyboardListHostState extends State<KeyboardListHost> {
  final _node = FocusNode(debugLabel: 'KeyboardListHost', skipTraversal: true);

  /// The list shown last (a screen can swap one list for another).
  KeyboardListState? _list;

  void _register(KeyboardListState list) => _list = list;

  void _unregister(KeyboardListState list) {
    if (_list == list) _list = null;
  }

  /// Gives this screen keyboard focus (e.g. when its tab is opened).
  void focus() => _node.requestFocus();

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final list = _list;
    if (list == null ||
        (key != LogicalKeyboardKey.arrowDown &&
            key != LogicalKeyboardKey.arrowUp)) {
      return KeyEventResult.ignored;
    }
    return list.focusEdge(last: key == LogicalKeyboardKey.arrowUp)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _node, onKeyEvent: _onKey, child: widget.child);
  }
}
