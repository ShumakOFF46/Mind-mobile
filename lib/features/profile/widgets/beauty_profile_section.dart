import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme.dart';
import 'beauty_attribute_row.dart';

/// "Attributes" карточка — те же поля из `getBeautyProfile()`, что и
/// раньше (`skin_type`/`concerns`/`hair`/`lifestyle`/`style_prefs`, см.
/// `beauty.user_data` в ProjectFull.md), просто в новом визуальном стиле
/// (иконка + капс-подпись слева + значение справа + разделитель) вместо
/// прежних отдельных плиток `profileTile()`.
///
/// ⚠ Полей "Tone"/"Sensitivity" с концепт-скриншота здесь НЕТ: такой
/// колонки/ключа нет ни в `beauty.user_data`, ни в задокументированном
/// ответе `/app/profile` (см. ProjectFull.md) — не показываю
/// несуществующие данные как настоящие. Если продукт хочет именно эти
/// два поля — нужен отдельный backend-бриф на добавление колонок/ключей.
class BeautyProfileSection extends StatelessWidget {
  const BeautyProfileSection({
    super.key,
    required this.profile,
    required this.loading,
  });

  final Map<String, dynamic> profile;
  final bool                 loading;

  @override
  Widget build(BuildContext context) {
    final c      = context.aura;
    final l      = context.l10n;
    final fields = _filledFields(l);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profileAttributesTitle,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              color:      c.textDark,
              fontSize:   18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: c.accent)),
            )
          else if (fields.isEmpty)
            _emptyState(c, l)
          else
            for (var i = 0; i < fields.length; i++)
              BeautyAttributeRow(
                icon:        fields[i].icon,
                label:       fields[i].label,
                value:       fields[i].value,
                showDivider: i != fields.length - 1,
              ),
        ],
      ),
    );
  }

  List<_AttributeField> _filledFields(AppLocalizations l) {
    final fields = <_AttributeField>[
      _AttributeField(Icons.face_retouching_natural_outlined,
          l.profileSkinType, profile['skin_type']?.toString() ?? ''),
      _AttributeField(Icons.favorite_border_rounded,
          l.profileConcerns, _formatList(profile['concerns'])),
      _AttributeField(Icons.content_cut_rounded,
          l.profileHair, _formatJson(profile['hair'])),
      _AttributeField(Icons.self_improvement_outlined,
          l.profileLifestyle, _formatJson(profile['lifestyle'])),
      _AttributeField(Icons.checkroom_outlined,
          l.profileStyle, _formatJson(profile['style_prefs'])),
    ];
    return fields.where((f) => f.value.isNotEmpty).toList();
  }

  Widget _emptyState(AuraColorScheme c, AppLocalizations l) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    decoration: BoxDecoration(
      color:        c.aiBubble,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      l.profileBeautyEmpty,
      textAlign: TextAlign.center,
      style:     TextStyle(color: c.textSub, fontSize: 13),
    ),
  );

  String _formatList(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  String _formatJson(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return value.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }
    return value.toString();
  }
}

class _AttributeField {
  final IconData icon;
  final String   label;
  final String   value;
  const _AttributeField(this.icon, this.label, this.value);
}
