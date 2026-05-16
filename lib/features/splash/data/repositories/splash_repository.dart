import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/user_session_service.dart';
import '../../domain/repositories/splash_repository.dart';

final splashRepositoryProvider = Provider<ISplashRepository>((ref) {
  return SplashRepository(
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class SplashRepository implements ISplashRepository {
  final UserSessionService _userSessionService;

  SplashRepository({required UserSessionService userSessionService})
      : _userSessionService = userSessionService;

  @override
  Future<bool> isUserLoggedIn() async {
    final session = await _userSessionService.getUserSession();
    return session != null;
  }
}
