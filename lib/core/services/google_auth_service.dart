import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

/// Thin wrapper over `google_sign_in` v7 that yields a Google **ID token** for
/// the backend to verify. Initialization is lazy and happens once.
class GoogleAuthService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: GoogleAuthConfig.iosClientId.isEmpty ? null : GoogleAuthConfig.iosClientId,
      serverClientId:
          GoogleAuthConfig.serverClientId.isEmpty ? null : GoogleAuthConfig.serverClientId,
    );
    _initialized = true;
  }

  /// Launches the interactive Google sign-in flow.
  ///
  /// Returns the ID token on success, or `null` if the user cancelled.
  /// Throws [GoogleAuthException] for configuration/other failures.
  Future<String?> signIn() async {
    if (!GoogleAuthConfig.isConfigured) {
      throw const GoogleAuthException(
          'Google sign-in is not configured. Set GOOGLE_SERVER_CLIENT_ID.');
    }

    await _ensureInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const GoogleAuthException('Google sign-in is not supported on this platform.');
    }

    try {
      final account = await GoogleSignIn.instance.authenticate(scopeHint: ['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const GoogleAuthException('Google did not return an ID token.');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      // The user-facing message stays generic, so log the real reason — without
      // it a failed sign-in is invisible. Note that Android reports a missing
      // OAuth client (package name + SHA-1 not registered in the Google Cloud
      // project) as `canceled`: the chooser opens and dismisses itself, which
      // is indistinguishable from the user backing out.
      debugPrint('GoogleSignIn failed: code=${e.code} description=${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw GoogleAuthException(e.description ?? 'Google sign-in failed');
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }
}

class GoogleAuthException implements Exception {
  final String message;
  const GoogleAuthException(this.message);

  @override
  String toString() => message;
}
