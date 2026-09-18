import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/api/api_client.dart';
import 'core/l10n/app_localizations.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'core/push/local_notifications.dart';
import 'core/push/push_navigation.dart';
import 'core/push/push_providers.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNotifications.init();
  await ApiClient.init();
  await AppStorage.initAvatarNotifier();

  // Push-уведомления (CONTRACT_push_notifications_v1 §4): PushNavigation
  // резолвит data.screen -> маршрут и дёргает appRouter.go() без
  // зависимости от BuildContext (тап может прийти вне активного дерева
  // виджетов — background/terminated старт). Привязка — здесь, а не
  // top-level side-effect в router.dart (см. коммит-историю: прежний
  // вариант ловил unused_element в flutter analyze).
  PushNavigation.router = appRouter;

  runApp(const ProviderScope(child: VibeBitApp()));
}

class VibeBitApp extends ConsumerStatefulWidget {
  const VibeBitApp({super.key});

  @override
  ConsumerState<VibeBitApp> createState() => _VibeBitAppState();
}

class _VibeBitAppState extends ConsumerState<VibeBitApp> {
  @override
  void initState() {
    super.initState();
    // Push-инфраструктура (CONTRACT_push_notifications_v1): слушатели
    // прикрепляются всегда, регистрация токена — только если разрешение
    // уже дано ранее и юзер залогинен (permission-запрос происходит
    // отдельно, после логина — см. login_screen.dart).
    final pushService = ref.read(pushServiceProvider);
    pushService.attachListeners();
    pushService.registerIfAuthorizedAndLoggedIn();
    pushService.handleInitialMessage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title:                      'AURA',
      debugShowCheckedModeBanner: false,
      theme:       AppTheme.light,
      darkTheme:   AppTheme.dark,
      themeMode:   ThemeMode.system,
      routerConfig: appRouter,

      // ─── Локализация ──────────────────────────────────
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // Flutter-встроенные (нужны для Material виджетов — AlertDialog и т.д.)
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
