import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_state.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/alarm_list_screen.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

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
  });

  testWidgets('AlarmListScreen delete action opens confirmation sheet; '
      'CANCEL does not delete, DELETE deletes', (tester) async {
    final alarm = const Alarm(
      id: 'alarm_test_1',
      hour: 6,
      minute: 30,
      isAm: true,
      repeatDays: [1, 2],
      sound: 'digital_beeps',
      isSnoozeEnabled: true,
    );

    when(() => mockAlarmBloc.state).thenReturn(AlarmLoaded([alarm]));

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
          child: const AlarmListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the alarm is displayed.
    expect(find.text('06:30 AM'), findsOneWidget);

    final alarmTile = find.byType(MechanixSwipableListTile);
    expect(alarmTile, findsOneWidget);

    // Swipe left to reveal the delete action.
    await tester.drag(alarmTile, const Offset(-400, 0));
    await tester.pumpAndSettle();

    final deleteActionButton = find.byKey(
      const Key('alarm_list_delete_button_alarm_test_1'),
    );

    expect(deleteActionButton, findsOneWidget);

    // Tap the swipe action to open the confirmation sheet.
    await tester.tap(deleteActionButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete alarm?'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('DELETE'), findsOneWidget);

    // Cancel deletion.
    await tester.tap(find.byKey(const Key('delete_alarm_cancel_button')));
    await tester.pumpAndSettle();

    // Verify the confirmation sheet is dismissed.
    expect(find.text('Delete alarm?'), findsNothing);

    // Verify no delete event was dispatched.
    verifyNever(() => mockAlarmBloc.add(const DeleteAlarm('alarm_test_1')));

    // Swipe left again to reveal the delete action.
    await tester.drag(alarmTile, const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(deleteActionButton, findsOneWidget);

    // Open the confirmation sheet again.
    await tester.tap(deleteActionButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete alarm?'), findsOneWidget);

    // Confirm deletion.
    await tester.tap(find.byKey(const Key('delete_alarm_delete_button')));
    await tester.pumpAndSettle();

    // Verify the delete event was dispatched exactly once.
    verify(
      () => mockAlarmBloc.add(const DeleteAlarm('alarm_test_1')),
    ).called(1);
  });

  testWidgets('shows the alarm label under the time', (tester) async {
    const alarm = Alarm(
      id: 'labelled',
      hour: 8,
      minute: 0,
      isAm: true,
      repeatDays: [],
      sound: 'digital_beeps',
      isSnoozeEnabled: true,
      label: 'Medicine',
    );
    when(() => mockAlarmBloc.state).thenReturn(const AlarmLoaded([alarm]));

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
          child: const AlarmListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('alarm_label_labelled')), findsOneWidget);
    expect(find.text('Medicine'), findsOneWidget);
  });

  testWidgets('says when the clock service is down, and Retry reloads', (
    tester,
  ) async {
    when(() => mockAlarmBloc.state).thenReturn(
      const AlarmError(
        ClockdUnavailable('org.freedesktop.DBus.Error.ServiceUnknown', ''),
      ),
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
          child: const AlarmListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Clock service isn't running"), findsOneWidget);
    await tester.tap(find.byKey(const Key('alarms_retry_button')));
    verify(() => mockAlarmBloc.add(const LoadAlarms())).called(1);
  });

  group('on/off switch: one alarm on per time', () {
    const on = Alarm(
      id: 'on',
      hour: 4,
      minute: 27,
      isAm: false,
      repeatDays: [],
      sound: 'digital_beeps',
      isSnoozeEnabled: true,
    );
    final off = on.copyWith(id: 'off', repeatDays: [3], isActive: false);

    Future<void> pumpList(WidgetTester tester, List<Alarm> alarms) async {
      when(() => mockAlarmBloc.state).thenReturn(AlarmLoaded(alarms));
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
            child: const AlarmListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder switchOf(String id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byType(MechanixSwitch),
    );

    testWidgets('switching on an alarm whose time is taken is refused', (
      tester,
    ) async {
      await pumpList(tester, [on, off]);

      await tester.tap(switchOf('off'));
      await tester.pump();

      expect(find.text('An alarm already exists for this time'), findsOneWidget);
      verifyNever(() => mockAlarmBloc.add(any()));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('switching off is always allowed', (tester) async {
      await pumpList(tester, [on, off]);

      await tester.tap(switchOf('on'));
      await tester.pump();

      verify(() => mockAlarmBloc.add(const ToggleAlarm('on'))).called(1);
    });

    testWidgets('switching on is allowed when the time is free', (
      tester,
    ) async {
      await pumpList(tester, [on.copyWith(isActive: false), off]);

      await tester.tap(switchOf('off'));
      await tester.pump();

      verify(() => mockAlarmBloc.add(const ToggleAlarm('off'))).called(1);
    });
  });
}
