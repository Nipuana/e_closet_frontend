import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/auth_api_model.dart';
import 'auth_datasource.dart';

final authRemoteDataSourceProvider = Provider<IAuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.watch(apiClientProvider),
    secureStorageService: ref.watch(secureStorageProvider),
    userSessionService: ref.watch(userSessionServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDatasource {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorageService;
  final UserSessionService _userSessionService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required SecureStorageService secureStorageService,
    required UserSessionService userSessionService,
  })  : _apiClient = apiClient,
        _secureStorageService = secureStorageService,
        _userSessionService = userSessionService;

  @override
  Future<AuthApiModel> register(AuthApiModel model) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerUser,
        data: {
          'username': model.username,
          'email': model.email,
          'password': model.password,
          // Backend requires confirmPassword; the UI already validated the
          // match, so fall back to password when not explicitly carried.
          'confirmPassword': model.confirmPassword ?? model.password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthApiModel.fromJson(response.data['data']);
      }
      throw ApiException(response.data['message'] ?? 'Registration failed', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Registration failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<AuthApiModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.loginUser,
        // Backend's LoginUserDto accepts an `identifier` (email or username).
        data: {'identifier': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] as String?;
        final loggedInUser = AuthApiModel.fromJson(response.data['data']);

        // Save token securely
        if (token != null) {
          await _secureStorageService.saveToken(token);
          _apiClient.setAuthToken(token);
        }

        // Save user session
        await _userSessionService.saveUserSession(
          loggedInUser.id ?? '',
          loggedInUser.email,
          loggedInUser.username,
          loggedInUser.userType,
          profilePicture: loggedInUser.profilePicture,
        );

        return loggedInUser;
      }
      throw ApiException(response.data['message'] ?? 'Login failed', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Login failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<AuthApiModel> signInWithGoogle(String idToken) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.googleAuth,
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] as String?;
        final loggedInUser = AuthApiModel.fromJson(response.data['data']);

        if (token != null) {
          await _secureStorageService.saveToken(token);
          _apiClient.setAuthToken(token);
        }

        await _userSessionService.saveUserSession(
          loggedInUser.id ?? '',
          loggedInUser.email,
          loggedInUser.username,
          loggedInUser.userType,
          profilePicture: loggedInUser.profilePicture,
        );

        return loggedInUser;
      }
      throw ApiException(response.data['message'] ?? 'Google sign-in failed', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Google sign-in failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<AuthApiModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getCurrentUser);

      if (response.statusCode == 200) {
        return AuthApiModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access');
      }
      throw ApiException('Failed to fetch user', e.response?.statusCode);
    }
  }

  @override
  Future<bool> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout, data: {});
      
      // Clear local data
      await _secureStorageService.clearTokens();
      await _userSessionService.clearSession();
      _apiClient.removeAuthToken();

      return true;
    } on DioException {
      // Even if remote logout fails, clear local data
      await _secureStorageService.clearTokens();
      await _userSessionService.clearSession();
      _apiClient.removeAuthToken();
      return true;
    }
  }

  @override
  Future<AuthApiModel> updateUser(AuthApiModel model, {String? filePath}) async {
    try {
      // The backend has no auth middleware, so it identifies the user by the
      // user_id carried in the request body (same pattern as the wardrobe API).
      final userId = await _userSessionService.getUserId() ?? model.id ?? '';

      final fields = <String, dynamic>{
        'user_id': userId,
        'username': model.username,
        'email': model.email,
      };

      final dynamic requestData = filePath != null
          ? FormData.fromMap({
              ...fields,
              'profile_picture': await MultipartFile.fromFile(filePath),
            })
          : fields;

      final response = await _apiClient.put(
        ApiEndpoints.updateUser,
        data: requestData,
      );

      if (response.statusCode == 200) {
        final updated = AuthApiModel.fromJson(response.data['data']);
        // Keep the cached session in sync so the profile reflects changes.
        await _userSessionService.saveUserSession(
          updated.id ?? userId,
          updated.email,
          updated.username,
          updated.userType,
          profilePicture: updated.profilePicture,
        );
        return updated;
      }
      throw ApiException(response.data['message'] ?? 'Update failed', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Update failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userId = await _userSessionService.getUserId() ?? '';
      final response = await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {
          'user_id': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Password changed successfully';
      }
      throw ApiException(response.data['message'] ?? 'Password change failed', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Password change failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.requestPasswordReset,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Password reset link sent to email';
      }
      throw ApiException(response.data['message'] ?? 'Request failed', response.statusCode);
    } on DioException catch (e) {
      throw ApiException('Password reset request failed', e.response?.statusCode);
    }
  }

  @override
  Future<String> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {'email': email, 'otp': otp},
      );

      if (response.statusCode == 200) {
        // Backend returns a short-lived reset token used for the reset step.
        final token = response.data['token'] as String?;
        if (token == null || token.isEmpty) {
          throw ApiException('Verification failed', response.statusCode);
        }
        return token;
      }
      throw ApiException(response.data['message'] ?? 'Verification failed', response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Verification failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> resetPassword({required String token, required String newPassword}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {'token': token, 'new_password': newPassword},
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Password reset successfully';
      }
      throw ApiException(response.data['message'] ?? 'Reset failed', response.statusCode);
    } on DioException catch (e) {
      throw ApiException('Password reset failed', e.response?.statusCode);
    }
  }
}
