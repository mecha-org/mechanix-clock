import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/world_clock/data/models/world_clock_model.dart';
import 'package:mechanix_clock/features/world_clock/presentation/screens/timezone_details_screen.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  const testClock = WorldClock(
    id: '1',
    cityName: 'London',
    country: 'UK',
    timezoneId: 'Europe/London',
  );

  Widget createWidgetUnderTest({double width = 800, double height = 600}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: const TimezoneDetailsScreen(clock: testClock),
      ),
    );
  }

  testWidgets('renders all timezone details successfully', (tester) async {
    // Set a normal screen size
    await tester.binding.setSurfaceSize(const Size(800, 600));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify city name and country are displayed
    expect(find.text('London'), findsNWidgets(2));
    expect(find.text('UK'), findsOneWidget);

    // Verify detail labels are present
    expect(find.text('Timezone'), findsOneWidget);
    expect(find.text('Time Difference'), findsOneWidget);
    expect(find.text('Day/Night Status'), findsOneWidget);

    // Verify values are present
    expect(find.text('Europe/London'), findsOneWidget);

    // Reset surface size
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('does not overflow on small screens', (tester) async {
    // Set a very small screen size (width 400, height 300)
    await tester.binding.setSurfaceSize(const Size(400, 300));

    await tester.pumpWidget(createWidgetUnderTest(width: 400, height: 300));
    await tester.pump();

    // Assert that no layout exceptions or overflow warnings were thrown
    expect(tester.takeException(), isNull);

    // Verify London and other elements are still rendered
    expect(find.text('London'), findsNWidgets(2));
    expect(find.text('Timezone'), findsOneWidget);

    // Reset surface size
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('handles missing/invalid timezone ID gracefully', (tester) async {
    const invalidClock = WorldClock(
      id: '2',
      cityName: 'Unknown City',
      country: 'Unknown Country',
      timezoneId: 'Invalid/Timezone',
    );
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', '')],
        home: TimezoneDetailsScreen(clock: invalidClock),
      ),
    );
    await tester.pump();

    // Verify it renders and displays the screen without crashing
    expect(find.text('Unknown City'), findsNWidgets(2));
    expect(find.text('Invalid/Timezone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
