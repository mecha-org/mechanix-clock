import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_bloc.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/alarm_list_screen.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/screens/stopwatch_screen.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_bloc.dart';
import 'package:mechanix_clock/features/timer/bloc/timer_event.dart';
import 'package:mechanix_clock/features/timer/presentation/timer_screen.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_event.dart';
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
  int _currentIndex = 0;

  // Track tabs whose initial data has already been requested.
  final Set<int> _initializedTabs = {0};

  @override
  void initState() {
    super.initState();

    // Load alarms because the Alarm tab is the initial screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AlarmBloc>().add(LoadAlarms());
    });
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Load data only the first time the user visits a tab.
    if (_initializedTabs.add(index)) {
      switch (index) {
        case 0:
          context.read<AlarmBloc>().add(LoadAlarms());
          break;

        case 2:
          context.read<WorldClockBloc>().add(LoadWorldClocks());
          break;

        case 3:
          context.read<TimerBloc>().add(LoadTimerPresets());
          break;

        case 1:
          // StopwatchBloc has no initial loading event.
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final screens = [
      const AlarmListScreen(),
      const StopwatchScreen(),
      const WorldClockScreen(),
      const TimerScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: MechanixNavigationBar(
        height: kBottomNavigationBarHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          MechanixNavigationDestination(
            icon: ImageIcon(
              const AssetImage(ClockIcons.alarm),
              color: colorScheme.onSurfaceVariant,
            ),
            label: l10n?.alarms ?? '',
          ),
          MechanixNavigationDestination(
            icon: ImageIcon(
              const AssetImage(ClockIcons.stopwatch),
              color: colorScheme.onSurfaceVariant,
            ),
            label: l10n?.stopwatch ?? '',
          ),
          MechanixNavigationDestination(
            icon: ImageIcon(
              const AssetImage(ClockIcons.worldClock),
              color: colorScheme.onSurfaceVariant,
            ),
            label: l10n?.world_clock ?? '',
          ),
          MechanixNavigationDestination(
            icon: ImageIcon(
              const AssetImage(ClockIcons.timer),
              color: colorScheme.onSurfaceVariant,
            ),
            label: l10n?.timers ?? '',
          ),
        ],
      ),
    );
  }
}
