import 'package:flutter/material.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

extension LocalizedDays on BuildContext {
  List<String> get dayAbbrs {
    final l10n = AppLocalizations.of(this)!;
    return [
      l10n.monday_abbr,
      l10n.tuesday_abbr,
      l10n.wednesday_abbr,
      l10n.thursday_abbr,
      l10n.friday_abbr,
      l10n.saturday_abbr,
      l10n.sunday_abbr,
    ];
  }
}

String formatEndTime(DateTime dateTime, AppLocalizations l10n) {
  final hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final isPm = hour >= 12;
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final period = isPm ? l10n.pm : l10n.am;
  return '$displayHour:$minute $period';
}

String formatDuration(Duration duration, {bool includeHundredths = false}) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));

  final base = hours > 0
      ? '${twoDigits(hours)}:$minutes:$seconds'
      : '$minutes:$seconds';

  if (includeHundredths) {
    final hundredths = twoDigits(
      (duration.inMilliseconds.remainder(1000) / 10).truncate(),
    );
    return '$base.$hundredths';
  }
  return base;
}




