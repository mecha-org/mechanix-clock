import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/widgets/clock_shortcuts.dart';

void main() {
  late int newAlarm;
  late int space;
  late bool spaceApplies;
  late bool newAlarmApplies;

  setUp(() {
    newAlarm = 0;
    space = 0;
    spaceApplies = true;
    newAlarmApplies = true;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ClockShortcuts(
          onNewAlarm: () {
            if (!newAlarmApplies) return false;
            newAlarm++;
            return true;
          },
          onSpace: () {
            if (!spaceApplies) return false;
            space++;
            return true;
          },
          child: const Focus(autofocus: true, child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Ctrl+N asks for a new alarm', (tester) async {
    await pump(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(newAlarm, 1);

    // N alone, or with Shift, is not the shortcut.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(newAlarm, 1);
  });

  testWidgets('Space toggles only where it applies', (tester) async {
    await pump(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(space, 1);

    spaceApplies = false;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(space, 1);
  });

  testWidgets('Ctrl+N does nothing where it does not apply', (tester) async {
    newAlarmApplies = false;
    await pump(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(newAlarm, 0);
  });

  testWidgets('ignored while another page is on top', (tester) async {
    await pump(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Focus(autofocus: true, child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(space, 0);
    expect(newAlarm, 0);
  });
}
