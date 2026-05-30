import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/wardrobe_repository.dart';
import '../../domain/repositories/wardrobe_repository.dart';

enum EditPieceStatus { idle, saving, deleting, error }

class EditPieceState extends Equatable {
  final EditPieceStatus status;
  final String? error;

  const EditPieceState({this.status = EditPieceStatus.idle, this.error});

  EditPieceState copyWith({EditPieceStatus? status, String? error}) =>
      EditPieceState(status: status ?? this.status, error: error);

  @override
  List<Object?> get props => [status, error];
}

final editPieceViewModelProvider =
    NotifierProvider<EditPieceViewModel, EditPieceState>(EditPieceViewModel.new);

class EditPieceViewModel extends Notifier<EditPieceState> {
  late IWardrobeRepository _repo;

  @override
  EditPieceState build() {
    _repo = ref.read(wardrobeRepositoryProvider);
    return const EditPieceState();
  }

  Future<bool> save({
    required String itemId,
    required String category,
    String? name,
    String? subCategory,
    String? brand,
    String? material,
    String? color,
    String? season,
    List<String>? colors,
    double? price,
    List<String>? tags,
    String? imagePath,
  }) async {
    state = state.copyWith(status: EditPieceStatus.saving, error: null);
    final result = await _repo.updateItem(
      itemId: itemId,
      category: category,
      name: name,
      subCategory: subCategory,
      brand: brand,
      material: material,
      color: color,
      season: season,
      colors: colors,
      price: price,
      tags: tags,
      imagePath: imagePath,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(status: EditPieceStatus.error, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: EditPieceStatus.idle);
        return true;
      },
    );
  }

  /// Permanently remove the piece from the wardrobe.
  Future<bool> delete(String itemId) async {
    state = state.copyWith(status: EditPieceStatus.deleting, error: null);
    final result = await _repo.deleteItem(itemId);
    return result.fold(
      (failure) {
        state = state.copyWith(status: EditPieceStatus.error, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: EditPieceStatus.idle);
        return true;
      },
    );
  }
}
