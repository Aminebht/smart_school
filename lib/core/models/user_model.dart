class UserModel {
  final dynamic id;
  final String email;
  final String name;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'email': email,
      'name': name,
      'role': role,
    };
  }

  bool isAdmin() {
    return role == 'admin';
  }

  bool isTeacher() {
    return role == 'teacher';
  }
} 