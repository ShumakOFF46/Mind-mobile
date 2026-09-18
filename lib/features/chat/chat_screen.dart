import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../calendar/providers/calendar_badge_provider.dart';
import 'chat_controller.dart';
import 'models/quick_prompt.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_list.dart';
import 'widgets/chat_welcome.dart';
import 'widgets/message_menu.dart';
import 'widgets/quick_prompts_section.dart';

// ═══════════════════════════════════════════
// FEATURE FLAG: quick prompts (chips)
// Отключено по просьбе маркетинга — стремимся к минимализму.
// Чтобы включить обратно: поставить true.
// ═══════════════════════════════════════════
const bool kEnableQuickPrompts = false;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final ChatController _ctrl;
  List<QuickPrompt> _quickPrompts = [];
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _ctrl = ChatController();
    // BRIEF_mobile_calendar_badge_invalidation_gap.md п.2: единственная
    // точка инвалидации calendarBadgeProvider во всём приложении.
    // ChatController — обычный ChangeNotifier без доступа к `ref` (см.
    // chat_controller_calendar_badge.dart), поэтому мост наружу — этот
    // колбэк, вызываемый после accept слота (calendar_proposal) и после
    // прихода calendar_event_confirmation (cancel/reschedule).
    _ctrl.onCalendarChanged = () => ref.invalidate(calendarBadgeProvider);
    _ctrl.init();

    // Загружаем профиль и чипы только если они включены
    if (kEnableQuickPrompts) {
      _loadProfileAndPrompts();
    }
  }

  Future<void> _loadProfileAndPrompts() async {
    try {
      final profile = await ApiClient.getBeautyProfile();
      if (mounted) {
        setState(() {
          _isProfileComplete = profile['profiling_done'] == true;
        });
        _rebuildPrompts();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProfileComplete = false);
        _rebuildPrompts();
      }
    }
  }

  void _rebuildPrompts() {
    setState(() {
      _quickPrompts = QuickPromptsLibrary.buildForState(
        l: context.l10n,
        c: context.aura,
        isProfileComplete: _isProfileComplete,
        totalCount: 4,
      );
    });
  }

  void _handleQuickPrompt(QuickPrompt prompt) {
    _ctrl.sendMessage(overrideText: prompt.prompt);
  }

  void _showMessageMenu(int index) {
    final msg = _ctrl.messages[index];
    if (_ctrl.isStreaming && index == _ctrl.messages.length - 1) return;
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => MessageMenu(
        message:  msg,
        onLike:   () { Navigator.pop(context); _ctrl.likeMessage(index); },
        onCopy:   () {
          Navigator.pop(context);
          Clipboard.setData(ClipboardData(text: msg.text));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:         Text(context.l10n.chatCopied),
            duration:        const Duration(seconds: 1),
            backgroundColor: context.aura.textDark,
            behavior:        SnackBarBehavior.floating,
          ));
        },
        onRetry:      msg.isUser ? null
            : () { Navigator.pop(context); _ctrl.retryMessage(index); },
        onDelete:     () { Navigator.pop(context); _ctrl.deleteMessage(index); },
        onDeleteChat: () { Navigator.pop(context); _ctrl.clearChat(); },
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.aura.bg,
      appBar: ChatAppBar.build(context),
      body: SafeArea(
        child: Column(
          children: [
            const ChatWelcome(),
            // Чипы временно отключены — стремимся к минимализму
            if (kEnableQuickPrompts && _ctrl.messages.isEmpty)
              QuickPromptsSection(
                prompts:     _quickPrompts,
                onPromptTap: _handleQuickPrompt,
                onRefresh:   _rebuildPrompts,
              ),
            Expanded(
              child: ChatMessageList(
                controller:  _ctrl,
                onLongPress: _showMessageMenu,
              ),
            ),
            ChatInputBar(controller: _ctrl),
          ],
        ),
      ),
    );
  }
}