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

class MockAlarmBloc extends Mock implements AlarmBloc {}

void main() {
  late MockAlarmBloc mockAlarmBloc;

  setUpAll(() {
    registerFallbackValue(const DeleteAlarm(''));
    registerFallbackValue(LoadAlarms());
  });

  setUp(() {
    mockAlarmBloc = MockAlarmBloc();
    when(() => mockAlarmBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets(
    'AlarmListScreen delete action opens confirmation sheet; CANCEL does not delete, TRASH deletes',
    (tester) async {
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

      expect(find.text('6:30 AM'), findsOneWidget);

      // Find and tap the swipe delete action button
      final deleteActionBtn = find.byKey(
        const Key('alarm_list_delete_button_alarm_test_1'),
      );
      expect(deleteActionBtn, findsOneWidget);
      await tester.tap(deleteActionBtn);
      await tester.pumpAndSettle();

      // Verify confirmation sheet opens
      expect(find.text('Delete alarm?'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('TRASH'), findsOneWidget);

      // Tap CANCEL
      await tester.tap(find.byKey(const Key('delete_alarm_cancel_button')));
      await tester.pumpAndSettle();

      // Verify sheet is dismissed and DeleteAlarm is not called
      expect(find.text('Delete alarm?'), findsNothing);
      verifyNever(() => mockAlarmBloc.add(any<DeleteAlarm>()));

      // Tap delete action button again
      await tester.tap(deleteActionBtn);
      await tester.pumpAndSettle();

      // Tap TRASH button
      await tester.tap(find.byKey(const Key('delete_alarm_trash_button')));
      await tester.pumpAndSettle();

      // Verify DeleteAlarm is dispatched
      verify(
        () => mockAlarmBloc.add(const DeleteAlarm('alarm_test_1')),
      ).called(1);
    },
  );
}
