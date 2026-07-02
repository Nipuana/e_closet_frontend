import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/usecases/usecase.dart';
import '../../data/repositories/wardrobe_repository.dart' as data_repo;
import '../entities/wardrobe_item_entity.dart';
import '../repositories/wardrobe_repository.dart';

final markWornUsecaseProvider = Provider<MarkWornUsecase>((ref) {
  return MarkWornUsecase(ref.read(data_repo.wardrobeRepositoryProvider));
});

class MarkWornUsecase implements UsecaseWithParms<WardrobeItemEntity, String> {
  final IWardrobeRepository _repository;
  MarkWornUsecase(this._repository);

  @override
  Future<Either<Failure, WardrobeItemEntity>> call(String itemId) =>
      _repository.markWorn(itemId);
}
