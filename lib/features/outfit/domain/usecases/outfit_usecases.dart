import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/outfit_repository.dart';
import '../entities/outfit_entity.dart';
import '../repositories/outfit_repository.dart';

final listOutfitsUsecaseProvider = Provider<ListOutfitsUsecase>(
    (ref) => ListOutfitsUsecase(ref.read(outfitRepositoryProvider)));
final createOutfitUsecaseProvider = Provider<CreateOutfitUsecase>(
    (ref) => CreateOutfitUsecase(ref.read(outfitRepositoryProvider)));
final updateOutfitUsecaseProvider = Provider<UpdateOutfitUsecase>(
    (ref) => UpdateOutfitUsecase(ref.read(outfitRepositoryProvider)));
final deleteOutfitUsecaseProvider = Provider<DeleteOutfitUsecase>(
    (ref) => DeleteOutfitUsecase(ref.read(outfitRepositoryProvider)));
final wearOutfitUsecaseProvider = Provider<WearOutfitUsecase>(
    (ref) => WearOutfitUsecase(ref.read(outfitRepositoryProvider)));

class ListOutfitsUsecase {
  final IOutfitRepository _repo;
  ListOutfitsUsecase(this._repo);
  Future<Either<Failure, List<OutfitEntity>>> call() => _repo.listOutfits();
}

class CreateOutfitUsecase {
  final IOutfitRepository _repo;
  CreateOutfitUsecase(this._repo);
  Future<Either<Failure, OutfitEntity>> call({required String name, required List<String> items}) =>
      _repo.createOutfit(name: name, items: items);
}

class UpdateOutfitUsecase {
  final IOutfitRepository _repo;
  UpdateOutfitUsecase(this._repo);
  Future<Either<Failure, OutfitEntity>> call({
    required String outfitId,
    String? name,
    List<String>? items,
  }) =>
      _repo.updateOutfit(outfitId: outfitId, name: name, items: items);
}

class DeleteOutfitUsecase {
  final IOutfitRepository _repo;
  DeleteOutfitUsecase(this._repo);
  Future<Either<Failure, Unit>> call(String outfitId) => _repo.deleteOutfit(outfitId);
}

class WearOutfitUsecase {
  final IOutfitRepository _repo;
  WearOutfitUsecase(this._repo);
  Future<Either<Failure, Unit>> call(String outfitId) => _repo.wearOutfit(outfitId);
}
