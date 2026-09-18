import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';
import 'profile_tiles.dart';

/// Bottom sheet из "..." в AppBar — техническая информация
/// (Platform/Subscription/Device ID) и выход из аккаунта. Раньше эти
/// элементы были всегда видны внизу экрана профиля; перенесены сюда,
/// чтобы основной экран соответствовал новому концепту (Header → Tabs →
/// Attributes/Skin Journal в основной прокрутке, без хвоста служебной
/// информации). Сама логика (_logout, реальные значения) не изменилась —
/// только место отображения.
class ProfileOverflowSheet extends StatelessWidget {
  const ProfileOverflowSheet({
    super.key,
    required this.shortId,
    required this.onSignOut,
  });

  final String shortId;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.hint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            sectionTitle(c, l.profileAccount),
            const SizedBox(height: 12),
            infoTile(c, l.profilePlatform,     'Android'),
            infoTile(c, l.profileSubscription, l.profileSubscriptionFree),
            infoTile(c, l.profileDeviceId,     shortId),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSignOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textSub,
                  side:    BorderSide(color: c.accent.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:   const StadiumBorder(),
                ),
                child: Text(l.profileSignOut, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
