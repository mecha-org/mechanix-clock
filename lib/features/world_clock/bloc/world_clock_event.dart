import 'package:equatable/equatable.dart';

abstract class WorldClockEvent extends Equatable {
  const WorldClockEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorldClocks extends WorldClockEvent {}

class AddWorldClock extends WorldClockEvent {
  final String cityName;
  final String country;
  final String timezoneId;

  const AddWorldClock({
    required this.cityName,
    required this.country,
    required this.timezoneId,
  });

  @override
  List<Object?> get props => [cityName, country, timezoneId];
}

class DeleteWorldClock extends WorldClockEvent {
  final String id;

  const DeleteWorldClock(this.id);

  @override
  List<Object?> get props => [id];
}

class ReorderWorldClocks extends WorldClockEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderWorldClocks(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}
