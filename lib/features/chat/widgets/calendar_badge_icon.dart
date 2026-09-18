import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../calendar/providers/calendar_badge_provider.dart';
import 'chat_app_bar.dart';

/// Иконка календаря в AppBar чата — розовый бейдж-квадрат с иконкой
/// внутри и красной точкой, если на этой неделе есть активные записи
/// (`calendarBadgeProvider`). Размер согласован с
/// `ChatAppBar.iconSize()`, чтобы не дублировать responsive-логику.
class CalendarBadgeIcon extends ConsumerWidget {
  final VoidCallback onTap;

  const CalendarBadgeIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.aura;
    final badgeSize = ChatAppBar.iconSize(context);
    final hasActiveEvents =
        ref.watch(calendarBadgeProvider).valueOrNull ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(badgeSize * 0.3),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: c.accent,
                size: badgeSize * 0.5,
              ),
            ),
            if (hasActiveEvents)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.bg, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
