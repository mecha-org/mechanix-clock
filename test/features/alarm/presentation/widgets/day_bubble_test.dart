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
