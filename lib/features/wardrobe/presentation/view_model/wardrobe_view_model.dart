import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wardrobe_item_entity.dart';
import '../../domain/usecases/get_all_items_usecase.dart';
import '../../domain/usecases/get_favorite_items_usecase.dart';
import '../../domain/usecases/get_recent_items_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';
import '../state/wardrobe_state.dart';

final wardrobeViewModelProvider =
    NotifierProvider<WardrobeViewModel, WardrobeState>(() => WardrobeViewModel());

class WardrobeViewModel extends Notifier<WardrobeState> {
  late GetAllItemsUsecase _getAllItems;
  late GetRecentItemsUsecase _getRecentItems;
  late GetFavoriteItemsUsecase _getFavoriteItems;
  late ToggleFavoriteUsecase _toggleFavorite;

  @override
  WardrobeState build() {
    _getAllItems = ref.read(getAllItemsUsecaseProvider);
    _getRecentItems = ref.read(getRecentItemsUsecaseProvider);
    _getFavoriteItems = ref.read(getFavoriteItemsUsecaseProvider);
    _toggleFavorite = ref.read(toggleFavoriteUsecaseProvider);
    return const WardrobeState();
  }

  /// Loads both dashboard sections.
  Future<void> loadDashboard() async {
    await Future.wait([loadRecentItems(), loadFavoriteItems()]);
  }

  /// Loads the full wardrobe (for the Wardrobe tab grid).
  ///
  /// Only shows the blocking spinner on the first load (when there's nothing to
  /// show yet). Later refreshes — returning from a detail screen, saving an
  /// edit, pull-to-refresh — keep the current grid on screen and swap the data
  /// in silently, so there's no spinner flash and images aren't torn down and
  /// re-decoded every time.
  Future<void> loadAllItems() async {
    if (state.allItems.isEmpty) {
      state = state.copyWith(allStatus: WardrobeStatus.loading);
    }
    final result = await _getAllItems();
    result.fold(
      (failure) => state = state.copyWith(
        // Keep whatever we're already showing if a background refresh fails.
        allStatus: state.allItems.isEmpty ? WardrobeStatus.error : WardrobeStatus.loaded,
        errorMessage: failure.message,
      ),
      (items) => state = state.copyWith(
        allStatus: WardrobeStatus.loaded,
        allItems: items,
      ),
    );
  }

  Future<void> loadRecentItems({int limit = 10}) async {
    if (state.recentItems.isEmpty) {
      state = state.copyWith(recentStatus: WardrobeStatus.loading);
    }

    final result = await _getRecentItems(GetRecentItemsParams(limit: limit));

    result.fold(
      (failure) => state = state.copyWith(
        recentStatus: state.recentItems.isEmpty ? WardrobeStatus.error : WardrobeStatus.loaded,
        errorMessage: failure.message,
      ),
      (items) => state = state.copyWith(
        recentStatus: WardrobeStatus.loaded,
        recentItems: items,
      ),
    );
  }

  Future<void> loadFavoriteItems({int? limit}) async {
    if (state.favoriteItems.isEmpty) {
      state = state.copyWith(favoritesStatus: WardrobeStatus.loading);
    }

    final result = await _getFavoriteItems(GetFavoriteItemsParams(limit: limit));

    result.fold(
      (failure) => state = state.copyWith(
        favoritesStatus:
            state.favoriteItems.isEmpty ? WardrobeStatus.error : WardrobeStatus.loaded,
        errorMessage: failure.message,
      ),
      (items) => state = state.copyWith(
        favoritesStatus: WardrobeStatus.loaded,
        favoriteItems: items,
      ),
    );
  }

  /// Optimistically flips the favourite flag, then reconciles with the server.
  Future<void> toggleFavorite(WardrobeItemEntity item) async {
    final newValue = !item.isFavorite;

    // Optimistic update on the recent list.
    final updatedRecent = state.recentItems
        .map((i) => i.itemId == item.itemId ? i.copyWith(isFavorite: newValue) : i)
        .toList();
    state = state.copyWith(recentItems: updatedRecent);

    final result = await _toggleFavorite(
      ToggleFavoriteParams(itemId: item.itemId, isFavorite: newValue),
    );

    result.fold(
      (failure) {
        // Revert on failure.
        final revertedRecent = state.recentItems
            .map((i) => i.itemId == item.itemId ? i.copyWith(isFavorite: item.isFavorite) : i)
            .toList();
        state = state.copyWith(
          recentItems: revertedRecent,
          errorMessage: failure.message,
        );
      },
      (_) {
        // Refresh the favourites section so it reflects the change.
        loadFavoriteItems();
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
