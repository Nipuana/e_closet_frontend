import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../features/main/presentation/state/main_nav_provider.dart';

/// Floating, pill-shaped bottom navigation (Elevation Level 3).
///
/// Purely presentational: it renders the four destinations plus the centred
/// camel "+" action and reports interactions through callbacks. The active-tab
/// state itself lives in [mainNavProvider], so the same bar can be reused on any
/// screen that hosts the shell.
class AppBottomNav extends StatelessWidget {
  final MainTab currentTab;
  final ValueChanged<MainTab> onTabSelected;
  final VoidCallback onAddPressed;

  // Optional anchors for the coach-mark tour. When provided, each key is
  // attached to its destination so the tutorial can spotlight it.
  final GlobalKey? homeKey;
  final GlobalKey? wardrobeKey;
  final GlobalKey? addKey;
  final GlobalKey? ensembleKey;
  final GlobalKey? planKey;

  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.onAddPressed,
    this.homeKey,
    this.wardrobeKey,
    this.addKey,
    this.ensembleKey,
    this.planKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(top: BorderSide(color: context.palette.border)),
        boxShadow: AppShadows.shadowLg,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              KeyedSubtree(
                key: homeKey,
                child: _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentTab == MainTab.home,
                  onTap: () => onTabSelected(MainTab.home),
                ),
              ),
              KeyedSubtree(
                key: wardrobeKey,
                child: _NavItem(
                  icon: Icons.door_sliding_outlined,
                  activeIcon: Icons.door_sliding,
                  label: 'Wardrobe',
                  selected: currentTab == MainTab.wardrobe,
                  onTap: () => onTabSelected(MainTab.wardrobe),
                ),
              ),
              KeyedSubtree(key: addKey, child: _AddButton(onTap: onAddPressed)),
              KeyedSubtree(
                key: ensembleKey,
                child: _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'Ensemble',
                  selected: currentTab == MainTab.ensemble,
                  onTap: () => onTabSelected(MainTab.ensemble),
                ),
              ),
              KeyedSubtree(
                key: planKey,
                child: _NavItem(
                  icon: Icons.event_note_outlined,
                  activeIcon: Icons.event_note,
                  label: 'Plan',
                  selected: currentTab == MainTab.plan,
                  onTap: () => onTabSelected(MainTab.plan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.palette.textPrimary : context.palette.textTertiary;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, size: AppSpacing.iconSm, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: color,
                fontWeight: selected ? AppTypography.semibold : AppTypography.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppShadows.buttonShadow,
        ),
        child: const Icon(Icons.add, color: AppColors.white, size: AppSpacing.iconMd),
      ),
    );
  }
}
