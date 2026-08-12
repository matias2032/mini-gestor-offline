class CustomerModel {
  final int idCustomer;
  final String name;
  final String? lastName;
  final String? phone;
  final String? notes;
  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    required this.idCustomer,
    required this.name,
    this.lastName,
    this.phone,
    this.notes,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      idCustomer: map['id_customer'] as int,
      name: map['name'] as String,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
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
    bool? deleted,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      idCustomer: idCustomer,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}