import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/world_clock_model.dart';
import '../data/repository/world_clock_repository.dart';
import 'world_clock_event.dart';
import 'world_clock_state.dart';

class WorldClockBloc extends Bloc<WorldClockEvent, WorldClockState> {
  final WorldClockRepository repository;

  WorldClockBloc({required this.repository}) : super(WorldClockInitial()) {
    on<LoadWorldClocks>(_onLoadWorldClocks);
    on<AddWorldClock>(_onAddWorldClock);
    on<DeleteWorldClock>(_onDeleteWorldClock);
    on<ReorderWorldClocks>(_onReorderWorldClocks);
  }

  Future<void> _onLoadWorldClocks(
    LoadWorldClocks event,
    Emitter<WorldClockState> emit,
  ) async {
    emit(WorldClockLoading());
    try {
      final clocks = await repository.getWorldClocks();
      emit(WorldClockLoaded(clocks));
    } catch (e) {
      emit(WorldClockError('Failed to load world clocks: $e'));
    }
  }

  Future<void> _onAddWorldClock(
    AddWorldClock event,
    Emitter<WorldClockState> emit,
  ) async {
    final currentState = state;
    List<WorldClock> currentClocks = [];
    if (currentState is WorldClockLoaded) {
      currentClocks = List.from(currentState.clocks);
    } else {
      try {
        currentClocks = await repository.getWorldClocks();
      } catch (_) {}
    }

    // Check for duplicate (by timezoneId and cityName)
    if (currentClocks.any(
      (c) => c.timezoneId == event.timezoneId && c.cityName == event.cityName,
    )) {
      emit(WorldClockLoaded(currentClocks));
      return;
    }

    final newClock = WorldClock(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cityName: event.cityName,
      country: event.country,
      timezoneId: event.timezoneId,
    );

    final updated = List<WorldClock>.from(currentClocks)..add(newClock);
    try {
      await repository.saveWorldClocks(updated);
      emit(WorldClockLoaded(updated));
    } catch (e) {
      emit(WorldClockError('Failed to save world clocks: $e'));
    }
  }

  Future<void> _onDeleteWorldClock(
    DeleteWorldClock event,
    Emitter<WorldClockState> emit,
  ) async {
    final currentState = state;
    if (currentState is WorldClockLoaded) {
      final updated = currentState.clocks
          .where((c) => c.id != event.id)
          .toList();
      try {
        await repository.saveWorldClocks(updated);
        emit(WorldClockLoaded(updated));
      } catch (e) {
        emit(WorldClockError('Failed to save world clocks: $e'));
      }
    }
  }

  Future<void> _onReorderWorldClocks(
    ReorderWorldClocks event,
    Emitter<WorldClockState> emit,
  ) async {
    final currentState = state;
    if (currentState is WorldClockLoaded) {
      int newIndex = event.newIndex;
      if (event.oldIndex < newIndex) {
        newIndex -= 1;
      }
      final updated = List<WorldClock>.from(currentState.clocks);
      if (event.oldIndex >= 0 &&
          event.oldIndex < updated.length &&
          newIndex >= 0 &&
          newIndex <= updated.length) {
        final item = updated.removeAt(event.oldIndex);
        updated.insert(newIndex, item);
      }

      try {
        await repository.saveWorldClocks(updated);
        emit(WorldClockLoaded(updated));
      } catch (e) {
        emit(WorldClockError('Failed to save world clocks: $e'));
      }
    }
  }
}
