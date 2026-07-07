import 'package:equatable/equatable.dart';
import '../data/models/world_clock_model.dart';

abstract class WorldClockState extends Equatable {
  const WorldClockState();

  @override
  List<Object?> get props => [];
}

class WorldClockInitial extends WorldClockState {}

class WorldClockLoading extends WorldClockState {}

class WorldClockLoaded extends WorldClockState {
  final List<WorldClock> clocks;

  const WorldClockLoaded(this.clocks);

  @override
  List<Object?> get props => [clocks];
}

class WorldClockError extends WorldClockState {
  final String message;

  const WorldClockError(this.message);

  @override
  List<Object?> get props => [message];
}
