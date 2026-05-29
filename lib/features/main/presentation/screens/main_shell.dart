import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/widgets/app_bottom_nav.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../outfit/presentation/screens/lookbook_screen.dart';
import '../../../plan/presentation/screens/plan_screen.dart';
import '../../../tutorial/presentation/coach_mark_overlay.dart';
import '../../../wardrobe/presentation/screens/add_piece_screen.dart';
import '../../../wardrobe/presentation/screens/wardrobe_tab_screen.dart';
import '../state/main_nav_provider.dart';

/// Root app shell. Hosts the four primary tabs in an [IndexedStack] (so each
/// tab keeps its scroll position and state) and the floating [AppBottomNav].
/// The active tab is sourced from [mainNavProvider], giving every screen a
/// shared navigation context.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // One persistent instance per tab; IndexedStack keeps them all alive.
  // Order must match the MainTab enum: home, wardrobe, ensemble, plan.
  static const List<Widget> _tabs = [
    HomeScreen(),
    WardrobeTabScreen(),
    LookbookScreen(showBackButton: false, title: 'Ensembles'),
    PlanScreen(),
  ];

  // Coach-mark anchors, handed to the bottom nav so the tour can spotlight them.
  final _homeKey = GlobalKey();
  final _wardrobeKey = GlobalKey();
  final _addKey = GlobalKey();
  final _ensembleKey = GlobalKey();
  final _planKey = GlobalKey();

  // Guards against the tour showing more than once per shell instance.
  bool _tourRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoStartTour());
  }

  Future<void> _maybeAutoStartTour() async {
    // Per-user flag: each account sees the tour on its own first login.
    final userId = await ref.read(userSessionServiceProvider).getUserId();
    final completed = await ref.read(tutorialServiceProvider).isCompleted(userId);
    if (!completed && mounted) {
      _startTour(markCompleteOnFinish: true);
    }
  }

  void _startTour({bool markCompleteOnFinish = false}) {
    if (_tourRunning) return;
    _tourRunning = true;

    // The tour narrates the bottom nav, so anchor it on the Home tab.
    ref.read(mainNavProvider.notifier).goTo(MainTab.home);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _tourRunning = false;
        return;
      }
      showCoachMarks(
        context,
        _buildSteps(),
        onFinish: () async {
          _tourRunning = false;
          if (markCompleteOnFinish) {
            final userId = await ref.read(userSessionServiceProvider).getUserId();
            await ref.read(tutorialServiceProvider).markCompleted(userId);
          }
        },
      );
    });
  }

  List<CoachMarkStep> _buildSteps() => [
        CoachMarkStep(
          targetKey: _homeKey,
          title: 'Home',
          description:
              'Your style dashboard — today’s suggestions, quick actions, and what’s coming up.',
        ),
        CoachMarkStep(
          targetKey: _wardrobeKey,
          title: 'Wardrobe',
          description:
              'Every piece you own, searchable and organized so you always know what you have.',
        ),
        CoachMarkStep(
          targetKey: _addKey,
          circle: true,
          title: 'Add a piece',
          description:
              'Snap or upload a photo to add a new item to your closet in seconds.',
        ),
        CoachMarkStep(
          targetKey: _ensembleKey,
          title: 'Ensembles',
          description:
              'Assemble outfits from your pieces and browse looks you’ve saved.',
        ),
        CoachMarkStep(
          targetKey: _planKey,
          title: 'Plan',
          description:
              'Schedule what to wear on any day and get a reminder when it’s time.',
        ),
      ];

  void _onAddPressed(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPieceScreen()),
    );
  }

  /// Handles the system back button at the app root. A back press never exits
  /// silently: from any other tab it returns to Home, and from Home it asks the
  /// user to confirm before quitting — so a misclick can't drop them out of the
  /// app.
  Future<void> _onBack(BuildContext context, WidgetRef ref) async {
    final tab = ref.read(mainNavProvider);
    if (tab != MainTab.home) {
      ref.read(mainNavProvider.notifier).goTo(MainTab.home);
      return;
    }
    if (await _confirmQuit(context)) {
      await SystemNavigator.pop();
    }
  }

  Future<bool> _confirmQuit(BuildContext context) async {
    final palette = context.palette;
    final quit = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Quit E-Closet?',
            style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
        content: Text('Are you sure you want to close the app?',
            style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text('Stay',
                style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text('Quit',
                style: AppTypography.labelMedium.copyWith(color: palette.accentStrong)),
          ),
        ],
      ),
    );
    return quit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(mainNavProvider);

    // A "Replay tutorial" tap from Profile bumps this token after popping back
    // to the shell; start the tour when it changes.
    ref.listen(tutorialReplayProvider, (previous, next) {
      if (previous != null && next != previous) _startTour();
    });

    return PopScope(
      // We always intercept: back either switches tabs or asks to quit.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack(context, ref);
      },
      child: Scaffold(
        backgroundColor: context.palette.background,
        // Body sits above the full-width nav bar (no overlap).
        extendBody: false,
        body: IndexedStack(
          index: currentTab.index,
          children: _tabs,
        ),
        bottomNavigationBar: AppBottomNav(
          currentTab: currentTab,
          onTabSelected: (tab) => ref.read(mainNavProvider.notifier).goTo(tab),
          onAddPressed: () => _onAddPressed(context),
          homeKey: _homeKey,
          wardrobeKey: _wardrobeKey,
          addKey: _addKey,
          ensembleKey: _ensembleKey,
          planKey: _planKey,
        ),
      ),
    );
  }
}
