import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class Usecase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

abstract class UsecaseWithoutParams<Type> {
  Future<Either<Failure, Type>> call();
}

abstract class UsecaseWithParms<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}
