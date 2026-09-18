import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';

class MessageMenu extends StatelessWidget {
  final ChatMessage   message;
  final VoidCallback  onLike;
  final VoidCallback  onCopy;
  final VoidCallback? onRetry;
  final VoidCallback  onDelete;
  final VoidCallback  onDeleteChat;

  const MessageMenu({
    super.key,
    required this.message,
    required this.onLike,
    required this.onCopy,
    required this.onRetry,
    required this.onDelete,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color:        c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      c.textDark.withValues(alpha: 0.10),
            blurRadius: 20,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              message.text.length > 80
                  ? '${message.text.substring(0, 80)}\u2026'
                  : message.text,
              style:    TextStyle(color: c.textSub, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: c.textSub.withValues(alpha: 0.15)),
          _MenuItem(
            icon:      message.liked ? Icons.favorite : Icons.favorite_border,
            iconColor: c.accent,
            label:     message.liked ? l.menuUnlike : l.menuLike,
            textColor: c.textDark,
            onTap:     onLike,
          ),
          Divider(height: 1, color: c.textSub.withValues(alpha: 0.15)),
          _MenuItem(
            icon:      Icons.copy_outlined,
            label:     l.menuCopy,
            textColor: c.textDark,
            onTap:     onCopy,
          ),
          if (onRetry != null) ...[
            Divider(height: 1, color: c.textSub.withValues(alpha: 0.15)),
            _MenuItem(
              icon:      Icons.refresh_rounded,
              label:     l.menuRetry,
              textColor: c.textDark,
              onTap:     onRetry!,
            ),
          ],
          Divider(height: 1, color: c.textSub.withValues(alpha: 0.15)),
          _MenuItem(
            icon:          Icons.delete_outline,
            label:         l.menuDeleteMessage,
            onTap:         onDelete,
            isDestructive: true,
          ),
          Divider(height: 1, color: c.textSub.withValues(alpha: 0.15)),
          _MenuItem(
            icon:          Icons.delete_sweep_outlined,
            label:         l.menuClearChat,
            onTap:         onDeleteChat,
            isDestructive: true,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData     icon;
  final Color?       iconColor;
  final Color?       textColor;
  final String       label;
  final VoidCallback onTap;
  final bool         isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive
        ? Colors.redAccent
        : (iconColor ?? textColor ?? const Color(0xFF3D2C2C));
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color:      isDestructive
                    ? Colors.redAccent
                    : (textColor ?? effectiveColor),
                fontSize:   15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
