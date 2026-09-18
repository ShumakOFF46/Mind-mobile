import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/storage.dart';
import '../../../core/theme.dart';

class ChatWelcome extends StatelessWidget {
  const ChatWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          FutureBuilder<String?>(
            future: AppStorage.getUserName(),
            builder: (context, snapshot) {
              final name = snapshot.data;
              return Text(
                name != null && name.isNotEmpty
                    ? '${l.chatWelcome}, $name'
                    : l.chatWelcome,
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  color:      c.textDark,
                  fontSize:   24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }
}