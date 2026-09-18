import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_service.dart';

/// DI-точка для PushService — никаких ручных `PushService()` внутри виджетов.
final pushServiceProvider = Provider<PushService>((ref) => PushService());
