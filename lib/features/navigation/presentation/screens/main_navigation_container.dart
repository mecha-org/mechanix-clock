import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/core/widgets/clock_shortcuts.dart';
import 'package:mechanix_clock/core/widgets/keyboard_list.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/alarm_list_screen.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_bloc.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_event.dart';
import 'package:mechanix_clock/features/stopwatch/bloc/stopwatch_state.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/screens/stopwatch_screen.dart';
import 'package:mechanix_clock/features/timer/presentation/timer_screen.dart';
import 'package:mechanix_clock/features/world_clock/presentation/screens/world_clock_screen.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  static const _alarmTab = 0;
  static const _stopwatchTab = 1;

  int _currentIndex = 0;

  /// Keyboard focus of each tab, so ↑/↓ reach the tab's list.
  final _tabFocus = List.generate(4, (_) => GlobalKey<KeyboardListHostState>());

  @override
  void initState() {
    super.initState();
    _focusTab(_currentIndex);
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

    setState(() {
      _currentIndex = index;
    });
    _focusTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

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
                label: l10n?.timers ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
