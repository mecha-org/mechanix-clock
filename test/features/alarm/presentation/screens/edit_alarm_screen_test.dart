import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_state.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/edit_alarm_screen.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/time_picker.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/time_picker_column.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAlarmBloc extends MockBloc<AlarmEvent, AlarmState>
    implements AlarmBloc {}

void main() {
  late MockAlarmBloc mockAlarmBloc;

  setUpAll(() {
    registerFallbackValue(const DeleteAlarm(''));
    registerFallbackValue(LoadAlarms());
  });

  setUp(() {
    mockAlarmBloc = MockAlarmBloc();
    when(() => mockAlarmBloc.state).thenReturn(const AlarmLoaded([]));
  });

  testWidgets(
    'EditAlarmScreen renders CustomTimePicker wheel scroll correctly',
    (tester) async {
      final testAlarm = const Alarm(
        id: 'alarm_1',
        hour: 7,
        minute: 10,
        isAm: true,
        repeatDays: [1, 2, 3],
        sound: 'digital_beeps',
        isSnoozeEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: BlocProvider<AlarmBloc>.value(
            value: mockAlarmBloc,
            child: EditAlarmScreen(alarm: testAlarm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomTimePicker), findsOneWidget);
      expect(find.byType(PickerColumn), findsNWidgets(2));
      expect(find.text(':'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping delete shows confirmation dialog with CANCEL and DELETE; CANCEL dismisses without deleting',
    (tester) async {
      final testAlarm = const Alarm(
        id: 'alarm_1',
        hour: 7,
        minute: 10,
        isAm: true,
        repeatDays: [1, 2, 3],
        sound: 'digital_beeps',
        isSnoozeEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: BlocProvider<AlarmBloc>.value(
            value: mockAlarmBloc,
            child: EditAlarmScreen(alarm: testAlarm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the delete icon button in app bar
      await tester.tap(find.byKey(const Key('delete_alarm_button')));
      await tester.pumpAndSettle();

      // Verify confirmation sheet elements
      expect(find.text('Delete alarm?'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);

      // Tap CANCEL
      await tester.tap(find.byKey(const Key('delete_alarm_cancel_button')));
      await tester.pumpAndSettle();

      // Verify sheet is dismissed and DeleteAlarm was NOT dispatched
      expect(find.text('Delete alarm?'), findsNothing);
      verifyNever(() => mockAlarmBloc.add(const DeleteAlarm('alarm_1')));
    },
  );

  testWidgets(
    'Tapping DELETE in confirmation dialog dispatches DeleteAlarm and closes screen',
    (tester) async {
      final testAlarm = const Alarm(
        id: 'alarm_1',
        hour: 7,
        minute: 10,
        isAm: true,
        repeatDays: [1, 2, 3],
        sound: 'digital_beeps',
        isSnoozeEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: BlocProvider<AlarmBloc>.value(
            value: mockAlarmBloc,
            child: EditAlarmScreen(alarm: testAlarm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the delete icon button
      final deleteBtn = find.byKey(const Key('delete_alarm_button'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Tap DELETE button
      await tester.tap(find.byKey(const Key('delete_alarm_delete_button')));
      await tester.pumpAndSettle();

      // Verify DeleteAlarm event was dispatched
      verify(() => mockAlarmBloc.add(const DeleteAlarm('alarm_1'))).called(1);
    },
  );

  testWidgets('a label can be added and is saved with the alarm', (
    tester,
  ) async {
    const testAlarm = Alarm(
      id: 'alarm_1',
      hour: 7,
      minute: 10,
      isAm: true,
      repeatDays: [],
      sound: 'digital_beeps',
      isSnoozeEnabled: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: BlocProvider<AlarmBloc>.value(
          value: mockAlarmBloc,
          child: const EditAlarmScreen(alarm: testAlarm),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter label'), findsOneWidget);

    // The label row opens the label sheet.
    await tester.tap(find.byKey(const Key('option_label')));
    await tester.pumpAndSettle();
    expect(find.text('Edit label'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('alarm_label_field')),
        matching: find.byType(EditableText),
      ),
      ' Medicine ',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('label_sheet_save')));
    await tester.pumpAndSettle();

    // Sheet closed, label shown on the row.
    expect(find.text('Edit label'), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('alarm_label_value'))).data,
      'Medicine',
    );

    await tester.tap(find.byKey(const Key('save_alarm_button')));
    await tester.pumpAndSettle();

    verify(
      () =>
          mockAlarmBloc.add(UpdateAlarm(testAlarm.copyWith(label: 'Medicine'))),
    ).called(1);
  });

  testWidgets('a label too long cannot be saved', (tester) async {
    const testAlarm = Alarm(
      id: 'alarm_1',
      hour: 7,
      minute: 10,
      isAm: true,
      repeatDays: [],
      sound: 'digital_beeps',
      isSnoozeEnabled: true,
      label: 'Gym',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: BlocProvider<AlarmBloc>.value(
          value: mockAlarmBloc,
          child: const EditAlarmScreen(alarm: testAlarm),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_label_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('alarm_label_field')),
        matching: find.byType(EditableText),
      ),
      'x' * 41,
    );
    await tester.pumpAndSettle();

    expect(find.text('Label can be at most 40 characters'), findsOneWidget);
    await tester.tap(find.byKey(const Key('label_sheet_save')));
    await tester.pumpAndSettle();
    // Still open; the row keeps the old label.
    expect(find.text('Edit label'), findsOneWidget);

    await tester.tap(find.byKey(const Key('label_sheet_back')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('alarm_label_value'))).data,
      'Gym',
    );
  });

  Future<void> pumpEdit(WidgetTester tester, Alarm alarm) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: BlocProvider<AlarmBloc>.value(
          value: mockAlarmBloc,
          child: EditAlarmScreen(alarm: alarm),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const snoozeAlarm = Alarm(
    id: 'alarm_1',
    hour: 7,
    minute: 10,
    isAm: true,
    repeatDays: [],
    sound: 'digital_beeps',
    isSnoozeEnabled: true,
  );

  testWidgets('snooze duration can be picked and is saved', (tester) async {
    await pumpEdit(tester, snoozeAlarm);

    final tile = find.byKey(const Key('option_snooze_duration'));
    await tester.ensureVisible(tile);
    expect(find.text('10 min'), findsOneWidget);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('snooze_duration_5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('snooze_duration_done_button')));
    await tester.pumpAndSettle();

    expect(find.text('5 min'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save_alarm_button')));
    await tester.pumpAndSettle();

    verify(
      () => mockAlarmBloc.add(
        UpdateAlarm(snoozeAlarm.copyWith(snoozeMinutes: 5)),
      ),
    ).called(1);
  });

  testWidgets('snooze duration can\'t be opened with snooze off', (
    tester,
  ) async {
    await pumpEdit(tester, snoozeAlarm.copyWith(isSnoozeEnabled: false));

    final tile = find.byKey(const Key('option_snooze_duration'));
    await tester.ensureVisible(tile);
    await tester.tap(tile, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('snooze_duration_5')), findsNothing);
  });

  group('duplicates (GNOME style)', () {
    const message = 'An alarm already exists for this time';

    // Changes the label (so Save is enabled) and taps Save.
    Future<void> saveWithLabel(WidgetTester tester, Alarm alarm) async {
      await pumpEdit(tester, alarm);
      // Let a duplicate snackbar shown on open close, so it doesn't cover Save.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final tile = find.byKey(const Key('option_label'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('alarm_label_field')),
          matching: find.byType(EditableText),
        ),
        'Gym',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('label_sheet_save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_alarm_button')));
      await tester.pump();
    }

    testWidgets('same time and repeat days: snackbar, not saved', (
      tester,
    ) async {
      when(() => mockAlarmBloc.state).thenReturn(
        AlarmLoaded([snoozeAlarm, snoozeAlarm.copyWith(id: 'other')]),
      );
      await saveWithLabel(tester, snoozeAlarm);

      expect(find.text(message), findsWidgets);
      verifyNever(() => mockAlarmBloc.add(any()));
      expect(find.byType(EditAlarmScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('same time on other days is a duplicate too', (tester) async {
      when(() => mockAlarmBloc.state).thenReturn(
        AlarmLoaded([
          snoozeAlarm,
          snoozeAlarm.copyWith(id: 'other', repeatDays: [1, 2, 3, 4, 5]),
        ]),
      );
      await saveWithLabel(tester, snoozeAlarm);

      expect(find.text(message), findsWidgets);
      verifyNever(() => mockAlarmBloc.add(any()));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('another time is saved', (tester) async {
      when(() => mockAlarmBloc.state).thenReturn(
        AlarmLoaded([
          snoozeAlarm,
          snoozeAlarm.copyWith(id: 'other', minute: 11),
          snoozeAlarm.copyWith(id: 'pm', isAm: false),
        ]),
      );
      await saveWithLabel(tester, snoozeAlarm);

      expect(find.text(message), findsNothing);
      verify(
        () => mockAlarmBloc.add(
          UpdateAlarm(snoozeAlarm.copyWith(label: 'Gym')),
        ),
      ).called(1);
    });

    testWidgets('opening an alarm that clashes says so straight away', (
      tester,
    ) async {
      // An old alarm, switched off, at the time of one that is on.
      final old = snoozeAlarm.copyWith(isActive: false);
      when(() => mockAlarmBloc.state).thenReturn(
        AlarmLoaded([old, snoozeAlarm.copyWith(id: 'other')]),
      );
      await pumpEdit(tester, old);

      expect(find.text(message), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('opening an alarm that does not clash shows nothing', (
      tester,
    ) async {
      when(
        () => mockAlarmBloc.state,
      ).thenReturn(const AlarmLoaded([snoozeAlarm]));
      await pumpEdit(tester, snoozeAlarm);

      expect(find.text(message), findsNothing);
    });

    testWidgets('an alarm at the same time that is off does not count', (
      tester,
    ) async {
      when(() => mockAlarmBloc.state).thenReturn(
        AlarmLoaded([
          snoozeAlarm,
          snoozeAlarm.copyWith(id: 'other', isActive: false),
        ]),
      );
      await saveWithLabel(tester, snoozeAlarm);

      expect(find.text(message), findsNothing);
      verify(
        () => mockAlarmBloc.add(
          UpdateAlarm(snoozeAlarm.copyWith(label: 'Gym')),
        ),
      ).called(1);
    });

    testWidgets('an alarm is not a duplicate of itself', (tester) async {
      when(
        () => mockAlarmBloc.state,
      ).thenReturn(const AlarmLoaded([snoozeAlarm]));
      await saveWithLabel(tester, snoozeAlarm);

      expect(find.text(message), findsNothing);
      verify(
        () => mockAlarmBloc.add(
          UpdateAlarm(snoozeAlarm.copyWith(label: 'Gym')),
        ),
      ).called(1);
    });
  });
}
