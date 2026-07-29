import 'package:dio/dio.dart';

import 'exceptions.dart';

/// Shown whenever a request fails for a reason the user can't act on.
const String kGenericFailure = 'Something went wrong. Please try again.';

/// Lost connectivity and an expired session are the two failures worth naming —
/// they're the only ones the user can actually do something about.
const String kNoInternetFailure =
    'No internet connection. Please check your network and try again.';
const String kSessionExpiredFailure =
    'Your session has expired. Please sign in again.';

/// Converts a caught error into copy that is safe to put in front of a user.
///
/// Raw exception text — `ApiException: Invalid credentials (Status: 401)`, Dio
/// errors, Hive errors — leaks implementation detail and reads as a crash.
/// Every [Failure] the UI renders is built through here, so screens can show
/// `failure.message` directly without internals reaching the user.
String userFacingError(Object error, {String fallback = kGenericFailure}) {
  if (error is NoInternetException) return kNoInternetFailure;
  if (error is UnauthorizedException) return kSessionExpiredFailure;
  if (error is ApiException && error.statusCode == 401) {
    return kSessionExpiredFailure;
  }
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return kNoInternetFailure;
      default:
        return fallback;
    }
  }
  return fallback;
}
