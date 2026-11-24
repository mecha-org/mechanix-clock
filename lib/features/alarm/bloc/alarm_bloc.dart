import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';

import '../data/models/alarm_model.dart';
import '../data/repository/alarm_repository.dart';
import 'alarm_event.dart';
import 'alarm_state.dart';

/// The alarm list as mxclockd keeps it; reloaded on `AlarmsChanged` and when
/// the daemon (re)starts. Failures are reported: save via [AlarmSaveResult],
/// toggle/delete via [AlarmLoaded.failure], load via [AlarmError].
class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  final AlarmRepository repository;
  final _subscriptions = <StreamSubscription<void>>[];
  int _failureSeq = 0;

  /// The last event's run. Every event waits for it, so events of all types
  /// run one at a time, in order (`sequential()` only orders one type).
  Future<void> _last = Future.value();

  EventTransformer<E> _inOrder<E>() =>
      (events, mapper) => concurrent<E>()(events, (event) {
        var cancelled = false; // The bloc closed: drop the queued event.
        final run = _last.then((_) async {
          if (!cancelled) await mapper(event).drain<void>();
        });
        // A failed handler doesn't hold up the events after it.
        _last = run.catchError((Object _) {});
        final done = StreamController<E>(onCancel: () => cancelled = true);
        run.then(
          (_) => done.close(),
          onError: (Object e, StackTrace s) => done
            ..addError(e, s)
            ..close(),
        );
        return done.stream;
      });

  AlarmBloc({required this.repository}) : super(AlarmInitial()) {
    // One at a time, in order: each handler reads the list the previous one
    // left.
    on<LoadAlarms>((_, emit) => _onLoadAlarms(emit), transformer: _inOrder());
    on<RefreshAlarms>((_, emit) => _refresh(emit), transformer: _inOrder());
    on<AddAlarm>(
      (event, emit) => _onAddAlarm(event.alarm, event.result, emit),
      transformer: _inOrder(),
    );
    on<UpdateAlarm>(
      (event, emit) => _onUpdateAlarm(event.alarm, event.result, emit),
      transformer: _inOrder(),
    );
    on<DeleteAlarm>(
      (event, emit) => _onDeleteAlarm(event.alarmId, emit),
      transformer: _inOrder(),
    );
    on<ToggleAlarm>(
      (event, emit) => _onToggleAlarm(event.alarmId, emit),
      transformer: _inOrder(),
    );
    _subscriptions
      ..add(repository.changes.listen((_) => add(const RefreshAlarms())))
      ..add(
        repository.serviceStarted.listen((_) => add(const RefreshAlarms())),
      );
  }

  Future<void> _onLoadAlarms(Emitter<AlarmState> emit) async {
    emit(AlarmLoading());
    await _load(emit);
  }

  Future<void> _load(Emitter<AlarmState> emit) async {
    try {
      emit(AlarmLoaded(_byTime(await repository.getAlarms())));
    } on ClockdException catch (e) {
      AppLogger.e('Failed to load alarms from mxclockd: $e');
      emit(AlarmError(e));
    }
  }

  /// Re-reads the list without the loading state. After a failed load it
  /// loads again (the daemon may be back).
  Future<void> _refresh(
    Emitter<AlarmState> emit, {
    AlarmFailure? failure,
  }) async {
    if (state is! AlarmLoaded) {
      await _load(emit);
      return;
    }
    try {
      emit(
        AlarmLoaded(_byTime(await repository.getAlarms()), failure: failure),
      );
    } on ClockdException catch (e) {
      AppLogger.e('Failed to reload alarms: $e');
      // Keep what is shown; still report the change that failed.
      if (failure != null) {
        emit(AlarmLoaded(_alarms ?? const [], failure: failure));
      }
    }
  }

  /// Alarms in time-of-day order (00:00 first), like other clock apps. Ties
  /// keep the order they came in.
  static List<Alarm> _byTime(List<Alarm> alarms) {
    int minuteOfDay(Alarm a) => AlarmRepository.hour24(a) * 60 + a.minute;
    final indexed = alarms.indexed.toList()
      ..sort((x, y) {
        final byTime = minuteOfDay(x.$2).compareTo(minuteOfDay(y.$2));
        return byTime != 0 ? byTime : x.$1.compareTo(y.$1);
      });
    return [for (final (_, a) in indexed) a];
  }

  List<Alarm>? get _alarms {
    final current = state;
    return current is AlarmLoaded ? current.alarms : null;
  }

  AlarmFailure _failure(AlarmChange change, ClockdException error) =>
      AlarmFailure(change, error, ++_failureSeq);

  Future<void> _onAddAlarm(
    Alarm alarm,
    AlarmSaveResult? result,
    Emitter<AlarmState> emit,
  ) async {
    try {
      final added = await repository.addAlarm(alarm);
      final alarms = _alarms;
      if (alarms != null) {
        emit(AlarmLoaded(_byTime([...alarms, added])));
      } else {
        // The list wasn't loaded (daemon was down): read it now.
        await _load(emit);
      }
      result?.complete(null);
    } on ClockdException catch (e) {
      AppLogger.e('Failed to add alarm: $e');
      await _reportSaveFailure(e, result, emit);
    }
  }

  Future<void> _onUpdateAlarm(
    Alarm alarm,
    AlarmSaveResult? result,
    Emitter<AlarmState> emit,
  ) async {
    try {
      await repository.updateAlarm(alarm);
      final alarms = _alarms;
      if (alarms != null) {
        emit(
          AlarmLoaded(
            // UpdateAlarm switches it on.
            _byTime([
              for (final a in alarms)
                a.id == alarm.id ? alarm.copyWith(isActive: true) : a,
            ]),
          ),
        );
      } else {
        await _load(emit);
      }
      result?.complete(null);
    } on ClockdException catch (e) {
      AppLogger.e('Failed to update alarm: $e');
      await _reportSaveFailure(e, result, emit);
    }
  }

  /// The editor shows a save failure itself when it waits for [result];
  /// otherwise the list does.
  Future<void> _reportSaveFailure(
    ClockdException error,
    AlarmSaveResult? result,
    Emitter<AlarmState> emit,
  ) async {
    if (result != null) {
      result.complete(error);
      await _refresh(emit);
    } else {
      await _refresh(emit, failure: _failure(AlarmChange.save, error));
    }
  }

  Future<void> _onDeleteAlarm(String id, Emitter<AlarmState> emit) async {
    try {
      await repository.deleteAlarm(id);
      final alarms = _alarms;
      if (alarms != null) {
        emit(
          AlarmLoaded([
            for (final a in alarms)
              if (a.id != id) a,
          ]),
        );
      }
    } on ClockdException catch (e) {
      AppLogger.e('Failed to delete alarm: $e');
      await _refresh(emit, failure: _failure(AlarmChange.delete, e));
    }
  }

  Future<void> _onToggleAlarm(String id, Emitter<AlarmState> emit) async {
    final alarms = _alarms;
    final alarm = alarms?.where((a) => a.id == id).firstOrNull;
    if (alarms == null || alarm == null) return;
    final toggled = alarm.copyWith(isActive: !alarm.isActive);
    try {
      await repository.setAlarmEnabled(id, toggled.isActive);
      emit(AlarmLoaded([for (final a in alarms) a.id == id ? toggled : a]));
    } on ClockdException catch (e) {
      AppLogger.e('Failed to toggle alarm: $e');
      await _refresh(emit, failure: _failure(AlarmChange.toggle, e));
    }
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
