import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/features/profile/models/profile_summary.dart';

void main() {
  test('fromJson — status=ready с текстом', () {
    final summary = ProfileSummary.fromJson({
      'completion_percent': 62,
      'summary': {
        'status': 'ready',
        'text': 'Описание готово.',
        'generated_at': '2026-09-05T10:00:00Z',
      },
    });

    expect(summary.completionPercent, 62);
    expect(summary.status, ProfileSummaryStatus.ready);
    expect(summary.text, 'Описание готово.');
    expect(summary.generatedAt, isNotNull);
    expect(summary.hasDisplayableText, isTrue);
  });

  test('fromJson — status=pending, text=null, generated_at=null', () {
    final summary = ProfileSummary.fromJson({
      'completion_percent': 0,
      'summary': {'status': 'pending', 'text': null, 'generated_at': null},
    });

    expect(summary.status, ProfileSummaryStatus.pending);
    expect(summary.text, isNull);
    expect(summary.generatedAt, isNull);
    expect(summary.hasDisplayableText, isFalse);
  });

  test('fromJson — status=failed с непустым text: hasDisplayableText=true (контракт §4)', () {
    final summary = ProfileSummary.fromJson({
      'completion_percent': 40,
      'summary': {'status': 'failed', 'text': 'Старый текст остаётся видимым.'},
    });

    expect(summary.status, ProfileSummaryStatus.failed);
    expect(summary.hasDisplayableText, isTrue);
  });

  test('fromJson — неизвестный/отсутствующий status трактуется как pending (safe default)', () {
    final summary = ProfileSummary.fromJson({'completion_percent': 15, 'summary': {}});
    expect(summary.status, ProfileSummaryStatus.pending);
  });

  test('fromJson — completion_percent отсутствует → 0 (не должно падать)', () {
    final summary = ProfileSummary.fromJson({'summary': {'status': 'pending'}});
    expect(summary.completionPercent, 0);
  });
}
