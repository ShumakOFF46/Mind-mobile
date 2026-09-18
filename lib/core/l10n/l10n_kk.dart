import 'l10n_en.dart';

/// Казахский — наследует английский до появления переводчика.
/// Заменяй методы по одному по мере перевода.
class L10nKk extends L10nEn {
  const L10nKk();

  @override String get appTagline      => 'Beauty AI Кеңесші';
  @override String get loginQuestion   => 'Сіздің атыңыз кім?';
  @override String get loginSubtitle   => 'Бұл бізге жеке сөйлесуге\nкөмектеседі';
  @override String get loginHint       => 'Есіміңіз';
  @override String get loginButton     => 'Жалғастыру';

  @override String get chatCalendar    => 'КҮНТІЗБЕ';
  @override String get chatMyProfile   => 'ПРОФИЛІМ';
  @override String get chatEmpty       => 'Төменде кеңес бастаңыз';
  @override String get chatStartConsultation => 'Кеңес бастау';

  @override String proceduresAdded(int count) =>
      'Күнтізбеге $count рәсім қосылды';

  // ─── Calendar ────────────────────────────────────────────
  // ⚠ Черновой перевод, требует вычитки носителем перед мержем
  // (см. BRIEF_mobile_calendar_screen_redesign.md, аналогичная пометка
  // была для предыдущего набора ключей).
  @override String get calendarToday               => 'Бүгін';
  @override String calendarProcedureCount(int count) => '· $count рәсім';
  @override String get calendarUpcomingProcedures  => 'Алдағы рәсімдер';
  @override List<String> get weekdayShortLabels =>
      const ['Жс', 'Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб'];
  @override List<String> get monthShortLabels => const [
        'Қаң', 'Ақп', 'Нау', 'Сәу', 'Мам', 'Мау',
        'Шіл', 'Там', 'Қыр', 'Қаз', 'Қар', 'Жел',
      ];
  @override String monthYearLabel(DateTime date) {
    const months = [
      'Қаңтар', 'Ақпан', 'Наурыз', 'Сәуір', 'Мамыр', 'Маусым',
      'Шілде', 'Тамыз', 'Қыркүйек', 'Қазан', 'Қараша', 'Желтоқсан',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // ─── Calendar: Procedure categories ───────────────────────
  @override String get categorySerum   => 'Сарысу';
  @override String get categoryMask    => 'Маска';
  @override String get categoryEyeCare => 'Көз аймағына күтім';
  @override String get categoryPeel    => 'Пилинг';
  // ⚠ Черновой перевод, требует вычитки носителем перед мержем. Добавлен
  // вместе с ProcedureCategory.other (Step 0 fix, taxonomy-gap) — для
  // консистентности с остальными 4 категориями этой секции, хотя
  // технически мог бы быть унаследован от L10nEn ("Other") без правки
  // этого файла, как это уже происходит для schedulingRoundIndicator/*
  // (Флоу 4) — они НЕ переопределены здесь намеренно, см.
  // L10N_STATUS.md.
  @override String get categoryOther   => 'Басқа';

  // ─── Calendar: Mock procedure content ─────────────────────
  // ⚠ Черновой перевод, требует вычитки носителем перед мержем.
  @override String get mockProcedureHydraGlowSerumTitle => 'HydraGlow Serum';
  @override String get mockProcedureHydraGlowSerumNotes =>
      'Гиалурон қышқылы бар жеңіл сарысу — теріні терең ылғалдандырады. '
      'Тазаланған, сәл дымқыл теріге кремнен бұрын жағыңыз.';
  @override String get mockProcedureOvernightSleepMaskTitle =>
      'Overnight Sleep Mask';
  @override String get mockProcedureOvernightSleepMaskNotes =>
      'Түнгі қоректендіргіш маска — түн бойы теріні қалпына келтіреді. '
      'Таңертең шайыңыз.';
  @override String get mockProcedureRetinolEyeSerumTitle => 'Retinol Eye Serum';
  @override String get mockProcedureRetinolEyeSerumNotes =>
      'Көз аймағына арналған жұмсақ ретинол сарысуы — ұсақ әжімдерге '
      'көмектеседі. Күріш дәні мөлшерінде жағыңыз.';
  @override String get mockProcedureLacticAcidPeelTitle => 'Lactic Acid Peel';
  @override String get mockProcedureLacticAcidPeelNotes =>
      'Жұмсақ эксфолиациялық пилинг — тері текстурасын тегістейді. '
      'Келесі күні күн қорғаныс кремін қолданыңыз.';

  // ─── Calendar: Procedure detail sheet ─────────────────────
  @override String get procedureDetailAbout => 'Процедура туралы';
  @override String procedureDetailDuration(int minutes) => '$minutes мин';
  @override String get procedureDetailClose => 'Жабу';

  // ─── Profile redesign (tabs, Attributes card, overflow menu) ────
  // ⚠ Черновой перевод, требует вычитки носителем перед мержем.
  @override String get profileAttributesTitle => 'Атрибуттар';
  @override String get profileTabBeauty       => 'Beauty-профиль';
  @override String get profileTabJournal      => 'Тері күнделігі';
  @override String get profileMoreOptions     => 'Тағы';
  @override String get profileSeeAll          => 'Барлығы';
}
