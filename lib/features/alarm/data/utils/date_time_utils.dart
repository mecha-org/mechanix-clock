import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static final Map<String, List<String>> _abbreviationCache = {};

  /// Returns localized weekday abbreviations in Sunday-first order.
  static List<String> getWeekdayAbbreviations(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final cached = _abbreviationCache[locale];
    if (cached != null) return cached;

    final weekdayFormatter = DateFormat('EEEEE', locale);

    final abbreviations = List<String>.unmodifiable(
      List.generate(7, (index) {
        // Convert Sunday-first list indices to DateTime weekday values.
        final weekday = index == 0 ? 7 : index;
        final date = DateTime(2024, 1, weekday);

        return weekdayFormatter.format(date);
      }),
    );

    _abbreviationCache[locale] = abbreviations;
    return abbreviations;
  }

  /// "Alarm set for 3 days and 5 minutes from now" (GNOME Clocks wording);
  /// minutes rounded up, zero parts left out.
  static String alarmSetFor(AppLocalizations l10n, Duration until) {
    if (until.inSeconds < 60) return l10n.alarm_set_less_than_minute;
    final totalMinutes = (until.inSeconds + 59) ~/ 60;
    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes ~/ 60) % 24;
    final minutes = totalMinutes % 60;
    final parts = [
      if (days > 0) l10n.duration_days(days),
      if (hours > 0) l10n.duration_hours(hours),
      if (minutes > 0) l10n.duration_minutes(minutes),
    ];
    final duration = switch (parts.length) {
      1 => parts[0],
      2 => l10n.list_two(parts[0], parts[1]),
      _ => l10n.list_three(parts[0], parts[1], parts[2]),
    };
    return l10n.alarm_set_for(duration);
  }
}
