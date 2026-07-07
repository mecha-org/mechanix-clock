import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/theme/app_theme.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_event.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_state.dart';
import 'package:mechanix_clock/features/world_clock/presentation/screens/timezone_details_screen.dart';
import 'package:mechanix_clock/features/world_clock/presentation/widgets/add_city_sheet.dart';
import 'package:mechanix_clock/features/world_clock/presentation/widgets/world_clock_empty_state.dart';
import 'package:mechanix_clock/features/world_clock/presentation/widgets/world_clock_item.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  bool _isEditing = false;
  late Timer _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isEditing) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  String _getRelativeDayAndOffset(BuildContext context, String timezoneId) {
    final l10n = AppLocalizations.of(context)!;
    try {
      final localLocation = tz.local;
      final localNow = tz.TZDateTime.now(localLocation);
      final targetLocation = tz.getLocation(timezoneId);
      final targetNow = tz.TZDateTime.now(targetLocation);

      final localToday = DateTime(localNow.year, localNow.month, localNow.day);
      final targetToday = DateTime(
        targetNow.year,
        targetNow.month,
        targetNow.day,
      );

      String dayStr = l10n.today;
      final diffDays = targetToday.difference(localToday).inDays;
      if (diffDays == 1) {
        dayStr = l10n.tomorrow;
      } else if (diffDays == -1) {
        dayStr = l10n.yesterday;
      }

      final offset = targetNow.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60).abs();
      final sign = hours >= 0 ? '+' : '−';
      final hoursStr = hours.abs().toString().padLeft(2, '0');
      final minutesStr = minutes.toString().padLeft(2, '0');

      return '$dayStr, UTC$sign$hoursStr:$minutesStr';
    } catch (e) {
      return '${l10n.today}, UTC+00:00';
    }
  }

  bool _isDaytime(String timezoneId) {
    try {
      final location = tz.getLocation(timezoneId);
      final now = tz.TZDateTime.now(location);
      return now.hour >= 6 && now.hour < 18;
    } catch (e) {
      return true;
    }
  }

  void _openAddCitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      builder: (context) =>
          const FractionallySizedBox(heightFactor: 1.0, child: AddCitySheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.world_clock,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            key: const Key('world_clock_edit_mode_button'),
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
          IconButton(
            key: const Key('world_clock_add_city_button'),
            icon: const Icon(
              Icons.add_box_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: _openAddCitySheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<WorldClockBloc, WorldClockState>(
        builder: (context, state) {
          if (state is WorldClockLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WorldClockLoaded) {
            if (state.clocks.isEmpty) {
              return const WorldClockEmptyState();
            }
            return Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: state.clocks.length,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final clock = state.clocks[index];
                  final relativeInfo = _getRelativeDayAndOffset(
                    context,
                    clock.timezoneId,
                  );
                  final isDay = _isDaytime(clock.timezoneId);

                  return WorldClockItem(
                    key: ValueKey(clock.id),
                    clock: clock,
                    index: index,
                    totalCount: state.clocks.length,
                    isEditing: _isEditing,
                    relativeInfo: relativeInfo,
                    isDay: isDay,
                    onTap: () {
                      if (_isEditing) {
                        context.read<WorldClockBloc>().add(
                          DeleteWorldClock(clock.id),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TimezoneDetailsScreen(clock: clock),
                          ),
                        );
                      }
                    },
                    onDelete: () {
                      context.read<WorldClockBloc>().add(
                        DeleteWorldClock(clock.id),
                      );
                    },
                  );
                },
                onReorderItem: (oldIndex, newIndex) {
                  context.read<WorldClockBloc>().add(
                    ReorderWorldClocks(oldIndex, newIndex),
                  );
                },
              ),
            );
          } else if (state is WorldClockError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const WorldClockEmptyState();
        },
      ),
    );
  }
}
