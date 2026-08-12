class UserModel {
  final int idUser;
  final String name;
  final String? lastName;
  final String? phone;
  final String? email;
  final String passwordHash;
  final String? businessName;
  final String currency;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.idUser,
    required this.name,
    this.lastName,
    this.phone,
    this.email,
    required this.passwordHash,
    this.businessName,
    this.currency = 'MZN',
    this.onboardingCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      idUser: map['id_user'] as int,
      name: map['name'] as String,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      passwordHash: map['password_hash'] as String,
      businessName: map['business_name'] as String?,
      currency: map['currency'] as String,
      onboardingCompleted: (map['onboarding_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'name': name,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'password_hash': passwordHash,
      'business_name': businessName,
      'currency': currency,
      'onboarding_completed': onboardingCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? lastName,
    String? phone,
    String? email,
    String? passwordHash,
    String? businessName,
    String? currency,
    bool? onboardingCompleted,
    DateTime? updatedAt,
  }) {
    return UserModel(
      idUser: idUser,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      businessName: businessName ?? this.businessName,
      currency: currency ?? this.currency,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}