import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_event.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_state.dart';
import 'package:mechanix_clock/features/world_clock/data/models/world_clock_model.dart';
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
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _scheduleNextMinute();
  }

  void _scheduleNextMinute() {
    final now = DateTime.now();

    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );

    _ticker = Timer(nextMinute.difference(now), () {
      if (!mounted) return;

      setState(() {});
      _scheduleNextMinute();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
      body: _WorldClockContent(
        relativeInfoBuilder: (timezoneId) =>
            _getRelativeDayAndOffset(context, timezoneId),
      ),
      floatingActionButton: MechanixFloatingActionButton(
        key: const Key('world_clock_add_city_button'),
        onPressed: _openAddCitySheet,
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _WorldClockContent extends StatelessWidget {
  final String Function(String timezoneId) relativeInfoBuilder;

  const _WorldClockContent({required this.relativeInfoBuilder});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorldClockBloc, WorldClockState, WorldClockState>(
      selector: (state) => state,
      builder: (context, state) {
        if (state is WorldClockLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is WorldClockLoaded) {
          if (state.clocks.isEmpty) {
            return const WorldClockEmptyState();
          }
          return _WorldClockListView(
            clocks: state.clocks,
            relativeInfoBuilder: relativeInfoBuilder,
          );
        } else if (state is WorldClockError) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        return const WorldClockEmptyState();
      },
    );
  }
}

class _WorldClockListView extends StatelessWidget {
  final List<WorldClock> clocks;
  final String Function(String timezoneId) relativeInfoBuilder;

  const _WorldClockListView({
    required this.clocks,
    required this.relativeInfoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: MechanixSwipableList(
        child: ListView.separated(
          itemCount: clocks.length,
          separatorBuilder: (context, index) =>
              MechanixDivider(color: theme.colorScheme.outline, space: 1),
          itemBuilder: (context, index) {
            final clockId = clocks[index].id;
            return BlocSelector<WorldClockBloc, WorldClockState, WorldClock?>(
              selector: (state) {
                if (state is WorldClockLoaded) {
                  for (final c in state.clocks) {
                    if (c.id == clockId) return c;
                  }
                }
                return null;
              },
              builder: (context, clock) {
                if (clock == null) return const SizedBox.shrink();
                return _WorldClockItemTile(
                  key: ValueKey(clock.id),
                  clock: clock,
                  relativeInfo: relativeInfoBuilder(clock.timezoneId),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _WorldClockItemTile extends StatelessWidget {
  final WorldClock clock;
  final String relativeInfo;

  const _WorldClockItemTile({
    super.key,
    required this.clock,
    required this.relativeInfo,
  });

  @override
  Widget build(BuildContext context) {
    return WorldClockItem(
      key: ValueKey(clock.id),
      clock: clock,
      relativeInfo: relativeInfo,
      onDelete: () {
        context.read<WorldClockBloc>().add(DeleteWorldClock(clock.id));
      },
    );
  }
}
