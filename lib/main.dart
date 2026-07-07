import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/data/repository/alarm_repository.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_bloc.dart';
import 'package:mechanix_clock/features/world_clock/bloc/world_clock_event.dart';
import 'package:mechanix_clock/features/world_clock/data/repository/world_clock_repository.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:show_fps/show_fps.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'core/theme/app_theme.dart';
import 'features/alarm/bloc/alarm_bloc.dart';
import 'features/navigation/presentation/screens/main_navigation_container.dart';
import 'features/stopwatch/bloc/stopwatch_bloc.dart';
import 'features/timer/bloc/timer_bloc.dart';
import 'features/timer/bloc/timer_event.dart';
import 'features/timer/data/repository/timer_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  final alarmRepository = AlarmRepository();
  final timerRepository = TimerRepository();
  final worldClockRepository = WorldClockRepository();
  final systemAlarmService = SystemAlarmService();

  _configureLocalTimezone(systemAlarmService);

  runApp(
    MechanixClockApp(
      repository: alarmRepository,
      timerRepository: timerRepository,
      worldClockRepository: worldClockRepository,
      systemAlarmService: systemAlarmService,
    ),
  );
}

void _configureLocalTimezone(SystemAlarmService systemAlarmService) {
  final timezoneName = systemAlarmService.getTimezoneSync();
  try {
    tz.setLocalLocation(tz.getLocation(timezoneName));
  } catch (_) {
    tz.setLocalLocation(tz.UTC);
  }
}

class MechanixClockApp extends StatelessWidget {
  final AlarmRepository repository;
  final TimerRepository timerRepository;
  final WorldClockRepository worldClockRepository;
  final SystemAlarmService systemAlarmService;

  const MechanixClockApp({
    super.key,
    required this.repository,
    required this.timerRepository,
    required this.worldClockRepository,
    required this.systemAlarmService,
  });

  @override
  Widget build(BuildContext context) {
    final showFps = Platform.environment['SHOW_FPS'] == 'true';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AlarmBloc(
            repository: repository,
            systemAlarmService: systemAlarmService,
          )..add(LoadAlarms()),
        ),
        BlocProvider(create: (context) => StopwatchBloc()),
        BlocProvider(
          create: (context) => TimerBloc(
            repository: timerRepository,
            systemAlarmService: systemAlarmService,
          )..add(LoadTimerPresets()),
        ),
        BlocProvider(
          create: (context) =>
              WorldClockBloc(repository: worldClockRepository)
                ..add(LoadWorldClocks()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mechanix Clock',
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainNavigationContainer(),
        builder: showFps
            ? (context, child) {
                return ShowFPS(
                  visible: showFps,
                  showChart: false,
                  child: child!,
                );
              }
            : null,
      ),
    );
  }
}
