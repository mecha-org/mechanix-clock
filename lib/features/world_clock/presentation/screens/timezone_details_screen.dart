import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/world_clock_model.dart';
import '../widgets/day_night_details_card.dart';
import '../widgets/timezone_detail_row.dart';

class TimezoneDetailsScreen extends StatefulWidget {
  final WorldClock clock;

  const TimezoneDetailsScreen({super.key, required this.clock});

  @override
  State<TimezoneDetailsScreen> createState() => _TimezoneDetailsScreenState();
}

class _TimezoneDetailsScreenState extends State<TimezoneDetailsScreen> {
  late Timer _timer;
  late tz.TZDateTime _targetTime;

  @override
  void initState() {
    super.initState();

    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    tz.Location location;
    try {
      location = tz.getLocation(widget.clock.timezoneId);
    } catch (_) {
      location = tz.UTC;
    }
    _targetTime = tz.TZDateTime.now(location);
  }

  String _getRelativeOffset(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    try {
      final localLocation = tz.local;
      final localNow = tz.TZDateTime.now(localLocation);

      final diff = _targetTime.timeZoneOffset - localNow.timeZoneOffset;
      final diffMinutes = diff.inMinutes;
      if (diffMinutes == 0) {
        return l10n.same_as_local;
      }

      final diffHours = diffMinutes / 60.0;
      final formattedHours = diffHours.toStringAsFixed(
        diffHours.truncateToDouble() == diffHours ? 0 : 1,
      );

      if (diffHours > 0) {
        return l10n.hours_ahead(formattedHours);
      } else {
        return l10n.hours_behind(formattedHours.replaceAll('-', ''));
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDay = _targetTime.hour >= 6 && _targetTime.hour < 18;
    final timeStr = DateFormat('hh:mm:ss').format(_targetTime);
    final amPmStr = DateFormat('a').format(_targetTime);
    final dateStr = DateFormat('EEEE, MMMM d, y').format(_targetTime);
    final relativeOffset = _getRelativeOffset(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.clock.cityName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DayNightDetailsCard(
                cityName: widget.clock.cityName,
                country: widget.clock.country,
                timeStr: timeStr,
                amPmStr: amPmStr,
                dateStr: dateStr,
                isDay: isDay,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TimeZoneDetailRow(
                      icon: Icons.info_outline,
                      label: l10n.timezone_id,
                      value: widget.clock.timezoneId.replaceAll('_', ' '),
                    ),
                    const SizedBox(height: 16),
                    TimeZoneDetailRow(
                      icon: Icons.compare_arrows,
                      label: l10n.time_difference,
                      value: relativeOffset,
                    ),
                    const SizedBox(height: 16),
                    TimeZoneDetailRow(
                      icon: isDay
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: l10n.day_night_status,
                      value: isDay ? l10n.daytime : l10n.nighttime,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
