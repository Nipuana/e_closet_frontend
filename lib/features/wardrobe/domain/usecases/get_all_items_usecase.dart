import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/usecases/usecase.dart';
import '../../data/repositories/wardrobe_repository.dart' as data_repo;
import '../entities/wardrobe_item_entity.dart';
import '../repositories/wardrobe_repository.dart';

final getAllItemsUsecaseProvider = Provider<GetAllItemsUsecase>((ref) {
  return GetAllItemsUsecase(
    wardrobeRepository: ref.read(data_repo.wardrobeRepositoryProvider),
  );
});

class GetAllItemsUsecase
    implements UsecaseWithoutParams<List<WardrobeItemEntity>> {
  final IWardrobeRepository _wardrobeRepository;

  GetAllItemsUsecase({required IWardrobeRepository wardrobeRepository})
      : _wardrobeRepository = wardrobeRepository;

  @override
  Future<Either<Failure, List<WardrobeItemEntity>>> call() {
    return _wardrobeRepository.getAllItems();
  }
}
