import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../closet/presentation/screens/wardrobe_list_screen.dart';
import '../../../insights/presentation/screens/insights_screen.dart';
import '../../../outfit/presentation/screens/lookbook_screen.dart';
import '../../../outfit/presentation/view_model/outfit_list_view_model.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';
import '../view_model/edit_profile_view_model.dart';
import 'edit_profile_screen.dart';

/// Profile — identity, headline counts, collections (Closet / Lookbook /
/// Insights), preferences, and sign out. Insights now lives here.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _username = '';
  String _email = '';
  String? _profilePicture;
  bool _uploadingPhoto = false;
  bool _notifications = true;
  bool _seasonalReminders = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
      ref.read(outfitListViewModelProvider.notifier).load();
      _loadUser();
    });
  }

  Future<void> _loadUser() async {
    final session = ref.read(userSessionServiceProvider);
    final name = await session.getUsername();
    final email = await session.getUserEmail();
    final picture = await session.getProfilePicture();
    if (mounted) {
      setState(() {
        _username = name ?? 'You';
        _email = email ?? '';
        _profilePicture = picture;
      });
    }
  }

  String? get _resolvedPictureUrl {
    final url = _profilePicture;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${ApiEndpoints.serverAddress}$url';
  }

  Future<void> _openEditProfile() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (changed == true) _loadUser();
  }

  /// Tapping the avatar goes straight to picking/capturing a new profile
  /// photo and uploading it — no detour through the full edit screen.
  Future<void> _changeProfilePhoto() async {
    if (_uploadingPhoto) return;
    final source = await _chooseImageSource();
    if (source == null) return;

    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final ok = await ref.read(editProfileViewModelProvider.notifier).saveProfile(
          username: _username,
          imagePath: file.path,
        );
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);

    if (ok) {
      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } else {
      final err = ref.read(editProfileViewModelProvider).error;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err ?? 'Could not update photo')));
      }
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

  Widget _avatar(AppPalette palette) {
    final url = _resolvedPictureUrl;
    final initial = Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(color: palette.textPrimary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _username.isNotEmpty ? _username[0].toUpperCase() : 'E',
        style: AppTypography.headingLarge.copyWith(color: palette.background),
      ),
    );

    final Widget picture = url == null
        ? initial
        : ClipOval(
            child: CachedNetworkImage(
              imageUrl: url,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              placeholder: (_, _) => initial,
              errorWidget: (_, _, _) => initial,
            ),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        picture,
        // Dim + spinner while a new photo uploads.
        if (_uploadingPhoto)
          Positioned.fill(
            child: ClipOval(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: palette.background),
                ),
              ),
            ),
          ),
        // Camera badge — signals the avatar is tappable to change the photo.
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
    );
  }

  Future<void> _signOut() async {
    await ref.read(sessionManagerProvider).clearSession();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Return to the shell and re-run the coach-mark tour. MainShell listens to
  /// [tutorialReplayProvider] and starts the tour once we're back on it.
  void _replayTutorial() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref.read(tutorialReplayProvider.notifier).request();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pieces = ref.watch(wardrobeViewModelProvider).allItems;
    final looks = ref.watch(outfitListViewModelProvider).outfits.length;
    final wears = pieces.fold<int>(0, (sum, i) => sum + i.usageCount);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: AppSpacing.iconSm, color: palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.space2, AppSpacing.lg, AppSpacing.space10),
          children: [
            // Identity
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _changeProfilePhoto,
                    child: _avatar(palette),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text('Tap your photo to change it',
                      style: AppTypography.captionSmall.copyWith(color: palette.textTertiary)),
                  const SizedBox(height: AppSpacing.space3),
                  Text(_username,
                      style: AppTypography.headingLarge.copyWith(color: palette.textPrimary)),
                  if (_email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_email,
                        style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.space2),
                  TextButton.icon(
                    onPressed: _openEditProfile,
                    icon: Icon(Icons.edit_outlined,
                        size: AppSpacing.iconXs, color: palette.accentStrong),
                    label: Text('Edit profile',
                        style: AppTypography.labelMedium.copyWith(color: palette.accentStrong)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            // Stat row
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.lg,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  _Stat(value: '${pieces.length}', label: 'PIECES'),
                  _Divider(),
                  _Stat(value: '$looks', label: 'LOOKS'),
                  _Divider(),
                  _Stat(value: '$wears', label: 'WEARS'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            // Collections
            Text('COLLECTIONS',
                style: AppTypography.labelSmall
                    .copyWith(color: palette.textTertiary, letterSpacing: 1.4)),
            const SizedBox(height: AppSpacing.space3),
            _Row(
              icon: Icons.door_sliding_outlined,
              label: 'Closet layouts',
              onTap: () => _push(const WardrobeListScreen()),
            ),
            _Row(
              icon: Icons.auto_awesome_outlined,
              label: 'Lookbook',
              onTap: () => _push(const LookbookScreen()),
            ),
            _Row(
              icon: Icons.bar_chart_outlined,
              label: 'Insights',
              onTap: () => _push(const InsightsScreen()),
            ),
            const SizedBox(height: AppSpacing.space6),
            // Preferences
            Text('PREFERENCES',
                style: AppTypography.labelSmall
                    .copyWith(color: palette.textTertiary, letterSpacing: 1.4)),
            const SizedBox(height: AppSpacing.space3),
            _ToggleRow(
              label: 'Notifications',
              value: _notifications,
              onChanged: (v) {
                setState(() => _notifications = v);
                if (v) ref.read(notificationServiceProvider).requestPermissions();
              },
            ),
            _ToggleRow(
              label: 'Seasonal rotation reminders',
              value: _seasonalReminders,
              onChanged: (v) => setState(() => _seasonalReminders = v),
            ),
            const SizedBox(height: AppSpacing.space6),
            // Help
            Text('HELP',
                style: AppTypography.labelSmall
                    .copyWith(color: palette.textTertiary, letterSpacing: 1.4)),
            const SizedBox(height: AppSpacing.space3),
            _Row(
              icon: Icons.school_outlined,
              label: 'Replay app tour',
              onTap: _replayTutorial,
            ),
            const SizedBox(height: AppSpacing.space6),
            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, size: AppSpacing.iconSm),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: palette.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.headingLarge.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.captionSmall
                  .copyWith(color: palette.textTertiary, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: context.palette.border);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.lg,
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: palette.surfaceAlt, borderRadius: AppRadius.md),
                child: Icon(icon, size: AppSpacing.iconSm, color: palette.accent),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(label,
                    style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
              ),
              Icon(Icons.chevron_right, color: palette.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4, vertical: AppSpacing.space1),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
            ),
            Switch.adaptive(
              value: value,
              activeThumbColor: palette.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
