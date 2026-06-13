import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/outfit_entity.dart';
import '../../domain/usecases/outfit_usecases.dart';

enum OutfitListStatus { initial, loading, ready, error }

class OutfitListState extends Equatable {
  final OutfitListStatus status;
  final List<OutfitEntity> outfits;
  final String? error;

  const OutfitListState({
    this.status = OutfitListStatus.initial,
    this.outfits = const [],
    this.error,
  });

  OutfitListState copyWith({
    OutfitListStatus? status,
    List<OutfitEntity>? outfits,
    String? error,
  }) {
    return OutfitListState(
      status: status ?? this.status,
      outfits: outfits ?? this.outfits,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, outfits, error];
}

final outfitListViewModelProvider =
    NotifierProvider<OutfitListViewModel, OutfitListState>(OutfitListViewModel.new);

class OutfitListViewModel extends Notifier<OutfitListState> {
  @override
  OutfitListState build() => const OutfitListState();

  Future<void> load() async {
    state = state.copyWith(status: OutfitListStatus.loading);
    final result = await ref.read(listOutfitsUsecaseProvider)();
    result.fold(
      (failure) => state = state.copyWith(status: OutfitListStatus.error, error: failure.message),
      (outfits) => state = state.copyWith(status: OutfitListStatus.ready, outfits: outfits),
    );
  }

  Future<bool> delete(String outfitId) async {
    final result = await ref.read(deleteOutfitUsecaseProvider)(outfitId);
    return result.fold(
      (failure) {
        state = state.copyWith(status: OutfitListStatus.error, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          outfits: state.outfits.where((o) => o.id != outfitId).toList(),
        );
        return true;
      },
    );
  }
}
