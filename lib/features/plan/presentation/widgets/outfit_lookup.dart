import '../../../outfit/domain/entities/outfit_entity.dart';
import '../../../wardrobe/domain/entities/wardrobe_item_entity.dart';

/// Joins plans to their outfit + wardrobe pieces for display. Built once per
/// screen from the loaded outfit list and wardrobe items.
class OutfitLookup {
  final Map<String, OutfitEntity> _outfits;
  final Map<String, WardrobeItemEntity> _items;

  OutfitLookup({
    required List<OutfitEntity> outfits,
    required List<WardrobeItemEntity> items,
  })  : _outfits = {for (final o in outfits) if (o.id != null) o.id!: o},
        _items = {for (final i in items) i.itemId: i};

  OutfitEntity? outfit(String outfitId) => _outfits[outfitId];

  String name(String outfitId) => _outfits[outfitId]?.name ?? 'Outfit';

  List<WardrobeItemEntity> piecesOf(String outfitId) {
    final outfit = _outfits[outfitId];
    if (outfit == null) return const [];
    return outfit.items
        .map((id) => _items[id])
        .whereType<WardrobeItemEntity>()
        .toList();
  }
}
