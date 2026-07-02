import '../models/wardrobe_item_api_model.dart';

abstract interface class IWardrobeRemoteDatasource {
  Future<WardrobeItemApiModel> addItem({
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
  Future<WardrobeItemApiModel> updateItem({
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
  Future<List<WardrobeItemApiModel>> getAllItems();
  Future<List<WardrobeItemApiModel>> getRecentItems({int limit});
  Future<List<WardrobeItemApiModel>> getFavoriteItems({int? limit});
  Future<WardrobeItemApiModel> getItem(String itemId);
  Future<void> deleteItem(String itemId);
  Future<WardrobeItemApiModel> markWorn(String itemId);
  Future<WardrobeItemApiModel> toggleFavorite({
    required String itemId,
    required bool isFavorite,
  });
}
