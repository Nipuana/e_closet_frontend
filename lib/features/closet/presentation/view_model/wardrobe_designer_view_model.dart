import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wardrobe_layout_entity.dart';
import '../../domain/usecases/closet_usecases.dart';
import 'wardrobe_list_view_model.dart';

enum DesignerStatus { initial, loading, ready, saving, error }

class WardrobeDesignerState extends Equatable {
  final DesignerStatus status;
  final WardrobeLayoutEntity layout;
  final String? error;

  WardrobeDesignerState({
    this.status = DesignerStatus.initial,
    WardrobeLayoutEntity? layout,
    this.error,
  }) : layout = layout ?? WardrobeLayoutEntity.blank();

  WardrobeDesignerState copyWith({
    DesignerStatus? status,
    WardrobeLayoutEntity? layout,
    String? error,
  }) {
    return WardrobeDesignerState(
      status: status ?? this.status,
      layout: layout ?? this.layout,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, layout, error];
}

final wardrobeDesignerViewModelProvider =
    NotifierProvider<WardrobeDesignerViewModel, WardrobeDesignerState>(
        WardrobeDesignerViewModel.new);

class WardrobeDesignerViewModel extends Notifier<WardrobeDesignerState> {
  static const int maxCols = 5;
  static const int maxRows = 8;

  @override
  WardrobeDesignerState build() => WardrobeDesignerState();

  /// Start editing [layout], or a fresh blank wardrobe when null (new wardrobe).
  void init(WardrobeLayoutEntity? layout) {
    state = WardrobeDesignerState(
      status: DesignerStatus.ready,
      layout: layout ?? WardrobeLayoutEntity.blank(),
    );
  }

  void setFinish(String finish) =>
      state = state.copyWith(layout: state.layout.copyWith(finish: finish));

  void setName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(layout: state.layout.copyWith(name: trimmed));
  }

  void setCell(int r, int c, String moduleId) =>
      state = state.copyWith(layout: state.layout.withModule(r, c, moduleId));

  /// Replace the whole working layout (used to discard/restore edits made in
  /// the modal resize editor).
  void setLayout(WardrobeLayoutEntity layout) =>
      state = state.copyWith(layout: layout);

  /// Grow/shrink the module anchored at (r, c) by one tile in a direction.
  void extendRight(int r, int c) => _resize(r, c, 1, 0);
  void extendDown(int r, int c) => _resize(r, c, 0, 1);
  void shrinkRight(int r, int c) => _resize(r, c, -1, 0);
  void shrinkDown(int r, int c) => _resize(r, c, 0, -1);

  void _resize(int r, int c, int dCols, int dRows) {
    final info = state.layout.cellAt(r, c);
    if (!info.isAnchor) return;
    state = state.copyWith(
      layout: state.layout.withSpan(r, c, info.colSpan + dCols, info.rowSpan + dRows),
    );
  }

  /// Swap the module at anchor (r, c) for another type, keeping its span.
  /// Pass [kEmptyModule] to clear it.
  void changeModule(int r, int c, String moduleId) =>
      state = state.copyWith(layout: state.layout.withSwappedModule(r, c, moduleId));

  /// Relocate the block anchored at (r, c) to (newR, newC), keeping its span.
  /// No-op if the destination is out of bounds or occupied.
  void moveBlock(int r, int c, int newR, int newC) =>
      state = state.copyWith(layout: state.layout.withMovedBlock(r, c, newR, newC));

  /// Resize the module anchored at (r, c) to span [cols] × [rows] tiles
  /// directly (used by drag-to-resize). No-op if the span isn't allowed.
  void resizeTo(int r, int c, int cols, int rows) {
    final info = state.layout.cellAt(r, c);
    if (!info.isAnchor) return;
    if (cols == info.colSpan && rows == info.rowSpan) return;
    state = state.copyWith(layout: state.layout.withSpan(r, c, cols, rows));
  }

  void setColumns(int cols) {
    final next = cols.clamp(1, maxCols);
    if (next == state.layout.cols) return;
    state = state.copyWith(layout: state.layout.resized(state.layout.rows, next));
  }

  void setRows(int rows) {
    final next = rows.clamp(1, maxRows);
    if (next == state.layout.rows) return;
    state = state.copyWith(layout: state.layout.resized(next, state.layout.cols));
  }

  Future<bool> save() async {
    state = state.copyWith(status: DesignerStatus.saving);
    final result = await ref.read(saveWardrobeLayoutUsecaseProvider)(state.layout);
    return result.fold(
      (failure) {
        state = state.copyWith(status: DesignerStatus.error, error: failure.message);
        return false;
      },
      (saved) {
        state = state.copyWith(status: DesignerStatus.ready, layout: saved);
        // Keep the shared wardrobe list in step, so the Closet tab and the
        // layouts list show the change without waiting to be reloaded.
        ref.read(wardrobeListViewModelProvider.notifier).upsert(saved);
        return true;
      },
    );
  }
}
