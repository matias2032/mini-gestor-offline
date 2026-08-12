/// Pure data class representing a row in the `supplier` table.
///
/// No business logic here — validations and rules live in
/// SupplierRepository.
class SupplierModel {
  const SupplierModel({
    this.idSupplier,
    required this.name,
    this.phone,
    this.address,
    this.deleted = false,
    required this.createdAt,
  });

  final int? idSupplier;
  final String name;
  final String? phone;
  final String? address;
  final bool deleted;
  final DateTime createdAt;

  factory SupplierModel.fromMap(Map<String, Object?> map) {
    return SupplierModel(
      idSupplier: map['id_supplier'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
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
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SupplierModel copyWith({
    int? idSupplier,
    String? name,
    String? phone,
    String? address,
    bool? deleted,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      idSupplier: idSupplier ?? this.idSupplier,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}