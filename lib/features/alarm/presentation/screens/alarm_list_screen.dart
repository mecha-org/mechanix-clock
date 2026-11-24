import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:mechanix_clock/core/utils/clockd_error_text.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/core/widgets/keyboard_list.dart';
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

/// Opens [EditAlarmScreen] for [alarm] (new when null). After saving, shows
/// "Alarm set for … from now", or "Couldn't save alarm: …" on failure.
Future<void> openAlarmEditor(BuildContext context, {Alarm? alarm}) async {
  final route = MaterialPageRoute<SavedAlarm>(
    builder: (context) => EditAlarmScreen(alarm: alarm),
  );
  final saved = await Navigator.push<SavedAlarm>(context, route);
  if (saved == null || !context.mounted) return;

  // push() returns as soon as the editor pops, while its closing animation
  // still runs. When that ends, the navigator re-orders its overlay and a
  // snackbar shown before then ends up hidden under the list, so wait.
  await _closed(route);
  final failure = await saved.result;
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;

  if (failure != null) {
    showAlarmError(
      context,
      l10n.alarm_save_failed(clockdErrorReason(l10n, failure)),
    );
    return;
  }
  if (!saved.alarm.isActive) return;

  final now = DateTime.now();
  final text = DateTimeUtils.alarmSetFor(
    l10n,
    saved.alarm.nextRing(now).difference(now),
  );
  AppLogger.i('[AlarmList] Saved alarm ${saved.alarm.id}: $text');
  MechanixSnackbar.text(
    position: MechanixSnackbarPosition.top,
    text: text,
  ).show(context, duration: const Duration(seconds: 2));
}

/// An alarm change failed: says so at the top, for longer than a success.
void showAlarmError(BuildContext context, String text) {
  AppLogger.e('[AlarmList] $text');
  MechanixSnackbar.text(
    position: MechanixSnackbarPosition.top,
    text: text,
  ).show(context, duration: const Duration(seconds: 2));
}

String _failureText(AppLocalizations l10n, AlarmFailure failure) {
  final reason = clockdErrorReason(l10n, failure.error);
  return switch (failure.change) {
    AlarmChange.save => l10n.alarm_save_failed(reason),
    AlarmChange.toggle => l10n.alarm_toggle_failed(reason),
    AlarmChange.delete => l10n.alarm_delete_failed(reason),
  };
}

/// Completes when [route]'s closing animation has finished (at most 1 s).
Future<void> _closed(ModalRoute<dynamic> route) async {
  final animation = route.animation;
  if (animation == null || animation.status == AnimationStatus.dismissed) {
    return;
  }
  final done = Completer<void>();
  void onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !done.isCompleted) {
      animation.removeStatusListener(onStatus);
      done.complete();
    }
  }

  animation.addStatusListener(onStatus);
  await done.future.timeout(const Duration(seconds: 1), onTimeout: () {});
}

class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

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
      body: BlocListener<AlarmBloc, AlarmState>(
        // A toggle or delete that failed (the list is already back to what
        // the daemon has).
        listenWhen: (previous, current) =>
            current is AlarmLoaded &&
            current.failure != null &&
            (previous is! AlarmLoaded || previous.failure != current.failure),
        listener: (context, state) => showAlarmError(
          context,
          _failureText(l10n, (state as AlarmLoaded).failure!),
        ),
        child: BlocSelector<AlarmBloc, AlarmState, AlarmState>(
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
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: MechanixSwipableList(
                  key: const Key('alarm_item_tap'),

                  // ↑/↓ move between alarms, Enter opens the editor.
                  child: KeyboardList(
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
                            return KeyboardListItem(
                              index: index,
                              onActivate: () =>
                                  openAlarmEditor(context, alarm: alarm),
                              child: _AlarmItem(
                                key: ValueKey(alarm.id),
                                alarm: alarm,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            } else if (state is AlarmError) {
              return _AlarmsUnavailable(error: state);
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
      ),
      floatingActionButton: MechanixFloatingActionButton(
        key: const Key('add_alarm_button'),
        onPressed: () => openAlarmEditor(context),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

/// The alarms couldn't be read: says why, with Retry. The list also comes
/// back by itself when mxclockd starts.
class _AlarmsUnavailable extends StatelessWidget {
  final AlarmError error;

  const _AlarmsUnavailable({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const Key('alarms_unavailable'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error.unavailable
                  ? l10n.alarms_unavailable_title
                  : l10n.alarms_load_failed_title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.unavailable
                  ? l10n.alarms_unavailable_body
                  : clockdErrorReason(l10n, error.error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            MechanixButton.filled(
              key: const Key('alarms_retry_button'),
              label: l10n.retry,
              onPressed: () =>
                  context.read<AlarmBloc>().add(const LoadAlarms()),
            ),
          ],
        ),
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
      extentRatio: 0.18,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => openAlarmEditor(context, alarm: alarm),
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
                // Two-digit hour: "02:11 PM".
                '${alarm.hour.toString().padLeft(2, '0')}:'
                '${alarm.minute.toString().padLeft(2, '0')} '
                '${alarm.isAm ? l10n.am : l10n.pm}',
                style: theme.textTheme.displayMedium!.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          if (alarm.label.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              alarm.label.trim(),
              key: Key('alarm_label_${alarm.id}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium!.copyWith(color: textColor),
            ),
          ],
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
            // Switching on an alarm whose time another alarm (that is on)
            // has is refused, as in the editor: one alarm per time.
            final state = context.read<AlarmBloc>().state;
            if (value &&
                state is AlarmLoaded &&
                alarmTimeTaken(
                  state.alarms,
                  hour: alarm.hour,
                  minute: alarm.minute,
                  isAm: alarm.isAm,
                  exceptId: alarm.id,
                )) {
              showAlarmError(
                context,
                AppLocalizations.of(context)!.alarm_already_exists,
              );
              return;
            }
            context.read<AlarmBloc>().add(ToggleAlarm(alarm.id));
          },
        ),
      ],
    );
  }
}
