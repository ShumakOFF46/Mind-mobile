import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';
import '../models/profile_tab.dart';

/// Двухсекционный переключатель "Beauty Profile" / "Skin Journal".
/// Чисто локальный UI-state (управляется родителем через onChanged) —
/// переключение вкладки не ходит в API, только меняет, какая уже
/// загруженная секция показывается.
class ProfileTabs extends StatelessWidget {
  const ProfileTabs({
    super.key,
    required this.active,
    required this.onChanged,
  });

  final ProfileTab active;
  final ValueChanged<ProfileTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.aiBubble,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(c, l.profileTabBeauty, ProfileTab.beauty),
          _segment(c, l.profileTabJournal, ProfileTab.journal),
        ],
      ),
    );
  }

  Widget _segment(AuraColorScheme c, String label, ProfileTab tab) {
    final isActive = tab == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? c.textDark : c.textSub,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
