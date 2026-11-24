import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/app_logger.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/core/widgets/clock_shortcuts.dart';
import 'package:mechanix_clock/core/widgets/keyboard_list.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/alarm_list_screen.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_bloc.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_event.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_state.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/screens/stopwatch_screen.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_state.dart';
import 'package:mechanix_clock/features/timer/presentation/timer_screen.dart';
import 'package:mechanix_clock/features/world_clock/presentation/screens/world_clock_screen.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets/widgets.dart';

/// The four tabs. Opens on the tab last used, a dot
/// on Stopwatch or Timer shows it is running.
class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  static const _alarmTab = 0;
  static const _stopwatchTab = 1;
  static const _tabCount = 4;

  /// Where the tab last used is saved.
  static const _lastTabKey = 'last_tab';

  int _currentIndex = _alarmTab;

  /// The user picked a tab before the saved one was read: keep theirs.
  bool _tabPicked = false;

  /// Keyboard focus of each tab, so ↑/↓ reach the tab's list.
  final _tabFocus = List.generate(
    _tabCount,
    (_) => GlobalKey<KeyboardListHostState>(),
  );

  @override
  void initState() {
    super.initState();
    _focusTab(_currentIndex);
    _restoreTab();
  }

  /// Moves to the tab the app was last left on. The app shows Alarms until
  /// it is read, and stays there when nothing was saved.
  Future<void> _restoreTab() async {
    var tab = _alarmTab;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_lastTabKey);
      if (saved != null && saved >= 0 && saved < _tabCount) {
        tab = saved;
      }
    } catch (e) {
      AppLogger.e('Reading the last tab: $e');
    }
    if (!mounted || _tabPicked || tab == _currentIndex) return;
    setState(() => _currentIndex = tab);
    _focusTab(tab);
  }

  /// Remembers [index] so the app opens on it next time.
  Future<void> _saveTab(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastTabKey, index);
    } catch (e) {
      AppLogger.e('Saving the last tab: $e');
    }
  }

  /// Gives the tab keyboard focus once it is on screen.
  void _focusTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && index == _currentIndex) {
        _tabFocus[index].currentState?.focus();
      }
    });
  }

  /// Ctrl+N on the Alarms tab: the alarm editor for a new alarm.
  bool _newAlarm() {
    if (_currentIndex != _alarmTab) return false;
    openAlarmEditor(context);
    return true;
  }

  /// Space on the Stopwatch tab: start or stop it.
  bool _toggleStopwatch() {
    if (_currentIndex != _stopwatchTab) return false;
    final bloc = context.read<StopwatchBloc>();
    bloc.add(
      bloc.state.status == StopwatchStatus.running
          ? StopStopwatch()
          : StartStopwatch(),
    );
    return true;
  }

  static const List<Widget> _screens = [
    AlarmListScreen(),
    StopwatchScreen(),
    WorldClockScreen(),
    TimerScreen(),
  ];

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    _tabPicked = true;
    setState(() {
      _currentIndex = index;
    });
    _focusTab(index);
    unawaited(_saveTab(index));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    // A dot on Stopwatch and Timer while one runs.
    // None for a paused or finished timer.
    final stopwatchRunning = context.select(
      (StopwatchBloc bloc) => bloc.state.status == StopwatchStatus.running,
    );
    final timerRunning = context.select(
      (TimerBloc bloc) => bloc.state.activeTimers.values.any(
        (t) => t.status == TimerStatus.running,
      ),
    );

    return ClockShortcuts(
      onNewAlarm: _newAlarm,
      onSpace: _toggleStopwatch,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            _screens.length,
            (index) => TickerMode(
              enabled: index == _currentIndex,
              // Hidden tabs can't take focus, so keys go to the shown one.
              child: ExcludeFocus(
                excluding: index != _currentIndex,
                child: KeyboardListHost(
                  key: _tabFocus[index],
                  child: RepaintBoundary(child: _screens[index]),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: RepaintBoundary(
          child: MechanixNavigationBar(
            height: kBottomNavigationBarHeight,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: [
              MechanixNavigationDestination(
                icon: ImageIcon(
                  const AssetImage(ClockIcons.alarm),
                  color: _currentIndex == 0
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                label: l10n?.alarms ?? '',
              ),
              MechanixNavigationDestination(
                icon: ImageIcon(
                  const AssetImage(ClockIcons.stopwatch),
                  color: _currentIndex == 1
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                badge: stopwatchRunning
                    ? const MechanixBadge(
                        key: Key('stopwatch_running_dot'),
                        variant: MechanixBadgeVariant.primary,
                      )
                    : null,
                label: l10n?.stopwatch ?? '',
              ),
              MechanixNavigationDestination(
                icon: ImageIcon(
                  const AssetImage(ClockIcons.worldClock),
                  color: _currentIndex == 2
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                label: l10n?.world_clock ?? '',
              ),
              MechanixNavigationDestination(
                icon: ImageIcon(
                  const AssetImage(ClockIcons.timer),
                  color: _currentIndex == 3
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                badge: timerRunning
                    ? const MechanixBadge(
                        key: Key('timer_running_dot'),
                        variant: MechanixBadgeVariant.primary,
                      )
                    : null,
                label: l10n?.timers ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
