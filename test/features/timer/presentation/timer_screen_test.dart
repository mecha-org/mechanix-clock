import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_event.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_state.dart';
import 'package:mechanix_clock/features/timer/data/models/active_timer_data.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/presentation/timer_screen.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_custom_picker.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

class MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

void main() {
  late MockTimerBloc mockTimerBloc;

  setUpAll(() {
    registerFallbackValue(const StartTimer(Duration.zero));
    registerFallbackValue(CancelTimer());
    registerFallbackValue(PauseTimer());
    registerFallbackValue(ResumeTimer());
  });

  setUp(() {
    mockTimerBloc = MockTimerBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: BlocProvider<TimerBloc>.value(
        value: mockTimerBloc,
        child: const TimerScreen(),
      ),
    );
  }

  testWidgets(
    'initially displays timer setting screen without AppBar action buttons',
    (tester) async {
      when(
        () => mockTimerBloc.state,
      ).thenReturn(const TimerState(status: TimerStatus.idle, presets: []));

      await tester.pumpWidget(createWidgetUnderTest());

      // Setting screen elements are present
      expect(find.byType(TimerCustomPicker), findsOneWidget);
      expect(find.byKey(const Key('timer_start_button')), findsOneWidget);
      expect(find.byKey(const Key('timer_left_button')), findsOneWidget);

      // AppBar action buttons (+ / edit) are removed from setting screen
      expect(find.byKey(const Key('timer_goto_setting_button')), findsNothing);
      expect(find.byKey(const Key('timer_add_preset_button')), findsNothing);
      expect(find.byKey(const Key('timer_edit_mode_button')), findsNothing);
    },
  );

  testWidgets('tapping start button dispatches StartTimer event', (
    tester,
  ) async {
    when(
      () => mockTimerBloc.state,
    ).thenReturn(const TimerState(status: TimerStatus.idle, presets: []));

    await tester.pumpWidget(createWidgetUnderTest());

    // Default duration is 1 min (hours: 0, minutes: 1, seconds: 0)
    await tester.tap(find.byKey(const Key('timer_start_button')));
    await tester.pump();

    verify(
      () => mockTimerBloc.add(
        const StartTimer(Duration(minutes: 1), resetOldActiveTimers: true),
      ),
    ).called(1);
  });

  testWidgets(
    'tapping reset button on setting screen resets picker time to 0',
    (tester) async {
      when(
        () => mockTimerBloc.state,
      ).thenReturn(const TimerState(status: TimerStatus.idle, presets: []));

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap reset button
      await tester.tap(find.byKey(const Key('timer_left_button')));
      await tester.pumpAndSettle();

      // Start button should now be disabled (no time selected)
      final startButton = tester.widget<MechanixIconButton>(
        find.byKey(const Key('timer_start_button')),
      );
      expect(startButton.onPressed, isNull);

      // Reset button should now be disabled (already 00:00:00)
      final resetButton = tester.widget<MechanixIconButton>(
        find.byKey(const Key('timer_left_button')),
      );
      expect(resetButton.onPressed, isNull);
    },
  );

  testWidgets(
    'running timer displays play/pause screen with orange + button and active pause button',
    (tester) async {
      final preset1 = const TimerPreset(
        id: 'p1',
        duration: Duration(minutes: 5),
      );
      final preset2 = const TimerPreset(
        id: 'p2',
        duration: Duration(minutes: 30),
      );
      when(() => mockTimerBloc.state).thenReturn(
        TimerState(
          status: TimerStatus.running,
          duration: const Duration(minutes: 5),
          remaining: const Duration(minutes: 4, seconds: 50),
          presets: [preset1, preset2],
          activePresetId: 'p1',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Play screen is visible
      expect(find.byType(TimerCustomPicker), findsNothing);
      expect(
        find.byKey(const Key('timer_goto_setting_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('timer_active_pause_button')),
        findsOneWidget,
      );

      // Other presets in list are visible
      expect(find.text('30:00'), findsOneWidget);

      // Tapping pause button dispatches PauseTimer
      await tester.tap(find.byKey(const Key('timer_active_pause_button')));
      await tester.pump();
      verify(() => mockTimerBloc.add(PauseTimer(presetId: 'p1'))).called(1);
    },
  );

  testWidgets('paused timer displays resume button on play screen', (
    tester,
  ) async {
    final preset1 = const TimerPreset(id: 'p1', duration: Duration(minutes: 5));
    when(() => mockTimerBloc.state).thenReturn(
      TimerState(
        status: TimerStatus.paused,
        duration: const Duration(minutes: 5),
        remaining: const Duration(minutes: 4, seconds: 50),
        presets: [preset1],
        activePresetId: 'p1',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byKey(const Key('timer_active_resume_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('timer_active_resume_button')));
    await tester.pump();
    verify(() => mockTimerBloc.add(ResumeTimer(presetId: 'p1'))).called(1);
  });

  testWidgets(
    'tapping + button on play/pause screen navigates to timer setting screen',
    (tester) async {
      final preset1 = const TimerPreset(
        id: 'p1',
        duration: Duration(minutes: 5),
      );
      when(() => mockTimerBloc.state).thenReturn(
        TimerState(
          status: TimerStatus.running,
          duration: const Duration(minutes: 5),
          remaining: const Duration(minutes: 5),
          presets: [preset1],
          activePresetId: 'p1',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Verify on play screen initially
      expect(
        find.byKey(const Key('timer_goto_setting_button')),
        findsOneWidget,
      );
      expect(find.byType(TimerCustomPicker), findsNothing);

      // Tap + button
      await tester.tap(find.byKey(const Key('timer_goto_setting_button')));
      await tester.pumpAndSettle();

      // Now on setting screen
      expect(find.byType(TimerCustomPicker), findsOneWidget);
      expect(find.byKey(const Key('timer_start_button')), findsOneWidget);
    },
  );

  testWidgets(
    'play screen renders paused timer, running timer, and idle preset simultaneously',
    (tester) async {
      final preset1 = const TimerPreset(
        id: 'p1',
        duration: Duration(seconds: 10),
      );
      final preset2 = const TimerPreset(
        id: 'p2',
        duration: Duration(minutes: 5),
      );
      final preset3 = const TimerPreset(
        id: 'p3',
        duration: Duration(minutes: 30),
      );

      when(() => mockTimerBloc.state).thenReturn(
        TimerState(
          status: TimerStatus.running,
          presets: [preset1, preset2, preset3],
          activePresetId: 'p2',
          activeTimers: const {
            'p1': ActiveTimerData(
              id: 'p1',
              duration: Duration(seconds: 10),
              remaining: Duration(seconds: 10),
              status: TimerStatus.paused,
            ),
            'p2': ActiveTimerData(
              id: 'p2',
              duration: Duration(minutes: 5),
              remaining: Duration(minutes: 5),
              status: TimerStatus.running,
            ),
          },
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Should display 1 pause button (for running p2) and 1 resume button (for paused p1)
      expect(
        find.byKey(const Key('timer_active_pause_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('timer_active_resume_button')),
        findsOneWidget,
      );

      // Preset 3 is idle in list
      expect(find.text('30:00'), findsOneWidget);
    },
  );

  testWidgets('play screen renders active timers above inactive presets', (
    tester,
  ) async {
    final preset1 = const TimerPreset(id: 'p1', duration: Duration(minutes: 1));
    final preset2 = const TimerPreset(id: 'p2', duration: Duration(minutes: 5));
    final preset3 = const TimerPreset(
      id: 'p3',
      duration: Duration(minutes: 10),
    );

    // Suppose p3 is running and p1, p2 are inactive presets
    when(() => mockTimerBloc.state).thenReturn(
      TimerState(
        status: TimerStatus.running,
        presets: [preset1, preset2, preset3],
        activePresetId: 'p3',
        activeTimers: const {
          'p3': ActiveTimerData(
            id: 'p3',
            duration: Duration(minutes: 10),
            remaining: Duration(minutes: 10),
            status: TimerStatus.running,
          ),
        },
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    // Find all TimerActiveItem and TimerPresetItem positions
    final activeFinder = find.byKey(const ValueKey('p3'));
    final inactive1Finder = find.byKey(const ValueKey('p1'));
    final inactive2Finder = find.byKey(const ValueKey('p2'));

    expect(activeFinder, findsOneWidget);
    expect(inactive1Finder, findsOneWidget);
    expect(inactive2Finder, findsOneWidget);

    final activeTop = tester.getTopLeft(activeFinder).dy;
    final inactive1Top = tester.getTopLeft(inactive1Finder).dy;
    final inactive2Top = tester.getTopLeft(inactive2Finder).dy;

    // Active timer p3 must be rendered above inactive presets p1 and p2
    expect(activeTop < inactive1Top, isTrue);
    expect(activeTop < inactive2Top, isTrue);
  });
}
