import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/wardrobe_layout_model.dart';

abstract interface class IClosetRemoteDatasource {
  Future<List<WardrobeLayoutModel>> listLayouts();
  Future<WardrobeLayoutModel> saveLayout({
    String? layoutId,
    required String name,
    required String cabinetType,
    required String finish,
    required int cols,
    required int rows,
    required List<List<String>> grid,
    Map<String, List<String>> placements,
  });
  Future<void> deleteLayout(String layoutId);
}

final closetRemoteDatasourceProvider = Provider<IClosetRemoteDatasource>((ref) {
  return ClosetRemoteDatasource(
    apiClient: ref.watch(apiClientProvider),
    userSessionService: ref.watch(userSessionServiceProvider),
  );
});

class ClosetRemoteDatasource implements IClosetRemoteDatasource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  ClosetRemoteDatasource({
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
  Future<List<WardrobeLayoutModel>> listLayouts() async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.get(
        ApiEndpoints.closetLayout,
        queryParameters: {'user_id': userId},
      );
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => WardrobeLayoutModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load wardrobes',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<WardrobeLayoutModel> saveLayout({
    String? layoutId,
    required String name,
    required String cabinetType,
    required String finish,
    required int cols,
    required int rows,
    required List<List<String>> grid,
    Map<String, List<String>> placements = const {},
  }) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.post(
        ApiEndpoints.saveClosetLayout,
        data: {
          'user_id': userId,
          'layout_id': ?layoutId,
          'name': name,
          'cabinet_type': cabinetType,
          'finish': finish,
          'dimensions': {'cols': cols, 'rows': rows},
          'zones': grid,
          'placements': placements,
        },
      );
      return WardrobeLayoutModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to save wardrobe',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteLayout(String layoutId) async {
    try {
      final userId = await _requireUserId();
      await _apiClient.delete(
        '${ApiEndpoints.closetLayoutById(layoutId)}?user_id=$userId',
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to delete wardrobe',
        e.response?.statusCode,
      );
    }
  }
}
