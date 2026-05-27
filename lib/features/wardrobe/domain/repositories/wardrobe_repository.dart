import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/wardrobe_item_entity.dart';

abstract interface class IWardrobeRepository {
  /// Create a new wardrobe item (multipart upload with image).
  Future<Either<Failure, WardrobeItemEntity>> addItem({
    String? imagePath,
    required String category,
    String? name,
    String? subCategory,
    String? brand,
    String? material,
    String? color,
    String? season,
    List<String>? colors,
    double? price,
    List<String>? tags,
  });

  /// Edit an existing item's details (multipart; optional replacement image).
  Future<Either<Failure, WardrobeItemEntity>> updateItem({
    required String itemId,
    required String category,
    String? name,
    String? subCategory,
    String? brand,
    String? material,
    String? color,
    String? season,
    List<String>? colors,
    double? price,
    List<String>? tags,
    String? imagePath,
  });

  /// All (non-archived) items for the current user.
  Future<Either<Failure, List<WardrobeItemEntity>>> getAllItems();

  /// Recently added items for the current user (newest first).
  Future<Either<Failure, List<WardrobeItemEntity>>> getRecentItems({int limit});

  /// Favourited items for the current user.
  Future<Either<Failure, List<WardrobeItemEntity>>> getFavoriteItems({int? limit});

  /// Fetch a single item by id.
  Future<Either<Failure, WardrobeItemEntity>> getItem(String itemId);

  /// Permanently remove an item.
  Future<Either<Failure, Unit>> deleteItem(String itemId);

  /// Increment an item's wear count; returns the updated item.
  Future<Either<Failure, WardrobeItemEntity>> markWorn(String itemId);

  /// Toggle the favourite flag of a single item; returns the updated item.
  Future<Either<Failure, WardrobeItemEntity>> toggleFavorite({
    required String itemId,
    required bool isFavorite,
  });
}
