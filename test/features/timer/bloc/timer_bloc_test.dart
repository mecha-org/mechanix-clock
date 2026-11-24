import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_event.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_state.dart';
import 'package:mechanix_clock/features/timer/data/models/active_timer_data.dart';
import 'package:mechanix_clock/features/timer/data/models/timer_preset.dart';
import 'package:mechanix_clock/features/timer/data/repository/timer_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTimerRepository extends Mock implements TimerRepository {}

class MockSystemAlarmService extends Mock implements SystemAlarmService {}

void main() {
  late TimerRepository repository;
  late SystemAlarmService systemAlarmService;
  late TimerBloc timerBloc;
  late StreamController<void> daemonStarted;

  const testPreset = TimerPreset(id: '1', duration: Duration(minutes: 5));

  setUpAll(() {
    registerFallbackValue(testPreset);
    registerFallbackValue(const Duration(minutes: 5));
    registerFallbackValue(<String, PausedTimer>{});
  });

  setUp(() {
    repository = MockTimerRepository();
    systemAlarmService = MockSystemAlarmService();

    // Stub platform timer channel calls
    when(
      () => systemAlarmService.setTimer(
        any(),
        any(),
        label: any(named: 'label'),
      ),
    ).thenAnswer((_) async => {});
    when(
      () => systemAlarmService.cancelTimer(any()),
    ).thenAnswer((_) async => {});
    when(
      () => systemAlarmService.forgetTimer(any()),
    ).thenAnswer((_) async => {});
    when(
      () => systemAlarmService.restoreTimers(),
    ).thenAnswer((_) async => RestoredTimers.none);
    daemonStarted = StreamController<void>.broadcast();
    when(
      () => systemAlarmService.daemonStarted,
    ).thenAnswer((_) => daemonStarted.stream);

    when(() => repository.getPausedTimers()).thenAnswer((_) async => {});
    when(() => repository.savePausedTimers(any())).thenAnswer((_) async {});

    timerBloc = TimerBloc(
      repository: repository,
      systemAlarmService: systemAlarmService,
    );
  });

  tearDown(() {
    timerBloc.close();
    daemonStarted.close();
  });

  group('TimerBloc', () {
    test('initial state has correct default values', () {
      expect(timerBloc.state.status, TimerStatus.initial);
      expect(timerBloc.state.duration, Duration.zero);
      expect(timerBloc.state.remaining, Duration.zero);
    });

    blocTest<TimerBloc, TimerState>(
      'emits correct state when LoadTimerPresets is added',
      build: () {
        when(
          () => repository.getPresets(),
        ).thenAnswer((_) async => [testPreset]);
        return timerBloc;
      },
      act: (bloc) => bloc.add(LoadTimerPresets()),
      expect: () => [
        const TimerState(
          status: TimerStatus.idle,
          presets: [testPreset],
        ),
      ],
    );

    const running = TimerState(
      status: TimerStatus.running,
      duration: Duration(seconds: 10),
      remaining: Duration(seconds: 8),
      activePresetId: 'active_123',
      activeTimers: {
        'active_123': ActiveTimerData(
          id: 'active_123',
          duration: Duration(seconds: 10),
          remaining: Duration(seconds: 8),
          status: TimerStatus.running,
        ),
      },
    );
    const gone = ClockdUnavailable(
      'org.freedesktop.DBus.Error.ServiceUnknown',
      'not running',
    );

    blocTest<TimerBloc, TimerState>(
      'a pause mxclockd cannot do is reported and the timer keeps running',
      build: () {
        when(() => systemAlarmService.cancelTimer(any())).thenThrow(gone);
        return timerBloc;
      },
      seed: () => running,
      act: (bloc) => bloc.add(const PauseTimer(presetId: 'active_123')),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.failure?.change, 'failure', TimerChange.pause)
            .having(
              (s) => s.activeTimers['active_123']?.status,
              'status',
              TimerStatus.running,
            ),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'a cancel mxclockd cannot do is reported and the timer stays',
      build: () {
        when(() => systemAlarmService.cancelTimer(any())).thenThrow(gone);
        return timerBloc;
      },
      seed: () => running,
      act: (bloc) => bloc.add(const CancelTimer(presetId: 'active_123')),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.failure?.change, 'failure', TimerChange.cancel)
            .having(
              (s) => s.activeTimers.containsKey('active_123'),
              'kept',
              isTrue,
            ),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'a timer mxclockd cannot start is reported and stays stopped',
      build: () {
        when(
          () => systemAlarmService.setTimer(
            any(),
            any(),
            label: any(named: 'label'),
          ),
        ).thenThrow(
          const ClockdUnavailable(
            'org.freedesktop.DBus.Error.ServiceUnknown',
            'not running',
          ),
        );
        when(() => repository.savePresets(any())).thenAnswer((_) async {});
        return timerBloc;
      },
      act: (bloc) =>
          bloc.add(const StartTimer(Duration(seconds: 30), presetId: '1')),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'status', TimerStatus.idle)
            .having(
              (s) => s.failure?.error,
              'failure',
              isA<ClockdUnavailable>(),
            ),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'LoadTimerPresets restores timers mxclockd is still running',
      build: () {
        when(
          () => repository.getPresets(),
        ).thenAnswer((_) async => [testPreset]);
        when(() => systemAlarmService.restoreTimers()).thenAnswer(
          (_) async => RestoredTimers(
            running: [
              ScheduledTimer(
                testPreset.id,
                DateTime.now().add(const Duration(minutes: 2)),
              ),
            ],
          ),
        );
        return timerBloc;
      },
      act: (bloc) => bloc.add(LoadTimerPresets()),
      skip: 1,
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'status', TimerStatus.running)
            .having((s) => s.activePresetId, 'activePresetId', testPreset.id)
            .having(
              (s) => s.activeTimers[testPreset.id]?.duration,
              'duration',
              testPreset.duration,
            ),
      ],
    );

    group('timers that ended while the device was off (missed)', () {
      final missed = MissedTimer(
        daemonId: 'd1',
        appId: testPreset.id,
        label: '5 min',
        endedAt: DateTime(2026, 11, 23, 16, 27),
      );

      blocTest<TimerBloc, TimerState>(
        'are not restored on load',
        build: () {
          when(
            () => repository.getPresets(),
          ).thenAnswer((_) async => [testPreset]);
          when(
            () => systemAlarmService.restoreTimers(),
          ).thenAnswer((_) async => RestoredTimers(missed: [missed]));
          return timerBloc;
        },
        act: (bloc) => bloc.add(LoadTimerPresets()),
        expect: () => [
          const TimerState(status: TimerStatus.idle, presets: [testPreset]),
        ],
      );

      blocTest<TimerBloc, TimerState>(
        'when mxclockd restarts, a timer shown running that ended goes idle',
        build: () {
          when(
            () => systemAlarmService.restoreTimers(),
          ).thenAnswer((_) async => RestoredTimers(missed: [missed]));
          return timerBloc;
        },
        seed: () => TimerState(
          status: TimerStatus.running,
          activePresetId: testPreset.id,
          remaining: const Duration(seconds: 5),
          activeTimers: {
            testPreset.id: ActiveTimerData(
              id: testPreset.id,
              duration: testPreset.duration,
              remaining: const Duration(seconds: 5),
              status: TimerStatus.running,
              endTime: DateTime.now().add(const Duration(seconds: 5)),
            ),
          },
        ),
        act: (_) => daemonStarted.add(null),
        expect: () => [
          isA<TimerState>()
              .having((s) => s.activeTimers, 'active', isEmpty)
              .having((s) => s.status, 'status', TimerStatus.idle)
              .having((s) => s.activePresetId, 'shown', ''),
        ],
      );
    });

    blocTest<TimerBloc, TimerState>(
      'deletes preset and emits new state when DeleteTimerPreset is added',
      build: () {
        when(() => repository.savePresets(any())).thenAnswer((_) async => {});
        return timerBloc;
      },
      seed: () =>
          const TimerState(status: TimerStatus.idle, presets: [testPreset]),
      act: (bloc) => bloc.add(const DeleteTimerPreset('1')),
      expect: () => [const TimerState(status: TimerStatus.idle, presets: [])],
    );

    blocTest<TimerBloc, TimerState>(
      'starts timer countdown and auto-saves new preset if not already present',
      build: () {
        when(() => repository.savePresets(any())).thenAnswer((_) async => {});
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
            .having((s) => s.presets.length, 'presets count', 1)
            .having(
              (s) => s.presets.first.duration,
              'preset duration',
              const Duration(seconds: 10),
            ),
      ],
      verify: (_) {
        verify(
          () => systemAlarmService.setTimer(
            any(),
            const Duration(seconds: 10),
            label: any(named: 'label'),
          ),
        ).called(1);
        verify(() => repository.savePresets(any())).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'starts timer with existing duration without duplicating preset',
      build: () {
        return timerBloc;
      },
      seed: () => const TimerState(
        presets: [
          TimerPreset(id: 'existing_1', duration: Duration(minutes: 5)),
        ],
      ),
      act: (bloc) => bloc.add(const StartTimer(Duration(minutes: 5))),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'timer status', TimerStatus.running)
            .having(
              (s) => s.duration,
              'timer duration',
              const Duration(minutes: 5),
            )
            .having((s) => s.presets.length, 'presets count', 1)
            .having((s) => s.activePresetId, 'active preset id', 'existing_1')
            .having(
              (s) => s.activeTimers['existing_1']?.status,
              'timer status in activeTimers',
              TimerStatus.running,
            ),
      ],
      verify: (_) {
        verify(
          () => systemAlarmService.setTimer(
            'existing_1',
            const Duration(minutes: 5),
            label: any(named: 'label'),
          ),
        ).called(1);
        verifyNever(() => repository.savePresets(any()));
      },
    );

    blocTest<TimerBloc, TimerState>(
      'a start that fails after stopping the running timer shows that one paused',
      build: () {
        when(
          () => systemAlarmService.setTimer(
            any(),
            any(),
            label: any(named: 'label'),
          ),
        ).thenThrow(gone);
        when(() => repository.savePresets(any())).thenAnswer((_) async {});
        return timerBloc;
      },
      seed: () => running,
      act: (bloc) =>
          bloc.add(const StartTimer(Duration(minutes: 3), presetId: 'new')),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.failure?.change, 'failure', TimerChange.start)
            .having((s) => s.status, 'status', TimerStatus.paused)
            .having((s) => s.activePresetId, 'shown', 'active_123')
            .having(
              (s) => s.activeTimers['active_123']?.status,
              'stopped timer',
              TimerStatus.paused,
            )
            .having(
              (s) => s.activeTimers.containsKey('new'),
              'new timer listed',
              isFalse,
            )
            .having(
              (s) => s.presets.any((p) => p.id == 'new'),
              'new preset kept',
              isTrue,
            ),
      ],
      verify: (_) {
        verify(() => systemAlarmService.cancelTimer('active_123')).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'a resume that fails leaves both timers paused',
      build: () {
        when(
          () => systemAlarmService.setTimer(
            any(),
            any(),
            label: any(named: 'label'),
          ),
        ).thenThrow(gone);
        return timerBloc;
      },
      seed: () => TimerState(
        status: TimerStatus.running,
        activePresetId: 'active_123',
        activeTimers: {
          ...running.activeTimers,
          'other': const ActiveTimerData(
            id: 'other',
            duration: Duration(minutes: 2),
            remaining: Duration(minutes: 1),
            status: TimerStatus.paused,
          ),
        },
      ),
      act: (bloc) => bloc.add(const ResumeTimer(presetId: 'other')),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.failure?.change, 'failure', TimerChange.start)
            .having((s) => s.status, 'status', TimerStatus.paused)
            .having(
              (s) => s.activeTimers.values.map((t) => t.status).toSet(),
              'statuses',
              {TimerStatus.paused},
            )
            .having(
              (s) => s.activeTimers['other']?.remaining,
              'other unchanged',
              const Duration(minutes: 1),
            ),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'pausing saves the paused timer',
      build: () => timerBloc,
      seed: () => running,
      act: (bloc) => bloc.add(const PauseTimer(presetId: 'active_123')),
      verify: (_) {
        final saved =
            verify(
                  () => repository.savePausedTimers(captureAny()),
                ).captured.single
                as Map<String, PausedTimer>;
        expect(saved.keys, ['active_123']);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'paused timers come back on load',
      build: () {
        when(() => repository.getPresets()).thenAnswer((_) async => []);
        when(() => repository.getPausedTimers()).thenAnswer(
          (_) async => {
            'p1': const PausedTimer(
              duration: Duration(minutes: 5),
              remaining: Duration(minutes: 2),
            ),
          },
        );
        return timerBloc;
      },
      act: (bloc) => bloc.add(LoadTimerPresets()),
      skip: 1,
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'status', TimerStatus.paused)
            .having((s) => s.activePresetId, 'shown', 'p1')
            .having((s) => s.remaining, 'remaining', const Duration(minutes: 2))
            .having(
              (s) => s.activeTimers['p1']?.status,
              'p1',
              TimerStatus.paused,
            ),
      ],
    );

    blocTest<TimerBloc, TimerState>(
      'starting second timer pauses first running timer and maintains both in activeTimers',
      build: () {
        return timerBloc;
      },
      seed: () => const TimerState(
        status: TimerStatus.running,
        duration: Duration(seconds: 10),
        remaining: Duration(seconds: 8),
        activePresetId: 't1',
        presets: [
          TimerPreset(id: 't1', duration: Duration(seconds: 10)),
          TimerPreset(id: 't2', duration: Duration(minutes: 5)),
        ],
        activeTimers: {
          't1': ActiveTimerData(
            id: 't1',
            duration: Duration(seconds: 10),
            remaining: Duration(seconds: 8),
            status: TimerStatus.running,
          ),
        },
      ),
      act: (bloc) =>
          bloc.add(const StartTimer(Duration(minutes: 5), presetId: 't2')),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'status', TimerStatus.running)
            .having((s) => s.activePresetId, 'activePresetId', 't2')
            .having(
              (s) => s.activeTimers['t1']?.status,
              't1 status in activeTimers',
              TimerStatus.paused,
            )
            .having(
              (s) => s.activeTimers['t2']?.status,
              't2 status in activeTimers',
              TimerStatus.running,
            ),
      ],
      verify: (_) {
        verify(() => systemAlarmService.cancelTimer('t1')).called(1);
        verify(
          () => systemAlarmService.setTimer(
            't2',
            const Duration(minutes: 5),
            label: any(named: 'label'),
          ),
        ).called(1);
      },
    );

    blocTest<TimerBloc, TimerState>(
      'starting timer with resetOldActiveTimers: true clears existing active timers',
      build: () {
        return timerBloc;
      },
      seed: () => const TimerState(
        status: TimerStatus.paused,
        duration: Duration(seconds: 10),
        remaining: Duration(seconds: 8),
        activePresetId: 't1',
        presets: [
          TimerPreset(id: 't1', duration: Duration(seconds: 10)),
          TimerPreset(id: 't2', duration: Duration(minutes: 5)),
        ],
        activeTimers: {
          't1': ActiveTimerData(
            id: 't1',
            duration: Duration(seconds: 10),
            remaining: Duration(seconds: 8),
            status: TimerStatus.paused,
          ),
        },
      ),
      act: (bloc) => bloc.add(
        const StartTimer(
          Duration(minutes: 5),
          presetId: 't2',
          resetOldActiveTimers: true,
        ),
      ),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'status', TimerStatus.running)
            .having((s) => s.activePresetId, 'activePresetId', 't2')
            .having((s) => s.activeTimers.length, 'activeTimers length', 1)
            .having(
              (s) => s.activeTimers.containsKey('t1'),
              'contains t1',
              false,
            )
            .having(
              (s) => s.activeTimers['t2']?.status,
              't2 status in activeTimers',
              TimerStatus.running,
            ),
      ],
      verify: (_) {
        verify(() => systemAlarmService.cancelTimer('t1')).called(1);
        verify(
          () => systemAlarmService.setTimer(
            't2',
            const Duration(minutes: 5),
            label: any(named: 'label'),
          ),
        ).called(1);
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
        activeTimers: {
          'active_123': ActiveTimerData(
            id: 'active_123',
            duration: Duration(seconds: 10),
            remaining: Duration(seconds: 10),
            status: TimerStatus.running,
          ),
        },
      ),
      act: (bloc) => bloc.add(PauseTimer()),
      expect: () => [
        const TimerState(
          status: TimerStatus.paused,
          duration: Duration(seconds: 10),
          remaining: Duration(seconds: 10),
          activePresetId: 'active_123',
          activeTimers: {
            'active_123': ActiveTimerData(
              id: 'active_123',
              duration: Duration(seconds: 10),
              remaining: Duration(seconds: 10),
              status: TimerStatus.paused,
            ),
          },
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
        activeTimers: {
          'active_123': ActiveTimerData(
            id: 'active_123',
            duration: Duration(seconds: 10),
            remaining: Duration(seconds: 10),
            status: TimerStatus.paused,
          ),
        },
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
            )
            .having(
              (s) => s.activeTimers['active_123']?.status,
              'active timer status',
              TimerStatus.running,
            ),
      ],
      verify: (_) {
        verify(
          () => systemAlarmService.setTimer(
            'active_123',
            const Duration(seconds: 10),
            label: any(named: 'label'),
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
        activeTimers: {
          'active_123': ActiveTimerData(
            id: 'active_123',
            duration: Duration(seconds: 10),
            remaining: Duration(seconds: 8),
            status: TimerStatus.running,
          ),
        },
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
          activePresetId: 'active_123',
          activeTimers: {
            'active_123': ActiveTimerData(
              id: 'active_123',
              duration: const Duration(seconds: 10),
              remaining: const Duration(seconds: 10),
              status: TimerStatus.running,
              endTime: now.add(const Duration(seconds: 9)),
            ),
          },
          endTime: now.add(const Duration(seconds: 9)),
        );
      },
      act: (bloc) => bloc.add(const TimerTick()),
      expect: () => [
        isA<TimerState>().having(
          (s) => s.activeTimers['active_123']?.remaining.inSeconds,
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
          activeTimers: {
            'active_123': ActiveTimerData(
              id: 'active_123',
              duration: const Duration(seconds: 10),
              remaining: const Duration(seconds: 1),
              status: TimerStatus.running,
              endTime: DateTime.now().subtract(const Duration(seconds: 1)),
            ),
          },
          endTime: DateTime.now().subtract(const Duration(seconds: 1)),
        );
      },
      act: (bloc) => bloc.add(const TimerTick()),
      expect: () => [
        isA<TimerState>()
            .having((s) => s.status, 'status', TimerStatus.finished)
            .having((s) => s.activePresetId, 'activePresetId', 'active_123'),
      ],
      verify: (_) {
        // mxclockd rings it; the app must not remove the daemon timer.
        verify(() => systemAlarmService.forgetTimer('active_123')).called(1);
        verifyNever(() => systemAlarmService.cancelTimer(any()));
      },
    );

  });
}
