/// Pure data class representing a row in the `expense_category` table.
class ExpenseCategoryModel {
  const ExpenseCategoryModel({
    this.idExpenseCategory,
    required this.name,
    this.description,
    this.deleted = false,
  });

  final int? idExpenseCategory;
  final String name;
  final String? description;
  final bool deleted;

  factory ExpenseCategoryModel.fromMap(Map<String, Object?> map) {
    return ExpenseCategoryModel(
      idExpenseCategory: map['id_expense_category'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      deleted: (map['deleted'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idExpenseCategory != null) 'id_expense_category': idExpenseCategory,
      'name': name,
      'description': description,
      'deleted': deleted ? 1 : 0,
    };
  }

  ExpenseCategoryModel copyWith({
    int? idExpenseCategory,
    String? name,
    String? description,
    bool? deleted,
  }) {
    return ExpenseCategoryModel(
      idExpenseCategory: idExpenseCategory ?? this.idExpenseCategory,
      name: name ?? this.name,
      description: description ?? this.description,
      deleted: deleted ?? this.deleted,
    );
  }
}