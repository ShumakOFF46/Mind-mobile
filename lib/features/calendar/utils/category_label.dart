import '../../../core/l10n/app_localizations.dart';
import '../models/procedure_event.dart';

String categoryLabel(ProcedureCategory category, AppLocalizations l) {
  switch (category) {
    case ProcedureCategory.serum:
      return l.categorySerum;
    case ProcedureCategory.mask:
      return l.categoryMask;
    case ProcedureCategory.eyeCare:
      return l.categoryEyeCare;
    case ProcedureCategory.peel:
      return l.categoryPeel;
    case ProcedureCategory.other:
      return l.categoryOther;
  }
}
