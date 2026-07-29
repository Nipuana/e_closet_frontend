import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wardrobe_layout_entity.dart';
import '../../domain/usecases/closet_usecases.dart';

enum WardrobeListStatus { initial, loading, ready, error }

class WardrobeListState extends Equatable {
  final WardrobeListStatus status;
  final List<WardrobeLayoutEntity> wardrobes;
  final String? error;

  const WardrobeListState({
    this.status = WardrobeListStatus.initial,
    this.wardrobes = const [],
    this.error,
  });

  WardrobeListState copyWith({
    WardrobeListStatus? status,
    List<WardrobeLayoutEntity>? wardrobes,
    String? error,
  }) {
    return WardrobeListState(
      status: status ?? this.status,
      wardrobes: wardrobes ?? this.wardrobes,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, wardrobes, error];
}

final wardrobeListViewModelProvider =
    NotifierProvider<WardrobeListViewModel, WardrobeListState>(WardrobeListViewModel.new);

class WardrobeListViewModel extends Notifier<WardrobeListState> {
  @override
  WardrobeListState build() => const WardrobeListState();

  Future<void> load() async {
    state = state.copyWith(status: WardrobeListStatus.loading);
    final result = await ref.read(listWardrobeLayoutsUsecaseProvider)();
    result.fold(
      (failure) =>
          state = state.copyWith(status: WardrobeListStatus.error, error: failure.message),
      (wardrobes) =>
          state = state.copyWith(status: WardrobeListStatus.ready, wardrobes: wardrobes),
    );
  }

  /// Reflect a just-saved wardrobe in the list straight away. Screens reach the
  /// designer from several routes (Home, the Closet tab, Profile → Closet
  /// layouts), and the Closet tab is kept alive inside an IndexedStack, so it
  /// can't rely on a reload-on-pop to notice a new wardrobe.
  void upsert(WardrobeLayoutEntity wardrobe) {
    // Nothing trustworthy to merge into yet — fetch the real list instead.
    if (state.status != WardrobeListStatus.ready) {
      load();
      return;
    }

    final next = [...state.wardrobes];
    final index =
        next.indexWhere((w) => w.id != null && w.id == wardrobe.id);
    if (index >= 0) {
      next[index] = wardrobe;
    } else {
      next.insert(0, wardrobe); // the backend lists newest first
    }
    state = state.copyWith(status: WardrobeListStatus.ready, wardrobes: next);
  }

  /// Delete a wardrobe and drop it from the list optimistically.
  Future<bool> delete(String layoutId) async {
    final result = await ref.read(deleteWardrobeLayoutUsecaseProvider)(layoutId);
    return result.fold(
      (failure) {
        state = state.copyWith(status: WardrobeListStatus.error, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          wardrobes: state.wardrobes.where((w) => w.id != layoutId).toList(),
        );
        return true;
      },
    );
  }
}
