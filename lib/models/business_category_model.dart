// business_category_model.dart
/// Pure data class representing a row in the `business_category` table.
/// Shared by both sales and expenses — this is the single "ramo de
/// negócio" concept used to classify both what comes in and what goes out.
///
/// `businessUnitId` is hybrid scope: `null` means the category is Global
/// (visible to every loja); a value means it belongs exclusively to that
/// business unit.
class BusinessCategoryModel {
  const BusinessCategoryModel({
    this.idBusinessCategory,
    required this.name,
    this.description,
    this.businessUnitId,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  final int? idBusinessCategory;
  final String name;
  final String? description;
  final int? businessUnitId;
  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isGlobal => businessUnitId == null;

  factory BusinessCategoryModel.fromMap(Map<String, Object?> map) {
    return BusinessCategoryModel(
      idBusinessCategory: map['id_business_category'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      businessUnitId: map['business_unit_id'] as int?,
      deleted: (map['deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idBusinessCategory != null) 'id_business_category': idBusinessCategory,
      'name': name,
      'description': description,
      'business_unit_id': businessUnitId,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      // updated_at is set automatically by trg_business_category_updated.
    };
  }

  BusinessCategoryModel copyWith({
    int? idBusinessCategory,
    String? name,
    String? description,
    int? businessUnitId,
    bool clearBusinessUnitId = false,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessCategoryModel(
      idBusinessCategory: idBusinessCategory ?? this.idBusinessCategory,
      name: name ?? this.name,
      description: description ?? this.description,
      businessUnitId:
          clearBusinessUnitId ? null : (businessUnitId ?? this.businessUnitId),
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}