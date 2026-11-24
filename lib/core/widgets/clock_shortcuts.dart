import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Main-screen shortcuts: Ctrl+N new alarm (Alarms tab), Space start/stop
/// (Stopwatch tab). Active only while the main screen is on top.
class ClockShortcuts extends StatefulWidget {
  const ClockShortcuts({
    super.key,
    required this.onNewAlarm,
    required this.onSpace,
    required this.child,
  });

  /// Returns false when Ctrl+N means nothing here (another tab).
  final bool Function() onNewAlarm;

  /// Returns false when Space means nothing here (another tab), so it keeps
  /// its usual meaning, e.g. pressing the focused button.
  final bool Function() onSpace;
  final Widget child;

  @override
  State<ClockShortcuts> createState() => _ClockShortcutsState();
}

class _ClockShortcutsState extends State<ClockShortcuts> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// True when the event was used.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    // Another page or sheet is open over the main screen.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;

    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyN &&
        keyboard.isControlPressed &&
        !keyboard.isAltPressed &&
        !keyboard.isShiftPressed &&
        !keyboard.isMetaPressed) {
      return widget.onNewAlarm();
    }
    if (key == LogicalKeyboardKey.space &&
        !keyboard.isControlPressed &&
        !keyboard.isAltPressed &&
        !keyboard.isMetaPressed) {
      return widget.onSpace();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
