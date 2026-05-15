import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

abstract interface class ISecureStorageService {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> deleteAll();
}

class SecureStorageService implements ISecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveToken(String token) async {
    await write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await read(key: _tokenKey);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await delete(key: _tokenKey);
    await delete(key: _refreshTokenKey);
  }
}
