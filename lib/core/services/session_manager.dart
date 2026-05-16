import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../api/api_client.dart';
import 'secure_storage_service.dart';
import 'user_session_service.dart';

/// Single source of truth for the user's authenticated session.
///
/// Responsibilities:
///  - Restore a persisted token into the live [ApiClient] on app startup.
///  - Validate JWT expiry before trusting a stored session.
///  - Start a session at login and tear it down at logout / on a 401.
///
/// Navigation is intentionally *not* handled here (core stays free of feature
/// imports): on an expired/invalid session it invokes [onSessionExpired], which
/// the presentation layer sets to redirect to the login screen.
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(
    apiClient: ref.read(apiClientProvider),
    secureStorage: ref.read(secureStorageProvider),
    userSession: ref.read(userSessionServiceProvider),
  );
  manager.attach();
  return manager;
});

class SessionManager {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final UserSessionService _userSession;

  SessionManager({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
    required UserSessionService userSession,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage,
        _userSession = userSession;

  /// Called when a session ends unexpectedly (server returned 401).
  void Function()? onSessionExpired;

  bool _handlingExpiry = false;

  /// Hook the API client's 401 handler into this manager. Called once when the
  /// provider is first read.
  void attach() {
    _apiClient.onUnauthorized = _handleUnauthorized;
  }

  /// Restore a persisted session on startup. Re-attaches a valid token to the
  /// [ApiClient]; clears anything stale. Returns true if the user is signed in.
  Future<bool> restoreSession() async {
    final token = await _secureStorage.getToken();
    if (token == null || token.isEmpty || _isExpired(token)) {
      await clearSession();
      return false;
    }

    _apiClient.setAuthToken(token);
    final session = await _userSession.getUserSession();
    return session != null;
  }

  /// Persist + activate a token at login time.
  Future<void> startSession(String token) async {
    await _secureStorage.saveToken(token);
    _apiClient.setAuthToken(token);
  }

  /// Tear the session down (logout or expiry): clear tokens, session, header.
  Future<void> clearSession() async {
    await _secureStorage.clearTokens();
    await _userSession.clearSession();
    _apiClient.removeAuthToken();
  }

  /// Whether a non-expired token + persisted session currently exist.
  Future<bool> get isAuthenticated async {
    final token = await _secureStorage.getToken();
    if (token == null || token.isEmpty || _isExpired(token)) return false;
    return (await _userSession.getUserSession()) != null;
  }

  bool _isExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      // Not a decodable JWT — don't force-expire; let the server be the judge.
      return false;
    }
  }

  Future<void> _handleUnauthorized() async {
    if (_handlingExpiry) return;
    _handlingExpiry = true;
    try {
      await clearSession();
      onSessionExpired?.call();
    } finally {
      _handlingExpiry = false;
    }
  }
}
