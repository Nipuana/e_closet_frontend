import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/outfit_model.dart';

abstract interface class IOutfitRemoteDatasource {
  Future<List<OutfitModel>> listOutfits();
  Future<OutfitModel> createOutfit({required String name, required List<String> items});
  Future<OutfitModel> updateOutfit({
    required String outfitId,
    String? name,
    List<String>? items,
  });
  Future<void> deleteOutfit(String outfitId);
  Future<void> wearOutfit(String outfitId);
}

final outfitRemoteDatasourceProvider = Provider<IOutfitRemoteDatasource>((ref) {
  return OutfitRemoteDatasource(
    apiClient: ref.watch(apiClientProvider),
    userSessionService: ref.watch(userSessionServiceProvider),
  );
});

class OutfitRemoteDatasource implements IOutfitRemoteDatasource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  OutfitRemoteDatasource({
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
  Future<List<OutfitModel>> listOutfits() async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.get(
        ApiEndpoints.outfits,
        queryParameters: {'user_id': userId},
      );
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((e) => OutfitModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load outfits',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<OutfitModel> createOutfit({required String name, required List<String> items}) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.post(
        ApiEndpoints.createOutfit,
        data: {'user_id': userId, 'name': name, 'items': items},
      );
      return OutfitModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to save outfit',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<OutfitModel> updateOutfit({
    required String outfitId,
    String? name,
    List<String>? items,
  }) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.patch(
        ApiEndpoints.outfitById(outfitId),
        data: {
          'user_id': userId,
          'name': ?name,
          'items': ?items,
        },
      );
      return OutfitModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to update outfit',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteOutfit(String outfitId) async {
    try {
      final userId = await _requireUserId();
      await _apiClient.delete('${ApiEndpoints.outfitById(outfitId)}?user_id=$userId');
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to delete outfit',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> wearOutfit(String outfitId) async {
    try {
      await _apiClient.post(ApiEndpoints.wearOutfit(outfitId), data: {});
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to mark worn',
        e.response?.statusCode,
      );
    }
  }
}
