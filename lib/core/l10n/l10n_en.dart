import 'app_localizations.dart';

class L10nEn extends AppLocalizations {
  const L10nEn();

  // ─── Auth ───────────────────────────────────────────────
  @override String get appTagline          => 'Beauty AI Consultant';
  @override String get loginQuestion       => 'What\'s your name?';
  @override String get loginSubtitle       => 'This helps us communicate\nmore personally';
  @override String get loginHint           => 'Your name';
  @override String get loginButton         => 'Continue';
  @override String get loginFooter         => 'VibeBit Studio';

  // ─── Chat ───────────────────────────────────────────────
  @override String get chatCalendar        => 'CALENDAR';
  @override String get chatMyProfile       => 'MY PROFILE';
  @override String get chatSubtitle        => 'Beauty AI Consultant';
  @override String get chatSessionHeader   => 'AI CONSULTANT';
  @override String get chatSessionStart    => 'Start A New Session';
  @override String get chatEmpty           => 'Start a consultation below';
  @override String get chatStartConsultation => 'Start Consultation';
  @override String get chatCopied          => 'Copied';
  @override String get photoUploadFailed   => 'Failed to upload photo';
  @override String get photoUploadPrompt   =>
      'I just uploaded a new photo. Please look at it and share your thoughts.';
  @override String proceduresAdded(int count) =>
      '$count procedure${count == 1 ? '' : 's'} added to calendar';

  // ─── Welcome & Quick Prompts ────────────────────────────
  @override String get chatWelcome         => 'Welcome';
  @override String get chatWelcomeSubtitle =>
      'I\'ll help with skincare and makeup — just ask.';
  @override String get chatStartWith       => 'WHERE TO START';
  @override String get chatOtherTopics     => 'Other topics';

  @override String get promptSkincareTitle   => 'Skincare';
  @override String get promptSkincare        =>
      'Help me build a daily skincare routine. Ask about my skin type and concerns first.';
  @override String get promptMakeupTitle     => 'Makeup';
  @override String get promptMakeup          =>
      'Help me choose a makeup look. Ask about the occasion and my skin tone.';
  @override String get promptPhotoTitle      => 'Photo analysis';
  @override String get promptPhoto           =>
      'I\'d like to upload a photo for analysis. What can you tell from it?';
  @override String get promptCalendarTitle   => 'Weekly plan';
  @override String get promptCalendar        =>
      'Help me plan beauty procedures for the week based on my skin type.';
  @override String get promptProductsTitle   => 'Product picks';
  @override String get promptProducts        =>
      'Recommend specific products for me. Ask about my budget and preferences.';
  @override String get promptProblemsTitle   => 'Skin concerns';
  @override String get promptProblems        =>
      'I have some skin concerns. Ask questions to understand what bothers me.';
  @override String get promptAntiAgeTitle    => 'Anti-age';
  @override String get promptAntiAge         =>
      'I\'m interested in anti-age care. What do you recommend for prevention?';
  @override String get promptQuickTipTitle   => 'Quick tip';
  @override String get promptQuickTip        =>
      'Give me one useful beauty tip for today — simple but effective.';
  @override String get promptOnboardingTitle => 'Get to know you';
  @override String get promptOnboarding =>
      'Let\'s get acquainted! Tell me about yourself — skin type, concerns, lifestyle — '
      'so I can give you personalized advice.';
  @override String get chipRequired => 'Required';
  @override String get chipRefreshPrompts => 'Other topics';

  // ─── Input bar ──────────────────────────────────────────
  @override String get inputHint           => 'I\'ll help with skincare and makeup — just ask...';
  @override String get inputListening      => 'Listening...';
  @override String get takePhoto           => 'Take a photo';
  @override String get chooseFromGallery   => 'Choose from gallery';
  @override String get guidedCapture       => 'Guided capture';

  // ─── Message menu ───────────────────────────────────────
  @override String get menuLike            => 'Like';
  @override String get menuUnlike          => 'Unlike';
  @override String get menuCopy            => 'Copy';
  @override String get menuRetry           => 'Retry';
  @override String get menuDeleteMessage   => 'Delete message';
  @override String get menuClearChat       => 'Clear chat';

  // ─── SDUI: Unknown block ────────────────────────────────
  @override String get sduiUnsupportedBlock =>
      'This message contains a block your app doesn\'t support yet';

  // ─── SDUI: Questionnaire Prompt block ──────────────────
  @override String qpProgressLabel(int current, int total) =>
      'Question $current of $total';
  @override String get qpRevalidationHint =>
      'You noted this before — still accurate?';
  @override String get qpDoneButton       => 'Done';
  @override String get qpSendButton       => 'Send';
  @override String get qpFreeTextHint     => 'Type your answer...';
  @override String get qpSubmittedLabel   => 'Sent';
  @override String get qpNumericMinLabel  => 'min';
  @override String get qpNumericMaxLabel  => 'max';
  @override String get qpMalformedButtonsBanner =>
      'This question isn\'t available right now — the rest of the '
      'consultation continues as usual, we\'ll follow up on this one later.';

  // ─── SDUI: Calendar Proposal block (Флоу 4, calendar_proposal v2) ──
  // CONTRACT_flow4_scheduling_v1.md §2-3. round/roundCap приходят из
  // payload блока, не хардкодятся клиентом.
  @override String schedulingRoundIndicator(int round, int roundCap) =>
      'Attempt $round of $roundCap';
  @override String get schedulingSlotConfirmed => 'Booking confirmed.';
  @override String get schedulingSlotStaleRound =>
      'This offer is no longer valid — ask the assistant for current options.';
  @override String get schedulingSlotNotFound =>
      'We couldn\'t find this scheduling session — try starting over.';
  @override String get schedulingSlotNotOwner =>
      'This booking belongs to another session.';
  @override String get schedulingSlotGenericError =>
      'Couldn\'t confirm the booking, please try again.';
  // TODO: copy review — placeholder, do not finalize wording here.
  @override String get schedulingNoSlotsFound =>
      'No suitable slots were found.';

  // ─── SDUI: Calendar Event Confirmation block (Флоу 4, v1) ──
  @override String get calendarConfirmationCancelledLabel => 'Cancelled';
  @override String get calendarConfirmationRescheduledLabel => 'Rescheduled';
  @override String get calendarConfirmationWasLabel => 'Was';
  @override String get calendarConfirmationNowLabel => 'Now';

  // ─── Profile ────────────────────────────────────────────
  @override String get profileTitle             => 'MY PROFILE';
  @override String get profileMember            => 'AURA Beauty Member';
  @override String get profileCompletion        => 'Profile completion';
  @override String get profileChoosePhoto       => 'CHOOSE PROFILE PHOTO';
  @override String get profileAddPhotosFirst    => 'Add photos in chat first';
  @override String get profileMyPhotos          => 'MY PHOTOS';
  @override String get profileAddPhotosHint     => 'Add photos in chat';
  @override String get profileAddPhotosDesc     =>
      'AURA will analyze them to give\nbetter personalized advice';
  @override String get profileBeautyTitle       => 'BEAUTY PROFILE';
  @override String get profileBeautyEmpty       =>
      'Chat with AURA to build your beauty profile';
  @override String get profileSkinType          => 'Skin type';
  @override String get profileConcerns          => 'Concerns';
  @override String get profileHair              => 'Hair';
  @override String get profileLifestyle         => 'Lifestyle';
  @override String get profileStyle             => 'Style';
  @override String get profileAccount           => 'ACCOUNT';
  @override String get profilePlatform          => 'Platform';
  @override String get profileSubscription      => 'Subscription';
  @override String get profileSubscriptionFree  => 'Free';
  @override String get profileDeviceId          => 'Device ID';
  @override String get profileSignOut           => 'Sign Out';
  @override String get profileDeletePhoto       => 'Delete photo?';
  @override String get profileDeletePhotoConfirm => 'This photo will be permanently deleted.';
  @override String get profileDeleteCancel      => 'Cancel';
  @override String get profileDeleteConfirm     => 'Delete';

  // ─── Profile redesign (tabs, Attributes card, overflow menu) ────
  @override String get profileAttributesTitle => 'Attributes';
  @override String get profileTabBeauty       => 'Beauty Profile';
  @override String get profileTabJournal      => 'Skin Journal';
  @override String get profileMoreOptions     => 'More options';
  @override String get profileSeeAll          => 'See All';

  // ⚠ Draft wording — pending content-owner review.
  @override String get profileSummaryTitle    => 'How AURA sees you';
  @override String get profileSummaryPending  => 'AURA is still getting to know you — check back soon.';

  // ─── Calendar ───────────────────────────────────────────
  @override String get calendarTitle        => 'CALENDAR';
  @override String get calendarComingSoon   => 'Coming Soon';
  @override String get calendarComingSoonDesc => 'Your beauty calendar\nwill appear here';
  @override String get calendarToday               => 'Today';
  @override String calendarProcedureCount(int count) =>
      '· $count procedure${count == 1 ? '' : 's'}';
  @override String get calendarUpcomingProcedures  => 'Upcoming Procedures';
  @override List<String> get weekdayShortLabels =>
      const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  @override List<String> get monthShortLabels => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
  @override String monthYearLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // ─── Calendar: Procedure categories ─────────────────────
  @override String get categorySerum   => 'Serum';
  @override String get categoryMask    => 'Mask';
  @override String get categoryEyeCare => 'Eye Care';
  @override String get categoryPeel    => 'Peel';
  @override String get categoryOther   => 'Other';

  // ─── Calendar: Mock procedure content ───────────────────
  @override String get mockProcedureHydraGlowSerumTitle => 'HydraGlow Serum';
  @override String get mockProcedureHydraGlowSerumNotes =>
      'A lightweight hyaluronic acid serum that deeply hydrates and plumps '
      'the skin. Apply to clean, slightly damp skin before moisturizer.';
  @override String get mockProcedureOvernightSleepMaskTitle =>
      'Overnight Sleep Mask';
  @override String get mockProcedureOvernightSleepMaskNotes =>
      'A rich overnight mask that works while you sleep to restore the '
      'skin barrier and lock in moisture. Rinse off in the morning.';
  @override String get mockProcedureRetinolEyeSerumTitle => 'Retinol Eye Serum';
  @override String get mockProcedureRetinolEyeSerumNotes =>
      'A gentle low-concentration retinol formula for the delicate eye '
      'area — helps with fine lines. Use a rice-grain amount, avoid the '
      'lash line.';
  @override String get mockProcedureLacticAcidPeelTitle => 'Lactic Acid Peel';
  @override String get mockProcedureLacticAcidPeelNotes =>
      'A mild exfoliating peel that smooths texture and evens tone. Use '
      'sunscreen the following day — skin will be more sun-sensitive.';

  // ─── Calendar: Procedure detail sheet ───────────────────
  @override String get procedureDetailAbout => 'About this procedure';
  @override String procedureDetailDuration(int minutes) => '$minutes min';
  @override String get procedureDetailClose => 'Close';

  // ─── Photo Capture (guided) ─────────────────────────────
  @override String get captureTitle           => 'GUIDED CAPTURE';
  @override String get captureHintInitial     =>
      'Position your face inside the oval';
  @override String get captureButton          => 'CAPTURE';
  @override String get captureRetake          => 'Retake';
  @override String get captureUse             => 'Use this photo';
  @override String get captureCancel          => 'Cancel';

  @override String get captureIndicatorLighting  => 'Lighting';
  @override String get captureIndicatorAngle     => 'Angle';
  @override String get captureIndicatorPosition  => 'Position';
  @override String get captureIndicatorDistance  => 'Distance';

  @override String get captureHintLightingDim         =>
      'Turn on bright light or stand by a window';
  @override String get captureHintLightingOverexposed =>
      'Photo too bright — step away from the window';
  @override String get captureHintSharpness           =>
      'Hold the phone steady, tap to focus';
  @override String get captureHintAngle               =>
      'Turn your head straight, look at the camera';
  @override String get captureHintTooClose            =>
      'Move the phone a bit further';
  @override String get captureHintTooFar              =>
      'Move the phone closer';

  @override String get captureErrorPermission =>
      'Camera permission is required for guided capture';
  @override String get captureErrorInit       =>
      'Failed to initialize camera';

  // ─── Errors ─────────────────────────────────────────────
  @override String get errorNetwork         => 'Check your internet connection';
  @override String get errorNoConnection    => 'Could not connect to server';
  @override String get errorTimeout         => 'Server not responding. Try again later';
  @override String get errorAuth            => 'Auth error. Please restart the app';
  @override String get errorNotFound        => 'Data not found';
  @override String get errorServer          => 'Server error. Try again later';
  @override String get errorUnknown         => 'Something went wrong';
  @override String get errorGeneric         => 'An unknown error occurred';

  // ─── Legal Consent Gate v4 (registration + regional screen) ──────
  @override String get legalBirthDateLabel => 'Date of birth';
  @override String get legalBirthDatePlaceholder => 'Select date';
  @override String get legalBasicConsentPrefix => 'I agree to the ';
  @override String get legalBasicConsentLinkText => 'basic data processing terms';
  @override String get legalUnderageTitle => 'Service unavailable';
  @override String get legalUnderageMessage =>
      'Sorry, AURA is only available to users 18 years and older.';
  @override String get legalUnderageClose => 'Close';
  @override String get legalConsentRequiredError => 'Please accept the terms to continue';

  @override String get legalRegionalTitle => 'Your region';
  @override String legalRegionConfirmQuestion(String regionLabel) =>
      'We detected your region as $regionLabel — is that correct?';
  @override String get legalRegionConfirmToggleLabel => 'Yes, that\'s my region';
  @override String get legalRegionSelectLabel => 'Select your region';
  @override String get legalRegionEu => 'European Union';
  @override String get legalRegionUs => 'United States';
  @override String get legalRegionLatam => 'Latin America';
  @override String get legalRegionRu => 'Russia';
  @override String get legalRegionCn => 'China';
  @override String get legalRegionOther => 'Other';
  @override String get legalRegionUnknownLabel => 'not detected';
  @override String get legalChatTosPrefix => 'I agree to the ';
  @override String get legalChatTosLinkText => 'Chat Terms of Service';
  @override String get legalPersonalDataPrefix => 'I agree to the ';
  @override String get legalPersonalDataLinkText => 'personal data processing policy';
  @override String get legalRegionalSubmitButton => 'Continue';
  @override String get legalRegionalDeclinedTitle => 'Can\'t continue without accepting the terms';
  @override String get legalRegionalDeclinedMessage =>
      'You can come back and accept the terms whenever you\'re ready.';
  @override String get legalRegionalDeclinedRetryButton => 'Review the terms';

  // ─── Legal Consent Gate v4 (medical, SDUI legal_consent_gate) ────
  @override String get legalMedicalGateTitle => 'Before we continue';
  @override String get legalMedicalDataConsentPrefix => 'I agree to the ';
  @override String get legalMedicalDataConsentLinkText => 'health data processing terms';
  @override String get legalModelTrainingConsentPrefix => 'I agree to the ';
  @override String get legalModelTrainingConsentLinkText => 'use of my data for model training';
  @override String get legalMedicalGateSubmitButton => 'Accept and continue';
  @override String get legalMedicalGateDeclinedBanner =>
      'You declined this before — accepting is required to discuss health topics.';
  @override String get legalMedicalConsentAcceptedMessage =>
      'Thanks — you can now ask about health-related topics.';
  @override String get legalMedicalConsentDeclinedMessage =>
      'Got it — health-related topics will stay off-limits until you accept the terms.';

  @override String get legalDocumentLoadError => 'Couldn\'t open the document';

  // ─── Deterministic Profiling Answer v1 (SDUI profiling_question) ──
  @override String get profilingQuestionRevalidationHint =>
      'You answered this before — let\'s double-check';
  @override String get profilingQuestionSaveError =>
      'Couldn\'t save your answer, please try again';
}
