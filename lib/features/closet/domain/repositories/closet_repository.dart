import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/wardrobe_layout_entity.dart';

abstract interface class IClosetRepository {
  Future<Either<Failure, List<WardrobeLayoutEntity>>> listLayouts();
  Future<Either<Failure, WardrobeLayoutEntity>> saveLayout(WardrobeLayoutEntity layout);
  Future<Either<Failure, Unit>> deleteLayout(String layoutId);
}
