import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The primary destinations shown in the floating bottom navigation.
/// The center "+" is an action, not a destination, so it isn't a tab here.
/// (Profile — which now also hosts Insights — is reached from the dashboard
/// avatar, not the tab bar.)
///
/// "wardrobe" hosts both the all-pieces grid and the built closet view behind
/// an in-screen toggle; "ensemble" is the saved-ensembles (Lookbook) list.
enum MainTab { home, wardrobe, ensemble, plan }

/// Shared navigation context for the whole app shell.
///
/// Any screen can read or drive the active tab via [mainNavProvider] without
/// passing callbacks down the widget tree — e.g. a "View wardrobe" link on the
/// home tab can call `ref.read(mainNavProvider.notifier).goTo(MainTab.wardrobe)`.
final mainNavProvider = NotifierProvider<MainNavController, MainTab>(
  MainNavController.new,
);

class MainNavController extends Notifier<MainTab> {
  @override
  MainTab build() => MainTab.home;

  void goTo(MainTab tab) => state = tab;

  void setIndex(int index) {
    if (index >= 0 && index < MainTab.values.length) {
      state = MainTab.values[index];
    }
  }
}
