import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<Either<Failure, bool>> register(AuthEntity entity);
  Future<Either<Failure, AuthEntity>> login(String email, String password);
  Future<Either<Failure, AuthEntity>> signInWithGoogle(String idToken);
  Future<Either<Failure, AuthEntity>> getCurrentUser();
  Future<Either<Failure, bool>> logout();
  Future<Either<Failure, AuthEntity>> updateUser(AuthEntity entity, {String? filePath});
  Future<Either<Failure, String>> changePassword({required String currentPassword, required String newPassword});
  Future<Either<Failure, String>> requestPasswordReset(String email);
  Future<Either<Failure, String>> verifyOtp({required String email, required String otp});
  Future<Either<Failure, String>> resetPassword({required String token, required String newPassword});
}
