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
        MaterialApp(
          home: SoundSelectionScreen(
            initialSound: 'digital_beeps',
            onPreview: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Digital beeps'), findsOneWidget);
      expect(find.text('Bedside alarm'), findsOneWidget);
      expect(find.text('Music box'), findsOneWidget);
      expect(find.text('Morning melody'), findsOneWidget);
      expect(find.byType(MechanixRadio<String>), findsWidgets);
      expect(find.byType(MechanixAppBar), findsOneWidget);
    });

    testWidgets('selecting another sound updates selection and previews it',
        (tester) async {
      final previewed = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: SoundSelectionScreen(
            initialSound: 'digital_beeps',
            onPreview: previewed.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Music box'));
      await tester.pumpAndSettle();

      final radio = tester.widget<MechanixRadio<String>>(
        find.byWidgetPredicate(
          (w) => w is MechanixRadio<String> && w.value == 'music_box',
        ),
      );
      expect(radio.groupValue, 'music_box');
      expect(previewed, ['music_box']);
    });

    testWidgets('going back stops the preview', (tester) async {
      var stops = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<String>(
                  builder: (_) => SoundSelectionScreen(
                    initialSound: 'digital_beeps',
                    onPreview: (_) {},
                    onStopPreview: () => stops++,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Music box'));
      await tester.pumpAndSettle();
      expect(stops, 0);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(stops, 1);
    });
  });
}
