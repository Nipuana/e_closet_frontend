import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'api_endpoints.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late Dio _dio;

  /// Invoked when the server rejects a request with 401 (expired/invalid
  /// session). Wired by [SessionManager] to clear the session and sign out.
  void Function()? onUnauthorized;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    // Surface auth failures so the session layer can react (auto sign-out).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: print,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
          Duration(seconds: 5),
        ],
      ),
    );

    // Add pretty logger
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<Response> post(String path, {required dynamic data, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<Response> put(String path, {required dynamic data, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<Response> patch(String path, {required dynamic data, Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? headers}) async {
    try {
      final response = await _dio.delete(
        path,
        options: Options(headers: headers),
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
