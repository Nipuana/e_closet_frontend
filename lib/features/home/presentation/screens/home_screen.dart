import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../../closet/presentation/screens/wardrobe_preset_picker_screen.dart';
import '../../../dashboard/presentation/view_model/dashboard_view_model.dart';
import '../../../outfit/presentation/screens/assemble_screen.dart';
import '../../../outfit/presentation/view_model/outfit_list_view_model.dart';
import '../../../outfit/presentation/widgets/outfit_visuals.dart';
import '../../../main/presentation/state/main_nav_provider.dart';
import '../../../plan/presentation/view_model/plan_view_model.dart';
import '../../../plan/presentation/widgets/outfit_lookup.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../wardrobe/domain/entities/wardrobe_item_entity.dart';
import '../../../wardrobe/presentation/state/wardrobe_state.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';
import '../../../wardrobe/presentation/widgets/wardrobe_item_card.dart';

/// Dashboard home tab — greeting, today's ensemble, quick actions, and the
/// Recently added / Favourites feeds.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _username = '';
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeViewModelProvider.notifier).loadDashboard();
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
      ref.read(dashboardViewModelProvider.notifier).load();
      ref.read(planViewModelProvider.notifier).load();
      ref.read(outfitListViewModelProvider.notifier).load();
      ref.read(notificationServiceProvider).requestPermissions();
      _loadUser();
    });
  }

  Future<void> _loadUser() async {
    final session = ref.read(userSessionServiceProvider);
    final name = await session.getUsername();
    final picture = await session.getProfilePicture();
    if (mounted) {
      setState(() {
        _username = name ?? '';
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

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(wardrobeViewModelProvider.notifier).loadDashboard(),
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems(),
      ref.read(dashboardViewModelProvider.notifier).load(),
      ref.read(planViewModelProvider.notifier).load(),
      ref.read(outfitListViewModelProvider.notifier).load(),
      _loadUser(),
    ]);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(wardrobeViewModelProvider);

    // Today's planned ensemble (if any), resolved to its outfit + pieces.
    final today = DateTime.now();
    final planState = ref.watch(planViewModelProvider);
    final lookup = OutfitLookup(
      outfits: ref.watch(outfitListViewModelProvider).outfits,
      items: state.allItems,
    );
    final todayPlans = planState.plansOn(today);
    final todayPlan = todayPlans.isEmpty ? null : todayPlans.first;
    final todayName = todayPlan == null
        ? null
        : (todayPlan.title?.isNotEmpty == true ? todayPlan.title! : lookup.name(todayPlan.outfitId));
    final todayPieces = todayPlan == null ? <WardrobeItemEntity>[] : lookup.piecesOf(todayPlan.outfitId);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.space2,
              bottom: AppSpacing.space10,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE · MMMM d').format(DateTime.now()).toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: palette.textTertiary,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          Text(
                            _greeting,
                            style: AppTypography.headingXlarge.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                          if (_username.isNotEmpty)
                            Text(
                              _username,
                              style: AppTypography.headingXlarge.copyWith(
                                color: palette.textPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _Avatar(
                      initial: _username.isNotEmpty ? _username[0].toUpperCase() : 'E',
                      imageUrl: _resolvedPictureUrl,
                      onTap: () => AppRoutes.push(context, const ProfileScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              _SectionHeader(
                title: "Today's ensemble",
                actionLabel: todayPlan == null ? 'Plan' : 'Change',
                onAction: () => ref.read(mainNavProvider.notifier).goTo(MainTab.plan),
              ),
              const SizedBox(height: AppSpacing.space2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TodayEnsembleCard(
                  name: todayName,
                  pieces: todayPieces,
                  onTap: () => ref.read(mainNavProvider.notifier).goTo(MainTab.plan),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        label: 'Build an\nensemble',
                        icon: Icons.auto_awesome_outlined,
                        background: palette.textPrimary,
                        foreground: palette.background,
                        onTap: () => AppRoutes.push(context, const AssembleScreen()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: _ActionCard(
                        label: 'Design my\ncloset',
                        icon: Icons.dashboard_customize_outlined,
                        background: palette.accent,
                        foreground: AppColors.white,
                        onTap: () => AppRoutes.push(
                          context,
                          const WardrobePresetPickerScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              _SectionHeader(
                title: 'Recently added',
                actionLabel: 'Wardrobe',
                onAction: () => ref.read(mainNavProvider.notifier).goTo(MainTab.wardrobe),
              ),
              const SizedBox(height: AppSpacing.space2),
              _ItemsRow(
                status: state.recentStatus,
                items: state.recentItems,
                emptyMessage: 'No items yet. Add your first piece.',
                onToggleFavorite: (item) =>
                    ref.read(wardrobeViewModelProvider.notifier).toggleFavorite(item),
                onRetry: () => ref.read(wardrobeViewModelProvider.notifier).loadRecentItems(),
              ),
              const SizedBox(height: AppSpacing.space5),
              _SectionHeader(
                title: 'Favourites',
                actionLabel: 'View all',
                onAction: () => ref.read(mainNavProvider.notifier).goTo(MainTab.wardrobe),
              ),
              const SizedBox(height: AppSpacing.space2),
              _ItemsRow(
                status: state.favoritesStatus,
                items: state.favoriteItems,
                emptyMessage: 'Tap the heart on any item to save it here.',
                onToggleFavorite: (item) =>
                    ref.read(wardrobeViewModelProvider.notifier).toggleFavorite(item),
                onRetry: () => ref.read(wardrobeViewModelProvider.notifier).loadFavoriteItems(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final String? imageUrl;
  final VoidCallback onTap;

  const _Avatar({required this.initial, this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fallback = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: palette.textPrimary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypography.labelLarge.copyWith(color: palette.background),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: imageUrl == null
          ? fallback
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
            ),
    );
  }
}

class _TodayEnsembleCard extends StatelessWidget {
  final String? name;
  final List<WardrobeItemEntity> pieces;
  final VoidCallback onTap;

  const _TodayEnsembleCard({
    required this.name,
    required this.pieces,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasPlan = name != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.md,
              child: SizedBox(
                width: 52,
                height: 52,
                child: hasPlan && pieces.isNotEmpty
                    ? OutfitThumbnail(items: pieces)
                    : DecoratedBox(
                        decoration: BoxDecoration(color: palette.surfaceAlt),
                        child: Icon(Icons.checkroom_outlined, color: palette.textTertiary),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPlan ? name! : 'No ensemble planned',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(color: palette.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPlan
                        ? '${pieces.length} ${pieces.length == 1 ? 'piece' : 'pieces'} · planned'
                        : "Plan today's look",
                    style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: foreground, size: AppSpacing.iconMd),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headingSmall.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: AppTypography.labelSmall.copyWith(color: palette.accentStrong),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsRow extends StatelessWidget {
  final WardrobeStatus status;
  final List<WardrobeItemEntity> items;
  final String emptyMessage;
  final void Function(WardrobeItemEntity item) onToggleFavorite;
  final VoidCallback onRetry;

  const _ItemsRow({
    required this.status,
    required this.items,
    required this.emptyMessage,
    required this.onToggleFavorite,
    required this.onRetry,
  });

  static const double _rowHeight = 172;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (status == WardrobeStatus.loading || status == WardrobeStatus.initial) {
      return SizedBox(
        height: _rowHeight,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (status == WardrobeStatus.error) {
      return SizedBox(
        height: _rowHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Couldn\'t load items',
                style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: AppTypography.labelSmall.copyWith(color: palette.accentStrong),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return SizedBox(
        height: _rowHeight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space4),
        itemBuilder: (context, index) {
          final item = items[index];
          return WardrobeItemCard(
            item: item,
            onFavoriteToggle: () => onToggleFavorite(item),
          );
        },
      ),
    );
  }
}
