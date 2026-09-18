import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';
import '../models/quick_prompt.dart';

class QuickPromptsSection extends StatelessWidget {
  final List<QuickPrompt> prompts;
  // ✅ ИСПРАВЛЕНО: VoidCallback → ValueChanged<QuickPrompt>
  final ValueChanged<QuickPrompt> onPromptTap;
  final VoidCallback onRefresh;

  const QuickPromptsSection({
    super.key,
    required this.prompts,
    required this.onPromptTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l.chatStartWith, style: TextStyle(
              color: c.accent, fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 2,
            )),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: prompts.map((p) => _QuickPromptChip(
              prompt: p,
              onTap:  () => onPromptTap(p),
            )).toList(),
          ),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 14),
            label: Text(l.chatOtherTopics),
            style: TextButton.styleFrom(
              foregroundColor: c.textSub,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final QuickPrompt prompt;
  final VoidCallback onTap;

  const _QuickPromptChip({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: prompt.isRequired ? c.accent.withValues(alpha: 0.12) : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: prompt.isRequired ? c.accent : c.accent.withValues(alpha: 0.25),
            width: prompt.isRequired ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(prompt.icon, color: prompt.iconColor, size: 18),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prompt.title, style: TextStyle(
                  color: c.textDark, fontSize: 13, fontWeight: FontWeight.w600,
                )),
                if (prompt.isRequired)
                  Text(l.chipRequired, style: TextStyle(
                    color: c.accent, fontSize: 9,
                    fontWeight: FontWeight.w500, letterSpacing: 0.5,
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}