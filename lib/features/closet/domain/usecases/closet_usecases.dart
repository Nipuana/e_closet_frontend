import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/closet_repository.dart';
import '../entities/wardrobe_layout_entity.dart';
import '../repositories/closet_repository.dart';

final listWardrobeLayoutsUsecaseProvider = Provider<ListWardrobeLayoutsUsecase>(
    (ref) => ListWardrobeLayoutsUsecase(ref.read(closetRepositoryProvider)));
final saveWardrobeLayoutUsecaseProvider = Provider<SaveWardrobeLayoutUsecase>(
    (ref) => SaveWardrobeLayoutUsecase(ref.read(closetRepositoryProvider)));
final deleteWardrobeLayoutUsecaseProvider = Provider<DeleteWardrobeLayoutUsecase>(
    (ref) => DeleteWardrobeLayoutUsecase(ref.read(closetRepositoryProvider)));

class ListWardrobeLayoutsUsecase {
  final IClosetRepository _repo;
  ListWardrobeLayoutsUsecase(this._repo);
  Future<Either<Failure, List<WardrobeLayoutEntity>>> call() => _repo.listLayouts();
}

class SaveWardrobeLayoutUsecase {
  final IClosetRepository _repo;
  SaveWardrobeLayoutUsecase(this._repo);
  Future<Either<Failure, WardrobeLayoutEntity>> call(WardrobeLayoutEntity layout) =>
      _repo.saveLayout(layout);
}

class DeleteWardrobeLayoutUsecase {
  final IClosetRepository _repo;
  DeleteWardrobeLayoutUsecase(this._repo);
  Future<Either<Failure, Unit>> call(String layoutId) => _repo.deleteLayout(layoutId);
}
