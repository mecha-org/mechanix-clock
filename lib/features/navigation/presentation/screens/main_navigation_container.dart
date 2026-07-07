import 'package:flutter/material.dart';
import 'package:mechanix_clock/features/alarm/presentation/screens/alarm_list_screen.dart';
import 'package:mechanix_clock/features/alarm/presentation/widgets/bottom_nav_bar.dart';
import 'package:mechanix_clock/features/stopwatch/presentation/screens/stopwatch_screen.dart';
import 'package:mechanix_clock/features/timer/presentation/timer_screen.dart';
import 'package:mechanix_clock/features/world_clock/presentation/screens/world_clock_screen.dart';

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
    final List<Widget> screens = [
      const AlarmListScreen(),
      const StopwatchScreen(),
      const TimerScreen(),
      const WorldClockScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
