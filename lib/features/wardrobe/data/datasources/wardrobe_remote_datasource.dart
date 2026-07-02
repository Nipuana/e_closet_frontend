import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/wardrobe_item_api_model.dart';
import 'wardrobe_datasource.dart';

final wardrobeRemoteDatasourceProvider = Provider<IWardrobeRemoteDatasource>((ref) {
  return WardrobeRemoteDatasource(
    apiClient: ref.watch(apiClientProvider),
    userSessionService: ref.watch(userSessionServiceProvider),
  );
});

class WardrobeRemoteDatasource implements IWardrobeRemoteDatasource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  WardrobeRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService;

  Future<String> _requireUserId() async {
    final userId = await _userSessionService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw UnauthorizedException('No active user session');
    }
    return userId;
  }

  List<WardrobeItemApiModel> _parseList(Response response) {
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => WardrobeItemApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
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
  }) async {
    try {
      final userId = await _requireUserId();
      final formData = FormData.fromMap({
        'user_id': userId,
        'category': category,
        if (name != null && name.isNotEmpty) 'name': name,
        if (subCategory != null && subCategory.isNotEmpty) 'sub_category': subCategory,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (material != null && material.isNotEmpty) 'material': material,
        if (color != null && color.isNotEmpty) 'color': color,
        if (season != null && season.isNotEmpty) 'season': season,
        if (colors != null && colors.isNotEmpty) 'colors': colors.join(','),
        'purchase_price': ?price,
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
        if (imagePath != null && imagePath.isNotEmpty)
          'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiClient.post(
        ApiEndpoints.addWardrobeItem,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return WardrobeItemApiModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw ApiException(
        response.data['message'] ?? 'Failed to add item',
        response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to add item',
        e.response?.statusCode,
      );
    }
  }

  @override
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
  }) async {
    try {
      final userId = await _requireUserId();
      // Send colors/tags always (even empty) so clearing them persists; the
      // backend treats an empty string as "no colours/tags".
      final formData = FormData.fromMap({
        'user_id': userId,
        'category': category,
        'name': name ?? '',
        'sub_category': ?subCategory,
        'brand': brand ?? '',
        'material': material ?? '',
        'color': ?color,
        'season': season ?? '',
        'colors': (colors ?? const []).join(','),
        'purchase_price': price?.toString() ?? '',
        if (tags != null) 'tags': tags.join(','),
        if (imagePath != null && imagePath.isNotEmpty)
          'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiClient.put(
        ApiEndpoints.wardrobeItem(itemId),
        data: formData,
      );

      if (response.statusCode == 200) {
        return WardrobeItemApiModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw ApiException(
        response.data['message'] ?? 'Failed to update item',
        response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to update item',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<WardrobeItemApiModel>> getAllItems() async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.get(
        ApiEndpoints.wardrobe,
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return _parseList(response);
      }
      throw ApiException(
        response.data['message'] ?? 'Failed to load wardrobe',
        response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load wardrobe',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<WardrobeItemApiModel>> getRecentItems({int limit = 10}) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.get(
        ApiEndpoints.recentWardrobeItems,
        queryParameters: {'user_id': userId, 'limit': limit},
      );

      if (response.statusCode == 200) {
        return _parseList(response);
      }
      throw ApiException(
        response.data['message'] ?? 'Failed to load recent items',
        response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load recent items',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<WardrobeItemApiModel>> getFavoriteItems({int? limit}) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.get(
        ApiEndpoints.favoriteWardrobeItems,
        queryParameters: {
          'user_id': userId,
          'limit': ?limit,
        },
      );

      if (response.statusCode == 200) {
        return _parseList(response);
      }
      throw ApiException(
        response.data['message'] ?? 'Failed to load favourites',
        response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load favourites',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<WardrobeItemApiModel> getItem(String itemId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.wardrobeItem(itemId));
      if (response.statusCode == 200) {
        return WardrobeItemApiModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw ApiException(response.data['message'] ?? 'Failed to load item', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load item',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.delete(
        '${ApiEndpoints.wardrobeItem(itemId)}?user_id=$userId',
      );
      if (response.statusCode == 200) return;
      throw ApiException(response.data['message'] ?? 'Failed to remove item', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to remove item',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<WardrobeItemApiModel> markWorn(String itemId) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.patch(
        ApiEndpoints.markWornWardrobeItem(itemId),
        data: {'user_id': userId},
      );
      if (response.statusCode == 200) {
        return WardrobeItemApiModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw ApiException(response.data['message'] ?? 'Failed to update item', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to update item',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<WardrobeItemApiModel> toggleFavorite({
    required String itemId,
    required bool isFavorite,
  }) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.patch(
        ApiEndpoints.toggleWardrobeFavorite(itemId),
        data: {'user_id': userId, 'is_favorite': isFavorite},
      );

      if (response.statusCode == 200) {
        return WardrobeItemApiModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw ApiException(
        response.data['message'] ?? 'Failed to update favourite',
        response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to update favourite',
        e.response?.statusCode,
      );
    }
  }
}
