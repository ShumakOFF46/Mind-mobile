import 'app_localizations.dart';

class L10nRu extends AppLocalizations {
  const L10nRu();

  // ─── Auth ───────────────────────────────────────────────
  @override String get appTagline          => 'Beauty AI Консультант';
  @override String get loginQuestion       => 'Как вас зовут?';
  @override String get loginSubtitle       => 'Это поможет нам общаться\nболее персонально';
  @override String get loginHint           => 'Ваше имя';
  @override String get loginButton         => 'Продолжить';
  @override String get loginFooter         => 'VibeBit Studio';

  // ─── Chat ───────────────────────────────────────────────
  @override String get chatCalendar        => 'КАЛЕНДАРЬ';
  @override String get chatMyProfile       => 'МОЙ ПРОФИЛЬ';
  @override String get chatSubtitle        => 'Beauty AI Консультант';
  @override String get chatSessionHeader   => 'AI КОНСУЛЬТАНТ';
  @override String get chatSessionStart    => 'Начать новую сессию';
  @override String get chatEmpty           => 'Начните консультацию ниже';
  @override String get chatStartConsultation => 'Новая консультация';
  @override String get chatCopied          => 'Скопировано';
  @override String get photoUploadFailed   => 'Не удалось загрузить фото';
  @override String get photoUploadPrompt   =>
      'Я только что загрузила новое фото. Пожалуйста, посмотри на него и поделись своими мыслями.';
  @override String proceduresAdded(int count) {
    if (count == 1) return '$count процедура добавлена в календарь';
    if (count >= 2 && count <= 4) return '$count процедуры добавлены в календарь';
    return '$count процедур добавлено в календарь';
  }

  // ─── Welcome & Quick Prompts ────────────────────────────
  @override String get chatWelcome         => 'Добро пожаловать';
  @override String get chatWelcomeSubtitle =>
      'Я помогу с уходом, макияжем — просто спросите.';
  @override String get chatStartWith       => 'С ЧЕГО НАЧНЁМ';
  @override String get chatOtherTopics     => 'Другие темы';

  @override String get promptSkincareTitle   => 'Уход за кожей';
  @override String get promptSkincare        =>
      'Помоги составить ежедневный уход за кожей. Сначала спроси о моём типе кожи и проблемах.';
  @override String get promptMakeupTitle     => 'Макияж';
  @override String get promptMakeup          =>
      'Помоги выбрать макияж. Спроси про повод и мой тон кожи.';
  @override String get promptPhotoTitle      => 'Анализ фото';
  @override String get promptPhoto           =>
      'Хочу загрузить фото для анализа. Что ты можешь определить по фотографии?';
  @override String get promptCalendarTitle   => 'План на неделю';
  @override String get promptCalendar        =>
      'Помоги спланировать бьюти-процедуры на неделю с учётом моего типа кожи.';
  @override String get promptProductsTitle   => 'Подбор средств';
  @override String get promptProducts        =>
      'Порекомендуй конкретные средства. Спроси про бюджет и предпочтения.';
  @override String get promptProblemsTitle   => 'Проблемы кожи';
  @override String get promptProblems        =>
      'У меня есть проблемы с кожей. Задай вопросы, чтобы понять, что меня беспокоит.';
  @override String get promptAntiAgeTitle    => 'Anti-age';
  @override String get promptAntiAge         =>
      'Интересует anti-age уход. Что посоветуешь для профилактики старения?';
  @override String get promptQuickTipTitle   => 'Быстрый совет';
  @override String get promptQuickTip        =>
      'Дай один полезный бьюти-совет на сегодня — простой, но эффективный.';
  @override String get promptOnboardingTitle => 'Знакомство';
  @override String get promptOnboarding =>
      'Давай познакомимся! Расскажи о себе — тип кожи, заботы, образ жизни — '
      'чтобы я могла давать персональные советы.';
  @override String get chipRequired => 'Обязательно';
  @override String get chipRefreshPrompts => 'Другие темы';

  // ─── Input bar ──────────────────────────────────────────
  @override String get inputHint           => 'Я помогу с уходом, макияжем — просто спросите...';
  @override String get inputListening      => 'Слушаю...';
  @override String get takePhoto           => 'Сделать фото';
  @override String get chooseFromGallery   => 'Выбрать из галереи';
  @override String get guidedCapture       => 'Образцовая съёмка';

  // ─── Message menu ───────────────────────────────────────
  @override String get menuLike            => 'Нравится';
  @override String get menuUnlike          => 'Убрать лайк';
  @override String get menuCopy            => 'Копировать';
  @override String get menuRetry           => 'Повторить';
  @override String get menuDeleteMessage   => 'Удалить сообщение';
  @override String get menuClearChat       => 'Очистить чат';

  // ─── SDUI: Unknown block ────────────────────────────────
  @override String get sduiUnsupportedBlock =>
      'Это сообщение содержит блок, который приложение пока не поддерживает';

  // ─── SDUI: Questionnaire Prompt block ──────────────────
  @override String qpProgressLabel(int current, int total) =>
      'Вопрос $current из $total';
  @override String get qpRevalidationHint =>
      'Ты отмечала это раньше — актуально ли сейчас?';
  @override String get qpDoneButton       => 'Готово';
  @override String get qpSendButton       => 'Отправить';
  @override String get qpFreeTextHint     => 'Введите ответ...';
  @override String get qpSubmittedLabel   => 'Отправлено';
  @override String get qpNumericMinLabel  => 'мин';
  @override String get qpNumericMaxLabel  => 'макс';
  @override String get qpMalformedButtonsBanner =>
      'Этот вопрос сейчас недоступен — продолжайте консультацию как обычно, '
      'мы вернёмся к нему позже.';

  // ─── SDUI: Calendar Proposal block (Флоу 4, calendar_proposal v2) ──
  // CONTRACT_flow4_scheduling_v1.md §2-3. round/roundCap приходят из
  // payload блока, не хардкодятся клиентом.
  @override String schedulingRoundIndicator(int round, int roundCap) =>
      'Попытка $round из $roundCap';
  @override String get schedulingSlotConfirmed => 'Запись подтверждена.';
  @override String get schedulingSlotStaleRound =>
      'Это предложение уже устарело — уточни у ассистента актуальные варианты.';
  @override String get schedulingSlotNotFound =>
      'Не нашли эту сессию планирования — попробуй начать заново.';
  @override String get schedulingSlotNotOwner =>
      'Эта запись принадлежит другой сессии.';
  @override String get schedulingSlotGenericError =>
      'Не получилось подтвердить запись, попробуй ещё раз.';
  // TODO: copy review — плейсхолдер, финальную формулировку не финализировать здесь.
  @override String get schedulingNoSlotsFound =>
      'Подходящих слотов не найдено.';

  // ─── SDUI: Calendar Event Confirmation block (Флоу 4, v1) ──
  @override String get calendarConfirmationCancelledLabel => 'Отменено';
  @override String get calendarConfirmationRescheduledLabel => 'Перенесено';
  @override String get calendarConfirmationWasLabel => 'Было';
  @override String get calendarConfirmationNowLabel => 'Стало';

  // ─── Profile ────────────────────────────────────────────
  @override String get profileTitle             => 'МОЙ ПРОФИЛЬ';
  @override String get profileMember            => 'Участник AURA Beauty';
  @override String get profileCompletion        => 'Заполненность профиля';
  @override String get profileChoosePhoto       => 'ВЫБЕРИТЕ ФОТО ПРОФИЛЯ';
  @override String get profileAddPhotosFirst    => 'Сначала добавьте фото в чате';
  @override String get profileMyPhotos          => 'МОИ ФОТО';
  @override String get profileAddPhotosHint     => 'Добавляйте фото в чате';
  @override String get profileAddPhotosDesc     =>
      'AURA проанализирует их и даст\nболее персональные советы';
  @override String get profileBeautyTitle       => 'BEAUTY ПРОФИЛЬ';
  @override String get profileBeautyEmpty       =>
      'Общайтесь с AURA, чтобы создать свой beauty профиль';
  @override String get profileSkinType          => 'Тип кожи';
  @override String get profileConcerns          => 'Проблемы';
  @override String get profileHair              => 'Волосы';
  @override String get profileLifestyle         => 'Образ жизни';
  @override String get profileStyle             => 'Стиль';
  @override String get profileAccount           => 'АККАУНТ';
  @override String get profilePlatform          => 'Платформа';
  @override String get profileSubscription      => 'Подписка';
  @override String get profileSubscriptionFree  => 'Бесплатная';
  @override String get profileDeviceId          => 'ID устройства';
  @override String get profileSignOut           => 'Выйти';
  @override String get profileDeletePhoto       => 'Удалить фото?';
  @override String get profileDeletePhotoConfirm => 'Это фото будет удалено навсегда.';
  @override String get profileDeleteCancel      => 'Отмена';
  @override String get profileDeleteConfirm     => 'Удалить';

  // ─── Profile redesign (tabs, Attributes card, overflow menu) ────
  @override String get profileAttributesTitle => 'Атрибуты';
  @override String get profileTabBeauty       => 'Beauty-профиль';
  @override String get profileTabJournal      => 'Дневник кожи';
  @override String get profileMoreOptions     => 'Ещё';
  @override String get profileSeeAll          => 'Все';

  // ⚠ Черновая формулировка — требует финальной сверки с владельцем контента.
  @override String get profileSummaryTitle    => 'Как AURA видит вас';
  @override String get profileSummaryPending  => 'AURA ещё формирует описание — загляните чуть позже.';

  // ─── Calendar ───────────────────────────────────────────
  @override String get calendarTitle        => 'КАЛЕНДАРЬ';
  @override String get calendarComingSoon   => 'Скоро';
  @override String get calendarComingSoonDesc => 'Ваш beauty календарь\nпоявится здесь';
  @override String get calendarToday               => 'Сегодня';
  @override String calendarProcedureCount(int count) {
    if (count == 1) return '· $count процедура';
    if (count >= 2 && count <= 4) return '· $count процедуры';
    return '· $count процедур';
  }
  @override String get calendarUpcomingProcedures  => 'Ближайшие процедуры';
  @override List<String> get weekdayShortLabels =>
      const ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  @override List<String> get monthShortLabels => const [
        'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
        'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
      ];
  @override String monthYearLabel(DateTime date) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // ─── Calendar: Procedure categories ─────────────────────
  @override String get categorySerum   => 'Сыворотка';
  @override String get categoryMask    => 'Маска';
  @override String get categoryEyeCare => 'Уход за глазами';
  @override String get categoryPeel    => 'Пилинг';
  // Флоу 4 / Step 0 fix — бакет для backend-категорий, не входящих в
  // исходные 4 (подтверждённый факт: routers/app_calendar.py,
  // CalendarEvent.category default="skincare"), см.
  // procedure_event.dart::ProcedureCategory.other.
  @override String get categoryOther   => 'Другое';

  // ─── Calendar: Mock procedure content ───────────────────
  @override String get mockProcedureHydraGlowSerumTitle => 'HydraGlow Serum';
  @override String get mockProcedureHydraGlowSerumNotes =>
      'Лёгкая сыворотка с гиалуроновой кислотой — глубоко увлажняет и '
      'делает кожу более упругой. Наносить на чистую, слегка влажную кожу '
      'перед кремом.';
  @override String get mockProcedureOvernightSleepMaskTitle =>
      'Overnight Sleep Mask';
  @override String get mockProcedureOvernightSleepMaskNotes =>
      'Питательная ночная маска — восстанавливает барьерную функцию кожи '
      'и удерживает влагу за ночь. Смывать утром.';
  @override String get mockProcedureRetinolEyeSerumTitle => 'Retinol Eye Serum';
  @override String get mockProcedureRetinolEyeSerumNotes =>
      'Мягкая сыворотка с ретинолом низкой концентрации для деликатной '
      'зоны вокруг глаз — помогает с мелкими морщинками. Наносить в '
      'количестве размером с рисовое зёрнышко, избегая линии ресниц.';
  @override String get mockProcedureLacticAcidPeelTitle => 'Lactic Acid Peel';
  @override String get mockProcedureLacticAcidPeelNotes =>
      'Мягкий отшелушивающий пилинг — выравнивает текстуру и тон кожи. На '
      'следующий день обязательно используйте солнцезащитный крем — кожа '
      'станет более чувствительной к солнцу.';

  // ─── Calendar: Procedure detail sheet ───────────────────
  @override String get procedureDetailAbout => 'О процедуре';
  @override String procedureDetailDuration(int minutes) => '$minutes мин';
  @override String get procedureDetailClose => 'Закрыть';

  // ─── Photo Capture (guided) ─────────────────────────────
  @override String get captureTitle           => 'ОБРАЗЦОВАЯ СЪЁМКА';
  @override String get captureHintInitial     =>
      'Расположите лицо внутри овала';
  @override String get captureButton          => 'СНЯТЬ';
  @override String get captureRetake          => 'Переснять';
  @override String get captureUse             => 'Использовать';
  @override String get captureCancel          => 'Отмена';

  @override String get captureIndicatorLighting  => 'Освещение';
  @override String get captureIndicatorAngle     => 'Ракурс';
  @override String get captureIndicatorPosition  => 'Позиция';
  @override String get captureIndicatorDistance  => 'Дистанция';

  @override String get captureHintLightingDim         =>
      'Включите яркий свет или встаньте у окна';
  @override String get captureHintLightingOverexposed =>
      'Фото слишком яркое — отойдите от окна';
  @override String get captureHintSharpness           =>
      'Держите телефон ровно, нажмите для фокусировки';
  @override String get captureHintAngle               =>
      'Поверните голову прямо, смотрите в камеру';
  @override String get captureHintTooClose            =>
      'Отодвиньте телефон немного дальше';
  @override String get captureHintTooFar              =>
      'Пододвиньте телефон ближе';

  @override String get captureErrorPermission =>
      'Для образцовой съёмки требуется доступ к камере';
  @override String get captureErrorInit       =>
      'Не удалось инициализировать камеру';

  // ─── Errors ─────────────────────────────────────────────
  @override String get errorNetwork         => 'Проверьте подключение к интернету';
  @override String get errorNoConnection    => 'Не удалось подключиться к серверу';
  @override String get errorTimeout         => 'Сервер не отвечает. Попробуйте позже';
  @override String get errorAuth            => 'Ошибка авторизации. Перезапустите приложение';
  @override String get errorNotFound        => 'Данные не найдены';
  @override String get errorServer          => 'Ошибка сервера. Попробуйте позже';
  @override String get errorUnknown         => 'Что-то пошло не так';
  @override String get errorGeneric         => 'Произошла неизвестная ошибка';

  // ─── Legal Consent Gate v4 (регистрация + региональный экран) ────
  @override String get legalBirthDateLabel => 'Дата рождения';
  @override String get legalBirthDatePlaceholder => 'Выберите дату';
  @override String get legalBasicConsentPrefix => 'Я согласен(а) с ';
  @override String get legalBasicConsentLinkText => 'условиями обработки данных';
  @override String get legalUnderageTitle => 'Сервис недоступен';
  @override String get legalUnderageMessage =>
      'Извините, AURA доступна только пользователям от 18 лет.';
  @override String get legalUnderageClose => 'Закрыть';
  @override String get legalConsentRequiredError =>
      'Подтвердите согласие с условиями, чтобы продолжить';

  @override String get legalRegionalTitle => 'Ваш регион';
  @override String legalRegionConfirmQuestion(String regionLabel) =>
      'Мы определили ваш регион как $regionLabel — верно?';
  @override String get legalRegionConfirmToggleLabel => 'Да, это мой регион';
  @override String get legalRegionSelectLabel => 'Выберите регион';
  @override String get legalRegionEu => 'Евросоюз';
  @override String get legalRegionUs => 'США';
  @override String get legalRegionLatam => 'Латинская Америка';
  @override String get legalRegionRu => 'Россия';
  @override String get legalRegionCn => 'Китай';
  @override String get legalRegionOther => 'Другое';
  @override String get legalRegionUnknownLabel => 'не определён';
  @override String get legalChatTosPrefix => 'Я согласен(а) с ';
  @override String get legalChatTosLinkText => 'условиями использования чата';
  @override String get legalPersonalDataPrefix => 'Я согласен(а) с ';
  @override String get legalPersonalDataLinkText => 'политикой обработки персональных данных';
  @override String get legalRegionalSubmitButton => 'Продолжить';
  @override String get legalRegionalDeclinedTitle => 'Без согласия с условиями продолжить нельзя';
  @override String get legalRegionalDeclinedMessage =>
      'Вы можете вернуться и принять условия, когда будете готовы.';
  @override String get legalRegionalDeclinedRetryButton => 'Вернуться к условиям';

  // ─── Legal Consent Gate v4 (medical, SDUI legal_consent_gate) ────
  @override String get legalMedicalGateTitle => 'Прежде чем продолжить';
  @override String get legalMedicalDataConsentPrefix => 'Я согласен(а) с ';
  @override String get legalMedicalDataConsentLinkText =>
      'условиями обработки данных о здоровье';
  @override String get legalModelTrainingConsentPrefix => 'Я согласен(а) на ';
  @override String get legalModelTrainingConsentLinkText =>
      'использование моих данных для обучения моделей';
  @override String get legalMedicalGateSubmitButton => 'Принять и продолжить';
  @override String get legalMedicalGateDeclinedBanner =>
      'Вы ранее отклонили условия — для обсуждения вопросов здоровья потребуется согласие.';
  @override String get legalMedicalConsentAcceptedMessage =>
      'Спасибо — теперь можно обсуждать вопросы здоровья.';
  @override String get legalMedicalConsentDeclinedMessage =>
      'Поняла — вопросы здоровья останутся недоступны, пока не будет принято согласие.';

  @override String get legalDocumentLoadError => 'Не удалось открыть документ';

  // ─── Deterministic Profiling Answer v1 (SDUI profiling_question) ──
  @override String get profilingQuestionRevalidationHint =>
      'Ты уже отвечала на это — давай уточним ещё раз';
  @override String get profilingQuestionSaveError =>
      'Не получилось сохранить ответ, попробуй ещё раз';
}
