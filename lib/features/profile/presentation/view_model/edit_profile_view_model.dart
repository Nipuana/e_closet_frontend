import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/user_session_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/domain/entities/auth_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class EditProfileState extends Equatable {
  final bool savingProfile;
  final bool changingPassword;
  final String? error;

  const EditProfileState({
    this.savingProfile = false,
    this.changingPassword = false,
    this.error,
  });

  EditProfileState copyWith({
    bool? savingProfile,
    bool? changingPassword,
    String? error,
  }) =>
      EditProfileState(
        savingProfile: savingProfile ?? this.savingProfile,
        changingPassword: changingPassword ?? this.changingPassword,
        error: error,
      );

  @override
  List<Object?> get props => [savingProfile, changingPassword, error];
}

final editProfileViewModelProvider =
    NotifierProvider<EditProfileViewModel, EditProfileState>(EditProfileViewModel.new);

class EditProfileViewModel extends Notifier<EditProfileState> {
  late IAuthRepository _repo;
  late UserSessionService _session;

  @override
  EditProfileState build() {
    _repo = ref.read(authRepositoryProvider);
    _session = ref.read(userSessionServiceProvider);
    return const EditProfileState();
  }

  /// Save the user's identity (and optionally a new profile photo). Email is
  /// immutable, so the current email is carried through unchanged. Returns
  /// true on success; the datasource keeps the cached session in sync.
  Future<bool> saveProfile({
    required String username,
    String? imagePath,
  }) async {
    state = state.copyWith(savingProfile: true, error: null);

    final userId = await _session.getUserId();
    final userType = await _session.getUserType() ?? 'user';
    final email = await _session.getUserEmail() ?? '';
    final entity = AuthEntity(
      userId: userId,
      username: username,
      email: email,
      userType: userType,
    );

    final result = await _repo.updateUser(entity, filePath: imagePath);
    return result.fold(
      (failure) {
        state = state.copyWith(savingProfile: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(savingProfile: false);
        return true;
      },
    );
  }

  /// Change the password by verifying the current one server-side. Returns
  /// true on success.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(changingPassword: true, error: null);

    final result = await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(changingPassword: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(changingPassword: false);
        return true;
      },
    );
  }
}
