/// Pure data class representing a row in the `sale_category` table.
///
/// Note: unlike `expense_category`, this table has `created_at` and
/// `updated_at` columns — but no update trigger, so `updated_at` must be
/// set manually by the repository on every update (same pattern as
/// `customer`).
class SaleCategoryModel {
  const SaleCategoryModel({
    this.idSaleCategory,
    required this.name,
    this.description,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  final int? idSaleCategory;
  final String name;
  final String? description;
  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory SaleCategoryModel.fromMap(Map<String, Object?> map) {
    return SaleCategoryModel(
      idSaleCategory: map['id_sale_category'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      deleted: (map['deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idSaleCategory != null) 'id_sale_category': idSaleCategory,
      'name': name,
      'description': description,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SaleCategoryModel copyWith({
    int? idSaleCategory,
    String? name,
    String? description,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleCategoryModel(
      idSaleCategory: idSaleCategory ?? this.idSaleCategory,
      name: name ?? this.name,
      description: description ?? this.description,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}