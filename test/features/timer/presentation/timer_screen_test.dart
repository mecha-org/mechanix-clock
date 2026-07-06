import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_event.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_state.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/presentation/timer_screen.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_button.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_custom_picker.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

void main() {
  late MockTimerBloc mockTimerBloc;

  setUpAll(() {
    registerFallbackValue(const AddTimerPreset(Duration.zero));
    registerFallbackValue(const UpdateTimerPreset(id: '', name: ''));
    registerFallbackValue(const ReorderTimerPresets(0, 0));
    registerFallbackValue(const DeleteTimerPreset(''));
    registerFallbackValue(CancelTimer());
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

  testWidgets('timer_add_preset_button is visible in idle status', (
    tester,
  ) async {
    when(
      () => mockTimerBloc.state,
    ).thenReturn(const TimerState(status: TimerStatus.idle, presets: []));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byKey(const Key('timer_add_preset_button')), findsOneWidget);
  });

  testWidgets('timer_add_preset_button is absent in running status', (
    tester,
  ) async {
    when(
      () => mockTimerBloc.state,
    ).thenReturn(const TimerState(status: TimerStatus.running, presets: []));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byKey(const Key('timer_add_preset_button')), findsNothing);
  });

  testWidgets(
    'shows warning SnackBar when trying to save a 0 duration preset',
    (tester) async {
      when(
        () => mockTimerBloc.state,
      ).thenReturn(const TimerState(status: TimerStatus.idle, presets: []));

      await tester.pumpWidget(createWidgetUnderTest());

      // Locate the three CupertinoPicker widgets inside TimerCustomPicker.
      // Set hours, minutes, and seconds to 0.
      final pickers = find.byType(CupertinoPicker);
      expect(pickers, findsNWidgets(3));

      // Scroll/Change picker values to 0
      // Hours (initial is 0 anyway, but let's select 0 to be sure)
      await tester.tap(find.text('00').first);
      // Minutes (initial is 5, scroll to 0)
      final CupertinoPicker minutesPicker = tester.widget<CupertinoPicker>(
        pickers.at(1),
      );
      minutesPicker.onSelectedItemChanged?.call(0);
      // Seconds (initial is 2, scroll to 0)
      final CupertinoPicker secondsPicker = tester.widget<CupertinoPicker>(
        pickers.at(2),
      );
      secondsPicker.onSelectedItemChanged?.call(0);

      await tester.pumpAndSettle();

      // Click the add preset button
      await tester.tap(find.byKey(const Key('timer_add_preset_button')));
      await tester.pump();

      // Verify warning SnackBar is shown
      expect(
        find.text('Please select a duration greater than 0'),
        findsOneWidget,
      );
      verifyNever(() => mockTimerBloc.add(any()));
    },
  );

  testWidgets('shows warning SnackBar when preset already exists', (
    tester,
  ) async {
    final existingPreset = TimerPreset(
      id: '1',
      duration: const Duration(minutes: 1),
    );
    when(() => mockTimerBloc.state).thenReturn(
      TimerState(status: TimerStatus.idle, presets: [existingPreset]),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    // By default: selected hours = 0, minutes = 1, seconds = 0.
    // This matches the existingPreset (1 min).
    await tester.tap(find.byKey(const Key('timer_add_preset_button')));
    await tester.pump();

    // Verify Warning SnackBar is shown
    expect(find.text('Preset already exists'), findsOneWidget);
    verifyNever(() => mockTimerBloc.add(any()));
  });

  testWidgets('adds preset when valid', (
    tester,
  ) async {
    when(
      () => mockTimerBloc.state,
    ).thenReturn(const TimerState(status: TimerStatus.idle, presets: []));

    await tester.pumpWidget(createWidgetUnderTest());

    // By default: selected hours = 0, minutes = 1, seconds = 0.
    await tester.tap(find.byKey(const Key('timer_add_preset_button')));
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Add Preset (01:00 mins)'), findsOneWidget);

    // Enter name
    await tester.enterText(find.byType(TextField), 'Work');
    await tester.pump();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify AddTimerPreset is called with the name
    verify(
      () => mockTimerBloc.add(
        const AddTimerPreset(Duration(minutes: 1), name: 'Work'),
      ),
    ).called(1);
  });

  testWidgets(
    'clicking a preset in edit mode opens rename dialog and updates preset',
    (tester) async {
      final existingPreset = TimerPreset(
        id: 'preset_123',
        duration: const Duration(minutes: 10),
        name: 'Old Name',
      );
      when(() => mockTimerBloc.state).thenReturn(
        TimerState(
          status: TimerStatus.idle,
          presets: [existingPreset],
          isEditingPresets: true,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Find the preset item and tap it (in edit mode, onTap is onEdit)
      await tester.tap(find.text('Old Name'));
      await tester.pumpAndSettle();

      // Verify rename dialog opened
      expect(find.text('Edit Preset (10:00 mins)'), findsOneWidget);
      expect(
        find.text('Old Name'),
        findsNWidgets(2),
      ); // One in the list, one in the TextField

      // Enter new name
      await tester.enterText(find.byType(TextField), 'New Name');
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify UpdateTimerPreset is dispatched
      verify(
        () => mockTimerBloc.add(
          const UpdateTimerPreset(id: 'preset_123', name: 'New Name'),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'clicking cancel button dispatches CancelTimer when preset is active',
    (tester) async {
      final existingPreset = TimerPreset(
        id: 'preset_123',
        duration: const Duration(minutes: 10),
      );
      when(() => mockTimerBloc.state).thenReturn(
        TimerState(
          status: TimerStatus.running,
          duration: const Duration(minutes: 10),
          remaining: const Duration(minutes: 8),
          presets: [existingPreset],
          activePresetId: 'preset_123',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Click the cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Verify CancelTimer is dispatched
      verify(() => mockTimerBloc.add(CancelTimer())).called(1);
      // Verify DeleteTimerPreset is NOT dispatched
      verifyNever(() => mockTimerBloc.add(any<DeleteTimerPreset>()));
    },
  );

  testWidgets(
    'clicking cancel button dispatches CancelTimer when no preset is active',
    (tester) async {
      when(() => mockTimerBloc.state).thenReturn(
        const TimerState(
          status: TimerStatus.running,
          duration: Duration(minutes: 10),
          remaining: Duration(minutes: 8),
          presets: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Click the cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Verify CancelTimer is dispatched
      verify(() => mockTimerBloc.add(CancelTimer())).called(1);
    },
  );

  testWidgets('reordering presets dispatches ReorderTimerPresets event', (
    tester,
  ) async {
    final preset1 = const TimerPreset(id: '1', duration: Duration(minutes: 1));
    final preset2 = const TimerPreset(id: '2', duration: Duration(minutes: 2));
    when(() => mockTimerBloc.state).thenReturn(
      TimerState(
        status: TimerStatus.idle,
        presets: [preset1, preset2],
        isEditingPresets: true,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    // Verify ReorderableListView is present
    expect(find.byType(ReorderableListView), findsOneWidget);

    // Trigger onReorderItem on the ReorderableListView
    final reorderableList = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderableList.onReorderItem?.call(0, 1);

    verify(() => mockTimerBloc.add(const ReorderTimerPresets(0, 1))).called(1);
  });

  testWidgets('start button is disabled when in editing mode', (tester) async {
    when(() => mockTimerBloc.state).thenReturn(
      const TimerState(
        status: TimerStatus.idle,
        presets: [],
        isEditingPresets: true,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    final startButtonFinder = find.byWidgetPredicate(
      (widget) => widget is TimerButton && widget.label == 'Start',
    );
    expect(startButtonFinder, findsOneWidget);

    final timerButton = tester.widget<TimerButton>(startButtonFinder);
    expect(timerButton.enabled, isFalse);
  });

  testWidgets('custom picker is disabled when in editing mode', (tester) async {
    when(() => mockTimerBloc.state).thenReturn(
      const TimerState(
        status: TimerStatus.idle,
        presets: [],
        isEditingPresets: true,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    final pickerFinder = find.byType(TimerCustomPicker);
    expect(pickerFinder, findsOneWidget);

    final picker = tester.widget<TimerCustomPicker>(pickerFinder);
    expect(picker.enabled, isFalse);
  });

  testWidgets(
    'finished dialog shows restart and dismiss buttons, restart triggers StartTimer',
    (tester) async {
      final states = Stream<TimerState>.fromIterable([
        const TimerState(status: TimerStatus.idle),
        const TimerState(
          status: TimerStatus.finished,
          duration: Duration(minutes: 5),
          activePresetId: 'preset_123',
          sound: 'Dancing Flames',
        ),
      ]);

      when(() => mockTimerBloc.state).thenReturn(
        const TimerState(
          status: TimerStatus.finished,
          duration: Duration(minutes: 5),
          activePresetId: 'preset_123',
          sound: 'Dancing Flames',
        ),
      );
      when(() => mockTimerBloc.stream).thenAnswer((_) => states);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify dialog elements
      expect(find.text('Timer Finished'), findsOneWidget);
      expect(find.text('Dancing Flames'), findsOneWidget);
      expect(find.text('05:00 mins'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Restart'), findsOneWidget);

      // Tap Restart
      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();

      // Verify events were dispatched
      verify(() => mockTimerBloc.add(ResetTimerToIdle())).called(1);
      verify(
        () => mockTimerBloc.add(
          const StartTimer(Duration(minutes: 5), presetId: 'preset_123'),
        ),
      ).called(1);
    },
  );
}
