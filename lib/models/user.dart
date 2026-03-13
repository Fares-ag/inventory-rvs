enum UserRole {
  admin,
  staff,
  viewer,
}

class User {
  final String? id; // Changed to String for Firestore compatibility
  final String username;
  final String email;
  final String passwordHash; // In production, use proper hashing
  final UserRole role;
  final String? fullName;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.fullName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'role': role.name,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(), // Handle both int and String IDs
      username: map['username'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.viewer,
      ),
      fullName: map['full_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get canEdit => role == UserRole.admin || role == UserRole.staff;
  bool get canViewReports => true; // All roles can view reports
  bool get canManageUsers => role == UserRole.admin;
}

