import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A named colour option for the wardrobe swatch picker.
class WardrobeColorOption {
  final String name;
  final Color color;
  const WardrobeColorOption(this.name, this.color);
}

/// Curated wardrobe palette — users pick from these instead of typing.
/// Multi-colour garments simply select more than one.
const List<WardrobeColorOption> kWardrobeColors = [
  WardrobeColorOption('Black', Color(0xFF1A1A18)),
  WardrobeColorOption('Charcoal', Color(0xFF3A3A38)),
  WardrobeColorOption('Grey', Color(0xFF9C938A)),
  WardrobeColorOption('White', Color(0xFFFFFFFF)),
  WardrobeColorOption('Cream', Color(0xFFF1E9DC)),
  WardrobeColorOption('Beige', Color(0xFFE0D4BE)),
  WardrobeColorOption('Camel', Color(0xFFBFA179)),
  WardrobeColorOption('Tan', Color(0xFFC8A06A)),
  WardrobeColorOption('Brown', Color(0xFF6B4A33)),
  WardrobeColorOption('Terracotta', Color(0xFF915A3C)),
  WardrobeColorOption('Rust', Color(0xFFA85C32)),
  WardrobeColorOption('Mustard', Color(0xFFB8974A)),
  WardrobeColorOption('Olive', Color(0xFF6B6A45)),
  WardrobeColorOption('Green', Color(0xFF5C7A6B)),
  WardrobeColorOption('Sage', Color(0xFF9CA98C)),
  WardrobeColorOption('Teal', Color(0xFF3E6F6A)),
  WardrobeColorOption('Navy', Color(0xFF2E3640)),
  WardrobeColorOption('Blue', Color(0xFF4A6B8A)),
  WardrobeColorOption('Burgundy', Color(0xFF6E2F38)),
  WardrobeColorOption('Red', Color(0xFFB2473F)),
  WardrobeColorOption('Pink', Color(0xFFD7A7A7)),
  WardrobeColorOption('Purple', Color(0xFF5E4B6E)),
];

final Map<String, Color> _byName = {
  for (final o in kWardrobeColors) o.name.toLowerCase(): o.color,
};

/// Resolve a stored colour to a [Color] — handles curated names and `#RRGGBB`
/// hex values (e.g. the auto-extracted `color_palette`). Falls back to grey.
Color colorForName(String value) {
  final v = value.trim();
  final named = _byName[v.toLowerCase()];
  if (named != null) return named;
  final hex = v.replaceAll('#', '');
  if (hex.length == 6) {
    final n = int.tryParse('FF$hex', radix: 16);
    if (n != null) return Color(n);
  }
  return AppColors.stone400;
}

/// Multi-select swatch grid. Reports the set of selected colour *names*.
class ColorMultiPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const ColorMultiPicker({super.key, required this.selected, required this.onChanged});

  void _toggle(String name) {
    final next = {...selected};
    if (!next.add(name)) next.remove(name);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      spacing: AppSpacing.space3,
      runSpacing: AppSpacing.space3,
      children: [
        for (final option in kWardrobeColors)
          _Swatch(
            option: option,
            selected: selected.contains(option.name),
            borderColor: palette.border,
            checkOn: palette.background,
            onTap: () => _toggle(option.name),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final WardrobeColorOption option;
  final bool selected;
  final Color borderColor;
  final Color checkOn;
  final VoidCallback onTap;

  const _Swatch({
    required this.option,
    required this.selected,
    required this.borderColor,
    required this.checkOn,
    required this.onTap,
  });

  bool get _isLight => option.color.computeLuminance() > 0.6;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.accent : borderColor,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check,
                    size: AppSpacing.iconXs,
                    color: _isLight ? AppColors.ink : checkOn)
                : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 48,
            child: Text(
              option.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                color: selected ? palette.textPrimary : palette.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
