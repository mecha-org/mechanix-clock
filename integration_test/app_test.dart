import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_clock/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

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

      // 1. Create New Alarm
      final addAlarmButton = find.byKey(const Key('add_alarm_button'));
      expect(addAlarmButton, findsOneWidget);
      await tester.tap(addAlarmButton);
      await tester.pumpAndSettle();

      // Verify we are on Set Alarm screen
      expect(find.text('Set alarm'), findsOneWidget);

      // Set Time (We won't actually drag pickers in this test as it's complex,
      // but we will interact with other elements)

      // Set Repeat (Monday and Tuesday)
      await tester.tap(find.byKey(const Key('option_repeat')));
      await tester.pumpAndSettle();
      expect(find.text('Repeat'), findsOneWidget);

      await tester.tap(find.byKey(const Key('day_0'))); // Monday
      await tester.tap(find.byKey(const Key('day_1'))); // Tuesday
      await tester.tap(find.byKey(const Key('repeat_done_button')));
      await tester.pumpAndSettle();

      // Set Sound
      await tester.tap(find.byKey(const Key('option_sound')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sound_Siren')));
      await tester.tap(find.byKey(const Key('sound_done_button')));
      await tester.pumpAndSettle();

      // Toggle Snooze
      final snoozeSwitch = find.byKey(const Key('custom_switch'));
      await tester.tap(snoozeSwitch);
      await tester.pumpAndSettle();

      // Save Alarm
      await tester.tap(find.byKey(const Key('save_alarm_button')));
      await tester.pumpAndSettle();

      // Verify alarm is in the list
      expect(find.byKey(const Key('alarm_repeat_days')), findsOneWidget);

      // 2. Edit Alarm
      // Tap on the alarm we just created
      final alarmItem = find.byKey(const Key('alarm_item_tap'));
      await tester.tap(alarmItem, warnIfMissed: false);
      await tester.pumpAndSettle();

      // If still not on edit screen, try tapping by text
      if (find.text('Edit alarm').evaluate().isEmpty) {
        await tester.tap(find.byType(ListView)); // ensure focus?
        await tester.tap(find.textContaining(':')); // Tap the time text
        await tester.pumpAndSettle();
      }

      if (find.text('Edit alarm').evaluate().isEmpty) {
        // One more try with a generic coordinate in the first item area
        await tester.tapAt(const Offset(200, 150));
        await tester.pumpAndSettle();
      }
      expect(find.text('Edit alarm'), findsOneWidget);

      // Change Repeat to Once (deselect Monday and Tuesday)
      await tester.tap(find.byKey(const Key('option_repeat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('day_0')));
      await tester.tap(find.byKey(const Key('day_1')));
      await tester.tap(find.byKey(const Key('repeat_done_button')));
      await tester.pumpAndSettle();

      // Save edited alarm
      await tester.tap(find.byKey(const Key('save_alarm_button')));
      await tester.pumpAndSettle();

      // Verify it now says 'Once'
      expect(find.text('Once'), findsOneWidget);

      // 3. Delete Alarm
      // Re-enter edit screen
      await tester.tap(
        find.byKey(const Key('alarm_item_tap')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      if (find.text('Edit alarm').evaluate().isEmpty) {
        await tester.tap(find.textContaining(':'));
        await tester.pumpAndSettle();
      }

      // Tap delete button
      final deleteButton = find.byKey(const Key('delete_alarm_button'));
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify alarm is gone
      expect(find.text('Once'), findsNothing);
    });
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

        // Navigate to World Clock
        final worldClockTab = find.byIcon(Icons.public_outlined);
        expect(worldClockTab, findsOneWidget);
        await tester.tap(worldClockTab);
        await tester.pumpAndSettle();

        // Verify title
        expect(find.text('World Clock'), findsOneWidget);

        // Tap on Add City button
        final addCityButton = find.byKey(
          const Key('world_clock_add_city_button'),
        );
        expect(addCityButton, findsOneWidget);
        await tester.tap(addCityButton);
        await tester.pumpAndSettle();

        // Tap on Kolkata to add it
        final kolkataTile = find.byKey(const Key('add_city_tile_Kolkata'));
        expect(kolkataTile, findsOneWidget);
        await tester.tap(kolkataTile);
        await tester.pumpAndSettle();

        // Verify Kolkata is added and visible in the list
        expect(find.text('Kolkata'), findsOneWidget);

        // Tap Edit Mode button
        final editModeButton = find.byKey(
          const Key('world_clock_edit_mode_button'),
        );
        expect(editModeButton, findsOneWidget);
        await tester.tap(editModeButton);
        await tester.pumpAndSettle();

        // Verify delete button is present and tap it
        final deleteClockButton = find.byIcon(Icons.remove_circle_outline);
        expect(deleteClockButton, findsOneWidget);
        await tester.tap(deleteClockButton);
        await tester.pumpAndSettle();

        // Exit Edit Mode
        await tester.tap(editModeButton);
        await tester.pumpAndSettle();

        // Verify Kolkata is gone from the screen
        expect(find.text('Kolkata'), findsNothing);
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

      // Navigate to Timer
      final timerTab = find.byIcon(Icons.hourglass_empty_outlined);
      expect(timerTab, findsOneWidget);
      await tester.tap(timerTab);
      await tester.pumpAndSettle();

      // Verify Timer title
      expect(find.text('Timers'), findsOneWidget);

      // Verify start button exists and tap it (starts default 1-minute timer)
      final startButton = find.text('Start');
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify it's in countdown mode (Cancel button should be present)
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);

      // Tap Pause
      final pauseButton = find.text('Pause');
      expect(pauseButton, findsOneWidget);
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // Verify Resume button is shown
      expect(find.text('Resume'), findsOneWidget);

      // Tap Cancel to return to picker
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify Start button is back
      expect(find.text('Start'), findsOneWidget);

      // Enter edit mode to delete the existing 1-minute preset so we can add a new one
      final editModeButton = find.byKey(const Key('timer_edit_mode_button'));
      expect(editModeButton, findsOneWidget);
      await tester.tap(editModeButton);
      await tester.pumpAndSettle();

      // Tap delete on the first preset (which is 1 minute)
      final deletePresetButton = find.byIcon(Icons.remove_circle_outline);
      expect(deletePresetButton, findsAtLeastNWidgets(1));
      await tester.tap(deletePresetButton.first);
      await tester.pumpAndSettle();

      // Exit edit mode
      await tester.tap(editModeButton);
      await tester.pumpAndSettle();

      // Add a Preset (since 1 minute is now free)
      final addPresetButton = find.byKey(const Key('timer_add_preset_button'));
      expect(addPresetButton, findsOneWidget);
      await tester.tap(addPresetButton);
      await tester.pumpAndSettle();

      // Enter name in Dialog
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Tea Timer');
      await tester.pumpAndSettle();

      // Tap Save
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify preset is in the list
      expect(find.text('Tea Timer'), findsOneWidget);

      // Toggle edit mode on presets to delete our custom one
      await tester.tap(editModeButton);
      await tester.pumpAndSettle();

      // Tap delete on the custom preset (which is now at the end of the list)
      await tester.tap(find.byIcon(Icons.remove_circle_outline).last);
      await tester.pumpAndSettle();

      // Exit edit mode
      await tester.tap(editModeButton);
      await tester.pumpAndSettle();

      // Verify preset is deleted
      expect(find.text('Tea Timer'), findsNothing);
    });
  });
}
