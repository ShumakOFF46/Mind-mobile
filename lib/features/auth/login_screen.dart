import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/push/push_providers.dart';
import '../../core/api/legal_consent_api_client.dart';
import '../../core/api/error_handler.dart';
import '../../core/widgets/consent_checkbox_row.dart';
import '../../core/legal_document_launcher.dart';
import '../legal_consent/legal_consent_errors.dart';
import '../legal_consent/regional_consent_screen.dart';
import 'widgets/birth_date_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  bool _basicConsent = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    // v4 (CONTRACT §2): birth_date/basic_data_consent обязательны для
    // регистрации. В ОТЛИЧИЕ от pre-v4 здесь НЕТ graceful degradation
    // при сетевой ошибке (раньше при сбое регистрации всё равно пускали
    // в чат — под гейтом это недопустимо: без успешного register() нет
    // ни токена, ни подтверждённого возраста).
    if (name.isEmpty || _birthDate == null || !_basicConsent) return;

    setState(() => _loading = true);
    try {
      final userId = await AppStorage.getOrCreateUserId();
      final result = await LegalConsentApiClient.register(
        appUserId: userId,
        birthDate: _birthDate!,
        basicDataConsent: _basicConsent,
        displayName: name,
      );
      await AppStorage.setUserName(name);

      // Push-разрешение — после успешного логина (CONTRACT_push_
      // notifications_v1 / BRIEF §2), fire-and-forget.
      ref.read(pushServiceProvider).requestPermissionAndRegister();

      if (!mounted) return;
      context.go(
        '/legal-consent/regional',
        extra: RegionalConsentArgs(
          detectedRegion: result.detectedRegion,
          regionLabel: result.regionLabel,
        ),
      );
    } catch (e) {
      if (LegalConsentErrors.isUnderage(e)) {
        if (mounted) context.go('/legal-consent/underage');
        return;
      }
      if (LegalConsentErrors.isConsentRequired(e)) {
        // Fallback-путь (BRIEF §1) — при нормальном UX не должен
        // произойти, чекбокс уже обязателен для сабмита клиентом.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.legalConsentRequiredError)),
          );
        }
        return;
      }
      if (mounted) {
        final err = ErrorHandler.handle(e, ErrorHandler.fromL10n(context.l10n));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final canSubmit = _birthDate != null && _basicConsent;

    return Scaffold(
      backgroundColor: c.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),

              // ── Логотип ──────────────────────────────────────────
              Text(
                'AURA',
                style: TextStyle(
                  fontFamily:    'CormorantGaramond',
                  fontSize:      52,
                  fontWeight:    FontWeight.w400,
                  letterSpacing: 10,
                  color:         c.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l.appTagline,
                style: TextStyle(
                  fontSize:      13,
                  letterSpacing: 2,
                  color:         c.textSub,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ── Вопрос ───────────────────────────────────────────
              Text(
                l.loginQuestion,
                style: TextStyle(
                  fontSize:   22,
                  fontWeight: FontWeight.w400,
                  color:      c.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l.loginSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color:    c.textSub,
                  height:   1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ── Поле имени ────────────────────────────────────────
              SizedBox(
                height: 52,
                child: TextField(
                  controller:         _nameController,
                  autofocus:  true,
                  textAlign:          TextAlign.center,
                  textAlignVertical:  TextAlignVertical.center,
                  style:              TextStyle(fontSize: 16, color: c.textDark),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText:  l.loginHint,
                    hintStyle: TextStyle(color: c.hint),
                    filled:    true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:   BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical:   0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Дата рождения (v4, CONTRACT §2) ──────────────────
              Text(l.legalBirthDateLabel, style: TextStyle(fontSize: 12, color: c.textSub)),
              const SizedBox(height: 6),
              BirthDateField(
                value: _birthDate,
                onChanged: (d) => setState(() => _birthDate = d),
              ),

              const SizedBox(height: 16),

              // ── Базовое согласие (v4, CONTRACT §2 п.3) ───────────
              ConsentCheckboxRow(
                value: _basicConsent,
                onChanged: (v) => setState(() => _basicConsent = v),
                prefixText: l.legalBasicConsentPrefix,
                linkText: l.legalBasicConsentLinkText,
                onLinkTap: () async {
                  // Универсальный документ (CONTRACT §2 п.3) — region=null,
                  // query-параметр region не передаём вообще.
                  final ok = await LegalDocumentLauncher.open('basic_data_consent');
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l.legalDocumentLoadError)));
                  }
                },
              ),

              const SizedBox(height: 24),

              // ── Кнопка ───────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_loading || !canSubmit) ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:         c.accent,
                    foregroundColor:         Colors.white,
                    disabledBackgroundColor: c.accent.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width:  20,
                          child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white,
                          ),
                        )
                      : Text(
                          l.loginButton,
                          style: const TextStyle(
                            fontSize:      15,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 48),

              // ── Футер ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  l.loginFooter,
                  style: TextStyle(
                    fontSize:      11,
                    letterSpacing: 1.5,
                    color:         c.hint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
