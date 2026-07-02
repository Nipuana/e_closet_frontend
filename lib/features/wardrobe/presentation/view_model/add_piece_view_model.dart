import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/add_item_usecase.dart';

enum AddPieceStatus { idle, submitting, success, error }

class AddPieceState extends Equatable {
  final AddPieceStatus status;
  final String? error;

  const AddPieceState({this.status = AddPieceStatus.idle, this.error});

  AddPieceState copyWith({AddPieceStatus? status, String? error}) =>
      AddPieceState(status: status ?? this.status, error: error);

  @override
  List<Object?> get props => [status, error];
}

final addPieceViewModelProvider =
    NotifierProvider<AddPieceViewModel, AddPieceState>(AddPieceViewModel.new);

class AddPieceViewModel extends Notifier<AddPieceState> {
  late AddItemUsecase _addItem;

  @override
  AddPieceState build() {
    _addItem = ref.read(addItemUsecaseProvider);
    return const AddPieceState();
  }

  Future<bool> submit(AddItemParams params) async {
    state = state.copyWith(status: AddPieceStatus.submitting, error: null);
    final result = await _addItem(params);
    return result.fold(
      (failure) {
        state = state.copyWith(status: AddPieceStatus.error, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: AddPieceStatus.success);
        return true;
      },
    );
  }
}
