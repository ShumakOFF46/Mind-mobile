import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';
import '../models/profile_summary.dart';

/// Карточка "как AURA видит вас" (BRIEF_mobile_profile_summary.md).
/// Read-only, нет UI для правки — текст формирует AURA, не пользователь.
///
/// Три состояния по `summary.status` (CONTRACT_profile_summary_v1.md §4):
/// - `ready`, либо `failed` с непустым `text` (сервер вернул предыдущий
///   успешный текст) — обычный текст, БЕЗ визуальной пометки ошибки:
///   пользователь не должен видеть технический сбой backend.
/// - `pending`, либо `failed` без текста — placeholder + skeleton, не
///   ошибка (типичное состояние для только что зарегистрированного
///   пользователя).
///
/// ⚠ Формулировка placeholder-текста (`profileSummaryPending` в l10n) —
/// черновая, требует финальной сверки с владельцем контента (см.
/// BRIEF_mobile_profile_summary.md, "Отображение по summary.status").
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({super.key, required this.summary, required this.loading});

  final ProfileSummary? summary;
  final bool             loading;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profileSummaryTitle,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              color:      c.textDark,
              fontSize:   18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildBody(c, l),
        ],
      ),
    );
  }

  Widget _buildBody(AuraColorScheme c, AppLocalizations l) {
    if (loading || summary == null) return _SummarySkeleton(c: c);
    if (summary!.hasDisplayableText) {
      return Text(
        summary!.text!,
        style: TextStyle(color: c.textDark, fontSize: 14, height: 1.5),
      );
    }
    // pending, либо failed без предыдущего текста — тот же placeholder.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.profileSummaryPending,
          style: TextStyle(color: c.textSub, fontSize: 13, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),
        _SummarySkeleton(c: c),
      ],
    );
  }
}

/// Лёгкий pulse-skeleton без внешней shimmer-зависимости (в pubspec её
/// нет — добавлять ради одного плейсхолдера избыточно).
class _SummarySkeleton extends StatefulWidget {
  const _SummarySkeleton({required this.c});

  final AuraColorScheme c;

  @override
  State<_SummarySkeleton> createState() => _SummarySkeletonState();
}

class _SummarySkeletonState extends State<_SummarySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.9).animate(_controller),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(widget.c, double.infinity),
          const SizedBox(height: 8),
          _bar(widget.c, 220),
          const SizedBox(height: 8),
          _bar(widget.c, 160),
        ],
      ),
    );
  }

  Widget _bar(AuraColorScheme c, double width) => Container(
    width:  width,
    height: 12,
    decoration: BoxDecoration(
      color:        c.aiBubble,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}
