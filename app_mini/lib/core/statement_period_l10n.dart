import 'package:mini/l10n/app_localizations.dart';

import '../models/financial_statement_model.dart';

extension StatementPeriodTypeL10n on StatementPeriodType {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case StatementPeriodType.today:
        return l10n.periodToday;
      case StatementPeriodType.last24Hours:
        return l10n.periodLast24Hours;
      case StatementPeriodType.oneWeek:
        return l10n.periodOneWeek;
      case StatementPeriodType.oneMonth:
        return l10n.periodOneMonth;
      case StatementPeriodType.threeMonths:
        return l10n.periodThreeMonths;
      case StatementPeriodType.sixMonths:
        return l10n.periodSixMonths;
      case StatementPeriodType.oneYear:
        return l10n.periodOneYear;
      case StatementPeriodType.custom:
        return l10n.periodCustom;
    }
  }
}