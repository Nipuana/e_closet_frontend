import '../../domain/entities/auth_entity.dart';

/// API model for the auth user.
///
/// Hand-mapped (no json_serializable) so it tolerates the backend's actual
/// response shape: Mongo's `_id` instead of `id`, camelCase `profilePicture`,
/// and an absent `user_type` (the backend has no such field). Defaulting these
/// avoids `type 'Null' is not a subtype of type 'String'` cast crashes.
class AuthApiModel {
  final String? id;
  final String username;
  final String email;
  final String userType;
  final String? profilePicture;
  final String? token;

  // Outbound-only credentials (never present in API responses).
  final String? password;
  final String? confirmPassword;

  AuthApiModel({
    this.id,
    required this.username,
    required this.email,
    this.userType = 'user',
    this.profilePicture,
    this.token,
    this.password,
    this.confirmPassword,
  });

  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: (json['id'] ?? json['_id'])?.toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      userType: (json['user_type'] ?? json['userType'] ?? 'user').toString(),
      profilePicture: (json['profile_picture'] ?? json['profilePicture'])?.toString(),
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'user_type': userType,
        'profile_picture': profilePicture,
        'token': token,
      };

  AuthEntity toEntity() {
    return AuthEntity(
      userId: id,
      username: username,
      email: email,
      userType: userType,
      profilePicture: profilePicture,
      token: token,
    );
  }

  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      id: entity.userId,
      username: entity.username,
      email: entity.email,
      userType: entity.userType,
      profilePicture: entity.profilePicture,
      token: entity.token,
      password: entity.password,
      confirmPassword: entity.confirmPassword,
    );
  }
}
