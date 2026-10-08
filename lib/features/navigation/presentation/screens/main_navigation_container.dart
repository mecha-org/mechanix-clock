import 'package:flutter/material.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/alarm_list_screen.dart';
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
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<Widget> screens = [
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
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          MechanixNavigationDestination(
            icon: const Icon(Icons.alarm_outlined),
            label: l10n?.alarms ?? '',
          ),
          MechanixNavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            label: l10n?.stopwatch ?? '',
          ),
          MechanixNavigationDestination(
            icon: const Icon(Icons.public_outlined),
            label: l10n?.world_clock ?? '',
          ),
          MechanixNavigationDestination(
            icon: const Icon(Icons.hourglass_empty_outlined),
            label: l10n?.timers ?? '',
          ),
        ],
      ),
    );
  }
}
