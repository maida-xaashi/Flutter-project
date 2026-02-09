enum UserRole { user, admin }

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String hashedPassword;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.hashedPassword,
    required this.createdAt,
  });
}
