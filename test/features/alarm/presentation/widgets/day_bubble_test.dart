import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/day_bubble.dart';

void main() {
  Widget buildTestWidget({
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
    double size = 40.0,
  }) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          surfaceContainerLow: Color(0xFF141415),
          outline: Color(0xFF373739),
          onSurface: Color(0xFFEEEEEE),
          onSurfaceVariant: Color(0xFF717171),
        ),
      ),
      home: Scaffold(
        body: Center(
          child: DayBubble(
            label: label,
            isSelected: isSelected,
            onTap: onTap,
            size: size,
          ),
        ),
      ),
    );
  }

  group('DayBubble Widget', () {
    testWidgets('renders label correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(label: 'M', isSelected: false));

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('displays correct colors when selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(label: 'M', isSelected: true));
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(DayBubble),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;

      // Background color should be surfaceContainerLow (#141415)
      expect(decoration.color, const Color(0xFF141415));

      // Border should be outline color (#373739)
      final border = decoration.border as Border;
      expect(border.top.color, const Color(0xFF373739));

      // Text color should be onSurface (#EEEEEE)
      final animatedTextStyle = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.byType(DayBubble),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      expect(animatedTextStyle.style.color, const Color(0xFFEEEEEE));
    });

    testWidgets('displays correct colors when unselected', (tester) async {
      await tester.pumpWidget(buildTestWidget(label: 'W', isSelected: false));
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(DayBubble),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;

      // Background color should be surfaceContainerLow (#141415)
      expect(decoration.color, const Color(0xFF141415));

      // Border should have 16% opacity
      final border = decoration.border as Border;
      expect(
        border.top.color,
        const Color(0xFF373739).withValues(alpha: 0.16),
      );

      // Text color should be onSurfaceVariant (#717171)
      final animatedTextStyle = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.byType(DayBubble),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      expect(animatedTextStyle.style.color, const Color(0xFF717171));
    });

    testWidgets('handles tap event', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          label: 'F',
          isSelected: false,
          onTap: () {
            tapped = true;
          },
        ),
      );

      await tester.tap(find.byType(DayBubble));
      expect(tapped, isTrue);
    });
  });
}
