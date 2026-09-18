import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/storage.dart';
import 'core/legal_consent_gate_cache.dart';
import 'features/auth/login_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/legal_consent/regional_consent_screen.dart';
import 'features/legal_consent/underage_blocked_screen.dart';

// Слайд слева направо (для Calendar)
CustomTransitionPage _slideFromLeft<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
  );
}

// Слайд справа налево (для Profile)
CustomTransitionPage _slideFromRight<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final name = await AppStorage.getUserName();
    final loc = state.matchedLocation;
    final onLogin = loc == '/login';
    final onLegalConsent = loc.startsWith('/legal-consent');

    // v4 (CONTRACT_legal_consent_gate_v4.md): /legal-consent/* —
    // самодостаточные состояния. Underage достигается ДО того, как
    // getUserName() вообще заполнен (регистрация провалилась, аккаунт не
    // создан) — обычная name-based redirect-логика их не должна трогать,
    // иначе underage-экран немедленно перекинуло бы на /login.
    if (onLegalConsent) return null;

    if (name != null && onLogin) return '/chat';
    if (name == null && !onLogin) return '/login';
    if (name == null) return null;

    // v4 (BRIEF §3): региональный гейт — проверяется один раз за сессию
    // (кэш в LegalConsentGateCache, fail-open при сетевой ошибке — см.
    // комментарий в самом кэше), не на каждую навигацию.
    final passed = await LegalConsentGateCache.ensureRegionalPassed();
    if (!passed) return '/legal-consent/regional';

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/legal-consent/regional',
      builder: (context, state) {
        final args = state.extra as RegionalConsentArgs?;
        return RegionalConsentScreen(
          detectedRegion: args?.detectedRegion,
          regionLabel: args?.regionLabel,
        );
      },
    ),
    GoRoute(
      path: '/legal-consent/underage',
      builder: (context, state) => const UnderageBlockedScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/calendar',
      pageBuilder: (context, state) =>
          _slideFromLeft(context, state, const CalendarScreen()),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) =>
          _slideFromRight(context, state, const ProfileScreen()),
    ),
  ],
);
