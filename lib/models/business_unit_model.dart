/// Represents a single business unit (loja/departamento) belonging to the
/// holding/matriz represented by `UserModel`.
///
/// A business unit is:
///  - The mandatory scope for [SaleModel] and [ExpenseModel] — every sale
///    and expense belongs to exactly one unit.
///  - The optional scope for `CustomerModel`, `SupplierModel` and
///    `BusinessCategoryModel` — `businessUnitId == null` means the record is
///    Global (shared across every unit); otherwise it belongs exclusively
///    to that unit.
///  - The optional scope for `FinancialStatementModel` — `null` means a
///    consolidated statement for the whole group/matriz.
class BusinessUnitModel {
  final int? idBusinessUnit;
  final String name;

  /// Marks the unit created automatically during onboarding. Exactly one
  /// active unit should have `isDefault == true` at any given time; this is
  /// enforced by BusinessUnitRepository, not by the database.
  final bool isDefault;

  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BusinessUnitModel({
    this.idBusinessUnit,
    required this.name,
    this.isDefault = false,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory BusinessUnitModel.fromMap(Map<String, dynamic> map) {
    return BusinessUnitModel(
      idBusinessUnit: map['id_business_unit'] as int?,
      name: map['name'] as String,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      deleted: (map['deleted'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Row used to INSERT a brand-new unit. `id_business_unit`, `created_at`
  /// and `updated_at` are left for SQLite/the trigger to fill in.
  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Row used to UPDATE an existing unit.
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'deleted': deleted ? 1 : 0,
    };
  }

  BusinessUnitModel copyWith({
    int? idBusinessUnit,
    String? name,
    bool? isDefault,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessUnitModel(
      idBusinessUnit: idBusinessUnit ?? this.idBusinessUnit,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessUnitModel &&
          other.idBusinessUnit == idBusinessUnit &&
          other.idBusinessUnit != null);

  @override
  int get hashCode => idBusinessUnit?.hashCode ?? identityHashCode(this);

  @override
  String toString() =>
      'BusinessUnitModel(id: $idBusinessUnit, name: $name, isDefault: $isDefault)';
}