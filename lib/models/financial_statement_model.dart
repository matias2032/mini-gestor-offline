// financial_statement_model.dart
/// Period filter used when generating a statement — mirrors
/// [DashboardPeriod] but includes a CUSTOM option for an explicit
/// start/end date range.
enum StatementPeriodType {
  today,
  last24Hours,
  oneWeek,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  custom,
}

extension StatementPeriodTypeX on StatementPeriodType {
  String get dbValue {
    switch (this) {
      case StatementPeriodType.today:
        return 'TODAY';
      case StatementPeriodType.last24Hours:
        return 'LAST_24_HOURS';
      case StatementPeriodType.oneWeek:
        return 'ONE_WEEK';
      case StatementPeriodType.oneMonth:
        return 'ONE_MONTH';
      case StatementPeriodType.threeMonths:
        return 'THREE_MONTHS';
      case StatementPeriodType.sixMonths:
        return 'SIX_MONTHS';
      case StatementPeriodType.oneYear:
        return 'ONE_YEAR';
      case StatementPeriodType.custom:
        return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case StatementPeriodType.today:
        return 'Today';
      case StatementPeriodType.last24Hours:
        return '1 day';
      case StatementPeriodType.oneWeek:
        return '1 week';
      case StatementPeriodType.oneMonth:
        return '1 month';
      case StatementPeriodType.threeMonths:
        return '3 months';
      case StatementPeriodType.sixMonths:
        return '6 months';
      case StatementPeriodType.oneYear:
        return '1 year';
      case StatementPeriodType.custom:
        return 'Custom';
    }
  }

  static StatementPeriodType fromDbValue(String value) {
    return StatementPeriodType.values.firstWhere(
      (period) => period.dbValue == value,
      orElse: () => StatementPeriodType.custom,
    );
  }

  /// Computes the inclusive start of the range given "now". Not used for
  /// [StatementPeriodType.custom] — callers must supply an explicit date.
  DateTime startDateFrom(DateTime now) {
    switch (this) {
      case StatementPeriodType.today:
        return DateTime(now.year, now.month, now.day);
      case StatementPeriodType.last24Hours:
        return now.subtract(const Duration(hours: 24));
      case StatementPeriodType.oneWeek:
        return now.subtract(const Duration(days: 7));
      case StatementPeriodType.oneMonth:
        return now.subtract(const Duration(days: 30));
      case StatementPeriodType.threeMonths:
        return now.subtract(const Duration(days: 90));
      case StatementPeriodType.sixMonths:
        return now.subtract(const Duration(days: 180));
      case StatementPeriodType.oneYear:
        return now.subtract(const Duration(days: 365));
      case StatementPeriodType.custom:
        return now;
    }
  }
}

/// Pure data class representing a row in the `financial_statement` table.
///
/// `updated_at` is omitted from [toMap] because `trg_financial_statement_updated`
/// sets it automatically on UPDATE — same pattern as `sale`/`expense`.
///
/// `businessUnitId` is hybrid scope: `null` means a consolidated
/// (matriz/grupo) statement; a value means the statement is for that one
/// loja.
class FinancialStatementModel {
  const FinancialStatementModel({
    this.idFinancialStatement,
    required this.reference,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    this.businessUnitId,
    this.totalSalesCents = 0,
    this.totalExpensesCents = 0,
    this.balanceCents = 0,
    this.salesCount = 0,
    this.expensesCount = 0,
    this.notes,
    this.deleted = false,
    required this.generatedAt,
    required this.createdAt,
    this.updatedAt,
  });

  final int? idFinancialStatement;
  final String reference;
  final StatementPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final int? businessUnitId;
  final int totalSalesCents;
  final int totalExpensesCents;
  final int balanceCents;
  final int salesCount;
  final int expensesCount;
  final String? notes;
  final bool deleted;
  final DateTime generatedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isConsolidated => businessUnitId == null;

  factory FinancialStatementModel.fromMap(Map<String, Object?> map) {
    return FinancialStatementModel(
      idFinancialStatement: map['id_financial_statement'] as int?,
      reference: map['reference'] as String,
      periodType: StatementPeriodTypeX.fromDbValue(map['period_type'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      businessUnitId: map['business_unit_id'] as int?,
      totalSalesCents: map['total_sales_cents'] as int,
      totalExpensesCents: map['total_expenses_cents'] as int,
      balanceCents: map['balance_cents'] as int,
      salesCount: map['sales_count'] as int,
      expensesCount: map['expenses_count'] as int,
      notes: map['notes'] as String?,
      deleted: (map['deleted'] as int) == 1,
      generatedAt: DateTime.parse(map['generated_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idFinancialStatement != null)
        'id_financial_statement': idFinancialStatement,
      'reference': reference,
      'period_type': periodType.dbValue,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'business_unit_id': businessUnitId,
      'total_sales_cents': totalSalesCents,
      'total_expenses_cents': totalExpensesCents,
      'balance_cents': balanceCents,
      'sales_count': salesCount,
      'expenses_count': expensesCount,
      'notes': notes,
      'deleted': deleted ? 1 : 0,
      'generated_at': generatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      // updated_at is set automatically by trg_financial_statement_updated.
    };
  }

  FinancialStatementModel copyWith({
    int? idFinancialStatement,
    String? reference,
    StatementPeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    int? businessUnitId,
    bool clearBusinessUnitId = false,
    int? totalSalesCents,
    int? totalExpensesCents,
    int? balanceCents,
    int? salesCount,
    int? expensesCount,
    String? notes,
    bool? deleted,
    DateTime? generatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialStatementModel(
      idFinancialStatement: idFinancialStatement ?? this.idFinancialStatement,
      reference: reference ?? this.reference,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      businessUnitId:
          clearBusinessUnitId ? null : (businessUnitId ?? this.businessUnitId),
      totalSalesCents: totalSalesCents ?? this.totalSalesCents,
      totalExpensesCents: totalExpensesCents ?? this.totalExpensesCents,
      balanceCents: balanceCents ?? this.balanceCents,
      salesCount: salesCount ?? this.salesCount,
      expensesCount: expensesCount ?? this.expensesCount,
      notes: notes ?? this.notes,
      deleted: deleted ?? this.deleted,
      generatedAt: generatedAt ?? this.generatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Snapshot row in `financial_statement_sale_item` — one finalized sale
/// as it looked at the moment the statement was generated.
///
/// No businessUnitId here — a statement's items already inherit their
/// scope from the parent `financial_statement` row.
class FinancialStatementSaleItemModel {
  const FinancialStatementSaleItemModel({
    this.idFinancialStatementSaleItem,
    required this.financialStatementId,
    required this.saleId,
    required this.saleReference,
    required this.saleDescription,
    required this.saleDate,
    this.businessCategoryId,
    this.businessCategoryName = '',
    required this.amountCents,
  });

  final int? idFinancialStatementSaleItem;
  final int financialStatementId;
  final int saleId;
  final String saleReference;
  final String saleDescription;
  final DateTime saleDate;
  final int? businessCategoryId;
  final String businessCategoryName;
  final int amountCents;

  factory FinancialStatementSaleItemModel.fromMap(Map<String, Object?> map) {
    return FinancialStatementSaleItemModel(
      idFinancialStatementSaleItem:
          map['id_financial_statement_sale_item'] as int?,
      financialStatementId: map['financial_statement_id'] as int,
      saleId: map['sale_id'] as int,
      saleReference: map['sale_reference'] as String,
      saleDescription: map['sale_description'] as String,
      saleDate: DateTime.parse(map['sale_date'] as String),
      businessCategoryId: map['business_category_id'] as int?,
      businessCategoryName: map['business_category_name'] as String? ?? '',
      amountCents: map['amount_cents'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idFinancialStatementSaleItem != null)
        'id_financial_statement_sale_item': idFinancialStatementSaleItem,
      'financial_statement_id': financialStatementId,
      'sale_id': saleId,
      'sale_reference': saleReference,
      'sale_description': saleDescription,
      'sale_date': saleDate.toIso8601String(),
      'business_category_id': businessCategoryId,
      'business_category_name': businessCategoryName,
      'amount_cents': amountCents,
    };
  }
}

/// Snapshot row in `financial_statement_expense_item` — one expense as it
/// looked at the moment the statement was generated.
///
/// No businessUnitId here — same reasoning as
/// [FinancialStatementSaleItemModel].
class FinancialStatementExpenseItemModel {
  const FinancialStatementExpenseItemModel({
    this.idFinancialStatementExpenseItem,
    required this.financialStatementId,
    required this.expenseId,
    required this.expenseDescription,
    required this.expenseDate,
    this.businessCategoryId,
    this.businessCategoryName = '',
    required this.amountCents,
  });

  final int? idFinancialStatementExpenseItem;
  final int financialStatementId;
  final int expenseId;
  final String expenseDescription;
  final DateTime expenseDate;
  final int? businessCategoryId;
  final String businessCategoryName;
  final int amountCents;

  factory FinancialStatementExpenseItemModel.fromMap(Map<String, Object?> map) {
    return FinancialStatementExpenseItemModel(
      idFinancialStatementExpenseItem:
          map['id_financial_statement_expense_item'] as int?,
      financialStatementId: map['financial_statement_id'] as int,
      expenseId: map['expense_id'] as int,
      expenseDescription: map['expense_description'] as String,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      businessCategoryId: map['business_category_id'] as int?,
      businessCategoryName: map['business_category_name'] as String? ?? '',
      amountCents: map['amount_cents'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idFinancialStatementExpenseItem != null)
        'id_financial_statement_expense_item': idFinancialStatementExpenseItem,
      'financial_statement_id': financialStatementId,
      'expense_id': expenseId,
      'expense_description': expenseDescription,
      'expense_date': expenseDate.toIso8601String(),
      'business_category_id': businessCategoryId,
      'business_category_name': businessCategoryName,
      'amount_cents': amountCents,
    };
  }
}

/// Aggregated per-category breakdown for a single financial statement —
/// how much of that statement's sales and expenses each shared
/// business_category accounts for. See [FinancialStatementDetail.categoryBreakdown].
class CategoryStatementSummary {
  const CategoryStatementSummary({
    required this.businessCategoryId,
    required this.name,
    required this.totalSalesCents,
    required this.totalExpensesCents,
  });

  final int? businessCategoryId;
  final String name;
  final int totalSalesCents;
  final int totalExpensesCents;

  int get balanceCents => totalSalesCents - totalExpensesCents;
}