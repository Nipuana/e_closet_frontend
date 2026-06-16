import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      return Left(NoInternetFailure(message: 'No internet connection'));
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
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      // Fallback to local database
      try {
        final hiveModel = await _authLocalDatasource.login(email, password);
        if (hiveModel != null) {
          return Right(hiveModel.toEntity());
        }
        return Left(LocalDatabaseFailure(message: 'Invalid credentials'));
      } catch (e) {
        return Left(LocalDatabaseFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> signInWithGoogle(String idToken) async {
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }

    try {
      final apiModel = await _authRemoteDatasource.signInWithGoogle(idToken);
      return Right(apiModel.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try {
      final apiModel = await _authRemoteDatasource.getCurrentUser();
      if (apiModel != null) {
        return Right(apiModel.toEntity());
      }
      return Left(UnauthorizedFailure(message: 'User not found'));
    } catch (e) {
      // Fallback to local
      try {
        final hiveModel = await _authLocalDatasource.getCurrentUser();
        if (hiveModel != null) {
          return Right(hiveModel.toEntity());
        }
        return Left(LocalDatabaseFailure(message: 'User not found'));
      } catch (ex) {
        return Left(LocalDatabaseFailure(message: ex.toString()));
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
      return Left(LocalDatabaseFailure(message: 'Logout failed'));
    } catch (e) {
      // Even if remote fails, try local
      try {
        await _authLocalDatasource.logout();
        return const Right(true);
      } catch (ex) {
        return Left(LocalDatabaseFailure(message: ex.toString()));
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
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      return Left(NoInternetFailure(message: 'No internet connection'));
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
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      return Left(NoInternetFailure(message: 'No internet connection'));
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
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      return Left(NoInternetFailure(message: 'No internet connection'));
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
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      return Left(NoInternetFailure(message: 'No internet connection'));
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
        return Left(ApiFailure(message: e.toString()));
      }
    } else {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }
  }
}
