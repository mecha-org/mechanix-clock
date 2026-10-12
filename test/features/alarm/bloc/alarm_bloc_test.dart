import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_state.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/features/alarm/data/repository/alarm_repository.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';

class MockAlarmRepository extends Mock implements AlarmRepository {}

class MockSystemAlarmService extends Mock implements SystemAlarmService {}

void main() {
  late AlarmRepository repository;
  late SystemAlarmService systemAlarmService;
  late AlarmBloc alarmBloc;

  const testAlarm = Alarm(
    id: '1',
    hour: 7,
    minute: 15,
    isAm: true,
    repeatDays: [],
    sound: 'Default',
    isSnoozeEnabled: true,
    isActive: true,
  );

  setUp(() {
    repository = MockAlarmRepository();
    systemAlarmService = MockSystemAlarmService();
    alarmBloc = AlarmBloc(
      repository: repository,
      systemAlarmService: systemAlarmService,
    );

    registerFallbackValue(testAlarm);
    registerFallbackValue(DateTime.now());
  });

  tearDown(() {
    alarmBloc.close();
  });

  group('AlarmBloc', () {
    test('initial state is AlarmInitial', () {
      expect(alarmBloc.state, AlarmInitial());
    });

    blocTest<AlarmBloc, AlarmState>(
      'emits [AlarmLoading, AlarmLoaded] when LoadAlarms is added',
      build: () {
        when(() => repository.getAlarms()).thenAnswer((_) async => [testAlarm]);
        return alarmBloc;
      },
      act: (bloc) => bloc.add(LoadAlarms()),
      expect: () => [
        AlarmLoading(),
        const AlarmLoaded([testAlarm]),
      ],
    );

    blocTest<AlarmBloc, AlarmState>(
      'emits [AlarmLoaded] with new alarm when AddAlarm is added',
      build: () {
        when(() => repository.saveAlarms(any())).thenAnswer((_) async => {});
        when(
          () => systemAlarmService.setAlarm(any(), any(), any(), any()),
        ).thenAnswer((_) async => {});
        return alarmBloc;
      },
      seed: () => const AlarmLoaded([]),
      act: (bloc) => bloc.add(const AddAlarm(testAlarm)),
      expect: () => [
        const AlarmLoaded([testAlarm]),
      ],
      verify: (_) {
        verify(() => repository.saveAlarms(any())).called(1);
        verify(
          () => systemAlarmService.setAlarm(any(), any(), any(), any()),
        ).called(1);
      },
    );

    blocTest<AlarmBloc, AlarmState>(
      'emits [AlarmLoaded] with updated alarm when UpdateAlarm is added',
      build: () {
        when(() => repository.saveAlarms(any())).thenAnswer((_) async {});

        when(
          () => systemAlarmService.cancelAlarm(any()),
        ).thenAnswer((_) async {});

        when(
          () => systemAlarmService.setAlarm(any(), any(), any(), any()),
        ).thenAnswer((_) async {});

        return alarmBloc;
      },
      seed: () => const AlarmLoaded([testAlarm]),
      act: (bloc) {
        final updatedAlarm = testAlarm.copyWith(hour: 8);
        bloc.add(UpdateAlarm(updatedAlarm));
      },
      expect: () => [
        AlarmLoaded([testAlarm.copyWith(hour: 8)]),
      ],
      verify: (_) {
        verify(() => repository.saveAlarms(any())).called(1);
      },
    );

    blocTest<AlarmBloc, AlarmState>(
      'emits [AlarmLoaded] without alarm when DeleteAlarm is added',
      build: () {
        when(() => repository.saveAlarms(any())).thenAnswer((_) async => {});
        when(
          () => systemAlarmService.cancelAlarm(any()),
        ).thenAnswer((_) async => {});
        return alarmBloc;
      },
      seed: () => const AlarmLoaded([testAlarm]),
      act: (bloc) => bloc.add(DeleteAlarm(testAlarm.id)),
      expect: () => [const AlarmLoaded([])],
      verify: (_) {
        verify(() => repository.saveAlarms(any())).called(1);
        verify(() => systemAlarmService.cancelAlarm(testAlarm.id)).called(1);
      },
    );

    blocTest<AlarmBloc, AlarmState>(
      'emits [AlarmLoaded] with toggled alarm when ToggleAlarm is added',
      build: () {
        when(() => repository.saveAlarms(any())).thenAnswer((_) async => {});
        when(
          () => systemAlarmService.cancelAlarm(any()),
        ).thenAnswer((_) async => {});
        return alarmBloc;
      },
      seed: () => const AlarmLoaded([testAlarm]),
      act: (bloc) => bloc.add(ToggleAlarm(testAlarm.id)),
      expect: () => [
        AlarmLoaded([testAlarm.copyWith(isActive: false)]),
      ],
      verify: (_) {
        verify(() => repository.saveAlarms(any())).called(1);
        verify(() => systemAlarmService.cancelAlarm(testAlarm.id)).called(1);
      },
    );
  });
}
