/// Pure data class representing a row in the `customer` table.
///
/// `businessUnitId` is hybrid scope: `null` means the customer is Global
/// (visible to every loja); a value means it belongs exclusively to that
/// business unit.
class CustomerModel {
  final int idCustomer;
  final String name;
  final String? lastName;
  final String? phone;
  final String? notes;
  final int? businessUnitId;
  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    required this.idCustomer,
    required this.name,
    this.lastName,
    this.phone,
    this.notes,
    this.businessUnitId,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isGlobal => businessUnitId == null;

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      idCustomer: map['id_customer'] as int,
      name: map['name'] as String,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      businessUnitId: map['business_unit_id'] as int?,
      deleted: (map['deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_customer': idCustomer,
      'name': name,
      'last_name': lastName,
      'phone': phone,
      'notes': notes,
      'business_unit_id': businessUnitId,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CustomerModel copyWith({
    String? name,
    String? lastName,
    String? phone,
    String? notes,
    int? businessUnitId,
    bool clearBusinessUnitId = false,
    bool? deleted,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      idCustomer: idCustomer,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      businessUnitId:
          clearBusinessUnitId ? null : (businessUnitId ?? this.businessUnitId),
      deleted: deleted ?? this.deleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}