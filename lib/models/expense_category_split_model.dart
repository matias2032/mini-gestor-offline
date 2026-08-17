/// Pure data class representing a row in the `expense_category_split`
/// table — one category's slice of a shared expense.
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