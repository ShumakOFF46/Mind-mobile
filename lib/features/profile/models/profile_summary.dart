/// Модель ответа `GET /api/app/profile-summary`
/// (CONTRACT_profile_summary_v1.md §4). Две независимые витрины:
/// `completionPercent` (детерминированный агрегат, всегда присутствует)
/// и `summary` (LLM-текст, асинхронный, статусный).
enum ProfileSummaryStatus { pending, ready, failed }

class ProfileSummary {
  const ProfileSummary({
    required this.completionPercent,
    required this.status,
    this.text,
    this.generatedAt,
  });

  final int                  completionPercent;
  final ProfileSummaryStatus status;
  final String?              text;
  final DateTime?            generatedAt;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    final summary = Map<String, dynamic>.from(json['summary'] as Map? ?? {});
    final rawDate = summary['generated_at'] as String?;
    return ProfileSummary(
      completionPercent: (json['completion_percent'] as num?)?.toInt() ?? 0,
      status:            _parseStatus(summary['status'] as String?),
      text:              summary['text'] as String?,
      generatedAt:       rawDate == null ? null : DateTime.tryParse(rawDate),
    );
  }

  static ProfileSummaryStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'ready':  return ProfileSummaryStatus.ready;
      case 'failed': return ProfileSummaryStatus.failed;
      default:       return ProfileSummaryStatus.pending; // includes null/unknown
    }
  }

  /// Контракт §4: `failed` с непустым `text` — сервер вернул предыдущий
  /// успешный текст, клиент обязан показать его как обычный, БЕЗ пометки
  /// ошибки. Для UI это неотличимо от `ready`. Единственный случай,
  /// требующий placeholder — `pending`, либо `failed` без текста
  /// (первой генерации не было и она упала).
  bool get hasDisplayableText => text != null && text!.trim().isNotEmpty;
}
