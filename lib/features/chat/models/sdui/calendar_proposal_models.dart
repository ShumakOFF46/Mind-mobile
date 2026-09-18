/// Модели данных SDUI-блока `calendar_proposal` v2 (Флоу 4).
/// Контракт: CONTRACT_flow4_scheduling_v1.md §2.
///
/// ⚠ На момент написания файла `contracts/sdui_blocks/
/// calendar_proposal.schema.json` (создаётся тем же контрактом впервые)
/// ещё не подтверждён живым прогоном backend-брифа — парсинг ниже
/// написан ПО ТЕКСТУ CONTRACT, не сверен с реальным `agent.messages.blocks`.
/// См. BRIEF_mobile_flow4_scheduling_harness.md п.4 — фикстуры и этот
/// файл требуют отдельного шага сверки перед финальным закрытием.
///
/// Разбор defensive: любое несоответствие обязательным полям бросает
/// FormatException — вызывающий код (SduiBlockDispatcher) обязан ловить
/// это и уходить в UnknownBlock, не ронять экран чата. Тот же паттерн,
/// что и questionnaire_prompt_models.dart.
library;

class CalendarProposalCandidate {
  final String slotId;
  final String start;
  final String end;
  final String label;

  const CalendarProposalCandidate({
    required this.slotId,
    required this.start,
    required this.end,
    required this.label,
  });

  factory CalendarProposalCandidate.fromJson(Map<String, dynamic> json) {
    final slotId = json['slot_id'];
    final start  = json['start'];
    final end    = json['end'];
    final label  = json['label'];
    if (slotId is! String || start is! String || end is! String || label is! String) {
      throw const FormatException(
          'candidate.slot_id/start/end/label обязательны и должны быть строками');
    }
    return CalendarProposalCandidate(
      slotId: slotId,
      start:  start,
      end:    end,
      label:  label,
    );
  }
}

class CalendarProposalBlockData {
  final String schedulingSessionId;
  final int    round;
  final int    roundCap;
  final List<CalendarProposalCandidate> candidates;
  final String rejectLabel;

  const CalendarProposalBlockData({
    required this.schedulingSessionId,
    required this.round,
    required this.roundCap,
    required this.candidates,
    required this.rejectLabel,
  });

  factory CalendarProposalBlockData.fromJson(Map<String, dynamic> json) {
    // ⚠ Контрактные JSON-ключи — `scheduling_session_id`/`round`/
    // `round_cap`/`candidates`/`reject_label` (CONTRACT_flow4_scheduling_
    // v1.md §2). `round`/`round_cap` — снапшот НА КАЖДЫЙ блок, клиент
    // обязан рендерить их из payload, не хардкодить число попыток нигде
    // в Dart-коде (см. BRIEF п.1 — грep на литерал 3 в новых файлах
    // должен быть пуст).
    final sessionId     = json['scheduling_session_id'];
    final round         = json['round'];
    final roundCap      = json['round_cap'];
    final rawCandidates = json['candidates'];
    final rejectLabel   = json['reject_label'];

    if (sessionId is! String ||
        round is! int ||
        roundCap is! int ||
        rawCandidates is! List ||
        rejectLabel is! String) {
      throw const FormatException(
          'scheduling_session_id/round/round_cap/candidates/reject_label обязательны');
    }

    final candidates = rawCandidates
        .map((c) => CalendarProposalCandidate.fromJson(
            Map<String, dynamic>.from(c as Map)))
        .toList();

    return CalendarProposalBlockData(
      schedulingSessionId: sessionId,
      round:               round,
      roundCap:            roundCap,
      candidates:          candidates,
      rejectLabel:         rejectLabel,
    );
  }
}
