import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_state.dart';
import 'package:mechanix_clock/features/alarm/data/models/alarm_model.dart';
import 'package:mechanix_clock/features/alarm/data/utils/date_time_utils.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/day_bubble.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/delete_alarm_confirmation_sheet.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

import 'edit_alarm_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AlarmBloc>().add(LoadAlarms());
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
          l10n.alarms.toUpperCase(),
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
      body: BlocSelector<AlarmBloc, AlarmState, AlarmState>(
        selector: (state) => state,
        builder: (context, state) {
          if (state is AlarmLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AlarmLoaded) {
            if (state.alarms.isEmpty) {
              return Center(
                child: Text(
                  l10n.no_alarms,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              );
            }
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: MechanixSwipableList(
                key: const Key('alarm_item_tap'),

                child: ListView.builder(
                  itemCount: state.alarms.length,
                  itemBuilder: (context, index) {
                    final alarmId = state.alarms[index].id;
                    return BlocSelector<AlarmBloc, AlarmState, Alarm?>(
                      selector: (state) {
                        if (state is AlarmLoaded) {
                          for (final a in state.alarms) {
                            if (a.id == alarmId) return a;
                          }
                        }
                        return null;
                      },
                      builder: (context, alarm) {
                        if (alarm == null) return const SizedBox.shrink();
                        return _AlarmItem(
                          key: ValueKey(alarm.id),
                          alarm: alarm,
                        );
                      },
                    );
                  },
                ),
              ),
            );
          } else {
            return Center(
              child: Text(
                l10n.alarms,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: MechanixFloatingActionButton(
        key: const Key('add_alarm_button'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditAlarmScreen()),
          );
        },
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _AlarmItem extends StatelessWidget {
  final Alarm alarm;

  const _AlarmItem({super.key, required this.alarm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color textColor = alarm.isActive
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    final days = DateTimeUtils.getWeekdayAbbreviations(context);

    return MechanixSwipableListTile(
      minHeight: 88.0,
      extentRatio: 0.28,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditAlarmScreen(alarm: alarm),
          ),
        );
      },
      actions: [
        MechanixIconButton.filled(
          key: Key('alarm_list_delete_button_${alarm.id}'),
          onPressed: () async {
            final confirmed = await showDeleteAlarmConfirmationSheet(context);
            if (confirmed == true && context.mounted) {
              context.read<AlarmBloc>().add(DeleteAlarm(alarm.id));
            }
          },
          icon: ImageIcon(
            const AssetImage(ClockIcons.delete),
            color: theme.colorScheme.onPrimary,
          ),
          size: IconButtonSize.xLarge,
          type: ButtonType.rounded,
          backgroundColor: theme.colorScheme.errorContainer,
        ),
      ],
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${alarm.hour}:${alarm.minute.toString().padLeft(2, '0')} '
                '${alarm.isAm ? l10n.am : l10n.pm}',
                style: theme.textTheme.displayMedium!.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (alarm.repeatDays.isEmpty)
            Text(
              l10n.once,
              style: theme.textTheme.labelLarge!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else if (alarm.repeatDays.length == 7)
            Text(
              l10n.daily,
              style: theme.textTheme.labelLarge!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (index) {
                final isSelected = alarm.repeatDays.contains(index);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: DayBubble(
                    size: 22,
                    label: days[index],
                    isSelected: isSelected,
                  ),
                );
              }),
            ),
        ],
      ),
      trailingWidgets: [
        MechanixSwitch(
          value: alarm.isActive,
          onChanged: (value) {
            context.read<AlarmBloc>().add(ToggleAlarm(alarm.id));
          },
        ),
      ],
    );
  }
}
