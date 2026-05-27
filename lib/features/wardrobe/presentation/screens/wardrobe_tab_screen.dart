import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../closet/presentation/screens/closet_tab_screen.dart';
import 'wardrobe_screen.dart';

/// The "Wardrobe" tab — hosts both the full "All clothes" grid and the built
/// "Closet" view behind a segmented toggle (the separator between the two).
class WardrobeTabScreen extends StatefulWidget {
  const WardrobeTabScreen({super.key});

  @override
  State<WardrobeTabScreen> createState() => _WardrobeTabScreenState();
}

class _WardrobeTabScreenState extends State<WardrobeTabScreen> {
  int _view = 0; // 0 = closet (front), 1 = all clothes

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.space3, AppSpacing.lg, AppSpacing.space2),
              child: _Toggle(
                index: _view,
                onChanged: (i) => setState(() => _view = i),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _view,
                children: const [
                  ClosetTabScreen(),
                  WardrobeScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _Toggle({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        children: [
          _Segment(label: 'Closet', selected: index == 0, onTap: () => onChanged(0)),
          _Segment(label: 'All clothes', selected: index == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.surface : Colors.transparent,
            borderRadius: AppRadius.pill,
            boxShadow: selected ? const [AppShadows.shadowSm] : null,
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: selected ? palette.textPrimary : palette.textSecondary,
              fontWeight: selected ? AppTypography.semibold : AppTypography.regular,
            ),
          ),
        ),
      ),
    );
  }
}
