import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/usecases/usecase.dart';
import '../../data/repositories/wardrobe_repository.dart' as data_repo;
import '../entities/wardrobe_item_entity.dart';
import '../repositories/wardrobe_repository.dart';

class GetRecentItemsParams extends Equatable {
  final int limit;

  const GetRecentItemsParams({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

final getRecentItemsUsecaseProvider = Provider<GetRecentItemsUsecase>((ref) {
  return GetRecentItemsUsecase(
    wardrobeRepository: ref.read(data_repo.wardrobeRepositoryProvider),
  );
});

class GetRecentItemsUsecase
    implements UsecaseWithParms<List<WardrobeItemEntity>, GetRecentItemsParams> {
  final IWardrobeRepository _wardrobeRepository;

  GetRecentItemsUsecase({required IWardrobeRepository wardrobeRepository})
      : _wardrobeRepository = wardrobeRepository;

  @override
  Future<Either<Failure, List<WardrobeItemEntity>>> call(GetRecentItemsParams params) {
    return _wardrobeRepository.getRecentItems(limit: params.limit);
  }
}
