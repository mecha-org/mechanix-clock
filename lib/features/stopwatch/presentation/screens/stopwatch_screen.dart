import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/helper.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_bloc.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_event.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_state.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

class StopwatchScreen extends StatelessWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.stopwatch,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: BlocBuilder<StopwatchBloc, StopwatchState>(
        builder: (context, state) {
          final timeStr = formatDuration(state.elapsed, includeHundredths: true);
          // timeStr = "MM:SS.hh"
          final colonIdx = timeStr.indexOf(':');
          final dotIdx = timeStr.indexOf('.');
          final mm = timeStr.substring(0, colonIdx); // "00"
          final ss = timeStr.substring(colonIdx + 1, dotIdx); // "05"
          final hh = timeStr.substring(dotIdx); // ".02"

          return Column(
            children: [
              // ── Timer display ──────────────────────────────────────
              SizedBox(
                height: 260,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TimePart(text: mm, width: 110),
                      const _TimePart(text: ':', width: 24),
                      _TimePart(text: ss, width: 110),
                      _TimePart(text: hh, width: 120),
                    ],
                  ),
                ),
              ),

              // ── Divider ────────────────────────────────────────────
              if (state.laps.isNotEmpty)
                const Divider(
                  color: Color(0xFF212121),
                  height: 1,
                  thickness: 1,
                ),

              // ── Lap list ───────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  reverse: true, // newest lap at top
                  itemCount: state.laps.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Color(0xFF212121),
                    height: 1,
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final lap = state.laps[index];
                    return SizedBox(
                      height: 56,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              l10n.lap_number(lap.lapNumber),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFFADADAD),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatDuration(lap.duration, includeHundredths: true),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFFADADAD),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Bottom divider (above buttons) ─────────────────────
              const Divider(color: Color(0xFF212121), height: 1, thickness: 1),

              // ── Buttons ────────────────────────────────────────────
              Container(
                height: 72,
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Lap / Reset button
                    _StopwatchButton(
                      label: state.status == StopwatchStatus.stopped
                          ? l10n.reset
                          : l10n.lap,
                      enabled: state.status != StopwatchStatus.initial,
                      onTap: () {
                        if (state.status == StopwatchStatus.stopped) {
                          context.read<StopwatchBloc>().add(ResetStopwatch());
                        } else if (state.status == StopwatchStatus.running) {
                          context.read<StopwatchBloc>().add(LapStopwatch());
                        }
                      },
                    ),
                    // Start / Stop button
                    _StopwatchButton(
                      label: state.status == StopwatchStatus.running
                          ? l10n.stop
                          : l10n.start,
                      enabled: true,
                      onTap: () {
                        if (state.status == StopwatchStatus.running) {
                          context.read<StopwatchBloc>().add(StopStopwatch());
                        } else {
                          context.read<StopwatchBloc>().add(StartStopwatch());
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Extracted stateless widgets ──────────────────────────────────────────────

class _TimePart extends StatelessWidget {
  final String text;
  final double width;

  const _TimePart({required this.text, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w300,
          fontSize: 80, // matches image — larger than before
          color: Color(0xFFDDDDDD),
          height: 1.0,
        ),
      ),
    );
  }
}

class _StopwatchButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _StopwatchButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 180,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          border: Border.all(
            color: enabled
                ? const Color(0xFF474747)
                : const Color(0xFF474747).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            height: 1.2,
            color: enabled
                ? const Color(0xFFADADAD)
                : const Color(0xFFADADAD).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
