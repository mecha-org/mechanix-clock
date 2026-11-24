import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_state.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/features/alarm/data/repository/alarm_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAlarmRepository extends Mock implements AlarmRepository {}

void main() {
  late MockAlarmRepository repository;
  late StreamController<void> changes;
  late StreamController<void> started;

  const testAlarm = Alarm(
    id: '1',
    hour: 7,
    minute: 15,
    isAm: true,
    repeatDays: [],
    sound: 'digital_beeps',
    isSnoozeEnabled: true,
    isActive: true,
  );

  setUpAll(() => registerFallbackValue(testAlarm));

  setUp(() {
    repository = MockAlarmRepository();
    changes = StreamController<void>.broadcast();
    started = StreamController<void>.broadcast();
    when(() => repository.changes).thenAnswer((_) => changes.stream);
    when(() => repository.serviceStarted).thenAnswer((_) => started.stream);
  });

  tearDown(() async {
    await changes.close();
    await started.close();
  });

  const unavailable = ClockdUnavailable(
    'org.freedesktop.DBus.Error.ServiceUnknown',
    'not running',
  );
  const rejected = ClockdRejected(
    'org.freedesktop.DBus.Error.InvalidArgs',
    "can't read sound",
  );

  AlarmBloc build() => AlarmBloc(repository: repository);

  test('initial state is AlarmInitial', () {
    expect(build().state, AlarmInitial());
  });

  blocTest<AlarmBloc, AlarmState>(
    'LoadAlarms shows the loading state, then the list',
    build: () {
      when(() => repository.getAlarms()).thenAnswer((_) async => [testAlarm]);
      return build();
    },
    act: (bloc) => bloc
      ..add(const LoadAlarms())
      ..add(const LoadAlarms()),
    expect: () => [
      AlarmLoading(),
      const AlarmLoaded([testAlarm]),
      AlarmLoading(),
      const AlarmLoaded([testAlarm]),
    ],
  );

  blocTest<AlarmBloc, AlarmState>(
    'LoadAlarms emits AlarmError when the daemon is unreachable',
    build: () {
      when(() => repository.getAlarms()).thenThrow(unavailable);
      return build();
    },
    act: (bloc) => bloc.add(const LoadAlarms()),
    expect: () => [AlarmLoading(), const AlarmError(unavailable)],
    verify: (bloc) => expect((bloc.state as AlarmError).unavailable, isTrue),
  );

  blocTest<AlarmBloc, AlarmState>(
    'the daemon starting reloads a list that failed to load',
    build: () {
      when(() => repository.getAlarms()).thenAnswer((_) async => [testAlarm]);
      return build();
    },
    seed: () => const AlarmError(unavailable),
    act: (_) => started.add(null),
    expect: () => [
      const AlarmLoaded([testAlarm]),
    ],
  );

  blocTest<AlarmBloc, AlarmState>(
    'AlarmsChanged from the daemon reloads the list without loading state',
    build: () {
      when(() => repository.getAlarms())
          .thenAnswer((_) async => [testAlarm.copyWith(isActive: false)]);
      return build();
    },
    seed: () => const AlarmLoaded([testAlarm]),
    act: (_) => changes.add(null),
    expect: () => [
      AlarmLoaded([testAlarm.copyWith(isActive: false)]),
    ],
  );

  blocTest<AlarmBloc, AlarmState>(
    'AddAlarm adds it to the daemon and keeps the daemon id',
    build: () {
      when(() => repository.addAlarm(any()))
          .thenAnswer((_) async => testAlarm.copyWith(id: 'uuid-1'));
      return build();
    },
    seed: () => const AlarmLoaded([]),
    act: (bloc) => bloc.add(const AddAlarm(testAlarm)),
    expect: () => [
      AlarmLoaded([testAlarm.copyWith(id: 'uuid-1')]),
    ],
    verify: (_) => verify(() => repository.addAlarm(testAlarm)).called(1),
  );

  blocTest<AlarmBloc, AlarmState>(
    'AddAlarm the daemon refuses: shown on the list when nobody waits',
    build: () {
      when(() => repository.addAlarm(any())).thenThrow(rejected);
      when(() => repository.getAlarms()).thenAnswer((_) async => []);
      return build();
    },
    seed: () => const AlarmLoaded([testAlarm]),
    act: (bloc) => bloc.add(const AddAlarm(testAlarm)),
    expect: () => [
      const AlarmLoaded(
        [],
        failure: AlarmFailure(AlarmChange.save, rejected, 1),
      ),
    ],
  );

  test('a save the editor waits for reports its result there', () async {
    when(() => repository.getAlarms()).thenAnswer((_) async => []);
    when(() => repository.addAlarm(any())).thenThrow(rejected);
    final bloc = build();
    bloc.emit(const AlarmLoaded([]));

    final failed = AlarmSaveResult();
    bloc.add(AddAlarm(testAlarm, result: failed));
    expect(await failed.future, rejected);
    // Not shown a second time on the list.
    expect((bloc.state as AlarmLoaded).failure, isNull);

    when(() => repository.addAlarm(any()))
        .thenAnswer((_) async => testAlarm.copyWith(id: 'uuid'));
    final saved = AlarmSaveResult();
    bloc.add(AddAlarm(testAlarm, result: saved));
    expect(await saved.future, isNull);
    await bloc.close();
  });

  blocTest<AlarmBloc, AlarmState>(
    'AddAlarm after a failed load reads the whole list',
    build: () {
      when(() => repository.addAlarm(any()))
          .thenAnswer((_) async => testAlarm.copyWith(id: 'uuid'));
      when(() => repository.getAlarms())
          .thenAnswer((_) async => [testAlarm.copyWith(id: 'uuid')]);
      return build();
    },
    seed: () => const AlarmError(unavailable),
    act: (bloc) => bloc.add(const AddAlarm(testAlarm)),
    expect: () => [
      AlarmLoaded([testAlarm.copyWith(id: 'uuid')]),
    ],
  );

  blocTest<AlarmBloc, AlarmState>(
    'a toggle or delete that fails is reported, list as the daemon has it',
    build: () {
      when(() => repository.setAlarmEnabled(any(), any()))
          .thenThrow(unavailable);
      when(() => repository.deleteAlarm(any())).thenThrow(unavailable);
      when(() => repository.getAlarms()).thenThrow(unavailable);
      return build();
    },
    seed: () => const AlarmLoaded([testAlarm]),
    act: (bloc) => bloc
      ..add(const ToggleAlarm('1'))
      ..add(const DeleteAlarm('1')),
    expect: () => [
      const AlarmLoaded([
        testAlarm,
      ], failure: AlarmFailure(AlarmChange.toggle, unavailable, 1)),
      const AlarmLoaded([
        testAlarm,
      ], failure: AlarmFailure(AlarmChange.delete, unavailable, 2)),
    ],
  );

  group('alarms are listed by time of day', () {
    final night = testAlarm.copyWith(id: 'night', hour: 11, isAm: false);
    final midnight = testAlarm.copyWith(id: 'midnight', hour: 12, isAm: true);
    final noon = testAlarm.copyWith(id: 'noon', hour: 12, isAm: false);
    final morning = testAlarm; // 7:15 AM

    blocTest<AlarmBloc, AlarmState>(
      'when loaded (12 AM first, 12 PM after the mornings)',
      build: () {
        when(() => repository.getAlarms())
            .thenAnswer((_) async => [night, noon, morning, midnight]);
        return build();
      },
      act: (bloc) => bloc.add(const LoadAlarms()),
      expect: () => [
        AlarmLoading(),
        AlarmLoaded([midnight, morning, noon, night]),
      ],
    );

    blocTest<AlarmBloc, AlarmState>(
      'a new alarm goes in its place, not at the bottom',
      build: () {
        when(() => repository.addAlarm(any()))
            .thenAnswer((_) async => midnight);
        return build();
      },
      seed: () => AlarmLoaded([morning, night]),
      act: (bloc) => bloc.add(AddAlarm(midnight)),
      expect: () => [
        AlarmLoaded([midnight, morning, night]),
      ],
    );

    blocTest<AlarmBloc, AlarmState>(
      'an edited alarm moves to its new place',
      build: () {
        when(() => repository.updateAlarm(any())).thenAnswer((_) async {});
        return build();
      },
      seed: () => AlarmLoaded([morning, noon]),
      act: (bloc) =>
          bloc.add(UpdateAlarm(morning.copyWith(hour: 9, isAm: false))),
      expect: () => [
        AlarmLoaded([noon, morning.copyWith(hour: 9, isAm: false)]),
      ],
    );

    blocTest<AlarmBloc, AlarmState>(
      'alarms at the same time keep their order',
      build: () {
        when(() => repository.getAlarms()).thenAnswer(
          (_) async => [morning.copyWith(id: 'b'), morning.copyWith(id: 'a')],
        );
        return build();
      },
      act: (bloc) => bloc.add(const LoadAlarms()),
      expect: () => [
        AlarmLoading(),
        AlarmLoaded([morning.copyWith(id: 'b'), morning.copyWith(id: 'a')]),
      ],
    );
  });

  blocTest<AlarmBloc, AlarmState>(
    'UpdateAlarm updates it in the daemon',
    build: () {
      when(() => repository.updateAlarm(any())).thenAnswer((_) async {});
      return build();
    },
    seed: () => const AlarmLoaded([testAlarm]),
    act: (bloc) => bloc.add(UpdateAlarm(testAlarm.copyWith(hour: 8))),
    expect: () => [
      AlarmLoaded([testAlarm.copyWith(hour: 8)]),
    ],
    verify: (_) =>
        verify(() => repository.updateAlarm(testAlarm.copyWith(hour: 8)))
            .called(1),
  );

  blocTest<AlarmBloc, AlarmState>(
    'DeleteAlarm removes it from the daemon',
    build: () {
      when(() => repository.deleteAlarm(any())).thenAnswer((_) async {});
      return build();
    },
    seed: () => const AlarmLoaded([testAlarm]),
    act: (bloc) => bloc.add(const DeleteAlarm('1')),
    expect: () => [const AlarmLoaded([])],
    verify: (_) => verify(() => repository.deleteAlarm('1')).called(1),
  );

  blocTest<AlarmBloc, AlarmState>(
    'ToggleAlarm switches it in the daemon',
    build: () {
      when(() => repository.setAlarmEnabled(any(), any()))
          .thenAnswer((_) async {});
      return build();
    },
    seed: () => const AlarmLoaded([testAlarm]),
    act: (bloc) => bloc.add(const ToggleAlarm('1')),
    expect: () => [
      AlarmLoaded([testAlarm.copyWith(isActive: false)]),
    ],
    verify: (_) =>
        verify(() => repository.setAlarmEnabled('1', false)).called(1),
  );
}
