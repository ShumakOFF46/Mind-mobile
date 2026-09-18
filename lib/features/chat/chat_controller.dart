import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/api/api_client.dart';
import '../../core/api/error_handler.dart';
import '../../core/storage.dart';
import 'chat_controller_calendar_badge.dart';
import 'models/chat_message.dart';
import 'models/scheduling_messages.dart';

/// Сигнатура ApiClient.streamChat() — вынесена отдельным typedef, чтобы
/// ChatController мог принимать mock-реализацию в тестах (см.
/// BRIEF_mobile_fix_conversationid_reset_on_stream_exception.md, задача 3),
/// не трогая сам ApiClient/SSE-парсинг (вне объёма брифа).
/// ⚠ ПРОВЕРИТЬ перед компиляцией: сигнатура должна дословно совпадать с
/// реальным ApiClient.streamChat() из core/api/api_client.dart — иначе
/// `streamChat ?? ApiClient.streamChat` в конструкторе не затайпчекается.
typedef StreamChatFn = Stream<Map<String, dynamic>> Function({
  required String prompt,
  String? conversationId,
  List<Map<String, dynamic>>? busySlots,
});

class ChatController extends ChangeNotifier with ChatControllerCalendarBadge {
  ChatController({StreamChatFn? streamChat})
      : _streamChat = streamChat ?? ApiClient.streamChat;

  /// Реальная реализация — ApiClient.streamChat (дефолт). В тестах
  /// подменяется мок-функцией через конструктор.
  final StreamChatFn _streamChat;

  final List<ChatMessage> messages         = [];
  bool                    isStreaming      = false;
  bool                    isUploadingPhoto = false;
  String?                 conversationId;

  final TextEditingController inputController  = TextEditingController();
  final ScrollController      scrollController = ScrollController();
  final stt.SpeechToText      _speech          = stt.SpeechToText();
  bool                        speechAvailable  = false;
  bool                        isListening      = false;

  // ─── Init ──────────────────────────────────────────────

  Future<void> init() async {
    await _initSpeech();
    await loadHistory();
  }

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ─── Speech ────────────────────────────────────────────

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError:  (e)      => debugPrint('STT error: $e'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening = false;
          notifyListeners();
        }
      },
    );
    speechAvailable = available;
    notifyListeners();
  }

  Future<void> toggleListening(VoidCallback onFinalResult) async {
    if (isStreaming) return;
    if (isListening) {
      await _speech.stop();
      isListening = false;
      notifyListeners();
    } else {
      isListening = true;
      notifyListeners();
      await _speech.listen(
        onResult: (result) {
          inputController.text = result.recognizedWords;
          inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: inputController.text.length),
          );
          notifyListeners();
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _speech.stop();
            isListening = false;
            notifyListeners();
            onFinalResult();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId:      'ru_RU',
          listenFor:     const Duration(seconds: 30),
          pauseFor:      const Duration(seconds: 3),
          cancelOnError: true,
        ),
      );
    }
  }

  // ─── History ───────────────────────────────────────────

  Future<void> loadHistory() async {
    final convId = await AppStorage.getConversationId();
    if (convId == null || convId.isEmpty) return;
    try {
      final history = await ApiClient.loadHistory(convId);
      conversationId = convId;
      messages.addAll(history.map((m) => ChatMessage(
        text:   m['content'] as String,
        isUser: m['role'] == 'user',
        timestamp: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      )));
      notifyListeners();
      scrollToBottom();
    } catch (e) {
      debugPrint('loadHistory error: $e');
      final appError = ErrorHandler.handle(e, ErrorHandler.defaultMessages);
      if (appError.type != AppErrorType.network) {
        await AppStorage.saveConversationId('');
      }
    }
  }

  // ─── Send ──────────────────────────────────────────────

  Future<void> sendMessage({String? overrideText, String? imageUrl}) async {
    final text = overrideText ?? inputController.text.trim();
    if (text.isEmpty || isStreaming) return;
    if (overrideText == null) inputController.clear();

    messages.add(ChatMessage(text: text, isUser: true, imageUrl: imageUrl));
    messages.add(ChatMessage(text: '', isUser: false));
    isStreaming = true;
    notifyListeners();
    scrollToBottom();

    // Снимок ДО попытки — нужен catch-блоку, чтобы принять явное решение
    // про conversationId (см. BRIEF_mobile_fix_conversationid_reset_on_
    // stream_exception.md, п.2), а не молча полагаться на побочный эффект
    // того, что conversationId просто не был тронут.
    final hadConversationIdBeforeAttempt = conversationId != null;

    try {
      final stream = _streamChat(
        prompt:         text,
        conversationId: conversationId,
      );
      await for (final event in stream) {
        await handleStreamEvent(event);
      }
    } catch (e) {
      // Обрыв streamChat() посреди потока (сеть/таймаут). Явная политика
      // (бриф, п.2):
      // - conversationId был null до попытки → это была попытка создать
      //   НОВЫЙ разговор, id с сервера не долетел → оставляем null,
      //   ничего лишнего "осиротевшего" на клиенте не появляется.
      // - conversationId уже был известен → это продолжение
      //   существующего разговора → НЕ обнуляем: разговор на сервере,
      //   скорее всего, существует, оборвался только content-поток;
      //   обнуление id потеряло бы связь с реальной перепиской.
      // Обе ветки технически не мутируют conversationId (он и так не
      // трогался) — политика зафиксирована явно тестами ниже, не
      // оставлена implicit-поведением.
      if (hadConversationIdBeforeAttempt) {
        debugPrint(
          'streamChat error, conversationId "$conversationId" сохранён '
          '(разговор уже существовал до обрыва): '
          '${e.runtimeType}: $e',
        );
      } else {
        debugPrint(
          'streamChat error, conversationId остаётся null '
          '(id нового разговора не был получен до обрыва): '
          '${e.runtimeType}: $e',
        );
      }
      final appError = ErrorHandler.handle(e, ErrorHandler.defaultMessages);
      messages[messages.length - 1] = ChatMessage(
        text:   appError.message,
        isUser: false,
      );
    } finally {
      isStreaming = false;
      notifyListeners();
    }
  }

  /// Обработка одного декодированного SSE-события из ApiClient.streamChat().
  /// Вынесено из sendMessage() как публичный метод намеренно — это
  /// тестовая точка входа для синтетических чанков (см. бриф
  /// questionnaire_prompt, Задача 3): позволяет прогнать событие
  /// {"blocks": [...]} через реальный ChatMessage/notifyListeners() без
  /// поднятия сети/мок-сервера.
  ///
  /// ⚠ `calendar_proposal` приходит ОТДЕЛЬНЫМ SSE-полем, никогда через
  /// `blocks[]` (backend `app_chat.py::_split_blocks()`) — оба поля ведут
  /// в один путь рендера через `_appendBlocksToLastMessage()`. Полная
  /// история фикса маршрутизации (коммит 35ab43f) —
  /// BRIEF_mobile_calendar_proposal_transport_fix.md /
  /// REPORT_mobile_calendar_proposal_render_check.md, не повторяю здесь.
  Future<void> handleStreamEvent(Map<String, dynamic> event) async {
    if (event.containsKey('blocks')) {
      final blocks = (event['blocks'] as List<dynamic>? ?? [])
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList();
      _appendBlocksToLastMessage(blocks);
    } else if (event.containsKey('calendar_proposal')) {
      final block = Map<String, dynamic>.from(
        event['calendar_proposal'] as Map,
      );
      _appendBlocksToLastMessage([block]);
    } else if (event.containsKey('content')) {
      final chunk = event['content'] as String;
      final last  = messages.last;
      messages[messages.length - 1] = last.copyWith(
        text: last.text + chunk,
      );
      notifyListeners();
      scrollToBottom();
    } else if (event.containsKey('conversation_id')) {
      conversationId = event['conversation_id'] as String;
      await AppStorage.saveConversationId(conversationId!);
    }
  }

  /// Общий путь добавления SDUI-блоков в последнее сообщение — используется
  /// и для `{"blocks": [...]}`, и для `{"calendar_proposal": {...}}` (см.
  /// handleStreamEvent()). Мёрджит с уже имеющимися блоками сообщения, а не
  /// перезаписывает — оба поля технически независимые SSE-события и в
  /// одном сообщении теоретически могут прийти оба (например,
  /// calendar_event_confirmation через `blocks` и следом calendar_proposal
  /// отдельным полем в рамках negotiation loop).
  void _appendBlocksToLastMessage(List<Map<String, dynamic>> newBlocks) {
    final last = messages.last;
    final merged = [...?last.blocks, ...newBlocks];
    messages[messages.length - 1] = last.copyWith(blocks: merged);
    // BRIEF_mobile_calendar_badge_invalidation_gap.md п.1.2: приход этого
    // блока сам по себе — сигнал, что запись в календаре реально
    // изменилась на бэкенде (cancel/reschedule), независимо от того,
    // распарсит ли его дальше SduiBlockDispatcher — проверка по сырому
    // `type`, не по распарсенной модели.
    if (newBlocks.any((b) => b['type'] == 'calendar_event_confirmation')) {
      onCalendarChanged?.call();
    }
    notifyListeners();
    scrollToBottom();
  }

  // ─── Photo ─────────────────────────────────────────────

  Future<void> uploadAndSendPhoto({
    required Uint8List fileBytes,
    required String    mimeType,
    required String    prompt,
    Map<String, dynamic>? qualityMetadata,
  }) async {
    if (isStreaming) return;
    isUploadingPhoto = true;
    notifyListeners();
    try {
      final result   = await ApiClient.uploadPhoto(
          fileBytes: fileBytes,
          mimeType: mimeType,
          qualityMetadata: qualityMetadata);
      final imageUrl = result['url'] as String?;
      await sendMessage(
        overrideText: prompt,
        imageUrl:     imageUrl,
      );
    } catch (e) {
      debugPrint('uploadPhoto error: $e');
      rethrow;
    } finally {
      isUploadingPhoto = false;
      notifyListeners();
    }
  }

  // ─── Scheduling (Флоу 4 negotiation loop) ──────────────

  /// Приём предложенного календарного слота — CONTRACT_flow4_scheduling_
  /// v1.md §3. Вызывается из виджета CalendarProposalBlock по тапу на
  /// кандидата (через SduiBlockDispatcher → ChatBubble → сюда), НЕ из
  /// sendMessage(). Структурированный HTTP-вызов, СОЗНАТЕЛЬНО МИМО
  /// streamChat()/LLM (universal_dialog_engine.md §9: выбор уже
  /// структурирован тапом, экстракция даты из текста здесь не нужна и не
  /// должна происходить).
  ///
  /// [schedulingMessages] — локализованные строки подтверждения/ошибки,
  /// резолвятся ВЫЗЫВАЮЩИМ КОДОМ через `SchedulingMessages.fromL10n(
  /// context.l10n)` (тот виджет имеет BuildContext, ChatController — нет),
  /// см. models/scheduling_messages.dart. Тот же паттерн, что уже
  /// используется для сетевых ошибок (ErrorHandler.fromL10n) в этом же
  /// файле — не новый прецедент.
  ///
  /// Подтверждение/ошибка добавляются в чат ЛОКАЛЬНО (не через LLM) —
  /// событие уже произошло на структурированном пути, ассистент не
  /// формулирует этот ответ.
  Future<void> acceptSchedulingSlot({
    required String schedulingSessionId,
    required String slotId,
    required SchedulingMessages schedulingMessages,
  }) async {
    try {
      final result = await ApiClient.acceptSchedulingSlot(
        schedulingSessionId: schedulingSessionId,
        slotId: slotId,
      );
      final confirmed = result['status'] == 'confirmed';
      // BRIEF_mobile_calendar_badge_invalidation_gap.md п.1.2, основной
      // кейс из эскалации: только "confirmed" реально создаёт запись в
      // `beauty.calendar_events` — ветка reason (stale_round/not_found/
      // not_owner) ничего не меняет, инвалидация там не нужна.
      if (confirmed) onCalendarChanged?.call();
      messages.add(ChatMessage(
        text: confirmed
            ? schedulingMessages.confirmed
            : schedulingMessages.forReason(result['reason'] as String?),
        isUser: false,
      ));
    } catch (e) {
      debugPrint('acceptSchedulingSlot error: $e');
      final appError = ErrorHandler.handle(e, ErrorHandler.defaultMessages);
      messages.add(ChatMessage(text: appError.message, isUser: false));
    } finally {
      notifyListeners();
      scrollToBottom();
    }
  }

  // ─── Message actions ───────────────────────────────────

  void likeMessage(int index) {
    messages[index] = messages[index].copyWith(liked: !messages[index].liked);
    notifyListeners();
  }

  void retryMessage(int index) {
    String? userText;
    for (int i = index - 1; i >= 0; i--) {
      if (messages[i].isUser) { userText = messages[i].text; break; }
    }
    if (userText == null) return;
    if (index > 0 && messages[index - 1].isUser) {
      messages.removeRange(index - 1, index + 1);
    } else {
      messages.removeAt(index);
    }
    notifyListeners();
    sendMessage(overrideText: userText);
  }

  void deleteMessage(int index) {
    messages.removeAt(index);
    notifyListeners();
  }

  Future<void> clearChat() async {
    messages.clear();
    conversationId = null;
    await AppStorage.saveConversationId('');
    notifyListeners();
  }

  // ─── Scroll ────────────────────────────────────────────

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  /// Публичный шлюз для extension-файлов (например,
  /// chat_controller_legal_consent.dart), вынесенных из этого файла по
  /// правилу "≤300-400 строк" — `notifyListeners()` сам по себе
  /// @protected внутри `ChangeNotifier` (доступен только в пределах его
  /// же библиотеки), extension в ДРУГОМ файле не может вызвать его
  /// напрямую (flutter analyze: invalid_use_of_protected_member/
  /// invalid_use_of_visible_for_testing_member — найдено живым
  /// прогоном 2026-09-06). Тонкая обёртка, не меняет логику.
  void notifyChatListeners() => notifyListeners();
}
