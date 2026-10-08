import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_event.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_state.dart';
import 'package:mechanix_clock/features/world_clock/presentation/widgets/add_city_sheet.dart';
import 'package:mechanix_clock/features/world_clock/presentation/widgets/world_clock_empty_state.dart';
import 'package:mechanix_clock/features/world_clock/presentation/widgets/world_clock_item.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:widgets/widgets.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  late Timer _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
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
      if (diffDays >= 1) {
        dayStr = l10n.tomorrow;
      } else if (diffDays <= -1) {
        dayStr = l10n.yesterday;
      }

      final offset = targetNow.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60).abs();
      final sign = offset.isNegative ? '-' : '+';
      final hoursAbs = hours.abs();

      final String offsetStr;
      if (minutes == 0) {
        offsetStr = 'UTC $sign$hoursAbs';
      } else {
        offsetStr = 'UTC $sign$hoursAbs:${minutes.toString().padLeft(2, '0')}';
      }

      return '$dayStr, $offsetStr';
    } catch (e) {
      return '${l10n.today}, UTC +0';
    }
  }

  void _openAddCitySheet() {
    MechanixBottomSheet.showModal(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const AddCitySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        primary: false,
        title: Text(
          l10n.world_clock.toUpperCase(),
          style: theme.textTheme.headlineMedium!.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: MechanixDivider(color: theme.colorScheme.outline, space: 1),
        ),
      ),
      body: BlocBuilder<WorldClockBloc, WorldClockState>(
        builder: (context, state) {
          if (state is WorldClockLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WorldClockLoaded) {
            if (state.clocks.isEmpty) {
              return const WorldClockEmptyState();
            }
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: MechanixSwipableList(
                child: ListView.separated(
                  itemCount: state.clocks.length,
                  separatorBuilder: (context, index) => MechanixDivider(
                    color: theme.colorScheme.outline,
                    space: 1,
                  ),
                  itemBuilder: (context, index) {
                    final clock = state.clocks[index];
                    final relativeInfo = _getRelativeDayAndOffset(
                      context,
                      clock.timezoneId,
                    );

                    return WorldClockItem(
                      key: ValueKey(clock.id),
                      clock: clock,
                      relativeInfo: relativeInfo,
                      onDelete: () {
                        context.read<WorldClockBloc>().add(
                          DeleteWorldClock(clock.id),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          } else if (state is WorldClockError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }
          return const WorldClockEmptyState();
        },
      ),
      floatingActionButton: MechanixFloatingActionButton(
        key: const Key('world_clock_add_city_button'),
        onPressed: _openAddCitySheet,
        icon: const Icon(Icons.add),
      ),
    );
  }
}
