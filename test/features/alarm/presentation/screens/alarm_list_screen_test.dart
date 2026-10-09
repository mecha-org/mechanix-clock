import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
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
      sound: 'Dancing Flames',
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
    expect(find.text('6:30 AM'), findsOneWidget);

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
}
