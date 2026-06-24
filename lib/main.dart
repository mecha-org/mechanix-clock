import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/system_alarm_service.dart';
import 'package:mechanix_clock/features/alarm/bloc/alarm_event.dart';
import 'package:mechanix_clock/features/alarm/data/repository/alarm_repository.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';
import 'package:show_fps/show_fps.dart';

import 'core/theme/app_theme.dart';
import 'features/alarm/bloc/alarm_bloc.dart';
import 'features/navigation/presentation/screens/main_navigation_container.dart';
import 'features/stopwatch/bloc/stopwatch_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final alarmRepository = AlarmRepository();
  final systemAlarmService = SystemAlarmService();
  runApp(
    MechanixClockApp(
      repository: alarmRepository,
      systemAlarmService: systemAlarmService,
    ),
  );
}

class MechanixClockApp extends StatelessWidget {
  final AlarmRepository repository;
  final SystemAlarmService systemAlarmService;

  const MechanixClockApp({
    super.key,
    required this.repository,
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
