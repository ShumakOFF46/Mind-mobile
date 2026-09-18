import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';
import '../chat_controller.dart';

class NewChatButton extends StatelessWidget {
  final ChatController controller;

  const NewChatButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextButton.icon(
          onPressed: controller.isStreaming ? null : controller.clearChat,
          icon: const Icon(Icons.add, size: 16),
          label: Text(l.chatStartConsultation),
          style: TextButton.styleFrom(
            foregroundColor: c.textSub,
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}