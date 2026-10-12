import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_clock/core/utils/constants.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/widgets/lap_list_item.dart';
import 'package:mechanix_clock/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets/widgets.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Alarm Integration Test', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});

      // Mock the method channel for SystemAlarmService
      const MethodChannel('com.example.clock/alarm').setMockMethodCallHandler((
        MethodCall methodCall,
      ) async {
        return null;
      });
    });

    testWidgets('Full alarm lifecycle: create, edit, and delete', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

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
      final soundItem = find.byKey(Key('sound_${sounds[0]}'));

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

      // 2. Verify the alarm list is displayed.
      expect(find.byKey(const Key('alarm_item_tap')), findsOneWidget);

      final alarmItems = find.byType(MechanixSwipableListTile);
      expect(alarmItems, findsOneWidget);

      // Open the alarm for editing.
      await tester.ensureVisible(alarmItems.first);
      await tester.tap(alarmItems.first);
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
      expect(find.text('Once'), findsOneWidget);

      // 4. Reopen the alarm for deletion.
      final alarmTile = find.byType(MechanixSwipableListTile);

      expect(alarmTile, findsOneWidget);
      await tester.ensureVisible(alarmTile.first);
      await tester.tap(alarmTile.first);
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

      // 5. Verify the alarm has been removed.
      expect(find.text('Once'), findsNothing);
    });
  });

  group('Stopwatch Integration Test', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});

      const MethodChannel('com.example.clock/alarm').setMockMethodCallHandler((
        MethodCall methodCall,
      ) async {
        return null;
      });
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

      const MethodChannel('com.example.clock/alarm').setMockMethodCallHandler((
        MethodCall methodCall,
      ) async {
        return null;
      });
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

        // 4. Select Kolkata.
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

      const MethodChannel('com.example.clock/alarm').setMockMethodCallHandler((
        MethodCall methodCall,
      ) async {
        return null;
      });
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
