import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/usecases/usecase.dart';
import '../../data/repositories/wardrobe_repository.dart' as data_repo;
import '../repositories/wardrobe_repository.dart';

final deleteItemUsecaseProvider = Provider<DeleteItemUsecase>((ref) {
  return DeleteItemUsecase(ref.read(data_repo.wardrobeRepositoryProvider));
});

class DeleteItemUsecase implements UsecaseWithParms<Unit, String> {
  final IWardrobeRepository _repository;
  DeleteItemUsecase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String itemId) =>
      _repository.deleteItem(itemId);
}
