import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/workbench_localizations.dart';
import '../services/app_environment.dart';
import 'home_screen.dart';
import 'theme.dart';

class WorkbenchApp extends StatelessWidget {
  const WorkbenchApp({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: WorkbenchPalette.coral,
          brightness: Brightness.light,
        ).copyWith(
          primary: WorkbenchPalette.coral,
          onPrimary: Colors.white,
          primaryContainer: WorkbenchPalette.coralWash,
          onPrimaryContainer: WorkbenchPalette.coralInk,
          secondary: WorkbenchPalette.honey,
          onSecondary: WorkbenchPalette.inkPrimary,
          secondaryContainer: const Color(0xFFFCEBC7),
          onSecondaryContainer: const Color(0xFF7A5A1A),
          tertiary: WorkbenchPalette.matcha,
          onTertiary: WorkbenchPalette.inkPrimary,
          surface: WorkbenchPalette.paper,
          onSurface: WorkbenchPalette.inkPrimary,
          surfaceContainerHighest: WorkbenchPalette.creamDeep,
          onSurfaceVariant: WorkbenchPalette.inkSecondary,
          outline: WorkbenchPalette.sand,
          outlineVariant: WorkbenchPalette.sandLine,
          error: const Color(0xFFC1413B),
        );

    final baseText = Theme.of(context).textTheme;
    final textTheme = baseText
        .apply(
          bodyColor: WorkbenchPalette.inkPrimary,
          displayColor: WorkbenchPalette.inkPrimary,
        )
        .copyWith(
          displayLarge: baseText.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
          headlineMedium: baseText.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          headlineSmall: baseText.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          titleLarge: baseText.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          titleSmall: baseText.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
          bodyLarge: baseText.bodyLarge?.copyWith(height: 1.6),
          bodyMedium: baseText.bodyMedium?.copyWith(height: 1.6),
          bodySmall: baseText.bodySmall?.copyWith(
            color: WorkbenchPalette.inkSecondary,
            height: 1.5,
          ),
          labelMedium: baseText.labelMedium?.copyWith(
            color: WorkbenchPalette.inkSecondary,
            letterSpacing: 0.4,
          ),
          labelSmall: baseText.labelSmall?.copyWith(
            color: WorkbenchPalette.inkSoft,
            letterSpacing: 0.6,
          ),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: const Locale('zh'),
      supportedLocales: WorkbenchLocalizations.supportedLocales,
      localeResolutionCallback: WorkbenchLocalizations.resolveLocale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        WorkbenchLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: WorkbenchPalette.cream,
        textTheme: textTheme,
        splashColor: WorkbenchPalette.coralWash.withValues(alpha: 0.4),
        highlightColor: WorkbenchPalette.coralWash.withValues(alpha: 0.25),
        appBarTheme: const AppBarTheme(
          backgroundColor: WorkbenchPalette.cream,
          surfaceTintColor: Colors.transparent,
          foregroundColor: WorkbenchPalette.inkPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: WorkbenchPalette.inkPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: WorkbenchPalette.paper,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: WorkbenchPalette.sand),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: WorkbenchPalette.coral,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 14.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            foregroundColor: WorkbenchPalette.coralInk,
            side: const BorderSide(color: WorkbenchPalette.sand),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: WorkbenchPalette.coralInk,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: WorkbenchPalette.inkPrimary,
            backgroundColor: WorkbenchPalette.paper.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: WorkbenchPalette.sand),
            ),
            padding: const EdgeInsets.all(10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: WorkbenchPalette.paper,
          hintStyle: const TextStyle(
            color: WorkbenchPalette.inkSoft,
            fontSize: 13,
          ),
          labelStyle: const TextStyle(
            color: WorkbenchPalette.inkSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: WorkbenchPalette.sand),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: WorkbenchPalette.sand),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: WorkbenchPalette.coral,
              width: 1.4,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: WorkbenchPalette.paper,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titleTextStyle: const TextStyle(
            color: WorkbenchPalette.inkPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          contentTextStyle: const TextStyle(
            color: WorkbenchPalette.inkSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: WorkbenchPalette.inkPrimary,
          contentTextStyle: const TextStyle(
            color: WorkbenchPalette.cream,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return WorkbenchPalette.creamDeep;
            }
            return WorkbenchPalette.paper;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return WorkbenchPalette.sand;
            }
            if (states.contains(WidgetState.selected)) {
              return WorkbenchPalette.coral;
            }
            return WorkbenchPalette.creamDeep;
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.transparent;
            }
            return WorkbenchPalette.sandLine;
          }),
          trackOutlineWidth: WidgetStateProperty.all(1.2),
          thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Icon(
                Icons.check_rounded,
                color: WorkbenchPalette.coral,
                size: 16,
              );
            }
            return const Icon(
              Icons.close_rounded,
              color: WorkbenchPalette.inkSoft,
              size: 14,
            );
          }),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.transparent,
          iconColor: WorkbenchPalette.inkSecondary,
          textColor: WorkbenchPalette.inkPrimary,
        ),
        dividerTheme: const DividerThemeData(
          color: WorkbenchPalette.sandLine,
          thickness: 1,
          space: 1,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: WorkbenchPalette.coral,
          linearTrackColor: WorkbenchPalette.sand,
        ),
      ),
      home: HomeScreen(environment: environment),
    );
  }
}
