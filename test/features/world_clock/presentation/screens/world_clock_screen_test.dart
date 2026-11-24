import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_event.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_state.dart';
import 'package:mechanix_clock/features/world_clock/data/models/world_clock_model.dart';
import 'package:mechanix_clock/features/world_clock/presentation/screens/world_clock_screen.dart';
import 'package:mechanix_clock/features/world_clock/presentation/widgets/add_city_sheet.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:widgets/widgets.dart';

class MockWorldClockBloc extends Mock implements WorldClockBloc {}

void main() {
  late MockWorldClockBloc mockWorldClockBloc;

  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    registerFallbackValue(const DeleteWorldClock(''));
    registerFallbackValue(
      const AddWorldClock(cityName: '', country: '', timezoneId: ''),
    );
  });

  setUp(() {
    mockWorldClockBloc = MockWorldClockBloc();
    when(() => mockWorldClockBloc.stream)
        .thenAnswer((_) => const Stream.empty());
  });

  const testClocks = [
    WorldClock(
      id: '1',
      cityName: 'Chicago',
      country: 'United States',
      timezoneId: 'America/Chicago',
    ),
    WorldClock(
      id: '2',
      cityName: 'Washington',
      country: 'United States',
      timezoneId: 'America/New_York',
    ),
  ];

  Widget createWidgetUnderTest({required WorldClockState state}) {
    when(() => mockWorldClockBloc.state).thenReturn(state);

    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: BlocProvider<WorldClockBloc>.value(
        value: mockWorldClockBloc,
        child: const WorldClockScreen(),
      ),
    );
  }

  testWidgets('renders empty state when no clocks are saved', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(state: const WorldClockLoaded([])),
    );
    await tester.pump();

    expect(find.text('WORLD CLOCK'), findsOneWidget);
    expect(find.byKey(const Key('world_clock_add_city_button')), findsOneWidget);
  });

  testWidgets('renders clock list with city name and relative UTC offset',
      (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(state: const WorldClockLoaded(testClocks)),
    );
    await tester.pump();

    expect(find.text('Chicago'), findsOneWidget);
    expect(find.text('Washington'), findsOneWidget);
    expect(find.textContaining('UTC'), findsNWidgets(2));
    expect(find.byType(MechanixSwipableList), findsOneWidget);
    expect(find.byType(MechanixFloatingActionButton), findsOneWidget);
  });

  testWidgets('tapping add city FAB opens AddCitySheet', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(state: const WorldClockLoaded(testClocks)),
    );
    await tester.pump();

    final fab = find.byKey(const Key('world_clock_add_city_button'));
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.byType(AddCitySheet), findsOneWidget);
    expect(find.byKey(const Key('add_city_search_field')), findsOneWidget);
  });

  testWidgets(
    'searching a city matches name/country only, not shared timezone IDs',
    (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(state: const WorldClockLoaded(testClocks)),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('world_clock_add_city_button')));
      await tester.pumpAndSettle();

      final searchField = find.descendant(
        of: find.byKey(const Key('add_city_search_field')),
        matching: find.byType(TextField),
      );
      await tester.enterText(searchField, 'kol');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_city_tile_Kolkata')), findsOneWidget);
      // These share the Asia/Kolkata timezone but must not match "kol".
      expect(find.byKey(const Key('add_city_tile_Bengaluru')), findsNothing);
      expect(find.byKey(const Key('add_city_tile_Mumbai')), findsNothing);
      expect(find.byKey(const Key('add_city_tile_New_Delhi')), findsNothing);
    },
  );

  testWidgets('city list in the search sheet is sorted alphabetically', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidgetUnderTest(state: const WorldClockLoaded(testClocks)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('world_clock_add_city_button')));
    await tester.pumpAndSettle();

    final searchField = find.descendant(
      of: find.byKey(const Key('add_city_search_field')),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchField, 'india');
    await tester.pumpAndSettle();

    // Declared in city_model.dart as Kolkata, Bengaluru, Mumbai, New Delhi.
    const expectedOrder = ['Bengaluru', 'Kolkata', 'Mumbai', 'New_Delhi'];
    final positions = expectedOrder
        .map(
          (name) =>
              tester.getTopLeft(find.byKey(Key('add_city_tile_$name'))).dy,
        )
        .toList();

    for (var i = 1; i < positions.length; i++) {
      expect(
        positions[i],
        greaterThan(positions[i - 1]),
        reason: '${expectedOrder[i]} should appear after ${expectedOrder[i - 1]}',
      );
    }
  });
}
