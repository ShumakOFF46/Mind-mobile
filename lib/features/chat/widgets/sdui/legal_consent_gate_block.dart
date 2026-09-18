import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/consent_checkbox_row.dart';
import '../../../../core/legal_document_launcher.dart';
import '../../models/sdui/legal_consent_gate_models.dart';

/// Рендер SDUI-блока `legal_consent_gate` (medical-гейт, контракт §6).
/// В отличие от questionnaire_prompt — НЕ отправляет текстовые сообщения
/// в чат по тапу; отправка — структурированный HTTP-вызов через
/// [onSubmit], полностью мимо LLM (тот же принцип, что onAcceptSlot у
/// calendar_proposal). Сам API не вызывает — колбэк приходит от
/// вызывающего кода (в конечном счёте ChatController), виджет остаётся
/// "тупым" UI (Dependency Injection/Interface Segregation).
///
/// [onSubmit] НИКОГДА не бросает исключение — реальный обработчик
/// (ChatController.submitMedicalConsent) сам ловит сетевые ошибки и
/// добавляет сообщение об ошибке в чат (тот же паттерн, что уже принят
/// для acceptSchedulingSlot()) — поэтому этот виджет считает вызов
/// завершённым (скрывает себя) сразу после `await`, без try/catch.
class LegalConsentGateBlock extends StatefulWidget {
  final LegalConsentGateBlockData data;
  final Future<void> Function(
    bool medicalDataAccepted,
    bool modelTrainingAccepted,
  ) onSubmit;

  const LegalConsentGateBlock({super.key, required this.data, required this.onSubmit});

  @override
  State<LegalConsentGateBlock> createState() => _LegalConsentGateBlockState();
}

class _LegalConsentGateBlockState extends State<LegalConsentGateBlock> {
  bool _medicalAccepted = false;
  bool _modelTrainingAccepted = false;
  bool _submitting = false;
  bool _resolved = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await widget.onSubmit(_medicalAccepted, _modelTrainingAccepted);
    if (!mounted) return;
    // Исход (принято/отклонено/ошибка) уже сообщён отдельным сообщением
    // в чате самим ChatController — блок просто скрывается, как и
    // CalendarProposalBlock после тапа по слоту.
    setState(() => _resolved = true);
  }

  Future<void> _openDocument(String documentType) async {
    final ok = await LegalDocumentLauncher.open(documentType);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.legalDocumentLoadError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved) return const SizedBox.shrink();

    final c = context.aura;
    final l = context.l10n;

    return Container(
      margin: const EdgeInsets.only(top: 6, right: 40),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hint.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.legalMedicalGateTitle,
            style: TextStyle(color: c.textDark, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (widget.data.reason == 'declined') ...[
            const SizedBox(height: 6),
            Text(
              l.legalMedicalGateDeclinedBanner,
              style: TextStyle(color: c.textSub, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          ConsentCheckboxRow(
            value: _medicalAccepted,
            onChanged: (v) => setState(() => _medicalAccepted = v),
            prefixText: l.legalMedicalDataConsentPrefix,
            linkText: l.legalMedicalDataConsentLinkText,
            onLinkTap: () => _openDocument('medical_data'),
          ),
          const SizedBox(height: 8),
          ConsentCheckboxRow(
            value: _modelTrainingAccepted,
            onChanged: (v) => setState(() => _modelTrainingAccepted = v),
            prefixText: l.legalModelTrainingConsentPrefix,
            linkText: l.legalModelTrainingConsentLinkText,
            onLinkTap: () => _openDocument('model_training'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.legalMedicalGateSubmitButton),
            ),
          ),
        ],
      ),
    );
  }
}
