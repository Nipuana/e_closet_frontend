import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';
import '../../data/repositories/auth_repository.dart' as data_repo;
import 'usecase.dart';

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  return LogoutUsecase(authRepository: ref.read(data_repo.authRepositoryProvider));
});

class LogoutUsecase implements UsecaseWithoutParams<bool> {
  final IAuthRepository _authRepository;

  LogoutUsecase({required IAuthRepository authRepository}) : _authRepository = authRepository;

  @override
  Future<Either<Failure, bool>> call() {
    return _authRepository.logout();
  }
}
