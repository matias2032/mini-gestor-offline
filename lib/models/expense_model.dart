/// Pure data class representing a row in the `expense` table.
class ExpenseModel {
  const ExpenseModel({
    this.idExpense,
    required this.expenseCategoryId,
    this.supplierId,
    required this.description,
    required this.amountCents,
    required this.expenseDate,
    this.deletionReason,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  final int? idExpense;
  final int expenseCategoryId;
  final int? supplierId;
  final String description;
  final int amountCents;
  final DateTime expenseDate;
  final String? deletionReason;
  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ExpenseModel.fromMap(Map<String, Object?> map) {
    return ExpenseModel(
      idExpense: map['id_expense'] as int?,
      expenseCategoryId: map['expense_category_id'] as int,
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
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idExpense != null) 'id_expense': idExpense,
      'expense_category_id': expenseCategoryId,
      'supplier_id': supplierId,
      'description': description,
      'amount_cents': amountCents,
      'expense_date': expenseDate.toIso8601String(),
      'deletion_reason': deletionReason,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      // updated_at is intentionally omitted — the trg_expense_updated
      // trigger sets it automatically on UPDATE.
    };
  }

  ExpenseModel copyWith({
    int? idExpense,
    int? expenseCategoryId,
    int? supplierId,
    String? description,
    int? amountCents,
    DateTime? expenseDate,
    String? deletionReason,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      idExpense: idExpense ?? this.idExpense,
      expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
      supplierId: supplierId ?? this.supplierId,
      description: description ?? this.description,
      amountCents: amountCents ?? this.amountCents,
      expenseDate: expenseDate ?? this.expenseDate,
      deletionReason: deletionReason ?? this.deletionReason,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}