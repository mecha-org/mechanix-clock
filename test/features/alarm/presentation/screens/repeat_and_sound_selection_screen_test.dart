import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/repeat_selection_screen.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/sound_selection_screen.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

void main() {
  group('RepeatSelectionScreen', () {
    testWidgets('renders Once, Daily, and Custom options with Mechanix widgets',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', '')],
          home: RepeatSelectionScreen(initialDays: [1, 3]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Once'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.byType(MechanixRadio<RepeatType>), findsNWidgets(3));
      expect(find.byType(MechanixAppBar), findsOneWidget);
    });

    testWidgets('selecting Once updates state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', '')],
          home: RepeatSelectionScreen(initialDays: [1, 3]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Once'));
      await tester.pumpAndSettle();

      final radio = tester.widget<MechanixRadio<RepeatType>>(
        find.byWidgetPredicate(
          (w) => w is MechanixRadio<RepeatType> && w.value == RepeatType.once,
        ),
      );
      expect(radio.groupValue, RepeatType.once);
    });
  });

  group('SoundSelectionScreen', () {
    testWidgets('renders sound list with MechanixRadio and MechanixAppBar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SoundSelectionScreen(initialSound: 'Dancing Flames'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dancing Flames'), findsOneWidget);
      expect(find.text('Comet on the go'), findsOneWidget);
      expect(find.text('Phoenix song'), findsOneWidget);
      expect(find.text('Wake up and party'), findsOneWidget);
      expect(find.byType(MechanixRadio<String>), findsWidgets);
      expect(find.byType(MechanixAppBar), findsOneWidget);
    });

    testWidgets('selecting another sound updates selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SoundSelectionScreen(initialSound: 'Dancing Flames'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phoenix song'));
      await tester.pumpAndSettle();

      final radio = tester.widget<MechanixRadio<String>>(
        find.byWidgetPredicate(
          (w) => w is MechanixRadio<String> && w.value == 'Phoenix song',
        ),
      );
      expect(radio.groupValue, 'Phoenix song');
    });
  });
}
