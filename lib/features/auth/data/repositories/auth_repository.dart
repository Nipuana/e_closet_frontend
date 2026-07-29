import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/network_info.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_api_model.dart';
import '../models/auth_hive_model.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authLocalDatasource = ref.read(authLocalDatasourceProvider);
  final authRemoteDatasource = ref.read(authRemoteDataSourceProvider);
  final networkInfo = ref.read(networkInfoProvider);

  return AuthRepository(
    authLocalDatasource: authLocalDatasource,
    authRemoteDatasource: authRemoteDatasource,
    networkInfo: networkInfo,
  );
});

/// Deliberately vague: a sign-in failure never says which of the two fields was
/// wrong, and never carries the server's wording.
const String _badCredentials = 'Incorrect email or password. Please try again.';

class AuthRepository implements IAuthRepository {
  final IAuthLocalDatasource _authLocalDatasource;
  final IAuthRemoteDatasource _authRemoteDatasource;
  final NetworkInfo _networkInfo;

  AuthRepository({
    required IAuthLocalDatasource authLocalDatasource,
    required IAuthRemoteDatasource authRemoteDatasource,
    required NetworkInfo networkInfo,
  })  : _authLocalDatasource = authLocalDatasource,
        _authRemoteDatasource = authRemoteDatasource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, bool>> register(AuthEntity entity) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final apiModel = AuthApiModel.fromEntity(entity);
        await _authRemoteDatasource.register(apiModel);

        // Also save locally
        final hiveModel = AuthHiveModel.fromEntity(entity);
        await _authLocalDatasource.register(hiveModel, entity.password ?? '');

        return const Right(true);
      } catch (e) {
        return Left(ApiFailure(
          message: userFacingError(e,
              fallback: 'Could not create your account. Please try again.'),
        ));
      }
    } else {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login(String email, String password) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final apiModel = await _authRemoteDatasource.login(email, password);
        return Right(apiModel.toEntity());
      } catch (e) {
        return Left(ApiFailure(message: userFacingError(e, fallback: _badCredentials)));
      }
    } else {
      // Fallback to local database
      try {
        final hiveModel = await _authLocalDatasource.login(email, password);
        if (hiveModel != null) {
          return Right(hiveModel.toEntity());
        }
        return Left(LocalDatabaseFailure(message: _badCredentials));
      } catch (e) {
        return Left(LocalDatabaseFailure(
            message: userFacingError(e, fallback: _badCredentials)));
      }
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> signInWithGoogle(String idToken) async {
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }

    try {
      final apiModel = await _authRemoteDatasource.signInWithGoogle(idToken);
      return Right(apiModel.toEntity());
    } catch (e) {
      return Left(ApiFailure(
        message: userFacingError(e, fallback: 'Google sign-in failed. Please try again.'),
      ));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try {
      final apiModel = await _authRemoteDatasource.getCurrentUser();
      if (apiModel != null) {
        return Right(apiModel.toEntity());
      }
      return Left(UnauthorizedFailure(message: kSessionExpiredFailure));
    } catch (e) {
      // Fallback to local
      try {
        final hiveModel = await _authLocalDatasource.getCurrentUser();
        if (hiveModel != null) {
          return Right(hiveModel.toEntity());
        }
        return Left(LocalDatabaseFailure(message: kSessionExpiredFailure));
      } catch (ex) {
        return Left(LocalDatabaseFailure(message: userFacingError(ex)));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final remoteResult = await _authRemoteDatasource.logout();
      final localResult = await _authLocalDatasource.logout();

      if (remoteResult || localResult) {
        return const Right(true);
      }
      return Left(LocalDatabaseFailure(message: 'Could not sign you out. Please try again.'));
    } catch (e) {
      // Even if remote fails, try local
      try {
        await _authLocalDatasource.logout();
        return const Right(true);
      } catch (ex) {
        return Left(LocalDatabaseFailure(
            message: userFacingError(ex, fallback: 'Could not sign you out. Please try again.')));
      }
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> updateUser(AuthEntity entity, {String? filePath}) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final apiModel = AuthApiModel.fromEntity(entity);
        final updatedModel = await _authRemoteDatasource.updateUser(apiModel, filePath: filePath);
        return Right(updatedModel.toEntity());
      } catch (e) {
        return Left(ApiFailure(
          message: userFacingError(e,
              fallback: 'Could not save your profile. Please try again.'),
        ));
      }
    } else {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
  }

  @override
  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final message = await _authRemoteDatasource.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        return Right(message);
      } catch (e) {
        return Left(ApiFailure(
          message: userFacingError(e,
              fallback: 'Could not change your password. Check your current '
                  'password and try again.'),
        ));
      }
    } else {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
  }

  @override
  Future<Either<Failure, String>> requestPasswordReset(String email) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final message = await _authRemoteDatasource.requestPasswordReset(email);
        return Right(message);
      } catch (e) {
        return Left(ApiFailure(
          message: userFacingError(e,
              fallback: 'Could not send a verification code. Please try again.'),
        ));
      }
    } else {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
  }

  @override
  Future<Either<Failure, String>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final token = await _authRemoteDatasource.verifyOtp(email: email, otp: otp);
        return Right(token);
      } catch (e) {
        return Left(ApiFailure(
          message: userFacingError(e,
              fallback: 'That code is incorrect or has expired. Please try again.'),
        ));
      }
    } else {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final message = await _authRemoteDatasource.resetPassword(
          token: token,
          newPassword: newPassword,
        );
        return Right(message);
      } catch (e) {
        return Left(ApiFailure(
          message: userFacingError(e,
              fallback: 'Could not reset your password. Please try again.'),
        ));
      }
    } else {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
  }
}
