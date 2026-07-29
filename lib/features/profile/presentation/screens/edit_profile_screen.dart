import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../common/common.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/theme/theme.dart';
import '../view_model/edit_profile_view_model.dart';

/// Edit the signed-in user's identity: profile photo, username, email, and
/// password. Returns `true` via Navigator.pop when anything changed so the
/// caller can refresh.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _remotePicture; // Existing photo path from the session.
  String? _newImagePath; // Freshly picked/captured photo (local file).
  String _loadedUsername = ''; // Username as loaded, to detect edits.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final session = ref.read(userSessionServiceProvider);
    final name = await session.getUsername();
    final email = await session.getUserEmail();
    final pic = await session.getProfilePicture();
    if (!mounted) return;
    setState(() {
      _loadedUsername = name ?? '';
      _username.text = name ?? '';
      _email.text = email ?? '';
      _remotePicture = pic;
    });
  }

  /// Has the user changed anything they haven't saved yet? Guards accidental
  /// exits (back button / system back) so edits aren't lost.
  bool get _hasUnsavedChanges =>
      _newImagePath != null ||
      _username.text.trim() != _loadedUsername.trim() ||
      _currentPassword.text.isNotEmpty ||
      _newPassword.text.isNotEmpty ||
      _confirmPassword.text.isNotEmpty;

  /// Leaves the screen, confirming first if there are unsaved edits. Returns
  /// [_changed] to the caller so it can refresh when something was saved.
  Future<void> _handleClose() =>
      guardedPop(context, hasUnsavedChanges: _hasUnsavedChanges, result: _changed);

  String? get _resolvedRemoteUrl {
    final url = _remotePicture;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${ApiEndpoints.serverAddress}$url';
  }

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file != null && mounted) {
      setState(() => _newImagePath = file.path);
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    final palette = context.palette;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.space2),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: palette.border, borderRadius: AppRadius.pill),
            ),
            const SizedBox(height: AppSpacing.space2),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: palette.accent),
              title: Text('Take a photo',
                  style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
              subtitle: Text('Open the camera now',
                  style: AppTypography.captionSmall.copyWith(color: palette.textTertiary)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: palette.accent),
              title: Text('Choose from gallery',
                  style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
              subtitle: Text('Pick an existing photo',
                  style: AppTypography.captionSmall.copyWith(color: palette.textTertiary)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile() async {
    final username = _username.text.trim();
    if (username.length < 3) {
      _snack('Username must be at least 3 characters');
      return;
    }

    // Email is intentionally not editable, so it is never sent as a change.
    final ok = await ref.read(editProfileViewModelProvider.notifier).saveProfile(
          username: username,
          imagePath: _newImagePath,
        );
    if (!mounted) return;
    if (ok) {
      _changed = true;
      _newImagePath = null;
      _snack('Profile updated');
      await _loadUser();
    } else {
      _snack(ref.read(editProfileViewModelProvider).error ?? 'Could not update profile');
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPassword.text;
    final next = _newPassword.text;
    final confirm = _confirmPassword.text;

    if (current.length < 6 || next.length < 6) {
      _snack('Passwords must be at least 6 characters');
      return;
    }
    if (next != confirm) {
      _snack('New passwords do not match');
      return;
    }

    final ok = await ref.read(editProfileViewModelProvider.notifier).changePassword(
          currentPassword: current,
          newPassword: next,
        );
    if (!mounted) return;
    if (ok) {
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      _snack('Password changed successfully');
    } else {
      _snack(ref.read(editProfileViewModelProvider).error ?? 'Could not change password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(editProfileViewModelProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleClose();
      },
      child: Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: AppSpacing.iconSm, color: palette.textPrimary),
          onPressed: _handleClose,
        ),
        title: Text('Edit profile',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.space4, AppSpacing.lg, AppSpacing.space10),
          children: [
            Center(child: _avatar(palette)),
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: TextButton(
                onPressed: _pickImage,
                child: Text('Change photo',
                    style: AppTypography.labelMedium.copyWith(color: palette.accentStrong)),
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            Text('ACCOUNT DETAILS',
                style: AppTypography.labelSmall
                    .copyWith(color: palette.textTertiary, letterSpacing: 1.4)),
            const SizedBox(height: AppSpacing.space3),
            AppTextInput(label: 'USERNAME', hint: 'Your name', controller: _username),
            const SizedBox(height: AppSpacing.space4),
            AppTextInput(
              label: 'EMAIL',
              hint: 'you@example.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              isReadOnly: true,
              suffixIcon: Icons.lock_outline,
              helperText: "Email can't be changed",
            ),
            const SizedBox(height: AppSpacing.space5),
            AppButton(
              text: 'Save changes',
              onPressed: state.savingProfile ? null : _saveProfile,
              isLoading: state.savingProfile,
              isFullWidth: true,
              size: ButtonSize.large,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text('CHANGE PASSWORD',
                style: AppTypography.labelSmall
                    .copyWith(color: palette.textTertiary, letterSpacing: 1.4)),
            const SizedBox(height: AppSpacing.space3),
            AppTextInput(
              label: 'CURRENT PASSWORD',
              hint: 'Enter current password',
              controller: _currentPassword,
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.space4),
            AppTextInput(
              label: 'NEW PASSWORD',
              hint: 'At least 6 characters',
              controller: _newPassword,
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.space4),
            AppTextInput(
              label: 'CONFIRM NEW PASSWORD',
              hint: 'Re-enter new password',
              controller: _confirmPassword,
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.space5),
            AppButton(
              text: 'Update password',
              onPressed: state.changingPassword ? null : _changePassword,
              isLoading: state.changingPassword,
              isFullWidth: true,
              variant: ButtonVariant.secondary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _avatar(AppPalette palette) {
    final remote = _resolvedRemoteUrl;
    Widget child;
    if (_newImagePath != null) {
      child = Image.file(File(_newImagePath!), fit: BoxFit.cover, width: 96, height: 96);
    } else if (remote != null) {
      child = CachedNetworkImage(
        imageUrl: remote,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorWidget: (_, _, _) => _initial(palette),
      );
    } else {
      child = _initial(palette);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(child: SizedBox(width: 96, height: 96, child: child)),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                color: palette.accentStrong,
                shape: BoxShape.circle,
                border: Border.all(color: palette.background, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: 16, color: palette.background),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initial(AppPalette palette) {
    final name = _username.text.trim();
    return Container(
      width: 96,
      height: 96,
      color: palette.textPrimary,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'E',
        style: AppTypography.headingLarge.copyWith(color: palette.background),
      ),
    );
  }
}
