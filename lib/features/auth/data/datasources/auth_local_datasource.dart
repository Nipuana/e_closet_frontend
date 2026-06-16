import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/hive_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/auth_hive_model.dart';
import 'auth_datasource.dart';

final authLocalDatasourceProvider = Provider<IAuthLocalDatasource>((ref) {
  return AuthLocalDatasource(
    hiveService: ref.read(hiveServiceProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AuthLocalDatasource implements IAuthLocalDatasource {
  static const String _usersBoxName = 'users_box';

  final HiveService _hiveService;
  final UserSessionService _userSessionService;

  AuthLocalDatasource({
    required HiveService hiveService,
    required UserSessionService userSessionService,
  })  : _hiveService = hiveService,
        _userSessionService = userSessionService;

  @override
  Future<bool> register(AuthHiveModel model, String password) async {
    try {
      // Store user in Hive database
      final userWithPassword = AuthHiveModel(
        userId: model.userId,
        username: model.username,
        email: model.email,
        userType: model.userType,
        password: password,
        profilePicture: model.profilePicture,
        token: model.token,
      );

      await _hiveService.saveData(_usersBoxName, model.email, userWithPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AuthHiveModel?> login(String email, String password) async {
    try {
      final user = await _hiveService.getData(_usersBoxName, email) as AuthHiveModel?;

      if (user != null && user.password == password) {
        // Save to session
        await _userSessionService.saveUserSession(
          user.userId ?? '',
          user.email,
          user.username,
          user.userType,
        );
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AuthHiveModel?> getCurrentUser() async {
    try {
      final session = await _userSessionService.getUserSession();
      if (session != null) {
        final email = session['email'] as String?;
        if (email != null) {
          return await _hiveService.getData(_usersBoxName, email) as AuthHiveModel?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> logout() async {
    try {
      await _userSessionService.clearSession();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> userExists(String email) async {
    try {
      final user = await _hiveService.getData(_usersBoxName, email);
      return user != null;
    } catch (e) {
      return false;
    }
  }
}
