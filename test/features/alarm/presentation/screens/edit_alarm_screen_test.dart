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
        sound: 'Dancing Flames',
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
        sound: 'Dancing Flames',
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
        sound: 'Dancing Flames',
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
}
