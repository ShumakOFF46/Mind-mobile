import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/push/push_navigation.dart';

void main() {
  group('PushNavigation.resolveRoute', () {
    test('chat -> /chat', () {
      expect(PushNavigation.resolveRoute({'screen': 'chat'}), '/chat');
    });

    test('calendar -> /calendar', () {
      expect(PushNavigation.resolveRoute({'screen': 'calendar'}), '/calendar');
    });

    test('calendar_event -> /calendar', () {
      expect(
        PushNavigation.resolveRoute({'screen': 'calendar_event', 'event_id': 'x'}),
        '/calendar',
      );
    });

    test('profile -> /profile', () {
      expect(PushNavigation.resolveRoute({'screen': 'profile'}), '/profile');
    });

    test('неизвестный screen -> fallback /chat (не падает)', () {
      expect(PushNavigation.resolveRoute({'screen': 'nonexistent'}), '/chat');
    });

    test('отсутствующий ключ screen -> fallback /chat', () {
      expect(PushNavigation.resolveRoute({}), '/chat');
    });
  });
}
