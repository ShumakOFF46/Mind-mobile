import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme.dart';

/// Нейтральный fallback для нераспознанного SDUI-блока или нераспознанной
/// версии известного блока (unknown block_version). Не роняет рендер
/// экрана чата — тихая заглушка + debug-лог типа блока.
class UnknownBlock extends StatelessWidget {
  final String? blockType;

  const UnknownBlock({super.key, this.blockType});

  @override
  Widget build(BuildContext context) {
    debugPrint('SDUI: unknown block encountered: $blockType');
    final c = context.aura;
    return Container(
      margin:  const EdgeInsets.only(top: 4, right: 60),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        c.aiBubble.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: c.hint.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, size: 14, color: c.textSub),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.l10n.sduiUnsupportedBlock,
              style: TextStyle(fontSize: 12, color: c.textSub),
            ),
          ),
        ],
      ),
    );
  }
}
