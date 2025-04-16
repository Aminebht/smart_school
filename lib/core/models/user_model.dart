class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatar_url': avatarUrl,
      'is_active': isActive,
    };
  }

  bool isAdmin() {
    return role == 'admin';
  }

  bool isTeacher() {
    return role == 'teacher';
  }
} 