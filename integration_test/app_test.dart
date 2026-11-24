import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_clock/core/utils/alarm_sounds.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_state.dart';
import 'package:mechanix_clock/features/navigation/presentation/screens/main_navigation_container.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/widgets/lap_list_item.dart';
import 'package:mechanix_clock/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets/widgets.dart';

/// Needs mxclockd on the session bus. To keep your own alarms safe, run a
/// throwaway one first: `systemctl --user stop mxclockd;`
/// `XDG_DATA_HOME=$(mktemp -d) mxclockd &`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Alarm Integration Test', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Full alarm lifecycle: create, edit, and delete', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // mxclockd may already hold alarms: track the new one by its id.
      await pumpUntil(
        tester,
        () => tester
            .element(find.byType(MainNavigationContainer))
            .read<AlarmBloc>()
            .state is AlarmLoaded,
      );
      final before = alarmIds(tester);

      // 1. Create a new alarm.
      final addAlarmButton = find.byKey(const Key('add_alarm_button'));

      expect(addAlarmButton, findsOneWidget);
      await tester.ensureVisible(addAlarmButton);
      await tester.tap(addAlarmButton);
      await tester.pumpAndSettle();

      // Verify the alarm editor is open.
      expect(find.byKey(const Key('save_alarm_button')), findsOneWidget);
      expect(find.byKey(const Key('option_repeat')), findsOneWidget);
      expect(find.byKey(const Key('option_sound')), findsOneWidget);

      // Set repeat days.
      final repeatOption = find.byKey(const Key('option_repeat_button'));

      await tester.ensureVisible(repeatOption);
      await tester.tap(repeatOption);
      await tester.pumpAndSettle();

      // Verify the repeat-selection screen is open.
      final monday = find.byKey(const Key('day_1'));
      expect(monday, findsOneWidget);

      // Select Monday.
      await tester.ensureVisible(monday);
      await tester.tap(monday);
      await tester.pumpAndSettle();

      // Save repeat selection.
      final repeatDoneButton = find.byKey(const Key('repeat_done_button'));

      expect(repeatDoneButton, findsOneWidget);
      await tester.ensureVisible(repeatDoneButton);
      await tester.tap(repeatDoneButton);
      await tester.pumpAndSettle();

      // Set sound.
      final soundOption = find.byKey(const Key('option_sound'));

      await tester.ensureVisible(soundOption);
      await tester.tap(soundOption);
      await tester.pumpAndSettle();

      // Select the first sound.
      final soundItem = find.byKey(Key('sound_${alarmSounds[0].id}'));

      expect(soundItem, findsOneWidget);
      await tester.ensureVisible(soundItem);
      await tester.tap(soundItem);
      await tester.pumpAndSettle();

      // Confirm sound selection.
      final soundDoneButton = find.byKey(const Key('sound_done_button'));

      expect(soundDoneButton, findsOneWidget);
      await tester.ensureVisible(soundDoneButton);
      await tester.tap(soundDoneButton);
      await tester.pumpAndSettle();

      // Toggle snooze.
      final snoozeSwitch = find.byKey(const Key('snooze_switch'));

      expect(snoozeSwitch, findsOneWidget);
      await tester.ensureVisible(snoozeSwitch);
      await tester.tap(snoozeSwitch);
      await tester.pumpAndSettle();

      // Save the new alarm.
      final saveAlarmButton = find.byKey(const Key('save_alarm_button'));

      await tester.ensureVisible(saveAlarmButton);
      await tester.tap(saveAlarmButton);
      await tester.pumpAndSettle();

      // 2. Verify the new alarm is listed (and only one was added).
      expect(find.byKey(const Key('alarm_item_tap')), findsOneWidget);

      // Saving goes to mxclockd over D-Bus; wait for the list to update.
      await pumpUntil(tester, () => alarmIds(tester).length > before.length);
      final added = alarmIds(tester).difference(before);
      expect(added, hasLength(1));
      // The "Alarm set for …" snackbar covers the top buttons; let it go.
      await waitForSnackbarToClose(tester);
      final alarmItem = await showAlarm(tester, added.single);

      // Open the alarm for editing.
      await tester.ensureVisible(alarmItem);
      await tester.tap(alarmItem);
      await tester.pumpAndSettle();

      // Verify the editor is open in edit mode.
      expect(find.byKey(const Key('save_alarm_button')), findsOneWidget);
      expect(find.byKey(const Key('delete_alarm_button')), findsOneWidget);

      // 3. Change Repeat to Once.
      final repeat = find.byKey(const Key('option_repeat_button'));

      await tester.ensureVisible(repeat);
      await tester.tap(repeat);
      await tester.pumpAndSettle();

      // Verify the repeat-selection screen is open.
      final day1 = find.byKey(const Key('day_1'));
      expect(day1, findsOneWidget);

      // Select Monday.
      await tester.ensureVisible(day1);
      await tester.tap(day1);
      await tester.pumpAndSettle();

      // Save repeat selection.
      final repeatDone = find.byKey(const Key('repeat_done_button'));

      expect(repeatDone, findsOneWidget);
      await tester.ensureVisible(repeatDone);
      await tester.tap(repeatDone);
      await tester.pumpAndSettle();

      // Save the edited alarm.
      await tester.tap(find.byKey(const Key('save_alarm_button')));
      await tester.pumpAndSettle();

      // Verify the alarm now repeats Once.
      await pumpUntil(
        tester,
        () =>
            find
                .descendant(of: alarmItem, matching: find.text('Once'))
                .evaluate()
                .isNotEmpty,
      );
      await showAlarm(tester, added.single);
      expect(
        find.descendant(of: alarmItem, matching: find.text('Once')),
        findsOneWidget,
      );
      await waitForSnackbarToClose(tester);

      // 4. Reopen the alarm for deletion.
      await showAlarm(tester, added.single);
      await tester.ensureVisible(alarmItem);
      await tester.tap(alarmItem);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_alarm_button')), findsOneWidget);

      // Delete the alarm.
      final deleteAlarmButton = find.byKey(const Key('delete_alarm_button'));

      await tester.ensureVisible(deleteAlarmButton);
      await tester.tap(deleteAlarmButton);
      await tester.pumpAndSettle();

      // Confirm deletion.
      final confirmDeleteButton = find.byKey(
        const Key('delete_alarm_delete_button'),
      );

      expect(confirmDeleteButton, findsOneWidget);
      await tester.ensureVisible(confirmDeleteButton);
      await tester.tap(confirmDeleteButton);
      await tester.pumpAndSettle();

      // 5. Verify the alarm has been removed; the others are untouched.
      await pumpUntil(tester, () => !alarmIds(tester).contains(added.single));
      expect(alarmItem, findsNothing);
      expect(alarmIds(tester), before);
    });
  });

  group('Stopwatch Integration Test', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'Full stopwatch lifecycle: start, record laps, stop, and reset',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 1. Navigate to Stopwatch.
        final stopwatchTab = find.byWidgetPredicate(
          (widget) =>
              widget is ImageIcon &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == ClockIcons.stopwatch,
        );

        expect(stopwatchTab, findsOneWidget);
        await tester.tap(stopwatchTab);
        await tester.pumpAndSettle();

        // 2. Verify the Stopwatch screen.
        expect(find.text('STOPWATCH'), findsOneWidget);

        // 3. Verify the initial Start button.
        final startButton = find.byKey(const Key('stopwatch_start_button'));
        expect(startButton, findsOneWidget);

        // 4. Start the stopwatch.
        await tester.tap(startButton);
        await tester.pumpAndSettle();

        // Verify Stop and Lap buttons are available.
        expect(find.byKey(const Key('stopwatch_stop_button')), findsOneWidget);
        expect(find.byKey(const Key('stopwatch_lap_button')), findsOneWidget);

        // Allow elapsed time to advance.
        await tester.pump(const Duration(seconds: 2));

        // 5. Record the first lap.
        await tester.tap(find.byKey(const Key('stopwatch_lap_button')));
        await tester.pumpAndSettle();

        // Verify the first lap is displayed.
        expect(find.byType(LapListItem), findsOneWidget);
        expect(find.textContaining('01'), findsWidgets);

        // 6. Record a second lap.
        await tester.pump(const Duration(seconds: 2));

        await tester.tap(find.byKey(const Key('stopwatch_lap_button')));
        await tester.pumpAndSettle();

        // Verify two laps are displayed.
        expect(find.byType(LapListItem), findsNWidgets(2));

        // 7. Stop the stopwatch.
        await tester.tap(find.byKey(const Key('stopwatch_stop_button')));
        await tester.pumpAndSettle();

        // Verify the stopwatch has stopped.
        expect(find.byKey(const Key('stopwatch_start_button')), findsOneWidget);
        expect(find.byKey(const Key('stopwatch_reset_button')), findsOneWidget);

        // 8. Reset the stopwatch.
        await tester.tap(find.byKey(const Key('stopwatch_reset_button')));
        await tester.pumpAndSettle();

        // 9. Verify the stopwatch is reset.
        expect(find.byType(LapListItem), findsNothing);

        expect(find.byKey(const Key('stopwatch_start_button')), findsOneWidget);
      },
    );
  });
  group('World Clock Integration Test', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'Full world clock lifecycle: navigate, add city, and delete city',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 1. Navigate to World Clock.
        final worldClockTab = find.byWidgetPredicate(
          (widget) =>
              widget is ImageIcon &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == ClockIcons.worldClock,
        );
        expect(worldClockTab, findsOneWidget);

        await tester.tap(worldClockTab);
        await tester.pumpAndSettle();

        // 2. Verify the World Clock screen.
        expect(find.text('WORLD CLOCK'), findsOneWidget);

        // 3. Open Add City sheet.
        final addCityButton = find.byKey(
          const Key('world_clock_add_city_button'),
        );
        expect(addCityButton, findsOneWidget);

        await tester.tap(addCityButton);
        await tester.pumpAndSettle();

        // 4. Search for Kolkata (the full list is built lazily, so a city
        // further down isn't on screen) and select it.
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('add_city_search_field')),
            matching: find.byType(EditableText),
          ),
          'Kolkata',
        );
        await tester.pumpAndSettle();
        final kolkataTile = find.byKey(const Key('add_city_tile_Kolkata'));
        expect(kolkataTile, findsOneWidget);

        await tester.tap(kolkataTile);
        await tester.pumpAndSettle();

        // 5. Verify Kolkata was added.
        expect(find.text('Kolkata'), findsOneWidget);

        // 6. Find Kolkata's delete button.
        // WorldClockItem uses the key: delete_clock_${clock.id}.
        final kolkataItem = tester.widget<MechanixSwipableListTile>(
          find.ancestor(
            of: find.text('Kolkata'),
            matching: find.byType(MechanixSwipableListTile),
          ),
        );

        // Swipe the Kolkata tile to reveal its delete action.
        await tester.drag(
          find.ancestor(
            of: find.text('Kolkata'),
            matching: find.byType(MechanixSwipableListTile),
          ),
          const Offset(-300, 0),
        );
        await tester.pumpAndSettle();

        // Locate the delete button belonging to Kolkata.
        // The exact clock ID is provided by the WorldClockItem widget.
        final deleteButton = find.descendant(
          of: find.ancestor(
            of: find.text('Kolkata'),
            matching: find.byType(MechanixSwipableListTile),
          ),
          matching: find.byKey(Key('delete_clock_${kolkataItem.key}')),
        );

        if (deleteButton.evaluate().isNotEmpty) {
          await tester.tap(deleteButton);
          await tester.pumpAndSettle();

          // 7. Verify Kolkata was deleted.
          expect(find.text('Kolkata'), findsNothing);
        }
      },
    );
  });

  group('Timer Integration Test', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Timer lifecycle: start, pause, cancel, and preset handling', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to Timer.
      final timerTab = find.byWidgetPredicate(
        (widget) =>
            widget is ImageIcon &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == ClockIcons.timer,
      );

      expect(timerTab, findsOneWidget);
      await tester.tap(timerTab);
      await tester.pumpAndSettle();

      // Verify Timer screen.
      expect(find.text('TIMER'), findsOneWidget);

      // 2. Start the default one-minute timer.
      final startButton = find.byKey(const Key('timer_start_button'));
      expect(startButton, findsOneWidget);

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify the active timer screen.
      expect(
        find.byKey(const Key('timer_goto_setting_button')),
        findsOneWidget,
      );

      // 3. Pause the running timer.
      final pauseButton = find.byWidgetPredicate(
        (widget) =>
            widget is ImageIcon &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == ClockIcons.pause,
      );
      expect(pauseButton, findsOneWidget);

      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // 4. Cancel the timer by navigating to settings.
      // The current TimerScreen doesn't expose a dedicated Cancel text button.
      await tester.tap(find.byKey(const Key('timer_goto_setting_button')));
      await tester.pumpAndSettle();

      // Verify the setting screen is displayed.
      expect(find.byKey(const Key('timer_start_button')), findsOneWidget);

      // 5. Test preset handling.
      // Enter preset-edit mode using the actual key from your implementation.
      final editModeButton = find.byKey(const Key('timer_edit_mode_button'));

      if (editModeButton.evaluate().isNotEmpty) {
        await tester.tap(editModeButton);
        await tester.pumpAndSettle();

        final deletePresetButton = find.byIcon(Icons.remove_circle_outline);
        expect(deletePresetButton, findsAtLeastNWidgets(1));

        await tester.tap(deletePresetButton.first);
        await tester.pumpAndSettle();

        await tester.tap(editModeButton);
        await tester.pumpAndSettle();
      }

      // Add a custom preset.
      final addPresetButton = find.byKey(const Key('timer_add_preset_button'));

      if (addPresetButton.evaluate().isNotEmpty) {
        await tester.tap(addPresetButton);
        await tester.pumpAndSettle();

        final nameField = find.byType(TextField);
        expect(nameField, findsOneWidget);

        await tester.enterText(nameField, 'Tea Timer');
        await tester.pumpAndSettle();

        final saveButton = find.text('Save');
        expect(saveButton, findsOneWidget);

        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(find.text('Tea Timer'), findsOneWidget);
      }
    });
  });
}

/// Ids of the alarms the app has loaded (from the bloc, so rows that are
/// scrolled out of view count too).
Set<String> alarmIds(WidgetTester tester) {
  final state = tester
      .element(find.byType(MainNavigationContainer))
      .read<AlarmBloc>()
      .state;
  return {if (state is AlarmLoaded) ...state.alarms.map((a) => a.id)};
}

/// Scrolls the alarm list until the row of alarm [id] is built and visible.
Future<Finder> showAlarm(WidgetTester tester, String id) async {
  final row = find.byKey(ValueKey(id));
  await tester.scrollUntilVisible(
    row,
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('alarm_item_tap')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  return row;
}

/// Pumps until [done] (D-Bus replies arrive outside the frame clock), for up
/// to [timeout].
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done() && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

/// Waits until the "Alarm set for …" snackbar shown at the top after a save
/// has gone, as it sits over the editor's top-bar buttons.
Future<void> waitForSnackbarToClose(WidgetTester tester) => pumpUntil(
  tester,
  () => find.textContaining('Alarm set for').evaluate().isEmpty,
  timeout: const Duration(seconds: 10),
);
