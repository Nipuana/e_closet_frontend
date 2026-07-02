import 'package:equatable/equatable.dart';

/// Sentinel stored in cells that are covered by a spanning neighbour module.
/// The covering module's anchor cell (top-left of its footprint) holds the id.
const String kCoveredCell = '#';

/// Decoded view of a single grid cell.
class CellInfo {
  /// Module id, or '' for an empty / covered cell.
  final String moduleId;
  final int colSpan;
  final int rowSpan;

  /// True when this cell is consumed by a spanning neighbour (not its anchor).
  final bool covered;

  const CellInfo({
    this.moduleId = '',
    this.colSpan = 1,
    this.rowSpan = 1,
    this.covered = false,
  });

  /// A tappable empty cell (no module, not covered).
  bool get isEmpty => moduleId.isEmpty && !covered;

  /// The top-left cell of a placed module's footprint.
  bool get isAnchor => moduleId.isNotEmpty;
}

/// The user's closet plan: a finish (wood tone) plus a [rows] × [cols] grid of
/// module ids ('' = empty) that mirrors the compartments of their real closet.
///
/// A placed module can be **extended across multiple tiles**. Its anchor cell
/// (top-left) stores the id, optionally with a span suffix `id@{cols}x{rows}`
/// (e.g. `hang@2x1`); every other tile in its footprint stores [kCoveredCell].
/// 1×1 modules keep a plain id (`hang`) so older plans stay compatible.
class WardrobeLayoutEntity extends Equatable {
  final String? id; // backend layout_id; null until first saved
  final String name; // user-facing label for this closet plan
  final String cabinetType; // Single | Double | Triple
  final String finish; // Natural | Walnut | Bone | Ink | Sage
  final int cols;
  final int rows;
  final List<List<String>> grid; // grid[row][col] = encoded cell
  // Pieces stored in each compartment: { "row,col": [itemId, ...] }.
  final Map<String, List<String>> placements;

  const WardrobeLayoutEntity({
    this.id,
    this.name = 'My Closet',
    this.cabinetType = 'Double',
    this.finish = 'Natural',
    this.cols = 3,
    this.rows = 4,
    this.grid = const [],
    this.placements = const {},
  });

  static String placementKey(int r, int c) => '$r,$c';

  /// Item ids stored in the compartment anchored at (r, c).
  List<String> itemsAt(int r, int c) => placements[placementKey(r, c)] ?? const [];

  /// Total pieces placed anywhere in this closet.
  int get placedCount => placements.values.fold(0, (n, list) => n + list.length);

  Map<String, List<String>> _mutablePlacements() =>
      {for (final e in placements.entries) e.key: [...e.value]};

  /// Add [itemId] to the compartment at (r, c) (removing it from any other
  /// compartment first, so a piece lives in one place).
  WardrobeLayoutEntity withItemAt(int r, int c, String itemId) {
    final p = _mutablePlacements();
    p.updateAll((key, list) => list.where((id) => id != itemId).toList());
    final key = placementKey(r, c);
    p[key] = [...(p[key] ?? const []), itemId];
    p.removeWhere((key, list) => list.isEmpty);
    return copyWith(placements: p);
  }

  /// Remove [itemId] from the compartment at (r, c).
  WardrobeLayoutEntity withoutItemAt(int r, int c, String itemId) {
    final p = _mutablePlacements();
    final key = placementKey(r, c);
    p[key] = (p[key] ?? const []).where((id) => id != itemId).toList();
    p.removeWhere((key, list) => list.isEmpty);
    return copyWith(placements: p);
  }

  /// An empty plan of the given size (a brand-new, unsaved wardrobe).
  factory WardrobeLayoutEntity.blank({
    String name = 'My Closet',
    String cabinetType = 'Double',
    String finish = 'Natural',
    int cols = 3,
    int rows = 4,
  }) {
    return WardrobeLayoutEntity(
      name: name,
      cabinetType: cabinetType,
      finish: finish,
      cols: cols,
      rows: rows,
      grid: List.generate(rows, (_) => List.filled(cols, '')),
    );
  }

  /// Count of placed modules (anchors) — handy for list previews.
  int get moduleCount {
    var n = 0;
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        if (cellAt(r, c).isAnchor) n++;
      }
    }
    return n;
  }

  String moduleAt(int r, int c) {
    if (r < 0 || r >= grid.length) return '';
    final row = grid[r];
    if (c < 0 || c >= row.length) return '';
    return row[c];
  }

  /// Decode the cell at (r, c) into id + span (or covered/empty).
  CellInfo cellAt(int r, int c) => _decode(moduleAt(r, c));

  static CellInfo _decode(String raw) {
    if (raw.isEmpty) return const CellInfo();
    if (raw == kCoveredCell) return const CellInfo(covered: true);
    final at = raw.indexOf('@');
    if (at < 0) return CellInfo(moduleId: raw);
    final id = raw.substring(0, at);
    final dims = raw.substring(at + 1).split('x');
    final cs = int.tryParse(dims.isNotEmpty ? dims[0] : '') ?? 1;
    final rs = int.tryParse(dims.length > 1 ? dims[1] : '') ?? 1;
    return CellInfo(moduleId: id, colSpan: cs < 1 ? 1 : cs, rowSpan: rs < 1 ? 1 : rs);
  }

  static String _encode(String id, int colSpan, int rowSpan) =>
      (colSpan <= 1 && rowSpan <= 1) ? id : '$id@${colSpan}x$rowSpan';

  List<List<String>> _mutableGrid() => [for (final row in grid) [...row]];

  /// Place a fresh 1×1 [moduleId] at (r, c), clearing any module already
  /// anchored there (including its spanned tiles). Pass '' to clear.
  WardrobeLayoutEntity withModule(int r, int c, String moduleId) {
    final g = _mutableGrid();
    _clearFootprint(g, r, c);
    g[r][c] = moduleId;
    return copyWith(grid: g);
  }

  /// Clear the module anchored at (r, c) and every tile it spans.
  WardrobeLayoutEntity clearCell(int r, int c) => withModule(r, c, '');

  /// Swap the module at anchor (r, c) for [moduleId] while keeping its current
  /// footprint (span). Clears it if [moduleId] is empty.
  WardrobeLayoutEntity withSwappedModule(int r, int c, String moduleId) {
    if (moduleId.isEmpty) return clearCell(r, c);
    final info = cellAt(r, c);
    if (!info.isAnchor) return withModule(r, c, moduleId);
    final g = _mutableGrid();
    g[r][c] = _encode(moduleId, info.colSpan, info.rowSpan);
    return copyWith(grid: g);
  }

  void _clearFootprint(List<List<String>> g, int r, int c) {
    final info = _decode(g[r][c]);
    if (!info.isAnchor) {
      g[r][c] = '';
      return;
    }
    for (int rr = r; rr < r + info.rowSpan && rr < g.length; rr++) {
      for (int cc = c; cc < c + info.colSpan && cc < g[rr].length; cc++) {
        g[rr][cc] = '';
      }
    }
  }

  /// Whether the block anchored at (r, c) can be relocated so its top-left sits
  /// at (newR, newC): it must stay in bounds and not overlap another module.
  bool canMoveTo(int r, int c, int newR, int newC) {
    final info = cellAt(r, c);
    if (!info.isAnchor) return false;
    if (newR < 0 || newC < 0) return false;
    if (newR + info.rowSpan > rows || newC + info.colSpan > cols) return false;
    for (int rr = newR; rr < newR + info.rowSpan; rr++) {
      for (int cc = newC; cc < newC + info.colSpan; cc++) {
        // Cells the block already occupies are free to reuse.
        final withinOld = rr >= r && rr < r + info.rowSpan &&
            cc >= c && cc < c + info.colSpan;
        if (withinOld) continue;
        if (moduleAt(rr, cc).isNotEmpty) return false;
      }
    }
    return true;
  }

  /// Move the block anchored at (r, c) so its top-left sits at (newR, newC),
  /// keeping its span. Returns the plan unchanged if the move isn't allowed.
  WardrobeLayoutEntity withMovedBlock(int r, int c, int newR, int newC) {
    if (!canMoveTo(r, c, newR, newC)) return this;
    final info = cellAt(r, c);
    final g = _mutableGrid();
    for (int rr = r; rr < r + info.rowSpan; rr++) {
      for (int cc = c; cc < c + info.colSpan; cc++) {
        g[rr][cc] = '';
      }
    }
    for (int rr = newR; rr < newR + info.rowSpan; rr++) {
      for (int cc = newC; cc < newC + info.colSpan; cc++) {
        g[rr][cc] = kCoveredCell;
      }
    }
    g[newR][newC] = _encode(info.moduleId, info.colSpan, info.rowSpan);
    return copyWith(grid: g);
  }

  /// Whether the module at (r, c) can be resized to span [newCols] × [newRows]
  /// tiles: it must stay in bounds and only grow into empty tiles.
  bool canResizeTo(int r, int c, int newCols, int newRows) {
    final info = cellAt(r, c);
    if (!info.isAnchor) return false;
    if (newCols < 1 || newRows < 1) return false;
    if (c + newCols > cols || r + newRows > rows) return false;
    for (int rr = r; rr < r + newRows; rr++) {
      for (int cc = c; cc < c + newCols; cc++) {
        if (rr == r && cc == c) continue;
        // Tiles already part of this module's current footprint are fine.
        final withinOld = rr < r + info.rowSpan && cc < c + info.colSpan;
        if (withinOld) continue;
        if (moduleAt(rr, cc).isNotEmpty) return false; // occupied by something else
      }
    }
    return true;
  }

  /// Resize the module anchored at (r, c) to span [newCols] × [newRows] tiles.
  /// Returns the plan unchanged if the resize isn't allowed.
  WardrobeLayoutEntity withSpan(int r, int c, int newCols, int newRows) {
    if (!canResizeTo(r, c, newCols, newRows)) return this;
    final info = cellAt(r, c);
    final g = _mutableGrid();
    // Release the old footprint, then stamp the new one.
    for (int rr = r; rr < r + info.rowSpan; rr++) {
      for (int cc = c; cc < c + info.colSpan; cc++) {
        g[rr][cc] = '';
      }
    }
    for (int rr = r; rr < r + newRows; rr++) {
      for (int cc = c; cc < c + newCols; cc++) {
        g[rr][cc] = kCoveredCell;
      }
    }
    g[r][c] = _encode(info.moduleId, newCols, newRows);
    return copyWith(grid: g);
  }

  /// Resize the grid, preserving placed modules and clamping any footprint
  /// that would overflow the new bounds.
  WardrobeLayoutEntity resized(int newRows, int newCols) {
    final next = List.generate(newRows, (_) => List.filled(newCols, ''));
    for (int r = 0; r < grid.length && r < newRows; r++) {
      for (int c = 0; c < grid[r].length && c < newCols; c++) {
        final info = _decode(grid[r][c]);
        if (!info.isAnchor) continue; // covered tiles are regenerated from anchors
        final cs = info.colSpan.clamp(1, newCols - c);
        final rs = info.rowSpan.clamp(1, newRows - r);
        for (int rr = r; rr < r + rs; rr++) {
          for (int cc = c; cc < c + cs; cc++) {
            next[rr][cc] = kCoveredCell;
          }
        }
        next[r][c] = _encode(info.moduleId, cs, rs);
      }
    }
    return copyWith(rows: newRows, cols: newCols, grid: next);
  }

  WardrobeLayoutEntity copyWith({
    String? id,
    String? name,
    String? cabinetType,
    String? finish,
    int? cols,
    int? rows,
    List<List<String>>? grid,
    Map<String, List<String>>? placements,
  }) {
    return WardrobeLayoutEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      cabinetType: cabinetType ?? this.cabinetType,
      finish: finish ?? this.finish,
      cols: cols ?? this.cols,
      rows: rows ?? this.rows,
      grid: grid ?? this.grid,
      placements: placements ?? this.placements,
    );
  }

  @override
  List<Object?> get props => [id, name, cabinetType, finish, cols, rows, grid, placements];
}
