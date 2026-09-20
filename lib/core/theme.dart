import 'package:flutter/material.dart';

// ─── Токены цветов AURA Mind ──────────────────────────────
//
// Палитра «Dietitian» (референс от заказчика):
//   coconut cream   #FFFAF2   фон
//   honey oatmilk   #F6EAD4   (резерв)
//   oat latte       #DCD4C1   сообщения пользователя
//   peach protein   #EFD7CF   сообщения AURA
//   blush beet      #DDBAAE   контур на розовом
//   avocado smoothie#C2C395   плашки / карточки
//   savory sage     #818263   акцент, контур на зелёном
//
// Light: bg=coconut, aiBubble=peach, userBubble=oat, surface=avocado.
// ⚠ textDark (#454633) и hint (#9A9B7E) — производные от savory sage
//   (в палитре нет тёмного цвета для основного текста). Dark-схема тоже
//   производная: в референсе тёмной темы нет.

class AuraColors {
  const AuraColors._();

  // Палитра
  static const coconutCream    = Color(0xFFFFFAF2);
  static const honeyOatmilk    = Color(0xFFF6EAD4);
  static const oatLatte        = Color(0xFFDCD4C1);
  static const peachProtein    = Color(0xFFEFD7CF);
  static const blushBeet       = Color(0xFFDDBAAE);
  static const avocadoSmoothie = Color(0xFFC2C395);
  static const savorySage      = Color(0xFF818263);

  // Общие
  static const accent       = savorySage;
  static const strokeGreen  = savorySage; // контур кнопок/плашек на зелёном
  static const strokePink   = blushBeet;  // контур кнопок/плашек на розовом

  // Light
  static const lightBg         = coconutCream;
  static const lightAiBubble   = peachProtein;
  static const lightUserBubble = oatLatte;
  static const lightSurface    = avocadoSmoothie;
  static const lightTextDark   = Color(0xFF454633);
  static const lightTextSub    = savorySage;
  static const lightHint       = Color(0xFF9A9B7E);

  // Dark (производная от палитры)
  static const darkBg          = Color(0xFF23241B);
  static const darkAiBubble    = Color(0xFF3A2F2B);
  static const darkUserBubble  = Color(0xFF2F3025);
  static const darkSurface     = Color(0xFF3B3C2C);
  static const darkTextDark    = honeyOatmilk;
  static const darkTextSub     = avocadoSmoothie;
  static const darkHint        = savorySage;
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
  final Color strokeGreen;
  final Color strokePink;

  const AuraColorScheme.light()
      : bg          = AuraColors.lightBg,
        aiBubble    = AuraColors.lightAiBubble,
        userBubble  = AuraColors.lightUserBubble,
        surface     = AuraColors.lightSurface,
        textDark    = AuraColors.lightTextDark,
        textSub     = AuraColors.lightTextSub,
        hint        = AuraColors.lightHint,
        accent      = AuraColors.accent,
        strokeGreen = AuraColors.strokeGreen,
        strokePink  = AuraColors.strokePink;

  const AuraColorScheme.dark()
      : bg          = AuraColors.darkBg,
        aiBubble    = AuraColors.darkAiBubble,
        userBubble  = AuraColors.darkUserBubble,
        surface     = AuraColors.darkSurface,
        textDark    = AuraColors.darkTextDark,
        textSub     = AuraColors.darkTextSub,
        hint        = AuraColors.darkHint,
        accent      = AuraColors.avocadoSmoothie,
        strokeGreen = AuraColors.strokeGreen,
        strokePink  = AuraColors.strokePink;
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
