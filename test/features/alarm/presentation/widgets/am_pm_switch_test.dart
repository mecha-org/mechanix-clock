import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/am_pm_switch.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

void main() {
  const surfaceContainerLow = Color(0xFF141415);
  const outline = Color(0xFF373739);
  const onSurface = Color(0xFFEEEEEE);
  const onSurfaceVariant = Color(0xFF717171);
  const onPrimaryFixed = Color(0xFFE2662C);

  Widget buildTestWidget({
    required bool isAm,
    required ValueChanged<bool> onChanged,
  }) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          surfaceContainerLow: surfaceContainerLow,
          outline: outline,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          onPrimaryFixed: onPrimaryFixed,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(
        body: Center(
          child: AmPmSwitch(
            isAm: isAm,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  group('AmPmSwitch Widget', () {
    testWidgets('renders AM and PM labels correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(isAm: true, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('has correct styling when AM is selected', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(isAm: true, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      final amContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const Key('am_segment')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final amDecoration = amContainer.decoration as BoxDecoration;
      expect(amDecoration.color, surfaceContainerLow);
      expect(amDecoration.border?.top.color, Colors.transparent);

      final amText = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.byKey(const Key('am_segment')),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      expect(amText.style.color, onPrimaryFixed);

      final pmContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const Key('pm_segment')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final pmDecoration = pmContainer.decoration as BoxDecoration;
      expect(pmDecoration.color, Colors.transparent);
      expect(pmDecoration.border?.top.color, outline);

      final pmText = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.byKey(const Key('pm_segment')),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      expect(pmText.style.color, onSurfaceVariant);
    });

    testWidgets('has correct styling when PM is selected', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(isAm: false, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      final amContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const Key('am_segment')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final amDecoration = amContainer.decoration as BoxDecoration;
      expect(amDecoration.color, Colors.transparent);
      expect(amDecoration.border?.top.color, outline);

      final amText = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.byKey(const Key('am_segment')),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      expect(amText.style.color, onSurfaceVariant);

      final pmContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const Key('pm_segment')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final pmDecoration = pmContainer.decoration as BoxDecoration;
      expect(pmDecoration.color, surfaceContainerLow);
      expect(pmDecoration.border?.top.color, Colors.transparent);

      final pmText = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.byKey(const Key('pm_segment')),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      expect(pmText.style.color, onPrimaryFixed);
    });

    testWidgets('tapping PM invokes onChanged with false', (tester) async {
      bool? updatedValue;
      await tester.pumpWidget(
        buildTestWidget(
          isAm: true,
          onChanged: (val) {
            updatedValue = val;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pm_segment')));
      await tester.pumpAndSettle();

      expect(updatedValue, isFalse);
    });

    testWidgets('tapping AM invokes onChanged with true', (tester) async {
      bool? updatedValue;
      await tester.pumpWidget(
        buildTestWidget(
          isAm: false,
          onChanged: (val) {
            updatedValue = val;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('am_segment')));
      await tester.pumpAndSettle();

      expect(updatedValue, isTrue);
    });
  });
}
