import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_bloc.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_event.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_state.dart';
import 'package:mechanix_clock/features/stopwatch/data/repository/stopwatch_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  final blocs = <StopwatchBloc>[];

  StopwatchBloc open() {
    final bloc = StopwatchBloc(
      repository: StopwatchRepository(),
      now: () => now,
    )..add(const LoadStopwatch());
    blocs.add(bloc);
    return bloc;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 19, 10);
  });

  tearDown(() async {
    for (final bloc in blocs) {
      await bloc.close();
    }
    blocs.clear();
  });

  test('starts fresh', () async {
    final bloc = open();
    await settle();
    expect(bloc.state, const StopwatchState());
  });

  test('keeps counting while the app is closed', () async {
    final first = open();
    await settle();
    first.add(StartStopwatch());
    await settle();
    await first.close();

    now = now.add(const Duration(minutes: 3, seconds: 5));
    final reopened = open();
    await settle();

    expect(reopened.state.status, StopwatchStatus.running);
    expect(reopened.state.elapsed, const Duration(minutes: 3, seconds: 5));
  });

  test('a paused stopwatch stays paused at its time', () async {
    final first = open();
    await settle();
    first.add(StartStopwatch());
    await settle();
    now = now.add(const Duration(seconds: 10));
    first.add(StopStopwatch());
    await settle();
    await first.close();

    now = now.add(const Duration(hours: 1));
    final reopened = open();
    await settle();

    expect(reopened.state.status, StopwatchStatus.stopped);
    expect(reopened.state.elapsed, const Duration(seconds: 10));
  });

  test('resume adds to the time counted before the pause', () async {
    final bloc = open();
    await settle();
    bloc.add(StartStopwatch());
    await settle();
    now = now.add(const Duration(seconds: 10));
    bloc.add(StopStopwatch());
    await settle();
    now = now.add(const Duration(minutes: 5)); // paused: doesn't count
    bloc.add(StartStopwatch());
    await settle();
    now = now.add(const Duration(seconds: 2));
    bloc.add(LapStopwatch());
    await settle();

    expect(bloc.state.elapsed, const Duration(seconds: 12));
  });

  test('laps are kept across restarts', () async {
    final first = open();
    await settle();
    first.add(StartStopwatch());
    await settle();
    now = now.add(const Duration(seconds: 4));
    first.add(LapStopwatch());
    await settle();
    now = now.add(const Duration(seconds: 6));
    first.add(LapStopwatch());
    await settle();
    await first.close();

    final reopened = open();
    await settle();

    final laps = reopened.state.laps;
    expect(laps.map((l) => l.lapNumber), [2, 1]);
    expect(laps.first.duration, const Duration(seconds: 6));
    expect(laps.first.totalTime, const Duration(seconds: 10));
    expect(laps.last.duration, const Duration(seconds: 4));
  });

  test('reset clears what was saved', () async {
    final first = open();
    await settle();
    first.add(StartStopwatch());
    await settle();
    now = now.add(const Duration(seconds: 30));
    first.add(ResetStopwatch());
    await settle();
    await first.close();

    final reopened = open();
    await settle();
    expect(reopened.state, const StopwatchState());
  });

  test('a clock set back never shows negative time', () async {
    final bloc = open();
    await settle();
    bloc.add(StartStopwatch());
    await settle();
    now = now.subtract(const Duration(minutes: 1));
    bloc.add(LapStopwatch());
    await settle();
    expect(bloc.state.elapsed, Duration.zero);
  });
}
