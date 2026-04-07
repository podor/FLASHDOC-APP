// lib/core/models/user_model.dart

class UserModel {
  final String id;
  final String phone;
  final String? email;
  final String role;
  final String status;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.phone,
    this.email,
    required this.role,
    required this.status,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty  ? lastName[0]  : '';
    return '$f$l'.toUpperCase();
  }

  // ✅ copyWith pour mettre à jour localement sans relancer un login
  UserModel copyWith({
    String? id,
    String? phone,
    String? email,
    String? role,
    String? status,
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) {
    return UserModel(
      id:        id        ?? this.id,
      phone:     phone     ?? this.phone,
      email:     email     ?? this.email,
      role:      role      ?? this.role,
      status:    status    ?? this.status,
      firstName: firstName ?? this.firstName,
      lastName:  lastName  ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id']        as String? ?? '',
      phone:     json['phone']     as String? ?? '',
      email:     json['email']     as String?,
      role:      json['role']      as String? ?? 'PATIENT',
      status:    json['status']    as String? ?? 'ACTIVE',
      firstName: json['firstName'] as String? ?? '',
      lastName:  json['lastName']  as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'phone':     phone,
    'email':     email,
    'role':      role,
    'status':    status,
    'firstName': firstName,
    'lastName':  lastName,
    'avatarUrl': avatarUrl,
  };
}
