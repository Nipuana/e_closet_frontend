import 'google_secrets.dart';

/// Google Sign-In client identifiers.
///
/// Create these in Google Cloud Console → APIs & Services → Credentials.
/// The values are read from (in order of precedence):
///   1. a `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` build flag, if provided;
///   2. otherwise `lib/core/config/google_secrets.dart` (gitignored local file).
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String _defineServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
  static const String _defineIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');

  /// OAuth 2.0 **Web** client ID. Required on Android to receive an ID token,
  /// and it must match the backend's `GOOGLE_CLIENT_ID` (token audience).
  static String get serverClientId =>
      _defineServerClientId.isNotEmpty ? _defineServerClientId : GoogleSecrets.serverClientId;

  /// OAuth 2.0 **iOS** client ID. Leave empty for Android-only builds.
  static String get iosClientId =>
      _defineIosClientId.isNotEmpty ? _defineIosClientId : GoogleSecrets.iosClientId;

  /// True once at least the web client ID has been configured.
  static bool get isConfigured => serverClientId.isNotEmpty;
}
