import '../models/auth_api_model.dart';
import '../models/auth_hive_model.dart';

abstract interface class IAuthLocalDatasource {
  Future<bool> register(AuthHiveModel model, String password);
  Future<AuthHiveModel?> login(String email, String password);
  Future<AuthHiveModel?> getCurrentUser();
  Future<bool> logout();
  Future<bool> userExists(String email);
}

abstract interface class IAuthRemoteDatasource {
  Future<AuthApiModel> register(AuthApiModel model);
  Future<AuthApiModel> login(String email, String password);
  Future<AuthApiModel> signInWithGoogle(String idToken);
  Future<AuthApiModel?> getCurrentUser();
  Future<bool> logout();
  Future<AuthApiModel> updateUser(AuthApiModel model, {String? filePath});
  Future<String> changePassword({required String currentPassword, required String newPassword});
  Future<String> requestPasswordReset(String email);
  Future<String> verifyOtp({required String email, required String otp});
  Future<String> resetPassword({required String token, required String newPassword});
}
