import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../models/sdui/profiling_question_models.dart';

/// Рендер SDUI-блока `profiling_question` (CONTRACT_deterministic_
/// profiling_answer_v1.md §1-2, contracts/sdui_blocks/profiling_question.
/// schema.json). Преимущественно `restriction:*`/`symptom:*` (safety-
/// критичные) вопросы, но применим к любому top-level buttons-вопросу.
///
/// ⚠ КЛЮЧЕВОЕ ОТЛИЧИЕ от QuestionnairePromptBlock/QpButtonsControl: тап
/// НЕ отправляется как транспорт записи через onSendMessage()/чат. Запись
/// — структурированный HTTP `POST /api/app/profiling-answers`,
/// СОЗНАТЕЛЬНО мимо streamChat()/LLM (тот же принцип, что onAcceptSlot/
/// onSubmitMedicalConsent; см. AGENT_RULES_mobile.md §1.6 — safety-ответы
/// никогда не идут как интерпретация свободного текста на клиенте).
///
/// [onSubmitAnswer] — В ОТЛИЧИЕ от onSubmitMedicalConsent/onAcceptSlot
/// (которые НИКОГДА не бросают исключение — ошибку глотает контроллер и
/// сам добавляет сообщение в чат, блок считается "отвеченным" в любом
/// случае) — ЗДЕСЬ исключение ОБЯЗАНО дойти до этого виджета. Бриф
/// (BRIEF_mobile_deterministic_profiling_answer.md, раздел "Обработка
/// ошибки") требует другого UX: при сетевой/422-ошибке кнопки должны
/// остаться активными для повторного тапа, а не считаться отвеченными.
/// Это возможно только если ChatControllerProfilingAnswer.
/// submitProfilingAnswer() — тонкая обёртка над API-клиентом БЕЗ
/// try/catch, пробрасывающая DioException сюда. Осознанное расхождение
/// с паттерном остальных структурированных блоков — задокументировано
/// тоже в REPORT_mobile_deterministic_profiling_answer.md.
///
/// [onSendMessage] — вызывается ТОЛЬКО после успешной записи, и ТОЛЬКО
/// как решение мобильного агента сделать диалог естественным (контракт
/// §2: "клиент опционально отправляет"). Решение зафиксировано: ДА,
/// отправлять локализованный текст выбранного варианта — см. отчёт,
/// раздел "Решение по текстовому подтверждению". Это ОБЫЧНОЕ сообщение
/// чата (уходит через streamChat()/LLM как если бы пользователь напечатал
/// его сам) — НЕ транспорт записи: запись уже подтверждена сервером до
/// этого вызова, что бы дальше ни решила модель с этим текстом.
class ProfilingQuestionBlock extends StatefulWidget {
  final ProfilingQuestionBlockData data;
  final void Function(String text) onSendMessage;
  final Future<void> Function(
    String questionnaireSlug,
    String answerKey,
    String value,
  ) onSubmitAnswer;

  const ProfilingQuestionBlock({
    super.key,
    required this.data,
    required this.onSendMessage,
    required this.onSubmitAnswer,
  });

  @override
  State<ProfilingQuestionBlock> createState() => _ProfilingQuestionBlockState();
}

class _ProfilingQuestionBlockState extends State<ProfilingQuestionBlock> {
  // Фиксируется ТОЛЬКО после подтверждённой сервером записи (200 OK).
  // Пока null — кнопки активны, включая повторный тап после ошибки.
  String? _confirmedValue;
  bool _submitting = false;
  bool _showError = false;

  Future<void> _handleTap(ProfilingQuestionOption option) async {
    if (_submitting || _confirmedValue != null) return;
    setState(() {
      _submitting = true;
      _showError = false;
    });
    try {
      await widget.onSubmitAnswer(
        widget.data.questionnaireSlug,
        widget.data.answerKey,
        option.value,
      );
      if (!mounted) return;
      setState(() {
        _confirmedValue = option.value;
        _submitting = false;
      });
      final languageCode = Localizations.localeOf(context).languageCode;
      widget.onSendMessage(option.label.resolve(languageCode));
    } catch (e) {
      // Defense-in-depth: легитимный блок от backend не должен получать
      // 422 forbidden_namespace (контракт §3), но сетевые ошибки/5xx
      // возможны всегда. Не роняем UI, не считаем вопрос отвеченным.
      debugPrint('ProfilingQuestionBlock: onSubmitAnswer error: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _showError = true;
        // _confirmedValue сознательно НЕ трогаем — остаётся null, кнопки
        // остаются активными для повторного тапа (BRIEF, "Обработка
        // ошибки": "показать нейтральную ошибку... оставить кнопки
        // активными для повторного тапа").
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final data = widget.data;

    return Container(
      margin: const EdgeInsets.only(top: 6, right: 40),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hint.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.isRevalidation) ...[
            Text(
              l.profilingQuestionRevalidationHint,
              style: TextStyle(color: c.textSub, fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            data.label.resolve(languageCode),
            style: TextStyle(color: c.textDark, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.options.map((opt) {
              final isSelected = _confirmedValue == opt.value;
              final isLocked = _confirmedValue != null;
              return OutlinedButton(
                key: ValueKey(opt.value),
                onPressed:
                    (_submitting || isLocked) ? null : () => _handleTap(opt),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected ? c.accent : Colors.transparent,
                  foregroundColor: isSelected ? Colors.white : c.textDark,
                  side: BorderSide(
                    color: (isLocked && !isSelected)
                        ? c.hint.withOpacity(0.3)
                        : c.accent,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  opt.label.resolve(languageCode),
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
          ),
          if (_submitting) ...[
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
              ),
            ),
          ],
          if (_showError) ...[
            const SizedBox(height: 8),
            Text(
              l.profilingQuestionSaveError,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
