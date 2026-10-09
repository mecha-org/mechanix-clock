import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/presentation/widgets/timer_preset_item.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

void main() {
  Widget buildTestWidget({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(
        body: MechanixSwipableList(
          child: child,
        ),
      ),
    );
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  testWidgets('TimerPresetItem renders MechanixSwipableListTile with formatted time and subtitle', (
    tester,
  ) async {
    const preset = TimerPreset(
      id: 'p1',
      duration: Duration(minutes: 5),
      name: 'Tea',
    );

    bool selected = false;
    bool played = false;

    await tester.pumpWidget(
      buildTestWidget(
        child: TimerPresetItem(
          preset: preset,
          isEditing: false,
          onSelect: () => selected = true,
          onPlay: () => played = true,
          onDelete: () {},
          onEdit: () {},
          formatPresetDuration: formatDuration,
        ),
      ),
    );

    expect(find.byType(MechanixSwipableListTile), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);

    // Tap tile
    await tester.tap(find.text('05:00'));
    await tester.pump();
    expect(selected, isTrue);

    // Tap play button
    final playBtnFinder = find.byKey(const Key('timer_preset_play_button_p1'));
    expect(playBtnFinder, findsOneWidget);
    await tester.tap(playBtnFinder);
    await tester.pump();
    expect(played, isTrue);
  });

  testWidgets('TimerPresetItem subtitle formats hours, mins, and secs using ARB keys', (
    tester,
  ) async {
    const preset = TimerPreset(
      id: 'p2',
      duration: Duration(hours: 1, minutes: 2, seconds: 3),
    );

    await tester.pumpWidget(
      buildTestWidget(
        child: TimerPresetItem(
          preset: preset,
          isEditing: false,
          onSelect: () {},
          onPlay: () {},
          onDelete: () {},
          onEdit: () {},
          formatPresetDuration: (d) => '01:02:03',
        ),
      ),
    );

    expect(find.text('1 hr 2 mins 3 secs'), findsOneWidget);
  });

  testWidgets('TimerPresetItem subtitle formats 0 duration as 0 min', (
    tester,
  ) async {
    const preset = TimerPreset(
      id: 'p3',
      duration: Duration.zero,
    );

    await tester.pumpWidget(
      buildTestWidget(
        child: TimerPresetItem(
          preset: preset,
          isEditing: false,
          onSelect: () {},
          onPlay: () {},
          onDelete: () {},
          onEdit: () {},
          formatPresetDuration: (d) => '00:00',
        ),
      ),
    );

    expect(find.text('0 min'), findsOneWidget);
  });
}
