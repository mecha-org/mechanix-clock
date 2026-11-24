import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/widgets/keyboard_list.dart';

void main() {
  late List<int> activated;

  setUp(() => activated = []);

  Widget list({required bool autofocus, int count = 3}) => KeyboardList(
    autofocus: autofocus,
    child: ListView.builder(
      itemCount: count,
      itemBuilder: (context, index) => KeyboardListItem(
        key: Key('item_$index'),
        index: index,
        onActivate: index == 2 ? null : () => activated.add(index),
        child: SizedBox(height: 48, child: Text('Item $index')),
      ),
    ),
  );

  bool focused(WidgetTester tester, int index) {
    final focus = tester.widget<Focus>(
      find
          .descendant(
            of: find.byKey(Key('item_$index')),
            matching: find.byType(Focus),
          )
          .first,
    );
    return focus.focusNode!.hasPrimaryFocus;
  }

  testWidgets('↓/↑ move between rows and stop at the ends', (tester) async {
    await tester.pumpWidget(MaterialApp(home: list(autofocus: true)));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focused(tester, 0), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focused(tester, 2), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(focused(tester, 1), isTrue);
  });

  testWidgets('↑ with nothing focused goes to the last row', (tester) async {
    await tester.pumpWidget(MaterialApp(home: list(autofocus: true)));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(focused(tester, 2), isTrue);
  });

  testWidgets('Enter activates the focused row only', (tester) async {
    await tester.pumpWidget(MaterialApp(home: list(autofocus: true)));
    await tester.pump();

    // Nothing focused yet: Enter does nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
    expect(activated, [1, 1]);

    // A row without an action ignores Enter.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, [1, 1]);
  });

  testWidgets('a host forwards ↓ to its list', (tester) async {
    final host = GlobalKey<KeyboardListHostState>();
    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardListHost(key: host, child: list(autofocus: false)),
      ),
    );
    host.currentState!.focus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focused(tester, 0), isTrue);
  });

  testWidgets('the ring is gone after a page opened from the row closes', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: list(autofocus: true)));
    await tester.pump();

    bool ring(int index) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(Key('item_$index')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).border != null;
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(ring(0), isTrue);

    // A page opens (as Enter on an alarm does) and closes again.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Focus(autofocus: true, child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();

    expect(focused(tester, 0), isTrue);
    expect(ring(0), isFalse);

    // ↓ carries on from that row, with the ring.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focused(tester, 1), isTrue);
    expect(ring(1), isTrue);
  });
}
