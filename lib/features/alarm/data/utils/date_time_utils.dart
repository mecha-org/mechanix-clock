import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  DateTimeUtils._();

  /// Returns localized weekday abbreviations in Sunday-first order.
  static List<String> getWeekdayAbbreviations(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final weekdayFormatter = DateFormat('EEEEE', locale);

    return List.generate(7, (index) {
      // Convert Sunday-first list indices to DateTime weekday values.
      final weekday = index == 0 ? 7 : index;
      final date = DateTime(2024, 1, weekday);

      return weekdayFormatter.format(date);
    });
  }
}
