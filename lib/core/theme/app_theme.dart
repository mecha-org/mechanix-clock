import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF151515);
  static const Color cardBackground = Color(0xFF2D2D2D);
  static const Color textPrimary = Color(0xFFDDDDDD);
  static const Color textSecondary = Color(0xFFADADAD);
  static const Color textGrey = Color(0xFF808080);
  static const Color textDim = Color(0xFF717171);
  static const Color textOffWhite = Color(0xFFEEEEEE);
  static const Color border = Color(0xFF2D2D2D);
  static const Color buttonBorder = Color(0xFF474747);
  static const Color accent = Color(0xFFDDDDDD);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Sora',
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      hoverColor: Colors.transparent,
      highlightColor: Colors.white.withAlpha(25),
      splashColor: Colors.white.withAlpha(25),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      scrollbarTheme: const ScrollbarThemeData(
        radius: Radius.circular(4),
        thickness: WidgetStatePropertyAll(4),
        thumbColor: WidgetStatePropertyAll(AppColors.textGrey),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.linux: CupertinoPageTransitionsBuilder()},
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withAlpha(25);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.transparent;
            }
            return null;
          }),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 60,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: AppColors.textDim,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        labelLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
