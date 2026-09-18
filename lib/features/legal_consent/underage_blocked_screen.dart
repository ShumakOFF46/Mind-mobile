import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/l10n/app_localizations.dart';

/// Dead-end экран (контракт §2 п.1: 403 underage — аккаунт НЕ создаётся).
/// Достигается напрямую из LoginScreen через context.go(), НЕ через
/// go_router redirect — на этом этапе AppStorage.getUserName() ещё пуст,
/// обычная redirect-логика роутера этот случай не должна перехватывать.
class UnderageBlockedScreen extends StatelessWidget {
  const UnderageBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, color: c.hint, size: 56),
                const SizedBox(height: 24),
                Text(
                  l.legalUnderageTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l.legalUnderageMessage,
                  style: TextStyle(fontSize: 14, color: c.textSub, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => SystemNavigator.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textDark,
                      side: BorderSide(color: c.hint),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(l.legalUnderageClose),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
