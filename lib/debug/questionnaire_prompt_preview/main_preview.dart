/// Отдельная точка входа для визуальной приёмки questionnaire_prompt на
/// реальном устройстве (планшет/телефон), см.
/// BRIEF_mobile_questionnaire_prompt_visual_qa.md.
///
/// Запуск:
///   flutter devices                       # найти id планшета
///   flutter run -t lib/debug/questionnaire_prompt_preview/main_preview.dart -d <device_id>
///
/// НЕ импортируется из lib/main.dart и не регистрируется в router.dart —
/// чисто debug-инструмент, живёт отдельно от прод-навигации.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/core/theme.dart';

import 'preview_screen.dart';

void main() {
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA — QA Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const QuestionnairePromptPreviewScreen(),
    );
  }
}
