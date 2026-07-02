import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/usecases/usecase.dart';
import '../../data/repositories/wardrobe_repository.dart' as data_repo;
import '../entities/wardrobe_item_entity.dart';
import '../repositories/wardrobe_repository.dart';

class ToggleFavoriteParams extends Equatable {
  final String itemId;
  final bool isFavorite;

  const ToggleFavoriteParams({required this.itemId, required this.isFavorite});

  @override
  List<Object?> get props => [itemId, isFavorite];
}

final toggleFavoriteUsecaseProvider = Provider<ToggleFavoriteUsecase>((ref) {
  return ToggleFavoriteUsecase(
    wardrobeRepository: ref.read(data_repo.wardrobeRepositoryProvider),
  );
});

class ToggleFavoriteUsecase
    implements UsecaseWithParms<WardrobeItemEntity, ToggleFavoriteParams> {
  final IWardrobeRepository _wardrobeRepository;

  ToggleFavoriteUsecase({required IWardrobeRepository wardrobeRepository})
      : _wardrobeRepository = wardrobeRepository;

  @override
  Future<Either<Failure, WardrobeItemEntity>> call(ToggleFavoriteParams params) {
    return _wardrobeRepository.toggleFavorite(
      itemId: params.itemId,
      isFavorite: params.isFavorite,
    );
  }
}
