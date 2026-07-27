import 'package:flutter/material.dart';

class MueddaFilterChip extends StatelessWidget {
  const MueddaFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      avatar: icon == null ? null : Icon(icon, size: 18),
      label: Text(label),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}
