import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_bloc.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_event.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_state.dart';
import 'package:mechanix_clock/features/stopwatch/data/models/lap_time_model.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/widgets/lap_list_item.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class StopwatchScreen extends StatelessWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        primary: false,
        title: Text(
          l10n.stopwatch.toUpperCase(),
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
      body: Column(
        children: [
          // ── Lap List Section (bottom-aligned & auto-scrolled to bottom) ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: BlocSelector<StopwatchBloc, StopwatchState, List<LapTime>>(
                selector: (state) => state.laps,
                builder: (context, laps) {
                  return _LapListView(laps: laps);
                },
              ),
            ),
          ),

          // ── Digital Timer Display ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
            child: RepaintBoundary(
              child: BlocSelector<StopwatchBloc, StopwatchState, Duration>(
                selector: (state) => state.elapsed,
                builder: (context, elapsed) {
                  return _StopwatchTimeDisplay(elapsed: elapsed);
                },
              ),
            ),
          ),

          // ── Action Buttons ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 36.0, top: 36.0),
            child: BlocSelector<StopwatchBloc, StopwatchState, StopwatchStatus>(
              selector: (state) => state.status,
              builder: (context, status) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left button: Lap / Reset
                    if (status == StopwatchStatus.running)
                      MechanixIconButton.filled(
                        key: const Key('stopwatch_lap_button'),
                        onPressed: () {
                          context.read<StopwatchBloc>().add(LapStopwatch());
                        },
                        icon: ImageIcon(
                          const AssetImage(ClockIcons.add),
                          color: theme.colorScheme.onPrimary,
                        ),
                        size: IconButtonSize.large,
                        type: ButtonType.rounded,
                        backgroundColor: theme.colorScheme.primary,
                      )
                    else if (status == StopwatchStatus.stopped)
                      MechanixIconButton.filled(
                        key: const Key('stopwatch_reset_button'),
                        onPressed: () {
                          context.read<StopwatchBloc>().add(ResetStopwatch());
                        },
                        icon: ImageIcon(
                          const AssetImage(ClockIcons.reset),
                          color: theme.colorScheme.onSurface,
                        ),
                        size: IconButtonSize.large,
                        type: ButtonType.rounded,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                      )
                    else
                      MechanixIconButton.outline(
                        key: const Key('stopwatch_lap_button'),
                        onPressed: null,
                        icon: ImageIcon(
                          const AssetImage(ClockIcons.add),
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(
                            120,
                          ),
                        ),
                        size: IconButtonSize.large,
                        type: ButtonType.rounded,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                      ),

                    const SizedBox(width: 32),

                    // Right button: Start / Stop
                    if (status == StopwatchStatus.running)
                      MechanixIconButton.filled(
                        key: const Key('stopwatch_stop_button'),
                        onPressed: () {
                          context.read<StopwatchBloc>().add(StopStopwatch());
                        },
                        icon: ImageIcon(
                          const AssetImage(ClockIcons.pause),
                          color: theme.colorScheme.onSurface,
                        ),
                        size: IconButtonSize.large,
                        type: ButtonType.rounded,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                      )
                    else
                      MechanixIconButton.filled(
                        key: const Key('stopwatch_start_button'),
                        onPressed: () {
                          context.read<StopwatchBloc>().add(StartStopwatch());
                        },
                        icon: ImageIcon(
                          const AssetImage(ClockIcons.play),
                          color: theme.colorScheme.onPrimary,
                        ),
                        size: IconButtonSize.large,
                        type: ButtonType.rounded,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LapListView extends StatefulWidget {
  final List<LapTime> laps;

  const _LapListView({required this.laps});

  @override
  State<_LapListView> createState() => _LapListViewState();
}

class _LapListViewState extends State<_LapListView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.laps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: ListView.builder(
          reverse: true,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: widget.laps.length,
          itemBuilder: (context, index) {
            // The latest lap appears at the bottom.
            final lap = widget.laps[index];
            final isLatest = index == 0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LapListItem(
                  key: ValueKey(lap.lapNumber),
                  lap: lap,
                  isLatest: isLatest,
                ),
                MechanixDivider(color: theme.colorScheme.outline),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StopwatchTimeDisplay extends StatelessWidget {
  final Duration elapsed;

  const _StopwatchTimeDisplay({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dimColor = colorScheme.onSurfaceVariant;
    final activeColor = colorScheme.onSurface;

    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    final hundredths = (elapsed.inMilliseconds.remainder(1000) / 10).truncate();

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hStr = '${twoDigits(hours)}:';
    final mStr = '${twoDigits(minutes)}:';
    final sStr = twoDigits(seconds);
    final hhStr = '.${twoDigits(hundredths)}';

    Color hColor, mColor, sColor, hhColor;

    if (elapsed == Duration.zero) {
      hColor = dimColor;
      mColor = dimColor;
      sColor = dimColor;
      hhColor = dimColor;
    } else if (hours > 0) {
      hColor = activeColor;
      mColor = activeColor;
      sColor = activeColor;
      hhColor = activeColor;
    } else if (minutes > 0) {
      hColor = dimColor;
      mColor = activeColor;
      sColor = activeColor;
      hhColor = activeColor;
    } else {
      hColor = dimColor;
      mColor = dimColor;
      sColor = activeColor;
      hhColor = activeColor;
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.textTheme.displayLarge!.copyWith(
          fontFamily: MechanixFontFamily.geistMono,
          fontSize: 80,
          fontWeight: FontWeight.w400,
          letterSpacing: -4,
        ),
        children: [
          TextSpan(
            text: hStr,
            style: TextStyle(color: hColor),
          ),
          TextSpan(
            text: mStr,
            style: TextStyle(color: mColor),
          ),
          TextSpan(
            text: sStr,
            style: TextStyle(color: sColor),
          ),
          TextSpan(
            text: hhStr,
            style: TextStyle(color: hhColor),
          ),
        ],
      ),
    );
  }
}
