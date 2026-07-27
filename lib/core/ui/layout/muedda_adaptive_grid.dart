import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';

class MueddaAdaptiveGrid extends StatelessWidget {
  const MueddaAdaptiveGrid({
    required this.children,
    super.key,
    this.minItemWidth = 300,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor().clamp(1, 4);
        final itemWidth = (constraints.maxWidth - ((count - 1) * spacing)) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [for (final child in children) SizedBox(width: itemWidth, child: child)],
        );
      },
    );
  }
}
