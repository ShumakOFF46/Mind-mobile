import 'package:flutter/material.dart';

// ─── Токены цветов AURA ───────────────────────────────────
//
// Light                          Dark
// bg         #FAF7F5             #1C1414
// aiBubble   #F2E8E4             #2A1F1F
// userBubble #EDE8E3             #241D1D
// surface    #FFFFFF             #221818
// accent     #E8A0A0             #E8A0A0  (неизменный)
// textDark   #3D2C2C             #F5EDE8
// textSub    #9E7E7E             #8A7070
// hint       #B09090             #6A5555

class AuraColors {
  const AuraColors._();

  static const accent     = Color(0xFFE8A0A0);

  // Light
  static const lightBg         = Color(0xFFFAF7F5);
  static const lightAiBubble   = Color(0xFFF2E8E4);
  static const lightUserBubble = Color(0xFFEDE8E3);
  static const lightSurface    = Color(0xFFFFFFFF);
  static const lightTextDark   = Color(0xFF3D2C2C);
  static const lightTextSub    = Color(0xFF9E7E7E);
  static const lightHint       = Color(0xFFB09090);

  // Dark
  static const darkBg          = Color(0xFF1C1414);
  static const darkAiBubble    = Color(0xFF2A1F1F);
  static const darkUserBubble  = Color(0xFF241D1D);
  static const darkSurface     = Color(0xFF221818);
  static const darkTextDark    = Color(0xFFF5EDE8);
  static const darkTextSub     = Color(0xFF8A7070);
  static const darkHint        = Color(0xFF6A5555);
}

// ─── Расширение контекста — удобный доступ ────────────────

extension AuraTheme on BuildContext {
  AuraColorScheme get aura => Theme.of(this).brightness == Brightness.dark
      ? const AuraColorScheme.dark()
      : const AuraColorScheme.light();
}

class AuraColorScheme {
  final Color bg;
  final Color aiBubble;
  final Color userBubble;
  final Color surface;
  final Color textDark;
  final Color textSub;
  final Color hint;
  final Color accent;

  const AuraColorScheme.light()
      : bg         = AuraColors.lightBg,
        aiBubble   = AuraColors.lightAiBubble,
        userBubble = AuraColors.lightUserBubble,
        surface    = AuraColors.lightSurface,
        textDark   = AuraColors.lightTextDark,
        textSub    = AuraColors.lightTextSub,
        hint       = AuraColors.lightHint,
        accent     = AuraColors.accent;

  const AuraColorScheme.dark()
      : bg         = AuraColors.darkBg,
        aiBubble   = AuraColors.darkAiBubble,
        userBubble = AuraColors.darkUserBubble,
        surface    = AuraColors.darkSurface,
        textDark   = AuraColors.darkTextDark,
        textSub    = AuraColors.darkTextSub,
        hint       = AuraColors.darkHint,
        accent     = AuraColors.accent;
}

// ─── ThemeData ────────────────────────────────────────────

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AuraColors.lightBg,
        colorScheme: const ColorScheme.light(
          primary:   AuraColors.accent,
          surface:   AuraColors.lightSurface,
          onPrimary: Colors.white,
          onSurface: AuraColors.lightTextDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AuraColors.lightBg,
          foregroundColor: AuraColors.lightTextDark,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AuraColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: AuraColors.lightHint),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AuraColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AuraColors.lightTextDark),
        ),
        fontFamily: 'CormorantGaramond',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AuraColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary:   AuraColors.accent,
          surface:   AuraColors.darkSurface,
          onPrimary: Colors.white,
          onSurface: AuraColors.darkTextDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AuraColors.darkBg,
          foregroundColor: AuraColors.darkTextDark,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AuraColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: AuraColors.darkHint),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AuraColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AuraColors.darkTextDark),
        ),
        fontFamily: 'CormorantGaramond',
      );
}
