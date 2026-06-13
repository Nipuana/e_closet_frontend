import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/dashboard_overview_model.dart';

abstract interface class IDashboardRemoteDatasource {
  Future<DashboardOverviewModel> getOverview();
}

final dashboardRemoteDatasourceProvider =
    Provider<IDashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasource(
    apiClient: ref.watch(apiClientProvider),
    userSessionService: ref.watch(userSessionServiceProvider),
  );
});

class DashboardRemoteDatasource implements IDashboardRemoteDatasource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  DashboardRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService;

  @override
  Future<DashboardOverviewModel> getOverview() async {
    try {
      final userId = await _userSessionService.getUserId();
      if (userId == null || userId.isEmpty) {
        throw UnauthorizedException('No active user session');
      }

      final response = await _apiClient.get(
        ApiEndpoints.analyticsOverview,
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return DashboardOverviewModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw ApiException(
        response.data['message'] ?? 'Failed to load overview',
        response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?['message'] ?? 'Failed to load overview',
        e.response?.statusCode,
      );
    }
  }
}
