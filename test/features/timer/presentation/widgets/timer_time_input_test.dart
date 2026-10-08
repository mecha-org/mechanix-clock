import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/time_picker_column.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_custom_picker.dart';

void main() {
  testWidgets('TimerCustomPicker renders 3 PickerColumns and colons', (
    tester,
  ) async {
    int hours = 0;
    int minutes = 1;
    int seconds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return TimerCustomPicker(
                selectedHours: hours,
                selectedMinutes: minutes,
                selectedSeconds: seconds,
                onHoursChanged: (v) => setState(() => hours = v),
                onMinutesChanged: (v) => setState(() => minutes = v),
                onSecondsChanged: (v) => setState(() => seconds = v),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(TimerCustomPicker), findsOneWidget);
    expect(find.byType(PickerColumn), findsNWidgets(3));
    expect(find.text(':'), findsNWidgets(2));
  });
}
