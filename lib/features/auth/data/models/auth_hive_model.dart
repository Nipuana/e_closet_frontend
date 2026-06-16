import 'package:hive/hive.dart';
import '../../../../core/constants/hive_table_constant.dart';
import '../../domain/entities/auth_entity.dart';

part 'auth_hive_model.g.dart';

@HiveType(typeId: HiveTableConstant.authTypeId)
class AuthHiveModel extends HiveObject {
  @HiveField(0)
  final String? userId;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String userType;

  @HiveField(4)
  final String? password;

  @HiveField(5)
  final String? profilePicture;

  @HiveField(6)
  final String? token;

  AuthHiveModel({
    this.userId,
    required this.username,
    required this.email,
    required this.userType,
    this.password,
    this.profilePicture,
    this.token,
  });

  AuthEntity toEntity() {
    return AuthEntity(
      userId: userId,
      username: username,
      email: email,
      userType: userType,
      password: password,
      profilePicture: profilePicture,
      token: token,
    );
  }

  factory AuthHiveModel.fromEntity(AuthEntity entity) {
    return AuthHiveModel(
      userId: entity.userId,
      username: entity.username,
      email: entity.email,
      userType: entity.userType,
      password: entity.password,
      profilePicture: entity.profilePicture,
      token: entity.token,
    );
  }
}
