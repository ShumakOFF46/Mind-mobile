import 'package:go_router/go_router.dart';

/// Резолвит deep-link из push-уведомления (CONTRACT_push_notifications_v1
/// §4) в маршрут go_router. resolveRoute() — чистая функция, тестируется
/// без Firebase/GoRouter.
class PushNavigation {
  PushNavigation._();

  /// Устанавливается один раз в main.dart сразу после создания appRouter.
  static GoRouter? router;

  static const Map<String, String> _routes = {
    'chat': '/chat',
    'calendar': '/calendar',
    'calendar_event': '/calendar', // event_id пока не используется —
                                    // детальная модалка открывается по
                                    // тапу в самом календаре, не по пушу
    'profile': '/profile',
  };

  static const String _fallbackRoute = '/chat';

  /// Неизвестный/отсутствующий screen -> fallback на главный экран.
  /// Тот же принцип, что UnknownBlock для SDUI — не падать, не игнорировать.
  static String resolveRoute(Map<String, dynamic> data) {
    final screen = data['screen'] as String?;
    return _routes[screen] ?? _fallbackRoute;
  }

  static void handle(Map<String, dynamic> data) {
    final activeRouter = router;
    if (activeRouter == null) return;
    activeRouter.go(resolveRoute(data));
  }
}
