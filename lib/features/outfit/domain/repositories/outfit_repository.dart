import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/outfit_entity.dart';

abstract interface class IOutfitRepository {
  Future<Either<Failure, List<OutfitEntity>>> listOutfits();
  Future<Either<Failure, OutfitEntity>> createOutfit({
    required String name,
    required List<String> items,
  });
  Future<Either<Failure, OutfitEntity>> updateOutfit({
    required String outfitId,
    String? name,
    List<String>? items,
  });
  Future<Either<Failure, Unit>> deleteOutfit(String outfitId);
  Future<Either<Failure, Unit>> wearOutfit(String outfitId);
}
