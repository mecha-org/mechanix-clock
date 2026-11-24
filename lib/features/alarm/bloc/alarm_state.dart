import 'package:equatable/equatable.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';

import '../data/models/alarm_model.dart';

abstract class AlarmState extends Equatable {
  const AlarmState();

  @override
  List<Object?> get props => [];
}

class AlarmInitial extends AlarmState {}

class AlarmLoading extends AlarmState {}

class AlarmLoaded extends AlarmState {
  final List<Alarm> alarms;

  /// The last change that failed, for the list to show once; null when the
  /// latest one worked.
  final AlarmFailure? failure;

  const AlarmLoaded(this.alarms, {this.failure});

  @override
  List<Object?> get props => [alarms, failure];
}

/// The alarms couldn't be read from mxclockd.
class AlarmError extends AlarmState {
  final ClockdException error;

  const AlarmError(this.error);

  /// mxclockd isn't running (rather than refusing).
  bool get unavailable => error is ClockdUnavailable;

  @override
  List<Object?> get props => [
    error.runtimeType,
    error.errorName,
    error.message,
  ];
}

/// What the user tried when an alarm change failed.
enum AlarmChange { save, toggle, delete }

/// A failed alarm change. [seq] tells two failures of the same kind apart,
/// so each one is shown.
class AlarmFailure extends Equatable {
  final AlarmChange change;
  final ClockdException error;
  final int seq;

  const AlarmFailure(this.change, this.error, this.seq);

  @override
  List<Object?> get props => [change, seq];
}
