class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? specialty;
  final String? licenseNumber;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.specialty,
    this.licenseNumber,
    required this.isActive,
    required this.createdAt,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isDoctor => role.toUpperCase() == 'OPHTHALMOLOGIST' || isAdmin;
  bool get isTechnician => role.toUpperCase() == 'TECHNICIAN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      specialty: json['specialty'] as String?,
      licenseNumber: json['license_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'specialty': specialty,
      'license_number': licenseNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
