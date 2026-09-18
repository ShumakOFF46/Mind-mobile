import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/storage.dart';
import '../../../core/theme.dart';
import 'calendar_badge_icon.dart';

class ChatAppBar {
  static double iconSize(BuildContext ctx) =>
      (MediaQuery.of(ctx).size.width * 0.11).clamp(28.0, 48.0);
  static double avatarRadius(BuildContext ctx) =>
      (MediaQuery.of(ctx).size.width * 0.064).clamp(18.0, 32.0);
  static double toolbarHeight(BuildContext ctx) =>
      (MediaQuery.of(ctx).size.width * 0.14).clamp(64.0, 96.0);

  static PreferredSizeWidget build(BuildContext context) {
    final c       = context.aura;
    final l       = context.l10n;
    final avatarR = avatarRadius(context);

    return AppBar(
      backgroundColor:  c.bg,
      elevation:        0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight:    toolbarHeight(context),
      leadingWidth:     64,
      leading: CalendarBadgeIcon(onTap: () => context.push('/calendar')),
      title: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('AURA', style: TextStyle(
            fontFamily: 'CormorantGaramond', color: c.textDark,
            fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 4,
          )),
          const SizedBox(width: 4),
          Icon(Icons.auto_awesome, color: c.accent, size: 14),
        ]),
        Text(l.chatSubtitle, style: TextStyle(
          color: c.textSub, fontSize: 10,
          fontWeight: FontWeight.w400, letterSpacing: 1.5,
        )),
      ]),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: ValueListenableBuilder<String?>(
              valueListenable: AppStorage.avatarNotifier,
              builder: (_, avatarPath, _) {
                final ImageProvider? image = avatarPath == null
                    ? null
                    : avatarPath.startsWith('http')
                        ? NetworkImage(avatarPath)
                        : FileImage(File(avatarPath));
                return CircleAvatar(
                  radius: avatarR,
                  backgroundColor: c.aiBubble,
                  backgroundImage: image,
                  child: image == null
                      ? Icon(Icons.person_outline, color: c.textSub, size: avatarR * 1.2)
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
