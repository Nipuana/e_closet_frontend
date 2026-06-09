import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../outfit/presentation/view_model/outfit_list_view_model.dart';
import '../../../wardrobe/domain/entities/wardrobe_item_entity.dart';
import '../../../wardrobe/presentation/state/wardrobe_state.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';

/// Insights — wardrobe analytics derived from the user's pieces and outfits:
/// headline stats, a category breakdown, and value highlights. Reached from
/// the Profile screen.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
      ref.read(outfitListViewModelProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final wardrobe = ref.watch(wardrobeViewModelProvider);
    final outfitCount = ref.watch(outfitListViewModelProvider).outfits.length;
    final items = wardrobe.allItems;

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
        title: Text('Insights',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: _body(context, wardrobe, items, outfitCount),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WardrobeState wardrobe,
    List<WardrobeItemEntity> items,
    int outfitCount,
  ) {
    final palette = context.palette;

    if (wardrobe.allStatus == WardrobeStatus.loading ||
        wardrobe.allStatus == WardrobeStatus.initial) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
          strokeWidth: 2.5,
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Text(
            'Add pieces to your wardrobe to see your habits and value insights here.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary),
          ),
        ),
      );
    }

    final stats = _Stats.from(items, outfitCount);
    final money0 = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final money2 = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.space2, AppSpacing.lg, AppSpacing.space12),
      children: [
        Text('YOUR HABITS',
            style: AppTypography.labelSmall
                .copyWith(color: palette.textTertiary, letterSpacing: 1.6)),
        const SizedBox(height: AppSpacing.space4),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${stats.totalPieces}',
                label: 'TOTAL PIECES',
                footnote: 'across ${stats.categoryCount} categories',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                value: money2.format(stats.avgCostPerWear),
                label: 'AVG COST / WEAR',
                footnote: '${stats.looks} looks saved',
                accent: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: money0.format(stats.collectionValue),
                label: 'COLLECTION VALUE',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                value: '${stats.totalWears}',
                label: 'TOTAL WEARS',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),
        Text('By category',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        const SizedBox(height: AppSpacing.space4),
        ...stats.categories.map((c) => _CategoryBar(
              label: c.name,
              count: c.count,
              fraction: stats.maxCategoryCount == 0 ? 0 : c.count / stats.maxCategoryCount,
            )),
        const SizedBox(height: AppSpacing.space6),
        Text('Highlights',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        const SizedBox(height: AppSpacing.space4),
        if (stats.mostWorn != null)
          _HighlightRow(
            icon: Icons.local_fire_department_outlined,
            title: 'Most worn',
            item: stats.mostWorn!.displayName,
            trailing: '${stats.mostWorn!.usageCount}×',
          ),
        if (stats.bestValue != null)
          _HighlightRow(
            icon: Icons.workspace_premium_outlined,
            title: 'Best value',
            item: stats.bestValue!.displayName,
            trailing: '${money2.format(stats.bestValueCpw)}/wear',
          ),
        if (stats.leastWorn != null)
          _HighlightRow(
            icon: Icons.bedtime_outlined,
            title: 'Needs love',
            item: stats.leastWorn!.displayName,
            trailing: stats.leastWorn!.usageCount == 0
                ? 'never worn'
                : '${stats.leastWorn!.usageCount}×',
          ),
      ],
    );
  }
}

/// Derived analytics for the current wardrobe.
class _Stats {
  final int totalPieces;
  final int categoryCount;
  final double collectionValue;
  final int totalWears;
  final double avgCostPerWear;
  final int looks;
  final List<({String name, int count})> categories;
  final int maxCategoryCount;
  final WardrobeItemEntity? mostWorn;
  final WardrobeItemEntity? leastWorn;
  final WardrobeItemEntity? bestValue;
  final double bestValueCpw;

  _Stats({
    required this.totalPieces,
    required this.categoryCount,
    required this.collectionValue,
    required this.totalWears,
    required this.avgCostPerWear,
    required this.looks,
    required this.categories,
    required this.maxCategoryCount,
    required this.mostWorn,
    required this.leastWorn,
    required this.bestValue,
    required this.bestValueCpw,
  });

  factory _Stats.from(List<WardrobeItemEntity> items, int looks) {
    final counts = <String, int>{};
    var value = 0.0;
    var wears = 0;
    final cpwValues = <double>[];
    WardrobeItemEntity? mostWorn, leastWorn, bestValue;
    var bestCpw = double.infinity;

    for (final i in items) {
      counts[i.category] = (counts[i.category] ?? 0) + 1;
      value += i.purchasePrice ?? 0;
      wears += i.usageCount;
      if (mostWorn == null || i.usageCount > mostWorn.usageCount) mostWorn = i;
      if (leastWorn == null || i.usageCount < leastWorn.usageCount) leastWorn = i;
      if ((i.purchasePrice ?? 0) > 0 && i.usageCount > 0) {
        final cpw = i.purchasePrice! / i.usageCount;
        cpwValues.add(cpw);
        if (cpw < bestCpw) {
          bestCpw = cpw;
          bestValue = i;
        }
      }
    }

    final categories = counts.entries.map((e) => (name: e.key, count: e.value)).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final avgCpw =
        cpwValues.isEmpty ? 0.0 : cpwValues.reduce((a, b) => a + b) / cpwValues.length;

    return _Stats(
      totalPieces: items.length,
      categoryCount: counts.length,
      collectionValue: value,
      totalWears: wears,
      avgCostPerWear: avgCpw,
      looks: looks,
      categories: categories,
      maxCategoryCount: categories.isEmpty ? 0 : categories.first.count,
      mostWorn: mostWorn,
      leastWorn: leastWorn,
      bestValue: bestValue,
      bestValueCpw: bestValue == null ? 0 : bestCpw,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? footnote;
  final bool accent;

  const _StatCard({
    required this.value,
    required this.label,
    this.footnote,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTypography.headingLarge
                  .copyWith(color: accent ? palette.accentStrong : palette.textPrimary)),
          const SizedBox(height: AppSpacing.space1),
          Text(label,
              style: AppTypography.captionSmall
                  .copyWith(color: palette.textTertiary, letterSpacing: 1.2)),
          if (footnote != null) ...[
            const SizedBox(height: 2),
            Text(footnote!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(color: palette.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int count;
  final double fraction;

  const _CategoryBar({required this.label, required this.count, required this.fraction});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(color: palette.textPrimary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: fraction.clamp(0.04, 1.0),
                minHeight: 10,
                backgroundColor: palette.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text('$count',
              style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String item;
  final String trailing;

  const _HighlightRow({
    required this.icon,
    required this.title,
    required this.item,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconSm, color: palette.accentStrong),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.captionSmall
                        .copyWith(color: palette.textTertiary, letterSpacing: 1.0)),
                Text(item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
              ],
            ),
          ),
          Text(trailing,
              style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
        ],
      ),
    );
  }
}
