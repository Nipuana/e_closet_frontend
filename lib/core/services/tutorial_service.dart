import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tutorialServiceProvider = Provider<TutorialService>((ref) => TutorialService());

/// A monotonically increasing token. Calling [TutorialReplayNotifier.request]
/// bumps it; [MainShell] listens so the "Replay tutorial" action from Profile
/// can trigger the tour after popping back to the shell.
final tutorialReplayProvider =
    NotifierProvider<TutorialReplayNotifier, int>(TutorialReplayNotifier.new);

class TutorialReplayNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state = state + 1;
}

/// Persists whether the first-run coach-mark tour has been completed. The flag
/// is keyed **per user** so every account sees the tour once on their first
/// login, even when several accounts share the same device.
class TutorialService {
  // Bump the version suffix if the tour changes enough to warrant re-showing.
  static const _prefix = 'main_tutorial_completed_v1';

  // Falls back to a device-wide key when the user id isn't known yet.
  String _keyFor(String? userId) =>
      (userId == null || userId.isEmpty) ? _prefix : '${_prefix}_$userId';

  Future<bool> isCompleted(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFor(userId)) ?? false;
  }

  Future<void> markCompleted(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(userId), true);
  }

  Future<void> reset(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(userId));
  }
}
