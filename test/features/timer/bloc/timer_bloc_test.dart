import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_event.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_state.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/data/repository/timer_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTimerRepository extends Mock implements TimerRepository {}

class MockSystemAlarmService extends Mock implements SystemAlarmService {}

void main() {
  late TimerRepository repository;
  late SystemAlarmService systemAlarmService;
  late TimerBloc timerBloc;

  const testPreset = TimerPreset(id: '1', duration: Duration(minutes: 5));

  setUpAll(() {
    registerFallbackValue(testPreset);
    registerFallbackValue(const Duration(minutes: 5));
  });

  setUp(() {
    repository = MockTimerRepository();
    systemAlarmService = MockSystemAlarmService();

    // Stub platform timer channel calls
    when(
      () => systemAlarmService.setTimer(any(), any()),
    ).thenAnswer((_) async => {});
    when(
      () => systemAlarmService.cancelTimer(any()),
    ).thenAnswer((_) async => {});
    when(
      () => systemAlarmService.playCompletionSound(),
    ).thenAnswer((_) async => {});

    timerBloc = TimerBloc(
      repository: repository,
      systemAlarmService: systemAlarmService,
    );
  });

  tearDown(() {
    timerBloc.close();
  });

  group('TimerBloc', () {
    test('initial state has correct default values', () {
      expect(timerBloc.state.status, TimerStatus.initial);
      expect(timerBloc.state.duration, Duration.zero);
      expect(timerBloc.state.remaining, Duration.zero);
      expect(timerBloc.state.isEditingPresets, false);
    });

    blocTest<TimerBloc, TimerState>(
      'emits correct state when LoadTimerPresets is added',
      build: () {
        when(
          () => repository.getPresets(),
        ).thenAnswer((_) async => [testPreset]);
        when(
          () => repository.getSelectedSound(),
        ).thenAnswer((_) async => 'Wakeup');
        return timerBloc;
      },
      act: (bloc) => bloc.add(LoadTimerPresets()),
      expect: () => [
        const TimerState(
          status: TimerStatus.idle,
          presets: [testPreset],
          sound: 'Wakeup',
        ),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'adds preset and emits new state when AddTimerPreset is added',
      build: () {
        when(() => repository.savePresets(any())).thenAnswer((_) async => {});
        return timerBloc;
      },
      seed: () => const TimerState(presets: []),
      act: (bloc) => bloc.add(const AddTimerPreset(Duration(minutes: 5))),
      expect: () {
        return [
          isA<TimerState>()
              .having((s) => s.presets.length, 'presets count', 1)
              .having(
                (s) => s.presets.first.duration,
                'preset duration',
                const Duration(minutes: 5),
              ),
        ];
      },
    );

    blocTest<TimerBloc, TimerState>(
      'adds preset with name and emits new state when AddTimerPreset with name is added',
      build: () {
        when(() => repository.savePresets(any())).thenAnswer((_) async => {});
        return timerBloc;
      },
      seed: () => const TimerState(presets: []),
      act: (bloc) =>
          bloc.add(const AddTimerPreset(Duration(minutes: 5), name: 'Tea')),
      expect: () {
        return [
          isA<TimerState>()
              .having((s) => s.presets.length, 'presets count', 1)
              .having((s) => s.presets.first.name, 'preset name', 'Tea'),
        ];
      },
    );

    blocTest<TimerBloc, TimerState>(
      'renames preset and emits new state when UpdateTimerPreset is added',
      build: () {
        when(() => repository.savePresets(any())).thenAnswer((_) async => {});
        return timerBloc;
      },
      seed: () => const TimerState(
        presets: [
          TimerPreset(id: '1', duration: Duration(minutes: 5), name: 'Tea'),
        ],
      ),
      act: (bloc) =>
          bloc.add(const UpdateTimerPreset(id: '1', name: 'Green Tea')),
      expect: () => [
        const TimerState(
          presets: [
            TimerPreset(
              id: '1',
              duration: Duration(minutes: 5),
              name: 'Green Tea',
            ),
          ],
        ),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'deletes preset and emits new state when DeleteTimerPreset is added',
      build: () {
        when(() => repository.savePresets(any())).thenAnswer((_) async => {});
        return timerBloc;
      },
      seed: () => const TimerState(presets: [testPreset]),
      act: (bloc) => bloc.add(const DeleteTimerPreset('1')),
      expect: () => [const TimerState(presets: [])],
    );

    blocTest<TimerBloc, TimerState>(
      'toggles edit mode when ToggleEditPresetsMode is added',
      build: () => timerBloc,
      act: (bloc) => bloc.add(ToggleEditPresetsMode()),
      expect: () => [const TimerState(isEditingPresets: true)],
    );

    blocTest<TimerBloc, TimerState>(
      'reorders presets and saves to repository',
      build: () {
        when(() => repository.savePresets(any())).thenAnswer((_) async => {});
        return timerBloc;
      },
      seed: () => const TimerState(
        presets: [
          TimerPreset(id: '1', duration: Duration(minutes: 1)),
          TimerPreset(id: '2', duration: Duration(minutes: 2)),
          TimerPreset(id: '3', duration: Duration(minutes: 3)),
        ],
      ),
      act: (bloc) => bloc.add(const ReorderTimerPresets(0, 1)),
      expect: () => [
        const TimerState(
          presets: [
            TimerPreset(id: '2', duration: Duration(minutes: 2)),
            TimerPreset(id: '1', duration: Duration(minutes: 1)),
            TimerPreset(id: '3', duration: Duration(minutes: 3)),
          ],
        ),
      ],
      verify: (_) {
        verify(
          () => repository.savePresets(const [
            TimerPreset(id: '2', duration: Duration(minutes: 2)),
            TimerPreset(id: '1', duration: Duration(minutes: 1)),
            TimerPreset(id: '3', duration: Duration(minutes: 3)),
          ]),
        ).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'starts timer countdown and does not add duration to presets',
      build: () {
        return timerBloc;
      },
      act: (bloc) => bloc.add(const StartTimer(Duration(seconds: 10))),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'timer status', TimerStatus.running)
            .having(
              (s) => s.duration,
              'timer duration',
              const Duration(seconds: 10),
            )
            .having(
              (s) => s.remaining,
              'timer remaining',
              const Duration(seconds: 10),
            )
            .having((s) => s.presets.length, 'presets count', 0),
      ],
      verify: (_) {
        verify(
          () => systemAlarmService.setTimer(any(), const Duration(seconds: 10)),
        ).called(1);
        verifyNever(() => repository.savePresets(any()));
      },
    );

    blocTest<TimerBloc, TimerState>(
      'pauses timer when PauseTimer is added',
      build: () => timerBloc,
      seed: () => const TimerState(
        status: TimerStatus.running,
        duration: Duration(seconds: 10),
        remaining: Duration(seconds: 10),
        activePresetId: 'active_123',
      ),
      act: (bloc) => bloc.add(PauseTimer()),
      expect: () => [
        const TimerState(
          status: TimerStatus.paused,
          duration: Duration(seconds: 10),
          remaining: Duration(seconds: 10),
          activePresetId: 'active_123',
        ),
      ],
      verify: (_) {
        verify(() => systemAlarmService.cancelTimer('active_123')).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'resumes timer when ResumeTimer is added',
      build: () => timerBloc,
      seed: () => const TimerState(
        status: TimerStatus.paused,
        duration: Duration(seconds: 10),
        remaining: Duration(seconds: 10),
        activePresetId: 'active_123',
      ),
      act: (bloc) => bloc.add(ResumeTimer()),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'timer status', TimerStatus.running)
            .having(
              (s) => s.duration,
              'timer duration',
              const Duration(seconds: 10),
            )
            .having(
              (s) => s.remaining,
              'timer remaining',
              const Duration(seconds: 10),
            ),
      ],
      verify: (_) {
        verify(
          () => systemAlarmService.setTimer(
            'active_123',
            const Duration(seconds: 10),
          ),
        ).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'cancels timer and resets remaining duration when CancelTimer is added',
      build: () => timerBloc,
      seed: () => const TimerState(
        status: TimerStatus.running,
        duration: Duration(seconds: 10),
        remaining: Duration(seconds: 8),
        activePresetId: 'active_123',
      ),
      act: (bloc) => bloc.add(CancelTimer()),
      expect: () => [
        const TimerState(
          status: TimerStatus.idle,
          duration: Duration.zero,
          remaining: Duration.zero,
        ),
      ],
      verify: (_) {
        verify(() => systemAlarmService.cancelTimer('active_123')).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'decrements remaining duration on TimerTick',
      build: () => timerBloc,
      seed: () {
        final now = DateTime.now();
        return TimerState(
          status: TimerStatus.running,
          duration: const Duration(seconds: 10),
          remaining: const Duration(seconds: 10),
          endTime: now.add(const Duration(seconds: 10)),
        );
      },
      act: (bloc) => bloc.add(const TimerTick()),
      expect: () => [
        isA<TimerState>().having(
          (s) => s.remaining.inSeconds,
          'remaining seconds',
          9,
        ),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'finishes timer when remaining duration ticks to zero',
      build: () => timerBloc,
      seed: () {
        return TimerState(
          status: TimerStatus.running,
          duration: const Duration(seconds: 10),
          remaining: const Duration(seconds: 1),
          activePresetId: 'active_123',
          endTime: DateTime.now().subtract(const Duration(seconds: 1)),
        );
      },
      act: (bloc) => bloc.add(const TimerTick()),
      expect: () => [
        const TimerState(
          status: TimerStatus.finished,
          duration: Duration(seconds: 10),
          remaining: Duration.zero,
          activePresetId: 'active_123',
        ),
      ],
      verify: (_) {
        verify(() => systemAlarmService.cancelTimer('active_123')).called(1);
        verify(() => systemAlarmService.playCompletionSound()).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'saves and sets sound when SetTimerSound is added',
      build: () {
        when(
          () => repository.saveSelectedSound(any()),
        ).thenAnswer((_) async => {});
        return timerBloc;
      },
      act: (bloc) => bloc.add(const SetTimerSound('Wakeup')),
      expect: () => [const TimerState(sound: 'Wakeup')],
      verify: (_) {
        verify(() => repository.saveSelectedSound('Wakeup')).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'resets finished timer back to idle when ResetTimerToIdle is added',
      build: () => timerBloc,
      seed: () => const TimerState(
        status: TimerStatus.finished,
        duration: Duration(seconds: 10),
        remaining: Duration.zero,
      ),
      act: (bloc) => bloc.add(ResetTimerToIdle()),
      expect: () => [
        const TimerState(
          status: TimerStatus.idle,
          duration: Duration.zero,
          remaining: Duration.zero,
        ),
      ],
    );
  });
}
