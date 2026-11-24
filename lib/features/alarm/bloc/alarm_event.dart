import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import '../data/models/alarm_model.dart';

abstract class AlarmEvent extends Equatable {
  const AlarmEvent();

  @override
  List<Object?> get props => [];
}

class LoadAlarms extends AlarmEvent {
  const LoadAlarms();
}

/// How saving an alarm went: null when it worked, otherwise the error. The
/// editor waits for it before saying "Alarm set for …".
typedef AlarmSaveResult = Completer<ClockdException?>;

class AddAlarm extends AlarmEvent {
  final Alarm alarm;

  /// Completed when the daemon has answered. Not part of equality.
  final AlarmSaveResult? result;

  const AddAlarm(this.alarm, {this.result});

  @override
  List<Object?> get props => [alarm];
}

class UpdateAlarm extends AlarmEvent {
  final Alarm alarm;

  /// Completed when the daemon has answered. Not part of equality.
  final AlarmSaveResult? result;

  const UpdateAlarm(this.alarm, {this.result});

  @override
  List<Object?> get props => [alarm];
}

class DeleteAlarm extends AlarmEvent {
  final String alarmId;
  const DeleteAlarm(this.alarmId);

  @override
  List<Object?> get props => [alarmId];
}

class ToggleAlarm extends AlarmEvent {
  final String alarmId;
  const ToggleAlarm(this.alarmId);

  @override
  List<Object?> get props => [alarmId];
}

/// Re-read the list from mxclockd, without the loading
/// state.
class RefreshAlarms extends AlarmEvent {
  const RefreshAlarms();
}
