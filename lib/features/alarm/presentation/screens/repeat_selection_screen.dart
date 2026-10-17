import 'package:flutter/material.dart';
import 'package:mechanix_clock/features/alarm/data/utils/date_time_utils.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/day_bubble.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

enum RepeatType { once, daily, custom }

class RepeatSelectionScreen extends StatefulWidget {
  final List<int> initialDays;
  const RepeatSelectionScreen({super.key, required this.initialDays});

  @override
  State<RepeatSelectionScreen> createState() => _RepeatSelectionScreenState();
}

class _RepeatSelectionScreenState extends State<RepeatSelectionScreen> {
  late RepeatType _repeatType;
  late List<int> _customDays;

  @override
  void initState() {
    super.initState();
    if (widget.initialDays.isEmpty) {
      _repeatType = RepeatType.once;
      _customDays = [];
    } else if (widget.initialDays.length == 7) {
      _repeatType = RepeatType.daily;
      _customDays = List<int>.from(widget.initialDays);
    } else {
      _repeatType = RepeatType.custom;
      _customDays = List<int>.from(widget.initialDays);
    }
  }

  List<int> get _resultDays {
    switch (_repeatType) {
      case RepeatType.once:
        return [];
      case RepeatType.daily:
        return [0, 1, 2, 3, 4, 5, 6];
      case RepeatType.custom:
        final sorted = List<int>.from(_customDays)..sort();
        return sorted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final days = DateTimeUtils.getWeekdayAbbreviations(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        primary: false,
        backgroundColor: Colors.transparent,
        leading: MechanixIconButton.standard(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          MechanixIconButton.standard(
            key: const Key('repeat_done_button'),
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _resultDays),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Once option
            MechanixListTile(
              key: const Key('option_repeat_once'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leadingWidgets: [
                MechanixRadio<RepeatType>(
                  value: RepeatType.once,
                  groupValue: _repeatType,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _repeatType = val);
                    }
                  },
                ),
              ],
              labelText: l10n.once,
              trailingText: l10n.default_label,
              onTap: () {
                setState(() => _repeatType = RepeatType.once);
              },
            ),
            const SizedBox(height: 8),

            // Daily option
            MechanixListTile(
              key: const Key('option_repeat_daily'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leadingWidgets: [
                MechanixRadio<RepeatType>(
                  value: RepeatType.daily,
                  groupValue: _repeatType,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _repeatType = val);
                    }
                  },
                ),
              ],
              labelText: l10n.daily,
              onTap: () {
                setState(() => _repeatType = RepeatType.daily);
              },
            ),
            const SizedBox(height: 8),

            // Custom option
            MechanixListTile(
              key: const Key('option_repeat_custom'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leadingWidgets: [
                MechanixRadio<RepeatType>(
                  value: RepeatType.custom,
                  groupValue: _repeatType,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _repeatType = val);
                    }
                  },
                ),
              ],
              labelText: l10n.custom,
              onTap: () {
                setState(() => _repeatType = RepeatType.custom);
              },
              trailingWidgets: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 8, // Gap between bubbles
                    children: List.generate(7, (index) {
                      final isSelected =
                          _repeatType == RepeatType.custom &&
                          _customDays.contains(index);

                      return DayBubble(
                        key: Key('day_$index'),
                        size: 40,
                        label: days[index],
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _repeatType = RepeatType.custom;

                            if (_customDays.contains(index)) {
                              _customDays.remove(index);
                            } else {
                              _customDays.add(index);
                              _customDays.sort();
                            }
                          });
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
