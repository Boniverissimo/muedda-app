import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';

class MueddaPageShell extends StatelessWidget {
  const MueddaPageShell({
    required this.child,
    super.key,
    this.maxWidth = 1180,
    this.padding,
    this.safeTop = true,
    this.safeBottom = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool safeTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1024 ? AppSpacing.xl : AppSpacing.md;

    return SafeArea(
      top: safeTop,
      bottom: safeBottom,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding ?? EdgeInsets.fromLTRB(horizontal, AppSpacing.md, horizontal, AppSpacing.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}
