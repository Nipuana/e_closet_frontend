import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';

abstract interface class ICatalogRemoteDatasource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory(String name, {List<String> subcategories});
  Future<List<BrandModel>> getBrands();
  Future<BrandModel> createBrand(String name);
}

final catalogRemoteDatasourceProvider = Provider<ICatalogRemoteDatasource>((ref) {
  return CatalogRemoteDatasource(
    apiClient: ref.watch(apiClientProvider),
    userSessionService: ref.watch(userSessionServiceProvider),
  );
});

class CatalogRemoteDatasource implements ICatalogRemoteDatasource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  CatalogRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService;

  Future<String> _requireUserId() async {
    final id = await _userSessionService.getUserId();
    if (id == null || id.isEmpty) throw UnauthorizedException('No active user session');
    return id;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.get(
        ApiEndpoints.categories,
        queryParameters: {'user_id': userId},
      );
      final list = response.data['data'] as List<dynamic>? ?? [];
      return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load categories',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<CategoryModel> createCategory(String name, {List<String> subcategories = const []}) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.post(
        ApiEndpoints.categories,
        data: {'user_id': userId, 'name': name, 'subcategories': subcategories},
      );
      return CategoryModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to add category',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<BrandModel>> getBrands() async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.get(
        ApiEndpoints.brands,
        queryParameters: {'user_id': userId},
      );
      final list = response.data['data'] as List<dynamic>? ?? [];
      return list.map((e) => BrandModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load brands',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<BrandModel> createBrand(String name) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.post(
        ApiEndpoints.brands,
        data: {'user_id': userId, 'name': name},
      );
      return BrandModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to add brand',
        e.response?.statusCode,
      );
    }
  }
}
