import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/usecases/usecase.dart';
import '../../data/repositories/wardrobe_repository.dart' as data_repo;
import '../entities/wardrobe_item_entity.dart';
import '../repositories/wardrobe_repository.dart';

class GetFavoriteItemsParams extends Equatable {
  final int? limit;

  const GetFavoriteItemsParams({this.limit});

  @override
  List<Object?> get props => [limit];
}

final getFavoriteItemsUsecaseProvider = Provider<GetFavoriteItemsUsecase>((ref) {
  return GetFavoriteItemsUsecase(
    wardrobeRepository: ref.read(data_repo.wardrobeRepositoryProvider),
  );
});

class GetFavoriteItemsUsecase
    implements UsecaseWithParms<List<WardrobeItemEntity>, GetFavoriteItemsParams> {
  final IWardrobeRepository _wardrobeRepository;

  GetFavoriteItemsUsecase({required IWardrobeRepository wardrobeRepository})
      : _wardrobeRepository = wardrobeRepository;

  @override
  Future<Either<Failure, List<WardrobeItemEntity>>> call(GetFavoriteItemsParams params) {
    return _wardrobeRepository.getFavoriteItems(limit: params.limit);
  }
}
