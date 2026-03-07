import 'package:supabase_flutter/supabase_flutter.dart' show User;

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // 'student' or 'teacher'
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.password = '',
    required this.role,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Build an [AppUser] from a Supabase [User] object.
  factory AppUser.fromSupabaseUser(User user) {
    return AppUser(
      id: user.id,
      name: (user.userMetadata?['name'] as String?) ?? user.email ?? '',
      email: user.email ?? '',
      password: '', // never stored locally
      role: (user.userMetadata?['role'] as String?) ?? 'student',
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'] ?? '',
      role: json['role'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  AppUser copyWith({String? name, String? email, String? password}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role,
      createdAt: createdAt,
    );
  }
}
