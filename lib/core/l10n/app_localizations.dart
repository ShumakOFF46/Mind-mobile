import 'package:flutter/material.dart';
import 'l10n_en.dart';
import 'l10n_ru.dart';
import 'l10n_kk.dart';

/// Доступ из виджета: context.l10n
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

abstract class AppLocalizations {
  const AppLocalizations();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('kk'),
  ];

  // ─── Auth / Login ──────────────────────────────────────
  String get appTagline;
  String get loginQuestion;
  String get loginSubtitle;
  String get loginHint;
  String get loginButton;
  String get loginFooter;

  // ─── Chat ─────────────────────────────────────────────
  String get chatCalendar;
  String get chatMyProfile;
  String get chatSubtitle;
  String get chatSessionHeader;
  String get chatSessionStart;
  String get chatEmpty;
  String get chatStartConsultation;
  String get chatWelcome;
  String get chatWelcomeSubtitle;
  String get chatStartWith;
  String get chatOtherTopics;
  String get chatCopied;
  String get photoUploadFailed;
  String get photoUploadPrompt;
  String proceduresAdded(int count);

  // ─── Input bar ────────────────────────────────────────
  String get inputHint;
  String get inputListening;
  String get takePhoto;
  String get chooseFromGallery;
  String get guidedCapture;

  // ─── Message menu ─────────────────────────────────────
  String get menuLike;
  String get menuUnlike;
  String get menuCopy;
  String get menuRetry;
  String get menuDeleteMessage;
  String get menuClearChat;

  // ─── SDUI: Unknown block ───────────────────────────────
  String get sduiUnsupportedBlock;

  // ─── SDUI: Questionnaire Prompt block ─────────────────
  String qpProgressLabel(int current, int total);
  String get qpRevalidationHint;
  String get qpDoneButton;
  String get qpSendButton;
  String get qpFreeTextHint;
  String get qpSubmittedLabel;
  String get qpNumericMinLabel;
  String get qpNumericMaxLabel;
  /// Malformed buttons UX (решение оркестратора, сессия 2026-08-31):
  /// input_mode=buttons без валидных options[] — вопрос скрыт целиком,
  /// показан только этот баннер (см. QpMalformedBanner).
  String get qpMalformedButtonsBanner;

  // ─── SDUI: Calendar Proposal block (Флоу 4, calendar_proposal v2) ──
  // Контракт: CONTRACT_flow4_scheduling_v1.md §2-3. round/roundCap —
  // параметры, значения приходят из payload блока, НЕ хардкодятся.
  String schedulingRoundIndicator(int round, int roundCap);
  String get schedulingSlotConfirmed;
  String get schedulingSlotStaleRound;
  String get schedulingSlotNotFound;
  String get schedulingSlotNotOwner;
  String get schedulingSlotGenericError;

  // BRIEF_mobile_calendar_proposal_transport_fix.md п.2: candidates: []
  // раньше деградировал в generic UnknownBlock ("блок не поддерживается") —
  // теперь специализированное состояние. // TODO: copy review — текст
  // ниже плейсхолдер, финальная формулировка RU/EN не входит в этот фикс.
  String get schedulingNoSlotsFound;

  // ─── SDUI: Calendar Event Confirmation block (Флоу 4, v1) ──
  // CONTRACT_flow4_scheduling_v1.md §4a. Неинтерактивный блок —
  // подтверждение уже свершившегося cancel/reschedule.
  String get calendarConfirmationCancelledLabel;
  String get calendarConfirmationRescheduledLabel;
  String get calendarConfirmationWasLabel;
  String get calendarConfirmationNowLabel;

  // ─── Profile ──────────────────────────────────────────
  String get profileTitle;
  String get profileMember;
  String get profileCompletion;
  String get profileChoosePhoto;
  String get profileAddPhotosFirst;
  String get profileMyPhotos;
  String get profileAddPhotosHint;
  String get profileAddPhotosDesc;
  String get profileBeautyTitle;
  String get profileBeautyEmpty;
  String get profileSkinType;
  String get profileConcerns;
  String get profileHair;
  String get profileLifestyle;
  String get profileStyle;
  String get profileAccount;
  String get profilePlatform;
  String get profileSubscription;
  String get profileSubscriptionFree;
  String get profileDeviceId;
  String get profileSignOut;
  String get profileDeletePhoto;
  String get profileDeletePhotoConfirm;
  String get profileDeleteCancel;
  String get profileDeleteConfirm;

  // ─── Profile redesign (tabs, Attributes card, overflow menu) ──
  String get profileAttributesTitle;
  String get profileTabBeauty;
  String get profileTabJournal;
  String get profileMoreOptions;
  String get profileSeeAll;

  // ─── Profile Summary v1 (CONTRACT_profile_summary_v1.md) ──
  // ⚠ profileSummaryPending — черновая формулировка, требует финальной
  // сверки с владельцем контента (см. BRIEF_mobile_profile_summary.md).
  String get profileSummaryTitle;
  String get profileSummaryPending;

  // ─── Calendar ─────────────────────────────────────────
  String get calendarTitle;
  String get calendarComingSoon;
  String get calendarComingSoonDesc;
  String get calendarToday;
  String calendarProcedureCount(int count);
  String get calendarUpcomingProcedures;
  /// [Su, Mo, Tu, We, Th, Fr, Sa] — порядок фиксирован (неделя с воскресенья,
  /// см. month_grid_builder.dart), не переставлять по языку.
  List<String> get weekdayShortLabels;
  /// [Jan..Dec] — короткие подписи месяца для таймлайна Upcoming Procedures.
  List<String> get monthShortLabels;
  /// "August 2026" — заголовок карточки месяца + подзаголовок AppBar.
  String monthYearLabel(DateTime date);

  // ─── Calendar: Procedure categories ────────────────────
  String get categorySerum;
  String get categoryMask;
  String get categoryEyeCare;
  String get categoryPeel;
  /// Флоу 4 / Step 0 fix — бакет для backend-категорий, не входящих в
  /// исходные 4 (подтверждённый факт: routers/app_calendar.py,
  /// CalendarEvent.category default="skincare"), см.
  /// procedure_event.dart::ProcedureCategory.other.
  String get categoryOther;

  // ─── Calendar: Mock procedure content ──────────────────
  /// Названия/описания тестовых процедур (см. mock_procedures.dart) —
  /// через l10n, а не хардкод, чтобы моки вели себя так же, как будет
  /// вести себя реальный бэкенд (label_resolver уже отдаёт готовую строку
  /// под язык текущего хода, см. ProjectFull.md/universal_dialog_engine.md).
  String get mockProcedureHydraGlowSerumTitle;
  String get mockProcedureHydraGlowSerumNotes;
  String get mockProcedureOvernightSleepMaskTitle;
  String get mockProcedureOvernightSleepMaskNotes;
  String get mockProcedureRetinolEyeSerumTitle;
  String get mockProcedureRetinolEyeSerumNotes;
  String get mockProcedureLacticAcidPeelTitle;
  String get mockProcedureLacticAcidPeelNotes;

  // ─── Calendar: Procedure detail sheet ──────────────────
  String get procedureDetailAbout;
  String procedureDetailDuration(int minutes);
  String get procedureDetailClose;

  // ─── Photo Capture (guided) ───────────────────────────
  String get captureTitle;
  String get captureHintInitial;
  String get captureButton;
  String get captureRetake;
  String get captureUse;
  String get captureCancel;

  // Capture indicators
  String get captureIndicatorLighting;
  String get captureIndicatorAngle;
  String get captureIndicatorPosition;
  String get captureIndicatorDistance;

  // Capture hints (dynamic, based on quality)
  String get captureHintLightingDim;
  String get captureHintLightingOverexposed;
  String get captureHintSharpness;
  String get captureHintAngle;
  String get captureHintTooClose;
  String get captureHintTooFar;

  // Capture errors
  String get captureErrorPermission;
  String get captureErrorInit;

  // ─── Errors ───────────────────────────────────────────
  String get errorNetwork;
  String get errorNoConnection;
  String get errorTimeout;
  String get errorAuth;
  String get errorNotFound;
  String get errorServer;
  String get errorUnknown;
  String get errorGeneric;

  // ─── Quick Prompts ────────────────────────────────────
  String get promptSkincareTitle;
  String get promptSkincare;
  String get promptMakeupTitle;
  String get promptMakeup;
  String get promptPhotoTitle;
  String get promptPhoto;
  String get promptCalendarTitle;
  String get promptCalendar;
  String get promptProductsTitle;
  String get promptProducts;
  String get promptProblemsTitle;
  String get promptProblems;
  String get promptAntiAgeTitle;
  String get promptAntiAge;
  String get promptQuickTipTitle;
  String get promptQuickTip;
  String get promptOnboardingTitle;
  String get promptOnboarding;
  String get chipRequired;
  String get chipRefreshPrompts;

  // ─── Legal Consent Gate v4 (регистрация + региональный экран) ────
  String get legalBirthDateLabel;
  String get legalBirthDatePlaceholder;
  String get legalBasicConsentPrefix;
  String get legalBasicConsentLinkText;
  String get legalUnderageTitle;
  String get legalUnderageMessage;
  String get legalUnderageClose;
  String get legalConsentRequiredError;

  String get legalRegionalTitle;
  String legalRegionConfirmQuestion(String regionLabel);
  String get legalRegionConfirmToggleLabel;
  String get legalRegionSelectLabel;
  String get legalRegionEu;
  String get legalRegionUs;
  String get legalRegionLatam;
  String get legalRegionRu;
  String get legalRegionCn;
  String get legalRegionOther;
  String get legalRegionUnknownLabel;
  String get legalChatTosPrefix;
  String get legalChatTosLinkText;
  String get legalPersonalDataPrefix;
  String get legalPersonalDataLinkText;
  String get legalRegionalSubmitButton;
  String get legalRegionalDeclinedTitle;
  String get legalRegionalDeclinedMessage;
  String get legalRegionalDeclinedRetryButton;

  // ─── Legal Consent Gate v4 (medical, SDUI legal_consent_gate) ────
  String get legalMedicalGateTitle;
  String get legalMedicalDataConsentPrefix;
  String get legalMedicalDataConsentLinkText;
  String get legalModelTrainingConsentPrefix;
  String get legalModelTrainingConsentLinkText;
  String get legalMedicalGateSubmitButton;
  String get legalMedicalGateDeclinedBanner;
  /// Локальное сообщение в чате после submitMedicalConsent() —
  /// ChatController::submitMedicalConsent (extension), passed=true.
  String get legalMedicalConsentAcceptedMessage;
  /// То же, passed=false (blocked_reason='declined').
  String get legalMedicalConsentDeclinedMessage;

  String get legalDocumentLoadError;

  // ─── Deterministic Profiling Answer v1 (SDUI profiling_question) ──
  /// Показывается вместо label, когда is_revalidation=true (BRIEF
  /// §1 — "подсказка is_revalidation... можно отобразить минимально").
  String get profilingQuestionRevalidationHint;
  /// Нейтральная ошибка после неудачной попытки записи ответа
  /// (POST /api/app/profiling-answers) — кнопки остаются активными,
  /// см. profiling_question_block.dart.
  String get profilingQuestionSaveError;
}

// ─── Delegate ─────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ru', 'kk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ru': return const L10nRu();
      case 'kk': return const L10nKk();
      default:   return const L10nEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
