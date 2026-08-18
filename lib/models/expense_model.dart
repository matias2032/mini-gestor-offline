// expense_model.dart

// ============================================================
// expense
// ============================================================

/// Pure data class representing a row in the `expense` table.
///
/// `businessUnitId` is strict scope (matches `expense.business_unit_id
/// NOT NULL` in the schema): every expense belongs to exactly one loja.
class ExpenseModel {
  const ExpenseModel({
    this.idExpense,
    this.supplierId,
    required this.description,
    required this.amountCents,
    required this.expenseDate,
    this.deletionReason,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
    required this.businessUnitId,
  });

  final int? idExpense;
  final int? supplierId;
  final String description;
  final int amountCents;
  final DateTime expenseDate;
  final String? deletionReason;
  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// The business unit (loja/departamento) this expense was posted to.
  /// Strict scope — always required, never Global.
  final int businessUnitId;

  factory ExpenseModel.fromMap(Map<String, Object?> map) {
    return ExpenseModel(
      idExpense: map['id_expense'] as int?,
      supplierId: map['supplier_id'] as int?,
      description: map['description'] as String,
      amountCents: map['amount_cents'] as int,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      deletionReason: map['deletion_reason'] as String?,
      deleted: (map['deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      businessUnitId: map['business_unit_id'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idExpense != null) 'id_expense': idExpense,
      'supplier_id': supplierId,
      'description': description,
      'amount_cents': amountCents,
      'expense_date': expenseDate.toIso8601String(),
      'deletion_reason': deletionReason,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      // updated_at is intentionally omitted — the trg_expense_updated
      // trigger sets it automatically on UPDATE.
      'business_unit_id': businessUnitId,
    };
  }

  ExpenseModel copyWith({
    int? idExpense,
    int? supplierId,
    String? description,
    int? amountCents,
    DateTime? expenseDate,
    String? deletionReason,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? businessUnitId,
  }) {
    return ExpenseModel(
      idExpense: idExpense ?? this.idExpense,
      supplierId: supplierId ?? this.supplierId,
      description: description ?? this.description,
      amountCents: amountCents ?? this.amountCents,
      expenseDate: expenseDate ?? this.expenseDate,
      deletionReason: deletionReason ?? this.deletionReason,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessUnitId: businessUnitId ?? this.businessUnitId,
    );
  }
}

// ============================================================
// expense_category_split
// ============================================================

/// Pure data class representing a row in the `expense_category_split`
/// table — one category's slice of a shared expense.
///
/// No businessUnitId here on purpose: the split inherits its unit from the
/// parent `expense` row, there is no independent scope to track.
class ExpenseCategorySplitModel {
  const ExpenseCategorySplitModel({
    this.idExpenseCategorySplit,
    required this.expenseId,
    required this.businessCategoryId,
    required this.amountCents,
  });

  final int? idExpenseCategorySplit;
  final int expenseId;
  final int businessCategoryId;
  final int amountCents;

  factory ExpenseCategorySplitModel.fromMap(Map<String, Object?> map) {
    return ExpenseCategorySplitModel(
      idExpenseCategorySplit: map['id_expense_category_split'] as int?,
      expenseId: map['expense_id'] as int,
      businessCategoryId: map['business_category_id'] as int,
      amountCents: map['amount_cents'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idExpenseCategorySplit != null)
        'id_expense_category_split': idExpenseCategorySplit,
      'expense_id': expenseId,
      'business_category_id': businessCategoryId,
      'amount_cents': amountCents,
    };
  }
}