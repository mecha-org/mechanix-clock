import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_event.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_state.dart';
import 'package:mechanix_clock/features/world_clock/data/models/world_clock_model.dart';
import 'package:mechanix_clock/features/world_clock/data/repository/world_clock_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockWorldClockRepository extends Mock implements WorldClockRepository {}

void main() {
  late WorldClockRepository repository;
  late WorldClockBloc bloc;

  const testClock = WorldClock(
    id: '1',
    cityName: 'London',
    country: 'UK',
    timezoneId: 'Europe/London',
  );

  setUpAll(() {
    registerFallbackValue(
      const WorldClock(id: '', cityName: '', country: '', timezoneId: ''),
    );
  });

  setUp(() {
    repository = MockWorldClockRepository();
    bloc = WorldClockBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('WorldClockBloc', () {
    test('initial state is WorldClockInitial', () {
      expect(bloc.state, equals(WorldClockInitial()));
    });

    blocTest<WorldClockBloc, WorldClockState>(
      'emits [WorldClockLoading, WorldClockLoaded] when LoadWorldClocks is added',
      build: () {
        when(
          () => repository.getWorldClocks(),
        ).thenAnswer((_) async => [testClock]);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadWorldClocks()),
      expect: () => [
        WorldClockLoading(),
        const WorldClockLoaded([testClock]),
      ],
    );

    blocTest<WorldClockBloc, WorldClockState>(
      'adds a new clock and emits [WorldClockLoaded] when AddWorldClock is added',
      build: () {
        when(() => repository.getWorldClocks()).thenAnswer((_) async => []);
        when(
          () => repository.saveWorldClocks(any()),
        ).thenAnswer((_) async => {});
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AddWorldClock(
          cityName: 'New York',
          country: 'USA',
          timezoneId: 'America/New_York',
        ),
      ),
      expect: () => [
        isA<WorldClockLoaded>()
            .having((s) => s.clocks.length, 'clocks count', 1)
            .having((s) => s.clocks.first.cityName, 'city name', 'New York'),
      ],
    );

    blocTest<WorldClockBloc, WorldClockState>(
      'does not add duplicate clock if it already exists',
      build: () {
        return bloc;
      },
      seed: () => const WorldClockLoaded([testClock]),
      act: (bloc) => bloc.add(
        const AddWorldClock(
          cityName: 'London',
          country: 'UK',
          timezoneId: 'Europe/London',
        ),
      ),
      expect: () => <WorldClockState>[],
    );

    blocTest<WorldClockBloc, WorldClockState>(
      'deletes clock and emits [WorldClockLoaded] when DeleteWorldClock is added',
      build: () {
        when(
          () => repository.saveWorldClocks(any()),
        ).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => const WorldClockLoaded([testClock]),
      act: (bloc) => bloc.add(const DeleteWorldClock('1')),
      expect: () => [const WorldClockLoaded([])],
    );

    blocTest<WorldClockBloc, WorldClockState>(
      'reorders clocks and emits [WorldClockLoaded] when ReorderWorldClocks is added',
      build: () {
        when(
          () => repository.saveWorldClocks(any()),
        ).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => const WorldClockLoaded([
        WorldClock(
          id: '1',
          cityName: 'London',
          country: 'UK',
          timezoneId: 'Europe/London',
        ),
        WorldClock(
          id: '2',
          cityName: 'New York',
          country: 'USA',
          timezoneId: 'America/New_York',
        ),
      ]),
      act: (bloc) => bloc.add(const ReorderWorldClocks(0, 2)),
      expect: () => [
        const WorldClockLoaded([
          WorldClock(
            id: '2',
            cityName: 'New York',
            country: 'USA',
            timezoneId: 'America/New_York',
          ),
          WorldClock(
            id: '1',
            cityName: 'London',
            country: 'UK',
            timezoneId: 'Europe/London',
          ),
        ]),
      ],
    );
  });
}
