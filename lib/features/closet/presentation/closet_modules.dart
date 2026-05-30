import 'package:flutter/material.dart';

/// A type of cabinet module that can be placed in a closet grid cell.
class ClosetModuleDef {
  final String id;
  final String label;
  final IconData icon;
  const ClosetModuleDef(this.id, this.label, this.icon);
}

/// Empty cell sentinel stored in the grid.
const String kEmptyModule = '';

/// Wood-tone colours for each finish, shared across the planner, list, and
/// preset previews.
const Map<String, Color> kFinishColors = {
  'Natural': Color(0xFFBFA179),
  'Walnut': Color(0xFF6B4A33),
  'Bone': Color(0xFFE0D4BE),
  'Ink': Color(0xFF2A2A28),
  'Sage': Color(0xFF9CA98C),
};

/// The modules a user can place. Kept intentionally small.
const List<ClosetModuleDef> kClosetModules = [
  ClosetModuleDef('folded', 'Folded', Icons.layers_outlined),
  ClosetModuleDef('hang', 'Hanger', Icons.checkroom),
  ClosetModuleDef('drawers', 'Drawers', Icons.dns_outlined),
];

/// Retired module types — no longer offered, but kept so closets saved with the
/// old, larger palette still render their tiles instead of going blank.
const List<ClosetModuleDef> _legacyModules = [
  ClosetModuleDef('double_hang', 'Double hang', Icons.density_small),
  ClosetModuleDef('long_hang', 'Long hang', Icons.dry_cleaning_outlined),
  ClosetModuleDef('shelf', 'Shelves', Icons.view_day_outlined),
  ClosetModuleDef('shoes', 'Shoe rack', Icons.ice_skating),
  ClosetModuleDef('cubby', 'Cubbies', Icons.grid_view_outlined),
];

final Map<String, ClosetModuleDef> _byId = {
  for (final m in [...kClosetModules, ..._legacyModules]) m.id: m,
};

ClosetModuleDef? moduleById(String id) => _byId[id];
