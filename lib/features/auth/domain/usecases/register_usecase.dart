import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository.dart' as data_repo;
import 'usecase.dart';

class RegisterUsecaseParams extends Equatable {
  final String username;
  final String email;
  final String password;
  final String userType;

  const RegisterUsecaseParams({
    required this.username,
    required this.email,
    required this.password,
    required this.userType,
  });

  @override
  List<Object?> get props => [username, email, password, userType];
}

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(authRepository: ref.read(data_repo.authRepositoryProvider));
});

class RegisterUsecase implements UsecaseWithParms<bool, RegisterUsecaseParams> {
  final IAuthRepository _authRepository;

  RegisterUsecase({required IAuthRepository authRepository}) : _authRepository = authRepository;

  @override
  Future<Either<Failure, bool>> call(RegisterUsecaseParams params) {
    final authEntity = AuthEntity(
      username: params.username,
      email: params.email,
      password: params.password,
      userType: params.userType,
    );
    return _authRepository.register(authEntity);
  }
}
