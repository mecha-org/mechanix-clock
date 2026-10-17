import 'package:flutter/material.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _screens.length,
          (index) => TickerMode(
            enabled: index == _currentIndex,
            child: RepaintBoundary(child: _screens[index]),
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
    );
  }
}
