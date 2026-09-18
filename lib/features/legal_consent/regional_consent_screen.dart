import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/api/legal_consent_api_client.dart';
import '../../core/api/error_handler.dart';
import '../../core/legal_consent_gate_cache.dart';
import '../../core/legal_document_launcher.dart';
import '../../core/widgets/consent_checkbox_row.dart';
import 'widgets/region_selector.dart';
import 'widgets/declined_consent_view.dart';

/// Передаётся через `context.go(..., extra: ...)` из LoginScreen сразу
/// после успешной регистрации, чтобы не делать лишний GET /status
/// (BRIEF §1). При заходе через redirect роутера (существующий
/// пользователь, повторный запуск приложения) — extra будет null, экран
/// сам догружает статус.
class RegionalConsentArgs {
  final String? detectedRegion;
  final Map<String, String>? regionLabel;
  const RegionalConsentArgs({this.detectedRegion, this.regionLabel});
}

/// Экран 2 (BRIEF "Экран 2") — региональное согласие.
class RegionalConsentScreen extends StatefulWidget {
  final String? detectedRegion;
  final Map<String, String>? regionLabel;

  const RegionalConsentScreen({super.key, this.detectedRegion, this.regionLabel});

  @override
  State<RegionalConsentScreen> createState() => _RegionalConsentScreenState();
}

class _RegionalConsentScreenState extends State<RegionalConsentScreen> {
  bool _loadingInitial = false;
  String? _detectedRegion;
  Map<String, String>? _regionLabel;

  bool _regionConfirm = true;
  String? _manualRegion;
  bool _chatTosAccepted = false;
  bool _personalDataAccepted = false;

  bool _submitting = false;
  bool _declined = false;

  @override
  void initState() {
    super.initState();
    _detectedRegion = widget.detectedRegion;
    _regionLabel = widget.regionLabel;
    if (_detectedRegion == null) {
      _fetchStatusForRegion();
      // ⚠ Живой прогон 2026-09-07 (реальное устройство, реальный
      // backend): если детект региона не удался (detected_region=null —
      // например, реальный клиентский IP через MikroTik NAT/Traefik
      // резолвится иначе, чем в curl-тестах backend с явным
      // X-Forwarded-For), тумблер НЕ должен молчаливо оставаться в "да,
      // это мой регион" — иначе пользователь подтверждает
      // несуществующий регион и проходит гейт без региона вообще.
      // Дублируется guard'ом в _submit() ниже — defense-in-depth,
      // не полагаемся только на дефолт состояния.
      _regionConfirm = false;
    }
  }

  Future<void> _fetchStatusForRegion() async {
    setState(() => _loadingInitial = true);
    try {
      final status = await LegalConsentApiClient.getStatus();
      if (!mounted) return;
      setState(() {
        _detectedRegion = status.detectedRegion;
        _regionLabel = status.regionLabel;
        // Тот же guard, что в initState() — статус мог легитимно
        // вернуться успешно (без исключения), но всё равно с
        // detected_region=null (сервер честно не смог определить регион,
        // не сетевая ошибка). "успешный ответ" ≠ "регион есть".
        if (_detectedRegion == null) _regionConfirm = false;
      });
    } catch (_) {
      // Регион не получен — форсируем ручной выбор, "верно?" без региона
      // бессмыслен.
      if (!mounted) return;
      setState(() => _regionConfirm = false);
    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  Future<void> _openDocument(String documentType) async {
    final ok = await LegalDocumentLauncher.open(
      documentType,
      region: _regionConfirm ? _detectedRegion : _manualRegion,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.legalDocumentLoadError)));
    }
  }

  Future<void> _submit() async {
    if (!_regionConfirm && _manualRegion == null) return;
    // Живой прогон 2026-09-07: второй, независимый уровень защиты —
    // даже если пользователь вручную вернул тумблер в "да, это мой
    // регион" при отсутствующем _detectedRegion (initState/fetch-guard
    // выше сработали только как ДЕФОЛТ, не как жёсткий запрет менять
    // состояние тумблера), подтвердить несуществующий регион всё равно
    // нельзя — это ровно тот сценарий, который был найден живьём как
    // баг ("регион не определён — это не то состояние, когда можно
    // пропускать пользователя в чат").
    if (_regionConfirm && _detectedRegion == null) return;

    setState(() => _submitting = true);
    try {
      final result = await LegalConsentApiClient.submitRegionalConsent(
        regionConfirm: _regionConfirm,
        region: _regionConfirm ? null : _manualRegion,
        chatTosAccepted: _chatTosAccepted,
        personalDataAccepted: _personalDataAccepted,
      );
      if (!mounted) return;

      if (result.passed) {
        LegalConsentGateCache.markRegionalPassed();
        context.go('/chat');
        return;
      }
      if (result.blockedReason == 'declined') {
        setState(() => _declined = true);
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.errorUnknown)));
    } catch (e) {
      if (!mounted) return;
      final err = ErrorHandler.handle(e, ErrorHandler.fromL10n(context.l10n));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _regionLabelText(AppLocalizations l) {
    if (_regionLabel == null) return l.legalRegionUnknownLabel;
    // ⚠ region_label — {"ru":..., "en":...}; берём 'ru' как основной язык
    // проекта, фолбэк 'en'. Не привязано к текущей Locale контекста —
    // открытый вопрос (в интерфейсе AppLocalizations нет прямого кода
    // языка), см. отчёт.
    return _regionLabel!['ru'] ?? _regionLabel!['en'] ?? l.legalRegionUnknownLabel;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: _loadingInitial
            ? const Center(child: CircularProgressIndicator())
            : _declined
                ? Center(child: DeclinedConsentView(onBack: () => setState(() => _declined = false)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          l.legalRegionalTitle,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: c.textDark),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l.legalRegionConfirmQuestion(_regionLabelText(l)),
                          style: TextStyle(fontSize: 15, color: c.textDark),
                        ),
                        Row(
                          children: [
                            Switch(
                              value: _regionConfirm,
                              // Нельзя подтвердить регион, которого нет —
                              // тумблер недоступен при _detectedRegion ==
                              // null (живой баг 2026-09-07, см. _submit()
                              // и initState() выше).
                              onChanged: _detectedRegion == null
                                  ? null
                                  : (v) => setState(() => _regionConfirm = v),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.legalRegionConfirmToggleLabel,
                                style: TextStyle(fontSize: 13, color: c.textSub),
                              ),
                            ),
                          ],
                        ),
                        if (!_regionConfirm) ...[
                          const SizedBox(height: 8),
                          RegionSelector(
                            value: _manualRegion,
                            onChanged: (r) => setState(() => _manualRegion = r),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ConsentCheckboxRow(
                          value: _chatTosAccepted,
                          onChanged: (v) => setState(() => _chatTosAccepted = v),
                          prefixText: l.legalChatTosPrefix,
                          linkText: l.legalChatTosLinkText,
                          onLinkTap: () => _openDocument('chat_tos'),
                        ),
                        const SizedBox(height: 12),
                        ConsentCheckboxRow(
                          value: _personalDataAccepted,
                          onChanged: (v) => setState(() => _personalDataAccepted = v),
                          prefixText: l.legalPersonalDataPrefix,
                          linkText: l.legalPersonalDataLinkText,
                          onLinkTap: () => _openDocument('personal_data'),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: c.accent.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l.legalRegionalSubmitButton),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
