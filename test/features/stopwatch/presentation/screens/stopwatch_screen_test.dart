import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_bloc.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_event.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_state.dart';
import 'package:mechanix_clock/features/stopwatch/data/models/lap_time_model.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/screens/stopwatch_screen.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/widgets/lap_list_item.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

class MockStopwatchBloc extends MockBloc<StopwatchEvent, StopwatchState>
    implements StopwatchBloc {}

void main() {
  late MockStopwatchBloc mockStopwatchBloc;

  setUpAll(() {
    registerFallbackValue(StartStopwatch());
    registerFallbackValue(StopStopwatch());
    registerFallbackValue(ResetStopwatch());
    registerFallbackValue(LapStopwatch());
  });

  setUp(() {
    mockStopwatchBloc = MockStopwatchBloc();
  });

  Widget createWidgetUnderTest() {
    return MechanixTheme(
      builder: (context, theme, child) {
        return MaterialApp(
          theme: theme.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: BlocProvider<StopwatchBloc>.value(
            value: mockStopwatchBloc,
            child: const StopwatchScreen(),
          ),
        );
      },
    );
  }

  testWidgets('renders initial stopwatch screen with MechanixAppBar and no laps before tapping lap button', (
    tester,
  ) async {
    when(
      () => mockStopwatchBloc.state,
    ).thenReturn(const StopwatchState(status: StopwatchStatus.initial));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('STOPWATCH'), findsOneWidget);

    // Verify no lap items are rendered initially
    expect(find.byType(LapListItem), findsNothing);

    // Verify buttons
    expect(find.byKey(const Key('stopwatch_lap_button')), findsOneWidget);
    expect(find.byKey(const Key('stopwatch_start_button')), findsOneWidget);

    // Tap start button
    await tester.tap(find.byKey(const Key('stopwatch_start_button')));
    verify(() => mockStopwatchBloc.add(StartStopwatch())).called(1);
  });

  testWidgets('renders running stopwatch state with laps and action buttons', (
    tester,
  ) async {
    final laps = [
      const LapTime(
        lapNumber: 3,
        duration: Duration(milliseconds: 300),
        totalTime: Duration(milliseconds: 500),
      ),
      const LapTime(
        lapNumber: 2,
        duration: Duration(milliseconds: 100),
        totalTime: Duration(milliseconds: 200),
      ),
      const LapTime(
        lapNumber: 1,
        duration: Duration(milliseconds: 100),
        totalTime: Duration(milliseconds: 100),
      ),
    ];

    when(() => mockStopwatchBloc.state).thenReturn(
      StopwatchState(
        status: StopwatchStatus.running,
        elapsed: const Duration(seconds: 50),
        laps: laps,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Lap items are rendered in ascending order
    expect(find.byType(LapListItem), findsNWidgets(3));
    expect(find.text('LAP 01'), findsOneWidget);
    expect(find.text('LAP 02'), findsOneWidget);
    expect(find.text('LAP 03'), findsOneWidget);

    // Verify lap and stop buttons are present
    expect(find.byKey(const Key('stopwatch_lap_button')), findsOneWidget);
    expect(find.byKey(const Key('stopwatch_stop_button')), findsOneWidget);

    // Tap lap button
    await tester.tap(find.byKey(const Key('stopwatch_lap_button')));
    verify(() => mockStopwatchBloc.add(LapStopwatch())).called(1);

    // Tap stop button
    await tester.tap(find.byKey(const Key('stopwatch_stop_button')));
    verify(() => mockStopwatchBloc.add(StopStopwatch())).called(1);
  });

  testWidgets('renders stopped/paused stopwatch state with reset and start buttons', (
    tester,
  ) async {
    when(() => mockStopwatchBloc.state).thenReturn(
      const StopwatchState(
        status: StopwatchStatus.stopped,
        elapsed: Duration(seconds: 50),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stopwatch_reset_button')), findsOneWidget);
    expect(find.byKey(const Key('stopwatch_start_button')), findsOneWidget);

    // Tap reset button
    await tester.tap(find.byKey(const Key('stopwatch_reset_button')));
    verify(() => mockStopwatchBloc.add(ResetStopwatch())).called(1);
  });
}
