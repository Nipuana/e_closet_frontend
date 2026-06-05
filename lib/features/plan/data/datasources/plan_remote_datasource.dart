import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/plan_model.dart';

abstract interface class IPlanRemoteDatasource {
  Future<List<PlanModel>> listPlans({DateTime? from, DateTime? to});
  Future<PlanModel> createPlan({
    required String outfitId,
    required DateTime date,
    bool reminderEnabled,
    DateTime? reminderAt,
    String? title,
    String? note,
  });
  Future<PlanModel> updatePlan({
    required String planId,
    DateTime? date,
    bool? reminderEnabled,
    DateTime? reminderAt,
    String? title,
    String? note,
    bool? worn,
  });
  Future<void> deletePlan(String planId);
}

final planRemoteDatasourceProvider = Provider<IPlanRemoteDatasource>((ref) {
  return PlanRemoteDatasource(
    apiClient: ref.watch(apiClientProvider),
    userSessionService: ref.watch(userSessionServiceProvider),
  );
});

class PlanRemoteDatasource implements IPlanRemoteDatasource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  PlanRemoteDatasource({
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
  Future<List<PlanModel>> listPlans({DateTime? from, DateTime? to}) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.get(
        ApiEndpoints.plans,
        queryParameters: {
          'user_id': userId,
          'from': ?from?.toIso8601String(),
          'to': ?to?.toIso8601String(),
        },
      );
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((e) => PlanModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load plans',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<PlanModel> createPlan({
    required String outfitId,
    required DateTime date,
    bool reminderEnabled = true,
    DateTime? reminderAt,
    String? title,
    String? note,
  }) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.post(
        ApiEndpoints.plans,
        data: {
          'user_id': userId,
          'outfit_id': outfitId,
          'date': date.toIso8601String(),
          'reminder_enabled': reminderEnabled,
          'reminder_at': ?reminderAt?.toIso8601String(),
          'title': ?title,
          'note': ?note,
        },
      );
      return PlanModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to create plan',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<PlanModel> updatePlan({
    required String planId,
    DateTime? date,
    bool? reminderEnabled,
    DateTime? reminderAt,
    String? title,
    String? note,
    bool? worn,
  }) async {
    try {
      final userId = await _requireUserId();
      final response = await _apiClient.patch(
        ApiEndpoints.planById(planId),
        data: {
          'user_id': userId,
          'date': ?date?.toIso8601String(),
          'reminder_enabled': ?reminderEnabled,
          'reminder_at': ?reminderAt?.toIso8601String(),
          'title': ?title,
          'note': ?note,
          'worn': ?worn,
        },
      );
      return PlanModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to update plan',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deletePlan(String planId) async {
    try {
      final userId = await _requireUserId();
      await _apiClient.delete('${ApiEndpoints.planById(planId)}?user_id=$userId');
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to delete plan',
        e.response?.statusCode,
      );
    }
  }
}
