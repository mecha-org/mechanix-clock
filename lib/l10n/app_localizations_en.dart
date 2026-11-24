// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get alarms => 'ALARMS';

  @override
  String get stopwatch => 'Stopwatch';

  @override
  String get lap => 'Lap';

  @override
  String get reset => 'Reset';

  @override
  String get no_alarms => 'NO ALARMS';

  @override
  String get once => 'Once';

  @override
  String get daily => 'Daily';

  @override
  String get custom => 'Custom';

  @override
  String get default_label => 'Default';

  @override
  String get alarm_time => 'Alarm time';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get repeat => 'Repeat';

  @override
  String get sound => 'Sound';

  @override
  String get snooze => 'Snooze';

  @override
  String get monday_abbr => 'M';

  @override
  String get tuesday_abbr => 'T';

  @override
  String get wednesday_abbr => 'W';

  @override
  String get thursday_abbr => 'T';

  @override
  String get friday_abbr => 'F';

  @override
  String get saturday_abbr => 'S';

  @override
  String get sunday_abbr => 'S';

  @override
  String lap_padded(String number) {
    return 'LAP $number';
  }

  @override
  String get start => 'Start';

  @override
  String get timers => 'Timer';

  @override
  String get cancel => 'Cancel';

  @override
  String get pause => 'Pause';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get hour_abbr => ' hr';

  @override
  String get hours_abbr => ' hrs';

  @override
  String get min_abbr => ' min';

  @override
  String get minutes_abbr => ' mins';

  @override
  String get sec_abbr => ' sec';

  @override
  String get seconds_abbr => ' secs';

  @override
  String get zero_min => '0 min';

  @override
  String get world_clock => 'World Clock';

  @override
  String get no_world_clocks => 'No world clocks added yet';

  @override
  String get tap_to_add_cities => 'Tap + to add cities around the world.';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get no_cities_found => 'No cities found';

  @override
  String get search_country_region => 'Search country/ region';

  @override
  String get delete_alarm_question => 'Delete alarm?';

  @override
  String get cancel_uppercase => 'CANCEL';

  @override
  String get alarm_label => 'Label';

  @override
  String get enter_label => 'Enter label';

  @override
  String get alarm_already_exists => 'An alarm already exists for this time';

  @override
  String get edit_label => 'Edit label';

  @override
  String alarm_label_limit(int max) {
    return 'Label can be at most $max characters';
  }

  @override
  String get snooze_duration => 'Snooze duration';

  @override
  String minutes_value(int minutes) {
    return '$minutes min';
  }

  @override
  String alarm_set_for(String duration) {
    return 'Alarm set for $duration from now';
  }

  @override
  String get alarm_set_less_than_minute =>
      'Alarm set for less than a minute from now';

  @override
  String duration_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String duration_hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String duration_minutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String list_two(String first, String last) {
    return '$first and $last';
  }

  @override
  String list_three(String first, String second, String last) {
    return '$first, $second and $last';
  }

  @override
  String get clock_service_unavailable => 'clock service isn\'t running';

  @override
  String get clock_service_mismatch =>
      'clock service version doesn\'t match the app';

  @override
  String alarm_save_failed(String reason) {
    return 'Couldn\'t save alarm: $reason';
  }

  @override
  String alarm_toggle_failed(String reason) {
    return 'Couldn\'t change alarm: $reason';
  }

  @override
  String alarm_delete_failed(String reason) {
    return 'Couldn\'t delete alarm: $reason';
  }

  @override
  String timer_start_failed(String reason) {
    return 'Couldn\'t start timer: $reason';
  }

  @override
  String timer_pause_failed(String reason) {
    return 'Couldn\'t pause timer: $reason';
  }

  @override
  String timer_cancel_failed(String reason) {
    return 'Couldn\'t cancel timer: $reason';
  }

  @override
  String get alarms_unavailable_title => 'Clock service isn\'t running';

  @override
  String get alarms_unavailable_body =>
      'Alarms can\'t be shown or changed until it starts.';

  @override
  String get alarms_load_failed_title => 'Couldn\'t load alarms';

  @override
  String get retry => 'Retry';
}
