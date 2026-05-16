import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService();
});

abstract interface class IUserSessionService {
  Future<void> saveUserSession(String userId, String email, String username, String userType,
      {String? profilePicture});
  Future<Map<String, dynamic>?> getUserSession();
  Future<void> clearSession();
  Future<String?> getUserId();
  Future<String?> getUserEmail();
  Future<String?> getUsername();
  Future<String?> getUserType();
  Future<String?> getProfilePicture();
}

class UserSessionService implements IUserSessionService {
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';
  static const String _usernameKey = 'username';
  static const String _userTypeKey = 'user_type';
  static const String _profilePictureKey = 'profile_picture';
  static const String _isLoggedInKey = 'is_logged_in';

  @override
  Future<void> saveUserSession(
    String userId,
    String email,
    String username,
    String userType, {
    String? profilePicture,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_userIdKey, userId),
      prefs.setString(_emailKey, email),
      prefs.setString(_usernameKey, username),
      prefs.setString(_userTypeKey, userType),
      if (profilePicture != null)
        prefs.setString(_profilePictureKey, profilePicture)
      else
        prefs.remove(_profilePictureKey),
      prefs.setBool(_isLoggedInKey, true),
    ]);
  }

  @override
  Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (!isLoggedIn) {
      return null;
    }

    return {
      'userId': prefs.getString(_userIdKey),
      'email': prefs.getString(_emailKey),
      'username': prefs.getString(_usernameKey),
      'userType': prefs.getString(_userTypeKey),
      'profilePicture': prefs.getString(_profilePictureKey),
    };
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_userIdKey),
      prefs.remove(_emailKey),
      prefs.remove(_usernameKey),
      prefs.remove(_userTypeKey),
      prefs.remove(_profilePictureKey),
      prefs.setBool(_isLoggedInKey, false),
    ]);
  }

  @override
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  @override
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  @override
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  @override
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  @override
  Future<String?> getProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePictureKey);
  }
}
