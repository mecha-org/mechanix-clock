import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/segmented_circular_progress.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_countdown_display.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(body: child),
    );
  }

  group('TimerCountdownDisplay Widget Tests', () {
    testWidgets('renders properly with active running timer', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          TimerCountdownDisplay(
            remaining: const Duration(minutes: 4, seconds: 30),
            totalDuration: const Duration(minutes: 5),
            isPaused: false,
            timerName: 'Tea',
            endTime: DateTime.now().add(
              const Duration(minutes: 4, seconds: 30),
            ),
          ),
        ),
      );

      expect(find.text('TEA'), findsOneWidget);
      expect(find.text('04:30'), findsOneWidget);
      expect(find.byType(SegmentedCountdownRing), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets(
      'handles zero totalDuration gracefully without division by zero',
      (tester) async {
        await tester.pumpWidget(
          wrapWidget(
            const TimerCountdownDisplay(
              remaining: Duration.zero,
              totalDuration: Duration.zero,
              isPaused: false,
            ),
          ),
        );

        expect(find.text('00:00'), findsOneWidget);
        expect(find.byType(SegmentedCountdownRing), findsOneWidget);
      },
    );

    testWidgets('handles paused and resume state transitions cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(minutes: 2),
            totalDuration: Duration(minutes: 5),
            isPaused: false,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Update to paused
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(minutes: 2),
            totalDuration: Duration(minutes: 5),
            isPaused: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Resume
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(minutes: 1, seconds: 59),
            totalDuration: Duration(minutes: 5),
            isPaused: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('01:59'), findsOneWidget);
    });

    testWidgets('initially displays exact selected duration on first frame', (
      tester,
    ) async {
      // 5 seconds -> 00:05
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(seconds: 5),
            totalDuration: Duration(seconds: 5),
            isPaused: false,
          ),
        ),
      );
      expect(find.text('00:05'), findsOneWidget);

      // 10 seconds -> 00:10
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(seconds: 10),
            totalDuration: Duration(seconds: 10),
            isPaused: false,
          ),
        ),
      );
      expect(find.text('00:10'), findsOneWidget);

      // 1 minute -> 01:00
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(minutes: 1),
            totalDuration: Duration(minutes: 1),
            isPaused: false,
          ),
        ),
      );
      expect(find.text('01:00'), findsOneWidget);

      // 5 minutes -> 05:00
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(minutes: 5),
            totalDuration: Duration(minutes: 5),
            isPaused: false,
          ),
        ),
      );
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('transitions sequentially without skipping seconds', (
      tester,
    ) async {
      // Start 10s
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(seconds: 10),
            totalDuration: Duration(seconds: 10),
            isPaused: false,
          ),
        ),
      );
      expect(find.text('00:10'), findsOneWidget);

      // Tick to 9s
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(seconds: 9),
            totalDuration: Duration(seconds: 10),
            isPaused: false,
          ),
        ),
      );
      expect(find.text('00:09'), findsOneWidget);

      // Tick to 8s
      await tester.pumpWidget(
        wrapWidget(
          const TimerCountdownDisplay(
            remaining: Duration(seconds: 8),
            totalDuration: Duration(seconds: 10),
            isPaused: false,
          ),
        ),
      );
      expect(find.text('00:08'), findsOneWidget);
    });
  });

  group('SegmentedCountdownRing Tests', () {
    testWidgets('paints correctly for edge values (0.0, 0.5, 1.0, clamped)', (
      tester,
    ) async {
      for (final value in [-0.5, 0.0, 0.5, 1.0, 1.5]) {
        await tester.pumpWidget(
          wrapWidget(
            SizedBox(
              width: 220,
              height: 220,
              child: SegmentedCountdownRing(
                value: value,
                totalSegments: 60,
                activeColor: Colors.white,
                inactiveColor: Colors.grey,
                glowColor: Colors.white,
                strokeWidth: 2.0,
                tickLength: 12.0,
              ),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(SegmentedCountdownRing),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
      }
    });
  });
}
