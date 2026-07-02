import '../../domain/entities/wardrobe_layout_entity.dart';

class WardrobeLayoutModel {
  final String? id;
  final String name;
  final String cabinetType;
  final String finish;
  final int cols;
  final int rows;
  final List<List<String>> grid;
  final Map<String, List<String>> placements;

  WardrobeLayoutModel({
    this.id,
    required this.name,
    required this.cabinetType,
    required this.finish,
    required this.cols,
    required this.rows,
    required this.grid,
    this.placements = const {},
  });

  factory WardrobeLayoutModel.fromJson(Map<String, dynamic> json) {
    final dims = json['dimensions'] as Map<String, dynamic>?;
    var cols = (dims?['cols'] as num?)?.toInt() ?? 3;
    var rows = (dims?['rows'] as num?)?.toInt() ?? 4;

    final zones = json['zones'] as List<dynamic>?;
    List<List<String>> grid;
    if (zones != null && zones.isNotEmpty) {
      grid = zones
          .map<List<String>>((row) =>
              (row as List<dynamic>).map((e) => e.toString()).toList())
          .toList();
      rows = grid.length;
      cols = grid.isNotEmpty ? grid.first.length : cols;
    } else {
      grid = List.generate(rows, (_) => List.filled(cols, ''));
    }

    final rawName = (json['name'] ?? '').toString().trim();

    final rawPlacements = json['placements'] as Map<String, dynamic>?;
    final placements = <String, List<String>>{};
    if (rawPlacements != null) {
      rawPlacements.forEach((key, value) {
        if (value is List) {
          placements[key] = value.map((e) => e.toString()).toList();
        }
      });
    }

    return WardrobeLayoutModel(
      id: json['layout_id']?.toString(),
      name: rawName.isEmpty ? 'My Closet' : rawName,
      cabinetType: (json['cabinet_type'] ?? 'Double').toString(),
      finish: (json['finish'] ?? 'Natural').toString(),
      cols: cols,
      rows: rows,
      grid: grid,
      placements: placements,
    );
  }

  WardrobeLayoutEntity toEntity() => WardrobeLayoutEntity(
        id: id,
        name: name,
        cabinetType: cabinetType,
        finish: finish,
        cols: cols,
        rows: rows,
        grid: grid,
        placements: placements,
      );
}
