/// Pure data class representing a row in the `supplier` table.
///
/// No business logic here — validations and rules live in
/// SupplierRepository.
///
/// `businessUnitId` is hybrid scope: `null` means the supplier is Global
/// (visible to every loja); a value means it belongs exclusively to that
/// business unit.
class SupplierModel {
  const SupplierModel({
    this.idSupplier,
    required this.name,
    this.phone,
    this.address,
    this.businessUnitId,
    this.deleted = false,
    required this.createdAt,
  });

  final int? idSupplier;
  final String name;
  final String? phone;
  final String? address;
  final int? businessUnitId;
  final bool deleted;
  final DateTime createdAt;

  bool get isGlobal => businessUnitId == null;

  factory SupplierModel.fromMap(Map<String, Object?> map) {
    return SupplierModel(
      idSupplier: map['id_supplier'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      businessUnitId: map['business_unit_id'] as int?,
      deleted: (map['deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idSupplier != null) 'id_supplier': idSupplier,
      'name': name,
      'phone': phone,
      'address': address,
      'business_unit_id': businessUnitId,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SupplierModel copyWith({
    int? idSupplier,
    String? name,
    String? phone,
    String? address,
    int? businessUnitId,
    bool clearBusinessUnitId = false,
    bool? deleted,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      idSupplier: idSupplier ?? this.idSupplier,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      businessUnitId:
          clearBusinessUnitId ? null : (businessUnitId ?? this.businessUnitId),
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}