import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wardrobe_item_entity.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../domain/usecases/get_item_usecase.dart';
import '../../domain/usecases/mark_worn_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';

enum ItemDetailStatus { idle, working, deleted }

class ItemDetailState extends Equatable {
  final WardrobeItemEntity? item;
  final ItemDetailStatus status;
  final String? error;

  const ItemDetailState({this.item, this.status = ItemDetailStatus.idle, this.error});

  ItemDetailState copyWith({
    WardrobeItemEntity? item,
    ItemDetailStatus? status,
    String? error,
  }) {
    return ItemDetailState(
      item: item ?? this.item,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [item, status, error];
}

final itemDetailProvider =
    NotifierProvider<ItemDetailController, ItemDetailState>(
        ItemDetailController.new);

class ItemDetailController extends Notifier<ItemDetailState> {
  late GetItemUsecase _getItem;
  late DeleteItemUsecase _deleteItem;
  late MarkWornUsecase _markWorn;
  late ToggleFavoriteUsecase _toggleFavorite;

  @override
  ItemDetailState build() {
    _getItem = ref.read(getItemUsecaseProvider);
    _deleteItem = ref.read(deleteItemUsecaseProvider);
    _markWorn = ref.read(markWornUsecaseProvider);
    _toggleFavorite = ref.read(toggleFavoriteUsecaseProvider);
    return const ItemDetailState();
  }

  void seed(WardrobeItemEntity item) => state = state.copyWith(item: item);

  Future<void> refresh() async {
    final item = state.item;
    if (item == null) return;
    final result = await _getItem(item.itemId);
    result.fold((_) {}, (fresh) => state = state.copyWith(item: fresh));
  }

  Future<void> toggleFavorite() async {
    final item = state.item;
    if (item == null) return;
    final newValue = !item.isFavorite;
    state = state.copyWith(item: item.copyWith(isFavorite: newValue));

    final result = await _toggleFavorite(
      ToggleFavoriteParams(itemId: item.itemId, isFavorite: newValue),
    );
    result.fold(
      (failure) => state = state.copyWith(
        item: item.copyWith(isFavorite: !newValue),
        error: failure.message,
      ),
      (updated) => state = state.copyWith(item: updated),
    );
  }

  Future<void> markWorn() async {
    final item = state.item;
    if (item == null) return;
    final result = await _markWorn(item.itemId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) => state = state.copyWith(item: updated),
    );
  }

  Future<bool> delete() async {
    final item = state.item;
    if (item == null) return false;
    state = state.copyWith(status: ItemDetailStatus.working);
    final result = await _deleteItem(item.itemId);
    return result.fold(
      (failure) {
        state = state.copyWith(status: ItemDetailStatus.idle, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: ItemDetailStatus.deleted);
        return true;
      },
    );
  }
}
