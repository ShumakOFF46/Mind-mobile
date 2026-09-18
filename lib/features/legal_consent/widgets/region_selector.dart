import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';

/// Фиксированный список 6 регионов (BRIEF "Экран 2" — временное решение,
/// отдельный GET-справочник контрактом не предусмотрен;
/// `agent.value_catalogs` catalog_slug='legal_region' — источник правды
/// на бэкенде, зеркалируется здесь вручную). ⚠ Если появится публичный
/// эндпоинт списка регионов — заменить этот hardcode.
class RegionSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const RegionSelector({super.key, required this.value, required this.onChanged});

  static const _regions = ['EU', 'US', 'LATAM', 'RU', 'CN', 'OTHER'];

  String _label(AppLocalizations l, String region) {
    switch (region) {
      case 'EU': return l.legalRegionEu;
      case 'US': return l.legalRegionUs;
      case 'LATAM': return l.legalRegionLatam;
      case 'RU': return l.legalRegionRu;
      case 'CN': return l.legalRegionCn;
      default: return l.legalRegionOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.legalRegionSelectLabel, style: TextStyle(fontSize: 13, color: c.textSub)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _regions.map((r) {
            final isSelected = value == r;
            return ChoiceChip(
              label: Text(_label(l, r)),
              selected: isSelected,
              selectedColor: c.accent,
              labelStyle: TextStyle(color: isSelected ? Colors.white : c.textDark, fontSize: 13),
              onSelected: (_) => onChanged(r),
            );
          }).toList(),
        ),
      ],
    );
  }
}
